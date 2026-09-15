class S {
  const S(this.code);

  final String code;

  static const locales = [
    (code: 'fa', label: 'فارسی', flag: '🇮🇷'),
    (code: 'en', label: 'English', flag: '🇬🇧'),
    (code: 'zh', label: '中文', flag: '🇨🇳'),
    (code: 'ru', label: 'Русский', flag: '🇷🇺'),
  ];

  bool get rtl => code == 'fa';

  String get appName => 'vpnai';

  String t(String key) => _all[code]?[key] ?? _all['en']![key] ?? key;

  String get login => t('login');
  String get register => t('register');
  String get username => t('username');
  String get password => t('password');
  String get email => t('email');
  String get close => t('close');
  String get minimize => t('minimize');
  String get language => t('language');
  String get settings => t('settings');
  String get plans => t('plans');
  String get connected => t('connected');
  String get disconnected => t('disconnected');
  String get connecting => t('connecting');
  String get switching => t('switching');
  String get logout => t('logout');
  String get back => t('back');
  String get connect => t('connect');
  String get disconnect => t('disconnect');
  String get upload => t('upload');
  String get download => t('download');
  String get privacy => t('privacy');
  String get telegram => t('telegram');
  String get copy => t('copy');
  String get retry => t('retry');
  String get buy => t('buy');
  String get requiredField => t('requiredField');
  String get passwordShort => t('passwordShort');
  String get usernameInvalid => t('usernameInvalid');
  String get usernameTaken => t('usernameTaken');
  String get badCredentials => t('badCredentials');
  String get offline => t('offline');
  String get apiOff => t('apiOff');
  String get sessionExpired => t('sessionExpired');
  String get forbidden => t('forbidden');
  String get inactivePlan => t('inactivePlan');
  String get noServer => t('noServer');
  String get noPlans => t('noPlans');
  String get planActive => t('planActive');
  String get telegramFail => t('telegramFail');
  String get telegramTitle => t('telegramTitle');
  String get privacyBody => t('privacyBody');
  String get remaining => t('remaining');
  String get expires => t('expires');
  String get home => t('home');
  String get offer => t('offer');
  String get account => t('account');
  String get premium => t('premium');
  String get protectedStatus => t('protectedStatus');
  String get unprotectedStatus => t('unprotectedStatus');
  String get ping => t('ping');
  String get serverList => t('serverList');
  String get searchServers => t('searchServers');
  String get allServers => t('allServers');
  String get streamAndGame => t('streamAndGame');
  String get selectServer => t('selectServer');
  String get streamSection => t('streamSection');
  String get gameSection => t('gameSection');

  // Protection & automation
  String get securitySection => t('securitySection');
  String get automationSection => t('automationSection');
  String get networkSection => t('networkSection');
  String get accountSection => t('accountSection');
  String get killSwitch => t('killSwitch');
  String get killSwitchDesc => t('killSwitchDesc');
  String get killSwitchOff => t('killSwitchOff');
  String get killSwitchAuto => t('killSwitchAuto');
  String get killSwitchStrict => t('killSwitchStrict');
  String get killSwitchNeedsAdmin => t('killSwitchNeedsAdmin');
  String get killSwitchUnsupported => t('killSwitchUnsupported');
  String get runAsAdmin => t('runAsAdmin');
  String get internetLocked => t('internetLocked');
  String get internetLockedBody => t('internetLockedBody');
  String get unlockInternet => t('unlockInternet');
  String get autoConnectLaunch => t('autoConnectLaunch');
  String get autoConnectLaunchDesc => t('autoConnectLaunchDesc');
  String get autoBestServer => t('autoBestServer');
  String get autoBestServerDesc => t('autoBestServerDesc');
  String get smartSwitch => t('smartSwitch');
  String get smartSwitchDesc => t('smartSwitchDesc');
  String get smartSwitchOff => t('smartSwitchOff');
  String get smartSwitchAsk => t('smartSwitchAsk');
  String get smartSwitchAuto => t('smartSwitchAuto');
  String get autoReconnect => t('autoReconnect');
  String get autoReconnectDesc => t('autoReconnectDesc');
  String get allowLan => t('allowLan');
  String get allowLanDesc => t('allowLanDesc');
  String get blockIpv6 => t('blockIpv6');
  String get blockIpv6Desc => t('blockIpv6Desc');
  String get blockAds => t('blockAds');
  String get blockAdsDesc => t('blockAdsDesc');
  String get dnsProtection => t('dnsProtection');
  String get dnsProtectionDesc => t('dnsProtectionDesc');
  String get dnsAuto => t('dnsAuto');

  // Quality & notices
  String get quality => t('quality');
  String get qualityExcellent => t('qualityExcellent');
  String get qualityGood => t('qualityGood');
  String get qualityFair => t('qualityFair');
  String get qualityPoor => t('qualityPoor');
  String get qualityDead => t('qualityDead');
  String get jitter => t('jitter');
  String get packetLoss => t('packetLoss');
  String get betterServer => t('betterServer');
  String get switchNow => t('switchNow');
  String get notNow => t('notNow');
  String get switchedTo => t('switchedTo');
  String get reconnecting => t('reconnecting');
  String get reconnected => t('reconnected');
  String get internetDown => t('internetDown');
  String get scanningServers => t('scanningServers');

  // Diagnostics
  String get diagnostics => t('diagnostics');
  String get diagnosticsDesc => t('diagnosticsDesc');
  String get testServers => t('testServers');
  String get publicIp => t('publicIp');
  String get checkIp => t('checkIp');
  String get dataUsed => t('dataUsed');
  String get sessionHistory => t('sessionHistory');
  String get noHistory => t('noHistory');
  String get copyReport => t('copyReport');
  String get copied => t('copied');
  String get score => t('score');
  String get protectionStatus => t('protectionStatus');
  String get armed => t('armed');
  String get inactive => t('inactive');

  // Advanced routing & protection
  String get advancedSection => t('advancedSection');
  String get routingProfile => t('routingProfile');
  String get routingProfileDesc => t('routingProfileDesc');
  String get routingGlobal => t('routingGlobal');
  String get routingDomestic => t('routingDomestic');
  String get routingSelected => t('routingSelected');
  String get splitTunneling => t('splitTunneling');
  String get splitTunnelingDesc => t('splitTunnelingDesc');
  String get bypassApps => t('bypassApps');
  String get tunnelApps => t('tunnelApps');
  String get bypassDomains => t('bypassDomains');
  String get addItem => t('addItem');
  String get appExample => t('appExample');
  String get domainExample => t('domainExample');
  String get multiHop => t('multiHop');
  String get multiHopDesc => t('multiHopDesc');
  String get multiHopOff => t('multiHopOff');
  String get multiHopDouble => t('multiHopDouble');
  String get shadowTesting => t('shadowTesting');
  String get shadowTestingDesc => t('shadowTestingDesc');
  String get adaptiveMtu => t('adaptiveMtu');
  String get adaptiveMtuDesc => t('adaptiveMtuDesc');
  String get leakSentinel => t('leakSentinel');
  String get leakSentinelDesc => t('leakSentinelDesc');
  String get trustedNetworks => t('trustedNetworks');
  String get trustedNetworksDesc => t('trustedNetworksDesc');
  String get autoConnectUntrusted => t('autoConnectUntrusted');
  String get autoConnectUntrustedDesc => t('autoConnectUntrustedDesc');
  String get currentNetwork => t('currentNetwork');
  String get trustThisNetwork => t('trustThisNetwork');
  String get untrusted => t('untrusted');
  String get openNetwork => t('openNetwork');
  String get leakAudit => t('leakAudit');
  String get leakPass => t('leakPass');
  String get leakFail => t('leakFail');
  String get leakUnknown => t('leakUnknown');
  String get checkExitIp => t('checkExitIp');
  String get checkDns => t('checkDns');
  String get checkIpv6 => t('checkIpv6');
  String get checkTunnel => t('checkTunnel');
  String get realIp => t('realIp');
  String get runAudit => t('runAudit');
  String get throughput => t('throughput');
  String get mtuValue => t('mtuValue');
  String get leakDetected => t('leakDetected');

  /// "A better server is available: {name} (+{gain})".
  String betterServerBody(String name, int gain) => t('betterServerBody')
      .replaceAll('{name}', name)
      .replaceAll('{gain}', '$gain');

  String switchedToBody(String name) =>
      t('switchedToBody').replaceAll('{name}', name);

  static const _all = <String, Map<String, String>>{
    'fa': {
      'login': 'ورود',
      'register': 'ثبت‌نام',
      'username': 'نام کاربری',
      'password': 'رمز عبور',
      'email': 'ایمیل',
      'close': 'بستن',
      'minimize': 'کوچک‌کردن',
      'language': 'زبان',
      'settings': 'تنظیمات',
      'plans': 'پلن‌ها',
      'connected': 'متصل',
      'disconnected': 'قطع',
      'connecting': 'اتصال',
      'switching': 'تعویض سرور',
      'logout': 'خروج',
      'back': 'بازگشت',
      'connect': 'اتصال',
      'disconnect': 'قطع',
      'upload': 'آپلود',
      'download': 'دانلود',
      'privacy': 'حریم خصوصی',
      'telegram': 'تلگرام',
      'copy': 'کپی',
      'retry': 'تلاش دوباره',
      'buy': 'خرید',
      'requiredField': 'الزامی',
      'passwordShort': 'حداقل ۶ نویسه',
      'usernameInvalid':
          'نام کاربری باید ۳ تا ۳۲ کاراکتر انگلیسی، عدد یا _ باشد.',
      'usernameTaken': 'این نام کاربری قبلاً ثبت شده است.',
      'badCredentials': 'نام کاربری یا رمز نادرست است.',
      'offline': 'ارتباط برقرار نشد.',
      'apiOff': 'سرویس در دسترس نیست.',
      'sessionExpired': 'نشست منقضی شده است.',
      'forbidden': 'دسترسی مجاز نیست.',
      'inactivePlan': 'پلن فعال نیست.',
      'noServer': 'سروری در دسترس نیست.',
      'noPlans': 'پلنی موجود نیست.',
      'planActive': 'پلن فعال شد.',
      'telegramFail': 'کد ساخته نشد.',
      'telegramTitle': 'کد تلگرام',
      'privacyBody':
          'vpnai برای اتصال، هویت حساب و آمار نشست را با پنل رد و بدل می‌کند.',
      'remaining': 'باقی‌مانده',
      'expires': 'انقضا',
      'home': 'خانه',
      'offer': 'پیشنهاد',
      'account': 'حساب',
      'premium': 'پرمیوم',
      'protectedStatus': 'محافظت‌شده',
      'unprotectedStatus': 'بدون محافظت',
      'ping': 'پینگ',
      'serverList': 'لیست سرور',
      'searchServers': 'جستجوی Netflix، بازی...',
      'allServers': 'همه',
      'streamAndGame': 'استریم و بازی',
      'selectServer': 'انتخاب سرور',
      'streamSection': 'استریم',
      'gameSection': 'بازی',
      'securitySection': 'امنیت و محافظت',
      'automationSection': 'هوشمند و خودکار',
      'networkSection': 'شبکه',
      'accountSection': 'حساب و اشتراک',
      'killSwitch': 'کیل سویچ',
      'killSwitchDesc':
          'اگر تونل قطع شد، تمام ترافیک در فایروال بسته می‌شود تا آی‌پی واقعی لو نرود.',
      'killSwitchOff': 'خاموش',
      'killSwitchAuto': 'خودکار (هنگام قطعی)',
      'killSwitchStrict': 'سخت‌گیرانه (همیشه)',
      'killSwitchNeedsAdmin':
          'برای قفل واقعی فایروال، اپ باید با دسترسی مدیر اجرا شود.',
      'killSwitchUnsupported': 'این سیستم از قفل فایروال پشتیبانی نمی‌کند.',
      'runAsAdmin': 'اجرا با دسترسی مدیر',
      'internetLocked': 'اینترنت قفل شد',
      'internetLockedBody':
          'تونل قطع شد و کیل سویچ جلوی نشت ترافیک را گرفت. در حال اتصال دوباره…',
      'unlockInternet': 'بازکردن اینترنت',
      'autoConnectLaunch': 'اتصال خودکار در اجرا',
      'autoConnectLaunchDesc': 'با باز شدن اپ، خودش به بهترین سرور وصل می‌شود.',
      'autoBestServer': 'انتخاب خودکار بهترین سرور',
      'autoBestServerDesc':
          'سرورها با پینگ، جیتر و اتلاف بسته سنجیده و سریع‌ترین انتخاب می‌شود.',
      'smartSwitch': 'تعویض هوشمند سرور',
      'smartSwitchDesc':
          'وقتی کیفیت افت کند، سرور بهتر پیدا می‌شود؛ با اجازه شما یا خودکار.',
      'smartSwitchOff': 'خاموش',
      'smartSwitchAsk': 'با تأیید من',
      'smartSwitchAuto': 'خودکار',
      'autoReconnect': 'اتصال دوباره خودکار',
      'autoReconnectDesc': 'پس از قطعی، با فاصله‌های فزاینده تلاش می‌کند.',
      'allowLan': 'دسترسی به شبکه محلی',
      'allowLanDesc': 'پرینتر و دستگاه‌های خانه در حال اتصال هم در دسترس بمانند.',
      'blockIpv6': 'مسدودسازی IPv6',
      'blockIpv6Desc': 'جلوگیری از نشت آی‌پی نسخه ۶ بیرون از تونل.',
      'blockAds': 'مسدودسازی تبلیغ و ردیاب',
      'blockAdsDesc': 'دامنه‌های تبلیغاتی و ردیابی داخل تونل بلاک می‌شوند.',
      'dnsProtection': 'DNS رمزنگاری‌شده',
      'dnsProtectionDesc': 'جلوگیری از نشت DNS با DoH داخل تونل.',
      'dnsAuto': 'پیش‌فرض پنل',
      'quality': 'کیفیت',
      'qualityExcellent': 'عالی',
      'qualityGood': 'خوب',
      'qualityFair': 'متوسط',
      'qualityPoor': 'ضعیف',
      'qualityDead': 'قطع',
      'jitter': 'جیتر',
      'packetLoss': 'اتلاف',
      'betterServer': 'سرور بهتری پیدا شد',
      'betterServerBody': 'اتصال به {name} حدود {gain} امتیاز بهتر است. عوض شود؟',
      'switchNow': 'عوض کن',
      'notNow': 'الان نه',
      'switchedTo': 'سرور عوض شد',
      'switchedToBody': 'اکنون به {name} متصل هستید.',
      'reconnecting': 'در حال اتصال دوباره…',
      'reconnected': 'اتصال برگشت',
      'internetDown': 'اینترنت دستگاه قطع است',
      'scanningServers': 'سنجش سرورها…',
      'diagnostics': 'عیب‌یابی و تست شبکه',
      'diagnosticsDesc': 'تست سرورها، آی‌پی و وضعیت محافظت.',
      'testServers': 'تست همه سرورها',
      'publicIp': 'آی‌پی عمومی',
      'checkIp': 'بررسی آی‌پی',
      'dataUsed': 'مصرف داده',
      'sessionHistory': 'نشست‌های اخیر',
      'noHistory': 'هنوز نشستی ثبت نشده.',
      'copyReport': 'کپی گزارش',
      'copied': 'کپی شد',
      'score': 'امتیاز',
      'protectionStatus': 'وضعیت محافظت',
      'armed': 'آماده',
      'inactive': 'غیرفعال',
      'advancedSection': 'پیشرفته',
      'routingProfile': 'حالت مسیریابی',
      'routingProfileDesc':
          'انتخاب کنید چه ترافیکی از تونل برود؛ عبور مستقیم سایت‌های ایرانی سرعت بانک و سایت‌های داخلی را حفظ می‌کند.',
      'routingGlobal': 'همه از تونل',
      'routingDomestic': 'ایران مستقیم',
      'routingSelected': 'فقط برنامه‌های انتخابی',
      'splitTunneling': 'تانل‌سازی تفکیکی',
      'splitTunnelingDesc':
          'برنامه‌ها و دامنه‌هایی که باید از تونل خارج یا داخل شوند را مشخص کنید.',
      'bypassApps': 'برنامه‌های بیرون از تونل',
      'tunnelApps': 'برنامه‌های داخل تونل',
      'bypassDomains': 'دامنه‌های بیرون از تونل',
      'addItem': 'افزودن',
      'appExample': 'مثال: chrome.exe',
      'domainExample': 'مثال: bank.ir',
      'multiHop': 'مالتی‌هاپ (تونل دوگانه)',
      'multiHopDesc':
          'ترافیک از دو سرور پشت سر هم می‌گذرد؛ سرور ورودی آی‌پی خروجی شما را نمی‌داند.',
      'multiHopOff': 'یک هاپ',
      'multiHopDouble': 'دو هاپ',
      'shadowTesting': 'تست واقعی سرعت (سایه)',
      'shadowTestingDesc':
          'سرورهای کاندید با یک هسته‌ی جداگانه و دانلود واقعی سنجیده می‌شوند، بدون قطع اتصال فعلی.',
      'adaptiveMtu': 'تنظیم خودکار MTU',
      'adaptiveMtuDesc':
          'بزرگ‌ترین بسته‌ی بدون تکه‌شدن پیدا و روی تونل تنظیم می‌شود تا سرعت نخوابد.',
      'leakSentinel': 'نگهبان نشتی',
      'leakSentinelDesc':
          'مرتب بررسی می‌شود که آی‌پی خروجی عوض شده، DNS سالم است و IPv6 بسته است.',
      'trustedNetworks': 'شبکه‌های مطمئن',
      'trustedNetworksDesc': 'در این شبکه‌ها اتصال خودکار انجام نمی‌شود.',
      'autoConnectUntrusted': 'اتصال خودکار در شبکه ناامن',
      'autoConnectUntrustedDesc':
          'با اتصال به وای‌فای عمومی یا ناشناس، تونل خودش بالا می‌آید.',
      'currentNetwork': 'شبکه فعلی',
      'trustThisNetwork': 'مطمئن است',
      'untrusted': 'نامطمئن',
      'openNetwork': 'بدون رمز',
      'leakAudit': 'بازرسی نشتی',
      'leakPass': 'سالم',
      'leakFail': 'نشتی',
      'leakUnknown': 'نامعلوم',
      'checkExitIp': 'آی‌پی خروجی',
      'checkDns': 'DNS',
      'checkIpv6': 'IPv6',
      'checkTunnel': 'تونل',
      'realIp': 'آی‌پی واقعی',
      'runAudit': 'اجرای بازرسی',
      'throughput': 'سرعت واقعی',
      'mtuValue': 'MTU',
      'leakDetected': 'احتمال نشت شناسایی شد',
    },
    'en': {
      'login': 'Sign in',
      'register': 'Create account',
      'username': 'Username',
      'password': 'Password',
      'email': 'Email',
      'close': 'Close',
      'minimize': 'Minimize',
      'language': 'Language',
      'settings': 'Setting',
      'plans': 'Plans',
      'connected': 'Connected',
      'disconnected': 'Disconnected',
      'connecting': 'Connecting',
      'switching': 'Switching',
      'logout': 'Sign out',
      'back': 'Back',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'upload': 'Upload',
      'download': 'Download',
      'privacy': 'Privacy',
      'telegram': 'Telegram',
      'copy': 'Copy',
      'retry': 'Retry',
      'buy': 'Buy',
      'requiredField': 'Required',
      'passwordShort': 'At least 6 characters',
      'usernameInvalid': 'Use 3–32 Latin letters, numbers, or underscores.',
      'usernameTaken': 'Username already exists.',
      'badCredentials': 'Wrong username or password.',
      'offline': 'Could not reach the server.',
      'apiOff': 'Service unavailable.',
      'sessionExpired': 'Session expired.',
      'forbidden': 'Not allowed.',
      'inactivePlan': 'No active plan.',
      'noServer': 'No server available.',
      'noPlans': 'No plans.',
      'planActive': 'Plan activated.',
      'telegramFail': 'Could not create a code.',
      'telegramTitle': 'Telegram code',
      'privacyBody':
          'vpnai exchanges account identity and session stats with your panel to establish the tunnel.',
      'remaining': 'Left',
      'expires': 'Expires',
      'home': 'Home',
      'offer': 'Offer & Update',
      'account': 'Account',
      'premium': 'Premium',
      'protectedStatus': 'Protected',
      'unprotectedStatus': 'Unprotected',
      'ping': 'Ping',
      'serverList': 'Server List',
      'searchServers': 'Search Netflix, games...',
      'allServers': 'All',
      'streamAndGame': 'Stream & Game',
      'selectServer': 'Select server',
      'streamSection': 'STREAM',
      'gameSection': 'GAME',
      'securitySection': 'Security & protection',
      'automationSection': 'Smart automation',
      'networkSection': 'Network',
      'accountSection': 'Account & plan',
      'killSwitch': 'Kill switch',
      'killSwitchDesc':
          'If the tunnel drops, all traffic is blocked at the firewall so your real IP never leaks.',
      'killSwitchOff': 'Off',
      'killSwitchAuto': 'Auto (on drop)',
      'killSwitchStrict': 'Strict (always)',
      'killSwitchNeedsAdmin':
          'Run the app as administrator to enforce the firewall lock.',
      'killSwitchUnsupported': 'This system cannot enforce a firewall lock.',
      'runAsAdmin': 'Restart as administrator',
      'internetLocked': 'Internet locked',
      'internetLockedBody':
          'The tunnel dropped and the kill switch blocked every leak. Reconnecting…',
      'unlockInternet': 'Unlock internet',
      'autoConnectLaunch': 'Connect on launch',
      'autoConnectLaunchDesc': 'Connect to the best server as soon as the app opens.',
      'autoBestServer': 'Auto-pick best server',
      'autoBestServerDesc':
          'Servers are ranked by latency, jitter and packet loss before connecting.',
      'smartSwitch': 'Smart server switching',
      'smartSwitchDesc':
          'When quality drops, a better server is found — with your approval or automatically.',
      'smartSwitchOff': 'Off',
      'smartSwitchAsk': 'Ask me first',
      'smartSwitchAuto': 'Automatic',
      'autoReconnect': 'Auto reconnect',
      'autoReconnectDesc': 'Retry with increasing backoff after a drop.',
      'allowLan': 'Allow local network',
      'allowLanDesc': 'Keep printers and home devices reachable while connected.',
      'blockIpv6': 'Block IPv6',
      'blockIpv6Desc': 'Prevents IPv6 traffic from escaping the tunnel.',
      'blockAds': 'Block ads & trackers',
      'blockAdsDesc': 'Ad and tracking domains are sinkholed inside the tunnel.',
      'dnsProtection': 'Encrypted DNS',
      'dnsProtectionDesc': 'Stops DNS leaks using DoH inside the tunnel.',
      'dnsAuto': 'Panel default',
      'quality': 'Quality',
      'qualityExcellent': 'Excellent',
      'qualityGood': 'Good',
      'qualityFair': 'Fair',
      'qualityPoor': 'Poor',
      'qualityDead': 'Down',
      'jitter': 'Jitter',
      'packetLoss': 'Loss',
      'betterServer': 'A better server is available',
      'betterServerBody': '{name} scores about {gain} points higher. Switch?',
      'switchNow': 'Switch',
      'notNow': 'Not now',
      'switchedTo': 'Server switched',
      'switchedToBody': 'You are now on {name}.',
      'reconnecting': 'Reconnecting…',
      'reconnected': 'Connection restored',
      'internetDown': 'Device has no internet',
      'scanningServers': 'Measuring servers…',
      'diagnostics': 'Diagnostics & network test',
      'diagnosticsDesc': 'Test servers, IP and protection status.',
      'testServers': 'Test all servers',
      'publicIp': 'Public IP',
      'checkIp': 'Check IP',
      'dataUsed': 'Data used',
      'sessionHistory': 'Recent sessions',
      'noHistory': 'No sessions yet.',
      'copyReport': 'Copy report',
      'copied': 'Copied',
      'score': 'Score',
      'protectionStatus': 'Protection status',
      'armed': 'Armed',
      'inactive': 'Inactive',
      'advancedSection': 'Advanced',
      'routingProfile': 'Routing mode',
      'routingProfileDesc':
          'Choose what goes through the tunnel. Keeping domestic sites direct preserves local banking speed.',
      'routingGlobal': 'Everything tunnelled',
      'routingDomestic': 'Domestic direct',
      'routingSelected': 'Selected apps only',
      'splitTunneling': 'Split tunneling',
      'splitTunnelingDesc':
          'Pick which apps and domains stay outside or inside the tunnel.',
      'bypassApps': 'Apps outside the tunnel',
      'tunnelApps': 'Apps inside the tunnel',
      'bypassDomains': 'Domains outside the tunnel',
      'addItem': 'Add',
      'appExample': 'e.g. chrome.exe',
      'domainExample': 'e.g. bank.ir',
      'multiHop': 'Multi-hop (double tunnel)',
      'multiHopDesc':
          'Traffic passes through two servers, so the entry node never learns your exit address.',
      'multiHopOff': 'Single hop',
      'multiHopDouble': 'Double hop',
      'shadowTesting': 'Real speed testing (shadow)',
      'shadowTestingDesc':
          'Candidates are measured with a separate core and a real download, without touching your live tunnel.',
      'adaptiveMtu': 'Adaptive MTU',
      'adaptiveMtuDesc':
          'Finds the largest packet that survives the path and tunes the tunnel so transfers never stall.',
      'leakSentinel': 'Leak sentinel',
      'leakSentinelDesc':
          'Continuously verifies the exit IP changed, DNS is sane and IPv6 is blocked.',
      'trustedNetworks': 'Trusted networks',
      'trustedNetworksDesc': 'Automation stays quiet on these networks.',
      'autoConnectUntrusted': 'Auto-connect on untrusted Wi-Fi',
      'autoConnectUntrustedDesc':
          'Joining a public or unknown network brings the tunnel up by itself.',
      'currentNetwork': 'Current network',
      'trustThisNetwork': 'Trusted',
      'untrusted': 'Untrusted',
      'openNetwork': 'Open',
      'leakAudit': 'Leak audit',
      'leakPass': 'Pass',
      'leakFail': 'Leak',
      'leakUnknown': 'Unknown',
      'checkExitIp': 'Exit IP',
      'checkDns': 'DNS',
      'checkIpv6': 'IPv6',
      'checkTunnel': 'Tunnel',
      'realIp': 'Real IP',
      'runAudit': 'Run audit',
      'throughput': 'Real speed',
      'mtuValue': 'MTU',
      'leakDetected': 'Possible leak detected',
    },
    'zh': {
      'login': '登录',
      'register': '注册',
      'username': '用户名',
      'password': '密码',
      'email': '邮箱',
      'close': '关闭',
      'minimize': '最小化',
      'language': '语言',
      'settings': '设置',
      'plans': '套餐',
      'connected': '已连接',
      'disconnected': '未连接',
      'connecting': '连接中',
      'switching': '切换节点',
      'logout': '退出',
      'back': '返回',
      'connect': '连接',
      'disconnect': '断开',
      'upload': '上传',
      'download': '下载',
      'privacy': '隐私',
      'telegram': 'Telegram',
      'copy': '复制',
      'retry': '重试',
      'buy': '购买',
      'requiredField': '必填',
      'passwordShort': '至少 6 个字符',
      'usernameInvalid': '用户名需为 3–32 位英文、数字或下划线。',
      'usernameTaken': '用户名已存在。',
      'badCredentials': '用户名或密码错误。',
      'offline': '无法连接服务器。',
      'apiOff': '服务不可用。',
      'sessionExpired': '会话已过期。',
      'forbidden': '无权限。',
      'inactivePlan': '套餐未激活。',
      'noServer': '没有可用节点。',
      'noPlans': '暂无套餐。',
      'planActive': '套餐已激活。',
      'telegramFail': '无法生成代码。',
      'telegramTitle': 'Telegram 代码',
      'privacyBody': 'vpnai 会与面板交换账户身份和会话统计以建立隧道。',
      'remaining': '剩余',
      'expires': '到期',
      'home': '首页',
      'offer': '优惠',
      'account': '账户',
      'premium': '高级',
      'protectedStatus': '已保护',
      'unprotectedStatus': '未保护',
      'ping': '延迟',
      'serverList': '服务器列表',
      'searchServers': '搜索 Netflix、游戏...',
      'allServers': '全部',
      'streamAndGame': '流媒体与游戏',
      'selectServer': '选择服务器',
      'streamSection': '流媒体',
      'gameSection': '游戏',
      'securitySection': '安全与防护',
      'automationSection': '智能自动化',
      'networkSection': '网络',
      'accountSection': '账户与套餐',
      'killSwitch': '断网保护',
      'killSwitchDesc': '隧道中断时在防火墙层阻断所有流量，真实 IP 不会泄露。',
      'killSwitchOff': '关闭',
      'killSwitchAuto': '自动（断线时）',
      'killSwitchStrict': '严格（始终）',
      'killSwitchNeedsAdmin': '需以管理员身份运行才能启用防火墙锁定。',
      'killSwitchUnsupported': '当前系统无法执行防火墙锁定。',
      'runAsAdmin': '以管理员身份重启',
      'internetLocked': '网络已锁定',
      'internetLockedBody': '隧道中断，断网保护已阻止泄露。正在重连…',
      'unlockInternet': '解锁网络',
      'autoConnectLaunch': '启动时自动连接',
      'autoConnectLaunchDesc': '打开应用后自动连接到最佳服务器。',
      'autoBestServer': '自动选择最佳服务器',
      'autoBestServerDesc': '按延迟、抖动和丢包排序后再连接。',
      'smartSwitch': '智能切换服务器',
      'smartSwitchDesc': '质量下降时寻找更好的服务器，可询问或自动切换。',
      'smartSwitchOff': '关闭',
      'smartSwitchAsk': '先询问我',
      'smartSwitchAuto': '自动',
      'autoReconnect': '自动重连',
      'autoReconnectDesc': '断线后以递增间隔重试。',
      'allowLan': '允许局域网',
      'allowLanDesc': '连接时仍可访问打印机等本地设备。',
      'blockIpv6': '阻止 IPv6',
      'blockIpv6Desc': '防止 IPv6 流量绕过隧道。',
      'blockAds': '拦截广告与追踪',
      'blockAdsDesc': '在隧道内屏蔽广告和追踪域名。',
      'dnsProtection': '加密 DNS',
      'dnsProtectionDesc': '在隧道内使用 DoH 防止 DNS 泄露。',
      'dnsAuto': '面板默认',
      'quality': '质量',
      'qualityExcellent': '极佳',
      'qualityGood': '良好',
      'qualityFair': '一般',
      'qualityPoor': '较差',
      'qualityDead': '中断',
      'jitter': '抖动',
      'packetLoss': '丢包',
      'betterServer': '发现更好的服务器',
      'betterServerBody': '{name} 大约高出 {gain} 分，要切换吗？',
      'switchNow': '切换',
      'notNow': '暂不',
      'switchedTo': '已切换服务器',
      'switchedToBody': '现已连接到 {name}。',
      'reconnecting': '正在重连…',
      'reconnected': '连接已恢复',
      'internetDown': '设备无网络',
      'scanningServers': '正在测速…',
      'diagnostics': '诊断与网络测试',
      'diagnosticsDesc': '测试服务器、IP 与防护状态。',
      'testServers': '测试所有服务器',
      'publicIp': '公网 IP',
      'checkIp': '检查 IP',
      'dataUsed': '流量使用',
      'sessionHistory': '最近会话',
      'noHistory': '暂无会话记录。',
      'copyReport': '复制报告',
      'copied': '已复制',
      'score': '评分',
      'protectionStatus': '防护状态',
      'armed': '已就绪',
      'inactive': '未启用',
      'advancedSection': '高级',
      'routingProfile': '路由模式',
      'routingProfileDesc': '选择哪些流量走隧道；本地站点直连可保持本地速度。',
      'routingGlobal': '全部走隧道',
      'routingDomestic': '本地直连',
      'routingSelected': '仅指定应用',
      'splitTunneling': '分应用代理',
      'splitTunnelingDesc': '指定哪些应用和域名走或不走隧道。',
      'bypassApps': '不走隧道的应用',
      'tunnelApps': '走隧道的应用',
      'bypassDomains': '不走隧道的域名',
      'addItem': '添加',
      'appExample': '例如 chrome.exe',
      'domainExample': '例如 bank.ir',
      'multiHop': '多跳（双重隧道）',
      'multiHopDesc': '流量经过两台服务器，入口节点无法得知出口地址。',
      'multiHopOff': '单跳',
      'multiHopDouble': '双跳',
      'shadowTesting': '真实测速（影子）',
      'shadowTestingDesc': '用独立内核和真实下载测量候选节点，不影响当前连接。',
      'adaptiveMtu': '自适应 MTU',
      'adaptiveMtuDesc': '探测链路可通过的最大包并调整隧道，避免传输停滞。',
      'leakSentinel': '泄露哨兵',
      'leakSentinelDesc': '持续校验出口 IP 已改变、DNS 正常、IPv6 已阻断。',
      'trustedNetworks': '受信网络',
      'trustedNetworksDesc': '在这些网络中不自动连接。',
      'autoConnectUntrusted': '在不受信 Wi-Fi 自动连接',
      'autoConnectUntrustedDesc': '连接公共或陌生网络时自动开启隧道。',
      'currentNetwork': '当前网络',
      'trustThisNetwork': '受信',
      'untrusted': '不受信',
      'openNetwork': '开放',
      'leakAudit': '泄露检测',
      'leakPass': '正常',
      'leakFail': '泄露',
      'leakUnknown': '未知',
      'checkExitIp': '出口 IP',
      'checkDns': 'DNS',
      'checkIpv6': 'IPv6',
      'checkTunnel': '隧道',
      'realIp': '真实 IP',
      'runAudit': '开始检测',
      'throughput': '真实速度',
      'mtuValue': 'MTU',
      'leakDetected': '检测到可能的泄露',
    },
    'ru': {
      'login': 'Войти',
      'register': 'Регистрация',
      'username': 'Имя пользователя',
      'password': 'Пароль',
      'email': 'Эл. почта',
      'close': 'Закрыть',
      'minimize': 'Свернуть',
      'language': 'Язык',
      'settings': 'Настройки',
      'plans': 'Тарифы',
      'connected': 'Подключено',
      'disconnected': 'Отключено',
      'connecting': 'Подключение',
      'switching': 'Смена сервера',
      'logout': 'Выйти',
      'back': 'Назад',
      'connect': 'Подключить',
      'disconnect': 'Отключить',
      'upload': 'Исходящий',
      'download': 'Входящий',
      'privacy': 'Конфиденциальность',
      'telegram': 'Telegram',
      'copy': 'Копировать',
      'retry': 'Повтор',
      'buy': 'Купить',
      'requiredField': 'Обязательно',
      'passwordShort': 'Не менее 6 символов',
      'usernameInvalid': 'Имя: 3–32 латинских буквы, цифры или _.',
      'usernameTaken': 'Имя пользователя уже занято.',
      'badCredentials': 'Неверное имя или пароль.',
      'offline': 'Нет связи с сервером.',
      'apiOff': 'Сервис недоступен.',
      'sessionExpired': 'Сессия истекла.',
      'forbidden': 'Нет доступа.',
      'inactivePlan': 'Нет активного тарифа.',
      'noServer': 'Нет доступного сервера.',
      'noPlans': 'Нет тарифов.',
      'planActive': 'Тариф активирован.',
      'telegramFail': 'Не удалось создать код.',
      'telegramTitle': 'Код Telegram',
      'privacyBody':
          'vpnai обменивается данными аккаунта и сессии с панелью для установления туннеля.',
      'remaining': 'Остаток',
      'expires': 'Истекает',
      'home': 'Главная',
      'offer': 'Акции',
      'account': 'Аккаунт',
      'premium': 'Premium',
      'protectedStatus': 'Защищено',
      'unprotectedStatus': 'Без защиты',
      'ping': 'Пинг',
      'serverList': 'Список серверов',
      'searchServers': 'Поиск Netflix, игр...',
      'allServers': 'Все',
      'streamAndGame': 'Стрим и игры',
      'selectServer': 'Выбор сервера',
      'streamSection': 'СТРИМ',
      'gameSection': 'ИГРЫ',
      'securitySection': 'Безопасность и защита',
      'automationSection': 'Умная автоматика',
      'networkSection': 'Сеть',
      'accountSection': 'Аккаунт и тариф',
      'killSwitch': 'Kill switch',
      'killSwitchDesc':
          'Если туннель упал, весь трафик блокируется брандмауэром — реальный IP не утечёт.',
      'killSwitchOff': 'Выключен',
      'killSwitchAuto': 'Авто (при обрыве)',
      'killSwitchStrict': 'Строгий (всегда)',
      'killSwitchNeedsAdmin':
          'Запустите приложение от имени администратора для блокировки.',
      'killSwitchUnsupported': 'Система не поддерживает блокировку брандмауэром.',
      'runAsAdmin': 'Перезапустить как администратор',
      'internetLocked': 'Интернет заблокирован',
      'internetLockedBody':
          'Туннель оборвался, kill switch не допустил утечки. Переподключение…',
      'unlockInternet': 'Разблокировать интернет',
      'autoConnectLaunch': 'Подключаться при запуске',
      'autoConnectLaunchDesc': 'Сразу подключаться к лучшему серверу.',
      'autoBestServer': 'Авто-выбор лучшего сервера',
      'autoBestServerDesc':
          'Серверы оцениваются по задержке, джиттеру и потерям пакетов.',
      'smartSwitch': 'Умная смена сервера',
      'smartSwitchDesc':
          'При падении качества ищется лучший сервер — с вашего согласия или автоматически.',
      'smartSwitchOff': 'Выключено',
      'smartSwitchAsk': 'Спрашивать меня',
      'smartSwitchAuto': 'Автоматически',
      'autoReconnect': 'Авто-переподключение',
      'autoReconnectDesc': 'Повтор с растущими интервалами после обрыва.',
      'allowLan': 'Доступ к локальной сети',
      'allowLanDesc': 'Принтеры и домашние устройства остаются доступны.',
      'blockIpv6': 'Блокировать IPv6',
      'blockIpv6Desc': 'Не даёт трафику IPv6 выйти из туннеля.',
      'blockAds': 'Блокировать рекламу и трекеры',
      'blockAdsDesc': 'Рекламные и трекинговые домены блокируются в туннеле.',
      'dnsProtection': 'Шифрованный DNS',
      'dnsProtectionDesc': 'Защита от утечек DNS через DoH внутри туннеля.',
      'dnsAuto': 'По умолчанию панели',
      'quality': 'Качество',
      'qualityExcellent': 'Отлично',
      'qualityGood': 'Хорошо',
      'qualityFair': 'Средне',
      'qualityPoor': 'Плохо',
      'qualityDead': 'Обрыв',
      'jitter': 'Джиттер',
      'packetLoss': 'Потери',
      'betterServer': 'Есть сервер получше',
      'betterServerBody': '{name} лучше примерно на {gain} баллов. Переключить?',
      'switchNow': 'Переключить',
      'notNow': 'Не сейчас',
      'switchedTo': 'Сервер изменён',
      'switchedToBody': 'Вы подключены к {name}.',
      'reconnecting': 'Переподключение…',
      'reconnected': 'Связь восстановлена',
      'internetDown': 'На устройстве нет интернета',
      'scanningServers': 'Измеряем серверы…',
      'diagnostics': 'Диагностика и тест сети',
      'diagnosticsDesc': 'Тест серверов, IP и статус защиты.',
      'testServers': 'Проверить все серверы',
      'publicIp': 'Публичный IP',
      'checkIp': 'Проверить IP',
      'dataUsed': 'Трафик',
      'sessionHistory': 'Последние сессии',
      'noHistory': 'Сессий пока нет.',
      'copyReport': 'Копировать отчёт',
      'copied': 'Скопировано',
      'score': 'Балл',
      'protectionStatus': 'Статус защиты',
      'armed': 'Готов',
      'inactive': 'Отключено',
      'advancedSection': 'Расширенные',
      'routingProfile': 'Режим маршрутизации',
      'routingProfileDesc':
          'Выберите, что идёт через туннель. Локальные сайты напрямую — быстрее банк и local-сервисы.',
      'routingGlobal': 'Всё через туннель',
      'routingDomestic': 'Локальные напрямую',
      'routingSelected': 'Только выбранные приложения',
      'splitTunneling': 'Раздельное туннелирование',
      'splitTunnelingDesc':
          'Укажите приложения и домены вне или внутри туннеля.',
      'bypassApps': 'Приложения вне туннеля',
      'tunnelApps': 'Приложения в туннеле',
      'bypassDomains': 'Домены вне туннеля',
      'addItem': 'Добавить',
      'appExample': 'напр. chrome.exe',
      'domainExample': 'напр. bank.ir',
      'multiHop': 'Мульти-хоп (двойной туннель)',
      'multiHopDesc':
          'Трафик идёт через два сервера: входной узел не знает выходной адрес.',
      'multiHopOff': 'Один хоп',
      'multiHopDouble': 'Два хопа',
      'shadowTesting': 'Реальный тест скорости',
      'shadowTestingDesc':
          'Кандидаты измеряются отдельным ядром и реальной загрузкой, не трогая активный туннель.',
      'adaptiveMtu': 'Адаптивный MTU',
      'adaptiveMtuDesc':
          'Находит максимальный проходящий пакет и настраивает туннель, чтобы передача не вставала.',
      'leakSentinel': 'Сторож утечек',
      'leakSentinelDesc':
          'Постоянно проверяет смену выходного IP, корректность DNS и блокировку IPv6.',
      'trustedNetworks': 'Доверенные сети',
      'trustedNetworksDesc': 'В этих сетях автоматика не срабатывает.',
      'autoConnectUntrusted': 'Автоподключение в недоверенной сети',
      'autoConnectUntrustedDesc':
          'При подключении к публичной или незнакомой сети туннель включится сам.',
      'currentNetwork': 'Текущая сеть',
      'trustThisNetwork': 'Доверенная',
      'untrusted': 'Недоверенная',
      'openNetwork': 'Открытая',
      'leakAudit': 'Проверка утечек',
      'leakPass': 'Ок',
      'leakFail': 'Утечка',
      'leakUnknown': 'Неизвестно',
      'checkExitIp': 'Выходной IP',
      'checkDns': 'DNS',
      'checkIpv6': 'IPv6',
      'checkTunnel': 'Туннель',
      'realIp': 'Реальный IP',
      'runAudit': 'Проверить',
      'throughput': 'Реальная скорость',
      'mtuValue': 'MTU',
      'leakDetected': 'Возможная утечка',
    },
  };
}
