using Church.BLL.Exceptions;
using Church.DAL.Repository.Interfaces;
using Church.Domain;

namespace Church.BLL.Services.UnifiedForms
{
    /// <summary>
    /// Loads built-in Member column values for unified form-data (including photo URL).
    /// </summary>
    public static class MemberFormBuiltInValuesLoader
    {
        public static async Task<IReadOnlyDictionary<string, string?>> LoadAsync(
            IMemberRepository memberRepository,
            int id)
        {
            var member = await memberRepository.GetByIdForFormAsync(id)
                ?? throw new NotFoundException($"Member with id {id} not found.");

            return new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase)
            {
                ["name1"] = member.Name1,
                ["name2"] = member.Name2,
                ["name3"] = member.Name3,
                ["gender"] = member.Gender,
                ["address"] = member.Address,
                ["dateOfBirth"] = FormatDate(member.DateOfBirth),
                ["joiningDate"] = FormatDate(member.JoiningDate),
                ["lastAttendanceDate"] = FormatDate(member.LastAttendanceDate),
                ["spiritualDateOfBirth"] = member.SpiritualDateOfBirth.HasValue
                    ? FormatDate(member.SpiritualDateOfBirth.Value)
                    : null,
                ["isDiscipline"] = member.IsDiscipline.ToString().ToLowerInvariant(),
                ["haveBrothers"] = member.HaveBrothers?.ToString().ToLowerInvariant(),
                ["imageUrl"] = ResolveImageUrl(member),
            };
        }

        private static string? ResolveImageUrl(Member member)
        {
            if (!string.IsNullOrWhiteSpace(member.ImageUrl))
                return member.ImageUrl.Trim();

            if (!string.IsNullOrWhiteSpace(member.ImageFileName))
                return $"/images/{member.ImageFileName.Trim()}";

            return null;
        }

        private static string? FormatDate(DateOnly date)
        {
            if (date == default)
                return null;

            return date.ToString("yyyy-MM-dd");
        }
    }
}
