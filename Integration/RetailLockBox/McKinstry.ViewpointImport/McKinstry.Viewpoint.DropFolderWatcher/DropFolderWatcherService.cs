using System;
using log4net;
using System.IO;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

[assembly: log4net.Config.XmlConfigurator(Watch = true)]

namespace McKinstry.Viewpoint.DropFolderWatcher
{
    public partial class DropFolderWatcherService : ServiceBase
    {
        private static DropFolderFileSystemWatcher watcher = null;
        private static readonly string serviceName = "McKinstry RLB Drop Folder File Watcher";
        private ILog log;
              
        /// <summary>
        /// Constructor
        /// </summary>
        public DropFolderWatcherService()
        {
            InitializeComponent();
            this.ServiceName = serviceName;
            log = DropFolderLoggingHelper.CreateDropFolderLogger();
            DropFolderWatcherDb.AddDropFolderWatcher("Initializing DropFolderWatcherService service.", true, null);
        }

        /// <summary>
        /// Service start event. Starts new file system watcher on drop folder
        /// </summary>
        protected override void OnStart(string[] args)
        {
            watcher = new DropFolderFileSystemWatcher(log);
            log.Info("Starting DropFolderFileSystemWatcher service.");
            DropFolderWatcherDb.AddDropFolderWatcher("Starting DropFolderWatcherService service.", true, null);
        }

        /// <summary>
        /// Service stop event. Disables and removes file system watcher.
        /// </summary>
        protected override void OnStop()
        {
            watcher.EnableRaisingEvents = false;
            bool cleared = ImportFileHelper.ClearProcessJunkFolder();
            DropFolderWatcherDb.AddDropFolderWatcher(string.Format("Clearing process junk folder: Success: {0}.", cleared), true, null);
            log.InfoFormat("Clearing process junk folder: Success: {0}.", cleared);
            watcher.Dispose();
            DropFolderWatcherDb.AddDropFolderWatcher("Stopping DropFolderWatcherService service.", true, null);
            log.Info("Stopping DropFolderWatcherService service.");
        }
     }
}
