import '../l10n/app_localizations.dart';
import '../../features/unified_form/models/unified_form_models.dart';

/// Maps backend property keys (JSON / DB column names) to user-facing labels.
/// Backend responses are unchanged; the UI must call these helpers instead of
/// showing raw keys or English template [displayName] values.
String? systemFieldLabel(
  AppLocalizations l10n,
  String entityName,
  String fieldKey,
) {
  switch (entityName) {
    case UnifiedEntityNames.classroom:
      switch (fieldKey) {
        case 'name':
          return l10n.classroomNameLabel;
        case 'ageOfMembers':
          return l10n.ageOfMembersLabel;
        case 'numberOfDisplineMembers':
          return l10n.numberOfDisciplineMembersLabel;
        case 'totalMembersCount':
          return l10n.totalMembersCountLabel;
        case 'leaderServantId':
          return l10n.leaderServantOptional;
        case 'meetingId':
          return l10n.meetingId;
      }
      break;
    case UnifiedEntityNames.meeting:
      switch (fieldKey) {
        case 'name':
          return l10n.meetingNameLabel;
        case 'dayOfWeek':
          return l10n.meetingDayOfWeek;
        case 'weeklyAppointment':
          return l10n.weeklyAppointmentLabel;
        case 'leaderServantId':
          return l10n.leaderServantOptional;
      }
      break;
    case UnifiedEntityNames.member:
      switch (fieldKey) {
        case 'name1':
          return l10n.firstName;
        case 'name2':
          return l10n.middleName;
        case 'name3':
          return l10n.lastName;
        case 'gender':
          return l10n.gender;
        case 'address':
          return l10n.address;
        case 'dateOfBirth':
          return l10n.birthDate;
        case 'joiningDate':
          return l10n.joiningDate;
        case 'spiritualDateOfBirth':
          return l10n.spiritualDateOfBirth;
        case 'lastAttendanceDate':
          return l10n.lastAttendanceDate;
        case 'isDiscipline':
          return l10n.discipline;
        case 'totalNumberOfDaysAttended':
          return l10n.totalDaysAttended;
        case 'haveBrothers':
          return l10n.haveBrothersInProgram;
        case 'brothersNames':
          return l10n.brothersNamesSection;
        case 'notes':
          return l10n.memberNotesSection;
        case 'phoneNumbers':
          return l10n.phoneNumbers;
        case 'classroomId':
          return l10n.classroomId;
        case 'imageUrl':
          return l10n.photoLabel;
      }
      break;
    case UnifiedEntityNames.servant:
      switch (fieldKey) {
        case 'name':
          return l10n.name;
        case 'phoneNumber':
          return l10n.phoneNumber;
        case 'birthDate':
          return l10n.birthDate;
        case 'joiningDate':
          return l10n.joiningDate;
        case 'classroomId':
          return l10n.selectClassroom;
        case 'imageUrl':
          return l10n.photoLabel;
      }
      break;
    case UnifiedEntityNames.church:
      switch (fieldKey) {
        case 'name':
          return l10n.churchName;
        case 'pastorId':
          return l10n.selectServant;
      }
      break;
  }
  return null;
}

String? systemFieldPlaceholder(
  AppLocalizations l10n,
  String entityName,
  String fieldKey,
) {
  switch (entityName) {
    case UnifiedEntityNames.classroom:
      if (fieldKey == 'name') return l10n.enterClassroomNameHint;
      break;
    case UnifiedEntityNames.meeting:
      switch (fieldKey) {
        case 'name':
          return l10n.enterMeetingNameHint;
        case 'weeklyAppointment':
          return l10n.timeFormatHint;
      }
      break;
    case UnifiedEntityNames.member:
      if (fieldKey == 'classroomId') return l10n.selectClassroom;
      break;
    case UnifiedEntityNames.servant:
      switch (fieldKey) {
        case 'classroomId':
          return l10n.selectClassroom;
        case 'phoneNumber':
          return l10n.enterPhoneNumber;
      }
      break;
    case UnifiedEntityNames.church:
      if (fieldKey == 'name') return l10n.enterChurchName;
      break;
  }
  return null;
}
