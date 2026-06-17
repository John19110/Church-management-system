/// Stable relation values stored in [MemberContact.relation] on the backend.
abstract final class MemberPhoneRelations {
  static const member = 'Member';
  static const father = 'Father';
  static const mother = 'Mother';
  static const brother = 'Brother';
  static const sister = 'Sister';
  static const guardian = 'Guardian';
  static const other = 'Other';

  static const all = [
    member,
    father,
    mother,
    brother,
    sister,
    guardian,
    other,
  ];
}

abstract final class MemberGenderValues {
  static const male = 'Male';
  static const female = 'Female';
}
