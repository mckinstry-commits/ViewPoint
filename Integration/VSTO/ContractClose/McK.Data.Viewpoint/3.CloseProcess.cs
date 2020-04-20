using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class CloseProcess
    {
        /// <summary>
        /// This will process the records and return the count which needs to displayed in VSTO panel
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="mth"></param>
        /// <param name="closeType"></param>
        /// <param name="batchId"></param>
        /// <returns>records processed count</returns>
        public static int MCKspContractCloseProcess(byte JCCo, string mth, char closeType, uint? batchId)
        {
            if (batchId == 0 || batchId == null) throw new Exception("Missing Batch ID required to process Contracts");

            //const string _sql = @"EXEC dbo.MCKspContractCloseProcess @co=@co, @month=@mth, @Istatus=@status, @Rbatchid=@batchId, @Count=@count output;";

            SqlParameter _co = new SqlParameter("@co", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
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
                SqlValue = batchId != 0 ? batchId : (object)DBNull.Value
            };
            SqlParameter _cnt = new SqlParameter("@Count", SqlDbType.Int)
            {
                SqlValue = DBNull.Value,
                Direction = ParameterDirection.Output
            };

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspContractCloseProcess", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_mth);
                        _cmd.Parameters.Add(_status);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.Parameters.Add(_cnt);
                        _cmd.CommandTimeout = 600;
                        _cmd.ExecuteNonQuery();

                        return _cnt.Value == null ? 0 : (int)_cnt.Value;
                    }
                }
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                _co = null;
                _mth = null;
                _status = null;
                _batchId = null;
            }
        }
    }
}
