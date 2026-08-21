import 'dart:io';

import 'languages.dart';

class LanguagePt extends BaseLanguage {
  @override
  String get language => 'Linguagem';

  @override
  String get sleepableAi => 'IA adormecida';

  /// WELCOME
  @override
  String get letStartFindingOutYou => 'Vamos começar descobrindo se você';

  @override
  String get haveProblemWithSleep => 'Tenho problemas para dormir.';

  @override
  String get startQuiz => 'Iniciar Questionário';

  ///QUESTIONS & ANSWER
  @override
  String get whatTimeDidYouWakeUpToday => 'A que horas você acordou hoje?';

  @override
  String get whatTimeDidYouGoToBedLastNight => 'A que horas você foi dormir ontem à noite?';

  @override
  String get AM => 'SOU';

  @override
  String get PM => 'PM';

  @override
  String get howMuchSleepDoYouUsuallyGetAtNight => 'Quantas horas de sono você costuma ter à noite?';

  @override
  String get lessThan6Hours => 'Menos de 6 horas';

  @override
  String get a6To8Hours => '6 a 8 horas';

  @override
  String get a8To10hours => '8 a 10 horas';

  @override
  String get moreThan10Hours => 'Mais de 10 horas';

  @override
  String get howSatisfiedAreYouWithYourSleep => 'Quão satisfeito(a) você está com seu sono?';

  @override
  String get verySatisfied => 'Muito satisfeito';

  @override
  String get neutral => 'Neutro';

  @override
  String get unsatisfied => 'Insatisfeito';

  @override
  String get veryUnsatisfied => 'Muito insatisfeito';

  @override
  String get whatYourSleepPosition => 'Qual é a sua posição para dormir?';

  @override
  String get back => 'Voltar';

  @override
  String get side => 'Lado';

  @override
  String get fetal => 'Fetal';

  @override
  String get stomach => 'Estômago';

  @override
  String get howMuchTimeYouNeedToFallSleepInBed => 'Quanto tempo você precisa para adormecer na cama?';

  @override
  String get aFewMinutes => 'Alguns minutos';

  @override
  String get a15To30Minutes => '15 a 30 minutos';

  @override
  String get a30To45Minutes => '30 a 45 minutos';

  @override
  String get struggleToFallAsleep => 'Tenho dificuldade para adormecer.';

  @override
  String get doYouWakeUpNightAndHaveTroubleGettingBackSleep => 'Você acorda à noite e tem dificuldade para voltar a dormir?';

  @override
  String get never => 'Nunca';

  @override
  String get someTimes => 'Às vezes';

  @override
  String get prettyOften => 'Com bastante frequência';

  @override
  String get mostNights => 'Na maioria das noites';

  @override
  String get howOftenYouWakeUpTiredMorning => 'Com que frequência você acorda cansado pela manhã?';

  @override
  String get always => 'Sempre';

  @override
  String get usually => 'Geralmente';

  @override
  String get rarely => 'Raramente';

  @override
  String get howDarkYourBedRoomWhenSleep => 'Quão escuro fica seu quarto quando você dorme?';

  @override
  String get completelyDark => 'Completamente escuro';

  @override
  String get mostlyDark => 'Predominantemente escuro';

  @override
  String get partiallyDark => 'Parcialmente escuro';

  @override
  String get bright => 'Brilhante';

  @override
  String get whichHabitHaveMayAffectYourSleepQuality => 'Que hábito você tem que pode afetar a qualidade do seu sono?';

  @override
  String get scrollingBeforeBed => 'Rolar a tela antes de dormir';

  @override
  String get havingCaffeineSfternoon => 'Tomar cafeína à tarde.';

  @override
  String get eatingLateNight => 'Comer tarde da noite';

  @override
  String get exercisingLateDay => 'Fazer exercício físico no final do dia';

  @override
  String get noneAbove => 'Nenhuma das acima';

  @override
  String get doesLackSleepAffectYourDailyLife => 'A falta de sono afeta sua vida diária?';

  @override
  String get veryMuch => 'Muito';

  @override
  String get someWhat => 'De alguma forma';

  @override
  String get little => 'Pequeno';

  @override
  String get notAtAll => 'De jeito nenhum';

  @override
  String get continues => 'Continuar';

  ///  ONBOARDING SCREEN
  @override
  String get creatingYourSleepReport => 'Criando seu relatório de sono';

  @override
  String get sleepableAiHasProvenBestSleepingApp => 'Sleepable.ai provou ser o melhor aplicativo para dormir.';

  @override
  String get accurateSleepRecorder => 'Gravador de sono preciso';

  @override
  String get findOutWhatYourSleep => 'Descubra o que você fez enquanto dormia!';
  @override
  String get youSnored => 'Você roncou';
  @override
  String get youGasped => 'Você ficou boquiaberto(a).';
  @override
  String get youTalked => 'Você falou';
  @override
  String get patentedSleeptTracker => 'Monitoramento de sono patenteado';
  @override
  String get sleepableAiTechBringsExpertSleepTrackAnalysis => 'A tecnologia Sleepable.ai oferece monitoramento e análise do sono por especialistas.';
  @override
  String get sleepSmarterDreamDeeper => 'Durma melhor. Sonhe melhor.';
  @override
  String get transformSleepCuperPower => 'Transforme o sono em seu superpoder.';
  @override
  String get continueGoogle => 'Continuar com o Google';
  @override
  String get continueFacebook => 'Continuar com o Facebook';
  @override
  String get skipNow => 'Por enquanto, pule esta etapa.';
  @override
  String get wantSkipStep => 'Deseja pular esta etapa?';
  @override
  String get skip => 'Pular';
  @override
  String get justSleepableSleepWell => 'Apenas consiga dormir bem e durma bem.';
  @override
  String get getUnlimitedAccessSleepSoundsSleepAnalysisSnoreRecordingSmartAlarm => 'Obtenha acesso ilimitado a todos os sons para dormir, além de análise do sono, gravação de ronco e alarme inteligente.';
  @override
  String get month => 'Mês';
  @override
  String get mo => 'mo';
  @override
  String get dayFreeTrial => 'Teste grátis por 7 dias';
  @override
  String get months => 'MESES';
  @override
  String get year => 'ano';
  @override
  String get mostPopular => 'Mais populares';
  @override
  String get noPaymentNow => 'Sem pagamento agora!';
  @override
  String get termsServicePrivacyPolicy => Platform.isIOS
      ? 'Termos de serviço e Política de privacidade. Observação: após o período de teste gratuito de 7 dias, sua forma de pagamento da Apple será cobrada automaticamente por um ano. Você pode cancelar a assinatura antes do término do período de teste gratuito para evitar a cobrança. Se tiver dúvidas sobre como cancelar ou gerenciar sua assinatura, visite nossa Central de Ajuda ou a App Store.'
      : 'Termos de serviço e Política de privacidade. Observação: após o período de teste gratuito de 7 dias, sua forma de pagamento do Google será cobrada automaticamente por um ano. Você pode cancelar a assinatura antes do término do período de teste gratuito para evitar a cobrança. Se tiver dúvidas sobre como cancelar ou gerenciar sua assinatura, visite nossa Central de Ajuda ou a página do Google Play.';

/// HOME
  @override
  String get h => 'h';
  @override
  String get m => 'm';
  @override
  String get untilBedtime => 'até a hora de dormir';
  @override
  String get goodMorning => 'Bom dia';
  @override
  String get goodAfternoon => 'Boa tarde';
  @override
  String get goodEvening => 'Boa noite';
  @override
  String get goodNight => 'Boa noite';
  @override
  String get whiteNoise => 'Ruído branco';
  @override
  String get sleepAid => 'Auxílio para dormir';
  @override
  String get premium => 'Premium';
  @override
  String get dreamBot => 'Robô dos Sonhos';
  @override
  String get breathwork => 'Exercícios de respiração';
  @override
  String get loading => 'Carregando...';
  @override
  String get youHadGreatNightSleepKeepItUp => 'Você dormiu muito bem! Continue assim.';
  @override
  String get lastNightSleep => 'O sono da noite passada';
  @override
  String get totalSleep => 'Sono Total';



  @override
  String get quality => 'Qualidade';
  @override
  String get tonightGoal => 'Objetivo de hoje à noite';
  @override
  String get targetBedtime => 'Hora de dormir da Target';
  @override
  String get goal => 'meta';
  @override
  String get setReminder => 'Definir lembrete';
  @override
  String get weeklySleepPattern => 'Padrão de sono semanal';
  @override
  String get tapBarsForDetails => 'Toque nas barras para obter detalhes.';
  @override
  String get recentlyUpdate => 'Atualização recente';
  @override
  String get featured => 'Apresentou';
  @override
  String get theBestSleepAidsYouCanMiss => 'Os melhores auxiliares para dormir que você não pode perder!';
  @override
  String get sleeppedia => 'Sleeppedia';
  @override
  String get healingMusic => 'Música de cura';
  @override
  String get deepHealingMusicBody => 'Música de cura profunda para o corpo.';
  @override
  String get sleepStory => 'História para dormir';
  @override
  String get sayGoodbyeSleeplessNightsWithSleepStory => 'Diga adeus às noites em claro com uma história para dormir.';
  @override
  String get sleepMeditation => 'Meditação para dormir';
  @override
  String get aGuidedSleepMeditationWorriesTroublesFallAsleepFast => 'Uma meditação guiada para dormir, que ajuda a se livrar de preocupações e problemas e a adormecer rapidamente.';
  @override
  String get soundScape => 'Paisagem sonora';
  @override
  String get ifYouWouldRelaxSoundsOutdoorsFurther => 'Se você deseja relaxar ao som da natureza, não precisa procurar mais.';
  @override
  String get featuredRender => 'Renderização em destaque';
  @override
  String get soundScenes => 'Cenas sonoras';
  @override
  String get sleepSolution => 'Solução para dormir';
  @override
  String get sleepQuiz => 'Teste do Sono';
  @override
  String get dreamInterpretation => 'Interpretação de Sonhos';
  @override
  String get dailyQuote => 'Citação diária';
  @override
  String get seeAll => 'Ver tudo';
  @override
  String get newS => 'NOVO';
  @override
  String get sleepableAccount => 'Conta que permite dormir';
  @override
  String get createAccountKeepSafeAcrossDevicesFavoritesContents => 'Crie uma conta para manter seus dados seguros em todos os dispositivos e acessar todo o seu conteúdo favorito.';
  @override
  String get logIn => 'Conecte-se';
  @override
  String get oneTimeOfferYou => 'Oferta única para você...';
  @override
  String get open => 'Abrir';
  @override
  String get permissionRequired => 'É necessária autorização.';
  @override
  String get pleaseAllowDisplayOverOtherAppsAlarmScreenAppear => 'Por favor, permita a opção ""Exibir sobre outros aplicativos"" para que a tela do alarme possa aparecer.';
  @override
  String get min => 'min';
  @override
  String get snooze => 'Soneca';
  @override
  String get melodies => 'Melodias';
  @override
  String get s => 'S';
  @override
  String get m1 => 'M';
  @override
  String get t => 'T';
  @override
  String get w => 'C';
  @override
  String get t2 => 'T';
  @override
  String get f => 'F';
  @override
  String get s2 => 'S';
  @override
  String get sun => 'Sol';
  @override
  String get mon => 'seg';
  @override
  String get tue => 'ter';
  @override
  String get wed => 'qua';
  @override
  String get thu => 'qui';
  @override
  String get fri => 'sex';
  @override
  String get sat => 'Sentado';
  @override
  String get everyDay => 'Diariamente';
  @override
  String get noDaysSelected => 'Nenhum dia selecionado';
  @override
  String get repeat => 'Repita';
  @override
  String get wakeUpAlarm => 'Alarme de despertar';
  @override
  String get onlyWorksAfterStartingSleepTracker => 'Só funciona depois de iniciar o monitor de sono.';
  @override
  String get alarmCurrentlyOff => 'O alarme está desativado.';
  @override
  String get fadeIn => 'Entrada gradual';
  @override
  String get haveNiceDay => 'Tenha um bom dia!';
  @override
  String get wakeUp => 'Acordar';
  @override
  String get forestStream => 'Riacho da Floresta';
  @override
  String get morningBirds => 'Pássaros da manhã';
  @override
  String get mountainBreeze => 'Brisa da montanha';
  @override
  String get HowManyMoreMinutesSleepWouldYouLike => 'Quantos minutos a mais de sono você gostaria de ter?';
  @override
  String get once => 'Uma vez';
  @override
  String get custom => 'Personalizado';
  @override
  String get videoError => 'Erro de vídeo';
  @override
  String get pressStartBegin => 'Pressione Iniciar para começar';
  @override
  String get breathingExercise => 'exercício de respiração';
  @override
  String get exerciseCompleted => 'Exercício concluído';
  @override
  String get breatheIn => 'Inspire quando';
  @override
  String get theBallUp => 'a bola sobe';
  @override
  String get breathOut => 'Expire quando';
  @override
  String get ballDown => 'a bola cai';
  @override
  String get holdYourBreath => 'Prenda a respiração';
  @override
  String get goldStandard => 'Padrão Ouro (4–7–8)';
  @override
  String get boxBreathing => 'Respiração quadrada (4-4-4-4)';
  @override
  String get slowBreathing => 'Respiração lenta (6-0-8)';
  @override
  String get remainingTime => 'Tempo restante';
  @override
  String get setTimer => 'Definir temporizador';
  @override
  String get breathworkCompleted => 'Exercício de respiração concluído!';
  @override
  String get stepCalmerSleep => 'Isso é um passo em direção a um sono mais tranquilo.';
  @override
  String get redo => 'Refazer';
  @override
  String get howYourExperience => 'Como foi sua experiência?';
  @override
  String get calmYourHeartRate => 'Acalme seus batimentos cardíacos';
  @override
  String get breathworkRelaxesBodyCalmsHeartRateMeasureHeartRateEffects => 'Exercícios de respiração relaxam o corpo e acalmam os batimentos cardíacos. Meça sua frequência cardíaca para observar os efeitos.';
  @override
  String get measureYourHeartRate => 'Meça sua frequência cardíaca';
  @override
  String get start => 'Começar';
  @override
  String get resume => 'Retomar';
  @override
  String get pause => 'Pausa';
  @override
  String get stop => 'Parar';
  @override
  String get moreInformation => 'Mais informações';
  @override
  String get howExercise => 'Como se exercitar?';
  @override
  String get step => 'Etapa';
  @override
  String get sitComfortablePositionRelaxCompletely => 'Sente-se numa posição confortável e relaxe completamente.';
  @override
  String get pressStartStayMoment => 'Pressione ""Iniciar"" e aproveite o momento.';
  @override
  String get breatheSyncOrbInhaleHoldExhale => 'Respire em sincronia com a esfera; inspire, segure a respiração, expire.';
  @override
  String get gentlyGiveAllYourFocusYourBreath => 'Delicadamente, concentre-se totalmente na sua respiração.';
  @override
  String get safetyNote => 'Nota de segurança';
  @override
  String get consultHealthcareProfessionalMedicalConditionsAsthmaAnxietyBeforeStartingBreathworkStopFeelDizzy => 'Consulte um profissional de saúde se você tiver problemas médicos como asma ou ansiedade antes de iniciar os exercícios respiratórios. Pare se sentir tontura.';
  @override
  String get gotIt => 'Entendi';
  @override
  String get exitApp => 'Sair do aplicativo?';
  @override
  String get areYouSureYouWantCloseApp => 'Tem certeza de que deseja fechar o aplicativo?';
  @override
  String get cancel => 'Cancelar';
  @override
  String get yesExit => 'Sim, sair';
  @override
  String get home => 'Lar';
  @override
  String get sounds => 'Sons';
  @override
  String get progress => 'Progresso';
  @override
  String get profile => 'Perfil';
  @override
  String get initializingDreamBot => 'Inicializando o DreamBot...';
  @override
  String get limitReached => 'Limite atingido.';
  @override
  String get exception => 'Exceção';
  @override
  String get forbidden => 'proibido';
  @override
  String get pageNotFound => 'Página não encontrada';
  @override
  String get freeUsersCanStartDreamSessionMonthUpgradePremiumUnlimitedAccess => 'Usuários gratuitos podem iniciar 1 sessão de sonhos por mês. Atualize para a versão premium para acesso ilimitado.';
  @override
  String get pleaseAnalyzeDream => 'Por favor, analise este sonho.';
  @override
  String get generateDreamImage => 'Gerar imagem de sonho';
  @override
  String get typeYourResponseHere => 'Digite sua resposta aqui...';
  @override
  String get upgrade => 'atualizar';
  @override
  String get limit => 'limite';
  @override
  String get upgradePremium => 'Faça upgrade para Premium';
  @override
  String get analyzeMyDream => 'Analise meu sonho';
  @override
  String get analyze => 'Analisar';
  @override
  String get noImageAvailable => 'Nenhuma imagem disponível';
  @override
  String get summary => 'Resumo';
  @override
  String get emotion => 'Emoção';
  @override
  String get keywords => 'Palavras-chave';
  @override
  String get dreamScenes => 'Cenas de sonho';
  @override
  String get manifestationGuidance => 'Orientação para Manifestação';
  @override
  String get interpretation => 'Interpretação';
  @override
  String get guidance => 'Orientação';
  @override
  String get actionSteps => 'Passos a seguir';
  @override
  String get conversation => 'Conversa';
  @override
  String get you => 'Você';
  @override
  String get generatingYourDream => 'Gerando o seu sonho...';
  @override
  String get typeHere => 'Digite aqui...';
  @override
  String get success => 'Sucesso';
  @override
  String get profileUpdatedSuccessfully => 'Perfil atualizado com sucesso';
  @override
  String get error => 'Erro';
  @override
  String get male => 'Macho';
  @override
  String get myProfile => 'Meu perfil';
  @override
  String get weUsePersonalizedRecommendationsCalculateYourDailyGoals => 'Usamos esses dados para fornecer recomendações personalizadas e calcular suas metas diárias.';
  @override
  String get firstName => 'Primeiro nome';
  @override
  String get email => 'E-mail';
  @override
  String get birthdate => 'data de nascimento';
  @override
  String get gender => 'Gênero';
  @override
  String get saving => 'Salvando...';
  @override
  String get save => 'Salvar';
  @override
  String get selectBirthdate => 'Selecione a data de nascimento';
  @override
  String get female => 'Fêmea';
  @override
  String get nonBinary => 'Não binário';
  @override
  String get camera => 'Câmera';
  @override
  String get gallery => 'Galeria';
  @override
  String get belowTargetRange => 'Abaixo da meta estabelecida.';
  @override
  String get aboveTargetRange => 'Acima da meta estabelecida.';
  @override
  String get withinTargetZone => 'Dentro da zona alvo.';
  @override
  String get age => 'Idade';
  @override
  String get targetRange => 'Alcance do alvo';
  @override
  String get bpm => 'bpm';
  @override
  String get yourBpm => 'Seu BPM';
  @override
  String get heartRate => 'Frequência cardíaca';
  @override
  String get measuring => 'Medindo...';
  @override
  String get heartElevatedDescription => 'Seu coração está acelerado. Vamos desacelerá-lo com respirações suaves para preparar seu corpo para o sono.';
  @override
  String get startBreathwork => 'Comece a praticar exercícios de respiração.';
  @override
  String get fingerFlashlightInstruction => 'Coloque o dedo no interruptor da lanterna e cubra a câmera traseira.';
  @override
  String get startSleep => 'Comece a dormir';
  @override
  String get howToMeasure => 'Como medir?';
  @override
  String get placeFingertipOverCamera => 'Coloque a ponta do dedo sobre a câmera traseira.';
  @override
  String get coverLensFully => 'Certifique-se de que seu dedo cubra completamente a lente.';
  @override
  String get automaticMeasurementStart => 'A medição começará automaticamente se sua mão estiver posicionada corretamente.';
  @override
  String get keepFingerSteady => 'Mantenha o dedo firme até que o processo termine.';
  @override
  String get disclaimer => 'Isenção de responsabilidade';
  @override
  String get ppgMethodDescription => 'Esta função utiliza o método PPG para estimar sua frequência cardíaca e VFC (variabilidade da frequência cardíaca). Ela foi projetada para bem-estar geral e não se destina a uso médico.';
  @override
  String get getReady => 'Prepare-se';
  @override
  String get getThemMostOut => 'Tire o máximo proveito';
  @override
  String get ofYourSleep => 'do seu sono';
  @override
  String get monitoringYourHeartRateBeforeSleepHelps => 'Monitorar sua frequência cardíaca antes de dormir ajuda';
  @override
  String get identifyStressLevelsImproveSleepQualityAnd => 'Identificar os níveis de estresse, melhorar a qualidade do sono e';
  @override
  String get optimizeOverallHealth => 'Otimizar a saúde geral.';
  @override
  String get measureHeartRate => 'Medir a frequência cardíaca';
  @override
  String get startWithoutMeasuring => 'Comece sem medir';
  @override
  String get understandSleepPatterns => 'Entenda seus padrões de sono';
  @override
  String get quickQuestions15 => '15 perguntas rápidas';
  @override
  String get exploreSleepHabitsDesc => 'Analise seus hábitos de sono, níveis de energia diários e qualidade do descanso por meio de uma breve avaliação.';
  @override
  String get nightBreathingRestCheck => 'Verificação da respiração e do descanso noturno';
  @override
  String get simpleQuestions12 => '12 perguntas simples';
  @override
  String get identifyBreathingDisturbancesDesc => 'Identificar possíveis distúrbios do sono relacionados à respiração.';
  @override
  String get Key => 'Valor';
  @override
  String get unableToLoadGoal => 'Não foi possível carregar o objetivo';
  @override
  String get bedtimeReached => 'Chegou a hora de dormir.';
  @override
  String get syncFailedTryAgain => 'A sincronização falhou. Tente novamente.';
  @override
  String get story => 'História';
  @override
  String get errorLoadingData => 'Erro ao carregar os dados';
  @override
  String get sleepDuration => 'Duração do sono';
  @override
  String get hourUnit => 'h';
  @override
  String get sleepablePremium => 'Premium para dormir';
  @override
  String get unlockAllFeatures => 'Desbloqueie todas as funcionalidades';
  @override
  String get dreamBotTitle => 'Robô dos Sonhos';
  @override
  String get visualizeImagination => 'Visualize sua imaginação.';
  @override
  String get soundTherapy => 'Terapia sonora';
  @override
  String get calmMindWithMusic => 'Acalme sua mente com música.';
  @override
  String get musicLabel => 'Música';
  @override
  String get storyLabel => 'História';
  @override
  String get newTag => 'NOVO';
  @override
  String get meditationLabel => 'Meditação';
  @override
  String get defaultQuote => 'Algumas pessoas falam enquanto dormem.\nPalestrantes falam enquanto outras pessoas dormem.';
  @override
  String get defaultAuthor => 'Albert Camus';
  @override
  String get signupApple => 'Cadastre-se na Apple';
  @override
  String get loginError => 'Erro de login';
  @override
  String get dreamerName => 'Sonhador';
  @override
  String get profileTitle => 'Perfil';
  @override
  String get proButton => 'PRÓ';
  @override
  String get consecutiveDays => 'Dias consecutivos';
  // @override
  // String get trackedNights => 'Noites rastreadas';
  // @override
  // String get avgSleepTime => 'Tempo médio de sono';
  // @override
  // String get avgSleepScore => 'Pontuação média do sono';
  @override
  String get trackedNights => 'Rastreado';
  @override
  String get trackedNights1 => 'Noites';
  @override
  String get avgSleepTime => 'Média';
  @override
  String get avgSleepTime1 => 'Hora de dormir';
  @override
  String get avgSleepScore => 'Média';
  @override
  String get avgSleepScore1 => 'Pontuação do sono';
  @override
  String get sleepTracker => 'Monitorador de sono';
  @override
  String get sleepGoal => 'Meta de sono';
  @override
  String get sleepReminder => 'Lembrete para dormir';
  @override
  String get alarm => 'Alarme';
  @override
  String get batteryWarning => 'Aviso de bateria';
  @override
  String get notifyLowBattery => 'Notifique quando a bateria estiver fraca.';
  @override
  String get heartRateTracker => 'Monitor de frequência cardíaca';
  @override
  String get trackHeartRate => 'Monitore sua frequência cardíaca antes de dormir.';
  @override
  String get offLabel => 'Desligado';
  @override
  String get settingsLabel => 'Configurações';
  @override
  String get userPlaceholder => 'Usuário';
  @override
  String get jan => 'janeiro';
  @override
  String get feb => 'fevereiro';
  @override
  String get mar => 'Mar';
  @override
  String get apr => 'abril';
  @override
  String get may => 'Poderia';
  @override
  String get jun => 'junho';
  @override
  String get jul => 'julho';
  @override
  String get aug => 'agosto';
  @override
  String get sep => 'Setembro';
  @override
  String get oct => 'Outubro';
  @override
  String get nov => 'novembro';
  @override
  String get dec => 'Dezembro';
  @override
  String get noEmail => 'no-email@app.com';
  @override
  String get bedtime => 'Hora de dormir';
  @override
  String get bedtimeSub => 'A hora em que você vai dormir.';
  @override
  String get wakeUpTime => 'Hora de acordar';
  @override
  String get wakeUpTimeSub => 'A hora em que você acorda';
  @override
  String get errorSettingsNotLoaded => 'As configurações existentes ainda não foram carregadas.';
  @override
  String get errorLabel => 'Erro';
  @override
  String get activateReminder => 'Ativar lembrete de sono';
  @override
  String get remindMeAt => 'Lembre-me em';
  @override
  String get updateFailed => 'A atualização falhou. Verifique sua conexão com a internet.';
  @override
  String get today => 'Hoje';
  @override
  String get week => 'Semana';
  @override
  String get sleepQualityAnalysis => 'Análise da Qualidade do Sono';
  @override
  String get sleepStages => 'Estágios do sono';
  @override
  String get sleepConsistency => 'Regularidade do sono';
  @override
  String get snoringIntensity => 'Intensidade do ronco';
  @override
  String get keyInsights => 'Principais conclusões';
  @override
  String get aiInsights => 'Análises de IA';
  @override
  String get achievementBadges => 'Distintivos de Conquista';
  @override
  String get personalizedRecommendations => 'Recomendações personalizadas';
  @override
  String get sleepRecorder => 'Gravador de sono';
  @override
  String get myDreams => 'Meus sonhos';
  @override
  String get calendar => 'Calendário';
  @override
  String get hoursLabel => 'Horas';
  @override
  String get awake => 'Acordado';
  @override
  String get dream => 'Sonhar';
  @override
  String get light => 'Luz';
  @override
  String get deep => 'Profundo';
  @override
  String get bedtimeRegularity => 'Hora de dormir';
  @override
  String get bedtimeRegularity1 => 'Regularidade';
  @override
  String get wakeTimePattern => 'Hora de acordar';
  @override
  String get wakeTimePattern1 => 'Padrão';
  @override
  String get avgBedtime => 'Horário médio de dormir';
  @override
  String get avgWakeTime => 'Tempo médio de vigília';
  @override
  String get sleepWindowVar => 'Variação da janela de sono';
  @override
  String get averageSleepLabel => 'Sono médio';
  @override
  String get sleepQualityLabel => 'Qualidade do sono';
  @override
  String get consistencyLabel => 'Consistência';
  @override
  String get sleepStreakLabel => 'Sequência de sono';
  @override
  String get daysLabel => 'dias';
  @override
  String get newDreamAnalysis => 'Nova Análise de Sonhos';
  @override
  String get startNewJourney => 'Comece uma nova jornada';
  @override
  String get proPrompt => 'Ainda não há dados sobre o seu sono. Desbloqueie análises detalhadas e insights de IA com o Sleepable Premium ✨';
  @override
  String get noDataToday => 'Ainda não há dados de sono para hoje.';
  @override
  String get noDataToday1 => 'Comece a monitorar seu sono hoje à noite!';
  @override
  String get unlockToCheck => 'Desbloqueie para verificar';
  @override
  String get items => 'Unid';
  @override
  String get sleepableWithYou => 'Sleepable está com você há';
  @override
  String get awakeDesc => 'Despertares curtos são naturais e muitas vezes passam despercebidos.';
  @override
  String get dreamDesc => 'O sono REM é o período em que a maioria dos sonhos ocorre.';
  @override
  String get lightDesc => 'O sono leve é ​​a fase de transição.';
  @override
  String get deepDesc => 'O sono profundo é crucial para a recuperação física.';
  @override
  String get optimalStatus => 'Ótimo';
  @override
  String get lowStatus => 'Baixo';
  @override
  String get highStatus => 'Alto';
  @override
  String get normalStatus => 'Normal';
  @override
  String get noneStatus => 'Nenhum';
  @override
  String get noSnoringDataAvailableUpgradePremium => 'Não há dados disponíveis sobre o seu ronco. Atualize para o Premium para ver a análise da intensidade do seu ronco ✨';
  @override
  String get noSnoringDataAvailableToday => 'Não há dados disponíveis sobre ronco para hoje.';
  @override
  String get intensity => 'Intensidade';
  @override
  String get earlyBird => 'Madrugador';
  @override
  String get sleep => 'Dormir';
  @override
  String get champion => 'Campeão';
  @override
  String get wakeUpGoal => 'Objetivo de despertar';
  @override
  String get nightOwlTamer => 'Domador de Corujas Noturnas';
  @override
  String get bedtimeBeforePM => 'Hora de dormir antes das 23h';
  @override
  String get noRecommendationsYetUpgradePremiumPersonalizedSleepImprovementTips => 'Ainda não há recomendações. Assine o Premium para receber dicas personalizadas para melhorar seu sono ✨';
  @override
  String get noRecommendationsAvailableToday => 'Nenhuma recomendação disponível para hoje.';
  @override
  String get duration => 'duração';
  @override
  String get environment => 'ambiente';
  @override
  String get deepSleep => 'sono profundo';
  @override
  String get quality1 => 'qualidade';
  @override
  String get day => 'dia';
  @override
  String get noDataFound => 'Nenhum dado encontrado';
  @override
  String get retry => 'Tentar novamente';
  @override
  String get unlockRecordingsPrompt => 'Nenhuma gravação encontrada. Desbloqueie suas gravações de sono e análises de IA com o Sleepable Premium ✨';
  @override
  String get noRecordingsToday => 'Nenhuma gravação encontrada para hoje.';
  @override
  String get noDataLabel => 'Sem dados';
  @override
  String get noDataRecorded => 'Nenhuma pessoa dormiu esta noite.';
  @override
  String get congratsLabel => 'Parabéns!';
  @override
  String get sleepChampion => 'Campeão do Sono';
  @override
  String get sleepScore => 'Pontuação do sono';
  @override
  String get sleepSpan => 'Duração do sono';
  @override
  String get atmosphere => 'Atmosfera';
  @override
  String get deepRecovery => 'Recuperação profunda';
  @override
  String get restPeriod => 'Período de repouso';
  @override
  String get actualRest => 'Descanso real';
  @override
  String get proInsightsPrompt => 'Nenhuma informação encontrada. Obtenha informações personalizadas sobre o seu sono com IA com o Sleepable Premium ✨';
  @override
  String get noInsightsToday => 'Nenhuma informação encontrada para hoje.';
  @override
  String get noInsightsWeek => 'Nenhuma informação encontrada para esta semana.';
  @override
  String get noInsightsMonth => 'Nenhuma informação encontrada para este mês.';
  @override
  String get settings => 'Configurações';
  @override
  String get support => 'Apoiar';
  @override
  String get account => 'Conta';
  @override
  String get emailSupport => 'Suporte por e-mail';
  @override
  String get privacyPolicy => 'política de Privacidade';
  @override
  String get termsOfService => 'Termos de Serviço';
  @override
  String get logOut => 'Sair';
  @override
  String get deleteAccount => 'Excluir conta';
  @override
  String get logoutTitle => 'Sair?';
  @override
  String get logoutContent => 'Tem certeza de que deseja sair da sua conta? Você pode entrar novamente a qualquer momento.';
  @override
  String get deleteTitle => 'Excluir conta?';
  @override
  String get deleteContent => 'Tem certeza de que deseja excluir sua conta permanentemente? Esta ação não pode ser desfeita.';
  @override
  String get yesLogout => 'Sim, sair';
  @override
  String get yesDelete => 'Sim, excluir';
  @override
  String get logoutFailed => 'Falha ao sair';
  @override
  String get deleteFailed => 'Exclusão falhou';
  @override
  String get errorNoEmail => 'Não foi possível abrir o aplicativo de e-mail.';
  @override
  String get termsService => 'Termos de Serviço';
  @override
  String get supportRequestSubject => 'Solicitação de suporte';
  @override
  String get supportEmailBody => 'Olá equipe,\n\nPreciso de ajuda com...';
  @override
  String get accountDeletedLabel => 'Conta excluída';
  @override
  String get accountDeletedSuccess => 'Sua conta foi excluída com sucesso.';
  @override
  String get deleteFailedLabel => 'Exclusão falhou';
  @override
  String get somethingWentWrong => 'Algo deu errado';
  @override
  String get shareSubject => 'Confira este aplicativo incrível!';
  @override
  String get youtube => 'YouTube';
  @override
  String get noVideosFound => 'Nenhum vídeo encontrado';
  @override
  String get noticeLabel => 'Perceber';
  @override
  String get notPlayableVideo => 'Este item não é um vídeo reproduzível.';
  @override
  String get untitledVideo => 'Sem título';
  @override
  String get understandSleepBetter => 'Entenda melhor o seu sono';
  @override
  String get quickSimpleQuestions => 'Perguntas rápidas e simples';
  @override
  String get builtWithSleepScience => 'Desenvolvido com base na ciência do sono.';
  @override
  String get whatYouWillGain => 'O que você vai ganhar';
  @override
  String get sleepOverviewTitle => 'Visão geral do sono';
  @override
  String get sleepOverviewDesc => 'Obtenha uma visão clara dos seus padrões de sono atuais e das possíveis áreas problemáticas.';
  @override
  String get personalInsightsTitle => 'Reflexões pessoais';
  @override
  String get personalInsightsDesc => 'Entenda como seus hábitos de sono podem influenciar o foco, o humor e a recuperação.';
  @override
  String get actionableGuidanceTitle => 'Orientações práticas';
  @override
  String get actionableGuidanceDesc => 'Receba sugestões práticas para ajudar você a melhorar a qualidade e a regularidade do seu sono.';
  @override
  String get theoreticalBackground => 'Fundamentos Teóricos';
  @override
  String get quizTheoryDesc => 'Com base em pesquisas consolidadas sobre o sono e na ciência comportamental, esta avaliação foi concebida para incentivar a conscientização precoce sobre os desafios relacionados ao sono e promover rotinas de sono mais saudáveis ​​por meio da tomada de decisões informadas.';
  @override
  String get viewResults => 'Ver resultados';
  @override
  String get insomniaTitle => 'Insônia';
  @override
  String get insomniaOverview1 => 'A insônia é um distúrbio do sono comum em que a pessoa tem dificuldade para adormecer, manter o sono ou acordar sentindo-se descansada.';
  @override
  String get insomniaOverview2 => 'Pode afetar pessoas de todas as idades e geralmente está associado ao estresse, hábitos de vida ou rotinas de sono irregulares.';
  @override
  String get insomniaOverview3 => 'Tentar adormecer em excesso pode aumentar a ansiedade, o que pode tornar o sono ainda mais difícil.';
  @override
  String get insomniaOverview4 => 'Hábitos de sono saudáveis ​​são uma das maneiras mais eficazes de melhorar a qualidade do sono.';
  @override
  String get insomniaOverview5 => 'A insônia persistente pode levar à fadiga diurna, baixa energia e dificuldade em realizar tarefas diárias.';
  @override
  String get insomniaDef1 => 'A insônia é um distúrbio do sono que dificulta adormecer, manter o sono ou voltar a dormir após acordar.';
  @override
  String get insomniaDef2 => 'Pessoas com insônia podem ter um sono de má qualidade e frequentemente se sentem cansadas ou sem energia pela manhã.';
  @override
  String get insomniaTypeShort => 'Insônia de curto prazo: dura menos de três meses e geralmente é causada por estresse, ansiedade ou mudanças ambientais.';
  @override
  String get insomniaTypeChronic => 'Insônia crônica: dura mais de três meses e ocorre pelo menos três noites por semana.';
  @override
  String get insomniaTypeOther => 'Outros tipos de insônia: problemas de sono que não se enquadram claramente nas categorias de curto prazo ou crônico.';
  @override
  String get insomniaWho1 => 'A insônia pode ocorrer em qualquer idade, mas é mais comum em idosos e mulheres.';
  @override
  String get insomniaWho2 => 'Estresse, desafios emocionais, pressão no trabalho e grandes mudanças na vida podem aumentar o risco.';
  @override
  String get insomniaWho3 => 'Viagens, horários irregulares ou um estilo de vida sedentário também podem contribuir para dificuldades de sono.';
  @override
  String get insomniaCause1 => 'Horários de sono irregulares';
  @override
  String get insomniaCause2 => 'sonecas diurnas';
  @override
  String get insomniaCause3 => 'Ambientes de sono barulhentos ou muito iluminados';
  @override
  String get insomniaCause4 => 'Passar muito tempo na cama sem dormir';
  @override
  String get insomniaCause5 => 'Trabalho por turnos ou atividade noturna';
  @override
  String get insomniaCause6 => 'Falta de exercícios físicos';
  @override
  String get insomniaCause7 => 'Usar telas na cama';
  @override
  String get insomniaSubstance1 => 'Álcool ou drogas recreativas';
  @override
  String get insomniaSubstance2 => 'Fumar muito';
  @override
  String get insomniaSubstance3 => 'Excesso de cafeína, especialmente à noite.';
  @override
  String get insomniaSubstance4 => 'Certos medicamentos ou suplementos';
  @override
  String get insomniaSubstance5 => 'Uso frequente de medicamentos para resfriado ou estimulantes';
  @override
  String get insomniaFactor1 => 'Ansiedade ou estresse crônico';
  @override
  String get insomniaFactor2 => 'Depressão ou mau humor';
  @override
  String get insomniaFactor3 => 'Transtorno bipolar';
  @override
  String get insomniaFactor4 => 'Dor ou desconforto físico';
  @override
  String get insomniaFactor5 => 'Gravidez';
  @override
  String get insomniaFactor6 => 'Apneia do sono ou outros distúrbios do sono';
  @override
  String get insomniaFactor7 => 'Alterações do sono relacionadas à idade';
  @override
  String get insomniaSymp1 => 'Dificuldade em adormecer';
  @override
  String get insomniaSymp2 => 'Acordar frequentemente durante a noite';
  @override
  String get insomniaSymp3 => 'Acordar muito cedo';
  @override
  String get insomniaSymp4 => 'Sentir-se cansado durante o dia';
  @override
  String get insomniaSymp5 => 'Dificuldade de concentração ou memória fraca';
  @override
  String get insomniaSymp6 => 'Humor deprimido ou irritabilidade';
  @override
  String get insomniaDiag1 => 'Revisão do histórico médico e do sono';
  @override
  String get insomniaDiag2 => 'Discussão sobre hábitos e rotinas diárias';
  @override
  String get insomniaDiag3 => 'Exame físico, se necessário.';
  @override
  String get insomniaDiag4 => 'Estudo do sono em certos casos';
  @override
  String get insomniaTreat1 => 'O tratamento geralmente se concentra em melhorar os hábitos de sono e abordar as causas subjacentes.';
  @override
  String get insomniaTreat2 => 'A Terapia Cognitivo-Comportamental para Insônia (TCC-I) é um tratamento de primeira linha amplamente recomendado.';
  @override
  String get insomniaTreat3 => 'Isso ajuda as pessoas a mudarem pensamentos e comportamentos negativos relacionados ao sono.';
  @override
  String get insomniaHabit1 => 'Vá para a cama somente quando sentir sono.';
  @override
  String get insomniaHabit2 => 'Use a cama apenas para dormir.';
  @override
  String get insomniaHabit3 => 'Evite telas e refeições pesadas antes de dormir.';
  @override
  String get insomniaHabit4 => 'Faça exercícios regularmente durante o dia.';
  @override
  String get insomniaHabit5 => 'Mantenha uma rotina consistente de sono e vigília.';
  @override
  String get insomniaHabit6 => 'Crie um quarto silencioso, escuro e confortável.';
  @override
  String get insomniaMed1 => 'Algumas pessoas podem usar medicamentos para dormir por um curto período sob orientação médica.';
  @override
  String get insomniaMed2 => 'No entanto, a melhora a longo prazo geralmente resulta de mudanças no estilo de vida e terapias comportamentais.';
  @override
  String get insomniaPrev1 => 'Gerencie seus níveis de estresse.';
  @override
  String get insomniaPrev2 => 'Mantenha uma rotina de sono consistente.';
  @override
  String get insomniaPrev3 => 'Faça exercícios regularmente';
  @override
  String get insomniaPrev4 => 'Limite o consumo de cafeína, álcool e nicotina.';
  @override
  String get insomniaPrev5 => 'Crie um ambiente confortável para dormir.';
  @override
  String get insomniaComp1 => 'Fadiga diurna';
  @override
  String get insomniaComp2 => 'Alterações de humor, como ansiedade ou depressão.';
  @override
  String get insomniaComp3 => 'Baixa concentração';
  @override
  String get insomniaComp4 => 'Aumento do risco de acidentes';
  @override
  String get insomniaComp5 => 'Maior risco de doenças como obesidade, diabetes e doenças cardíacas.';
  @override
  String get insomniaOutlook1 => 'Muitas pessoas se recuperam da insônia melhorando os hábitos de sono e controlando o estresse.';
  @override
  String get insomniaOutlook2 => 'O tratamento precoce da insônia de curto prazo pode evitar que ela se torne crônica.';
  @override
  String get insomniaOutlook3 => 'Manter rotinas saudáveis ​​ajuda a reduzir o risco de recorrência.';
  @override
  String get hypersomniaTitle => 'Hipersonia';
  @override
  String get hypersomniaOverview1 => 'A hipersonia é uma condição em que a pessoa sente sonolência excessiva durante o dia, mesmo depois de ter dormido o suficiente à noite.';
  @override
  String get hypersomniaOverview2 => 'Isso pode afetar as atividades diárias, a concentração e os níveis gerais de energia.';
  @override
  String get hypersomniaCause1 => 'Má qualidade do sono';
  @override
  String get hypersomniaCause2 => 'Distúrbios do sono, como apneia do sono';
  @override
  String get hypersomniaCause3 => 'Depressão ou outros problemas de saúde mental';
  @override
  String get hypersomniaCause4 => 'Certos medicamentos';
  @override
  String get hypersomniaSymp1 => 'Sonolência diurna extrema';
  @override
  String get hypersomniaSymp2 => 'Dificuldade em se manter acordado';
  @override
  String get hypersomniaSymp3 => 'Longos períodos de sono';
  @override
  String get hypersomniaSymp4 => 'Pouca energia e motivação';
  @override
  String get hypersomniaTip1 => 'Mantenha um horário de sono regular.';
  @override
  String get hypersomniaTip2 => 'Evite álcool e refeições pesadas antes de dormir.';
  @override
  String get hypersomniaTip3 => 'Pratique atividade física diariamente.';
  @override
  String get hypersomniaTip4 => 'Consulte um profissional de saúde se os sintomas persistirem.';
  @override
  String get snoringTitle => 'Ronco';
  @override
  String get snoringOverview1 => 'O ronco ocorre quando o fluxo de ar pela boca e pelo nariz é parcialmente bloqueado durante o sono.';
  @override
  String get snoringOverview2 => 'É comum e geralmente inofensivo, mas em alguns casos pode indicar um distúrbio do sono.';
  @override
  String get snoringCause1 => 'Congestão nasal';
  @override
  String get snoringCause2 => 'Dormindo de costas';
  @override
  String get snoringCause3 => 'Obesidade';
  @override
  String get snoringCause4 => 'Consumo de álcool antes de dormir';
  @override
  String get snoringEffect1 => 'Sono perturbado';
  @override
  String get snoringEffect2 => 'Fadiga diurna';
  @override
  String get snoringEffect3 => 'problemas de sono no relacionamento ou com o parceiro';
  @override
  String get snoringTip1 => 'Durma de lado';
  @override
  String get snoringTip2 => 'Mantenha um peso saudável.';
  @override
  String get snoringTip3 => 'Evite o consumo de álcool antes de dormir.';
  @override
  String get snoringTip4 => 'Mantenha as vias nasais desobstruídas.';
  @override
  String get breathingPausesTitle => 'Pausas respiratórias durante o sono';
  @override
  String get apneaOverview1 => 'As pausas respiratórias durante o sono são frequentemente associadas à apneia do sono, uma condição em que a respiração para e recomeça repetidamente.';
  @override
  String get apneaOverview2 => 'Isso pode reduzir os níveis de oxigênio e prejudicar a qualidade do sono.';
  @override
  String get apneaSign1 => 'Ronco alto';
  @override
  String get apneaSign2 => 'Ofegante ou engasgando durante o sono';
  @override
  String get apneaSign3 => 'dores de cabeça matinais';
  @override
  String get apneaSign4 => 'Sonolência diurna';
  @override
  String get apneaRisk1 => 'Excesso de peso';
  @override
  String get apneaRisk2 => 'Via aérea estreita';
  @override
  String get apneaRisk3 => 'Fumar';
  @override
  String get apneaRisk4 => 'Histórico familiar de apneia do sono';
  @override
  String get apneaTreat1 => 'Controle de peso';
  @override
  String get apneaTreat2 => 'Dormindo de lado';
  @override
  String get apneaTreat3 => 'terapia CPAP';
  @override
  String get apneaTreat4 => 'Avaliação e tratamento médico';
  @override
  String get bruxismTitle => 'Bruxismo';
  @override
  String get bruxismOverview1 => 'Bruxismo é o hábito de ranger ou apertar os dentes, geralmente durante o sono.';
  @override
  String get bruxismOverview2 => 'Com o tempo, isso pode causar dor na mandíbula, dores de cabeça e danos aos dentes.';
  @override
  String get bruxismCause1 => 'Estresse ou ansiedade';
  @override
  String get bruxismCause2 => 'Distúrbios do sono';
  @override
  String get bruxismCause3 => 'Dentes desalinhados';
  @override
  String get bruxismCause4 => 'Uso de cafeína ou álcool';
  @override
  String get bruxismSymp1 => 'Dor ou rigidez na mandíbula';
  @override
  String get bruxismSymp2 => 'Dores de cabeça pela manhã';
  @override
  String get bruxismSymp3 => 'Dentes desgastados ou sensíveis';
  @override
  String get bruxismSymp4 => 'Estalo na mandíbula';
  @override
  String get bruxismManage1 => 'Técnicas de redução do estresse';
  @override
  String get bruxismManage2 => 'Utilizando um protetor noturno';
  @override
  String get bruxismManage3 => 'Limitar o consumo de cafeína e álcool.';
  @override
  String get bruxismManage4 => 'Consultar um dentista';
  @override
  String get restlessLegTitle => 'Síndrome das Pernas Inquietas';
  @override
  String get rlsOverview1 => 'A Síndrome das Pernas Inquietas (SPI) é uma condição que causa sensações desconfortáveis ​​nas pernas e uma forte vontade de movê-las.';
  @override
  String get rlsOverview2 => 'Os sintomas geralmente aparecem à noite e podem perturbar o sono.';
  @override
  String get rlsSymp1 => 'Sensação de formigamento ou rastejamento nas pernas';
  @override
  String get rlsSymp2 => 'Vontade de mexer as pernas';
  @override
  String get rlsSymp3 => 'Os sintomas pioram à noite.';
  @override
  String get rlsSymp4 => 'Alívio temporário após o movimento';
  @override
  String get rlsCause1 => 'Deficiência de ferro';
  @override
  String get rlsCause2 => 'Gravidez';
  @override
  String get rlsCause3 => 'Doenças crônicas';
  @override
  String get rlsCause4 => 'História familiar';
  @override
  String get rlsHabit1 => 'Exercício regular';
  @override
  String get rlsHabit2 => 'Alongamento antes de dormir';
  @override
  String get rlsHabit3 => 'Limitar a cafeína';
  @override
  String get rlsHabit4 => 'Manter uma rotina de sono regular';
  @override
  String get palpitationsTitle => 'Palpitações e insônia';
  @override
  String get palpOverview1 => 'Palpitações cardíacas e insônia frequentemente ocorrem juntas, especialmente durante períodos de estresse ou ansiedade.';
  @override
  String get palpOverview2 => 'Batimentos cardíacos acelerados ou irregulares podem dificultar o relaxamento e o adormecer.';
  @override
  String get palpCause1 => 'Estresse e ansiedade';
  @override
  String get palpCause2 => 'Excesso de cafeína';
  @override
  String get palpCause3 => 'Falta de sono';
  @override
  String get palpCause4 => 'Alterações hormonais';
  @override
  String get palpSymp1 => 'batimento cardíaco acelerado ou forte';
  @override
  String get palpSymp2 => 'Dificuldade em adormecer';
  @override
  String get palpSymp3 => 'Ansiedade noturna';
  @override
  String get palpSymp4 => 'Despertares frequentes';
  @override
  String get palpTip1 => 'Pratique técnicas de relaxamento antes de dormir.';
  @override
  String get palpTip2 => 'Limitar a ingestão de cafeína';
  @override
  String get palpTip3 => 'Mantenha um horário de sono consistente.';
  @override
  String get palpTip4 => 'Consulte um médico se as palpitações persistirem.';
  @override
  String get commonCauses => 'Causas comuns';
  @override
  String get symptoms => 'Sintomas';
  @override
  String get finish => 'Terminar';
  @override
  String get next => 'Próximo';
  @override
  String get previous => 'Anterior';
  @override
  String get yesLabel => 'Sim';
  @override
  String get noLabel => 'Não';
  @override
  String get qSnoring => 'Você ronca alto ou com frequência durante o sono?';
  @override
  String get qMorningHeadache => 'Você costuma acordar com dor de cabeça pela manhã?';
  @override
  String get qGaspingAir => 'Você acorda com falta de ar ou como se estivesse ofegante?';
  @override
  String get qBreathingPauses => 'Alguém já lhe disse que você para de respirar ou pausa a respiração enquanto dorme?';
  @override
  String get qSleepyDriving => 'Você sente muito sono ao dirigir ou durante atividades importantes?';
  @override
  String get qDryMouth => 'Você acorda com a boca seca ou dor de garganta?';
  @override
  String get qIrritable => 'Outras pessoas comentaram que você parece estar excepcionalmente irritável ou mal-humorado?';
  @override
  String get qLowStamina => 'Você costuma sentir que seus níveis de energia ou resistência estão mais baixos do que deveriam?';
  @override
  String get qChestDiscomfort => 'Você sente desconforto ou aperto no peito ao acordar?';
  @override
  String get qDaytimeSleepiness => 'Você sofre com sonolência diurna persistente?';
  @override
  String get qBloodPressure => 'Você foi diagnosticado com pressão arterial alta ou descontrolada?';
  @override
  String get qNasalBreathing => 'Você tem dificuldade para respirar confortavelmente pelo nariz à noite?';
  @override
  String get qDifficultySleep => 'Você tem dificuldade para adormecer ou para permanecer dormindo pelo menos três noites por semana?';
  @override
  String get qNightAwakenings => 'Você acorda várias vezes durante a noite e tem dificuldade para voltar a dormir?';
  @override
  String get qDaytimeFatigue => 'Durante o dia, você costuma se sentir cansado, irritado, sem concentração ou mentalmente esgotado?';
  @override
  String get qSleepMedication => 'Você depende de medicamentos ou suplementos para dormir para conseguir pegar no sono?';
  @override
  String get qEveningAlcohol => 'Você consome álcool à noite para relaxar ou dormir melhor?';
  @override
  String get qSleepAnxiety => 'Você se sente ansioso, estressado ou frustrado em relação ao seu sono antes de ir para a cama?';
  @override
  String get qLateSchedule => 'Você costuma adormecer tarde e depois tem muita dificuldade para acordar de manhã?';
  @override
  String get qMedicalConditions => 'Você já foi diagnosticado com pressão alta, problemas cardíacos ou sofreu um AVC?';
  @override
  String get qExcessWeight => 'Você está atualmente com excesso de peso corporal que pode afetar sua saúde?';
  @override
  String get results => 'Resultados';
  @override
  String get disorder => 'Transtorno';
  @override
  String get resultDetails => 'Detalhes do resultado';
  @override
  String get suggestions => 'Sugestões';
  @override
  String get backToHome => 'Voltar para a página inicial';
  @override
  String get errorNoQuizData => 'Nenhum dado de questionário encontrado.';
  @override
  String get errorGenerateResult => 'Não foi possível gerar seus resultados. Tente novamente.';
  @override
  String get errorNetwork => 'Ocorreu um erro de rede.';
  @override
  String get maxSoundsLimit => 'É possível reproduzir no máximo 10 sons simultaneamente.';
  @override
  String get errorFavUpdate => 'Não foi possível atualizar os favoritos. Verifique sua conexão.';
  @override
  String get duplicateMixName => 'Já existe uma mistura com esse nome.';
  @override
  String get duplicateMixContent => 'Essa combinação exata já está salva.';
  @override
  String get mixMinSoundsError => 'Por favor, selecione pelo menos dois sons ou um som com música.';
  @override
  String get mixSavedSuccess => 'Mixagem salva com sucesso';
  @override
  String get nowPlaying => 'Tocando agora';
  @override
  String get ambientPlaying => 'Sons ambientes tocando';
  @override
  String get soundPlaying => 'Reprodução de som';
  @override
  String get sleepTrackingActive => 'O monitoramento do sono está ativo.';
  @override
  String get timerHitZero => 'O cronômetro chegou a zero. Limpando...';
  @override
  String get duplicateNameTitle => 'Nome duplicado';
  @override
  String get duplicateMixTitle => 'Mistura duplicada';
  @override
  String get cannotSaveTitle => 'Não é possível salvar a mistura.';
  @override
  String get mixSaved => 'Mistura salva';
  @override
  String get sleepSounds => 'Sons para dormir';
  @override
  String get noMixesFound => 'Ainda não há misturas disponíveis.';
  @override
  String get noSoundsFound => 'Nenhum som encontrado';
  @override
  String get timerSubTitle => 'À medida que o tempo se aproxima do fim, o som irá se dissipar suavemente no silêncio...';
  @override
  String get timerQuestion => 'Por quanto tempo o áudio deve ser reproduzido?';
  @override
  String get resetTimer => 'Reiniciar temporizador';
  @override
  String get serviceTitle => 'A IA Sleepable está ativa';
  @override
  String get serviceText => 'Monitorando seu sono...';
  @override
  String get calibratingSensors => 'Calibrando sensores de ambiente...';
  @override
  String get noTimeSet => 'Sem horário definido';
  @override
  String get errorTrackerStop => 'Não foi possível interromper o monitoramento do sono.';
  @override
  String get batteryWarningTitle => 'Bateria fraca';
  @override
  String get batteryWarningText => 'Conecte seu carregador para um monitoramento preciso do sono.';
  @override
  String get startingSleepTracker => 'Iniciando o monitoramento do sono...';
  @override
  String get keepChargerConnected => 'Mantenha o carregador conectado.';
  @override
  String get ambientNoise => 'Ruído ambiente';
  @override
  String get alarmOff => 'Alarme desativado';
  @override
  String get preventShutdown => 'Impedir desligamento';
  @override
  String get connectCharger => 'Conecte o dispositivo ao carregador.';
  @override
  String get noMixAdded => 'Sem adição de mistura';
  @override
  String get quit => 'Desistir';
  @override
  String get keepTracking => 'Continue acompanhando';
  @override
  String get quitNow => 'Desista agora';
  @override
  String get notBedtimeYet => 'Ainda não é hora de dormir.';
  @override
  String get sleepableWillRemind => 'Sleepable irá lembrá-lo de dormir às:';
  @override
  String get notNow => 'Agora não';
  @override
  String get ratingTitle => 'Que bom que você gostou de Sleepable!';
  @override
  String get ratingStep1Desc => 'Se você gosta do que fazemos, por favor, deixe uma avaliação.';
  @override
  String get ratingStep2Desc => 'Se você gostou do nosso trabalho, considere deixar uma avaliação positiva!';
  @override
  String get theBest => 'O melhor!';
  @override
  String get goRating => 'Avaliação do Go';
  @override
  String get maybeLater => 'Não, talvez mais tarde.';
  @override
  String get luckySpinOffer => 'OFERTA DE GIRO DA SORTE APLICADA';
  @override
  String get limitedPeriodOffer => 'OFERTA POR TEMPO LIMITADO - {discount}% DE DESCONTO';
  @override
  String get specialDiscountApplied => 'DESCONTO ESPECIAL APLICADO';
  @override
  String get seizeNow => 'Aproveite agora';
  @override
  String get cancelAnytime => 'Cobrança recorrente. Cancele quando quiser.';
  @override
  String get termsAndPrivacy => 'Termos de serviço e Política de privacidade.';
  @override
  String get noPaymentDue => 'Nenhum pagamento devido agora.';
  @override
  String get noCommitment => 'Sem compromisso - cancele quando quiser';
  @override
  String get bestDeal => 'Melhor Oferta do Ano';
  @override
  String get trySleepableFree => 'Queremos que você';
  @override
  String get trySleepableFree1 => 'Experimente o Sleepable gratuitamente.';
  @override
  String get spinUnlockTitle => 'desconto exclusivo';
  @override
  String get spinUnlockTitle1 => 'desconto exclusivo';
  @override
  String get congratsUnlock => 'PARABÉNS! Você desbloqueou {discount}% de desconto.';
  @override
  String get spinNow => 'Gire agora';
  @override
  String get claimDiscount => 'REIVINDIQUE O DESCONTO';
  @override
  String get oneTimeOffer => 'Sua oferta única';
  @override
  String get continueFree => 'Continue GRATUITAMENTE';
  @override
  String get startTrialToContinue => 'Comece seu teste GRÁTIS de 3 dias para continuar.';
  @override
  String get startFreeTrial => 'Comece seu teste gratuito de 3 dias';
  @override
  String get just => 'Apenas';
  @override
  String get only => 'APENAS';
  @override
  String get perWeek => 'SEMANA';
  @override
  String get total => 'Total';
  @override
  String get perYear => 'ano';
  @override
  String get termsApply => 'Aplicam-se os termos de serviço.';
  @override
  String get googleIdCharge => Platform.isIOS ? 'Será feita a cobrança em sua conta da Apple.' : 'Será feita a cobrança em sua conta do Google.';
  @override
  String get cancelStore => Platform.isIOS ? 'Cancele a qualquer momento pela App Store.' : 'Cancele a qualquer momento pela Play Store.';
  @override
  String get btnTryFree => 'Experimente grátis';
  @override
  String get btnGetForZero => 'Obtenha por {symbol}0,00';
  @override
  String get btnStartTrial => 'Comece o teste agora';
  @override
  String get btnUnlockAccess => 'Desbloquear acesso';
  @override
  String get goodLuck => 'Boa sorte!';
  @override
  String get connectionError => 'Erro de conexão.';
  @override
  String get tryAgainLater => 'Tente novamente mais tarde.';
  @override
  String get congrats => 'PARABÉNS!';
  @override
  String get unlocked => 'Você desbloqueou';
  @override
  String get spinning => 'FIAÇÃO...';
  @override
  String get off => 'DESLIGADO';
  @override
  String get discountUnlocked => 'Desconto desbloqueado!';
  @override
  String get oneTimeOfferTitle => 'Sua oferta única';
  @override
  String get offForever => 'PARA SEMPRE';
  @override
  String get featureSleep => 'Desfrute de um sono profundo e reparador esta noite.';
  @override
  String get featureSounds => 'Acesso ilimitado a todos os sons para dormir.';
  @override
  String get featureAnalytics => 'Informações e análises personalizadas sobre o sono.';
  @override
  String get yearlyPremium => 'Prêmio Anual';
  @override
  String get continueYearly => 'Continue com o programa anual';
  @override
  String get continueWeekly => 'Continue com o programa semanal';
  @override
  String get remindPart1 => 'Nós lhe enviaremos';
  @override
  String get remindPart2 => 'um lembrete antes';
  @override
  String get remindPart3 => 'seu';
  @override
  String get remindPart4 => 'O período de teste gratuito termina aqui.';
  @override
  String get unlockSleepableTitle => 'Desbloqueie o Sleepable para alcançar seus objetivos mais rapidamente.';
  @override
  String get startJourney => 'Comece minha jornada';
  @override
  String get threeDaysFreeBadge => '3 DIAS GRÁTIS';
  @override
  String get threeDaysFreeThen => '3 dias grátis, depois';
  @override
  String get in2Days => 'Em 2 dias - Lembrete';
  @override
  String get trialEndingReminder => 'Gostaríamos de lembrar que seu período de teste está terminando.';
  @override
  String get in3Days => 'Em 3 dias - Início da cobrança';
  @override
  String get billingStartsNote => 'A cobrança será efetuada a menos que você cancele a qualquer momento antes do prazo.';
  @override
  String get easySleepTracking => 'Monitoramento fácil do sono';
  @override
  String get trackCyclesAuto => 'Acompanhe seus ciclos automaticamente';
  @override
  String get wakeUpRefreshed => 'Acorde revigorado';
  @override
  String get keepItSimple => 'Mantenha as coisas simples para facilitar o despertar.';
  @override
  String get trackProgress => 'Acompanhe seu progresso';
  @override
  String get smartReminders => 'Lembretes e insights inteligentes';
  @override
  String get weekly => 'Semanalmente';
  @override
  String get yearly => 'Anual';
  @override
  String get tlToday => 'Hoje';
  @override
  String get tlTodaySub => 'Desbloqueie todos os recursos e comece a rastrear.';
  @override
  String get tlReminder => 'Em 2 dias - Lembrete';
  @override
  String get tlReminderSub => 'Gostaríamos de lembrar que seu período de teste está terminando.';
  @override
  String get tlBilling => 'Em 3 dias - Início da cobrança';
  @override
  String get tlBillingSub => 'A cobrança será efetuada a menos que você cancele a qualquer momento antes do prazo.';
  @override
  String get appSettings => 'Configurações do aplicativo';
  @override
  String get commonSigns => 'Sinais comuns';
  @override
  String get commonSymptoms => 'Sintomas comuns';
  @override
  String get diagnosis => 'Diagnóstico';
  @override
  String get healthEmotionalFactors => 'Fatores de saúde e emocionais';
  @override
  String get healthySleepHabits => 'Hábitos de sono saudáveis';
  @override
  String get helpfulHabits => 'Hábitos Úteis';
  @override
  String get helpfulTips => 'Dicas úteis';
  @override
  String get management => 'Gerenciamento';
  @override
  String get managementTips => 'Dicas de gestão';
  @override
  String get medication => 'Medicamento';
  @override
  String get outlook => 'Panorama';
  @override
  String get possibleCauses => 'Possíveis causas';
  @override
  String get possibleComplications => 'Possíveis Complicações';
  @override
  String get possibleEffects => 'Possíveis efeitos';
  @override
  String get preventionTips => 'Dicas de prevenção';
  @override
  String get riskFactors => 'Fatores de risco';
  @override
  String get substancesAffectSleep => 'Substâncias que afetam o sono';
  @override
  String get treatmentApproaches => 'Abordagens de tratamento';
  @override
  String get treatmentOptions => 'Opções de tratamento';
  @override
  String get typesOfInsomnia => 'Tipos de Insônia';
  @override
  String get whoIsAffected => 'Quem é afetado?';
  @override
  String get freeTrialReminder => 'Lembrete de teste gratuito';
  // @override
  // String get oneTimeOffer => 'Oferta única';"
  // @override
  // String get only => 'APENAS';"
  // @override
  // String get disorder => 'Transtorno';"
  // @override
  // String get resultDetails => 'Detalhes do resultado';"
  // @override
  // String get symptoms => 'Sintomas';"
  @override
  String get overview => 'Visão geral';
  @override
  String get default1 => 'Padrão';
  @override
  String get definition => 'Definição';

  ///
   @override
  String get welcomeToTheMost => 'Bem-vindo ao mais';
   @override
  String get advancedSleepTracker => 'rastreador de sono avançado';
   @override
  String get knowAboutSleepPatterns => 'Conheça os padrões de sono.';
   @override
  String get gainInsightOfYourSleep => 'Obtenha informações sobre o seu sono.';
   @override
  String get monitorTalkingAndSnoring => 'Monitore conversas e roncos.';
   @override
  String get trackSleepSounds => 'Monitore os sons do sono';
   @override
  String get smartSleepAnalysis => 'Análise inteligente do sono';
   @override
  String get improveSleepEfficiency => 'Melhore a eficiência do sono.';
   @override
  String get placeTheDeviceAsPicture => 'Posicione o dispositivo conforme a imagem.';
   @override
  String get pleasePlacePhoneNextBedKeepChargerConnected => 'Por favor, coloque o telefone ao lado da sua cama e mantenha o carregador conectado.';
   @override
  String get setYourWakeUpTime => 'Defina seu horário de despertar';
   @override
  String get trySleepNote => 'Experimente o Sleep Note?';
   @override
  String get sleepNoteEasyRevealFactorsGoodNightsRest => 'O Sleep Note é uma ferramenta simples para revelar fatores que podem estar impedindo você de ter uma boa noite de sono.';
   @override
  String get done => 'Feito';
   @override
  String get dontShowAgain => 'Não mostrar novamente';
  @override
  String get addSleepNote => 'Adicionar nota de sono';
  @override
  String get others => 'Outros';
  @override
  String get describeYourDay => 'Talvez você queira nos descrever o seu dia!';
  @override
  String get sleepNoteHintText => 'Hoje, tomei 3 xícaras de café... e me senti sonolenta/preguiçosa ao meio-dia 🥱';
  @override
  String get add => 'Adicionar';
  @override
  String get deleteNote => 'Apagar nota?';
  @override
  String get areSureWantDeleteNote => 'Tem certeza de que deseja excluir esta nota?';
  @override
  String get thisActionCannotUndone => 'Esta ação não pode ser desfeita.';
  @override
  String get failedDeleteNote => 'Falha ao excluir a nota';
  @override
  String get edit => 'Editar';
  @override
  String get tag => 'Marcação';
  @override
  String get enterTagName => 'Digite o nome da etiqueta';
  @override
  String get sleepNoteAddedSuccessfully => 'Anotação de sono adicionada com sucesso!';
  @override
  String get oK => 'OK';
  @override
  String get update => 'Atualizar';
  @override
  String get setSleepTimer => 'Definir temporizador de sono';
  @override
  String get soundList => 'Lista de sons';
  @override
  String get noItemsFound => 'Nenhum item encontrado';
  @override
  String get storyteller => 'Contador de histórias';
  @override
  String get relaxingMelody => 'Melodia Relaxante';
  @override
  String get relaxYourBody => 'Relaxe o seu corpo';
  @override
  String get unknownArtist => 'Sleepable AI';
  @override
  String get spinToUnlockAn => 'Gire para desbloquear um';
  @override
  String get exclusiveDiscount => 'desconto exclusivo';
  @override
  String get gift => 'Presente';
  @override
  String get noLuck => 'Sem sorte';
  @override
  String get signInWithEmail => 'Entrar com e-mail';
  @override
  String get emailAddress => 'Endereço de email';
  @override
  String get password => 'Senha';
  @override
  String get pleaseFillAllFields => 'Por favor, preencha todos os campos.';
  @override
  String get loginFailed => 'falha no login';
  @override
  String get somethingWentWrongDuringLogin => 'Ocorreu um erro durante o login.';
  @override
  String get enter6DigitOTP => 'Digite o código OTP de 6 dígitos.';
  @override
  String get oTPError => 'Erro de OTP';
  @override
  String get somethingWentWrongDuringotpVerification => 'Ocorreu um erro durante a verificação do OTP.';
  @override
  String get verificationCode => 'Código de verificação';
  @override
  String get pleaseEnterThe6DigitCodeSentTo => 'Por favor, insira o código de 6 dígitos enviado para';
  @override
  String get verifyLogin => 'Verificar e iniciar sessão';

}
