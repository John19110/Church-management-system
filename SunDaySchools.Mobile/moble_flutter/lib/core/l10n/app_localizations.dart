import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const localizationsDelegates = <LocalizationsDelegate>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  String _t(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['en']![key] ??
        key;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  String get login => _t('login');
  String get register => _t('register');
  String get name => _t('name');
  String get password => _t('password');
  String get enterName => _t('enterName');
  String get enterPassword => _t('enterPassword');
  String get nameRequired => _t('nameRequired');
  String get passwordRequired => _t('passwordRequired');
  String get dontHaveAccount => _t('dontHaveAccount');
  String get createAccount => _t('createAccount');
  String get confirmPassword => _t('confirmPassword');
  String get enterConfirmPassword => _t('enterConfirmPassword');
  String get pleaseConfirmPassword => _t('pleaseConfirmPassword');
  String get phoneNumber => _t('phoneNumber');
  String get enterPhoneNumber => _t('enterPhoneNumber');
  String get phoneRequired => _t('phoneRequired');
  String get passwordTooShort => _t('passwordTooShort');
  String get passwordsDoNotMatch => _t('passwordsDoNotMatch');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');

  // ── Dashboard ─────────────────────────────────────────────────────────────
  String get dashboard => _t('dashboard');
  String get welcome => _t('welcome');
  String get sundaySchoolManagement => _t('sundaySchoolManagement');
  String get quickAccess => _t('quickAccess');
  String get members => _t('members');
  String get attendance => _t('attendance');
  String get servants => _t('servants');
  String get logout => _t('logout');
  String get sundaySchool => _t('sundaySchool');
  String get managementSystem => _t('managementSystem');

  // ── Children ──────────────────────────────────────────────────────────────
  String get noMembers => _t('noMembers');
  String get addMember => _t('addMember');
  String get editMember => _t('editMember');
  String get memberDetails => _t('memberDetails');
  String get search => _t('search');
  String get firstName => _t('firstName');
  String get middleName => _t('middleName');
  String get lastName => _t('lastName');
  String get fullName => _t('fullName');
  String get gender => _t('gender');
  String get male => _t('male');
  String get female => _t('female');
  String get address => _t('address');
  String get dateOfBirth => _t('dateOfBirth');
  String get joiningDate => _t('joiningDate');
  String get spiritualDateOfBirth => _t('spiritualDateOfBirth');
  String get haveBrothers => _t('haveBrothers');
  String get brothersNames => _t('brothersNames');
  String get brother => _t('brother');
  String get classroomId => _t('classroomId');
  String get phoneNumbers => _t('phoneNumbers');
  String get relation => _t('relation');
  String get phone => _t('phone');
  String get save => _t('save');
  String get delete => _t('delete');
  String get cancel => _t('cancel');
  String get deleteMember => _t('deleteMember');
  String get confirmDeleteMember => _t('confirmDeleteMember');
  String get memberAddedSuccessfully => _t('memberAddedSuccessfully');
  String get memberUpdatedSuccessfully => _t('memberUpdatedSuccessfully');
  String get memberDeletedSuccessfully => _t('memberDeletedSuccessfully');
  String get firstNameRequired => _t('firstNameRequired');
  String get dobRequired => _t('dobRequired');
  String get joiningDateRequired => _t('joiningDateRequired');
  String get classroomIdRequired => _t('classroomIdRequired');

  // ── Servants ──────────────────────────────────────────────────────────────
  String get noServants => _t('noServants');
  String get addServant => _t('addServant');
  String get editServant => _t('editServant');
  String get servantDetails => _t('servantDetails');
  String get birthDate => _t('birthDate');
  String get deleteServant => _t('deleteServant');
  String get confirmDeleteServant => _t('confirmDeleteServant');
  String get servantAddedSuccessfully => _t('servantAddedSuccessfully');
  String get servantUpdatedSuccessfully => _t('servantUpdatedSuccessfully');
  String get servantDeletedSuccessfully => _t('servantDeletedSuccessfully');

  // ── Registration ──────────────────────────────────────────────────────────
  String get churchId => _t('churchId');
  String get enterChurchId => _t('enterChurchId');
  String get churchIdRequired => _t('churchIdRequired');
  String get meetingId => _t('meetingId');
  String get enterMeetingId => _t('enterMeetingId');
  String get meetingIdRequired => _t('meetingIdRequired');
  String get churchName => _t('churchName');
  String get enterChurchName => _t('enterChurchName');
  String get churchNameRequired => _t('churchNameRequired');
  String get meetingName => _t('meetingName');
  String get enterMeetingName => _t('enterMeetingName');
  String get meetingNameRequired => _t('meetingNameRequired');
  String get selectRegistrationType => _t('selectRegistrationType');
  String get registerTypeServant => _t('registerTypeServant');
  String get registerTypeChurchAdmin => _t('registerTypeChurchAdmin');
  String get registerTypeMeetingAdmin => _t('registerTypeMeetingAdmin');
  String get weeklyAppointment => _t('weeklyAppointment');
  String get weeklyAppointmentRequired => _t('weeklyAppointmentRequired');

  // ── Attendance ────────────────────────────────────────────────────────────
  String get takeAttendance => _t('takeAttendance');
  String get viewAttendance => _t('viewAttendance');
  String get notes => _t('notes');
  String get sessionNotes => _t('sessionNotes');
  String get present => _t('present');
  String get absent => _t('absent');
  String get late => _t('late');
  String get excused => _t('excused');
  String get homework => _t('homework');
  String get tools => _t('tools');
  String get status => _t('status');
  String get submit => _t('submit');
  String get sessionId => _t('sessionId');
  String get load => _t('load');
  String get markAllPresent => _t('markAllPresent');
  String get enterClassroomAndLoad => _t('enterClassroomAndLoad');
  String get attendanceSaved => _t('attendanceSaved');
  String get loadMembersFirst => _t('loadMembersFirst');
  String get enterClassroomId => _t('enterClassroomId');
  String get sessionInfo => _t('sessionInfo');
  String get date => _t('date');
  String get records => _t('records');
  String get lightMode => _t('lightMode');
  String get darkMode => _t('darkMode');

  // ── Common ────────────────────────────────────────────────────────────────
  String get loading => _t('loading');
  String get error => _t('error');
  String get success => _t('success');
  String get required => _t('required');
  String get tapToSelectImage => _t('tapToSelectImage');

  // ── Translation tables ────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Auth
      'login': 'Login',
      'register': 'Register',
      'name': 'Name',
      'password': 'Password',
      'enterName': 'Enter your name',
      'enterPassword': 'Enter your password',
      'nameRequired': 'Name is required',
      'passwordRequired': 'Password is required',
      'dontHaveAccount': "Don't have an account? Register",
      'createAccount': 'Create Account',
      'confirmPassword': 'Confirm Password',
      'enterConfirmPassword': 'Confirm your password',
      'pleaseConfirmPassword': 'Please confirm password',
      'phoneNumber': 'Phone Number',
      'enterPhoneNumber': 'Enter your phone number',
      'phoneRequired': 'Phone number is required',
      'passwordTooShort': 'Password must be at least 6 characters',
      'passwordsDoNotMatch': 'Passwords do not match',
      'alreadyHaveAccount': 'Already have an account? Login',
      // Dashboard
      'dashboard': 'Dashboard',
      'welcome': 'Welcome!',
      'sundaySchoolManagement': 'Sunday School Management',
      'quickAccess': 'Quick Access',
      'members': 'Members',
      'attendance': 'Attendance',
      'servants': 'Servants',
      'logout': 'Logout',
      'sundaySchool': 'Sunday School',
      'managementSystem': 'Management System',
      // Children
      'noMembers': 'No members yet. Tap + to add one.',
      'addMember': 'Add Member',
      'editMember': 'Edit Member',
      'memberDetails': 'Member Details',
      'search': 'Search',
      'firstName': 'First Name',
      'middleName': 'Middle Name',
      'lastName': 'Last Name',
      'fullName': 'Full Name',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'address': 'Address',
      'dateOfBirth': 'Date of Birth',
      'joiningDate': 'Joining Date',
      'spiritualDateOfBirth': 'Spiritual Date of Birth',
      'haveBrothers': 'Have Brothers',
      'brothersNames': 'Brothers Names',
      'brother': 'Brother',
      'classroomId': 'Classroom ID',
      'phoneNumbers': 'Phone Numbers',
      'relation': 'Relation',
      'phone': 'Phone',
      'save': 'Save Changes',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'deleteMember': 'Delete Member',
      'confirmDeleteMember': 'Are you sure you want to delete this member?',
      'memberAddedSuccessfully': 'Member added successfully',
      'memberUpdatedSuccessfully': 'Member updated successfully',
      'memberDeletedSuccessfully': 'Member deleted successfully',
      'firstNameRequired': 'First name is required',
      'dobRequired': 'Date of birth is required',
      'joiningDateRequired': 'Joining date is required',
      'classroomIdRequired': 'Classroom ID is required',
      // Servants
      'noServants': 'No servants yet. Tap + to add one.',
      'addServant': 'Add Servant',
      'editServant': 'Edit Servant',
      'servantDetails': 'Servant Details',
      'birthDate': 'Birth Date',
      'deleteServant': 'Delete Servant',
      'confirmDeleteServant': 'Are you sure you want to delete this servant?',
      'servantAddedSuccessfully': 'Servant added successfully',
      'servantUpdatedSuccessfully': 'Servant updated successfully',
      'servantDeletedSuccessfully': 'Servant deleted',
      // Registration
      'churchId': 'Church ID',
      'enterChurchId': 'Enter your church ID',
      'churchIdRequired': 'Church ID is required',
      'meetingId': 'Meeting ID',
      'enterMeetingId': 'Enter your meeting ID',
      'meetingIdRequired': 'Meeting ID is required',
      'churchName': 'Church Name',
      'enterChurchName': 'Enter church name',
      'churchNameRequired': 'Church name is required',
      'meetingName': 'Meeting Name',
      'enterMeetingName': 'Enter meeting name',
      'meetingNameRequired': 'Meeting name is required',
      'selectRegistrationType': 'Select Registration Type',
      'registerTypeServant': 'Servant',
      'registerTypeChurchAdmin': 'Church Admin',
      'registerTypeMeetingAdmin': 'Meeting Admin',
      'weeklyAppointment': 'Weekly Appointment',
      'weeklyAppointmentRequired': 'Weekly appointment is required',
      // Attendance
      'takeAttendance': 'Take Attendance',
      'viewAttendance': 'View Attendance',
      'notes': 'Notes',
      'sessionNotes': 'Session Notes (optional)',
      'present': 'Present',
      'absent': 'Absent',
      'late': 'Late',
      'excused': 'Excused',
      'homework': 'Homework',
      'tools': 'Tools',
      'status': 'Status',
      'submit': 'Save Attendance',
      'sessionId': 'Session',
      'load': 'Load',
      'markAllPresent': 'Mark All Present',
      'enterClassroomAndLoad':
          'Enter a classroom ID and tap Load\nto see children.',
      'attendanceSaved': 'Attendance saved!',
      'loadMembersFirst': 'Load members first',
      'enterClassroomId': 'Enter a classroom ID',
      'sessionInfo': 'Session Info',
      'date': 'Date',
      'records': 'Records',
      'lightMode': 'Light mode',
      'darkMode': 'Dark mode',
      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'required': 'This field is required',
      'tapToSelectImage': 'Tap to select image',
    },
    'ar': {
      // Auth
      'login': 'تسجيل الدخول',
      'register': 'تسجيل',
      'name': 'الاسم',
      'password': 'كلمة المرور',
      'enterName': 'أدخل اسمك',
      'enterPassword': 'أدخل كلمة المرور',
      'nameRequired': 'الاسم مطلوب',
      'passwordRequired': 'كلمة المرور مطلوبة',
      'dontHaveAccount': 'ليس لديك حساب؟ سجل الآن',
      'createAccount': 'إنشاء حساب',
      'confirmPassword': 'تأكيد كلمة المرور',
      'enterConfirmPassword': 'أدخل تأكيد كلمة المرور',
      'pleaseConfirmPassword': 'يرجى تأكيد كلمة المرور',
      'phoneNumber': 'رقم الهاتف',
      'enterPhoneNumber': 'أدخل رقم هاتفك',
      'phoneRequired': 'رقم الهاتف مطلوب',
      'passwordTooShort': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'passwordsDoNotMatch': 'كلمتا المرور غير متطابقتين',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟ سجل دخولك',
      // Dashboard
      'dashboard': 'لوحة التحكم',
      'welcome': 'مرحباً!',
      'sundaySchoolManagement': 'إدارة مدرسة الأحد',
      'quickAccess': 'الوصول السريع',
      'members': 'الأعضاء',
      'attendance': 'الحضور',
      'servants': 'الخدام',
      'logout': 'تسجيل الخروج',
      'sundaySchool': 'مدرسة الأحد',
      'managementSystem': 'نظام الإدارة',
      // Children
      'noMembers': 'لا يوجد أعضاء بعد. اضغط + للإضافة.',
      'addMember': 'إضافة عضو',
      'editMember': 'تعديل عضو',
      'memberDetails': 'تفاصيل العضو',
      'search': 'بحث',
      'firstName': 'الاسم الأول',
      'middleName': 'الاسم الأوسط',
      'lastName': 'الاسم الأخير',
      'fullName': 'الاسم الكامل',
      'gender': 'الجنس',
      'male': 'ذكر',
      'female': 'أنثى',
      'address': 'العنوان',
      'dateOfBirth': 'تاريخ الميلاد',
      'joiningDate': 'تاريخ الانضمام',
      'spiritualDateOfBirth': 'تاريخ الميلاد الروحي',
      'haveBrothers': 'لديه إخوة',
      'brothersNames': 'أسماء الإخوة',
      'brother': 'أخ',
      'classroomId': 'معرف الفصل',
      'phoneNumbers': 'أرقام الهاتف',
      'relation': 'صلة القرابة',
      'phone': 'الهاتف',
      'save': 'حفظ التغييرات',
      'delete': 'حذف',
      'cancel': 'إلغاء',
      'deleteMember': 'حذف عضو',
      'confirmDeleteMember': 'هل أنت متأكد من حذف هذا العضو؟',
      'memberAddedSuccessfully': 'تمت إضافة العضو بنجاح',
      'memberUpdatedSuccessfully': 'تم تحديث العضو بنجاح',
      'memberDeletedSuccessfully': 'تم حذف العضو بنجاح',
      'firstNameRequired': 'الاسم الأول مطلوب',
      'dobRequired': 'تاريخ الميلاد مطلوب',
      'joiningDateRequired': 'تاريخ الانضمام مطلوب',
      'classroomIdRequired': 'معرف الفصل مطلوب',
      // Servants
      'noServants': 'لا يوجد خدام بعد. اضغط + للإضافة.',
      'addServant': 'إضافة خادم',
      'editServant': 'تعديل خادم',
      'servantDetails': 'تفاصيل الخادم',
      'birthDate': 'تاريخ الميلاد',
      'deleteServant': 'حذف خادم',
      'confirmDeleteServant': 'هل أنت متأكد من حذف هذا الخادم؟',
      'servantAddedSuccessfully': 'تمت إضافة الخادم بنجاح',
      'servantUpdatedSuccessfully': 'تم تحديث الخادم بنجاح',
      'servantDeletedSuccessfully': 'تم حذف الخادم',
      // Registration
      'churchId': 'معرف الكنيسة',
      'enterChurchId': 'أدخل معرف كنيستك',
      'churchIdRequired': 'معرف الكنيسة مطلوب',
      'meetingId': 'معرف الاجتماع',
      'enterMeetingId': 'أدخل معرف الاجتماع',
      'meetingIdRequired': 'معرف الاجتماع مطلوب',
      'churchName': 'اسم الكنيسة',
      'enterChurchName': 'أدخل اسم الكنيسة',
      'churchNameRequired': 'اسم الكنيسة مطلوب',
      'meetingName': 'اسم الاجتماع',
      'enterMeetingName': 'أدخل اسم الاجتماع',
      'meetingNameRequired': 'اسم الاجتماع مطلوب',
      'selectRegistrationType': 'اختر نوع التسجيل',
      'registerTypeServant': 'خادم',
      'registerTypeChurchAdmin': 'مشرف كنيسة',
      'registerTypeMeetingAdmin': 'مشرف اجتماع',
      'weeklyAppointment': 'الموعد الأسبوعي',
      'weeklyAppointmentRequired': 'الموعد الأسبوعي مطلوب',
      // Attendance
      'takeAttendance': 'تسجيل الحضور',
      'viewAttendance': 'عرض الحضور',
      'notes': 'ملاحظات',
      'sessionNotes': 'ملاحظات الجلسة (اختياري)',
      'present': 'حاضر',
      'absent': 'غائب',
      'late': 'متأخر',
      'excused': 'معذور',
      'homework': 'الواجب',
      'tools': 'الأدوات',
      'status': 'الحالة',
      'submit': 'حفظ الحضور',
      'sessionId': 'الجلسة',
      'load': 'تحميل',
      'markAllPresent': 'تحديد الكل حاضر',
      'enterClassroomAndLoad': 'أدخل معرف الفصل واضغط تحميل\nلعرض الأعضاء.',
      'attendanceSaved': 'تم حفظ الحضور!',
      'loadMembersFirst': 'قم بتحميل الأعضاء أولاً',
      'enterClassroomId': 'أدخل معرف الفصل',
      'sessionInfo': 'معلومات الجلسة',
      'date': 'التاريخ',
      'records': 'السجلات',
      'lightMode': 'الوضع الفاتح',
      'darkMode': 'الوضع الداكن',
      // Common
      'loading': 'جار التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'required': 'هذا الحقل مطلوب',
      'tapToSelectImage': 'اضغط لاختيار صورة',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
