using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IMemberRepository
    {
        IQueryable<Member> GetAll();
        
        Member GetById(int id);
        void Add(Member member);
        void Update(Member member);
        void Delete(int id);
        IQueryable<Member> GetSpecificClassroom(int ClassroomId);

    }
}
