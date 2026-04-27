using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using SunDaySchools.BLL.Configuration;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class MemberManager : IMemberManager
    {
        private readonly IMemberRepository _memberRepository;
        private readonly IClassroomRepository _classroomRepository;
        private readonly IServantRepository _servantRepository;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMapper _mapper;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly ServantProfileOptions _servantProfileOptions;


        public MemberManager(IMemberRepository memberRepository, IMapper mapper,
            IHttpContextAccessor httpContextAccessor, UserManager<ApplicationUser> userManager,
            IClassroomRepository classroomRepository, IServantRepository servantRepository,
            IOptions<ServantProfileOptions> servantProfileOptions)
        {
            _memberRepository = memberRepository;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;
            _userManager = userManager;
            _classroomRepository = classroomRepository;
            _servantRepository = servantRepository;
            _servantProfileOptions = servantProfileOptions.Value;

        }

        public async Task<IEnumerable<MemberReadDTO>> GetAllAsync()
        {
            var members = await _memberRepository.GetAllAsync();
            return _mapper.Map<IEnumerable<MemberReadDTO>>(members);
        }

        public async Task<MemberReadDTO?> GetByIdAsync(int id)
        {
            var member = await _memberRepository.GetByIdAsync(id);
            if (member == null)
                return null;

            return _mapper.Map<MemberReadDTO>(member);
        }

        public async Task<IEnumerable<MemberReadDTO>> GetSpecificClassroomAsync(int classroomId)
        {
            var exists = await _classroomRepository.ExistsAsync(classroomId);
            if (!exists)
                throw new NotFoundException($"Classroom with id {classroomId} was not found.");

            var members = await _memberRepository.GetSpecificClassroomAsync(classroomId);
            return _mapper.Map<IEnumerable<MemberReadDTO>>(members);
        }

        public async Task AddAsync(MemberAddDTO memberDto, int classroomId)
        {
            var user = _httpContextAccessor.HttpContext?.User;
            if (user == null)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var userIdClaim = _userManager.GetUserId(user);
            if (string.IsNullOrEmpty(userIdClaim))
                throw new UnauthorizedAccessException(
                    "User identifier could not be resolved from the token.");

            var appUser = await _userManager.FindByIdAsync(userIdClaim);
            if (appUser == null)
                throw new NotFoundException("User not found.");

            var servant = await _servantRepository.EnsureServantProfileAsync(
                appUser,
                _servantProfileOptions.AutoCreateMissingProfile);
            if (servant == null)
            {
                var detail = _servantProfileOptions.AutoCreateMissingProfile
                    ? ServantProfileMessages.MissingAfterAutoCreateAttempt()
                    : ServantProfileMessages.MissingProfileManual();
                throw new ServantProfileMissingException(detail);
            }

            var isAssigned = await _classroomRepository.IsServantAssignedAsync(servant.Id, classroomId);

            if (!isAssigned && user.IsInRole("Servant"))
                throw new UnauthorizedAccessException("This class is not assigned to you.");


            foreach (var claim in _httpContextAccessor.HttpContext.User.Claims)
            {
                Console.WriteLine($"{claim.Type} = {claim.Value}");
            }

            string? fileName = null;

            if (memberDto.Image != null)
            {
                fileName = Guid.NewGuid().ToString() + Path.GetExtension(memberDto.Image.FileName);

                var folderPath = Path.Combine("wwwroot", "images");
                Directory.CreateDirectory(folderPath);

                var filePath = Path.Combine(folderPath, fileName);

                using var stream = new FileStream(filePath, FileMode.Create);
                await memberDto.Image.CopyToAsync(stream);
            }

            var model = _mapper.Map<Member>(memberDto);
            model.ImageFileName = fileName;
            model.ImageUrl = fileName != null ? $"/images/{fileName}" : null;
            model.ClassroomId = classroomId;

            await _memberRepository.AddAsync(model);
            await _memberRepository.SaveAsync();
        }
        public async Task<List<SelectOptionDTO>> GetMembersForSelection()
        {
            var members = await _memberRepository.GetMembersForSelection();

            return members.Select(m => new SelectOptionDTO
            {
                Id = m.Id,
                Name = m.Item2
            }).ToList();
        }
        public async Task UpdateAsync(MemberUpdateDTO memberUpdateDto)
        {
            var existing = await _memberRepository.GetByIdAsync(memberUpdateDto.Id);

            if (existing == null)
                throw new NotFoundException($"Member with id {memberUpdateDto.Id} not found.");

            // Partial update: only apply provided fields.
            if (memberUpdateDto.Name1 != null) existing.Name1 = memberUpdateDto.Name1;
            if (memberUpdateDto.Name2 != null) existing.Name2 = memberUpdateDto.Name2;
            if (memberUpdateDto.Name3 != null) existing.Name3 = memberUpdateDto.Name3;
            if (memberUpdateDto.Gender != null) existing.Gender = memberUpdateDto.Gender;
            if (memberUpdateDto.Address != null) existing.Address = memberUpdateDto.Address;

            if (memberUpdateDto.DateOfBirth.HasValue) existing.DateOfBirth = memberUpdateDto.DateOfBirth.Value;
            if (memberUpdateDto.JoiningDate.HasValue) existing.JoiningDate = memberUpdateDto.JoiningDate.Value;
            if (memberUpdateDto.LastAttendanceDate.HasValue) existing.LastAttendanceDate = memberUpdateDto.LastAttendanceDate.Value;
            if (memberUpdateDto.SpiritualDateOfBirth.HasValue) existing.SpiritualDateOfBirth = memberUpdateDto.SpiritualDateOfBirth;

            if (memberUpdateDto.IsDiscipline.HasValue) existing.IsDiscipline = memberUpdateDto.IsDiscipline.Value;
            if (memberUpdateDto.TotalNumberOfDaysAttended.HasValue) existing.TotalNumberOfDaysAttended = memberUpdateDto.TotalNumberOfDaysAttended.Value;

            if (memberUpdateDto.HaveBrothers.HasValue) existing.HaveBrothers = memberUpdateDto.HaveBrothers;
            if (memberUpdateDto.BrothersNames != null) existing.BrothersNames = memberUpdateDto.BrothersNames;
            if (memberUpdateDto.Notes != null) existing.Notes = memberUpdateDto.Notes;
            if (memberUpdateDto.PhoneNumbers != null)
                existing.PhoneNumbers = _mapper.Map<List<MemberContact>>(memberUpdateDto.PhoneNumbers);

            if (memberUpdateDto.ClassroomId.HasValue) existing.ClassroomId = memberUpdateDto.ClassroomId;
            await _memberRepository.UpdateAsync(existing);
        }

        public async Task UpdateImageAsync(int id, string imageFileName, string imageUrl)
        {
            var existing = await _memberRepository.GetByIdAsync(id);
            if (existing == null)
                throw new NotFoundException($"Member with id {id} not found.");

            existing.ImageFileName = imageFileName;
            existing.ImageUrl = imageUrl;

            await _memberRepository.UpdateAsync(existing);
        }

        public async Task DeleteAsync(int id)
        {
            var member = await _memberRepository.GetByIdAsync(id);

            if (member == null)
                throw new NotFoundException($"Member with id {id} not found.");

            await _memberRepository.DeleteAsync(id);
        }
    }
}
