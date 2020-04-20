using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace McKinstry.ExpenseWire.Controller
{
    public class LogFactory
    {
        ILog _iLog;
        public LogFactory(ILog iLog)
        {
            _iLog = iLog;
        }

        public void LogMe(string Message)
        {
            _iLog.LogMessage(Message);
        }
    }
}
