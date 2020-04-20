using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace McKinstry.ExpenseWire.Controller
{
    public interface ILog
    {
        void LogMessage(string Message);
        void Flush();
    }
}
