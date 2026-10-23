enum AppLanguage {
  en,
  hi,
  mr,
}

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.en:
        return 'en';
      case AppLanguage.hi:
        return 'hi';
      case AppLanguage.mr:
        return 'mr';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.en:
        return 'English';
      case AppLanguage.hi:
        return 'हिन्दी (Hindi)';
      case AppLanguage.mr:
        return 'मराठी (Marathi)';
    }
  }

  String get shortName {
    switch (this) {
      case AppLanguage.en:
        return 'EN';
      case AppLanguage.hi:
        return 'HI';
      case AppLanguage.mr:
        return 'MR';
    }
  }

  String get ttsLocale {
    switch (this) {
      case AppLanguage.en:
        return 'en-IN';
      case AppLanguage.hi:
        return 'hi-IN';
      case AppLanguage.mr:
        return 'mr-IN';
    }
  }

  String get sttLocale {
    switch (this) {
      case AppLanguage.en:
        return 'en_IN';
      case AppLanguage.hi:
        return 'hi_IN';
      case AppLanguage.mr:
        return 'mr_IN';
    }
  }
}

class LocalizationService {
  static final Map<String, Map<AppLanguage, String>> _strings = {
    // General & Navigation
    'app_name': {
      AppLanguage.en: 'SignConnect',
      AppLanguage.hi: 'साइन कनेक्ट',
      AppLanguage.mr: 'साइन कनेक्ट',
    },
    'app_tagline': {
      AppLanguage.en: 'Bridging Communication with Sign Language & Voice',
      AppLanguage.hi: 'सांकेतिक भाषा और आवाज से संचार का सेतु',
      AppLanguage.mr: 'सांकेतिक भाषा आणि आवाजाने संवादाचा सेतू',
    },
    'nav_home': {
      AppLanguage.en: 'Home',
      AppLanguage.hi: 'होम',
      AppLanguage.mr: 'मुख्यपृष्ठ',
    },
    'nav_profile': {
      AppLanguage.en: 'Profile',
      AppLanguage.hi: 'प्रोफ़ाइल',
      AppLanguage.mr: 'प्रोफाइल',
    },
    'nav_options': {
      AppLanguage.en: 'Options',
      AppLanguage.hi: 'विकल्प',
      AppLanguage.mr: 'पर्याय',
    },

    // Profile Selector
    'welcome_title': {
      AppLanguage.en: 'Welcome to SignConnect',
      AppLanguage.hi: 'साइन कनेक्ट में आपका स्वागत है',
      AppLanguage.mr: 'साइन कनेक्ट मध्ये आपले स्वागत आहे',
    },
    'choose_experience': {
      AppLanguage.en: 'Choose how you experience the app',
      AppLanguage.hi: 'ऐप का अनुभव कैसे करना चाहते हैं चुनें',
      AppLanguage.mr: 'ॲपचा अनुभव कसा घ्यायचा ते निवडा',
    },
    'profile_deaf_label': {
      AppLanguage.en: 'Deaf / Mute',
      AppLanguage.hi: 'बधिर / मूक',
      AppLanguage.mr: 'बहिरे / मुके',
    },
    'profile_deaf_desc': {
      AppLanguage.en: 'Visual-first layout. Live sign detection and speech-to-text subtitles.',
      AppLanguage.hi: 'दृश्य-प्रधान लेआउट। लाइव संकेत पहचान और आवाज-से-पाठ उपशीर्षक।',
      AppLanguage.mr: 'दृश्य-प्रथम मांडणी. थेट चिन्ह ओळख आणि आवाज-ते-मजकूर उपशीर्षके.',
    },
    'profile_blind_label': {
      AppLanguage.en: 'Blind',
      AppLanguage.hi: 'दृष्टिहीन',
      AppLanguage.mr: 'दृष्टीहीन',
    },
    'profile_blind_desc': {
      AppLanguage.en: 'Audio-first layout. Everything is read aloud with large touch zones.',
      AppLanguage.hi: 'ऑडियो-प्रथम लेआउट। बड़ी स्पर्श सीमाओं के साथ सब कुछ पढ़कर सुनाया जाता है।',
      AppLanguage.mr: 'ऑडिओ-प्रथम मांडणी. मोठ्या टच झोनसह सर्वकाही वाचून दाखवले जाते.',
    },
    'profile_general_label': {
      AppLanguage.en: 'General',
      AppLanguage.hi: 'सामान्य',
      AppLanguage.mr: 'सामान्य',
    },
    'profile_general_desc': {
      AppLanguage.en: 'Standard layout with live sign translation, audio, and video calling.',
      AppLanguage.hi: 'लाइव संकेत अनुवाद, ऑडियो और वीडियो कॉलिंग के साथ मानक लेआउट।',
      AppLanguage.mr: 'थेट संकेत भाषांतर, ऑडिओ आणि व्हिडिओ कॉलिंगसह मानक मांडणी.',
    },

    // Home Dashboard
    'tools_title': {
      AppLanguage.en: 'Accessibility Tools',
      AppLanguage.hi: 'सुलभता उपकरण',
      AppLanguage.mr: 'सुलभता साधने',
    },
    'start_meet': {
      AppLanguage.en: 'Start New Meet',
      AppLanguage.hi: 'नई बैठक शुरू करें',
      AppLanguage.mr: 'नवीन बैठक सुरू करा',
    },
    'join_code': {
      AppLanguage.en: 'Join with Code',
      AppLanguage.hi: 'कोड से जुड़ें',
      AppLanguage.mr: 'कोडने सामील व्हा',
    },
    'saved_contacts': {
      AppLanguage.en: 'Saved Contacts',
      AppLanguage.hi: 'सहेजे गए संपर्क',
      AppLanguage.mr: 'जतन केलेले संपर्क',
    },
    'read_screen': {
      AppLanguage.en: 'Read screen',
      AppLanguage.hi: 'स्क्रीन पढ़ें',
      AppLanguage.mr: 'स्क्रीन वाचा',
    },
    'enter_meeting_code': {
      AppLanguage.en: 'Enter meeting code',
      AppLanguage.hi: 'मीटिंग कोड दर्ज करें',
      AppLanguage.mr: 'बैठक कोड प्रविष्ट करा',
    },
    'join_btn': {
      AppLanguage.en: 'Join',
      AppLanguage.hi: 'जुड़ें',
      AppLanguage.mr: 'सामील व्हा',
    },
    'close_btn': {
      AppLanguage.en: 'Close',
      AppLanguage.hi: 'बंद करें',
      AppLanguage.mr: 'बंद करा',
    },
    'start_now': {
      AppLanguage.en: 'Start now',
      AppLanguage.hi: 'अभी शुरू करें',
      AppLanguage.mr: 'आता सुरू करा',
    },
    'meeting_created': {
      AppLanguage.en: 'Meeting created',
      AppLanguage.hi: 'बैठक बन गई है',
      AppLanguage.mr: 'बैठक तयार झाली',
    },
    'share_code': {
      AppLanguage.en: 'Share this code so others can join:',
      AppLanguage.hi: 'यह कोड साझा करें ताकि अन्य जुड़ सकें:',
      AppLanguage.mr: 'हा कोड शेअर करा जेणेकरून इतर सामील होऊ शकतील:',
    },

    // Profile Screen
    'current_mode': {
      AppLanguage.en: 'Current mode:',
      AppLanguage.hi: 'वर्तमान मोड:',
      AppLanguage.mr: 'वर्तमान मोड:',
    },
    'change_profile': {
      AppLanguage.en: 'Change sensory profile',
      AppLanguage.hi: 'संवेदी प्रोफ़ाइल बदलें',
      AppLanguage.mr: 'संवेदी प्रोफाइल बदला',
    },

    // Accessibility Tools Tabs
    'tab_tts': {
      AppLanguage.en: 'Text→Speech',
      AppLanguage.hi: 'पाठ→आवाज',
      AppLanguage.mr: 'मजकूर→आवाज',
    },
    'tab_stt': {
      AppLanguage.en: 'Audio→Text',
      AppLanguage.hi: 'आवाज→पाठ',
      AppLanguage.mr: 'आवाज→मजकूर',
    },
    'tab_tto': {
      AppLanguage.en: 'Text→Audio',
      AppLanguage.hi: 'पाठ→ऑडियो फाइल',
      AppLanguage.mr: 'मजकूर→ऑडिओ फाईल',
    },
    'tab_signs': {
      AppLanguage.en: 'ISL Signs',
      AppLanguage.hi: 'संकेत पहचान',
      AppLanguage.mr: 'संकेत ओळख',
    },

    // STT Screen (Audio to Text)
    'stt_title': {
      AppLanguage.en: 'Audio → Text (Real-Time)',
      AppLanguage.hi: 'आवाज → पाठ (वास्तविक समय)',
      AppLanguage.mr: 'आवाज → मजकूर (रिअल-टाइम)',
    },
    'stt_desc': {
      AppLanguage.en: 'Tap the mic and speak — recognized words appear in real time.',
      AppLanguage.hi: 'माइक दबाएं और बोलें — पहचाने गए शब्द तुरंत दिखाई देंगे।',
      AppLanguage.mr: 'माइक टॅप करा आणि बोला — ओळखलेले शब्द त्वरित दिसतील.',
    },
    'stt_select_language': {
      AppLanguage.en: 'Speech Language:',
      AppLanguage.hi: 'बोलने की भाषा:',
      AppLanguage.mr: 'बोलण्याची भाषा:',
    },
    'stt_listening': {
      AppLanguage.en: 'Listening in real time… Speak now',
      AppLanguage.hi: 'वास्तविक समय में सुन रहे हैं… अब बोलें',
      AppLanguage.mr: 'रिअल-टाइममध्ये ऐकत आहे… आता बोला',
    },
    'stt_tap_to_listen': {
      AppLanguage.en: 'Tap the microphone to start listening',
      AppLanguage.hi: 'सुनना शुरू करने के लिए माइक दबाएं',
      AppLanguage.mr: 'ऐकणे सुरू करण्यासाठी माइक दाबा',
    },
    'stt_recognized_words': {
      AppLanguage.en: 'Recognized Words',
      AppLanguage.hi: 'पहचाने गए शब्द',
      AppLanguage.mr: 'ओळखलेले शब्द',
    },
    'stt_live_transcript': {
      AppLanguage.en: 'Live Transcript',
      AppLanguage.hi: 'लाइव प्रतिलेख',
      AppLanguage.mr: 'थेट मजकूर',
    },
    'stt_copy': {
      AppLanguage.en: 'Copy',
      AppLanguage.hi: 'कॉपी करें',
      AppLanguage.mr: 'कॉपी करा',
    },
    'stt_clear': {
      AppLanguage.en: 'Clear',
      AppLanguage.hi: 'साफ़ करें',
      AppLanguage.mr: 'हटवा',
    },
    'stt_copied': {
      AppLanguage.en: 'Text copied to clipboard',
      AppLanguage.hi: 'पाठ क्लिपबोर्ड पर कॉपी किया गया',
      AppLanguage.mr: 'मजकूर क्लिपबोर्डवर कॉपी केला गेला',
    },

    // TTS Screen (Text to Speech)
    'tts_title': {
      AppLanguage.en: 'Text → Speech (Real-Time)',
      AppLanguage.hi: 'पाठ → आवाज (वास्तविक समय)',
      AppLanguage.mr: 'मजकूर → आवाज (रिअल-टाइम)',
    },
    'tts_desc': {
      AppLanguage.en: 'Type words below or pick quick phrases to speak aloud instantly.',
      AppLanguage.hi: 'नीचे शब्द लिखें या तुरंत जोर से बोलने के लिए त्वरित वाक्य चुनें।',
      AppLanguage.mr: 'खाली शब्द टाइप करा किंवा त्वरित मोठ्याने बोलण्यासाठी वाक्य निवडा.',
    },
    'tts_hint': {
      AppLanguage.en: 'Type text to speak… (English, Hindi, Marathi)',
      AppLanguage.hi: 'बोलने के लिए लिखें… (अंग्रेजी, हिन्दी, मराठी)',
      AppLanguage.mr: 'बोलण्यासाठी टाइप करा… (इंग्रजी, हिंदी, मराठी)',
    },
    'tts_speed': {
      AppLanguage.en: 'Speed',
      AppLanguage.hi: 'गति',
      AppLanguage.mr: 'गती',
    },
    'tts_pitch': {
      AppLanguage.en: 'Pitch',
      AppLanguage.hi: 'पिच / स्वर',
      AppLanguage.mr: 'पिच / स्वर',
    },
    'tts_speak_btn': {
      AppLanguage.en: 'Speak',
      AppLanguage.hi: 'बोलें',
      AppLanguage.mr: 'बोला',
    },
    'tts_speaking': {
      AppLanguage.en: 'Speaking in real-time…',
      AppLanguage.hi: 'वास्तविक समय में बोल रहे हैं…',
      AppLanguage.mr: 'रिअल-टाइममध्ये बोलत आहे…',
    },
    'tts_stop_btn': {
      AppLanguage.en: 'Stop',
      AppLanguage.hi: 'रोकें',
      AppLanguage.mr: 'थांबवा',
    },
    'tts_quick_phrases': {
      AppLanguage.en: 'Quick Everyday Phrases',
      AppLanguage.hi: 'त्वरित उपयोगी वाक्य',
      AppLanguage.mr: 'त्वरित उपयुक्त वाक्ये',
    },
    'tts_spoken_words': {
      AppLanguage.en: 'Words Being Spoken',
      AppLanguage.hi: 'बोले जा रहे शब्द',
      AppLanguage.mr: 'बोलले जात असलेले शब्द',
    },

    // Sign Recognition Screen
    'sign_title': {
      AppLanguage.en: 'Real-Time ISL Sign Recognition',
      AppLanguage.hi: 'वास्तविक समय भारतीय संकेत भाषा पहचान',
      AppLanguage.mr: 'रिअल-टाइम भारतीय सांकेतिक भाषा ओळख',
    },
    'sign_mode_model': {
      AppLanguage.en: 'Trained Model (Words)',
      AppLanguage.hi: 'प्रशिक्षित मॉडल (शब्द)',
      AppLanguage.mr: 'प्रशिक्षित मॉडेल (शब्द)',
    },
    'sign_mode_alphabets': {
      AppLanguage.en: 'Hand Tracking (Letters)',
      AppLanguage.hi: 'हैंड ट्रैकिंग (वर्णमाला)',
      AppLanguage.mr: 'हस्त ट्रॅकिंग (अक्षरे)',
    },
    'sign_detected': {
      AppLanguage.en: 'Recognized Sign',
      AppLanguage.hi: 'पहचाना गया संकेत',
      AppLanguage.mr: 'ओळखलेले चिन्ह',
    },
    'sign_confidence': {
      AppLanguage.en: 'Confidence',
      AppLanguage.hi: 'सटीकता / विश्वास',
      AppLanguage.mr: 'आत्मविश्वास / अचूकता',
    },
    'sign_add_btn': {
      AppLanguage.en: 'Add Word',
      AppLanguage.hi: 'शब्द जोड़ें',
      AppLanguage.mr: 'शब्द जोडा',
    },
    'sign_spelled_sentence': {
      AppLanguage.en: 'Constructed Sentence / Word',
      AppLanguage.hi: 'निर्मित वाक्य / शब्द',
      AppLanguage.mr: 'तयार केलेले वाक्य / शब्द',
    },
    'sign_spell_placeholder': {
      AppLanguage.en: '(Signs recognized from camera appear here)',
      AppLanguage.hi: '(कैमरे से पहचाने गए संकेत यहाँ दिखाई देंगे)',
      AppLanguage.mr: '(कॅमेऱ्यातून ओळखलेली चिन्हे येथे दिसतील)',
    },
    'sign_speak_sentence': {
      AppLanguage.en: 'Speak Sentence',
      AppLanguage.hi: 'वाक्य बोलें',
      AppLanguage.mr: 'वाक्य बोला',
    },
    'sign_backend_status_online': {
      AppLanguage.en: 'Backend AI Model: Online & Ready',
      AppLanguage.hi: 'बैकएंड एआई मॉडल: ऑनलाइन और तैयार',
      AppLanguage.mr: 'बॅकएंड एआय मॉडेल: ऑनलाइन आणि सज्ज',
    },
    'sign_backend_status_offline': {
      AppLanguage.en: 'Backend Model: Connecting… (Using on-device model)',
      AppLanguage.hi: 'बैकएंड मॉडल: कनेक्ट हो रहा है… (ऑन-डिवाइस मॉडल सक्रिय)',
      AppLanguage.mr: 'बॅकएंड मॉडेल: कनेक्ट करत आहे… (ऑन-डिव्हाइस मॉडेल सुरू)',
    },
    'sign_supported_classes': {
      AppLanguage.en: 'Trained signs: Hello, Thank You, Please, Sorry, Yes, No, Help',
      AppLanguage.hi: 'प्रशिक्षित संकेत: नमस्ते, धन्यवाद, कृपया, माफ़ करें, हाँ, नहीं, मदद',
      AppLanguage.mr: 'प्रशिक्षित चिन्हे: नमस्कार, धन्यवाद, कृपया, माफ करा, होय, नाही, मदत',
    },

    // Settings / Options Screen
    'settings_language_section': {
      AppLanguage.en: 'App Language / भाषा / भाषा',
      AppLanguage.hi: 'ऐप की भाषा / App Language',
      AppLanguage.mr: 'अ‍ॅपची भाषा / App Language',
    },
    'settings_language_desc': {
      AppLanguage.en: 'Select menu and audio language (English, हिन्दी, मराठी)',
      AppLanguage.hi: 'मेनू और आवाज की भाषा चुनें (English, हिन्दी, मराठी)',
      AppLanguage.mr: 'मेनू आणि आवाजाची भाषा निवडा (English, हिन्दी, मराठी)',
    },
    'settings_force_tts': {
      AppLanguage.en: 'Force text-to-speech',
      AppLanguage.hi: 'टेक्स्ट-टू-स्पीच अनिवार्य करें',
      AppLanguage.mr: 'मजकूर-ते-आवाज सक्तीने करा',
    },
    'settings_force_tts_desc': {
      AppLanguage.en: 'Always read incoming captions aloud during calls',
      AppLanguage.hi: 'कॉल के दौरान आने वाले कैप्शन को हमेशा जोर से पढ़ें',
      AppLanguage.mr: 'कॉल दरम्यान येणारे कॅप्शन नेहमी मोठ्याने वाचा',
    },
    'settings_autoread': {
      AppLanguage.en: 'Auto-read screen',
      AppLanguage.hi: 'स्क्रीन स्वतः पढ़ें',
      AppLanguage.mr: 'स्क्रीन आपोआप वाचा',
    },
    'settings_autoread_desc': {
      AppLanguage.en: 'Speak each screen\'s content automatically when opened',
      AppLanguage.hi: 'खुलने पर प्रत्येक स्क्रीन की सामग्री को स्वतः बोलकर सुनाएं',
      AppLanguage.mr: 'स्क्रीन उघडल्यावर त्यातील मजकूर आपोआप बोलून दाखवा',
    },
    'settings_admission': {
      AppLanguage.en: 'Meeting admission',
      AppLanguage.hi: 'बैठक प्रवेश नियम',
      AppLanguage.mr: 'बैठक प्रवेश नियम',
    },
    'settings_backend_server': {
      AppLanguage.en: 'Backend AI Model Server URL',
      AppLanguage.hi: 'बैकएंड एआई मॉडल सर्वर URL',
      AppLanguage.mr: 'बॅकएंड एआय मॉडेल सर्व्हर URL',
    },
    'settings_on_device_title': {
      AppLanguage.en: '100% On-Device AI Engine',
      AppLanguage.hi: '100% ऑन-डिवाइस एआई इंजन',
      AppLanguage.mr: '100% ऑन-डिव्हाइस एआय इंजिन',
    },
    'settings_on_device_desc': {
      AppLanguage.en: 'ISL Sign Recognition (MediaPipe), Speech-to-Text, and Text-to-Speech execute 100% locally on your phone without external servers.',
      AppLanguage.hi: 'संकेत पहचान (MediaPipe), आवाज-से-पाठ, और पाठ-से-आवाज बिना किसी बाहरी सर्वर के सीधे आपके फोन पर काम करते हैं।',
      AppLanguage.mr: 'चिन्ह ओळख (MediaPipe), आवाज-ते-मजकूर, आणि मजकूर-ते-आवाज कोणत्याही बाह्य सर्व्हरशिवाय थेट तुमच्या फोनवर कार्य करतात.',
    },
    'settings_profile_section': {
      AppLanguage.en: 'Current Sensory Profile',
      AppLanguage.hi: 'वर्तमान संवेदी प्रोफ़ाइल',
      AppLanguage.mr: 'सध्याचे संवेदी प्रोफाइल',
    },
    'settings_change_profile_btn': {
      AppLanguage.en: 'Switch Sensory Profile',
      AppLanguage.hi: 'संवेदी प्रोफ़ाइल बदलें',
      AppLanguage.mr: 'संवेदी प्रोफाइल बदला',
    },
    'admission_allow_all': {
      AppLanguage.en: 'Allow everyone directly',
      AppLanguage.hi: 'सभी को सीधे प्रवेश दें',
      AppLanguage.mr: 'सर्वांना थेट प्रवेश द्या',
    },
    'admission_allow_all_desc': {
      AppLanguage.en: 'Anyone with the meeting code joins immediately.',
      AppLanguage.hi: 'मीटिंग कोड वाला कोई भी व्यक्ति तुरंत जुड़ जाएगा।',
      AppLanguage.mr: 'मीटिंग कोड असलेली कोणतीही व्यक्ती लगेच सामील होईल.',
    },
    'admission_ask': {
      AppLanguage.en: 'Always ask before letting someone in',
      AppLanguage.hi: 'किसी को अंदर आने देने से पहले हमेशा पूछें',
      AppLanguage.mr: 'कोणालाही आत घेण्यापूर्वी नेहमी विचारा',
    },
    'admission_ask_desc': {
      AppLanguage.en: 'New participants wait in a lobby until you admit them.',
      AppLanguage.hi: 'नए प्रतिभागी लॉबी में प्रतीक्षा करेंगे जब तक आप उन्हें प्रवेश न दें।',
      AppLanguage.mr: 'नवीन सहभागी तुम्ही प्रवेश देईपर्यंत लॉबीमध्ये थांबतील.',
    },
  };

  /// Sign label dictionary with translations in English, Hindi, and Marathi
  static final Map<String, Map<AppLanguage, String>> signTranslations = {
    'HELLO': {
      AppLanguage.en: 'Hello',
      AppLanguage.hi: 'नमस्ते',
      AppLanguage.mr: 'नमस्कार',
    },
    'THANK_YOU': {
      AppLanguage.en: 'Thank You',
      AppLanguage.hi: 'धन्यवाद',
      AppLanguage.mr: 'धन्यवाद',
    },
    'PLEASE': {
      AppLanguage.en: 'Please',
      AppLanguage.hi: 'कृपया',
      AppLanguage.mr: 'कृपया',
    },
    'SORRY': {
      AppLanguage.en: 'Sorry',
      AppLanguage.hi: 'माफ़ कीजिए',
      AppLanguage.mr: 'माफ करा',
    },
    'YES': {
      AppLanguage.en: 'Yes',
      AppLanguage.hi: 'हाँ',
      AppLanguage.mr: 'होय',
    },
    'NO': {
      AppLanguage.en: 'No',
      AppLanguage.hi: 'नहीं',
      AppLanguage.mr: 'नाही',
    },
    'HELP': {
      AppLanguage.en: 'Help',
      AppLanguage.hi: 'मदद',
      AppLanguage.mr: 'मदत',
    },
    // Letters & common gestures
    'HELLO / NAMASTE': {
      AppLanguage.en: 'Hello / Namaste',
      AppLanguage.hi: 'नमस्ते',
      AppLanguage.mr: 'नमस्कार',
    },
    'YES (Thumbs Up)': {
      AppLanguage.en: 'Yes',
      AppLanguage.hi: 'हाँ (सहमति)',
      AppLanguage.mr: 'होय (संमती)',
    },
    'NO / POINTING': {
      AppLanguage.en: 'No',
      AppLanguage.hi: 'नहीं',
      AppLanguage.mr: 'नाही',
    },
    'VICTORY / PEACE': {
      AppLanguage.en: 'Victory / Peace',
      AppLanguage.hi: 'विजय / शांति',
      AppLanguage.mr: 'विजय / शांतता',
    },
    'I LOVE YOU': {
      AppLanguage.en: 'I Love You',
      AppLanguage.hi: 'मुझे तुमसे प्यार है',
      AppLanguage.mr: 'माझे तुझ्यावर प्रेम आहे',
    },
    'OK': {
      AppLanguage.en: 'OK',
      AppLanguage.hi: 'ठीक है',
      AppLanguage.mr: 'ठीक आहे',
    },
  };

  /// Predefined quick phrases for TTS in each language
  static List<String> getQuickPhrases(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hi:
        return [
          'नमस्ते, आप कैसे हैं?',
          'बहुत बहुत धन्यवाद।',
          'कृपया मेरी मदद करें, मुझे सहायता चाहिए।',
          'मुझे पानी चाहिए।',
          'बाहर जाने का रास्ता कहाँ है?',
          'मैं सुन नहीं सकता, कृपया लिखकर बताएं।',
          'हाँ, मैं समझ गया।',
          'कृपया थोड़ा रुकिए।',
        ];
      case AppLanguage.mr:
        return [
          'नमस्कार, तुम्ही कसे आहात?',
          'खूप खूप धन्यवाद.',
          'कृपया मला मदत करा, मला सहाय्य हवे आहे.',
          'मला पाणी हवे आहे.',
          'बाहेर पडण्याचा मार्ग कुठे आहे?',
          'मी ऐकू शकत नाही, कृपया लिहून सांगा.',
          'होय, मला समजले.',
          'कृपया थोडा वेळ थांबा.',
        ];
      case AppLanguage.en:
        return [
          'Hello, how are you?',
          'Thank you very much.',
          'Please help me, I need assistance.',
          'I need water.',
          'Where is the exit?',
          'I cannot hear, please write it down.',
          'Yes, I understand.',
          'Please wait a moment.',
        ];
    }
  }

  /// Get localized text for a key
  static String tr(String key, AppLanguage language) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[language] ?? entry[AppLanguage.en] ?? key;
  }

  /// Translate a sign label into target language
  static String translateSign(String signKey, AppLanguage language) {
    final upper = signKey.toUpperCase().trim();
    final entry = signTranslations[upper] ?? signTranslations[signKey];
    if (entry != null) {
      return entry[language] ?? entry[AppLanguage.en] ?? signKey;
    }
    return signKey;
  }
}
