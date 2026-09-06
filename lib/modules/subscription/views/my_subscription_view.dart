import 'dart:io';

import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sleepable_ai/core/utils/library.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../localization/lang_extension.dart';
import '../../../widgets/SubscriptionController.dart';
import '../../../widgets/showPremiumOfferSheet.dart';
import '../../music/views/music_view.dart';

/// Where a subscriber can see what they are actually paying for.
///
/// Everything on this screen comes from two places: the store's own record of
/// the purchase (RevenueCat), and the backend's premium flag. The backend is
/// the one that decides access - a user can be premium without any store
/// purchase, for instance when support grants it - so the screen has to read
/// sensibly when there is no store record at all.
class MySubscriptionView extends StatefulWidget {
  const MySubscriptionView({Key? key}) : super(key: key);

  @override
  State<MySubscriptionView> createState() => _MySubscriptionViewState();
}

class _MySubscriptionViewState extends State<MySubscriptionView> {
  final SubscriptionController sub = Get.isRegistered<SubscriptionController>()
      ? Get.find<SubscriptionController>()
      : Get.put(SubscriptionController());

  @override
  void initState() {
    super.initState();
    // Both sides can be stale by the time someone opens this screen.
    sub.refreshEntitlementDetails();
    sub.getBackendSubscriptionStatus();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 22.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SmallCircleIcon(
              icon: Icons.arrow_back_rounded,
              size: 20 * SizeConfigs.textScale,
              iconColor: Colors.white,
              backgroundColor: Colors.white10,
              onTap: () => Get.back(),
            ),
          ),
        ),
        title: Text(
          _copy("title"),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontSize: 21 * SizeConfigs.textScale,
                fontWeight: FontWeight.w500,
              ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final ent = sub.activeEntitlement.value;
        final isTrial = sub.isTrial.value;
        final isPremium = sub.isPremium.value;

        return RefreshIndicator(
          onRefresh: () async {
            await sub.refreshEntitlementDetails();
            await sub.getBackendSubscriptionStatus();
          },
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20 * SizeConfigs.paddingScale, vertical: 16),
            children: [
              _statusCard(isPremium: isPremium, isTrial: isTrial, ent: ent),
              const SizedBox(height: 20),
              if (isPremium || isTrial) ..._details(ent: ent, isTrial: isTrial),
              const SizedBox(height: 8),
              ..._actions(isPremium: isPremium, isTrial: isTrial, ent: ent),
              const SizedBox(height: 28),
              Text(
                _copy("storeNote"),
                style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  Widget _statusCard({required bool isPremium, required bool isTrial, EntitlementInfo? ent}) {
    final String label;
    final Color colour;
    if (isPremium) {
      label = _copy("statusPremium");
      colour = const Color(0xFF4ADE80);
    } else if (isTrial) {
      label = _copy("statusTrial");
      colour = const Color(0xFFFBBF24);
    } else {
      label = _copy("statusFree");
      colour = Colors.white38;
    }

    final days = sub.trialDaysRemaining;
    final String? subtitle = isTrial
        ? (days == null
            ? _copy("trialRunning")
            : days <= 0
                ? _copy("trialEndsToday")
                : days == 1
                    ? _copy("trialEndsTomorrow")
                    : _copy("trialEndsIn").replaceAll("{days}", "$days"))
        : (isPremium ? _planName(ent) : _copy("freeSubtitle"));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colour.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: colour, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(color: colour, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle ?? "",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * SizeConfigs.textScale,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (isTrial) ...[
            const SizedBox(height: 10),
            Text(_copy("trialIncludes"), style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Detail rows
  // ---------------------------------------------------------------------------

  List<Widget> _details({EntitlementInfo? ent, required bool isTrial}) {
    final rows = <Widget>[];

    if (ent == null) {
      // Premium without a store purchase: nothing here comes from the store, so
      // say that plainly rather than showing blank rows.
      rows.add(_infoBox(_copy("noStoreRecord")));
      return rows;
    }

    final started = _date(ent.latestPurchaseDate);
    final ends = _date(ent.expirationDate);
    final cancelled = ent.unsubscribeDetectedAt != null;

    rows.add(_row(_copy("plan"), _planName(ent)));
    if (started != null) rows.add(_row(_copy("started"), started));
    if (ends != null) {
      rows.add(_row(
        isTrial
            ? _copy("firstCharge")
            : cancelled || !ent.willRenew
                ? _copy("accessUntil")
                : _copy("renewsOn"),
        ends,
      ));
    }
    rows.add(_row(
      _copy("autoRenew"),
      ent.willRenew ? _copy("on") : _copy("off"),
      valueColour: ent.willRenew ? null : const Color(0xFFFBBF24),
    ));
    rows.add(_row(_copy("boughtFrom"), _storeName(ent.store)));

    if (cancelled) rows.add(_infoBox(_copy("cancelledNote")));
    if (ent.billingIssueDetectedAt != null) rows.add(_infoBox(_copy("billingIssue")));

    return rows;
  }

  Widget _row(String label, String value, {Color? valueColour}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColour ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  List<Widget> _actions({required bool isPremium, required bool isTrial, EntitlementInfo? ent}) {
    final buttons = <Widget>[];

    if (!isPremium && !isTrial) {
      buttons.add(_primaryButton(_copy("seePlans"), () => showPremiumOfferSheet(context)));
    }

    // Cancelling is the store's job on both platforms; the app is not allowed
    // to do it, so send the user to the page that can.
    if (isPremium || isTrial) {
      buttons.add(_primaryButton(_copy("manage"), _openStoreSubscriptions));
    }

    buttons.add(const SizedBox(height: 10));
    buttons.add(
      TextButton(
        onPressed: sub.restorePurchases,
        child: Text(_copy("restore"), style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ),
    );

    return buttons;
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.animationEndColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Future<void> _openStoreSubscriptions() async {
    final url = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(context.lang.error, _copy("couldNotOpenStore"));
    }
  }

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  String? _date(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateFormat('d MMM yyyy').format(parsed.toLocal());
  }

  String _planName(EntitlementInfo? ent) {
    final id = ent?.productIdentifier.toLowerCase() ?? '';
    if (id.contains('year') || id.contains('annual')) return _copy("yearly");
    if (id.contains('week')) return _copy("weekly");
    if (id.contains('month')) return _copy("monthly");
    return _copy("statusPremium");
  }

  String _storeName(Store store) {
    switch (store) {
      case Store.appStore:
        return 'App Store';
      case Store.playStore:
        return 'Google Play';
      case Store.stripe:
        return 'Stripe';
      case Store.promotional:
        return _copy("granted");
      default:
        return _copy("other");
    }
  }

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  String _copy(String key) {
    const map = {
      "en": {
        "title": "My Subscription",
        "statusPremium": "Premium",
        "statusTrial": "Free Trial",
        "statusFree": "Free",
        "freeSubtitle": "You are on the free plan",
        "trialRunning": "Your free trial is running",
        "trialEndsIn": "Premium starts in {days} days",
        "trialEndsTomorrow": "Premium starts tomorrow",
        "trialEndsToday": "Premium starts today",
        "trialIncludes": "During the trial you get 1 dream and 1 sleep report. Recordings unlock when Premium starts.",
        "plan": "Plan",
        "started": "Started on",
        "renewsOn": "Renews on",
        "accessUntil": "Access until",
        "firstCharge": "First charge on",
        "autoRenew": "Auto-renew",
        "on": "On",
        "off": "Off",
        "boughtFrom": "Bought from",
        "yearly": "Yearly",
        "weekly": "Weekly",
        "monthly": "Monthly",
        "granted": "Granted",
        "other": "Other",
        "cancelledNote": "You have cancelled. You keep full access until the date above, and nothing more will be charged.",
        "billingIssue": "There is a problem with your payment method. Update it in the store to keep your subscription.",
        "noStoreRecord": "Your Premium was not bought through the store, so there is no renewal date to show. Contact support if anything looks wrong.",
        "seePlans": "See Plans",
        "manage": "Manage or Cancel",
        "restore": "Restore Purchases",
        "couldNotOpenStore": "Could not open subscription settings",
        "storeNote": "Subscriptions are billed and cancelled by the store, not by Sleepable. Cancelling stops the next charge; you keep access until the current period ends.",
      },
      "de": {
        "title": "Mein Abo",
        "statusPremium": "Premium",
        "statusTrial": "Kostenlose Testphase",
        "statusFree": "Kostenlos",
        "freeSubtitle": "Sie nutzen den kostenlosen Tarif",
        "trialRunning": "Ihre Testphase laeuft",
        "trialEndsIn": "Premium startet in {days} Tagen",
        "trialEndsTomorrow": "Premium startet morgen",
        "trialEndsToday": "Premium startet heute",
        "trialIncludes": "Waehrend der Testphase erhalten Sie 1 Traum und 1 Schlafbericht. Aufnahmen werden mit Premium freigeschaltet.",
        "plan": "Tarif",
        "started": "Begonnen am",
        "renewsOn": "Verlaengert am",
        "accessUntil": "Zugriff bis",
        "firstCharge": "Erste Abbuchung am",
        "autoRenew": "Automatische Verlaengerung",
        "on": "An",
        "off": "Aus",
        "boughtFrom": "Gekauft ueber",
        "yearly": "Jaehrlich",
        "weekly": "Woechentlich",
        "monthly": "Monatlich",
        "granted": "Gewaehrt",
        "other": "Andere",
        "cancelledNote": "Sie haben gekuendigt. Der Zugriff bleibt bis zum oben genannten Datum bestehen, weitere Abbuchungen erfolgen nicht.",
        "billingIssue": "Es gibt ein Problem mit Ihrer Zahlungsmethode. Bitte aktualisieren Sie sie im Store.",
        "noStoreRecord": "Ihr Premium wurde nicht ueber den Store gekauft, daher gibt es kein Verlaengerungsdatum. Bei Fragen wenden Sie sich an den Support.",
        "seePlans": "Tarife ansehen",
        "manage": "Verwalten oder kuendigen",
        "restore": "Kaeufe wiederherstellen",
        "couldNotOpenStore": "Abo-Einstellungen konnten nicht geoeffnet werden",
        "storeNote": "Abos werden vom Store abgerechnet und gekuendigt, nicht von Sleepable. Eine Kuendigung stoppt die naechste Abbuchung; der Zugriff bleibt bis zum Ende des Zeitraums.",
      },
      "fr": {
        "title": "Mon abonnement",
        "statusPremium": "Premium",
        "statusTrial": "Essai gratuit",
        "statusFree": "Gratuit",
        "freeSubtitle": "Vous utilisez la formule gratuite",
        "trialRunning": "Votre essai gratuit est en cours",
        "trialEndsIn": "Premium demarre dans {days} jours",
        "trialEndsTomorrow": "Premium demarre demain",
        "trialEndsToday": "Premium demarre aujourd'hui",
        "trialIncludes": "Pendant l'essai vous avez 1 reve et 1 rapport de sommeil. Les enregistrements arrivent avec Premium.",
        "plan": "Formule",
        "started": "Debut le",
        "renewsOn": "Renouvellement le",
        "accessUntil": "Acces jusqu'au",
        "firstCharge": "Premier paiement le",
        "autoRenew": "Renouvellement auto",
        "on": "Active",
        "off": "Desactive",
        "boughtFrom": "Achete sur",
        "yearly": "Annuel",
        "weekly": "Hebdomadaire",
        "monthly": "Mensuel",
        "granted": "Accorde",
        "other": "Autre",
        "cancelledNote": "Vous avez resilie. Vous gardez l'acces jusqu'a la date ci-dessus et rien ne sera preleve.",
        "billingIssue": "Votre moyen de paiement pose probleme. Mettez-le a jour dans le store.",
        "noStoreRecord": "Votre Premium n'a pas ete achete via le store, il n'y a donc pas de date de renouvellement. Contactez le support si besoin.",
        "seePlans": "Voir les formules",
        "manage": "Gerer ou resilier",
        "restore": "Restaurer les achats",
        "couldNotOpenStore": "Impossible d'ouvrir les reglages d'abonnement",
        "storeNote": "Les abonnements sont factures et resilies par le store, pas par Sleepable. Resilier arrete le prochain paiement; l'acces reste jusqu'a la fin de la periode.",
      },
      "es": {
        "title": "Mi suscripcion",
        "statusPremium": "Premium",
        "statusTrial": "Prueba gratuita",
        "statusFree": "Gratis",
        "freeSubtitle": "Estas en el plan gratuito",
        "trialRunning": "Tu prueba gratuita esta activa",
        "trialEndsIn": "Premium empieza en {days} dias",
        "trialEndsTomorrow": "Premium empieza manana",
        "trialEndsToday": "Premium empieza hoy",
        "trialIncludes": "Durante la prueba tienes 1 sueno y 1 informe de sueno. Las grabaciones se activan con Premium.",
        "plan": "Plan",
        "started": "Inicio el",
        "renewsOn": "Se renueva el",
        "accessUntil": "Acceso hasta",
        "firstCharge": "Primer cobro el",
        "autoRenew": "Renovacion automatica",
        "on": "Activada",
        "off": "Desactivada",
        "boughtFrom": "Comprado en",
        "yearly": "Anual",
        "weekly": "Semanal",
        "monthly": "Mensual",
        "granted": "Concedido",
        "other": "Otro",
        "cancelledNote": "Has cancelado. Conservas el acceso hasta la fecha de arriba y no se cobrara nada mas.",
        "billingIssue": "Hay un problema con tu metodo de pago. Actualizalo en la tienda.",
        "noStoreRecord": "Tu Premium no se compro en la tienda, asi que no hay fecha de renovacion. Contacta con soporte si algo no cuadra.",
        "seePlans": "Ver planes",
        "manage": "Gestionar o cancelar",
        "restore": "Restaurar compras",
        "couldNotOpenStore": "No se pudieron abrir los ajustes de suscripcion",
        "storeNote": "Las suscripciones las cobra y cancela la tienda, no Sleepable. Cancelar detiene el proximo cobro; mantienes el acceso hasta que termine el periodo.",
      },
      "pt": {
        "title": "Minha assinatura",
        "statusPremium": "Premium",
        "statusTrial": "Teste gratuito",
        "statusFree": "Gratuito",
        "freeSubtitle": "Voce esta no plano gratuito",
        "trialRunning": "Seu teste gratuito esta ativo",
        "trialEndsIn": "O Premium comeca em {days} dias",
        "trialEndsTomorrow": "O Premium comeca amanha",
        "trialEndsToday": "O Premium comeca hoje",
        "trialIncludes": "Durante o teste voce tem 1 sonho e 1 relatorio de sono. As gravacoes liberam com o Premium.",
        "plan": "Plano",
        "started": "Iniciado em",
        "renewsOn": "Renova em",
        "accessUntil": "Acesso ate",
        "firstCharge": "Primeira cobranca em",
        "autoRenew": "Renovacao automatica",
        "on": "Ativada",
        "off": "Desativada",
        "boughtFrom": "Comprado em",
        "yearly": "Anual",
        "weekly": "Semanal",
        "monthly": "Mensal",
        "granted": "Concedido",
        "other": "Outro",
        "cancelledNote": "Voce cancelou. O acesso continua ate a data acima e nada mais sera cobrado.",
        "billingIssue": "Ha um problema com sua forma de pagamento. Atualize na loja.",
        "noStoreRecord": "Seu Premium nao foi comprado na loja, entao nao ha data de renovacao. Fale com o suporte se algo parecer errado.",
        "seePlans": "Ver planos",
        "manage": "Gerenciar ou cancelar",
        "restore": "Restaurar compras",
        "couldNotOpenStore": "Nao foi possivel abrir as configuracoes de assinatura",
        "storeNote": "As assinaturas sao cobradas e canceladas pela loja, nao pelo Sleepable. Cancelar interrompe a proxima cobranca; o acesso continua ate o fim do periodo.",
      },
    };
    final table = map[Get.locale?.languageCode ?? "en"] ?? map["en"]!;
    return table[key] ?? map["en"]![key] ?? "";
  }
}
