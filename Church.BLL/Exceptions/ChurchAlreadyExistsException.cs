
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

public class ChurchAlreadyExistsException:Exception
    {
    public ChurchAlreadyExistsException(string message = "Church already exists.") : base(message) { }
    }

