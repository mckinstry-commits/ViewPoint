using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class CloseInsert
    {
        /// <summary>
        /// This will insert the data in the grid to table -- MCKPOCloseStage which also acts as a history/audit table
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="mth"></param>
        /// <param name="closeType"></param>
        /// <param name="batchId"></param>
        /// <param name="POs"></param>
        /// <returns>list of failed contracts inserts</returns>
        public static List<string> MCKspPOCloseInsert(byte JCCo, string mth, char closeType, uint? batchId, dynamic POs)
        {
            if (batchId == null || batchId == 0) throw new Exception("Missing Batch ID required to insert POs into");

            SqlParameter _co = new SqlParameter("@co", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _po = new SqlParameter("@PO", SqlDbType.VarChar, 30)
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
                SqlValue = batchId
            };
            List<string> lstFailed = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspPOCloseInsert", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;

                        if (POs.GetType() == typeof(Object[,]))
                        {
                            for (int n = 0; n < POs.GetUpperBound(0); n++)
                            {
                                if (POs[n + 1, 1] == null) continue;

                                _po.SqlValue = POs[n + 1, 1];
                                _cmd.Parameters.Add(_co);
                                _cmd.Parameters.Add(_po);
                                _cmd.Parameters.Add(_mth);
                                _cmd.Parameters.Add(_status);
                                _cmd.Parameters.Add(_batchId);
                                _cmd.CommandTimeout = 600;
                                if (_cmd.ExecuteNonQuery() == 0)
                                {
                                    lstFailed = lstFailed ?? new List<string>();
                                    lstFailed.Add(_po.Value.ToString());
                                }
                                _cmd.Parameters.Clear();
                            }
                        }
                        else
                        {
                            _po.SqlValue = POs;
                            _cmd.Parameters.Add(_co);
                            _cmd.Parameters.Add(_po);
                            _cmd.Parameters.Add(_mth);
                            _cmd.Parameters.Add(_status);
                            _cmd.Parameters.Add(_batchId);
                            _cmd.CommandTimeout = 600;
                            if (_cmd.ExecuteNonQuery() == 0)
                            {
                                lstFailed = lstFailed ?? new List<string>();
                                lstFailed.Add(_po.Value.ToString());
                            }
                            _cmd.Parameters.Clear();
                        }
                    }
                } // close connection

                return lstFailed;
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                _co = null;
                _po = null;
                _mth = null;
                _status = null;
                _batchId = null;
            }
        }
    }
}
