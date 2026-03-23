using AutoMapper;
using Microsoft.AspNetCore.Http;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class MemberManager : IMemberManager
    {
        private readonly IMemberRepository _memberRepository;
        private readonly IMapper _mapper;
        private readonly IHttpContextAccessor _httpContextAccessor;


        public MemberManager(IMemberRepository memberRepository, IMapper mapper,
            IHttpContextAccessor httpContextAccessor)
        {
            _memberRepository = memberRepository;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;
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


     
        public async Task AddAsync(MemberAddDTO memberDto,int classroomId)
        {
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