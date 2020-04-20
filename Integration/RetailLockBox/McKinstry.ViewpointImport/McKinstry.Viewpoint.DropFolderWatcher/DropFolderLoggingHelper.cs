using System;
using System.IO;
using log4net;
using log4net.Config;

namespace McKinstry.Viewpoint.DropFolderWatcher
{
    internal static class DropFolderLoggingHelper
    {
        private static ILog log;

        internal static ILog CreateDropFolderLogger()
        {
            log = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
            log4net.Config.XmlConfigurator.Configure();
            return log;
        }
    }
}