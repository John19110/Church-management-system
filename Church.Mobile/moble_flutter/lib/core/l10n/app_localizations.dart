import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'locale_format.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Use when [BuildContext] is unavailable (e.g. error mappers with [Locale]).
  static AppLocalizations forLocale(Locale locale) => AppLocalizations(locale);

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
  String get groups => _t('groups');
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
  String get searchMembers => _t('searchMembers');
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
  String get fatherName => _t('fatherName');
  String get familyName => _t('familyName');
  String get memberSectionPersonal => _t('memberSectionPersonal');
  String get memberSectionDates => _t('memberSectionDates');
  String get disciplineStatus => _t('disciplineStatus');
  String get disciplineStatusHint => _t('disciplineStatusHint');
  String get fullNameComputedHint => _t('fullNameComputedHint');
  String get optionalLabel => _t('optionalLabel');
  String get clearLabel => _t('clearLabel');
  String get haveBrothersQuestion => _t('haveBrothersQuestion');
  String get addPhoneNumber => _t('addPhoneNumber');
  String get removePhoneNumber => _t('removePhoneNumber');
  String get removeBrother => _t('removeBrother');
  String get removeNote => _t('removeNote');
  String get phoneRelationMember => _t('phoneRelationMember');
  String get phoneRelationFather => _t('phoneRelationFather');
  String get phoneRelationMother => _t('phoneRelationMother');
  String get phoneRelationBrother => _t('phoneRelationBrother');
  String get phoneRelationSister => _t('phoneRelationSister');
  String get phoneRelationGuardian => _t('phoneRelationGuardian');
  String get phoneRelationOther => _t('phoneRelationOther');
  String get invalidPhoneFormat => _t('invalidPhoneFormat');
  String get relationRequiredWhenPhone => _t('relationRequiredWhenPhone');
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
  String get deleteMeeting => _t('deleteMeeting');
  String get confirmDeleteMeeting => _t('confirmDeleteMeeting');
  String get meetingDeletedSuccessfully => _t('meetingDeletedSuccessfully');
  String get deleteClassroom => _t('deleteClassroom');
  String get confirmDeleteClassroom => _t('confirmDeleteClassroom');
  String get classroomDeletedSuccessfully => _t('classroomDeletedSuccessfully');
  String get leaderServantLabel => _t('leaderServantLabel');
  String get assignedServantsLabel => _t('assignedServantsLabel');
  String get noServantsAssigned => _t('noServantsAssigned');

  // ── Registration ──────────────────────────────────────────────────────────
  String get churchId => _t('churchId');
  String get enterChurchId => _t('enterChurchId');
  String get churchIdRequired => _t('churchIdRequired');
  String get churchOrMeetingIdLabel => _t('churchOrMeetingIdLabel');
  String get enterChurchOrMeetingId => _t('enterChurchOrMeetingId');
  String get churchOrMeetingIdRequired => _t('churchOrMeetingIdRequired');
  String get requestedMeetingNameChurchIdHint =>
      _t('requestedMeetingNameChurchIdHint');
  String get meetingAdminPhoneChurchIdHint =>
      _t('meetingAdminPhoneChurchIdHint');
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
  String get churchExistsQuestion => _t('churchExistsQuestion');
  String get churchExistsYes => _t('churchExistsYes');
  String get churchExistsNo => _t('churchExistsNo');
  String get joinExistingChurchTitle => _t('joinExistingChurchTitle');
  String get meetingAdminPhone => _t('meetingAdminPhone');
  String get enterMeetingAdminPhone => _t('enterMeetingAdminPhone');
  String get meetingAdminPhoneRequired => _t('meetingAdminPhoneRequired');
  String get noMeetingsToAssign => _t('noMeetingsToAssign');
  String get weeklyAppointment => _t('weeklyAppointment');
  String get weeklyAppointmentRequired => _t('weeklyAppointmentRequired');
  String get phoneAlreadyUsed => _t('phoneAlreadyUsed');
  String get phoneInvalid => _t('phoneInvalid');
  String get churchNameAlreadyExists => _t('churchNameAlreadyExists');
  String get churchOrMeetingNotFound => _t('churchOrMeetingNotFound');
  String get churchOrMeetingIdInvalid => _t('churchOrMeetingIdInvalid');
  String get meetingAdminPhoneRequiredForServants =>
      _t('meetingAdminPhoneRequiredForServants');
  String get registrationUsernameConflict => _t('registrationUsernameConflict');
  String get meetingNotInChurch => _t('meetingNotInChurch');
  String get validationFailed => _t('validationFailed');
  String get confirmPasswordRequired => _t('confirmPasswordRequired');
  String get passwordRequiresDigit => _t('passwordRequiresDigit');
  String get passwordRequiresLower => _t('passwordRequiresLower');
  String get passwordRequiresUpper => _t('passwordRequiresUpper');
  String get passwordRequiresNonAlphanumeric =>
      _t('passwordRequiresNonAlphanumeric');
  String get registrationDataInvalid => _t('registrationDataInvalid');
  String get churchAlreadyExists => _t('churchAlreadyExists');
  String get passwordMustContainAtLeast6 => _t('passwordMustContainAtLeast6');

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
  // Church user approval workflow
  String get pendingUsers => _t('pendingUsers');
  String get noPendingUsers => _t('noPendingUsers');
  String get requestedMeetingName => _t('requestedMeetingName');
  String get enterRequestedMeetingName => _t('enterRequestedMeetingName');
  String get requestedMeetingNameRequired => _t('requestedMeetingNameRequired');
  String get requestedMeetingLabel => _t('requestedMeetingLabel');
  String get requestedRoleLabel => _t('requestedRoleLabel');
  String get registrationDateLabel => _t('registrationDateLabel');
  String get publicChurchIdLabel => _t('publicChurchIdLabel');
  String get approveUserTitle => _t('approveUserTitle');
  String get meetingSelectionRequired => _t('meetingSelectionRequired');
  String get rejectReasonOptional => _t('rejectReasonOptional');
  String get accountPendingApproval => _t('accountPendingApproval');
  String get accountRejected => _t('accountRejected');
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

  // ── groups ────────────────────────────────────────────────────────────
  String get classroomsHome => _t('classroomsHome');
  String get classroomsTitleWithMeeting => _t('classroomsTitleWithMeeting');
  String get addClassroom => _t('addClassroom');
  String get classroomNameLabel => _t('classroomNameLabel');
  String get enterClassroomNameHint => _t('enterClassroomNameHint');
  String get classroomNameRequiredGeneric => _t('classroomNameRequiredGeneric');
  String get ageOfMembersLabel => _t('ageOfMembersLabel');
  String get numberOfDisciplineMembersLabel =>
      _t('numberOfDisciplineMembersLabel');
  String get totalMembersCountLabel => _t('totalMembersCountLabel');
  String get photoLabel => _t('photoLabel');
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
  String get profileInformation => _t('profileInformation');
  String get servantInformation => _t('servantInformation');
  String get appSettings => _t('appSettings');
  String get tapToChangePhoto => _t('tapToChangePhoto');
  String get saveLabel => _t('saveLabel');
  String get done => _t('done');
  String get select => _t('select');
  String get failedToLoadOptions => _t('failedToLoadOptions');
  String get failedToLoadProfile => _t('failedToLoadProfile');
  String get profileUpdated => _t('profileUpdated');
  String get churchIdLabel => _t('churchIdLabel');
  String get copyLabel => _t('copyLabel');
  String get churchIdCopied => _t('churchIdCopied');
  String get meetingIdLabel => _t('meetingIdLabel');
  String get meetingIdCopied => _t('meetingIdCopied');
  String get meetingMoreActions => _t('meetingMoreActions');
  String get churchMeetingsIdsTitle => _t('churchMeetingsIdsTitle');
  String get publicMeetingIdLabel => _t('publicMeetingIdLabel');
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
  String get classroomServantsOptional => _t('classroomServantsOptional');
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

  // ── Custom fields (admin) ─────────────────────────────────────────────────
  String get customFields => _t('customFields');
  String customFieldsForEntity(String entityName) =>
      _t('customFieldsForEntity').replaceAll('{entity}', entityDisplayName(entityName));
  String entityDisplayName(String entityName) {
    switch (entityName) {
      case 'Member':
        return _t('entityMember');
      case 'Classroom':
        return _t('entityClassroom');
      case 'Servant':
        return _t('entityServant');
      case 'Meeting':
        return _t('entityMeeting');
      case 'Church':
        return _t('entityChurch');
      default:
        return entityName;
    }
  }
  String get notAuthorized => _t('notAuthorized');
  String get noCustomFieldsYet => _t('noCustomFieldsYet');
  String get noFieldsConfigured => _t('noFieldsConfigured');
  String get systemFieldsSection => _t('systemFieldsSection');
  String get systemFieldsSectionHint => _t('systemFieldsSectionHint');
  String get customFieldsSection => _t('customFieldsSection');
  String get systemFieldBadge => _t('systemFieldBadge');
  String get fieldStatusRequired => _t('fieldStatusRequired');
  String get fieldStatusOptional => _t('fieldStatusOptional');
  String get fieldHiddenInForms => _t('fieldHiddenInForms');
  String get fieldHiddenLabel => _t('fieldHiddenLabel');
  String get fieldHiddenHint => _t('fieldHiddenHint');
  String get sortOrderLabel => _t('sortOrderLabel');
  String get fieldAppearancePositionLabel => _t('fieldAppearancePositionLabel');
  String fieldPositionOrdinal(int position) => fieldPositionName(position);
  String fieldPositionName(int position) {
    if (position <= 0) return '';
    switch (position) {
      case 1:
        return _t('fieldPos_1');
      case 2:
        return _t('fieldPos_2');
      case 3:
        return _t('fieldPos_3');
      case 4:
        return _t('fieldPos_4');
      case 5:
        return _t('fieldPos_5');
      case 6:
        return _t('fieldPos_6');
      case 7:
        return _t('fieldPos_7');
      case 8:
        return _t('fieldPos_8');
      case 9:
        return _t('fieldPos_9');
      case 10:
        return _t('fieldPos_10');
      default:
        return _t('fieldPositionNumber').replaceAll('{n}', '$position');
    }
  }
  String get fieldPositionLast => _t('fieldPositionLast');
  String get deleteFieldPermanently => _t('deleteFieldPermanently');
  String deleteFieldPermanentlyConfirm(String name) =>
      _t('deleteFieldPermanentlyConfirm').replaceAll('{name}', name);
  String get deletePermanently => _t('deletePermanently');
  String get fieldMoreOptions => _t('fieldMoreOptions');
  String get fieldDeletedPermanently => _t('fieldDeletedPermanently');
  String get systemFieldCannotDelete => _t('systemFieldCannotDelete');
  String get placeholderLabel => _t('placeholderLabel');
  String get validationRegexLabel => _t('validationRegexLabel');
  String get editSystemField => _t('editSystemField');
  String systemFieldNameLocked(String name) =>
      _t('systemFieldNameLocked').replaceAll('{name}', name);
  String systemFieldKeyLockedLabel(String label) =>
      _t('systemFieldKeyLockedLabel').replaceAll('{label}', label);
  String get systemFieldCannotDeactivate => _t('systemFieldCannotDeactivate');
  String get systemFieldNotProvisioned => _t('systemFieldNotProvisioned');
  String get editCustomField => _t('editCustomField');
  String get newCustomField => _t('newCustomField');
  String get displayNameLabel => _t('displayNameLabel');
  String get displayNameEnglishLabel => _t('displayNameEnglishLabel');
  String get displayNameArabicLabel => _t('displayNameArabicLabel');
  String get displayNameRequired => _t('displayNameRequired');
  String get fieldTypeLabel => _t('fieldTypeLabel');
  String get fieldRequiredLabel => _t('fieldRequiredLabel');
  String get fieldReadOnlyLabel => _t('fieldReadOnlyLabel');
  String get customFieldOptions => _t('customFieldOptions');
  String get addOption => _t('addOption');
  String get optionValueLabel => _t('optionValueLabel');
  String get optionLabelLabel => _t('optionLabelLabel');
  String get createField => _t('createField');
  String get deactivateField => _t('deactivateField');
  String deactivateFieldConfirm(String name) =>
      _t('deactivateFieldConfirm').replaceAll('{name}', name);
  String get deactivate => _t('deactivate');
  String get fieldDeactivated => _t('fieldDeactivated');
  String get reactivateField => _t('reactivateField');
  String reactivateFieldConfirm(String name) =>
      _t('reactivateFieldConfirm').replaceAll('{name}', name);
  String get reactivate => _t('reactivate');
  String get fieldActivated => _t('fieldActivated');
  String get fieldActive => _t('fieldActive');
  String get fieldInactive => _t('fieldInactive');
  String get selectOptionsRequired => _t('selectOptionsRequired');
  String customFieldDataTypeLabel(String typeKey) => _t('cfdt_$typeKey');
  String get manageCustomFields => _t('manageCustomFields');
  String get editEntityFields => _t('editEntityFields');
  String get changesSaved => _t('changesSaved');
  String get entityFieldsNotConfigured => _t('entityFieldsNotConfigured');
  String configureEntityAttributesTitle(String entityName) =>
      _t('configureEntityAttributesTitle')
          .replaceAll('{entity}', entityDisplayName(entityName));
  String get customFieldsAdminDescription => _t('customFieldsAdminDescription');
  String get recommendedSyncKeysHint => _t('recommendedSyncKeysHint');

  // ── Auth extras ─────────────────────────────────────────────────────────────
  String get registrationSuccessfulPleaseSignIn =>
      _t('registrationSuccessfulPleaseSignIn');

  // ── Common booleans / placeholders ────────────────────────────────────────
  String get yes => _t('yes');
  String get no => _t('no');
  String get unknownName => _t('unknownName');
  String get notAvailable => _t('notAvailable');
  String get timeFormatHint => _t('timeFormatHint');
  String get churchBrand => _t('churchBrand');

  // ── Errors (no context) ───────────────────────────────────────────────────
  String get genericErrorTryAgain => _t('genericErrorTryAgain');
  String get invalidCredentialsPleaseTryAgain =>
      _t('invalidCredentialsPleaseTryAgain');
  String get sessionExpiredPleaseSignIn => _t('sessionExpiredPleaseSignIn');
  String get networkErrorTryAgain => _t('networkErrorTryAgain');
  String get somethingWentWrongTryAgain => _t('somethingWentWrongTryAgain');
  String get serverErrorTryLater => _t('serverErrorTryLater');

  // ── Members / servants / IDs ──────────────────────────────────────────────
  String get invalidMemberId => _t('invalidMemberId');
  String get invalidMemberIdDetail => _t('invalidMemberIdDetail');
  String get memberIdMissingFromApi => _t('memberIdMissingFromApi');
  String get servantIdMissingFromApi => _t('servantIdMissingFromApi');

  // ── Attendance extras ───────────────────────────────────────────────────────
  String get noAttendanceSessionsYet => _t('noAttendanceSessionsYet');
  String get editMeeting => _t('editMeeting');
  String get editChurch => _t('editChurch');
  String get classroomDetails => _t('classroomDetails');
  String get customFieldValues => _t('customFieldValues');
  String get entityChurch => _t('entityChurch');

  // ── Custom fields extras ──────────────────────────────────────────────────
  String get additionalFields => _t('additionalFields');
  String get additionalFieldsSaved => _t('additionalFieldsSaved');
  String get saveAdditionalFields => _t('saveAdditionalFields');
  String get failedToLoadCustomFields => _t('failedToLoadCustomFields');
  String get isoDateTimeHint => _t('isoDateTimeHint');
  String get jsonExampleHint => _t('jsonExampleHint');

  // ── Admin confirm ─────────────────────────────────────────────────────────
  String rejectUserConfirm(String name) =>
      _t('rejectUserConfirm').replaceAll('{name}', name);

  // ── Validation templates ──────────────────────────────────────────────────
  String fieldIsRequired(String displayName) =>
      _t('fieldIsRequired').replaceAll('{name}', displayName);
  String fieldFormatInvalid(String displayName) =>
      _t('fieldFormatInvalid').replaceAll('{name}', displayName);
  String fieldMustBeWholeNumber(String displayName) =>
      _t('fieldMustBeWholeNumber').replaceAll('{name}', displayName);
  String fieldMustBeNumber(String displayName) =>
      _t('fieldMustBeNumber').replaceAll('{name}', displayName);
  String fieldMustBeBoolean(String displayName) =>
      _t('fieldMustBeBoolean').replaceAll('{name}', displayName);
  String fieldMustBeValidDate(String displayName) =>
      _t('fieldMustBeValidDate').replaceAll('{name}', displayName);
  String fieldMustBeValidDateTime(String displayName) =>
      _t('fieldMustBeValidDateTime').replaceAll('{name}', displayName);
  String fieldMustBeValidJson(String displayName) =>
      _t('fieldMustBeValidJson').replaceAll('{name}', displayName);
  String selectValidOptionFor(String displayName) =>
      _t('selectValidOptionFor').replaceAll('{name}', displayName);
  String fieldRequiresAtLeastOneOption(String displayName) =>
      _t('fieldRequiresAtLeastOneOption').replaceAll('{name}', displayName);
  String invalidSelectionFor(String displayName) =>
      _t('invalidSelectionFor').replaceAll('{name}', displayName);

  /// Locale-aware integer for UI (Western in EN, Eastern Arabic in AR).
  String formatNumber(num value) => LocaleFormat.number(value, locale);

  String formatInteger(int value) => LocaleFormat.integer(value, locale);

  /// Localizes Western digits inside arbitrary text (ages, IDs in labels, etc.).
  String formatDigitsIn(String text) => LocaleFormat.digitsIn(text, locale);

  /// Locale-aware date preview (short date, correct reading direction).
  String formatDate(String? raw) => LocaleFormat.formatDateString(raw, locale);

  /// Locale-aware date-time preview.
  String formatDateTime(String? raw) =>
      LocaleFormat.formatDateTimeString(raw, locale);

  String memberNumberLabel(int id) =>
      _t('memberNumber').replaceAll('{id}', formatInteger(id));

  String sessionNumberLabel(int id) =>
      _t('sessionNumber').replaceAll('{id}', formatInteger(id));

  String recordsCountLabel(int count) =>
      _t('recordsCountLabel').replaceAll('{count}', formatInteger(count));

  String pendingCountText(int count) =>
      pendingCount.replaceAll('{count}', formatInteger(count));

  String ageLabelText(String? age) {
    final display = (age == null || age.trim().isEmpty)
        ? notAvailable
        : formatDigitsIn(age.trim());
    return ageLabel.replaceAll('{age}', display);
  }

  String attendanceSessionsCountText(int count) =>
      attendanceSessionsCount.replaceAll('{count}', formatInteger(count));

  String membersCountLine(int count) =>
      '${formatInteger(count)} $members';

  String membersAndSessionsLine(int members, int sessions) =>
      '${membersCountLine(members)} · ${attendanceSessionsCountText(sessions)}';

  String meetingServantsMembersSummary(int servants, int members) =>
      _t('meetingServantsMembersSummary')
          .replaceAll('{servants}', formatInteger(servants))
          .replaceAll('{members}', formatInteger(members));
  String attendanceHistoryTitle(String? classroomName) {
    if (classroomName == null || classroomName.trim().isEmpty) {
      return attendanceHistory;
    }
    return _t('attendanceHistoryWithClassroom')
        .replaceAll('{classroom}', classroomName);
  }
  String entityAdditionalFieldsTitle(String entityName) =>
      _t('entityAdditionalFieldsTitle')
          .replaceAll('{entity}', entityDisplayName(entityName));

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
      'quickAccess': 'Quick Access',
      'members': 'Members',
      'attendance': 'Attendance',
      'groups': 'groups',
      'classrooms': 'Classrooms',
      'servants': 'Servants',
      'logout': 'Logout',
      'sundaySchool': 'Sunday School',
      // Children
      'noMembers': 'No members yet. Tap + to add one.',
      'addMember': 'Add Member',
      'editMember': 'Edit Member',
      'memberDetails': 'Member Details',
      'search': 'Search',
      'searchMembers': 'Search members',
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
      'fatherName': 'Father name',
      'familyName': 'Family name',
      'memberSectionPersonal': 'Personal information',
      'memberSectionDates': 'Dates',
      'disciplineStatus': 'Discipline member',
      'disciplineStatusHint':
          'Mark if this member is on the discipline list',
      'fullNameComputedHint':
          'Full name is generated automatically from the name fields',
      'optionalLabel': 'Optional',
      'clearLabel': 'Clear',
      'haveBrothersQuestion': 'Does the member have brothers in the program?',
      'addPhoneNumber': 'Add phone number',
      'removePhoneNumber': 'Remove phone number',
      'removeBrother': 'Remove brother',
      'removeNote': 'Remove note',
      'phoneRelationMember': 'Member',
      'phoneRelationFather': 'Father',
      'phoneRelationMother': 'Mother',
      'phoneRelationBrother': 'Brother',
      'phoneRelationSister': 'Sister',
      'phoneRelationGuardian': 'Guardian',
      'phoneRelationOther': 'Other',
      'invalidPhoneFormat': 'Enter a valid phone number',
      'relationRequiredWhenPhone':
          'Select a relation when a phone number is entered',
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
      'deleteMeeting': 'Delete Meeting',
      'confirmDeleteMeeting':
          'Deleting this meeting will permanently delete all groups and all members inside these groups. This action cannot be undone. Do you want to continue?',
      'meetingDeletedSuccessfully': 'Meeting deleted successfully',
      'deleteClassroom': 'Delete Classroom',
      'confirmDeleteClassroom':
          'Delete this classroom and all members assigned to it? This cannot be undone.',
      'classroomDeletedSuccessfully': 'Classroom deleted successfully',
      'leaderServantLabel': 'Leader Servant',
      'assignedServantsLabel': 'Assigned Servants',
      'noServantsAssigned': 'No servants assigned',
      // Registration
      'churchId': 'Church ID',
      'enterChurchId': 'Enter your church ID',
      'churchIdRequired': 'Church ID is required',
      'churchOrMeetingIdLabel': 'Church ID or Meeting ID',
      'enterChurchOrMeetingId': 'Enter church ID or meeting ID',
      'churchOrMeetingIdRequired': 'Church ID or Meeting ID is required',
      'requestedMeetingNameChurchIdHint':
          'Required only when registering with a Church ID (not a Meeting ID).',
      'meetingAdminPhoneChurchIdHint':
          'Required for servants registering with a Church ID only.',
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
      'churchExistsQuestion': 'Does your church already exist in the application?',
      'churchExistsYes': 'Yes, my church already exists',
      'churchExistsNo': 'No, my church does not exist yet',
      'joinExistingChurchTitle': 'Join an Existing Church',
      'meetingAdminPhone': 'Meeting Admin Phone Number',
      'enterMeetingAdminPhone': 'Enter the meeting admin\'s phone number',
      'meetingAdminPhoneRequired': 'Meeting admin phone number is required',
      'noMeetingsToAssign': 'No meetings exist yet. Create a meeting before approving this user.',
      'weeklyAppointment': 'Weekly Appointment',
      'weeklyAppointmentRequired': 'Weekly appointment is required',
      'phoneAlreadyUsed': 'This phone number is already in use. Please sign in or use a different number.',
      'phoneInvalid':
          'Enter a valid phone number (e.g. +201001234567).',
      'churchNameAlreadyExists': 'A church with this name already exists.',
      'churchOrMeetingNotFound': 'Church or meeting not found.',
      'churchOrMeetingIdInvalid':
          'A valid church or meeting identifier is required.',
      'meetingAdminPhoneRequiredForServants':
          'Meeting admin phone number is required for servants.',
      'registrationUsernameConflict':
          'Registration failed due to a username conflict. Please try again.',
      'meetingNotInChurch':
          'The selected meeting does not belong to the selected church.',
      'validationFailed': 'Validation failed',
      'confirmPasswordRequired': 'Confirm password is required.',
      'passwordRequiresDigit': 'Password must contain at least one digit.',
      'passwordRequiresLower':
          'Password must contain at least one lowercase letter.',
      'passwordRequiresUpper':
          'Password must contain at least one uppercase letter.',
      'passwordRequiresNonAlphanumeric':
          'Password must contain at least one non-alphanumeric character.',
      'registrationDataInvalid': 'Registration data is invalid.',
      'churchAlreadyExists': 'Church already exists.',
      'passwordMustContainAtLeast6':
          'Password must contain at least 6 characters.',
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
          'Enter a classroom ID and tap Load\nto see members.',
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
      'pendingUsers': 'Pending Users',
      'noPendingUsers': 'No pending users.',
      'requestedMeetingName': 'Requested Meeting Name',
      'enterRequestedMeetingName': 'e.g. Preparatory Boys, College, Servants Meeting',
      'requestedMeetingNameRequired': 'Requested meeting name is required.',
      'requestedMeetingLabel': 'Requested Meeting',
      'requestedRoleLabel': 'Role',
      'registrationDateLabel': 'Registration Date',
      'publicChurchIdLabel': 'Public Church ID',
      'publicMeetingIdLabel': 'Public Meeting ID',
      'approveUserTitle': 'Approve User',
      'meetingSelectionRequired': 'Please select a meeting for this user.',
      'rejectReasonOptional': 'Reason (optional)',
      'accountPendingApproval':
          'Your account is waiting for approval from the church administrator.',
      'accountRejected': 'Your registration request was rejected.',
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

      // groups
      'classroomsHome': 'groups Home',
      'classroomsTitleWithMeeting': 'groups — {meetingName}',
      'addClassroom': 'Add Classroom',
      'classroomNameLabel': 'Classroom Name',
      'enterClassroomNameHint': 'Enter classroom name',
      'classroomNameRequiredGeneric': 'Classroom name is required',
      'ageOfMembersLabel': 'Age of Members',
      'numberOfDisciplineMembersLabel': 'Number of discipline members',
      'totalMembersCountLabel': 'Total members count',
      'photoLabel': 'Photo',
      'enterAgeRangeHint': 'Enter age range',
      'ageOfMembersRequiredGeneric': 'Age of members is required',
      'classroomAddedSuccessfully': 'Classroom added successfully.',
      'visibleClassrooms': 'Visible groups',
      'noVisibleClassroomsFound': 'No visible groups found.',
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
      'addUpdateRemoveMembers': 'Manage Members',
      'manageServants': 'Manage Servants',
      'home': 'Home',

      // Profile / Forms
      'profile': 'Profile',
      'editProfile': 'Edit profile',
      'profileInformation': 'Profile information',
      'servantInformation': 'Servant information',
      'appSettings': 'App settings',
      'tapToChangePhoto': 'Tap to change photo',
      'saveLabel': 'Save',
      'done': 'Done',
      'select': 'Select',
      'failedToLoadOptions': 'Failed to load options:',
      'failedToLoadProfile': 'Failed to load profile:',
      'profileUpdated': 'Profile updated.',
      'churchIdLabel': 'Church ID',
      'copyLabel': 'Copy',
      'churchIdCopied': 'Church ID copied to clipboard',
      'meetingIdLabel': 'Meeting ID',
      'meetingIdCopied': 'Meeting ID copied to clipboard',
      'meetingMoreActions': 'More actions',
      'churchMeetingsIdsTitle': 'Meeting IDs in your church',
      'meetingLabel': 'Meeting',
      'selectMeeting': 'Select meeting',
      'classroomsLabel': 'groups',
      'selectClassrooms': 'Select groups',
      'superAdminHome': 'Super Admin Home',
      'loadingLabel': 'Loading...',
      'errorLabel': 'Error:',
      'pendingCount': '{count} pending',
      'noVisibleMeetingsFound': 'No visible meetings found.',
      'failedToLoadVisibleMeetings': 'Failed to load visible meetings:',
      'failedToLoadVisibleClassrooms': 'Failed to load visible groups:',
      'failedToLoadClassrooms': 'Failed to load groups:',
      'editMeetingTitle': 'Edit Meeting: {meeting}',
      'pageNotFound': 'Page not found:',
      'missingRequiredData': 'Missing required data for this screen.',
      'optional': 'optional',
      'visibleMeetings': 'Visible Meetings',
      'leaderServantOptional': 'Leader Servant (optional)',
      'classroomServantsOptional': 'Servants (optional)',
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
      // Custom fields
      'customFields': 'Custom fields',
      'customFieldsForEntity': '{entity} custom fields',
      'entityMember': 'Member',
      'entityClassroom': 'Classroom',
      'entityServant': 'Servant',
      'entityMeeting': 'Meeting',
      'notAuthorized': 'Not authorized',
      'noCustomFieldsYet': 'No custom fields yet.',
      'noFieldsConfigured': 'No fields configured yet.',
      'systemFieldsSection': 'System fields',
      'systemFieldsSectionHint':
          'Built-in model properties. You can rename labels, hide fields, reorder, and set validation. Database column names cannot be changed.',
      'customFieldsSection': 'Custom fields',
      'systemFieldBadge': 'System',
      'fieldStatusRequired': 'Required',
      'fieldStatusOptional': 'Optional',
      'fieldHiddenInForms': 'Hidden in forms',
      'fieldHiddenLabel': 'Hidden in forms',
      'fieldHiddenHint': 'When enabled, this field is not shown on create/edit screens.',
      'sortOrderLabel': 'Sort order',
      'fieldAppearancePositionLabel': 'Appearance position',
      'fieldPos_1': 'First',
      'fieldPos_2': 'Second',
      'fieldPos_3': 'Third',
      'fieldPos_4': 'Fourth',
      'fieldPos_5': 'Fifth',
      'fieldPos_6': 'Sixth',
      'fieldPos_7': 'Seventh',
      'fieldPos_8': 'Eighth',
      'fieldPos_9': 'Ninth',
      'fieldPos_10': 'Tenth',
      'fieldPositionNumber': 'Position {n}',
      'fieldPositionLast': 'Last',
      'deleteFieldPermanently': 'Delete field permanently',
      'deleteFieldPermanentlyConfirm':
          'This will permanently delete "{name}" and all saved values. This action cannot be undone.',
      'deletePermanently': 'Delete permanently',
      'fieldMoreOptions': 'Field options',
      'fieldDeletedPermanently': 'Field deleted permanently',
      'systemFieldCannotDelete':
          'The entity name field cannot be permanently deleted.',
      'placeholderLabel': 'Placeholder',
      'validationRegexLabel': 'Validation pattern (regex)',
      'editSystemField': 'Edit system field',
      'systemFieldNameLocked':
          'Database key "{name}" is fixed and cannot be changed.',
      'systemFieldKeyLockedLabel':
          '"{label}" is a system field; its internal property name cannot be changed.',
      'systemFieldCannotDeactivate': 'The entity name field cannot be deactivated.',
      'systemFieldNotProvisioned':
          'This system field is not saved on the server yet. Deploy the latest API and reopen this screen.',
      'editCustomField': 'Edit custom field',
      'newCustomField': 'New custom field',
      'displayNameLabel': 'Display name',
      'displayNameEnglishLabel': 'Display name (English)',
      'displayNameArabicLabel': 'Display name (Arabic)',
      'displayNameRequired': 'Display name is required',
      'fieldTypeLabel': 'Field type',
      'fieldRequiredLabel': 'Required',
      'fieldReadOnlyLabel': 'Read only',
      'customFieldOptions': 'Options',
      'addOption': 'Add option',
      'optionValueLabel': 'Stored value',
      'optionLabelLabel': 'Shown label',
      'createField': 'Create field',
      'deactivateField': 'Deactivate field',
      'deactivateFieldConfirm':
          'Deactivate "{name}"? Existing values are preserved.',
      'deactivate': 'Deactivate',
      'fieldDeactivated': 'Field deactivated',
      'reactivateField': 'Reactivate field',
      'reactivateFieldConfirm': 'Reactivate "{name}"? It will appear on forms and detail screens again.',
      'reactivate': 'Reactivate',
      'fieldActivated': 'Field activated',
      'fieldActive': 'Active',
      'fieldInactive': 'Inactive',
      'selectOptionsRequired': 'Add at least one option for this field type.',
      'manageCustomFields': 'Manage custom fields',
      'editEntityFields': 'Edit fields',
      'cfdt_text': 'Short text',
      'cfdt_longText': 'Long text',
      'cfdt_number': 'Whole number',
      'cfdt_decimal': 'Decimal number',
      'cfdt_boolean': 'Yes / No',
      'cfdt_date': 'Date',
      'cfdt_dateTime': 'Date and time',
      'cfdt_json': 'Structured data',
      'cfdt_singleSelect': 'Single choice',
      'cfdt_multiSelect': 'Multiple choice',
      'changesSaved': 'Changes saved.',
      'entityFieldsNotConfigured':
          'An admin must define which attributes to store for this entity (Custom Fields).',
      'configureEntityAttributesTitle': 'Configure {entity} attributes',
      'customFieldsAdminDescription':
          'System fields from the backend model appear at the top. Custom fields you create appear below. Configure labels, visibility, order, and validation; active fields appear on create, edit, and detail screens.',
      'recommendedSyncKeysHint':
          'Tip: use internal keys like name, ageOfMembers, or leaderServantId (classroom) to also update list titles when auto-generated from display names.',
      // Auth
      'registrationSuccessfulPleaseSignIn':
          'Registration successful. Please sign in.',
      // Common
      'yes': 'Yes',
      'no': 'No',
      'unknownName': 'Unknown',
      'notAvailable': '—',
      'timeFormatHint': 'HH:mm',
      'churchBrand': 'MY Church',
      // Errors
      'genericErrorTryAgain': 'An error occurred. Please try again.',
      'invalidCredentialsPleaseTryAgain':
          'Wrong credentials. Please try again.',
      'sessionExpiredPleaseSignIn':
          'Your session has expired. Please sign in again.',
      'networkErrorTryAgain':
          'Network error. Please check your connection and try again.',
      'somethingWentWrongTryAgain': 'Something went wrong. Please try again.',
      'serverErrorTryLater': 'Server error. Please try again later.',
      // IDs / API
      'invalidMemberId': 'Invalid member id.',
      'invalidMemberIdDetail':
          'Invalid member id. Open this screen from the list after the API returns real ids.',
      'memberIdMissingFromApi':
          'Member id is missing from the server response. The API must include an id field on each member.',
      'servantIdMissingFromApi':
          'Servant id is missing from the server response. The API must include an id field on each servant.',
      // Attendance
      'noAttendanceSessionsYet': 'No attendance sessions yet.',
      'sessionNumber': 'Session #{id}',
      'recordsCountLabel': '{count} records',
      'attendanceHistoryWithClassroom': 'Attendance history • {classroom}',
      'meetingServantsMembersSummary':
          'Servants: {servants} • Members: {members}',
      // Routing / screens
      'editMeeting': 'Edit meeting',
      'editChurch': 'Edit church',
      'classroomDetails': 'Classroom details',
      'customFieldValues': 'Custom field values',
      'entityChurch': 'Church',
      // Custom fields extras
      'additionalFields': 'Additional fields',
      'additionalFieldsSaved': 'Additional fields saved',
      'saveAdditionalFields': 'Save additional fields',
      'entityAdditionalFieldsTitle': '{entity} — additional fields',
      'failedToLoadCustomFields': 'Failed to load custom fields:',
      'isoDateTimeHint': 'ISO date-time',
      'jsonExampleHint': '{"key": "value"}',
      // Admin
      'rejectUserConfirm': 'This will reject {name}.',
      // Validation templates
      'fieldIsRequired': '{name} is required',
      'fieldFormatInvalid': '{name} does not match the required format',
      'fieldMustBeWholeNumber': '{name} must be a whole number',
      'fieldMustBeNumber': '{name} must be a number',
      'fieldMustBeBoolean': '{name} must be true or false',
      'fieldMustBeValidDate': '{name} must be a valid date',
      'fieldMustBeValidDateTime': '{name} must be a valid date/time',
      'fieldMustBeValidJson': '{name} must be valid JSON',
      'selectValidOptionFor': 'Select a valid option for {name}',
      'fieldRequiresAtLeastOneOption': '{name} requires at least one option',
      'invalidSelectionFor': 'Invalid selection for {name}',
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
      'groups': 'المجموعه',
      'classrooms': 'المجموعات',
      'servants': 'الخدام',
      'logout': 'تسجيل الخروج',
      'sundaySchool': 'مدرسة الأحد',
      'managementSystem': 'نظام الإدارة',
      // Children
      'noMembers': 'لا يوجد أعضاء بعد. اضغط + للإضافة.',
      'addMember': 'إضافة مخدوم',
      'editMember': 'تعديل مخدوم',
      'memberDetails': 'تفاصيل المخدوم',
      'search': 'بحث',
      'searchMembers': 'البحث عن الأعضاء',
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
      'classroomId': 'المجموعه',
      'cancel': 'إلغاء',
      'deleteMember': 'حذف مخدوم',
      'confirmDeleteMember': 'هل أنت متأكد من حذف هذا المخدوم؟',
      'memberAddedSuccessfully': 'تمت إضافة المخدوم بنجاح',
      'memberUpdatedSuccessfully': 'تم تحديث المخدوم بنجاح',
      'memberDeletedSuccessfully': 'تم حذف المخدوم بنجاح',
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
      'fatherName': 'اسم الأب',
      'familyName': 'اسم العائلة',
      'memberSectionPersonal': 'المعلومات الشخصية',
      'memberSectionDates': 'التواريخ',
      'disciplineStatus': 'ملتزم',
      'disciplineStatusHint': 'حدّد إذا كان المخدوم ضمن قائمة الانضباط',
      'fullNameComputedHint':
          'يُولَّد الاسم الكامل تلقائياً من معلومات الاسم',
      'optionalLabel': 'اختياري',
      'clearLabel': 'مسح',
      'haveBrothersQuestion': 'هل لدى المخدوم إخوة في البرنامج؟',
      'addPhoneNumber': 'إضافة رقم هاتف',
      'removePhoneNumber': 'إزالة رقم الهاتف',
      'removeBrother': 'إزالة أخ',
      'removeNote': 'إزالة ملاحظة',
      'phoneRelationMember': 'المخدوم',
      'phoneRelationFather': 'الأب',
      'phoneRelationMother': 'الأم',
      'phoneRelationBrother': 'الأخ',
      'phoneRelationSister': 'الأخت',
      'phoneRelationGuardian': 'ولي الأمر',
      'phoneRelationOther': 'أخرى',
      'invalidPhoneFormat': 'أدخل رقماً هاتفياً صالحاً',
      'relationRequiredWhenPhone':
          'اختر صلة القرابة عند إدخال رقم هاتف',
      'classroomIdsOptional': ' المجموعه (مفصولة بفاصلة، اختياري)',
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
      'selectClassroom': 'المجموعات',

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
      'deleteMeeting': 'حذف الاجتماع',
      'confirmDeleteMeeting':
          'سيؤدي حذف هذا الاجتماع إلى حذف جميع المجموعه وجميع الأعضاء داخل هذه المجموعه نهائياً. لا يمكن التراجع عن هذا الإجراء. هل تريد المتابعة؟',
      'meetingDeletedSuccessfully': 'تم حذف الاجتماع بنجاح',
      'deleteClassroom': 'حذف المجموعه',
      'confirmDeleteClassroom':
          'حذف هذا المجموعه وجميع الأعضاء المعيّنين فيه؟ لا يمكن التراجع عن هذا الإجراء.',
      'classroomDeletedSuccessfully': 'تم حذف المجموعه بنجاح',
      'leaderServantLabel': 'الخادم المسؤول',
      'assignedServantsLabel': 'الخدام المعيّنون',
      'noServantsAssigned': 'لا يوجد خدام معيّنون',
      // Registration
      'churchId': 'كود الكنيسه (اطلبه من الراعي)',
      'enterChurchId': 'أدخل كود كنيستك',
      'churchIdRequired': 'كود الكنيسة مطلوب',
      'churchOrMeetingIdLabel': 'كود الكنيسة أو كود الاجتماع',
      'enterChurchOrMeetingId': 'أدخل كود الكنيسة أو كود الاجتماع',
      'churchOrMeetingIdRequired': 'كود الكنيسة أو كود الاجتماع مطلوب',
      'requestedMeetingNameChurchIdHint':
          'مطلوب فقط عند التسجيل بكود الكنيسة (وليس كود الاجتماع).',
      'meetingAdminPhoneChurchIdHint':
          'مطلوب للخدام المسجّلين بكود الكنيسة فقط.',
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
      'registerTypeChurchAdmin': 'قائد الكنيسة',
      'registerTypeMeetingAdmin': 'قائد اجتماع',
      'churchExistsQuestion': 'هل كنيستك مسجّلة بالفعل في التطبيق؟',
      'churchExistsYes': 'نعم، كنيستي موجودة بالفعل',
      'churchExistsNo': 'لا، كنيستي غير موجودة بعد',
      'joinExistingChurchTitle': 'الانضمام إلى كنيسة موجودة',
      'meetingAdminPhone': 'رقم هاتف قائد الاجتماع',
      'enterMeetingAdminPhone': 'أدخل رقم هاتف قائد الاجتماع',
      'meetingAdminPhoneRequired': 'رقم هاتف قائد الاجتماع مطلوب',
      'noMeetingsToAssign': 'لا توجد اجتماعات بعد. أنشئ اجتماعًا قبل الموافقة على هذا المستخدم.',
      'weeklyAppointment': 'الموعد الأسبوعي',
      'weeklyAppointmentRequired': 'الموعد الأسبوعي مطلوب',
      'phoneAlreadyUsed': 'رقم الهاتف مستخدم بالفعل. يرجى تسجيل الدخول أو استخدام رقم آخر.',
      'phoneInvalid':
          'أدخل رقم هاتف صالح (مثال: +201001234567).',
      'churchNameAlreadyExists': 'كنيسة بهذا الاسم موجودة بالفعل.',
      'churchOrMeetingNotFound': 'الكنيسة أو الاجتماع غير موجود.',
      'churchOrMeetingIdInvalid': 'يلزم إدخال معرّف كنيسة أو اجتماع صالح.',
      'meetingAdminPhoneRequiredForServants':
          'رقم هاتف قائد الاجتماع مطلوب للخدام.',
      'registrationUsernameConflict':
          'فشل التسجيل بسبب تعارض في اسم المستخدم. يرجى المحاولة مرة أخرى.',
      'meetingNotInChurch':
          'الاجتماع المحدد لا ينتمي إلى الكنيسة المحددة.',
      'validationFailed': 'فشل التحقق من البيانات',
      'confirmPasswordRequired': 'تأكيد كلمة المرور مطلوب.',
      'passwordRequiresDigit': 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل.',
      'passwordRequiresLower':
          'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل.',
      'passwordRequiresUpper':
          'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل.',
      'passwordRequiresNonAlphanumeric':
          'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل.',
      'registrationDataInvalid': 'بيانات التسجيل غير صالحة.',
      'churchAlreadyExists': 'الكنيسة موجودة بالفعل.',
      'passwordMustContainAtLeast6':
          'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل.',
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
      'enterClassroomAndLoad': 'أدخل  المجموعه واضغط تحميل\nلعرض الأعضاء.',
      'attendanceSaved': 'تم حفظ الحضور!',
      'loadMembersFirst': 'قم بتحميل الأعضاء أولاً',
      'enterClassroomId': 'أدخل  المجموعه',
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
      'assignClass': 'تعيين مجموعه',
      'assignClassroom': 'تعيين مجموعه',
      'classroom': 'المجموعه',
      'pleaseSelectClassroom': 'يرجى اختيار مجموعه.',
      'classAssigned': 'تم تعيين المجموعه.',
      'noPendingServants': 'لا يوجد خدام معلّقون.',
      'noPendingAdmins': 'لا يوجد مسؤولون معلّقون.',
      'noName': '(بدون اسم)',
      'noPhone': '(بدون رقم)',
      'rejectServantTitle': 'رفض الخادم؟',
      'rejectAdminTitle': 'رفض المسؤول؟',
      'rejectThisUser': 'هذا المستخدم',
      'approvedUser': 'تم القبول',
      'rejectedUser': 'تم الرفض',
      'pendingUsers': 'المستخدمون المعلّقون',
      'noPendingUsers': 'لا يوجد مستخدمون معلّقون.',
      'requestedMeetingName': 'اسم الاجتماع المطلوب',
      'enterRequestedMeetingName': 'مثال: إعدادي بنين، الجامعة، اجتماع الخدام',
      'requestedMeetingNameRequired': 'اسم الاجتماع المطلوب مطلوب.',
      'requestedMeetingLabel': 'الاجتماع المطلوب',
      'requestedRoleLabel': 'الدور',
      'registrationDateLabel': 'تاريخ التسجيل',
      'publicChurchIdLabel': 'معرّف الكنيسة العام',
      'publicMeetingIdLabel': 'معرّف الاجتماع العام',
      'approveUserTitle': 'قبول المستخدم',
      'meetingSelectionRequired': 'يرجى اختيار اجتماع لهذا المستخدم.',
      'rejectReasonOptional': 'السبب (اختياري)',
      'accountPendingApproval': 'حسابك في انتظار موافقة مسؤول الكنيسة.',
      'accountRejected': 'تم رفض طلب تسجيلك.',
      'assignClassTooltip': 'تعيين مجموعه',
      'couldNotVerifyRole': 'تعذر التحقق من الدور:',
      'adminOnlyScreen': 'هذه الصفحة خاصة بالقاده فقط.',
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

      // groups
      'classroomsHome': 'صفحة المجموعه',
      'classroomsTitleWithMeeting': 'المجموعه — {meetingName}',
      'addClassroom': 'إضافة مجموعه',
      'classroomNameLabel': 'اسم المجموعه',
      'enterClassroomNameHint': 'أدخل اسم المجموعه',
      'classroomNameRequiredGeneric': 'اسم المجموعه مطلوب',
      'ageOfMembersLabel': 'أعمار الأعضاء',
      'numberOfDisciplineMembersLabel': 'عدد الأعضاء الملتزمين',
      'totalMembersCountLabel': 'إجمالي عدد الأعضاء',
      'photoLabel': 'الصورة',
      'enterAgeRangeHint': 'أدخل نطاق الأعمار',
      'ageOfMembersRequiredGeneric': 'أعمار الأعضاء مطلوبة',
      'classroomAddedSuccessfully': 'تمت إضافة المجموعه بنجاح.',
      'visibleClassrooms': 'المجموعه',
      'noVisibleClassroomsFound': 'لم يتم العثور على مجموعات ظاهرة.',
      'attendanceHistory': 'سجل الحضور',

      // Members / Common actions
      'retry': 'إعادة المحاولة',
      'couldNotLoadMembers': 'تعذر تحميل الأعضاء:',
      'noMembersInClassroomYet': 'لا يوجد أعضاء في هذا المجموعه بعد.',
      'memberNumber': ' رقم المخدوم {id}',
      'classroomInvalidMissingId': 'مجموعه غير صالح: الكود مفقود.',
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
      'addUpdateRemoveMembers': 'إدارة الأعضاء',
      'manageServants': 'إدارة الخدام',
      'home': 'الرئيسية',

      // Profile / Forms
      'profile': 'الملف الشخصي',
      'editProfile': 'تعديل الملف الشخصي',
      'profileInformation': 'معلومات الملف الشخصي',
      'servantInformation': 'معلومات الخادم',
      'appSettings': 'إعدادات التطبيق',
      'tapToChangePhoto': 'اضغط لتغيير الصورة',
      'saveLabel': 'حفظ',
      'done': 'تم',
      'select': 'اختر',
      'failedToLoadOptions': 'تعذر تحميل الخيارات:',
      'failedToLoadProfile': 'تعذر تحميل الملف الشخصي:',
      'profileUpdated': 'تم تحديث الملف الشخصي.',
      'churchIdLabel': 'كود الكنيسة',
      'copyLabel': 'نسخ',
      'churchIdCopied': 'تم نسخ كود الكنيسة',
      'meetingIdLabel': 'كود الاجتماع',
      'meetingIdCopied': 'تم نسخ كود الاجتماع',
      'meetingMoreActions': 'المزيد من الإجراءات',
      'churchMeetingsIdsTitle': 'أكواد الاجتماعات في كنيستك',
      'meetingLabel': 'الاجتماع',
      'selectMeeting': 'اختر الاجتماع',
      'classroomsLabel': 'المجموعه',
      'selectClassrooms': 'اختر المجموعه',
      'superAdminHome': 'الصفحة الرئيسيه',
      'loadingLabel': 'جار التحميل...',
      'errorLabel': 'خطأ:',
      'pendingCount': '{count} معلّق',
      'noVisibleMeetingsFound': 'لم يتم العثور على اجتماعات ظاهرة.',
      'failedToLoadVisibleMeetings': 'تعذر تحميل الاجتماعات :',
      'failedToLoadVisibleClassrooms': 'تعذر تحميل المجموعه :',
      'failedToLoadClassrooms': 'تعذر تحميل المجموعه:',
      'editMeetingTitle': 'تعديل الاجتماع: {meeting}',
      'pageNotFound': 'الصفحة غير موجودة:',
      'missingRequiredData': 'بيانات مطلوبة مفقودة لهذه الصفحة.',
      'optional': 'اختياري',
      'visibleMeetings': 'الاجتماعات ',
      'leaderServantOptional': 'الخادم المسؤول (اختياري)',
      'classroomServantsOptional': 'الخدام (اختياري)',
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
      // Custom fields
      'customFields': 'المعلومات الجديده',
      'customFieldsForEntity': 'معلومات جديده — {entity}',
      'entityMember': 'المخدوم',
      'entityClassroom': 'المجموعه',
      'entityServant': 'الخادم',
      'entityMeeting': 'الاجتماع',
      'notAuthorized': 'غير مصرح',
      'noCustomFieldsYet': 'لا توجد معلومات جديده بعد.',
      'noFieldsConfigured': 'لا توجد معلومات مُعدّة بعد.',
      'systemFieldsSection': 'معلومات النظام',
      'systemFieldsSectionHint':
          'خصائص النموذج المدمجة. يمكنك تغيير التسميات وإخفاء المعلومات وإعادة الترتيب وضبط التحقق. لا يمكن تغيير أسماء أعمدة قاعدة البيانات.',
      'customFieldsSection': 'المعلومات الجديده',
      'systemFieldBadge': 'نظام',
      'fieldStatusRequired': 'إلزامي',
      'fieldStatusOptional': 'اختياري',
      'fieldHiddenInForms': 'مخفي في النماذج',
      'fieldHiddenLabel': 'مخفي في النماذج',
      'fieldHiddenHint': 'عند التفعيل، لا يظهر هذا الحقل في شاشات الإنشاء أو التعديل.',
      'sortOrderLabel': 'ترتيب العرض',
      'fieldAppearancePositionLabel': 'موضع الظهور',
      'fieldPos_1': 'الأول',
      'fieldPos_2': 'الثاني',
      'fieldPos_3': 'الثالث',
      'fieldPos_4': 'الرابع',
      'fieldPos_5': 'الخامس',
      'fieldPos_6': 'السادس',
      'fieldPos_7': 'السابع',
      'fieldPos_8': 'الثامن',
      'fieldPos_9': 'التاسع',
      'fieldPos_10': 'العاشر',
      'fieldPositionNumber': 'الموضع {n}',
      'fieldPositionLast': 'الأخير',
      'deleteFieldPermanently': 'حذف الحقل نهائياً',
      'deleteFieldPermanentlyConfirm':
          'سيؤدي هذا إلى حذف "{name}" وجميع القيم المحفوظة نهائياً. لا يمكن التراجع عن هذا الإجراء.',
      'deletePermanently': 'حذف نهائي',
      'fieldMoreOptions': 'خيارات الحقل',
      'fieldDeletedPermanently': 'تم حذف الحقل نهائياً',
      'systemFieldCannotDelete':
          'لا يمكن حذف حقل اسم الكيان نهائياً.',
      'placeholderLabel': 'نص توضيحي',
      'validationRegexLabel': 'نمط التحقق (تعبير نمطي)',
      'editSystemField': 'تعديل حقل النظام',
      'systemFieldNameLocked':
          'مفتاح قاعدة البيانات "{name}" ثابت ولا يمكن تغييره.',
      'systemFieldKeyLockedLabel':
          '"{label}" حقل نظام؛ لا يمكن تغيير اسم الخاصية الداخلي له.',
      'systemFieldCannotDeactivate': 'لا يمكن إلغاء تفعيل حقل اسم الكيان.',
      'systemFieldNotProvisioned':
          'حقل النظام هذا غير محفوظ على الخادم بعد. انشر أحدث إصدار من الواجهة البرمجية وأعد فتح هذه الشاشة.',
      'editCustomField': 'تعديل حقل مخصص',
      'newCustomField': 'حقل مخصص جديد',
      'displayNameLabel': 'الاسم المعروض',
      'displayNameEnglishLabel': 'الاسم المعروض (إنجليزي)',
      'displayNameArabicLabel': 'الاسم المعروض (عربي)',
      'displayNameRequired': 'الاسم المعروض مطلوب',
      'fieldTypeLabel': 'نوع الحقل',
      'fieldRequiredLabel': 'إلزامي',
      'fieldReadOnlyLabel': 'للقراءة فقط',
      'customFieldOptions': 'الخيارات',
      'addOption': 'إضافة خيار',
      'optionValueLabel': 'القيمة المخزنة',
      'optionLabelLabel': 'النص المعروض',
      'createField': 'إنشاء الحقل',
      'deactivateField': 'إلغاء تفعيل الحقل',
      'deactivateFieldConfirm':
          'إلغاء تفعيل "{name}"؟ القيم الحالية تبقى محفوظة.',
      'deactivate': 'إلغاء التفعيل',
      'fieldDeactivated': 'تم إلغاء تفعيل الحقل',
      'reactivateField': 'إعادة تفعيل الحقل',
      'reactivateFieldConfirm':
          'إعادة تفعيل "{name}"؟ سيظهر مرة أخرى في النماذج وشاشات التفاصيل.',
      'reactivate': 'إعادة التفعيل',
      'fieldActivated': 'تم تفعيل الحقل',
      'fieldActive': 'مفعّل',
      'fieldInactive': 'غير مفعّل',
      'selectOptionsRequired': 'أضف خياراً واحداً على الأقل لهذا النوع.',
      'manageCustomFields': 'إدارة المعلومات الجديده',
      'editEntityFields': 'تعديل المعلومات',
      'cfdt_text': 'نص قصير',
      'cfdt_longText': 'نص طويل',
      'cfdt_number': 'عدد صحيح',
      'cfdt_decimal': 'عدد عشري',
      'cfdt_boolean': 'نعم / لا',
      'cfdt_date': 'تاريخ',
      'cfdt_dateTime': 'تاريخ ووقت',
      'cfdt_json': 'بيانات منظمة',
      'cfdt_singleSelect': 'اختيار واحد',
      'cfdt_multiSelect': 'اختيار متعدد',
      'changesSaved': 'تم حفظ التغييرات.',
      'entityFieldsNotConfigured':
          'يجب على المسؤول تحديد السمات التي تُخزَّن لهذا الكيان (المعلومات الجديده).',
      'configureEntityAttributesTitle': 'إعداد سمات {entity}',
      'customFieldsAdminDescription':
          'معلومات النظام من نموذج الخادم تظهر في الأعلى. المعلومات الجديده التي تنشئها تظهر أدناه. اضبط التسميات والظهور والترتيب والتحقق؛ المعلومات النشطة تظهر في الإنشاء والتعديل والتفاصيل.',
      'recommendedSyncKeysHint':
          'نصيحة: المفاتيح الداخلية مثل name أو ageOfMembers أو leaderServantId (للفصل) تحدّث أيضاً عناوين القوائم عند توليدها من الاسم المعروض.',
      // Auth
      'registrationSuccessfulPleaseSignIn':
          'تم التسجيل بنجاح. يرجى تسجيل الدخول.',
      // Common
      'yes': 'نعم',
      'no': 'لا',
      'unknownName': 'غير معروف',
      'notAvailable': '—',
      'timeFormatHint': 'س:د',
      'churchBrand': 'كنيستي',
      // Errors
      'genericErrorTryAgain': 'حدث خطأ. يرجى المحاولة مرة أخرى.',
      'invalidCredentialsPleaseTryAgain':
          'بيانات الدخول غير صحيحة. يرجى المحاولة مرة أخرى.',
      'sessionExpiredPleaseSignIn':
          'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.',
      'networkErrorTryAgain':
          'خطأ في الشبكة. تحقق من الاتصال وحاول مرة أخرى.',
      'somethingWentWrongTryAgain': 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
      'serverErrorTryLater': 'خطأ في الخادم. يرجى المحاولة لاحقاً.',
      // IDs / API
      'invalidMemberId': 'كود المخدوم غير صالح.',
      'invalidMemberIdDetail':
          'كود المخدوم غير صالح. افتح هذه الشاشة من القائمة بعد أن يعيد الخادم كودات صحيحة.',
      'memberIdMissingFromApi':
          'كود المخدوم مفقود من استجابة الخادم. يجب أن يتضمن كل مخدوم حقل كود.',
      'servantIdMissingFromApi':
          'كود الخادم مفقود من استجابة الخادم. يجب أن يتضمن كل خادم حقل id.',
      // Attendance
      'noAttendanceSessionsYet': 'لا توجد جلسات حضور بعد.',
      'sessionNumber': 'جلسة رقم {id}',
      'recordsCountLabel': '{count} سجلات',
      'attendanceHistoryWithClassroom': 'سجل الحضور • {classroom}',
      'meetingServantsMembersSummary':
          'الخدام: {servants} • الأعضاء: {members}',
      // Routing / screens
      'editMeeting': 'تعديل الاجتماع',
      'editChurch': 'تعديل الكنيسة',
      'classroomDetails': 'تفاصيل المجموعه',
      'customFieldValues': 'قيم المعلومات الجديده',
      'entityChurch': 'الكنيسة',
      // Custom fields extras
      'additionalFields': 'معلومات إضافية',
      'additionalFieldsSaved': 'تم حفظ المعلومات الإضافية',
      'saveAdditionalFields': 'حفظ المعلومات الإضافية',
      'entityAdditionalFieldsTitle': '{entity} — معلومات إضافية',
      'failedToLoadCustomFields': 'تعذر تحميل المعلومات الجديده:',
      'isoDateTimeHint': 'تاريخ ووقت بصيغة ISO',
      'jsonExampleHint': '{"key": "value"}',
      // Admin
      'rejectUserConfirm': 'سيتم رفض {name}.',
      // Validation templates
      'fieldIsRequired': '{name} مطلوب',
      'fieldFormatInvalid': '{name} لا يطابق الصيغة المطلوبة',
      'fieldMustBeWholeNumber': '{name} يجب أن يكون عدداً صحيحاً',
      'fieldMustBeNumber': '{name} يجب أن يكون رقماً',
      'fieldMustBeBoolean': '{name} يجب أن يكون صحيحاً أو خاطئاً',
      'fieldMustBeValidDate': '{name} يجب أن يكون تاريخاً صالحاً',
      'fieldMustBeValidDateTime': '{name} يجب أن يكون تاريخاً/وقتاً صالحاً',
      'fieldMustBeValidJson': '{name} يجب أن يكون JSON صالحاً',
      'selectValidOptionFor': 'اختر خياراً صالحاً لـ {name}',
      'fieldRequiresAtLeastOneOption': '{name} يتطلب خياراً واحداً على الأقل',
      'invalidSelectionFor': 'اختيار غير صالح لـ {name}',
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
