using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity.Core.Objects;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.AttachmentUtility
{
    internal class AttachmentUtilityDb : Db
    {
        internal static HQAT[] GetAttachments()
        {
            HQAT[] attachments;
            using (var ctx = new ViewpointEntities(ViewpointConnectionString))
            {
                attachments = ctx.HQATs
                    .ToArray<HQAT>();
            }
            return attachments;
        }

        internal static void TruncateViewpointAttachFilesTable()
        {
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                int results = ctx.Database.ExecuteSqlCommand("TRUNCATE TABLE [dbo].[ViewpointAttachFiles]");
            }
        }

        internal static void TruncateMissingAttachTable()
        {
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                int results = ctx.Database.ExecuteSqlCommand("TRUNCATE TABLE [dbo].[MissingAttachments]");
            }
        }

        internal static int AddAttachFile(ViewpointAttachFile file)
        {
            ViewpointAttachFile newFile = new ViewpointAttachFile();
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                newFile = ctx.ViewpointAttachFiles.Add(file);
                ctx.SaveChanges();
            }
            return newFile.ViewpointAttachFilesID;
        }

        internal static int AddMissingAttachment(MissingAttachment attachment)
        {
            MissingAttachment newAttach = new MissingAttachment();
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                newAttach = ctx.MissingAttachments.Add(attachment);
                ctx.SaveChanges();
            }
            return newAttach.MissingAttachmentsID;
        }

        internal static DateTime? GetLatestAttachmentFileDate(string environment)
        {
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                var attach = ctx.ViewpointAttachFiles
                    .OrderByDescending(a => a.FileCreationTime)
                    .Where(a => a.Environment == environment)
                    .Select(a => a).FirstOrDefault<ViewpointAttachFile>();

                return attach == default(ViewpointAttachFile) ? null : attach.FileCreationTime;
            }   
        }
    }
}
