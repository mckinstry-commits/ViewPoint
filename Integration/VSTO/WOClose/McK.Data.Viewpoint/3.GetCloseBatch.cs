using McK.Data.Viewpoint;
using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class CloseBatch
    {
        /// <summary>
        /// Creates a batch to associate WOs with
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="mth"></param>
        /// <param name="closeType"></param>
        /// <returns>A Batch ID to associate unit of work</returns>
        public static uint? MCKspWOCloseBatch(byte JCCo, string mth, char closeType)
        {
            SqlParameter _co = new SqlParameter("@co", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _mth = new SqlParameter("@month", SqlDbType.DateTime)
            {
                SqlValue = mth ?? (object)DBNull.Value
            };
            SqlParameter _status = new SqlParameter("@Istatus", SqlDbType.TinyInt)
            {
                SqlValue = closeType != '\0' ? closeType : (object)DBNull.Value
            };
            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = DBNull.Value,
                Direction = ParameterDirection.Output
            };

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspWOCloseBatch", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_mth);
                        _cmd.Parameters.Add(_status);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.CommandTimeout = 600;
                        _cmd.ExecuteScalar();

                        return (uint?)Convert.ToUInt32(_batchId.Value); //returns zero if null
                    }
                }
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                _co = null;
                _mth = null;
                _status = null;
            }
        }
    }
}
