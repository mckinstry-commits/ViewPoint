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
using System.Threading;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.DropFolderWatcher
{
    internal class DropFolderFileSystemWatcher : FileSystemWatcher
    {
        private static ILog logger;

        /// <summary>
        /// Constructor
        /// </summary>
        public DropFolderFileSystemWatcher(ILog log) : base()
        {
            try
            {
                base.Path = CommonSettings.RlbDownloadFileDrop;
                base.Filter = "*.*";
                base.NotifyFilter = NotifyFilters.FileName;
                base.Created += new FileSystemEventHandler(OnCreated);
                base.EnableRaisingEvents = true;
                Settings settings = new Settings();
                logger = log;
                DropFolderWatcherDb.AddDropFolderWatcher("DropFolderFileSystemWatcher Initialize.", true, null);
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                DropFolderWatcherDb.AddDropFolderWatcher("DropFolderFileSystemWatcher Initialize.", false,
                        string.Format("DropFolderFileSystemWatcher Initialize Error: '{0}'.", ex.GetBaseException().Message));
            }
        }
        // Hide other constructors
        private DropFolderFileSystemWatcher() { }
        private DropFolderFileSystemWatcher(string path) : base(path) { }
        private DropFolderFileSystemWatcher(string path, string filter) : base(path, filter) { }

        /// <summary>
        /// File watcher file create event.  Starts AP upload application for AP files.  Starts AR 
        /// upload application for AR files.  Moves any other files to junk folder.
        /// </summary>
        static void OnCreated(object sender, FileSystemEventArgs e)
        {
            try
            {
                if (string.IsNullOrEmpty(e.Name))
                {
                    goto MoveToJunkFolder;
                }

                if (System.IO.Path.GetExtension(e.Name).ToLower() != ".zip")
                {
                    goto MoveToJunkFolder;
                }

                if (e.Name.StartsWith(APSettings.APFilePrefix))
                {
                    // Start AP Process
                    bool? started = StartExecutableProcess(Settings.APApplicationPath, e.FullPath);
                    logger.InfoFormat("Process started for AP file '{0}'.  Success: {1}.", e.Name, started.Value == true);
                    DropFolderWatcherDb.AddDropFolderWatcher("Starting AP upload process.", started.Value == true, null);
                    if (started.Value == false)
                    {
                        goto MoveToJunkFolder;
                    }
                    return;
                }

                if (e.Name.StartsWith(ARSettings.ARFilePrefix))
                {
                    // Start AR Process
                    bool? started = StartExecutableProcess(Settings.ARApplicationPath, e.FullPath);
                    logger.InfoFormat("Process started for AR file '{0}'.  Success: {1}.", e.Name, started.Value == true);
                    DropFolderWatcherDb.AddDropFolderWatcher("Starting AR upload process.", started.Value == true, null);
                    if (started.Value == false)
                    {
                        goto MoveToJunkFolder;
                    }
                    return;
                }

            MoveToJunkFolder:

                List<Task<bool>> tasks = new List<Task<bool>>();
                tasks.Add(MoveFileTask(e.FullPath));

                try
                {
                    Task.WaitAll(tasks.ToArray());
                }
                catch { }

                // Log each file move
                foreach (var task in tasks)
                {
                    string message = string.Format("Move '{0}' to junk folder.", e.Name);
                    string extendedMessage = string.Format("File '{0}' moved to junk folder '{1}'.  Success: {2}.", e.Name, CommonSettings.RlbDownloadJunkFolder, task.Result);
                    logger.Info(extendedMessage);
                    DropFolderWatcherDb.AddDropFolderWatcher(message, task.Result, message.Length > 200 ? extendedMessage : null);
                }
                tasks.Clear();
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                DropFolderWatcherDb.AddDropFolderWatcher("DropFolderFileSystemWatcher Created Event.", false,
                        string.Format("DropFolderFileSystemWatcher Error: '{0}'. File: '{1}'.", ex.GetBaseException().Message, e.Name));
            }
        }

        /// <summary>
        /// Task to move files to junk folder
        /// </summary>
        private static Task<bool> MoveFileTask(string sourceFilePath)
        {
            return Task.Run(() =>
            {
                Thread.Sleep(1000);
                return ImportFileHelper.MoveFileToProcessJunkFolder(sourceFilePath);
            });
        }

        
        /// <summary>
        /// Starts specified application with specified command arguments.  Does not wait for results.
        /// </summary>
        private static bool? StartExecutableProcess(string applicationPath, string arguments)
        {
            string processName = System.IO.Path.GetFileNameWithoutExtension(applicationPath);

            try
            {
                // Check if process is already running
                bool alreadyRunning = Process.GetProcesses().Any(p => p.ProcessName == processName);
                if (alreadyRunning)
                {
                    return null;
                }

                ProcessStartInfo startInfo = new ProcessStartInfo()
                {
                    Arguments = arguments,
                    FileName = applicationPath,
                    WindowStyle = ProcessWindowStyle.Hidden,
                    CreateNoWindow = true
                };

                DateTime startTime = DateTime.MinValue;

                using (Process proc = Process.Start(startInfo))
                {
                    startTime = proc.StartTime;
                }
                return startTime > DateTime.MinValue;
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                DropFolderWatcherDb.AddDropFolderWatcher(string.Format("Process start: {0}.", processName), false,
                        string.Format("Process Start Error.  Process '{0}'. Error: '{1}'.", processName, ex.GetBaseException().Message));
                return false;
            }
        }
    }
}
