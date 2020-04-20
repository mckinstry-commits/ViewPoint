using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class CloseBatch
    {
        /// <summary>
        /// This will create the batch to display on panel
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="mth"></param>
        /// <param name="closeType"></param>
        /// <returns>Contract Batch ID</returns>
        public static uint? MCKspPOCloseBatch(byte JCCo, string mth, char closeType)
        {
            const string _sql = @"EXEC dbo.MCKspPOCloseBatch @co=@JCCo, @month=@mth, @Istatus=@status, @Rbatchid=@batchId output;";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value;

            SqlParameter _mth = new SqlParameter("@mth", SqlDbType.DateTime);
            _mth.SqlValue = mth != null ? mth : (object)DBNull.Value;

            SqlParameter _status = new SqlParameter("@status", SqlDbType.TinyInt);
            _status.SqlValue = closeType != '\0' ? closeType :  (object)DBNull.Value;

            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
            _batchId.SqlValue = DBNull.Value;
            _batchId.Direction = ParameterDirection.Output;

            SqlCommand _cmd;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_mth);
                    _cmd.Parameters.Add(_status);
                    _cmd.Parameters.Add(_batchId);
                    _cmd.CommandTimeout = 600;
                    _cmd.ExecuteScalar();

                    return (uint?)Convert.ToUInt32(_batchId.Value); //returns zero if null
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
                _status = null;
            }
        }
    }
}
