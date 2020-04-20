using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Data.Entity.Validation;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class AddDetailRecordsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Add AR Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Adds an AR detail record for each row in the RLB data file.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Adding AR detail records to the database.");

            CsvFileDescription inputFileDescription = new CsvFileDescription
            {
                SeparatorChar = ',',
                FirstLineHasColumnNames = true
            };

            CsvContext cc = new CsvContext();

            IEnumerable<string> dataFiles = ImportFileHelper.FetchFiles(file.ProcessExtractPath, ".csv");

            List<ARRecord> missingRecords = new List<ARRecord>();

            foreach (var dataFile in dataFiles)
            {
                List<ARRecord> records = cc.Read<ARRecord>(dataFile, inputFileDescription).ToList<ARRecord>();
                int count = records.Count();
                FileInfo dataFileInfo = new FileInfo(dataFile);

                log.InfoFormat("Parsing data file '{0}'.  Found records: {1}.", dataFileInfo.Name, count);
                file.RecordCount += count;

                if (count <= 0)
                {
                    throw new ApplicationException(string.Format("Unable to add AR Detail records to database. Count: {0}.", count));
                }

                foreach (var record in records)
                {
                    try
                    {
                        log.Info("----------------");
                        int detailRecordID = ARImportDb.CreateARImportDetail(batch.RLBImportBatchID, dataFileInfo, record);
                        log.InfoFormat("Adding AR Import Detail to Integration.  Success: {0}. ID: {1}.", detailRecordID > 0, detailRecordID);
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
                    cc.Write(missingRecords, Path.Combine(ARSettings.ARProcessFolderLocation, missingRecordsFile));
                }
            }

            log.Info("----------------");
            log.Info("Done adding AR detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
