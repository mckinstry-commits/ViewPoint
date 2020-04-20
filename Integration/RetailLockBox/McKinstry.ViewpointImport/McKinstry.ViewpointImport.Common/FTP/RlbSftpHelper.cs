using System;
using System.Linq;
using System.Collections.Generic;

namespace McKinstry.ViewpointImport.Common
{
    public static class RlbSftpHelper
    {

        public static bool GetLatestFilesFromRemotePath(int fileCount, string remotePath, string localPath)
        {
            SftpHelper sftp = new SftpHelper(CommonSettings.RlbHostName, CommonSettings.RlbUserName, CommonSettings.RlbPassword, CommonSettings.RlbHostkeyFingerprint);
            return sftp.GetLatestFiles(fileCount, remotePath, localPath);
        }

        public static bool RemoteFileExists(string fileName, string remotePath, out SftpFile fileInfo)
        {
            SftpHelper sftp = new SftpHelper(CommonSettings.RlbHostName, CommonSettings.RlbUserName, CommonSettings.RlbPassword, CommonSettings.RlbHostkeyFingerprint);
            return sftp.FileExists(fileName, remotePath, out fileInfo);
        }

        public static bool GetFileFromRemotePath(string fileName, string remotePath, string localPath)
        {
            SftpHelper sftp = new SftpHelper(CommonSettings.RlbHostName, CommonSettings.RlbUserName, CommonSettings.RlbPassword, CommonSettings.RlbHostkeyFingerprint);
            return sftp.GetFile(fileName, remotePath, localPath);
        }

        public static bool UploadFileToRemotePath(string localPath, string remotePath)
        {
            SftpHelper sftp = new SftpHelper(CommonSettings.RlbHostName, CommonSettings.RlbUserName, CommonSettings.RlbPassword, CommonSettings.RlbHostkeyFingerprint);
            return sftp.UploadFile(localPath, remotePath);
        }

        public static bool RemoveFileFromRemotePath(string remotePath)
        {
            SftpHelper sftp = new SftpHelper(CommonSettings.RlbHostName, CommonSettings.RlbUserName, CommonSettings.RlbPassword, CommonSettings.RlbHostkeyFingerprint);
            return sftp.RemoveFile(remotePath);
        }

        public static List<SftpFile> GetLatestFileInfoFromRemotePath(int fileCount, string remotePath)
        {
            SftpHelper sftp = new SftpHelper(CommonSettings.RlbHostName, CommonSettings.RlbUserName, CommonSettings.RlbPassword, CommonSettings.RlbHostkeyFingerprint);
            return sftp.GetLatestFiles(fileCount, remotePath);
        }
    }
}
