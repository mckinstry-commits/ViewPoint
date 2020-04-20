using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.DropFolderWatcher
{
    public class DropFolderWatcherDb : Db
    {

        public static bool AddDropFolderWatcher(string activity, bool? success, string processNote)
        {
            RLBDropFolderWatcher record = new RLBDropFolderWatcher();
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                int? processNotesID = null;
                if (!string.IsNullOrEmpty(processNote))
                {
                    processNotesID = MckIntegrationDb.CreateProcessNote(processNote);
                }

                record = ctx.RLBDropFolderWatchers.Add(
                    new RLBDropFolderWatcher
                    {
                        Activity = TrimString(activity, 200),
                        Success = success,
                        RLBProcessNotesID = processNotesID,
                        Created = DateTime.Now
                    });
                ctx.SaveChanges();
            }
            return record.DropFolderWatcherID > 0;
        }
    }
}
