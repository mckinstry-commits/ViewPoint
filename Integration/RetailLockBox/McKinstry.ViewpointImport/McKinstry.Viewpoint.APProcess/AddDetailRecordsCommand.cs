using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Data.Entity.Validation;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class AddDetailRecordsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Add AP Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Adds an AP detail record for each row in the RLB data file.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Adding AP detail records to the database.");

            CsvFileDescription inputFileDescription = new CsvFileDescription
            {
                SeparatorChar = ',',
                FirstLineHasColumnNames = true
            };

            CsvContext cc = new CsvContext();

            IEnumerable<string> dataFiles = ImportFileHelper.FetchFiles(file.ProcessExtractPath, ".csv");

            List<APRecord> missingRecords = new List<APRecord>();

            foreach (var dataFile in dataFiles)
            {
                List<APRecord> records = cc.Read<APRecord>(dataFile, inputFileDescription).ToList<APRecord>();
                int count = records.Count();
                FileInfo dataFileInfo = new FileInfo(dataFile);

                // Update file with data file name
                file.DataFileName = dataFileInfo.Name;

                log.InfoFormat("Parsing data file '{0}'.  Found records: {1}.", dataFileInfo.Name, count);
                file.RecordCount += count;

                if (count <= 0)
                {
                    throw new ApplicationException(string.Format("Unable to add AP Detail records to database. Count: {0}.", count));
                }

                foreach (var record in records)
                {
                    try
                    {
                        log.Info("----------------");
                        int detailRecordID = APProcessDb.CreateAPImportDetail(batch.RLBImportBatchID, dataFileInfo, record);
                        log.InfoFormat("Adding AP Import Detail to Integration.  Success: {0}. ID: {1}.", detailRecordID > 0, detailRecordID);
                    }
                    catch (DbEntityValidationException ex)
                    {
                        var errorMessages = ex.EntityValidationErrors
                        .SelectMany(x => x.ValidationErrors)
                        .Select(x => x.ErrorMessage);

                        foreach (var message in errorMessages)
                        {
                            log.Error(string.Concat("Record add exception: ", message), ex);
                            missingRecords.Add(record);
                        }
                    }
                    catch (Exception ex)
                    {
                        log.Error("Record add exception.", ex);
                        missingRecords.Add(record);
                    }
                }

                if (missingRecords.Count > 0)
                {
                    string missingRecordsFile = string.Concat(Path.GetFileNameWithoutExtension(dataFileInfo.Name), "_MissingRecords.csv");
                    log.Info("----------------");
                    log.InfoFormat("Saving missing records in file '{0}'.  Missing records: {1}.", missingRecordsFile, missingRecords.Count);
                    cc.Write(missingRecords, Path.Combine(APSettings.APProcessFolderLocation, missingRecordsFile));
                }
            }

            log.Info("----------------");
            log.Info("Done adding AP detail records.");

            log.Info("Checking AP detail records.");

            List<RLBAPImportDetail> unprocessedRecords = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);
            int unprocessedCount = unprocessedRecords.Count();
            log.InfoFormat("AP detail records found: {0}.", unprocessedCount);
            if (unprocessedCount <= 0)
            {
                throw new ApplicationException(string.Format("Did not find unprocessed detail records for batch. Count: {0}.  Batch file: '{1}'.", unprocessedCount, batch.FileName));
            }

            log.Info("Done checking AP detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
