import 'package:flutter/material.dart';

abstract class BaseLanguage {
  static BaseLanguage? of(BuildContext context) => Localizations.of<BaseLanguage>(context, BaseLanguage);

  String get language;

  String get sleepableAi;

  /// WELCOME
  String get letStartFindingOutYou;

  String get haveProblemWithSleep;

  String get startQuiz;

  ///QUESTIONS & ANSWER
  String get whatTimeDidYouWakeUpToday;

  String get whatTimeDidYouGoToBedLastNight;

  String get AM;

  String get PM;

  String get howMuchSleepDoYouUsuallyGetAtNight;

  String get lessThan6Hours;

  String get a6To8Hours;

  String get a8To10hours;

  String get moreThan10Hours;

  String get howSatisfiedAreYouWithYourSleep;

  String get verySatisfied;

  String get neutral;

  String get unsatisfied;

  String get veryUnsatisfied;

  String get whatYourSleepPosition;

  String get back;

  String get side;

  String get fetal;

  String get stomach;

  String get howMuchTimeYouNeedToFallSleepInBed;

  String get aFewMinutes;

  String get a15To30Minutes;

  String get a30To45Minutes;

  String get struggleToFallAsleep;

  String get doYouWakeUpNightAndHaveTroubleGettingBackSleep;

  String get never;

  String get someTimes;

  String get prettyOften;

  String get mostNights;

  String get howOftenYouWakeUpTiredMorning;

  String get always;

  String get usually;

  String get rarely;

  String get howDarkYourBedRoomWhenSleep;

  String get completelyDark;

  String get mostlyDark;

  String get partiallyDark;

  String get bright;

  String get whichHabitHaveMayAffectYourSleepQuality;

  String get scrollingBeforeBed;

  String get havingCaffeineSfternoon;

  String get eatingLateNight;

  String get exercisingLateDay;

  String get noneAbove;

  String get doesLackSleepAffectYourDailyLife;

  String get veryMuch;

  String get someWhat;

  String get little;

  String get notAtAll;

  String get continues;

  ///  ONBOARDING SCREEN
  String get creatingYourSleepReport;

  String get sleepableAiHasProvenBestSleepingApp;

  String get accurateSleepRecorder;

  String get findOutWhatYourSleep;

  String get youSnored;

  String get youGasped;

  String get youTalked;

  String get patentedSleeptTracker;
  String get sleepableAiTechBringsExpertSleepTrackAnalysis;
  String get sleepSmarterDreamDeeper;
  String get transformSleepCuperPower;
  String get continueGoogle;
  String get continueFacebook;
  String get skipNow;
  String get wantSkipStep;
  String get skip;
  String get justSleepableSleepWell;
  String get getUnlimitedAccessSleepSoundsSleepAnalysisSnoreRecordingSmartAlarm;
  String get month;
  String get mo;
  String get dayFreeTrial;
  String get months;
  String get year;
  String get mostPopular;
  String get noPaymentNow;
  String get termsServicePrivacyPolicy;

  /// HOME
  String get h;
  String get m;
  String get untilBedtime;
  String get goodMorning;
  String get goodAfternoon;
  String get goodEvening;
  String get goodNight;
  String get whiteNoise;
  String get sleepAid;
  String get premium;
  String get dreamBot;
  String get breathwork;
  String get loading;
  String get youHadGreatNightSleepKeepItUp;
  String get lastNightSleep;
  String get totalSleep;
  String get quality;
  String get tonightGoal;
  String get targetBedtime;
  String get goal;
  String get setReminder;
  String get weeklySleepPattern;
  String get tapBarsForDetails;
  String get recentlyUpdate;
  String get featured;
  String get theBestSleepAidsYouCanMiss;
  String get sleeppedia;
  String get healingMusic;
  String get deepHealingMusicBody;
  String get sleepStory;
  String get sayGoodbyeSleeplessNightsWithSleepStory;
  String get sleepMeditation;
  String get aGuidedSleepMeditationWorriesTroublesFallAsleepFast;
  String get soundScape;
  String get ifYouWouldRelaxSoundsOutdoorsFurther;
  String get featuredRender;
  String get soundScenes;
  String get sleepSolution;
  String get sleepQuiz;
  String get dreamInterpretation;
  String get dailyQuote;
  String get seeAll;
  String get newS;
  String get sleepableAccount;
  String get createAccountKeepSafeAcrossDevicesFavoritesContents;
  String get logIn;
  String get oneTimeOfferYou;
  String get open;

  /// Accurate sleep recorder
  String get permissionRequired;
  String get pleaseAllowDisplayOverOtherAppsAlarmScreenAppear;

  /// Alram
  String get min;
  String get snooze;
  String get melodies;
  String get s;
  String get m1;
  String get t;
  String get w;
  String get t2;
  String get f;
  String get s2;
  String get sun;
  String get mon;
  String get tue;
  String get wed;
  String get thu;
  String get fri;
  String get sat;
  String get everyDay;
  String get noDaysSelected;
  String get repeat;
  String get wakeUpAlarm;
  String get onlyWorksAfterStartingSleepTracker;
  String get alarmCurrentlyOff;
  String get fadeIn;
  String get default1;
  String get haveNiceDay;
  String get wakeUp;
  String get forestStream;
  String get morningBirds;
  String get mountainBreeze;
  String get HowManyMoreMinutesSleepWouldYouLike;
  String get once;
  String get custom;

  /// bootup controll
  String get videoError;

  /// breathwork
  String get pressStartBegin;
  String get breathingExercise;
  String get exerciseCompleted;
  String get breatheIn;
  String get theBallUp;
  String get breathOut;
  String get ballDown;
  String get holdYourBreath;
  String get goldStandard;
  String get boxBreathing;
  String get slowBreathing;
  String get remainingTime;
  String get setTimer;
  String get breathworkCompleted;
  String get stepCalmerSleep;
  String get redo;
  String get howYourExperience;
  String get calmYourHeartRate;
  String get breathworkRelaxesBodyCalmsHeartRateMeasureHeartRateEffects;
  String get measureYourHeartRate;
  String get startSleep;
  String get start;
  String get resume;
  String get pause;
  String get stop;
  String get moreInformation;
  String get howExercise;
  String get step;
  String get sitComfortablePositionRelaxCompletely;
  String get pressStartStayMoment;
  String get breatheSyncOrbInhaleHoldExhale;
  String get gentlyGiveAllYourFocusYourBreath;
  String get safetyNote;
  String get consultHealthcareProfessionalMedicalConditionsAsthmaAnxietyBeforeStartingBreathworkStopFeelDizzy;
  String get gotIt;

  /// Dashboard
  String get exitApp;
  String get areYouSureYouWantCloseApp;
  String get cancel;
  String get yesExit;
  String get home;
  String get sounds;
  String get progress;
  String get profile;

  ///Dream Bot
  String get initializingDreamBot;
  String get limitReached;
  String get exception;
  String get forbidden;
  String get pageNotFound;
  String get freeUsersCanStartDreamSessionMonthUpgradePremiumUnlimitedAccess;
  String get pleaseAnalyzeDream;
  String get generateDreamImage;
  String get typeYourResponseHere;
  String get upgrade;
  String get limit;
  String get upgradePremium;
  String get analyzeMyDream;
  String get analyze;
  String get noImageAvailable;
  String get summary;
  String get emotion;
  String get keywords;
  String get dreamScenes;
  String get manifestationGuidance;
  String get interpretation;
  String get guidance;
  String get actionSteps;
  String get conversation;
  String get you;
  String get generatingYourDream;
  String get typeHere;

  ///Edit Profile
  String get success;
  String get profileUpdatedSuccessfully;
  String get error;
  String get male;
  String get myProfile;
  String get weUsePersonalizedRecommendationsCalculateYourDailyGoals;
  String get firstName;
  String get email;
  String get birthdate;
  String get gender;
  String get saving;
  String get save;
  String get selectBirthdate;
  String get female;
  String get nonBinary;
  String get camera;
  String get gallery;

  ///Heart BPM
  String get belowTargetRange;
  String get aboveTargetRange;
  String get withinTargetZone;
  String get age;
  String get targetRange;
  String get bpm;
  String get yourBpm;
  String get heartRate;
  String get measuring;
  // String get calmYourHeartRate;
  String get heartElevatedDescription;
  String get startBreathwork;
  String get fingerFlashlightInstruction;
  // String get startSleep;
  String get howToMeasure;
  String get placeFingertipOverCamera;
  String get coverLensFully;
  String get automaticMeasurementStart;
  String get keepFingerSteady;
  String get disclaimer;
  String get ppgMethodDescription;
  String get getReady;
  String get getThemMostOut;
  String get ofYourSleep;
  String get monitoringYourHeartRateBeforeSleepHelps;
  String get identifyStressLevelsImproveSleepQualityAnd;
  String get optimizeOverallHealth;
  String get measureHeartRate;
  String get startWithoutMeasuring;

  ///Home
  String get understandSleepPatterns;
  String get quickQuestions15;
  String get exploreSleepHabitsDesc;
  String get nightBreathingRestCheck;
  String get simpleQuestions12;
  String get identifyBreathingDisturbancesDesc;
  String get Key;
  String get unableToLoadGoal;
  String get bedtimeReached;
  String get syncFailedTryAgain;
  String get story;
  String get errorLoadingData;
  String get sleepDuration;
  String get hourUnit;
  String get sleepablePremium;
  String get unlockAllFeatures;
  String get dreamBotTitle;
  String get visualizeImagination;
  String get soundTherapy;
  String get calmMindWithMusic;
  String get musicLabel;
  String get storyLabel;
  String get newTag;
  String get meditationLabel;
  String get defaultQuote;
  String get defaultAuthor;

  /// Login
  String get signupApple;
  String get loginError;
  String get dreamerName;

  /// Profile
  String get profileTitle;
  String get proButton;
  String get consecutiveDays;
  String get trackedNights;
  String get trackedNights1;
  String get avgSleepTime;
  String get avgSleepTime1;
  String get avgSleepScore;
  String get avgSleepScore1;
  String get sleepTracker;
  String get sleepGoal;
  String get sleepReminder;
  String get alarm;
  String get batteryWarning;
  String get notifyLowBattery;
  String get heartRateTracker;
  String get trackHeartRate;
  String get offLabel;
  String get settingsLabel;
  String get userPlaceholder;
  String get jan;
  String get feb;
  String get mar;
  String get apr;
  String get may;
  String get jun;
  String get jul;
  String get aug;
  String get sep;
  String get oct;
  String get nov;
  String get dec;
  String get noEmail;

 /// Profile sleep
  String get bedtime;
  String get bedtimeSub;
  String get wakeUpTime;
  String get wakeUpTimeSub;
  String get errorSettingsNotLoaded;
  String get errorLabel;

  ///sleep reminder
  String get activateReminder;
  String get remindMeAt;
  String get updateFailed;

  ///progress
  String get today;
  String get week;
  String get sleepQualityAnalysis;
  String get sleepStages;
  String get sleepConsistency;
  String get snoringIntensity;
  String get keyInsights;
  String get aiInsights;
  String get achievementBadges;
  String get personalizedRecommendations;
  String get sleepRecorder;
  String get myDreams;
  String get calendar;
  String get hoursLabel;
  String get awake;
  String get dream;
  String get light;
  String get deep;
  String get bedtimeRegularity;
  String get bedtimeRegularity1;
  String get wakeTimePattern;
  String get wakeTimePattern1;
  String get avgBedtime;
  String get avgWakeTime;
  String get sleepWindowVar;
  String get averageSleepLabel;
  String get sleepQualityLabel;
  String get consistencyLabel;
  String get sleepStreakLabel;
  String get daysLabel;
  String get newDreamAnalysis;
  String get startNewJourney;
  String get proPrompt;
  String get noDataToday;
  String get noDataToday1;
  String get unlockToCheck;
  String get items;
  String get sleepableWithYou;
  String get awakeDesc;
  String get dreamDesc;
  String get lightDesc;
  String get deepDesc;
  String get optimalStatus;
  String get lowStatus;
  String get highStatus;
  String get normalStatus;
  String get noneStatus;
  String get noSnoringDataAvailableUpgradePremium;
  String get noSnoringDataAvailableToday;
  String get intensity;
  String get earlyBird;
  String get sleep;
  String get champion;
  String get wakeUpGoal;
  String get nightOwlTamer;
  String get bedtimeBeforePM;
  String get noRecommendationsYetUpgradePremiumPersonalizedSleepImprovementTips;
  String get noRecommendationsAvailableToday;
  String get duration;
  String get environment;
  String get deepSleep;
  String get quality1;
  String get day;
  String get noDataFound;
  String get retry;
  String get unlockRecordingsPrompt;
  String get noRecordingsToday;
  String get noDataLabel;
  String get noDataRecorded;
  String get congratsLabel;
  String get sleepChampion;
  String get sleepScore;
  String get sleepSpan;
  String get atmosphere;
  String get deepRecovery;
  String get restPeriod;
  String get actualRest;
  String get proInsightsPrompt;
  String get noInsightsToday;

  ///setting
  String get settings;
  String get support;
  String get account;
  String get emailSupport;
  String get privacyPolicy;
  String get termsOfService;
  String get logOut;
  String get deleteAccount;
  String get logoutTitle;
  String get logoutContent;
  String get deleteTitle;
  String get deleteContent;
  String get yesLogout;
  String get yesDelete;
  String get logoutFailed;
  String get deleteFailed;
  String get errorNoEmail;
  String get termsService;
  String get supportRequestSubject;
  String get supportEmailBody;
  String get accountDeletedLabel;
  String get accountDeletedSuccess;
  String get deleteFailedLabel;
  String get somethingWentWrong;
  String get shareSubject;

  ///sleep info
  String get youtube;
  String get noVideosFound;
  String get noticeLabel;
  String get notPlayableVideo;
  String get untitledVideo;

  ///sleep quiz
  String get understandSleepBetter;
  String get quickSimpleQuestions;
  String get builtWithSleepScience;
  String get whatYouWillGain;
  String get sleepOverviewTitle;
  String get sleepOverviewDesc;
  String get personalInsightsTitle;
  String get personalInsightsDesc;
  String get actionableGuidanceTitle;
  String get actionableGuidanceDesc;
  String get theoreticalBackground;
  String get quizTheoryDesc;
  String get viewResults;



  /// Sleeppedia Section Headers
  String get overview;
  String get definition;
  String get typesOfInsomnia;
  String get whoIsAffected;
  String get substancesAffectSleep;
  String get healthEmotionalFactors;
  String get diagnosis;
  String get treatmentApproaches;
  String get healthySleepHabits;
  String get medication;
  String get preventionTips;
  String get possibleComplications;
  String get outlook;
  String get possibleCauses;
  String get managementTips;
  String get possibleEffects;
  String get helpfulTips;
  // String get commonSigns;
  String get riskFactors;
  String get treatmentOptions;
  String get management;
  String get commonSymptoms;
  String get helpfulHabits;

  /// Sleeppedia Educational Content
  String get insomniaTitle;
  String get insomniaOverview1;
  String get insomniaOverview2;
  String get insomniaOverview3;
  String get insomniaOverview4;
  String get insomniaOverview5;
  String get insomniaDef1;
  String get insomniaDef2;
  String get insomniaTypeShort;
  String get insomniaTypeChronic;
  String get insomniaTypeOther;
  String get insomniaWho1;
  String get insomniaWho2;
  String get insomniaWho3;
  String get insomniaCause1;
  String get insomniaCause2;
  String get insomniaCause3;
  String get insomniaCause4;
  String get insomniaCause5;
  String get insomniaCause6;
  String get insomniaCause7;
  String get insomniaSubstance1;
  String get insomniaSubstance2;
  String get insomniaSubstance3;
  String get insomniaSubstance4;
  String get insomniaSubstance5;
  String get insomniaFactor1;
  String get insomniaFactor2;
  String get insomniaFactor3;
  String get insomniaFactor4;
  String get insomniaFactor5;
  String get insomniaFactor6;
  String get insomniaFactor7;
  String get insomniaSymp1;
  String get insomniaSymp2;
  String get insomniaSymp3;
  String get insomniaSymp4;
  String get insomniaSymp5;
  String get insomniaSymp6;
  String get insomniaDiag1;
  String get insomniaDiag2;
  String get insomniaDiag3;
  String get insomniaDiag4;
  String get insomniaTreat1;
  String get insomniaTreat2;
  String get insomniaTreat3;
  String get insomniaHabit1;
  String get insomniaHabit2;
  String get insomniaHabit3;
  String get insomniaHabit4;
  String get insomniaHabit5;
  String get insomniaHabit6;
  String get insomniaMed1;
  String get insomniaMed2;
  String get insomniaPrev1;
  String get insomniaPrev2;
  String get insomniaPrev3;
  String get insomniaPrev4;
  String get insomniaPrev5;
  String get insomniaComp1;
  String get insomniaComp2;
  String get insomniaComp3;
  String get insomniaComp4;
  String get insomniaComp5;
  String get insomniaOutlook1;
  String get insomniaOutlook2;
  String get insomniaOutlook3;
  String get hypersomniaTitle;
  String get hypersomniaOverview1;
  String get hypersomniaOverview2;
  String get hypersomniaCause1;
  String get hypersomniaCause2;
  String get hypersomniaCause3;
  String get hypersomniaCause4;
  String get hypersomniaSymp1;
  String get hypersomniaSymp2;
  String get hypersomniaSymp3;
  String get hypersomniaSymp4;
  String get hypersomniaTip1;
  String get hypersomniaTip2;
  String get hypersomniaTip3;
  String get hypersomniaTip4;
  String get snoringTitle;
  String get snoringOverview1;
  String get snoringOverview2;
  String get snoringCause1;
  String get snoringCause2;
  String get snoringCause3;
  String get snoringCause4;
  String get snoringEffect1;
  String get snoringEffect2;
  String get snoringEffect3;
  String get snoringTip1;
  String get snoringTip2;
  String get snoringTip3;
  String get snoringTip4;
  String get breathingPausesTitle;
  String get apneaOverview1;
  String get apneaOverview2;
  String get apneaSign1;
  String get apneaSign2;
  String get apneaSign3;
  String get apneaSign4;
  String get apneaRisk1;
  String get apneaRisk2;
  String get apneaRisk3;
  String get apneaRisk4;
  String get apneaTreat1;
  String get apneaTreat2;
  String get apneaTreat3;
  String get apneaTreat4;
  String get bruxismTitle;
  String get bruxismOverview1;
  String get bruxismOverview2;
  String get bruxismCause1;
  String get bruxismCause2;
  String get bruxismCause3;
  String get bruxismCause4;
  String get bruxismSymp1;
  String get bruxismSymp2;
  String get bruxismSymp3;
  String get bruxismSymp4;
  String get bruxismManage1;
  String get bruxismManage2;
  String get bruxismManage3;
  String get bruxismManage4;
  String get rlsOverview1;
  String get rlsOverview2;
  String get rlsSymp1;
  String get rlsSymp2;
  String get rlsSymp3;
  String get rlsSymp4;
  String get rlsCause1;
  String get rlsCause2;
  String get rlsCause3;
  String get rlsCause4;
  String get rlsHabit1;
  String get rlsHabit2;
  String get rlsHabit3;
  String get rlsHabit4;
  String get palpitationsTitle;
  String get palpOverview1;
  String get palpOverview2;
  String get palpCause1;
  String get palpCause2;
  String get palpCause3;
  String get palpCause4;
  String get palpSymp1;
  String get palpSymp2;
  String get palpSymp3;
  String get palpSymp4;
  String get palpTip1;
  String get palpTip2;
  String get palpTip3;
  String get palpTip4;
  String get restlessLegTitle;
  String get commonCauses;
  String get symptoms;

  /// quiz
  String get finish;
  String get next;
  String get previous;
  String get yesLabel;
  String get noLabel;
  String get qSnoring;
  String get qMorningHeadache;
  String get qGaspingAir;
  String get qBreathingPauses;
  String get qSleepyDriving;
  String get qDryMouth;
  String get qIrritable;
  String get qLowStamina;
  String get qChestDiscomfort;
  String get qDaytimeSleepiness;
  String get qBloodPressure;
  String get qNasalBreathing;
  String get qDifficultySleep;
  String get qNightAwakenings;
  String get qDaytimeFatigue;
  String get qSleepMedication;
  String get qEveningAlcohol;
  String get qSleepAnxiety;
  String get qLateSchedule;
  String get qMedicalConditions;
  String get qExcessWeight;
  String get results;
  String get disorder;
  String get resultDetails;
  String get suggestions;
  String get backToHome;
  String get errorNoQuizData;
  String get errorGenerateResult;
  String get errorNetwork;

  ///sound
  String get maxSoundsLimit;
  String get errorFavUpdate;
  String get duplicateMixName;
  String get duplicateMixContent;
  String get mixMinSoundsError;
  String get mixSavedSuccess;
  String get nowPlaying;
  String get ambientPlaying;
  String get soundPlaying;
  String get sleepTrackingActive;
  String get timerHitZero;
  String get duplicateNameTitle;
  String get duplicateMixTitle;
  String get cannotSaveTitle;
  String get mixSaved;
  String get sleepSounds;
  String get noMixesFound;
  String get noSoundsFound;
  String get timerSubTitle;
  String get timerQuestion;
  String get resetTimer;

  ///SleepTracker
  String get serviceTitle;
  String get serviceText;
  String get calibratingSensors;
  String get noTimeSet;
  String get errorTrackerStop;
  String get batteryWarningTitle;
  String get batteryWarningText;
  String get startingSleepTracker;
  String get keepChargerConnected;
  String get ambientNoise;
  String get alarmOff;
  String get preventShutdown;
  String get connectCharger;
  String get noMixAdded;
  String get quit;
  String get keepTracking;
  String get quitNow;
  String get notBedtimeYet;
  String get sleepableWillRemind;
  String get notNow;

  /// Rating
  String get ratingTitle;
  String get ratingStep1Desc;
  String get ratingStep2Desc;
  String get theBest;
  String get goRating;
  String get maybeLater;

  /// premium
  String get luckySpinOffer;
  String get specialDiscountApplied;
  String get seizeNow;
  String get cancelAnytime;
  String get termsAndPrivacy;
  String get noPaymentDue;
  String get noCommitment;
  String get bestDeal;
  String get trySleepableFree;
  String get trySleepableFree1;
  String get spinUnlockTitle;
  String get spinUnlockTitle1;
  String get congratsUnlock;
  String get spinNow;
  String get claimDiscount;
  String get oneTimeOffer;
  String get freeTrialReminder;
  String get continueFree;
  String get startTrialToContinue;
  String get startFreeTrial;
  String get just;
  String get perYear;
  String get perWeek;
  String get only;
  String get total;
  String get termsApply;
  String get googleIdCharge;
  String get cancelStore;
  String get btnTryFree;
  String get btnGetForZero;
  String get btnStartTrial;
  String get btnUnlockAccess;
  String get goodLuck;
  String get connectionError;
  String get tryAgainLater;
  String get congrats;
  String get unlocked;
  String get spinning;
  String get off;
  String get discountUnlocked;
  String get oneTimeOfferTitle;
  String get offForever;
  String get featureSleep;
  String get featureSounds;
  String get featureAnalytics;
  String get yearlyPremium;
  String get continueYearly;
  String get continueWeekly;
  String get remindPart1;
  String get remindPart2;
  String get remindPart3;
  String get remindPart4;
  String get unlockSleepableTitle;
  String get startJourney;
  String get threeDaysFreeBadge;
  String get threeDaysFreeThen;
  String get in2Days;
  String get trialEndingReminder;
  String get in3Days;
  String get billingStartsNote;
  String get easySleepTracking;
  String get trackCyclesAuto;
  String get wakeUpRefreshed;
  String get keepItSimple;
  String get trackProgress;
  String get smartReminders;
  String get weekly;
  String get yearly;
  String get tlToday;
  String get tlTodaySub;
  String get tlReminder;
  String get tlReminderSub;
  String get tlBilling;
  String get tlBillingSub;
  String get appSettings;

  /// bottom sheet
  String get welcomeToTheMost;
  String get advancedSleepTracker;
  String get knowAboutSleepPatterns;
  String get gainInsightOfYourSleep;
  String get monitorTalkingAndSnoring;
  String get trackSleepSounds;
  String get smartSleepAnalysis;
  String get improveSleepEfficiency;
  String get placeTheDeviceAsPicture;
  String get pleasePlacePhoneNextBedKeepChargerConnected;
  String get setYourWakeUpTime;
  String get trySleepNote;
  String get sleepNoteEasyRevealFactorsGoodNightsRest;
  String get done;
  String get dontShowAgain;
  String get addSleepNote;
  String get others;
  String get describeYourDay;
  String get sleepNoteHintText;
  String get add;
  String get deleteNote;
  String get areSureWantDeleteNote;
  String get thisActionCannotUndone;
  String get failedDeleteNote;
  String get edit;
  String get tag;
  String get enterTagName;
  String get sleepNoteAddedSuccessfully;
  String get oK;
  String get update;
  String get setSleepTimer;
  String get soundList;
  String get noItemsFound;
  String get storyteller;
  String get relaxingMelody;
  String get relaxYourBody;
  String get unknownArtist;
  String get spinToUnlockAn;
  String get exclusiveDiscount;
  String get gift;
  String get noLuck;
}
