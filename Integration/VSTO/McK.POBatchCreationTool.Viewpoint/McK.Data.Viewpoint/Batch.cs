using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class Batch
    {
        // STEP 1
        /// <summary>
        /// Creates Viewpoint batch to populate with validated POs
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="month"></param>
        /// <param name="Rbatchid"></param>
        /// <returns>Contract Batch ID</returns>
        public static uint? CreateBatch(byte JCCo, string month)
        {
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
            };

            SqlParameter _mth = new SqlParameter("@BatchMth", SqlDbType.DateTime)
            {
                SqlValue = month ?? (object)DBNull.Value
            };

            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = DBNull.Value,
                Direction = ParameterDirection.Output
            };

            SqlCommand _cmd;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (_cmd = new SqlCommand("dbo.MCKspPOCreateBatch", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_mth);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.CommandTimeout = 600;
                        _cmd.ExecuteScalar();

                        return (uint?)Convert.ToUInt32(_batchId.Value); //returns zero if null
                    }
                }

            }
            catch (Exception)
            {
                throw; // to UI
            }
            finally
            {
                _cmd = null;
                _co = null;
                _mth = null;
            }
        }

        // STEP 2
        /// <summary>
        /// Inserts POs into staging table -- MCKPOStage which also acts as a history/audit table
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="month"></param>
        /// <param name="batchId"></param>
        /// <param name="POs"></param>
        /// <returns>list of failed contracts inserts</returns>
        public static List<string> StagePOs(byte JCCo, string month, uint? batchId, dynamic POs)
        {
            if (batchId == null || batchId == 0) throw new Exception("Missing Batch ID required to insert POs into");

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _mckPo = new SqlParameter("@MCKPO", SqlDbType.VarChar, 30)
            {
                SqlValue = DBNull.Value
            };
            SqlParameter _mth = new SqlParameter("@BatchMth", SqlDbType.DateTime)
            {
                SqlValue = month ?? (object)DBNull.Value
            };
            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId
            };

            List<string> lstFailed = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspPOInsertLoad", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;

                        if (POs.GetType() == typeof(Object[,]))
                        {
                            // a list (array)
                            for (int n = 0; n < POs.GetUpperBound(0); n++)
                            {
                                if (POs[n + 1, 1] == null) continue;

                                _mckPo.SqlValue = POs[n + 1, 1];
                                _cmd.Parameters.Add(_co);
                                _cmd.Parameters.Add(_mckPo);
                                _cmd.Parameters.Add(_mth);
                                _cmd.Parameters.Add(_batchId);
                                _cmd.CommandTimeout = 600;
                                try
                                {
                                    if (_cmd.ExecuteNonQuery() == 0)
                                    {
                                        // no rows affected..
                                        lstFailed = lstFailed ?? new List<string>();
                                        lstFailed.Add(_mckPo.Value.ToString());
                                    }
                                }
                                catch (SqlException)
                                {
                                    // SQL exception.. log PO and keep going..
                                    lstFailed = lstFailed ?? new List<string>();
                                    lstFailed.Add(_mckPo.Value.ToString());
                                }

                                _cmd.Parameters.Clear();
                            }
                        }
                        else
                        {
                            // single row
                            _mckPo.SqlValue = POs;
                            _cmd.Parameters.Add(_co);
                            _cmd.Parameters.Add(_mckPo);
                            _cmd.Parameters.Add(_mth);
                            _cmd.Parameters.Add(_batchId);
                            _cmd.CommandTimeout = 600;
                            try
                            {
                                if (_cmd.ExecuteNonQuery() == 0)
                                {
                                    // no rows affected..
                                    lstFailed = lstFailed ?? new List<string>();
                                    lstFailed.Add(_mckPo.Value.ToString());
                                }
                            }
                            catch (SqlException)
                            {
                                // SQL exception.. log PO and keep going..
                                lstFailed = lstFailed ?? new List<string>();
                                lstFailed.Add(_mckPo.Value.ToString());
                            }
                        }
                    }
                } // close connection

                return lstFailed;
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                _co = null;
                _mckPo = null;
                _mth = null;
                _batchId = null;
            }
        }

        // STEP 3
        /// <summary>
        /// Validate all Staged POs: valid Company, MCK PO exists, and PO is OPEN
        /// </summary>
        /// <param name="batchId">Working VP Batch ID</param>
        /// <returns>Records processed count</returns>
        public static bool ValidateBatch(uint? batchId)
        {
            if (batchId == null) throw new Exception("Missing required Batch ID to process users");

            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId // 'Value' gets assigned and used.  SQLValue is not used.
            };

            SqlCommand _cmd = null;
            bool success;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (_cmd = new SqlCommand("dbo.MCKspPOValidateBatch", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_batchId);
                        _cmd.CommandTimeout = 0;

                        success = Convert.ToBoolean(_cmd.ExecuteScalar());
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Batch.ValidateBatch");
                throw ex;
            }
            finally
            {
                _batchId = null;
            }
            //returns zero if null
            return success;
        }

        // STEP 4
        /// <summary>
        /// Insert all good POs into VP Batch
        /// </summary>
        /// <param name="batchId">Current working Batch ID</param>
        public static uint InsertGoodPOsIntoVPBatch(byte JCCo, string month, uint? batchId)
        {
            if (batchId == null) throw new Exception("Missing required Batch ID to process users");

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value
            };

            SqlParameter _mth = new SqlParameter("@BatchMth", SqlDbType.DateTime)
            {
                SqlValue = month ?? (object)DBNull.Value
            };

            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId
            };

            SqlParameter _passCnt = new SqlParameter("@passCnt", SqlDbType.Int)
            {
                SqlValue = DBNull.Value,
                Direction = ParameterDirection.Output
            };

            SqlCommand _cmd = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    //_conn.InfoMessage += new SqlInfoMessageEventHandler(ProgressStatus); //get updates from the database

                    using (_cmd = new SqlCommand("dbo.MCKspPOInsertBatch", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_mth);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.Parameters.Add(_passCnt);
                        _cmd.CommandTimeout = 0;
                        _cmd.ExecuteScalar();

                        return _passCnt.Value != DBNull.Value ? Convert.ToUInt32(_passCnt.Value) : 0;
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Batch.InsertGoodPOsIntoVPBatch");
                throw ex;
            }
        }


        // STEP 5
        /// <summary>
        /// Get failed POs
        /// </summary>
        /// <param name="batchId"></param>
        /// <returns>List of failed POs</returns>
        public static List<dynamic> GetPOBatchErrors(uint? batchId)
        {
            string _sql = "Select * from dbo.MCKPOerror with(nolock) Where BatchNum = @Rbatchid;";
            SqlParameter _batch = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId ?? (object)DBNull.Value
            };
            List<dynamic> table = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_batch);
                        _cmd.CommandTimeout = 600;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            table = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    // get type name
                                    string type = reader.GetFieldType(field).FullName;

                                    // trim out 'System.' from type name
                                    int dot = type.IndexOf('.') + 1;
                                    type = type.Substring(dot, type.Length - dot);

                                    // add ROW: Column Name | data type | value
                                    row.Add(reader.GetName(field), new KeyValuePair<string, object>(type, reader[field]));
                                }
                                table.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "GetPOBatchErrors");
                throw ex;
            }
            return table;
        }
    }
}

