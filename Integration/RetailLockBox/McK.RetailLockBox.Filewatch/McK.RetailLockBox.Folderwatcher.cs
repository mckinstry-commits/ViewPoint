using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;
using System.IO;

namespace McK.RetailLockBox.Folderwatch
{   // ABOUT:
    /**************************************************************************************************************
     * PURPOSE: Moves created, renamed or modified files from RLB_[AP/AR]_Download folder to RLB_DownloadFileDrop
     *          where the next folder watcher takes it to the next step in the [AP/RA]_Process folder 
     * 
     * Author:  Leo Gurdian
     * Date:    2.20.20
     * 
     * HISTORY:
     * --------
     * 2.20.20  Leo Gurdian Init
     *
     **************************************************************************************************************/
    public partial class RLB_DownloadFolderwatcher : ServiceBase
    {
        static readonly string fileSourceAP = ConfigurationManager.AppSettings["WatchFolderAPSource"];
        static readonly string fileSourceAR = ConfigurationManager.AppSettings["WatchFolderARSource"];
        static readonly string pathDest = ConfigurationManager.AppSettings["WatchFolderDestination"];
        static readonly string watchFolderLog = ConfigurationManager.AppSettings["WatchFolderLog"];

        //public void onDebug() => OnStart(null);

        public RLB_DownloadFolderwatcher()
        {
            InitializeComponent();

            try
            {
                if (!EventLog.SourceExists("MCK RLB Folderwatch"))
                {
                    EventLog.CreateEventSource("MCK RLB Folderwatch", "MCK Log");
                }

                eventLog1 = new EventLog
                {
                    Source = "MCK RLB Folderwatch",
                    Log = "MCK Log"
                };
            }
            catch (Exception ex)
            {
                WriteErrorFile(ex);
            }
        }

        protected override void OnStart(string[] args)
        {
            try
            {
                if (eventLog1.Log != "") eventLog1.WriteEntry("Starting RLB Folderwatch.");

                APFolderWatcher.Path = fileSourceAP;
                APFolderWatcher.EnableRaisingEvents = true;
                APFolderWatcher.Created += FolderWatcher1_Changed;
                APFolderWatcher.Renamed += FolderWatcher1_Changed;
                APFolderWatcher.Changed += FolderWatcher1_Changed;

                ARFolderWatcher.Path = fileSourceAR;
                ARFolderWatcher.EnableRaisingEvents = true;
                ARFolderWatcher.Created += FolderWatcher1_Changed;
                ARFolderWatcher.Renamed += FolderWatcher1_Changed;
                ARFolderWatcher.Changed += FolderWatcher1_Changed;
            }
            catch (Exception ex)
            {
                WriteErrorFile(ex);
            }
        }

        protected override void OnStop()
        {
            if (eventLog1.Log != "") eventLog1.WriteEntry("Stopping RLB Folderwatch.");
        }

        private void FolderWatcher1_Changed(object sender, System.IO.FileSystemEventArgs e)
        {
            try
            {
                eventLog1.WriteEntry("Moving " + e.Name + " to " + pathDest);
                System.Threading.Thread.Sleep(5000); // wait 5 seconds

                string pathFileNameFullDest = Path.Combine(pathDest, e.Name);
                //if (!(File.Exists(pathFileNameFullDest)))
                //{
                    MoveFile_To_DropFolder(e.Name, Path.GetDirectoryName(e.FullPath), pathDest);
                //}
            }
            catch (Exception ex)
            {
                WriteErrorFile(ex);
            }
        }


        /// </summary>
        /// The files from one location to another location
        /// </summary>  
        private bool MoveFile_To_DropFolder(string fileName, string fileFullPathSrc, string fileFullPathDest)
        {
            bool isMoved = false; 
                
            try
            {
                if (!(PathUriExists(pathDest) && PathUriExists(fileFullPathSrc)))
                {
                    eventLog1.WriteEntry("Move failed!");
                    return isMoved;
                }

                bool copied = CopyFile(fileName, fileFullPathSrc, fileFullPathDest);
                bool deleted = DeleteFile(Path.Combine(fileFullPathSrc, fileName));
                isMoved = copied && deleted;
                eventLog1.WriteEntry("Move successful!");
            }
            catch (Exception ex)
            {
                WriteErrorFile(ex);
            }
            return isMoved;
        }

        public static void EnsureDirectory(string path)
        {
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
        }

        public static bool CopyFile(string fileName, string sourceDirectory, string destDirectory)
        {
            try
            {
                EnsureDirectory(destDirectory);
                File.Copy(Path.Combine(sourceDirectory, fileName), Path.Combine(destDirectory, fileName), true);
                return true;
            }
            catch
            {
                return false;
            }
        }

        public static bool DeleteFile(string fileName)
        {
            try
            {
                if (File.Exists(fileName))
                {
                    File.Delete(fileName);
                }
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>  
        ///  Log the error to a text file.
        /// </summary>  
        /// <param name="ex"></param>  
        public static void WriteErrorFile(Exception ex)
        {
            if (PathUriExists(watchFolderLog))
            {
                StreamWriter SW;
                if (!File.Exists(Path.Combine(watchFolderLog, "DownloadFolderWatcherLog_" + DateTime.Now.ToString("yyyyMMdd") + ".txt")))
                {
                    SW = File.CreateText(Path.Combine(watchFolderLog, "DownloadFolderWatcherLog_" + DateTime.Now.ToString("yyyyMMdd") + ".txt"));
                    SW.Flush();
                    SW.Close();
                }

                using (SW = File.AppendText(Path.Combine(watchFolderLog, "DownloadFolderWatcherLog_" + DateTime.Now.ToString("yyyyMMdd") + ".txt")))
                {
                    SW.Write("\r\n");
                    SW.WriteLine(DateTime.Now.ToString("yyyy-MM-dd hh.mm.ss ") + (ex.Message == null ? "" : ex.Message.ToString()));
                    SW.WriteLine(DateTime.Now.ToString("yyyy-MM-dd hh.mm.ss ") + (ex.StackTrace == null ? "" : ex.StackTrace.ToString().Trim()));
                    SW.Flush();
                    SW.Close();
                }
            }
        }

        /// <summary>
        /// Checks to see if directory exists on the network without hanging. Timeout specified.  
        /// </summary>
        /// <remarks>Executes on separate thread to avoid bottlenecks (server offline, rights or DNS issues, etc.)</remarks>
        /// <param name="fullUriPath"></param>
        /// <returns>If it path exists or not</returns>
        public static bool PathUriExists(string fullUriPath)
        {
            var task = new Task<bool>(() =>
            {
                string pathFullUri = Path.GetDirectoryName(fullUriPath);

                if (pathFullUri != null)
                {
                    return new DirectoryInfo(pathFullUri).Exists;
                }
                else
                {
                    //path denotes a root directory or is null
                    return Path.IsPathRooted(fullUriPath);
                }
            });

            task.Start();

            return task.Wait(100) && task.Result;
        }

        //private static bool CheckFileExistance(string FullPath, string FileName)
        //{
        //    // Get the subdirectories for the specified directory
        //    bool IsFileExist = false;
        //    DirectoryInfo dir = new DirectoryInfo(FullPath);
        //    if (!dir.Exists)
        //        IsFileExist = false;
        //    else
        //    {
        //        string FileFullPath = Path.Combine(FullPath, FileName);
        //        if (File.Exists(FileFullPath))
        //            IsFileExist = true;
        //    }
        //    return IsFileExist;
        //}

    }

}
