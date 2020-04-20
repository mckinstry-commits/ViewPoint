using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using McK.APImport.Common;
using System.Data;

namespace McK.Data.Viewpoint
{
    public class MckIntegrationDb
    {
        public MckIntegrationDb()=> connectionString = CommonSettings.MckIntegrationConnectionString;
        

        private static string connectionString;
        private static string ConnectionString
        {
            get
            {
                if (string.IsNullOrEmpty(connectionString))
                {
                    connectionString = CommonSettings.MckIntegrationConnectionString;
                }
                return connectionString;
            }
        }

        public static int? CreateProcessNote(string processNote)
        {
            string sqlInsert = @"INSERT INTO dbo.RLBProcessNotes
                                 VALUES (@ProcessNotes, GETDATE());
                                 SELECT @@IDENTITY";

            SqlParameter processNotes = new SqlParameter("@ProcessNotes", SqlDbType.NVarChar, 512)
            {
                SqlValue = processNote
            };
            int? rlbProcessNotesID = default(int?);

            try
            {
                using (var _conn = new SqlConnection(connectionString))
                {
                    _conn.Open();

                    // INSERT
                    using (var _cmd = new SqlCommand(sqlInsert, _conn))
                    {
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(processNotes);

                        var noteID = _cmd.ExecuteScalar();
                        if (noteID != DBNull.Value)
                        {
                            rlbProcessNotesID = Convert.ToInt32(noteID);
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.CreateProcessNote: \n" + e.Message); }

            return rlbProcessNotesID;
        }

        public static List<RLBImportBatch> GetUnprocessedAPBatches()
        {
            string sql = @"SELECT * FROM [MCK_INTEGRATION].[dbo].RLBImportBatch
                            WHERE	 RLBImportBatchStatusCode = 'MAN'";
            List<RLBImportBatch> list;

            try
            {
                using (var _conn = new SqlConnection(connectionString))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(sql, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            list = new List<RLBImportBatch>();

                            while (reader.Read())
                            {
                                RLBImportBatch record = new RLBImportBatch();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);

                                list.Add(record);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.GetUnprocessedAPBatches: \n" + e.Message); }

            return list;
        }

        public static List<RLBAPImportDetail> GetUnprocessedAPDetailRecords(int batchID)
        {
            string sql = @"SELECT *
                            FROM [MCK_INTEGRATION].[dbo].[RLBAPImportDetail]
                            WHERE RLBImportBatchID = " + batchID + " AND RLBImportDetailStatusCode = 'UNP'";
            List<RLBAPImportDetail> list;

            try
            {
                using (var _conn = new SqlConnection(connectionString))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(sql, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            list = new List<RLBAPImportDetail>();

                            while (reader.Read())
                            {
                                RLBAPImportDetail record = new RLBAPImportDetail();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);

                                list.Add(record);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.GetUnprocessedAPDetailRecords: \n" + e.Message); }

            return list;
        }


        public static RLBImportBatch GetImportBatch(int batchID)
        {
            string sql = @"SELECT *
                            FROM [MCK_INTEGRATION].[dbo].RLBImportBatch
                            WHERE	 RLBImportBatchID = " + batchID;
            RLBImportBatch record = default(RLBImportBatch);

            try
            {
                using (var _conn = new SqlConnection(connectionString))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(sql, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                record = new RLBImportBatch();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.GetImportBatch: \n" + e.Message); }

            return record;
        }

        public static bool UpdateImportBatch(RLBImportBatch batch)
        {
            SqlParameter completeTime = new SqlParameter("@CompleteTime", SqlDbType.DateTime)
            {
                SqlValue = (object)DBNull.Value
            };
            SqlParameter rlbImportBatchStatusCode = new SqlParameter("@RLBImportBatchStatusCode", SqlDbType.VarChar, 3)
            {
                SqlValue = (object)DBNull.Value
            };
            SqlParameter modified = new SqlParameter("@Modified", SqlDbType.DateTime)
            {
                SqlValue = (object)DBNull.Value
            };

            string sqlSelect = @"SELECT CompleteTime, RLBImportBatchStatusCode, Modified
                                 FROM [MCK_INTEGRATION].[dbo].RLBImportBatch
                                 WHERE RLBImportBatchID = " + batch.RLBImportBatchID;

            string sqlUpdate = @"UPDATE [MCK_INTEGRATION].[dbo].RLBImportBatch
                                 SET   CompleteTime = @CompleteTime
                                     , RLBImportBatchStatusCode = @RLBImportBatchStatusCode
                                     , Modified = @Modified
                                 WHERE RLBImportBatchID = " + batch.RLBImportBatchID;
            bool updated = false;
            bool existing = false;

            try
            {
                using (var _conn = new SqlConnection(connectionString))
                {
                    _conn.Open();

                    // SELECT (check for existing)
                    using (var _cmd = new SqlCommand(sqlSelect, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            existing = reader.HasRows;

                            while (reader.Read())
                            {
                                completeTime.SqlValue = batch.CompleteTime;
                                rlbImportBatchStatusCode.SqlValue = batch.RLBImportBatchStatusCode;
                                modified.SqlValue = DateTime.Now;
                            }
                        }

                    }
                    
                    if (existing)
                    {
                        // UPDATE
                        using (var _cmd = new SqlCommand(sqlUpdate, _conn))
                        {
                            _cmd.Parameters.Add(completeTime);
                            _cmd.Parameters.Add(rlbImportBatchStatusCode);
                            _cmd.Parameters.Add(modified);

                            var success = _cmd.ExecuteNonQuery();
                            updated = Convert.ToBoolean(success);
                        }
                        if (updated) batch.Modified = (DateTime?)modified.Value;
                    }
                }
            }
            catch (Exception ex) { return false; }

            return updated;
        }

        public static List<RLBAPImportDetail> GetAPDetailRecords(int batchID)
        {
            string sql = @"SELECT *
                            FROM [MCK_INTEGRATION].[dbo].[RLBAPImportDetail]
                            WHERE	 RLBImportBatchID = " + batchID;
            List<RLBAPImportDetail> list;

            try
            {
                using (var _conn = new SqlConnection(connectionString))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(sql, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            list = new List<RLBAPImportDetail>();

                            while (reader.Read())
                            {
                                RLBAPImportDetail record = new RLBAPImportDetail();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);

                                list.Add(record);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.GetAPDetailRecords: \n" + e.Message); }

            return list;
        }

        public static bool UpdateAPImportDetail(int importDetailID, string statusCode, int? noteID)
        {
            SqlParameter rlbProcessNotesID = new SqlParameter("@RLBProcessNotesID", SqlDbType.Int);
            SqlParameter rlbImportDetailStatusCode = new SqlParameter("@RLBImportDetailStatusCode", SqlDbType.VarChar, 3);
            SqlParameter modified = new SqlParameter("@Modified", SqlDbType.DateTime);

            string sqlSelect = @"SELECT RLBProcessNotesID, RLBImportDetailStatusCode, Modified
                                 FROM [MCK_INTEGRATION].[dbo].[RLBAPImportDetail]
                                 WHERE RLBAPImportDetailID = " + importDetailID;

            string sqlUpdate = @"UPDATE [MCK_INTEGRATION].[dbo].[RLBAPImportDetail]
                                SET RLBProcessNotesID = @RLBProcessNotesID
                                , RLBImportDetailStatusCode = @RLBImportDetailStatusCode
                                , Modified = @Modified
                                WHERE RLBAPImportDetailID = " + importDetailID;
            bool updated = false;
            bool hasRows = false;

            try
            {
                using (var _conn = new SqlConnection(connectionString))
                {
                    _conn.Open();

                    // SELECT 
                    using (var _cmd = new SqlCommand(sqlSelect, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            hasRows = reader.HasRows;

                            while (reader.Read())
                            {
                                rlbProcessNotesID.SqlValue = noteID.HasValue ? noteID : (object)DBNull.Value;
                                rlbImportDetailStatusCode.SqlValue = statusCode;
                                modified.SqlValue = DateTime.Now;
                            }
                        }
                    }
                    
                    // UPDATE
                    if (hasRows)
                    {
                        using (var _cmd = new SqlCommand(sqlUpdate, _conn))
                        {
                            _cmd.CommandTimeout = 600;
                            _cmd.Parameters.Add(rlbProcessNotesID);
                            _cmd.Parameters.Add(rlbImportDetailStatusCode);
                            _cmd.Parameters.Add(modified);

                            updated = Convert.ToBoolean(_cmd.ExecuteNonQuery());
                        }
                    }
      
                }
            }
            catch (Exception e) { throw new Exception("MckIntegrationDb.GetImportBatch: \n" + e.Message); }

            return updated;
        }
    }
}
