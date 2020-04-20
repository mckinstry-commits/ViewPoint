using System;
using System.IO;
using log4net;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewoint.CompanyMove
{
    internal class APCompanyMoveCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "AP Company Move Command";
            }
        }

        public string Description
        {
            get
            {
                return "Moves Viewpoint AP header records and attachments between specified companies.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Begin AP company move.");

            string logFile = Path.GetFileName(log4net.GlobalContext.Properties["FileName"].ToString());

            var itemsToMove = CompanyMoveDb.GetAPCompanyMoveItems();
            log.InfoFormat("Fetching AP records to move companies. Items found: {0}.", itemsToMove.Count());
            if (itemsToMove.Count() == 0)
            {
                goto EndProcess;
            }

            foreach (var moveItem in itemsToMove)
            {
                int companyMoveID = 0;
                try
                {
                    log.Info("----------------------------");

                    if (moveItem.AttachmentCount == 0)
                    {
                        log.Info("Cannot move company --> Header record has no attachment.");
                        log.InfoFormat("--Header details--> APCo:{0}, UIMth:{1}, UISeq:{2}, APRef:'{3}', InvTotal:{4}.",
                            moveItem.APCo, moveItem.UIMth.ToString("MM/yyyy"), moveItem.UISeq, moveItem.APRef, moveItem.InvTotal);
                        CompanyMoveDb.CreateAPCompanyMove(logFile, false, null, null, moveItem.UIMth, moveItem.Vendor, moveItem.APRef, moveItem.InvTotal, moveItem.APCo, moveItem.UISeq,
                            moveItem.UniqueAttchID, moveItem.KeyID, moveItem.DestAPCo, null, null, null, "Cannot move company. Header record has no attachment.");
                        continue;
                    }
                    if (moveItem.HasDetailLine.Value == true)
                    {
                        log.Info("Cannot move company --> Header record has detail line.");
                        log.InfoFormat("--Header details--> APCo:{0}, UIMth:{1}, UISeq:{2}, APRef:'{3}', InvTotal:{4}.",
                            moveItem.APCo, moveItem.UIMth.ToString("MM/yyyy"), moveItem.UISeq, moveItem.APRef, moveItem.InvTotal);
                        CompanyMoveDb.CreateAPCompanyMove(logFile, false, null, null, moveItem.UIMth, moveItem.Vendor, moveItem.APRef, moveItem.InvTotal, moveItem.APCo, moveItem.UISeq,
                            moveItem.UniqueAttchID, moveItem.KeyID, moveItem.DestAPCo, null, null, null, "Cannot move company. Header record has a detail line.");
                        continue;
                    }

                    List<HQAT> attachments = ViewpointDb.GetAttachmentRecords(moveItem.UniqueAttchID);

                    bool newHeaderCreated = false;
                    bool oldHeaderDeleted = false;
                    bool keepOldAttachment = moveItem.AttachmentCount > 1;
                    int attachCount = attachments.Count();
                    int attachDeleteCount = 0;
                    int attachCreateCount = 0;
                    int attachCopiedCount = 0;
                    Guid? newAttachUniqueID = null;

                    log.InfoFormat("Creating new AP header record. APRef:'{0}'. DestAPCo:{1}.", moveItem.APRef, moveItem.DestAPCo);
                    APUIUploadResults results = new APUIUploadResults();
                    newHeaderCreated = ViewpointDb.CreateAPUIRecord(moveItem.DestAPCo, moveItem.UIMth, moveItem.VendorGroup, moveItem.Vendor,
                        moveItem.APRef, moveItem.Description, moveItem.Notes, moveItem.InvDate, moveItem.InvTotal, moveItem.FreightCost, out results);
                    log.InfoFormat("New AP header record created. Success: {0}.", newHeaderCreated);
                    companyMoveID = CompanyMoveDb.CreateAPCompanyMove(logFile, null, null, null, moveItem.UIMth, moveItem.Vendor, moveItem.APRef, moveItem.InvTotal, moveItem.APCo,
                        moveItem.UISeq, moveItem.UniqueAttchID, moveItem.KeyID, moveItem.DestAPCo, results.UISeq, null, results.HeaderKeyID, null);
                    if (newHeaderCreated)
                    {
                        log.InfoFormat("--New AP header details--> APCo:{0}, UIMth:{1}, UISeq:{2}, APRef:'{3}', InvTotal:{4}.",
                            moveItem.DestAPCo, moveItem.UIMth.ToString("MM/yyyy"), results.UISeq, moveItem.APRef, moveItem.InvTotal);
                        foreach (var attachment in attachments)
                        {
                            HQATUploadResults attachResults = new HQATUploadResults();
                            bool attachCreated = ViewpointDb.CreateHQATRecord(moveItem.DestAPCo, results.HeaderKeyID, moveItem.UIMth, attachment.Description, APSettings.APModule, APSettings.APForm,
                                attachment.AttachmentTypeID, attachment.TableName, attachment.OrigFileName, attachment.AddedBy, out attachResults);
                            log.InfoFormat("Creating new attachment. Image:'{0}'. ID:'{1}'. Success: {2}.", attachment.OrigFileName, attachResults.UniqueAttachmentID, attachCreated);
                            log.InfoFormat("Message: '{0}'.", attachResults.Message);
                            bool? fileCopied = null;
                            bool attachDeleted = false;
                            if (attachCreated)
                            {
                                attachCreateCount++;
                                newAttachUniqueID = attachResults.UniqueAttachmentID;

                                log.InfoFormat("Attachment path:'{0}'.", attachResults.AttachmentFilePath);
                                fileCopied = ImportFileHelper.CopyImageFile(attachment.DocName, attachResults.AttachmentFilePath);
                                log.InfoFormat("Copying image file to new path.  Success: {0}.", fileCopied);
                                if (fileCopied == true)
                                {
                                    attachCopiedCount++;
                                }

                                log.InfoFormat("Attachment '{0}' belongs to multiple AP header records: {1}.", moveItem.UniqueAttchID, keepOldAttachment);

                                if (!keepOldAttachment)
                                {
                                    DBResults attachDeleteResults = new DBResults();
                                    attachDeleted = ViewpointDb.DeleteHQATRecord(attachment.AttachmentID, out attachDeleteResults);
                                    log.InfoFormat("Deleting attachment. AttachmentID:{0}. Success: {1}.", attachment.AttachmentID, attachDeleted);
                                    log.InfoFormat("Message: '{0}'.", attachDeleteResults.Message);
                                }
                            }
                            if (attachDeleted)
                            {
                                attachDeleteCount++;
                            }
                            string attachNote = string.Format("New attachment created: {0}. Old attachment deleted: {1}. Keep old attachment: {2}.", attachCreated, attachDeleted, keepOldAttachment);
                            CompanyMoveDb.CreateAttachmentCompanyMove(companyMoveID, keepOldAttachment, attachDeleted, fileCopied, attachment.OrigFileName,
                                attachment.FormName, attachment.TableName, attachment.DocName, attachment.AttachmentID, attachment.UniqueAttchID,
                                attachResults.AttachmentFilePath, attachResults.KeyID, attachResults.UniqueAttachmentID, attachNote);
                        }
                        log.InfoFormat("Deleting old AP header record. Invoice Number: '{0}'. Company: {1}.", moveItem.APRef, moveItem.APCo);
                        DBResults headerDeleteResults = new DBResults();
                        oldHeaderDeleted = ViewpointDb.DeleteAPUIRecord(moveItem.KeyID, out headerDeleteResults);
                        log.InfoFormat("Old AP header record deleted. Success: {0}. Message: '{1}'.", oldHeaderDeleted, headerDeleteResults.Message);
                    }
                    bool headerOkay = (newHeaderCreated && oldHeaderDeleted);

                    bool attachOkay = keepOldAttachment ? (attachCount - attachCreateCount == 0) : (attachCreateCount - attachDeleteCount == 0);
                    bool attachCopyOkay = (attachCount - attachCopiedCount == 0);
                    string headerNote = string.Format("AP Company move. Header move success: {0}. Attachment move success: {1}. Attach copy success: {2}", headerOkay, attachOkay, attachCopyOkay);
                    CompanyMoveDb.UpdateAPCompanyMove(companyMoveID, headerOkay, attachOkay, attachCopyOkay, newAttachUniqueID, headerNote);
                }
                catch (Exception ex)
                {
                    log.Error("An error has occurred.", ex);
                    if (companyMoveID > 0)
                    {
                        CompanyMoveDb.UpdateAPCompanyMoveError(companyMoveID, string.Concat("Error: ", ex.GetBaseException().Message));
                    }
                    else
                    {
                        CompanyMoveDb.CreateAPCompanyMove(logFile, false, null, null, moveItem.UIMth, moveItem.Vendor, moveItem.APRef, moveItem.InvTotal, moveItem.APCo, moveItem.UISeq,
                            moveItem.UniqueAttchID, moveItem.KeyID, moveItem.DestAPCo, null, null, null, string.Concat("Error: ", ex.GetBaseException().Message));
                    }
                }
            }
            log.Info("----------------------------");

            EndProcess:
            log.Info("Done AP with company move.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
