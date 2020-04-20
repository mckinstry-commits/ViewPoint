using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class CloseInsert
    {
        /// <summary>
        /// This will insert the data in the grid to table -- MCKWOCloseStage which also acts as a history/audit table
        /// A batch is created to associate WOS
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="mth"></param>
        /// <param name="WOs"></param>
        /// <returns>list of failed contracts inserts</returns>
        public static void MCKspWOCloseInsert(byte JCCo, string mth, dynamic WOs)
        {
            SqlParameter _co = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _wo = new SqlParameter("@WO", SqlDbType.VarChar, 30)
            {
                SqlValue = DBNull.Value
            };
            SqlParameter _mth = new SqlParameter("@BatchMonth", SqlDbType.DateTime)
            {
                SqlValue = mth ?? (object)DBNull.Value
            };


            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspWOCloseInsert", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;

                        if (WOs.GetType() == typeof(Object[,]))
                        {
                            for (int n = 0; n < WOs.GetUpperBound(0); n++)
                            {
                                if (WOs[n + 1, 1] == null) continue;

                                _wo.SqlValue = WOs[n + 1, 1];
                                _cmd.Parameters.Add(_co);
                                _cmd.Parameters.Add(_wo);
                                _cmd.Parameters.Add(_mth);
                                _cmd.CommandTimeout = 600;
                                _cmd.ExecuteNonQuery();

                                
                                _cmd.Parameters.Clear();
                            }
                        }
                        else
                        {
                            _wo.SqlValue = WOs;
                            _cmd.Parameters.Add(_co);
                            _cmd.Parameters.Add(_wo);
                            _cmd.Parameters.Add(_mth);
                            _cmd.CommandTimeout = 600;
                            _cmd.ExecuteNonQuery();
                            _cmd.Parameters.Clear();
                        }
                    }
                } // close connection
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                _co = null;
                _wo = null;
                _mth = null;
            }
        }
    }
}
