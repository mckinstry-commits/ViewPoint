using System;
using System.IO;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.DropFolderWatcher
{
    /// <summary>
    /// Application settings class
    /// </summary>
    internal class Settings
    {
        /// <summary>
        /// Initialize and test settings in constructor
        /// </summary>
        internal Settings()
        {
            apApplicationPath = ConfigurationHelper.GetAppSettingsValue("APApplicationPath");
            arApplicationPath = ConfigurationHelper.GetAppSettingsValue("ARApplicationPath");
        }

        private static string apApplicationPath;
        public static string APApplicationPath
        {
            get
            {
                return apApplicationPath;
            }
        }

        private static string arApplicationPath;
        public static string ARApplicationPath
        {
            get
            {
                return arApplicationPath;
            }
        }      
    }
}
