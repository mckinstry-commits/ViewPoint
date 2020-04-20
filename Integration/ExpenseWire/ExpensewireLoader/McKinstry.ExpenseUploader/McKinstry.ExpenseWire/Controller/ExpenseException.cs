using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace McKinstry.ExpenseWire.Controller
{
    public class ExpenseException:ILog
    {

        FileStream fs;
        public ExpenseException()
        {
            if (fs == null)
                fs = File.Open("ExceptionLog.txt", FileMode.OpenOrCreate, FileAccess.ReadWrite) ;
        }
        public void LogMessage(string Message)
        {
            byte[] messageBytes = Utility.GetBytes(Message);
            fs.Write(messageBytes, 0, messageBytes.Length);
        }

        public void Flush()
        {
            fs.Flush();
        }

        public void Dispose()
        {
            fs.Dispose();
        }
    }
}
