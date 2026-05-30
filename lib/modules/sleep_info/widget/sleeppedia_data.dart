
import 'package:get/get.dart';
import 'package:sleepable_ai/localization/lang_extension.dart';
import '../../../generated/assets.dart';
import '../model/sleeppedia_item.dart';

// Note: Is list ko ek function ke andar rakhein taaki 'context' access ho sake
List<SleeppediaItem> getLocalizedSleeppediaList() {
  final lang = Get.context!.lang;

  return [
    // ================= INSOMNIA =================
    SleeppediaItem(
      title: lang.insomniaTitle, // "Insomnia"
      image: Assets.sleeppediaInsomania,
      sections: [
        SleeppediaSection(
          title: lang.overview,
          paragraphs: [
            lang.insomniaOverview1, // "Insomnia is a common sleep condition..."
            lang.insomniaOverview2,
            lang.insomniaOverview3,
            lang.insomniaOverview4,
            lang.insomniaOverview5,
          ],
        ),
        SleeppediaSection(
          title: lang.definition,
          paragraphs: [
            lang.insomniaDef1,
            lang.insomniaDef2,
          ],
        ),
        SleeppediaSection(
          title: lang.typesOfInsomnia,
          bullets: [
            lang.insomniaTypeShort,
            lang.insomniaTypeChronic,
            lang.insomniaTypeOther,
          ],
        ),
        SleeppediaSection(
          title: lang.whoIsAffected,
          paragraphs: [
            lang.insomniaWho1,
            lang.insomniaWho2,
            lang.insomniaWho3,
          ],
        ),
        SleeppediaSection(
          title: lang.commonCauses,
          bullets: [
            lang.insomniaCause1,
            lang.insomniaCause2,
            lang.insomniaCause3,
            lang.insomniaCause4,
            lang.insomniaCause5,
            lang.insomniaCause6,
            lang.insomniaCause7,
          ],
        ),
        SleeppediaSection(
          title: lang.substancesAffectSleep,
          bullets: [
            lang.insomniaSubstance1,
            lang.insomniaSubstance2,
            lang.insomniaSubstance3,
            lang.insomniaSubstance4,
            lang.insomniaSubstance5,
          ],
        ),
        SleeppediaSection(
          title: lang.healthEmotionalFactors,
          bullets: [
            lang.insomniaFactor1,
            lang.insomniaFactor2,
            lang.insomniaFactor3,
            lang.insomniaFactor4,
            lang.insomniaFactor5,
            lang.insomniaFactor6,
            lang.insomniaFactor7,
          ],
        ),
        SleeppediaSection(
          title: lang.symptoms,
          bullets: [
            lang.insomniaSymp1,
            lang.insomniaSymp2,
            lang.insomniaSymp3,
            lang.insomniaSymp4,
            lang.insomniaSymp5,
            lang.insomniaSymp6,
          ],
        ),
        SleeppediaSection(
          title: lang.diagnosis,
          bullets: [
            lang.insomniaDiag1,
            lang.insomniaDiag2,
            lang.insomniaDiag3,
            lang.insomniaDiag4,
          ],
        ),
        SleeppediaSection(
          title: lang.treatmentApproaches,
          paragraphs: [
            lang.insomniaTreat1,
            lang.insomniaTreat2,
            lang.insomniaTreat3,
          ],
        ),
        SleeppediaSection(
          title: lang.healthySleepHabits,
          bullets: [
            lang.insomniaHabit1,
            lang.insomniaHabit2,
            lang.insomniaHabit3,
            lang.insomniaHabit4,
            lang.insomniaHabit5,
            lang.insomniaHabit6,
          ],
        ),
        SleeppediaSection(
          title: lang.medication,
          paragraphs: [
            lang.insomniaMed1,
            lang.insomniaMed2,
          ],
        ),
        SleeppediaSection(
          title: lang.preventionTips,
          bullets: [
            lang.insomniaPrev1,
            lang.insomniaPrev2,
            lang.insomniaPrev3,
            lang.insomniaPrev4,
            lang.insomniaPrev5,
          ],
        ),
        SleeppediaSection(
          title: lang.possibleComplications,
          bullets: [
            lang.insomniaComp1,
            lang.insomniaComp2,
            lang.insomniaComp3,
            lang.insomniaComp4,
            lang.insomniaComp5,
          ],
        ),
        SleeppediaSection(
          title: lang.outlook,
          paragraphs: [
            lang.insomniaOutlook1,
            lang.insomniaOutlook2,
            lang.insomniaOutlook3,
          ],
        ),
      ],
    ),

    // ================= HYPERSOMNIA =================
    SleeppediaItem(
      title: lang.hypersomniaTitle,
      image: Assets.sleeppediaHypersomnia1,
      sections: [
        SleeppediaSection(
          title: lang.overview,
          paragraphs: [lang.hypersomniaOverview1, lang.hypersomniaOverview2],
        ),
        SleeppediaSection(
          title: lang.commonCauses,
          bullets: [lang.hypersomniaCause1, lang.hypersomniaCause2, lang.hypersomniaCause3, lang.hypersomniaCause4],
        ),
        SleeppediaSection(
          title: lang.symptoms,
          bullets: [lang.hypersomniaSymp1, lang.hypersomniaSymp2, lang.hypersomniaSymp3, lang.hypersomniaSymp4],
        ),
        SleeppediaSection(
          title: lang.managementTips,
          bullets: [lang.hypersomniaTip1, lang.hypersomniaTip2, lang.hypersomniaTip3, lang.hypersomniaTip4],
        ),
      ],
    ),

    // ================= SNORING =================
    SleeppediaItem(
      title: lang.snoringTitle,
      image: Assets.sleeppediaSnoring,
      sections: [
        SleeppediaSection(
          title: lang.overview,
          paragraphs: [lang.snoringOverview1, lang.snoringOverview2],
        ),
        SleeppediaSection(
          title: lang.commonCauses,
          bullets: [lang.snoringCause1, lang.snoringCause2, lang.snoringCause3, lang.snoringCause4],
        ),
        SleeppediaSection(
          title: lang.possibleEffects,
          bullets: [lang.snoringEffect1, lang.snoringEffect2, lang.snoringEffect3],
        ),
        SleeppediaSection(
          title: lang.helpfulTips,
          bullets: [lang.snoringTip1, lang.snoringTip2, lang.snoringTip3, lang.snoringTip4],
        ),
      ],
    ),

    // ================= SLEEP APNEA =================
    SleeppediaItem(
      title: lang.breathingPausesTitle,
      image: Assets.sleeppediaBreathingAbnormalPauses,
      sections: [
        SleeppediaSection(
          title: lang.overview,
          paragraphs: [lang.apneaOverview1, lang.apneaOverview2],
        ),
        SleeppediaSection(
          title: lang.symptoms, // Reusing symptoms key
          bullets: [lang.apneaSign1, lang.apneaSign2, lang.apneaSign3, lang.apneaSign4],
        ),
        SleeppediaSection(
          title: lang.riskFactors,
          bullets: [lang.apneaRisk1, lang.apneaRisk2, lang.apneaRisk3, lang.apneaRisk4],
        ),
        SleeppediaSection(
          title: lang.treatmentOptions,
          bullets: [lang.apneaTreat1, lang.apneaTreat2, lang.apneaTreat3, lang.apneaTreat4],
        ),
      ],
    ),

    // ================= BRUXISM =================
    SleeppediaItem(
      title: lang.bruxismTitle,
      image: Assets.sleeppediaBruxism,
      sections: [
        SleeppediaSection(
          title: lang.overview,
          paragraphs: [lang.bruxismOverview1, lang.bruxismOverview2],
        ),
        SleeppediaSection(
          title: lang.commonCauses,
          bullets: [lang.bruxismCause1, lang.bruxismCause2, lang.bruxismCause3, lang.bruxismCause4],
        ),
        SleeppediaSection(
          title: lang.symptoms,
          bullets: [lang.bruxismSymp1, lang.bruxismSymp2, lang.bruxismSymp3, lang.bruxismSymp4],
        ),
        SleeppediaSection(
          title: lang.management,
          bullets: [lang.bruxismManage1, lang.bruxismManage2, lang.bruxismManage3, lang.bruxismManage4],
        ),
      ],
    ),

    // ================= RESTLESS LEG =================
    SleeppediaItem(
      title: lang.restlessLegTitle,
      image: Assets.sleeppediaRestlessLegSyndrome,
      sections: [
        SleeppediaSection(
          title: lang.overview,
          paragraphs: [lang.rlsOverview1, lang.rlsOverview2],
        ),
        SleeppediaSection(
          title: lang.commonSymptoms,
          bullets: [lang.rlsSymp1, lang.rlsSymp2, lang.rlsSymp3, lang.rlsSymp4],
        ),
        SleeppediaSection(
          title: lang.commonCauses,
          bullets: [lang.rlsCause1, lang.rlsCause2, lang.rlsCause3, lang.rlsCause4],
        ),
        SleeppediaSection(
          title: lang.helpfulHabits,
          bullets: [lang.rlsHabit1, lang.rlsHabit2, lang.rlsHabit3, lang.rlsHabit4],
        ),
      ],
    ),

    // ================= PALPITATIONS & INSOMNIA =================
    SleeppediaItem(
      title: lang.palpitationsTitle,
      image: Assets.sleeppediaPalpitations,
      sections: [
        SleeppediaSection(
          title: lang.overview,
          paragraphs: [lang.palpOverview1, lang.palpOverview2],
        ),
        SleeppediaSection(
          title: lang.commonCauses,
          bullets: [lang.palpCause1, lang.palpCause2, lang.palpCause3, lang.palpCause4],
        ),
        SleeppediaSection(
          title: lang.symptoms,
          bullets: [lang.palpSymp1, lang.palpSymp2, lang.palpSymp3, lang.palpSymp4],
        ),
        SleeppediaSection(
          title: lang.helpfulTips,
          bullets: [lang.palpTip1, lang.palpTip2, lang.palpTip3, lang.palpTip4],
        ),
      ],
    ),
  ];
}