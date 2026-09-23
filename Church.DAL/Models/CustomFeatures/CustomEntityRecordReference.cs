using Church.Domain;

namespace Church.DAL.Models.CustomFeatures
{
    public class CustomEntityRecordReference
    {
        public int Id { get; set; }
        public int RecordId { get; set; }
        public CustomEntityRecord? Record { get; set; }

        public int FieldId { get; set; }
        public CustomEntityField? Field { get; set; }

        public CustomEntityReferenceTargetKind TargetKind { get; set; }

        public int? TargetRecordId { get; set; }
        public CustomEntityRecord? TargetRecord { get; set; }

        public int? TargetMemberId { get; set; }
        public Member? TargetMember { get; set; }

        public int? TargetServantId { get; set; }
        public Servant? TargetServant { get; set; }
    }
}
