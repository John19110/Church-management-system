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
  String get classrooms => _t('classrooms');
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
  String get spiritualDateOfBirth => _t('spiritualDateOfBirth');
  String get haveBrothersInProgram => _t('haveBrothersInProgram');
  String get brothersNamesSection => _t('brothersNamesSection');
  String get brotherName => _t('brotherName');
  String get addBrotherName => _t('addBrotherName');
  String get memberNotesSection => _t('memberNotesSection');
  String get addNoteLine => _t('addNoteLine');
  String get noteLine => _t('noteLine');
  String get lastAttendanceDate => _t('lastAttendanceDate');
  String get totalDaysAttended => _t('totalDaysAttended');
  String get discipline => _t('discipline');
  String get classroomIdsOptional => _t('classroomIdsOptional');
  String get weeklyAppointmentHint => _t('weeklyAppointmentHint');
  String get invalidWeeklyAppointment => _t('invalidWeeklyAppointment');
  String get meetingDayOfWeek => _t('meetingDayOfWeek');
  String get weekdaySaturday => _t('weekdaySaturday');
  String get weekdaySunday => _t('weekdaySunday');
  String get weekdayMonday => _t('weekdayMonday');
  String get weekdayTuesday => _t('weekdayTuesday');
  String get weekdayWednesday => _t('weekdayWednesday');
  String get weekdayThursday => _t('weekdayThursday');
  String get weekdayFriday => _t('weekdayFriday');

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
  String get language => _t('language');
  String get english => _t('english');
  String get arabic => _t('arabic');

  // ── Roles / Admin ─────────────────────────────────────────────────────────
  String get admin => _t('admin');
  String get superAdmin => _t('superAdmin');
  String get pendingServants => _t('pendingServants');
  String get pendingAdmins => _t('pendingAdmins');
  String get openPendingServants => _t('openPendingServants');
  String get approve => _t('approve');
  String get reject => _t('reject');
  String get assign => _t('assign');
  String get assignClass => _t('assignClass');
  String get assignClassroom => _t('assignClassroom');
  String get classroom => _t('classroom');
  String get selectClassroom => _t('selectClassroom');
  String get pleaseSelectClassroom => _t('pleaseSelectClassroom');
  String get classAssigned => _t('classAssigned');
  String get noPendingServants => _t('noPendingServants');
  String get noPendingAdmins => _t('noPendingAdmins');
  String get noName => _t('noName');
  String get noPhone => _t('noPhone');
  String get rejectServantTitle => _t('rejectServantTitle');
  String get rejectAdminTitle => _t('rejectAdminTitle');
  String get rejectThisUser => _t('rejectThisUser');
  String get approvedUser => _t('approvedUser');
  String get rejectedUser => _t('rejectedUser');
  String get assignClassTooltip => _t('assignClassTooltip');
  String get couldNotVerifyRole => _t('couldNotVerifyRole');
  String get adminOnlyScreen => _t('adminOnlyScreen');
  String get noRoleFoundPleaseRelogin => _t('noRoleFoundPleaseRelogin');

  // ── Meetings (Super Admin dialogs) ────────────────────────────────────────
  String get addMeeting => _t('addMeeting');
  String get add => _t('add');
  String get meetingAddedSuccessfully => _t('meetingAddedSuccessfully');
  String get meetingNameLabel => _t('meetingNameLabel');
  String get enterMeetingNameHint => _t('enterMeetingNameHint');
  String get meetingNameRequiredGeneric => _t('meetingNameRequiredGeneric');
  String get dayOfWeekRequired => _t('dayOfWeekRequired');
  String get weeklyAppointmentTime => _t('weeklyAppointmentTime');
  String get weeklyAppointmentTimeRequired => _t('weeklyAppointmentTimeRequired');

  // ── Servant ───────────────────────────────────────────────────────────────
  String get servant => _t('servant');
  String get servantOnlyScreen => _t('servantOnlyScreen');

  // ── Notifications ─────────────────────────────────────────────────────────
  String get notifications => _t('notifications');
  String get noNotificationsYet => _t('noNotificationsYet');

  // ── Classrooms ────────────────────────────────────────────────────────────
  String get classroomsHome => _t('classroomsHome');
  String get classroomsTitleWithMeeting => _t('classroomsTitleWithMeeting');
  String get addClassroom => _t('addClassroom');
  String get classroomNameLabel => _t('classroomNameLabel');
  String get enterClassroomNameHint => _t('enterClassroomNameHint');
  String get classroomNameRequiredGeneric => _t('classroomNameRequiredGeneric');
  String get ageOfMembersLabel => _t('ageOfMembersLabel');
  String get enterAgeRangeHint => _t('enterAgeRangeHint');
  String get ageOfMembersRequiredGeneric => _t('ageOfMembersRequiredGeneric');
  String get classroomAddedSuccessfully => _t('classroomAddedSuccessfully');
  String get visibleClassrooms => _t('visibleClassrooms');
  String get noVisibleClassroomsFound => _t('noVisibleClassroomsFound');
  String get attendanceHistory => _t('attendanceHistory');

  // ── Members / Common actions ──────────────────────────────────────────────
  String get retry => _t('retry');
  String get couldNotLoadMembers => _t('couldNotLoadMembers');
  String get noMembersInClassroomYet => _t('noMembersInClassroomYet');
  String get memberNumber => _t('memberNumber');
  String get classroomInvalidMissingId => _t('classroomInvalidMissingId');
  String get membersHeading => _t('membersHeading');
  String get ageGroupLabel => _t('ageGroupLabel');
  String get pastAttendanceSessions => _t('pastAttendanceSessions');
  String get servantsLabel => _t('servantsLabel');

  // ── Meetings detail ───────────────────────────────────────────────────────
  String get meetingDetails => _t('meetingDetails');
  String get nameLabel => _t('nameLabel');
  String get dayOfWeekLabel => _t('dayOfWeekLabel');
  String get weeklyAppointmentLabel => _t('weeklyAppointmentLabel');
  String get servantsCountLabel => _t('servantsCountLabel');
  String get membersCountLabel => _t('membersCountLabel');
  String get addUpdateRemoveMembers => _t('addUpdateRemoveMembers');
  String get manageServants => _t('manageServants');
  String get home => _t('home');

  // ── Profile / Forms ───────────────────────────────────────────────────────
  String get profile => _t('profile');
  String get editProfile => _t('editProfile');
  String get saveLabel => _t('saveLabel');
  String get done => _t('done');
  String get select => _t('select');
  String get failedToLoadOptions => _t('failedToLoadOptions');
  String get failedToLoadProfile => _t('failedToLoadProfile');
  String get profileUpdated => _t('profileUpdated');
  String get churchIdLabel => _t('churchIdLabel');
  String get meetingLabel => _t('meetingLabel');
  String get selectMeeting => _t('selectMeeting');
  String get classroomsLabel => _t('classroomsLabel');
  String get selectClassrooms => _t('selectClassrooms');
  String get superAdminHome => _t('superAdminHome');
  String get loadingLabel => _t('loadingLabel');
  String get errorLabel => _t('errorLabel');
  String get pendingCount => _t('pendingCount');
  String get noVisibleMeetingsFound => _t('noVisibleMeetingsFound');
  String get failedToLoadVisibleMeetings => _t('failedToLoadVisibleMeetings');
  String get failedToLoadVisibleClassrooms => _t('failedToLoadVisibleClassrooms');
  String get failedToLoadClassrooms => _t('failedToLoadClassrooms');
  String get editMeetingTitle => _t('editMeetingTitle');
  String get pageNotFound => _t('pageNotFound');
  String get missingRequiredData => _t('missingRequiredData');
  String get optional => _t('optional');
  String get visibleMeetings => _t('visibleMeetings');
  String get leaderServantOptional => _t('leaderServantOptional');
  String get selectServant => _t('selectServant');
  String get meetingUpdated => _t('meetingUpdated');
  String get attendanceSessionsCount => _t('attendanceSessionsCount');
  String get ageLabel => _t('ageLabel');

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
      'classrooms': 'Classrooms',
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
      'spiritualDateOfBirth': 'Spiritual date of birth (optional)',
      'haveBrothersInProgram': 'Has brothers in the program',
      'brothersNamesSection': 'Brothers\' names',
      'brotherName': 'Brother name',
      'addBrotherName': 'Add brother',
      'memberNotesSection': 'Notes',
      'addNoteLine': 'Add note',
      'noteLine': 'Note',
      'lastAttendanceDate': 'Last attendance date',
      'totalDaysAttended': 'Total days attended',
      'discipline': 'Discipline flag',
      'classroomIdsOptional':
          'Classroom IDs (comma-separated, optional)',
      'weeklyAppointmentHint':
          'Time only, e.g. 09:00',
      'invalidWeeklyAppointment': 'Enter a valid time',
      'meetingDayOfWeek': 'Day of week',
      'weekdaySaturday': 'Saturday',
      'weekdaySunday': 'Sunday',
      'weekdayMonday': 'Monday',
      'weekdayTuesday': 'Tuesday',
      'weekdayWednesday': 'Wednesday',
      'weekdayThursday': 'Thursday',
      'weekdayFriday': 'Friday',
      // Servants
      'noServants': 'No servants found.',
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
      'language': 'Language',
      'english': 'English',
      'arabic': 'Arabic',

      // Roles / Admin
      'admin': 'Admin',
      'superAdmin': 'Super Admin',
      'pendingServants': 'Pending Servants',
      'pendingAdmins': 'Pending Admins',
      'openPendingServants': 'Open Pending Servants',
      'approve': 'Approve',
      'reject': 'Reject',
      'assign': 'Assign',
      'assignClass': 'Assign class',
      'assignClassroom': 'Assign classroom',
      'classroom': 'Classroom',
      'selectClassroom': 'Select classroom',
      'pleaseSelectClassroom': 'Please select a classroom.',
      'classAssigned': 'Class assigned.',
      'noPendingServants': 'No pending servants.',
      'noPendingAdmins': 'No pending admins.',
      'noName': '(no name)',
      'noPhone': '(no phone)',
      'rejectServantTitle': 'Reject servant?',
      'rejectAdminTitle': 'Reject admin?',
      'rejectThisUser': 'this user',
      'approvedUser': 'Approved',
      'rejectedUser': 'Rejected',
      'assignClassTooltip': 'Assign class',
      'couldNotVerifyRole': 'Could not verify your role:',
      'adminOnlyScreen': 'This screen is for Admin users only.',
      'noRoleFoundPleaseRelogin':
          'No role found in your session. Please log out and sign in again.',

      // Meetings (Super Admin dialogs)
      'addMeeting': 'Add Meeting',
      'add': 'Add',
      'meetingAddedSuccessfully': 'Meeting added successfully.',
      'meetingNameLabel': 'Meeting Name',
      'enterMeetingNameHint': 'Enter meeting name',
      'meetingNameRequiredGeneric': 'Meeting name is required',
      'dayOfWeekRequired': 'Day of week is required',
      'weeklyAppointmentTime': 'Weekly appointment time',
      'weeklyAppointmentTimeRequired': 'Weekly appointment time is required',

      // Servant
      'servant': 'Servant',
      'servantOnlyScreen': 'This screen is for Servant users only.',

      // Notifications
      'notifications': 'Notifications',
      'noNotificationsYet': 'No notifications yet.',

      // Classrooms
      'classroomsHome': 'Classrooms Home',
      'classroomsTitleWithMeeting': 'Classrooms — {meetingName}',
      'addClassroom': 'Add Classroom',
      'classroomNameLabel': 'Classroom Name',
      'enterClassroomNameHint': 'Enter classroom name',
      'classroomNameRequiredGeneric': 'Classroom name is required',
      'ageOfMembersLabel': 'Age of Members',
      'enterAgeRangeHint': 'Enter age range',
      'ageOfMembersRequiredGeneric': 'Age of members is required',
      'classroomAddedSuccessfully': 'Classroom added successfully.',
      'visibleClassrooms': 'Visible Classrooms',
      'noVisibleClassroomsFound': 'No visible classrooms found.',
      'attendanceHistory': 'Attendance history',

      // Members / Common actions
      'retry': 'Retry',
      'couldNotLoadMembers': 'Could not load members:',
      'noMembersInClassroomYet': 'No members in this classroom yet.',
      'memberNumber': 'Member #{id}',
      'classroomInvalidMissingId': 'Invalid classroom: missing id.',
      'membersHeading': 'Members',
      'ageGroupLabel': 'Age group: {age}',
      'pastAttendanceSessions': '{count} past attendance sessions',
      'servantsLabel': 'Servants: {names}',

      // Meetings detail
      'meetingDetails': 'Meeting Details',
      'nameLabel': 'Name',
      'dayOfWeekLabel': 'Day of week',
      'weeklyAppointmentLabel': 'Weekly appointment',
      'servantsCountLabel': 'Servants count',
      'membersCountLabel': 'Members count',
      'addUpdateRemoveMembers': 'Add/Update/Remove Members',
      'manageServants': 'Manage Servants',
      'home': 'Home',

      // Profile / Forms
      'profile': 'Profile',
      'editProfile': 'Edit profile',
      'saveLabel': 'Save',
      'done': 'Done',
      'select': 'Select',
      'failedToLoadOptions': 'Failed to load options:',
      'failedToLoadProfile': 'Failed to load profile:',
      'profileUpdated': 'Profile updated.',
      'churchIdLabel': 'Church id',
      'meetingLabel': 'Meeting',
      'selectMeeting': 'Select meeting',
      'classroomsLabel': 'Classrooms',
      'selectClassrooms': 'Select classrooms',
      'superAdminHome': 'Super Admin Home',
      'loadingLabel': 'Loading...',
      'errorLabel': 'Error:',
      'pendingCount': '{count} pending',
      'noVisibleMeetingsFound': 'No visible meetings found.',
      'failedToLoadVisibleMeetings': 'Failed to load visible meetings:',
      'failedToLoadVisibleClassrooms': 'Failed to load visible classrooms:',
      'failedToLoadClassrooms': 'Failed to load classrooms:',
      'editMeetingTitle': 'Edit Meeting: {meeting}',
      'pageNotFound': 'Page not found:',
      'missingRequiredData': 'Missing required data for this screen.',
      'optional': 'optional',
      'visibleMeetings': 'Visible Meetings',
      'leaderServantOptional': 'Leader Servant (optional)',
      'selectServant': 'Select servant',
      'meetingUpdated': 'Meeting updated.',
      'attendanceSessionsCount': '{count} attendance sessions',
      'ageLabel': 'Age: {age}',
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
      'classrooms': 'الفصول',
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
      'spiritualDateOfBirth': 'تاريخ الميلاد الروحي (اختياري)',
      'haveBrothersInProgram': 'لديه إخوة في البرنامج',
      'brothersNamesSection': 'أسماء الإخوة',
      'brotherName': 'اسم الأخ',
      'addBrotherName': 'إضافة أخ',
      'memberNotesSection': 'ملاحظات',
      'addNoteLine': 'إضافة ملاحظة',
      'noteLine': 'ملاحظة',
      'lastAttendanceDate': 'تاريخ آخر حضور',
      'totalDaysAttended': 'إجمالي أيام الحضور',
      'discipline': 'علم انضباط',
      'classroomIdsOptional': ' الفصول (مفصولة بفاصلة، اختياري)',
      'weeklyAppointmentHint': 'وقت فقط، مثال 09:00',
      'invalidWeeklyAppointment': 'أدخل وقتاً صحيحاً',
      'meetingDayOfWeek': 'يوم الأسبوع',
      'weekdaySaturday': 'السبت',
      'weekdaySunday': 'الأحد',
      'weekdayMonday': 'الإثنين',
      'weekdayTuesday': 'الثلاثاء',
      'weekdayWednesday': 'الأربعاء',
      'weekdayThursday': 'الخميس',
      'weekdayFriday': 'الجمعة',
      // Servants
      'noServants': 'لا يوجد خدام.',
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
      'churchId': 'كود الكنيسه (اطلبه من الراعي)',
      'enterChurchId': 'أدخل كود كنيستك',
      'churchIdRequired': 'كود الكنيسة مطلوب',
      'meetingId': 'كود الاجتماع',
      'enterMeetingId': 'أدخل كود الاجتماع',
      'meetingIdRequired': 'كود الاجتماع مطلوب',
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
      'enterClassroomAndLoad': 'أدخل  الفصل واضغط تحميل\nلعرض الأعضاء.',
      'attendanceSaved': 'تم حفظ الحضور!',
      'loadMembersFirst': 'قم بتحميل الأعضاء أولاً',
      'enterClassroomId': 'أدخل  الفصل',
      'sessionInfo': 'معلومات الجلسة',
      'date': 'التاريخ',
      'records': 'السجلات',
      'lightMode': 'الوضع الفاتح',
      'darkMode': 'الوضع الداكن',
      'language': 'اللغة',
      'english': 'الإنجليزية',
      'arabic': 'العربية',

      // Roles / Admin
      'admin': 'مسؤول',
      'superAdmin': 'مسؤول عام',
      'pendingServants': 'الخدام المعلّقون',
      'pendingAdmins': 'المسؤولون المعلّقون',
      'openPendingServants': 'فتح الخدام المعلّقين',
      'approve': 'قبول',
      'reject': 'رفض',
      'assign': 'تعيين',
      'assignClass': 'تعيين فصل',
      'assignClassroom': 'تعيين فصل',
      'classroom': 'الفصل',
      'selectClassroom': 'اختر الفصل',
      'pleaseSelectClassroom': 'يرجى اختيار فصل.',
      'classAssigned': 'تم تعيين الفصل.',
      'noPendingServants': 'لا يوجد خدام معلّقون.',
      'noPendingAdmins': 'لا يوجد مسؤولون معلّقون.',
      'noName': '(بدون اسم)',
      'noPhone': '(بدون رقم)',
      'rejectServantTitle': 'رفض الخادم؟',
      'rejectAdminTitle': 'رفض المسؤول؟',
      'rejectThisUser': 'هذا المستخدم',
      'approvedUser': 'تم القبول',
      'rejectedUser': 'تم الرفض',
      'assignClassTooltip': 'تعيين فصل',
      'couldNotVerifyRole': 'تعذر التحقق من الدور:',
      'adminOnlyScreen': 'هذه الصفحة خاصة بالمشرفين فقط.',
      'noRoleFoundPleaseRelogin':
          'لم يتم العثور على دور في جلستك. يرجى تسجيل الخروج ثم تسجيل الدخول مرة أخرى.',

      // Meetings (Super Admin dialogs)
      'addMeeting': 'إضافة اجتماع',
      'add': 'إضافة',
      'meetingAddedSuccessfully': 'تمت إضافة الاجتماع بنجاح.',
      'meetingNameLabel': 'اسم الاجتماع',
      'enterMeetingNameHint': 'أدخل اسم الاجتماع',
      'meetingNameRequiredGeneric': 'اسم الاجتماع مطلوب',
      'dayOfWeekRequired': 'يوم الأسبوع مطلوب',
      'weeklyAppointmentTime': 'وقت الموعد الأسبوعي',
      'weeklyAppointmentTimeRequired': 'وقت الموعد الأسبوعي مطلوب',

      // Servant
      'servant': 'خادم',
      'servantOnlyScreen': 'هذه الصفحة خاصة بالخدام فقط.',

      // Notifications
      'notifications': 'الإشعارات',
      'noNotificationsYet': 'لا توجد إشعارات بعد.',

      // Classrooms
      'classroomsHome': 'صفحة الفصول',
      'classroomsTitleWithMeeting': 'الفصول — {meetingName}',
      'addClassroom': 'إضافة فصل',
      'classroomNameLabel': 'اسم الفصل',
      'enterClassroomNameHint': 'أدخل اسم الفصل',
      'classroomNameRequiredGeneric': 'اسم الفصل مطلوب',
      'ageOfMembersLabel': 'أعمار الأعضاء',
      'enterAgeRangeHint': 'أدخل نطاق الأعمار',
      'ageOfMembersRequiredGeneric': 'أعمار الأعضاء مطلوبة',
      'classroomAddedSuccessfully': 'تمت إضافة الفصل بنجاح.',
      'visibleClassrooms': 'الفصول الظاهرة',
      'noVisibleClassroomsFound': 'لم يتم العثور على فصول ظاهرة.',
      'attendanceHistory': 'سجل الحضور',

      // Members / Common actions
      'retry': 'إعادة المحاولة',
      'couldNotLoadMembers': 'تعذر تحميل الأعضاء:',
      'noMembersInClassroomYet': 'لا يوجد أعضاء في هذا الفصل بعد.',
      'memberNumber': 'عضو رقم {id}',
      'classroomInvalidMissingId': 'فصل غير صالح: المعرف مفقود.',
      'membersHeading': 'الأعضاء',
      'ageGroupLabel': 'الفئة العمرية: {age}',
      'pastAttendanceSessions': '{count} سجلات حضور سابقة',
      'servantsLabel': 'الخدام: {names}',

      // Meetings detail
      'meetingDetails': 'تفاصيل الاجتماع',
      'nameLabel': 'الاسم',
      'dayOfWeekLabel': 'يوم الأسبوع',
      'weeklyAppointmentLabel': 'الموعد الأسبوعي',
      'servantsCountLabel': 'عدد الخدام',
      'membersCountLabel': 'عدد الأعضاء',
      'addUpdateRemoveMembers': 'إضافة/تعديل/حذف أعضاء',
      'manageServants': 'إدارة الخدام',
      'home': 'الرئيسية',

      // Profile / Forms
      'profile': 'الملف الشخصي',
      'editProfile': 'تعديل الملف الشخصي',
      'saveLabel': 'حفظ',
      'done': 'تم',
      'select': 'اختر',
      'failedToLoadOptions': 'تعذر تحميل الخيارات:',
      'failedToLoadProfile': 'تعذر تحميل الملف الشخصي:',
      'profileUpdated': 'تم تحديث الملف الشخصي.',
      'churchIdLabel': 'معرف الكنيسة',
      'meetingLabel': 'الاجتماع',
      'selectMeeting': 'اختر الاجتماع',
      'classroomsLabel': 'الفصول',
      'selectClassrooms': 'اختر الفصول',
      'superAdminHome': 'صفحة المسؤول العام',
      'loadingLabel': 'جار التحميل...',
      'errorLabel': 'خطأ:',
      'pendingCount': '{count} معلّق',
      'noVisibleMeetingsFound': 'لم يتم العثور على اجتماعات ظاهرة.',
      'failedToLoadVisibleMeetings': 'تعذر تحميل الاجتماعات الظاهرة:',
      'failedToLoadVisibleClassrooms': 'تعذر تحميل الفصول الظاهرة:',
      'failedToLoadClassrooms': 'تعذر تحميل الفصول:',
      'editMeetingTitle': 'تعديل الاجتماع: {meeting}',
      'pageNotFound': 'الصفحة غير موجودة:',
      'missingRequiredData': 'بيانات مطلوبة مفقودة لهذه الصفحة.',
      'optional': 'اختياري',
      'visibleMeetings': 'الاجتماعات الظاهرة',
      'leaderServantOptional': 'الخادم المسؤول (اختياري)',
      'selectServant': 'اختر خادماً',
      'meetingUpdated': 'تم تحديث الاجتماع.',
      'attendanceSessionsCount': '{count} جلسات حضور',
      'ageLabel': 'العمر: {age}',
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
