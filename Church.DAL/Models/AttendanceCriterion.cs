using System;
using System.Collections.Generic;

namespace Church.DAL.Models
{
    /// <summary>
    /// Meeting-scoped attendance checklist item (e.g. "Has own tools", "Did homework").
    /// Soft-deleted criteria remain for historical results.
    /// </summary>
    public class AttendanceCriterion : ChurchEntity
    {
        public int Id { get; set; }

        /// <summary>Stable internal key unique per meeting (e.g. has_tools).</summary>
        public string Name { get; set; } = string.Empty;

        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }

        public AttendanceCriterionDataType DataType { get; set; } = AttendanceCriterionDataType.Boolean;

        public bool IsActive { get; set; } = true;

        /// <summary>Soft-deleted: hidden from new attendance; historical results remain.</summary>
        public bool IsDeleted { get; set; }

        public int SortOrder { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public Meeting? Meeting { get; set; }
        public ICollection<AttendanceCriterionResult> Results { get; set; } = new List<AttendanceCriterionResult>();
    }
}
