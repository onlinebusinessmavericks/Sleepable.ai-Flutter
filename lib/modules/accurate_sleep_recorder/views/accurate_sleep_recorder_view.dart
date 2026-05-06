import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart' hide LinearGradient;
import 'package:sleepable_ai/localization/lang_extension.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/text_theme.dart';
import '../../../data/billing/billing_controller.dart';
import '../../../generated/assets.dart';
import '../../../widgets/custom_button.dart';
import '../controllers/accurate_sleep_recorder_controller.dart';

class AccurateSleepRecorderView extends GetView<AccurateSleepRecorderController> {
  const AccurateSleepRecorderView({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfigs.init(context);
    SizeConfigs2.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Lottie.asset(Assets.lottieSleepReportBackground, fit: BoxFit.cover, repeat: true)),
        
            Column(
              children: [
                SizedBox(height: sh(80)),
        
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad(24)),
                  child: Text(
                    context.lang.accurateSleepRecorder,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColors.white, fontSize: sp(14), fontWeight: FontWeight.w300),
                  ),
                ),
        
                SizedBox(height: sh(10)),
        
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad(24)),
                  child: Text(
                    context.lang.findOutWhatYourSleep,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.white, fontSize: sp(24), fontWeight: FontWeight.bold),
                  ),
                ),
        
                SizedBox(height: sh(20)),
        
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.audios.length,
                    itemBuilder: (_, index) {
                      return Obx(() {
                        return SleepAudioCard(audio: controller.audios[index], isActive: controller.currentIndex.value == index, onTap: () {});
                      });
                    },
                  ),
                ),
        
                SizedBox(height: sh(20)),
                AnimatedNextButton(onPressed: controller.goNext),
                SizedBox(height: sh(30)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SleepAudioCard extends StatelessWidget {
  final SleepAudio audio;
  final bool isActive;
  final VoidCallback onTap;

  const SleepAudioCard({super.key, required this.audio, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: pad(16), vertical: sh(8)),
        padding: EdgeInsets.all(pad(16)),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(sw(20)),
          border: isActive ? Border.all(color: const Color(0xFF4F8CFF), width: sw(2)) : null,
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF4F8CFF).withOpacity(0.5), blurRadius: sw(16), spreadRadius: sw(1))] : [],
        ),
        child: Row(
          children: [
            Lottie.asset(audio.lottiePath, height: sw(70), width: sw(70), repeat: isActive),

            SizedBox(width: sw(12)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.title,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(color: AppColors.white, fontSize: sp(20), fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: sh(4)),

                  Padding(
                    padding: EdgeInsets.only(left: sw(8)),
                    child: Text(
                      audio.time,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white70, fontSize: sp(14)),
                    ),
                  ),

                  // SizedBox(height: sh(8)),
                  SoundWaveLottie(isActive: isActive),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoundWaveLottie extends StatefulWidget {
  final bool isActive;

  const SoundWaveLottie({super.key, required this.isActive});

  @override
  State<SoundWaveLottie> createState() => _SoundWaveLottieState();
}

class _SoundWaveLottieState extends State<SoundWaveLottie> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant SoundWaveLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.isActive ? _controller.repeat() : _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.isActive ? 1 : 0.3,
      child: Row(children: List.generate(3, (_) => _wave())),
    );
  }

  Widget _wave() {
    return Expanded(
      child: Lottie.asset(
        Assets.lottieSoundWaves,
        height: sh(40),
        controller: _controller,
        fit: BoxFit.fitWidth,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          if (widget.isActive) _controller.repeat();
        },
      ),
    );
  }
}
