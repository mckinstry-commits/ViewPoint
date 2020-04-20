using System;
using System.IO;
using WinSCP;
using System.Linq;
using System.Collections.Generic;

namespace McKinstry.ViewpointImport.Common
{
    internal class SftpHelper
    {
        private static SessionOptions sessionOptions;
        private static string lastFileName;

        private SftpHelper() { }
        public SftpHelper(string hostName, string userName, string password, string hostkeyFingerprint)
        {
            sessionOptions = new SessionOptions
            {
                Protocol = Protocol.Sftp,
                HostName = hostName,
                UserName = userName,
                Password = password,
                SshHostKeyFingerprint = hostkeyFingerprint
            };
        }

        public bool FileExists(string fileName, string remotePath, out SftpFile fileInfo)
        {
            bool fileExists = false;
            fileInfo = new SftpFile();
            using (Session session = new Session())
            {
                string path = Path.Combine(remotePath, fileName);
                session.Open(sessionOptions);
                fileExists = session.FileExists(path);
                if (fileExists)
                {
                    RemoteFileInfo info = session.GetFileInfo(path);
                    fileInfo = new SftpFile()
                    {
                        FileName = Path.GetFileName(info.Name),
                        Length = info.Length,
                        LastWriteTime = info.LastWriteTime
                    };
                }
            }
            return fileExists;
        }

        public List<SftpFile> GetLatestFiles(int fileCount, string remotePath)
        {
            List<SftpFile> list;
            using (Session session = new Session())
            {
                session.Open(sessionOptions);

                RemoteDirectoryInfo directoryInfo = session.ListDirectory(remotePath);
                list = directoryInfo.Files
                    .Where(f => f.IsDirectory == false)
                    .OrderByDescending(f => f.LastWriteTime)
                    .Take(fileCount)
                    .Select(f =>
                        new SftpFile()
                        {
                            FileName = f.Name,
                            Length = f.Length,
                            LastWriteTime = f.LastWriteTime
                        })
                    .ToList();
            }
            return list;
        }

        public bool GetLatestFiles(int fileCount, string remotePath, string localPath)
        {
            List<bool> allSuccessful = new List<bool>();
            using (Session session = new Session())
            {
                session.FileTransferProgress += SessionFileTransferProgress;
                session.Open(sessionOptions);

                RemoteDirectoryInfo directoryInfo = session.ListDirectory(remotePath);
                RemoteFileInfo[] files = directoryInfo.Files
                    .Where(f => f.IsDirectory == false)
                    .OrderByDescending(f => f.LastWriteTime)
                    .Take(fileCount)
                    .ToArray();

                foreach (var file in files)
                {
                    TransferOperationResult result = session.GetFiles(Path.Combine(remotePath, file.Name), Path.Combine(localPath, file.Name));
                    result.Check();
                    allSuccessful.Add(result.IsSuccess);
                }
            }
            return allSuccessful.Contains(false);
        }

        public bool GetFile(string fileName, string remotePath, string localPath)
        {
            bool success = false;
            using (Session session = new Session())
            {
                session.FileTransferProgress += SessionFileTransferProgress;
                session.Open(sessionOptions);
                TransferOperationResult result = session.GetFiles(Path.Combine(remotePath, fileName), Path.Combine(localPath, fileName));
                result.Check();
                success = result.IsSuccess;
            }
            return success;
        }

        public bool UploadFile(string localPath, string remotePath)
        {
            bool success = false;
            using (Session session = new Session())
            {
                session.FileTransferProgress += SessionFileTransferProgress;
                session.Open(sessionOptions);
                TransferOperationResult result = session.PutFiles(localPath, remotePath);
                result.Check();
                success = result.IsSuccess;
            }
            return success;
        }

        public bool RemoveFile(string remotePath)
        {
            bool success = false;
            using (Session session = new Session())
            {
                session.Open(sessionOptions);
                RemovalOperationResult result = session.RemoveFiles(remotePath);
                result.Check();
                success = result.IsSuccess;
            }
            return success;
        }

        private static void SessionFileTransferProgress(object sender, FileTransferProgressEventArgs e)
        {
            if ((lastFileName != null) && (lastFileName != e.FileName))
            {
                Console.WriteLine();
            }

            Console.Write("\rFile Transfer: {0} ({1:P0})", e.FileName, e.FileProgress);

            lastFileName = e.FileName;
        }

    }
}
