using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

namespace McK.RetailLockBox.Folderwatch
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        static void Main()
        {
            ServiceBase[] ServicesToRun;
            ServicesToRun = new ServiceBase[]
            {
                new RLB_DownloadFolderwatcher()
            };
            ServiceBase.Run(ServicesToRun);
            //#if DEBUG
            //            RetailLockBox_Folderwatch retailLockBox_Folderwatch = new RetailLockBox_Folderwatch();
            //            retailLockBox_Folderwatch.onDebug();
            //#else
            //            ServiceBase[] ServicesToRun;
            //            ServicesToRun = new ServiceBase[]
            //            {
            //                new RetailLockBox_Folderwatch()
            //            };
            //            ServiceBase.Run(ServicesToRun);
            //#endif

        }
    }
}
