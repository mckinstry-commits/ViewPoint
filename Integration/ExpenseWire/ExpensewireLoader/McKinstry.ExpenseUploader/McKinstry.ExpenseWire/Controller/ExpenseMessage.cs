using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;



namespace McKinstry.ExpenseWire.Controller
{
    public class ExpenseMessage:ILog,IDisposable
    {
        FileStream fs;
        public ExpenseMessage()
        {
            if (fs == null)
                fs = File.Open("Log.txt", FileMode.OpenOrCreate, FileAccess.ReadWrite) ;
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
