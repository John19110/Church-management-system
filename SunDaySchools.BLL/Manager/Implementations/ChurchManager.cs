using SunDaySchools.BLL.DTOS.ChurchDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Interfaces;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class ChurchManager : IChurchManager
    {
        private readonly IChurchRepository _churchRepository;
        private readonly IServantRepository _servantRepository;

        public ChurchManager(IChurchRepository churchRepository, IServantRepository servantRepository)
        {
            _churchRepository = churchRepository;
            _servantRepository = servantRepository;
        }

        public async Task<ChurchReadDTO> GetByIdAsync(int id)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ChurchId"] = new[] { "Church id must be a positive integer." }
                });

            var church = await _churchRepository.GetByIdAsync(id);
            if (church == null)
                throw new NotFoundException($"Church with id {id} not found.");

            string? pastorName = null;
            if (church.PastorId.HasValue)
            {
                var pastor = await _servantRepository.GetByIdAsync(church.PastorId.Value);
                pastorName = pastor?.Name;
            }

            return new ChurchReadDTO
            {
                Id = church.Id,
                Name = church.Name,
                PastorId = church.PastorId,
                PastorName = pastorName,
            };
        }

        public async Task UpdateAsync(int id, ChurchUpdateDTO dto, bool generateDefaults = false)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ChurchId"] = new[] { "Church id must be a positive integer." }
                });

            if (dto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Church"] = new[] { "Request body cannot be empty." }
                });

            if (dto.Id != 0 && dto.Id != id)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Id"] = new[] { "The ID in the URL does not match the ID in the request body." }
                });

            var church = await _churchRepository.GetByIdAsync(id);
            if (church == null)
                throw new NotFoundException($"Church with id {id} not found.");

            if (dto.Name != null)
            {
                var trimmed = dto.Name.Trim();
                church.Name = trimmed;
            }
            else if (generateDefaults && string.IsNullOrWhiteSpace(church.Name))
            {
                church.Name = $"Church {church.Id}";
            }

            if (dto.PastorId.HasValue)
            {
                if (dto.PastorId.Value <= 0)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["PastorId"] = new[] { "Pastor id must be a positive integer." }
                    });

                // Ensure servant exists
                var pastor = await _servantRepository.GetByIdAsync(dto.PastorId.Value);
                if (pastor == null)
                    throw new NotFoundException($"Servant with id {dto.PastorId.Value} not found.");

                church.PastorId = dto.PastorId;
            }

            await _churchRepository.UpdateAsync(church);
        }
    }
}

