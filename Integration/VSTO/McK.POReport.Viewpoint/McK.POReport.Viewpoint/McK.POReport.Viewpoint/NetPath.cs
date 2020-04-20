using System.Threading.Tasks;
using System.IO;

namespace McK.POReport.Viewpoint
{
    internal static class NetPath
    {
        /// <summary>
        /// Checks to see if directory exists on the network without hanging. Timeout specified.
        /// </summary>
        /// <param name="fullUriPath"></param>
        /// <returns></returns>
        /// <remarks>executes on separate thread to avoid bottlenecks (server offline, rights or DNS issues, etc.)</remarks>
        public static bool PathExists(string fullUriPath)
        {
            var task = new Task<bool>(() =>
            {
                string dirName = Path.GetDirectoryName(fullUriPath);

                if (dirName != null)
                {
                    return new DirectoryInfo(Path.GetDirectoryName(fullUriPath)).Exists;
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
    }
}
