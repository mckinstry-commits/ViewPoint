using System;
using System.Collections.Generic;
using System.Linq;
using System.Data.SqlClient;
using System.Data;
using McK.APImport.Common;
using McK.Data.Viewpoint;

namespace McK.APImport.Viewpoint
{
    internal class APImportDb : Db
    {
        public static List<RLBAPImportDetail> GetExistingAPExceptions(int batchID)
        {
            List<RLBAPImportDetail> exceptions;
            string sqlSelect = @"SELECT *
                                 FROM [MCK_INTEGRATION].[dbo].[RLBAPImportDetail]
                                 WHERE RLBImportBatchID = " + batchID + @" AND RLBImportDetailStatusCode = 'EXC'";

            try
            {
                using (var _conn = new SqlConnection(IntegrationConnectionString))
                {
                    _conn.Open();

                    exceptions = new List<RLBAPImportDetail>();

                    using (var _cmd = new SqlCommand(sqlSelect, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                RLBAPImportDetail record = new RLBAPImportDetail();

                                DataHelper.ReaderToModel(reader, record);

                                exceptions.Add(record);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("APImportDb.GetExistingAPExceptions: \n" + e.Message); }

            return exceptions;
        }

        public static bool AddAPRecord(DateTime transactionDate, RLBAPImportDetail record, out APRecordUploadResults results)
        {
            #region INPUT
            SqlParameter recordType = new SqlParameter("@RecordType", SqlDbType.NVarChar, 30)
            {
                SqlValue = record.RecordType
            };
            SqlParameter company = new SqlParameter("@Company", SqlDbType.TinyInt)
            {
                SqlValue = record.Company
            };
            SqlParameter transDate = new SqlParameter("@TransactionDate", SqlDbType.DateTime)
            {
                SqlValue = transactionDate
            };
            SqlParameter number = new SqlParameter("@Number", SqlDbType.VarChar, 30)
            {
                SqlValue = record.Number
            };
            SqlParameter vendorGroup = new SqlParameter("@VendorGroup", SqlDbType.TinyInt)
            {
                SqlValue = record.VendorGroup
            };
            SqlParameter vendor = new SqlParameter("@Vendor", SqlDbType.Int)
            {
                SqlValue = record.Vendor
            };
            SqlParameter collectedInvoiceNumber = new SqlParameter("@CollectedInvoiceNumber", SqlDbType.VarChar, 50)
            {
                SqlValue = record.CollectedInvoiceNumber
            };
            SqlParameter description = new SqlParameter("@Description", SqlDbType.VarChar, 30)
            {
                SqlValue = record.Description
            };
            SqlParameter collectedInvoiceDate = new SqlParameter("@CollectedInvoiceDate", SqlDbType.SmallDateTime)
            {
                SqlValue = record.CollectedInvoiceDate
            };
            SqlParameter collectedInvoiceAmount = new SqlParameter("@CollectedInvoiceAmount", SqlDbType.Decimal)
            {
                SqlValue = record.CollectedInvoiceAmount
            };
            SqlParameter collectedTaxAmount = new SqlParameter("@CollectedTaxAmount", SqlDbType.Decimal)
            {
                SqlValue = record.CollectedTaxAmount
            };
            SqlParameter collectedShippingAmount = new SqlParameter("@CollectedShippingAmount", SqlDbType.Decimal)
            {
                SqlValue = record.CollectedShippingAmount
            };
            SqlParameter module = new SqlParameter("@Module", SqlDbType.VarChar, 30)
            {
                SqlValue = APSettings.APModule
            };
            SqlParameter formName = new SqlParameter("@FormName", SqlDbType.VarChar, 30)
            {
                SqlValue = APSettings.APForm
            };
            SqlParameter imageFileName = new SqlParameter("@ImageFileName", SqlDbType.NVarChar, 512)
            {
                SqlValue = record.CollectedImage
            };
            SqlParameter userAccount = new SqlParameter("@UserAccount", SqlDbType.NVarChar, 200)
            {
                SqlValue = APSettings.APUserAccount
            };
            SqlParameter unmatchedCompany = new SqlParameter("@UnmatchedCompany", SqlDbType.TinyInt)
            {
                SqlValue = APSettings.APUnmatchedCompany
            };
            SqlParameter unmatchedVendorGroup = new SqlParameter("@UnmatchedVendorGroup", SqlDbType.TinyInt)
            {
                SqlValue = APSettings.APUnmatchedVendorGroup
            };
            SqlParameter unmatchedVendor = new SqlParameter("@UnmatchedVendor", SqlDbType.Int)
            {
                SqlValue = APSettings.APUnmatchedVendor
            }; 
            #endregion

            #region OUTPUT
            SqlParameter attachmentID = new SqlParameter("@AttachmentID", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
            SqlParameter uniqueAttachmentID = new SqlParameter("@UniqueAttachmentID", SqlDbType.UniqueIdentifier)
            {
                Direction = ParameterDirection.Output
            };
            SqlParameter attachmentFilePath = new SqlParameter("@AttachmentFilePath", SqlDbType.VarChar, 512)
            {
                Direction = ParameterDirection.Output
            };
            SqlParameter headerKeyID = new SqlParameter("@HeaderKeyID", SqlDbType.BigInt)
            {
                Direction = ParameterDirection.Output
            };
            SqlParameter footerKeyID = new SqlParameter("@FooterKeyID", SqlDbType.BigInt)
            {
                Direction = ParameterDirection.Output
            };
            SqlParameter message = new SqlParameter("@Message", SqlDbType.VarChar, 512)
            {
                Direction = ParameterDirection.Output
            };
            SqlParameter retVal = new SqlParameter("@RetVal", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                }; 
            #endregion

            try
            {
                using (var _conn = new SqlConnection(ViewpointConnectionString))
                {
                    _conn.Open();

                    // EXECUTE 
                    using (var _cmd = new SqlCommand("mckspAPUIAddItemWithFile", _conn))
                    {
                        _cmd.CommandTimeout = 600;
                        _cmd.CommandType = CommandType.StoredProcedure;

                        _cmd.Parameters.AddRange(new SqlParameter[] { recordType, company, transDate, number, vendorGroup, vendor,
                                                collectedInvoiceNumber, description, collectedInvoiceDate, collectedInvoiceAmount, collectedTaxAmount,
                                                collectedShippingAmount, module, formName, imageFileName, userAccount, unmatchedCompany, unmatchedVendorGroup, unmatchedVendor,
                                                attachmentID, uniqueAttachmentID, attachmentFilePath, headerKeyID, footerKeyID, message, retVal});
                        _cmd.ExecuteNonQuery();

                        results = new APRecordUploadResults
                        {
                            AttachmentID = (attachmentID.Value == DBNull.Value) ? default(int?) : Convert.ToInt32(attachmentID.Value),
                            UniqueAttachmentID = (uniqueAttachmentID.Value == DBNull.Value) ? default(Guid?) : Guid.Parse(uniqueAttachmentID.Value.ToString()),
                            AttachmentFilePath = attachmentFilePath.Value == DBNull.Value ? null : attachmentFilePath.Value.ToString(),
                            HeaderKeyID = (headerKeyID.Value == DBNull.Value) ? default(long?) : Convert.ToInt64(headerKeyID.Value),
                            FooterKeyID = (footerKeyID.Value == DBNull.Value) ? default(long?) : Convert.ToInt64(footerKeyID.Value),
                            Message = message.Value == DBNull.Value ? null : message.Value.ToString(),
                            RetVal = (retVal.Value == DBNull.Value) ? -1 : Convert.ToInt32(retVal.Value)
                        };
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                results = new APRecordUploadResults
                {
                    Message = string.Format("Execution Exception: {0}.", ex.GetBaseException().Message)
                };
                return false;
            }
        }

        public static string GetRLBImportDetailStatusCode(dynamic importRecordID)
        {
            string sqlSelect = @"SELECT HeaderKeyID, FooterKeyID, AttachmentID 
                                 FROM [MCK_INTEGRATION].[dbo].[RLBAPImportRecord]
                                 WHERE RLBAPImportRecordID = " + importRecordID;
            RLBAPImportRecord record = default(RLBAPImportRecord);

            try
            {
                using (var _conn = new SqlConnection(IntegrationConnectionString))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(sqlSelect, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                record = new RLBAPImportRecord();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("APImportDb.GetRLBImportDetailStatusCode: \n" + e.Message); }


            if (record == default(RLBAPImportRecord))
            {
                return "UNP"; // Unprocessed
            }
            if (record.HeaderKeyID.HasValue && record.FooterKeyID.HasValue && record.AttachmentID.HasValue)
            {
                return "MAT"; // Matched
            }
            if (record.HeaderKeyID.HasValue && !record.FooterKeyID.HasValue && record.AttachmentID.HasValue)
            {
                return "UNM"; // Unmatched
            }
            if (!record.HeaderKeyID.HasValue && !record.FooterKeyID.HasValue && record.AttachmentID.HasValue)
            {
                return "STN"; // Standalone
            }

            return "UNP";
        }

        public static dynamic CreateAPImportRecord(int importDetailID, APRecordUploadResults results, APUI headerRecord, HQAT attachmentRecord, bool? fileCopied, int? processNotesID)
        {
            string sqlInsert = @"INSERT INTO [dbo].[RLBAPImportRecord]
                                                   ([RLBAPImportDetailID]
                                                   ,[Co]
                                                   ,[Mth]
                                                   ,[UISeq]
                                                   ,[Vendor]
                                                   ,[APRef]
                                                   ,[InvDate]
                                                   ,[InvTotal]
                                                   ,[HeaderKeyID]
                                                   ,[FooterKeyID]
                                                   ,[DocName]
                                                   ,[AttachmentID]
                                                   ,[UniqueAttchID]
                                                   ,[OrigFileName]
                                                   ,[FileCopied]
                                                   ,[RLBProcessNotesID]
                                                   ,[Created]
                                                   ,[Modified])
                                             VALUES
                                                   (@RLBAPImportDetailID
                                                   ,@Co
                                                   ,@Mth
                                                   ,@UISeq
                                                   ,@Vendor
                                                   ,@APRef
                                                   ,@InvDate
                                                   ,@InvTotal
                                                   ,@HeaderKeyID
                                                   ,@FooterKeyID
                                                   ,@DocName
                                                   ,@AttachmentID
                                                   ,@UniqueAttchID
                                                   ,@OrigFileName
                                                   ,@FileCopied
                                                   ,@RLBProcessNotesID
                                                   ,@Created
                                                   ,@Modified);
                                    SELECT @@IDENTITY";

            SqlParameter rlbAPImportDetailID = new SqlParameter("@RLBAPImportDetailID", SqlDbType.Int)
            {
                SqlValue = importDetailID
            };

            SqlParameter co = new SqlParameter("@Co", SqlDbType.TinyInt)
            {
                SqlValue = (headerRecord.APCo == 0) ? (object)DBNull.Value : headerRecord.APCo
            };
            SqlParameter mth = new SqlParameter("@Mth", SqlDbType.SmallDateTime)
            {
                SqlValue = (headerRecord.UIMth == DateTime.MinValue) ? (object)DBNull.Value : headerRecord.UIMth
            };
            SqlParameter uiSeq = new SqlParameter("@UISeq", SqlDbType.SmallInt)
            {
                SqlValue = (headerRecord.UISeq == 0) ? (object)DBNull.Value : headerRecord.UISeq
            };
            SqlParameter vendor = new SqlParameter("@Vendor", SqlDbType.Int)
            {
                SqlValue = (headerRecord.Vendor == 0 || headerRecord.Vendor == null) ? (object)DBNull.Value : headerRecord.Vendor
            };
            SqlParameter apRef = new SqlParameter("@APRef", SqlDbType.VarChar, 15)
            {
                SqlValue = headerRecord.APRef ?? (object)DBNull.Value
            };
            SqlParameter invDate = new SqlParameter("@InvDate", SqlDbType.SmallDateTime)
            {
                SqlValue = (headerRecord.InvDate == null || headerRecord.InvDate == DateTime.MinValue) ? (object)DBNull.Value : headerRecord.InvDate
            };
            SqlParameter invTotal = new SqlParameter("@InvTotal", SqlDbType.Decimal)
            {
                SqlValue = headerRecord.InvTotal
            };
            SqlParameter headerKeyID = new SqlParameter("@HeaderKeyID", SqlDbType.BigInt)
            {
                SqlValue = (headerRecord.KeyID == 0) ? (object)DBNull.Value : headerRecord.KeyID
            };
            SqlParameter footerKeyID = new SqlParameter("@FooterKeyID", SqlDbType.BigInt)
            {
                SqlValue = (results.FooterKeyID == null || (results.FooterKeyID == 0)) ? (object)DBNull.Value : results.FooterKeyID
            };
            SqlParameter docName = new SqlParameter("@DocName", SqlDbType.NVarChar, 512)
            {
                SqlValue = attachmentRecord.DocName
            };
            SqlParameter attachmentID = new SqlParameter("@AttachmentID", SqlDbType.Int)
            {
                SqlValue = (attachmentRecord.AttachmentID == 0) ? (object)DBNull.Value : attachmentRecord.AttachmentID
            };
            SqlParameter uniqueAttchID = new SqlParameter("@UniqueAttchID", SqlDbType.UniqueIdentifier)
            {
                SqlValue = attachmentRecord.UniqueAttchID ?? (object)DBNull.Value 
            };
            SqlParameter OrigFileName = new SqlParameter("@OrigFileName", SqlDbType.NVarChar, 512)
            {
                SqlValue = attachmentRecord.OrigFileName
            };
            SqlParameter filecopied = new SqlParameter("@FileCopied", SqlDbType.Bit)
            {
                SqlValue = fileCopied ?? (object)DBNull.Value
            };
            SqlParameter rlbProcessNotesID = new SqlParameter("@RLBProcessNotesID", SqlDbType.Int)
            {
                SqlValue = processNotesID
            };
            SqlParameter created = new SqlParameter("@Created", SqlDbType.DateTime)
            {
                SqlValue = DateTime.Now
            };
            SqlParameter modified = new SqlParameter("@Modified", SqlDbType.DateTime)
            {
                SqlValue = DateTime.Now
            };

            dynamic rlbAPImportRecordID;

            try
            {
                using (var _conn = new SqlConnection(IntegrationConnectionString))
                {
                    _conn.Open();

                    // INSERT
                    using (var _cmd = new SqlCommand(sqlInsert, _conn))
                    {
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.AddRange(new SqlParameter[] { rlbAPImportDetailID, co, mth, uiSeq, vendor, apRef, invDate, invTotal,
                                                                      headerKeyID, footerKeyID, docName,attachmentID, uniqueAttchID, OrigFileName, filecopied,
                                                                      rlbProcessNotesID, created, modified});

                        var rlbAPImportRecID = _cmd.ExecuteScalar();
                        rlbAPImportRecordID = rlbAPImportRecID == DBNull.Value ? null : rlbAPImportRecID;
                    }
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.CreateProcessNote: \n" + e.Message); }

            return rlbAPImportRecordID;
        }

        public static List<RecordSummary> GetAPDetailRecordCounts(int recordCount, int batchID)
        {
            List<RecordSummary> list = new List<RecordSummary>();
            List<RLBAPImportDetail> detailItems;

            string sqlSelect = @"SELECT *
                            FROM [MCK_INTEGRATION].[dbo].[RLBAPImportDetail]
                            WHERE RLBImportBatchID = " + batchID;

            try
            {
                using (var _conn = new SqlConnection(IntegrationConnectionString))
                {
                    _conn.Open();

                    detailItems = new List<RLBAPImportDetail>();

                    using (var _cmd = new SqlCommand(sqlSelect, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                RLBAPImportDetail record = new RLBAPImportDetail();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);

                                detailItems.Add(record);
                            }
                        }
                    }

                    sqlSelect = "SELECT StatusCode, Status FROM dbo.RLBImportDetailStatus";

                    List<RLBImportDetailStatus> listStatusCodes = new List<RLBImportDetailStatus>();

                    using (var _cmd = new SqlCommand(sqlSelect, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                RLBImportDetailStatus record = new RLBImportDetailStatus();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);

                                listStatusCodes.Add(record);
                            }
                        }
                    }
                    int detailCount = detailItems.Count();

                    var items = detailItems.GroupBy(r => r.RLBImportDetailStatusCode)
                                            .Select(g => new
                                            {
                                                StatusCode = g.Key,
                                                Status = listStatusCodes.Where(s => s.StatusCode == g.Key).Select(s => s.Status).FirstOrDefault<string>(),
                                                Count = g.Count()

                                            });

                    items = items.OrderBy(i => i.Status);

                    int count = items.Count();

                    foreach (var item in items)
                    {
                        list.Add(new RecordSummary { Count = item.Count, Status = item.Status });
                    }
                    if (recordCount > detailCount)
                    {
                        list.Add(new RecordSummary { Count = recordCount - detailCount, Status = "Missing Records" });
                    }
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.GetAPDetailRecordCounts: \n" + e.Message); }

            return list;
        }

        public static List<RecordSummary> GetAPProcessingCounts(int recordCount, int batchID)
        {
            List<RecordSummary> list = new List<RecordSummary>();
            List<RLBAPImportDetail> detailItems;

            string sqlSelect = @"SELECT *
                                 FROM [MCK_INTEGRATION].[dbo].[RLBAPImportDetail]
                                 WHERE RLBImportBatchID = " + batchID;

            try
            {
                using (var _conn = new SqlConnection(IntegrationConnectionString))
                {
                    _conn.Open();

                    detailItems = new List<RLBAPImportDetail>();

                    using (var _cmd = new SqlCommand(sqlSelect, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                RLBAPImportDetail record = new RLBAPImportDetail();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);

                                detailItems.Add(record);
                            }
                        }
                    }

                    int errorItems = detailItems.Where(r => r.RLBImportDetailStatusCode == "ERR")
                       .Select(r => r)
                       .Count();

                    int unprocessedItems = detailItems.Where(r => r.RLBImportDetailStatusCode == "UNP")
                       .Select(r => r)
                       .Count();

                    sqlSelect = @"SELECT FileCopied, AttachmentID
                                    FROM [MCK_INTEGRATION].[dbo].mckvwRLBAPImportRecord
                                    WHERE RLBImportBatchID = " + batchID;

                    List<RLBAPImportRecord> recordItems = new List<RLBAPImportRecord>();

                    using (var _cmd = new SqlCommand(sqlSelect, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                RLBAPImportRecord record = new RLBAPImportRecord();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);

                                recordItems.Add(record);
                            }
                        }
                    }

                    int filesNotCopied = recordItems.Where(r => Convert.ToBoolean(r.FileCopied) == false)
                       .Select(r => r)
                       .Count();

                    int missingAttachments = recordItems.Where(r => (r.AttachmentID == null) || (r.AttachmentID == 0))
                       .Select(r => r)
                       .Count();

                    list.Add(new RecordSummary { Status = "Files Not Copied", Count = filesNotCopied });
                    list.Add(new RecordSummary { Status = "Missing Attachments", Count = missingAttachments });
                    list.Add(new RecordSummary { Status = "Missing Records", Count = recordCount - (detailItems.Count > 0 ? detailItems.Count-1: 0) });
                    list.Add(new RecordSummary { Status = "Errors", Count = errorItems });
                    list.Add(new RecordSummary { Status = "Unprocessed Records", Count = unprocessedItems });
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.GetAPProcessingCounts: \n" + e.Message); }

            return list;
        }
    }
}
