using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class CloseInsert
    {
        /// <summary>
        /// This will insert the data in the grid to table
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="mth"></param>
        /// <param name="closeType"></param>
        /// <param name="batchId"></param>
        /// <param name="contracts"></param>
        /// <returns>list of failed contracts inserts</returns>
        public static List<string> MCKspContractCloseInsert(byte JCCo, string mth, char closeType, uint? batchId, dynamic contracts)
        {
            if (batchId == 0 || batchId == null) throw new Exception("Missing Batch ID required to insert Contracts into");
            SqlParameter _co = new SqlParameter("@co", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 30)
            {
                SqlValue = DBNull.Value
            };
            SqlParameter _mth = new SqlParameter("@month", SqlDbType.DateTime)
            {
                SqlValue = mth ?? (object)DBNull.Value
            };
            SqlParameter _status = new SqlParameter("@Istatus", SqlDbType.Char)
            {
                SqlValue = closeType != '\0' ? closeType : (object)DBNull.Value
            };
            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId != 0x0 ? batchId : (object)DBNull.Value
            };
            List<string> failedContracts = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    using (var _cmd = new SqlCommand("dbo.MCKspContractCloseInsert", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;

                        if (contracts.GetType() == typeof(Object[,]))
                        {
                            for (int n = 0; n < contracts.GetUpperBound(0); n++)
                            {
                                if (contracts[n + 1, 1] == null) continue;

                                _contract.SqlValue = contracts[n + 1, 1];
                                _cmd.Parameters.Add(_co);
                                _cmd.Parameters.Add(_contract);
                                _cmd.Parameters.Add(_mth);
                                _cmd.Parameters.Add(_status);
                                _cmd.Parameters.Add(_batchId);
                                _cmd.CommandTimeout = 600;

                                if (_cmd.ExecuteNonQuery() == 0)
                                {
                                    failedContracts = failedContracts ?? new List<string>();
                                    failedContracts.Add(_contract.Value.ToString());
                                }
                                _cmd.Parameters.Clear();
                            }
                        }
                        else // single entry
                        {
                            _contract.SqlValue = contracts;
                            _cmd.Parameters.Add(_co);
                            _cmd.Parameters.Add(_contract);
                            _cmd.Parameters.Add(_mth);
                            _cmd.Parameters.Add(_status);
                            _cmd.Parameters.Add(_batchId);
                            _cmd.CommandTimeout = 600;

                            if (_cmd.ExecuteNonQuery() == 0)
                            {
                                failedContracts = failedContracts ?? new List<string>();
                                failedContracts.Add(_contract.Value.ToString());
                            }
                            _cmd.Parameters.Clear();
                        }
                    }
                } // close connection

                return failedContracts;
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                _co = null;
                _contract = null;
                _mth = null;
                _status = null;
                _batchId = null;
            }
        }
    }
}
