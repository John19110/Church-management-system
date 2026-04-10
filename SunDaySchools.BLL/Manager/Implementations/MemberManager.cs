using AutoMapper;
using Microsoft.AspNetCore.Http;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Interfaces;
using Microsoft.AspNetCore.Identity;
using SunDaySchools.Models;
using System.Security.Claims;
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


        public MemberManager(IMemberRepository memberRepository, IMapper mapper,
            IHttpContextAccessor httpContextAccessor, UserManager<ApplicationUser> userManager,
            IClassroomRepository classroomRepository, IServantRepository servantRepository)
        {
            _memberRepository = memberRepository;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;
            _userManager = userManager;
            _classroomRepository = classroomRepository;
            _servantRepository = servantRepository;

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

            var servant = await _servantRepository.GetByApplicationUserIdAsync(userIdClaim);
            if (servant == null)
                throw new UnauthorizedAccessException("Current user is not linked to a servant profile.");

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
            var members = await _memberRepository.GetAllAsync();

            return members.Select(m => new SelectOptionDTO
            {
                Id = m.Id,
                Name = m.FullName
            }).ToList();
        }
        public async Task UpdateAsync(MemberUpdateDTO memberUpdateDto)
        {
            var existing = await _memberRepository.GetByIdAsync(memberUpdateDto.Id);

            if (existing == null)
                throw new NotFoundException($"Member with id {memberUpdateDto.Id} not found.");

            _mapper.Map(memberUpdateDto, existing);
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
