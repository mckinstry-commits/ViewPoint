using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.IO.Compression;

namespace McK.APImport.Common
{
    public static class ImportFileHelper
    {

        public static bool RecordImageIsMissing(string processPath, string collectedImage)
        {
            if (string.IsNullOrEmpty(collectedImage) || string.IsNullOrEmpty(processPath))
            {
                return true;
            }
            return !FileExists(Path.Combine(processPath, collectedImage));
        }

        public static void EnsureDirectory(string path)
        {
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
        }

        public static bool MoveFileToProcessJunkFolder(string fullFileName)
        {
            try
            {
                EnsureDirectory(CommonSettings.RlbDownloadJunkFolder);
                bool copied = CopyFile(fullFileName, Path.Combine(CommonSettings.RlbDownloadJunkFolder, Path.GetFileName(fullFileName)));
                bool deleted = DeleteFile(fullFileName);
                return copied && deleted;
            }
            catch
            {
                return false;
            }
        }

        public static bool ClearProcessJunkFolder()
        {
            bool deleted = true;
            if (Directory.Exists(CommonSettings.RlbDownloadJunkFolder))
            {
                deleted = DeleteDirectory(CommonSettings.RlbDownloadJunkFolder);
            }
            EnsureDirectory(CommonSettings.RlbDownloadJunkFolder);
            return Directory.Exists(CommonSettings.RlbDownloadJunkFolder) && deleted;
        }

        public static bool CopyFile(string sourceDirectory, string destDirectory)
        {
            try
            {
                File.Copy(sourceDirectory, destDirectory, true);
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public static bool CopyImageFile(string sourceDirectory, string destDirectory)
        {
            try
            {
                EnsureDirectory(Path.GetDirectoryName(destDirectory));
                File.Copy(sourceDirectory, destDirectory, true);
                return true;
            }
            catch (Exception)
            {
                return false;
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

        public static bool CopyDirectory(string sourceDirectory, string destDirectory)
        {
            try
            {
                string newFolder = Path.GetFileName(sourceDirectory);
                string newDirectory = Path.Combine(destDirectory, newFolder);

                EnsureDirectory(newDirectory);

                string[] files = Directory.GetFiles(sourceDirectory);

                foreach (var file in files)
                {
                    string name = Path.GetFileName(file);
                    File.Copy(file, Path.Combine(newDirectory, name));
                }
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

        public static bool DeleteDirectory(string directoryName)
        {
            try
            {
                Directory.Delete(directoryName, true);
                return true;
            }
            catch
            {
                return false;
            }
        }

        //public static bool ExtractZip(string zipPath, string extractPath)
        //{
        //    try
        //    {
        //        ZipFile.ExtractToDirectory(zipPath, extractPath);
        //        return true;
        //    }
        //    catch
        //    {
        //        return false;
        //    }
        //}

        //public static bool CreateZipFromDirectory(string sourceDirectoryName, string destinationArchiveFileName)
        //{
        //    try
        //    {
        //        ZipFile.CreateFromDirectory(sourceDirectoryName, destinationArchiveFileName);
        //        return true;
        //    }
        //    catch
        //    {
        //        return false;
        //    }
        //}

        public static bool FileExists(string path)
        {
            try
            {
                return File.Exists(path);
            }
            catch
            {
                return false;
            }
        }

        public static List<string> FetchFiles(string path, string extension)
        {
            var files = from f in Directory.EnumerateFiles(path)
                        where f.ToLower().EndsWith(extension.ToLower())
                        select f;
            return files.ToList<string>();
        }
    }
}
