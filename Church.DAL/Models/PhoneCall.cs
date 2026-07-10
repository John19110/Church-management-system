using Church.DAL.Models;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.DAL.Models
{
    public class PhoneCall
    {
        public int Id { get; set; }

        public DateOnly? DateOFthecall;
        public Servant? Servant { get; set; } 
        public string? Notes { get; set; }
        public int MemberContactId { get; set; }
        public MemberContact MemberContact { get; set; } = default!;
    }
}
