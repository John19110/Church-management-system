using SunDaySchools.BLL.DTOS.ChurchDtos;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IChurchManager
    {
        Task<ChurchReadDTO> GetByIdAsync(int id);
        Task UpdateAsync(int id, ChurchUpdateDTO dto, bool generateDefaults = false);
    }
}

