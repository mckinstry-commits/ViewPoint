using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using log4net;

namespace McK.APImport.Common
{
    public static class LoggingHelper
    {
        public static ILog CreateLogger(Type caller, string logFilePath, string logFileName)
        {
            return CreateLogger(caller, Path.Combine(logFilePath, Path.GetFileNameWithoutExtension(logFileName)));
        }

        public static ILog CreateLogger(Type caller, string fullLogFilePath)
        {
            if (LogManager.GetCurrentLoggers().Length == 0)
            {
                string path = AppDomain.CurrentDomain.BaseDirectory.ToString();
                string configFile = string.Concat(path, "Logging.config");

                string fileName = string.Format("{0}_{1}{2}", fullLogFilePath, DateTime.Now.ToString("yyyy-MM-dd hh.mm.ss"), ".txt");
                log4net.GlobalContext.Properties["FileName"] = fileName;
                log4net.Config.XmlConfigurator.Configure(new FileInfo(configFile));
            }
            ILog logger = LogManager.GetLogger(caller);
            return logger;
        }
    }
}
