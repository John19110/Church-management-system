/* =========================================================
   My Church — landing page interactivity
   Reproduces (in vanilla JS) the behavior that Flutter handled via
   localeProvider (language), themeProvider (dark mode), and
   go_router (login/register/contact/privacy/deletion navigation).
   ========================================================= */

(function () {
  'use strict';

  /* ---- Configuration: Flutter app routes + API-hosted legal pages ---- */
  var CONFIG = {
    // Privacy / account-deletion are served by the ASP.NET API host.
    baseUrl: 'https://mychurchwebapp-cdfpdedgfdd7cqhb.germanywestcentral-01.azurewebsites.net',
    routes: {
      login: '/login',
      register: '/register'
    }
  };

  /* ---- Translation strings (EN / AR), keyed the same as the Flutter l10n getters ---- */
  var STRINGS = {
    en: {
      appTitle: 'My Church',
      landingBrandSubtitle: 'Always abounding in the work of the Lord',
      landingBrandSubtitle2: '(1 Corinthians 15:58)',
      login: 'Log in',
      register: 'Register',
      english: 'English',
      arabic: 'العربية',
      lightMode: 'Light mode',
      darkMode: 'Dark mode',


      landingRegNumber1: '1',
      landingRegNumber2: '2',
      landingRegNumber3: '3',
      landingRegNumber4: '4',
      landingRegNumber5: '5',
      landingRegNumber6: '6',
      landingRegNumber7: '7',

      landingHowNumber1: '01',
      landingHowNumber2: '02',
      landingHowNumber3: '03',
      landingHowNumber4: '04',
      landingHowNumber5: '05',

      landingHeroHeadline: 'Everything your church needs. In one place.',
      landingHeroSubtitle: "My Church helps you organize people, attendance, classrooms, and ministries with less paperwork and fewer disconnected tools.",

      landingFeaturesTitle: 'Everything your church needs, in one place',
      landingFeaturesSubtitle: 'Built specifically for the way churches operate, from Sunday services to weekday ministries.',
      landingFeatureChurchTitle: 'Church profile',
      landingFeatureChurchBody: "Set up your church's details and ministries once, and keep everyone working from the same source of truth.",
      landingFeaturePeopleTitle: 'People',
      landingFeaturePeopleBody: 'Keep a complete, up-to-date record of every member, servant, and family in your congregation.',
      landingFeatureAttendanceTitle: 'Attendance',
      landingFeatureAttendanceBody: 'Track attendance for services, classes, and events in seconds, and see participation trends over time.',
      landingFeatureClassroomsTitle: 'Groups',
      landingFeatureClassroomsBody: 'Manage Bible studies, children ministries, youth groups, and classes with rosters, schedules, and servants.',
      landingFeatureCustomFieldsTitle: 'Custom fields',
      landingFeatureCustomFieldsBody: 'Capture exactly the information your church cares about by adding your own fields to any record.',
      landingFeatureRolesTitle: 'Roles & permissions',
      landingFeatureRolesBody: 'Give servants access to only what they need, with clear roles for every responsibility.',
     
      landingRegistrationTitle: 'Getting started',
      landingRegistrationSubtitle: 'A simple registration flow gets your church online in minutes.',
      landingRegStep1: 'Enter your details',
      landingRegStep2: 'Set up your church',
      landingRegStep3: 'Create your account',
      landingRegStep4: 'Share the church code',
      landingRegStep5: 'Accept join requests',
      landingRegStep6: 'Team members join',
      landingRegStep7: 'Start using My Church',
      landingRegChurchPathTitle: 'Registering a new church',
      landingRegChurchPathBody: "If your church isn't set up yet, create it during registration — add its name, location, and structure, and you'll be assigned as its administrator.",
      landingRegMeetingPathTitle: 'Joining an existing church',
      landingRegMeetingPathBody: 'Already have a church using My Church? Search for it during registration and request to join, and an administrator will confirm your access.',

      landingHowTitle: 'How it works',
      landingHowSubtitle: "From setup to your first service, here's what to expect.",
      landingHowStep1Title: 'Create your account',
      landingHowStep1Body: 'Register with your email and set up your login in under a minute.',
      landingHowStep2Title: 'Set up your church',
      landingHowStep2Body: "Add your church's details and ministries.",
      landingHowStep3Title: 'Invite your team',
      landingHowStep3Body: 'Add servants, and assign them the right roles.',
      landingHowStep4Title: 'Add your people',
      landingHowStep4Body: "Bring in your congregation's records, or add them as they join.",
      landingHowStep5Title: 'Start your service',
      landingHowStep5Body: 'Record attendance, organize classes, and send your first notification.',

      landingPlatformsTitle: 'Your church, wherever you are.',
      landingPlatformsSubtitle: 'Use My Church from a browser or install it as a mobile app — your data stays in sync across both.',
      landingPlatformWeb: 'Web',
      landingPlatformMobile: 'Mobile',
      landingPlatformsNote: 'No installation required to get started — sign in from any device with a browser, or install the mobile app for on-the-go access.',

      landingContactTitle: 'Contact us',
      landingContactSubtitle: "Have a question before you sign up? We're happy to help.",
      landingContactPhone: 'Phone',
      landingContactPhonenumber: '(+20)1273036464',
      landingContactEmail: 'Email',
      landingContactHint: 'We typically respond within one business day.',

      landingCtaTitle: 'Ready to bring your church online?',
      landingCtaSubtitle: 'Join the churches already using My Church to manage their people, attendance, and ministries.',

      landingFooterTagline: 'Church management software built for congregations of every size.',
      landingPrivacyPolicy: 'Privacy policy',
      landingAccountDeletion: 'Delete my account'
    },

    ar: {
      appTitle: 'كنيستي',
      landingBrandSubtitle: 'مُكْثِرِينَ فِي عَمَلِ الرَّبِّ كُلَّ حِينٍ',
      landingBrandSubtitle2: '(١ كو ٥٨:١٥)',

      login: 'تسجيل الدخول',
      register: 'التسجيل',
      english: 'English',
      arabic: 'العربية',
      lightMode: 'الوضع الفاتح',
      darkMode: 'الوضع الداكن',

      landingHeroHeadline: 'منصة واحدة لإدارة كنيستك',
      landingHeroSubtitle: 'مكان واحد لتخزين البيانات و متابعة الحضور وتننظّيم الخدمات و المجموعات.',

      landingFeaturesTitle: 'كل ما تحتاجه كنيستك في مكان واحد',
      landingFeaturesSubtitle: 'مصممة خصيصًا لطريقة عمل الكنائس، من قداسات الأحد إلى خدمات أيام الأسبوع.',
      landingFeatureChurchTitle: 'ملف الكنيسة',
      landingFeatureChurchBody: 'أنشئ بيانات كنيستك وفروعها وخدماتها مرة واحدة، ليعمل الجميع من مصدر بيانات موحّد.',
      landingFeaturePeopleTitle: 'الأفراد',
      landingFeaturePeopleBody: 'تخزين كل بيانات الخدمه والأعضاء في مكان واحد ',
      landingFeatureAttendanceTitle: 'الحضور',
      landingFeatureAttendanceBody: 'أمكانية تسجيل حضور الخدام والمخدومين بسهوله والرجوع اليه في اي وقت',
      landingFeatureClassroomsTitle: 'المجموعات ',
      landingFeatureClassroomsBody: 'نظّم مدارس الأحد ومجموعات الدراسة والمجموعات  بجداول وقوائم ومعلمين في مكان واحد.',
      landingFeatureCustomFieldsTitle: 'المعلومات الجديده',
      landingFeatureCustomFieldsBody: 'سجّل بالضبط المعلومات التي تهم كنيستك .',
      landingFeatureRolesTitle: 'الأدوار والصلاحيات',
      landingFeatureRolesBody: 'امنح الموظفين والمتطوعين صلاحية الوصول لما يحتاجونه فقط، بأدوار واضحة لكل مسؤولية.',
      landingFeatureTenantTitle: 'كنائس متعددة',
      landingFeatureTenantBody: 'أدر أكثر من كنيسة أو فرع من حساب واحد، ولكل منها بياناتها وإعداداتها الخاصة.',
      landingFeatureNotificationsTitle: 'الإشعارات',
      landingFeatureNotificationsBody: 'أرسل الإعلانات والتذكيرات للأعضاء والموظفين، ولا تفوّت أي تحديث.',

      landingRegistrationTitle: 'ابدأ الآن',
      landingRegistrationSubtitle: 'خطوات تسجيل بسيطة تُظهر كنيستك على المنصة خلال دقائق.',
      landingRegStep1: 'أدخل بياناتك',
      landingRegStep2: 'أعدّ بيانات كنيستك',
      landingRegStep3: 'أنشئ حسابك',
      landingRegStep4: 'شارك كود الكنيسة',
      landingRegStep5: 'اقبل طلبات الانضمام',
      landingRegStep6: 'أبدأ ستدخدم كنيستي',
      landingRegChurchPathTitle: 'تسجيل كنيسة جديدة',
      landingRegChurchPathBody: 'إذا لم تكن كنيستك مُضافة بعد، أنشئها أثناء التسجيل — أضف اسمها وموقعها وهيكلها، وستُعيَّن كمسؤول عنها.',
      landingRegMeetingPathTitle: 'الانضمام إلى كنيسة قائمة',
      landingRegMeetingPathBody: 'هل تستخدم كنيستك My Church بالفعل؟ ابحث عنها أثناء التسجيل واطلب الانضمام، وسيقوم أحد المسؤولين بتأكيد صلاحيتك.',

      landingHowTitle: 'كيف تعمل المنصة',
      landingHowSubtitle: 'من الإعداد إلى أول خدمة لك، إليك ما يمكن توقعه.',
      landingHowStep1Title: 'أنشئ حسابك',
      landingHowStep1Body: 'سجّل ببريدك الإلكتروني وجهّز حساب الدخول في أقل من دقيقة.',
      landingHowStep2Title: 'أعدّ بيانات كنيستك',
      landingHowStep2Body: 'أضف بيانات كنيستك وفروعها وخدماتها.',
      landingHowStep3Title: 'ادعُ فريقك',
      landingHowStep3Body: 'أضف الموظفين والمتطوعين وحدد لهم الأدوار المناسبة.',
      landingHowStep4Title: 'أضف أفراد مجموعاتك',
      landingHowStep4Body: 'استورد سجلات مجموعاتك، أو أضفهم تباعًا عند انضمامهم.',
      landingHowStep5Title: 'ابدأ المتابعة',
      landingHowStep5Body: 'سجّل الحضور، ونظّم المجموعات ، وأرسل أول إشعار لك.',

landingRegNumber1: '١',
landingRegNumber2: '٢',
landingRegNumber3: '٣',
landingRegNumber4: '٤',
landingRegNumber5: '٥',
landingRegNumber6: '٦',
landingRegNumber7: '٧',

landingHowNumber1: '٠١',
landingHowNumber2: '٠٢',
landingHowNumber3: '٠٣',
landingHowNumber4: '٠٤',
landingHowNumber5: '٠٥',

      landingPlatformsTitle: 'متاحة أينما كان فريقك',
      landingPlatformsSubtitle: 'استخدم كنيستي من المتصفح أو ثبّته كتطبيق موبايل — تبقى بياناتك متزامنة بينهما.',
      landingPlatformWeb: 'الويب',
      landingPlatformMobile: 'الجوال',
      landingContactPhonenumber: '٠١٢٧٣٠٣٦٤٦٤',
      landingPlatformsNote: 'لا حاجة لأي تثبيت للبدء — سجّل الدخول من أي جهاز عبر المتصفح، أو ثبّت تطبيق الجوال للوصول أثناء التنقل.',

      landingContactTitle: 'تواصل معنا',
      landingContactSubtitle: 'لديك سؤال قبل التسجيل؟ يسعدنا مساعدتك.',
      landingContactPhone: 'الهاتف',
      landingContactEmail: 'البريد الإلكتروني',
      landingContactHint: 'نرد عادة خلال يوم عمل واحد.',

      landingCtaTitle: 'هل أنت مستعد لنقل كنيستك إلى الإنترنت؟',
      landingCtaSubtitle: 'انضم إلى الكنائس التي تستخدم My Church بالفعل لإدارة أفرادها وحضورها وخدماتها.',

      landingFooterTagline: 'برنامج لإدارة الكنائس مصمم لجماعات بجميع أحجامها.',
      landingPrivacyPolicy: 'سياسة الخصوصية',
      landingAccountDeletion: 'حذف حسابي'
    }
  };

  /* ---- State: Arabic default; persist lang/theme in localStorage ---- */
  var state = {
    lang: (function () {
      try {
        var saved = localStorage.getItem('landing_lang');
        if (saved === 'en' || saved === 'ar') return saved;
      } catch (e) { /* ignore */ }
      return 'ar';
    })(),
    theme: (function () {
      try {
        var saved = localStorage.getItem('landing_theme');
        if (saved === 'light' || saved === 'dark') return saved;
      } catch (e) { /* ignore */ }
      return 'light';
    })()
  };

  var root = document.documentElement;
  var langFlag = document.getElementById('langFlag');
  var themeIconMoon = document.getElementById('themeIconMoon');
  var themeIconSun = document.getElementById('themeIconSun');
  var footerCopyright = document.getElementById('footerCopyright');

  function t(key) {
    var dict = STRINGS[state.lang] || STRINGS.en;
    return dict[key] || STRINGS.en[key] || key;
  }

  function persistState() {
    try {
      localStorage.setItem('landing_lang', state.lang);
      localStorage.setItem('landing_theme', state.theme);
    } catch (e) { /* ignore */ }
  }

  function applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      el.textContent = t(el.getAttribute('data-i18n'));
    });

    root.lang = state.lang;
    root.dir = state.lang === 'ar' ? 'rtl' : 'ltr';
    document.title = state.lang === 'ar'
      ? 'كنيستي — My Church'
      : 'My Church — كنيستي';

    if (langFlag) {
      langFlag.src = state.lang === 'ar'
        ? 'assets/icons/flag-uk.svg'
        : 'assets/icons/flag-eg.svg';
      langFlag.alt = state.lang === 'ar' ? t('english') : t('arabic');
    }

    var langToggleEl = document.getElementById('langToggle');
    if (langToggleEl) {
      langToggleEl.setAttribute(
        'aria-label',
        state.lang === 'ar' ? t('english') : t('arabic')
      );
    }

    var currentYear = new Date().getFullYear();
    var displayYear = state.lang === 'ar'
      ? String(currentYear).replace(/\d/g, function (digit) {
          return '٠١٢٣٤٥٦٧٨٩'[digit];
        })
      : String(currentYear);

    var yearText = state.lang === 'ar'
      ? '\u00A9 ' + displayYear + ' كنيستي جميع الحقوق محفوظة.'
      : '\u00A9 ' + displayYear + ' My Church. All rights reserved.';

    if (footerCopyright) {
      footerCopyright.textContent = yearText;
    }

    updateNavCompact();
  }

  function applyTheme() {
    root.setAttribute('data-theme', state.theme);
    var isDark = state.theme === 'dark';
    if (themeIconMoon) themeIconMoon.hidden = isDark;
    if (themeIconSun) themeIconSun.hidden = !isDark;
    var themeToggleEl = document.getElementById('themeToggle');
    if (themeToggleEl) {
      themeToggleEl.setAttribute(
        'aria-label',
        isDark ? t('lightMode') : t('darkMode')
      );
    }
  }

  function updateNavCompact() {
    var threshold = state.lang === 'ar' ? 920 : 720;
    var isCompact = window.innerWidth < threshold;
    document.body.classList.toggle('nav-compact', isCompact);
  }

  function goToRoute(routeName) {
    switch (routeName) {
      case 'login':
        window.location.assign(CONFIG.routes.login);
        break;
      case 'register':
        window.location.assign(CONFIG.routes.register);
        break;
      case 'privacy':
        window.location.assign(CONFIG.baseUrl + '/privacy-policy');
        break;
      case 'deletion':
        window.location.assign(CONFIG.baseUrl + '/account-deletion');
        break;
      default:
        break;
    }
  }

  function init() {
    applyTranslations();
    applyTheme();
    persistState();

    var langToggleEl = document.getElementById('langToggle');
    if (langToggleEl) {
      langToggleEl.addEventListener('click', function () {
        state.lang = state.lang === 'ar' ? 'en' : 'ar';
        persistState();
        applyTranslations();
        applyTheme();
      });
    }

    var themeToggleEl = document.getElementById('themeToggle');
    if (themeToggleEl) {
      themeToggleEl.addEventListener('click', function () {
        state.theme = state.theme === 'dark' ? 'light' : 'dark';
        persistState();
        applyTheme();
      });
    }

    document.querySelectorAll('[data-route]').forEach(function (el) {
      el.addEventListener('click', function () {
        goToRoute(el.getAttribute('data-route'));
      });
    });

    window.addEventListener('resize', updateNavCompact);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
