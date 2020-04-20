using McK.Data.Viewpoint;
using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class UserCreationBatch
    {
        /// <summary>
        /// This will create the batch to display on panel
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="role"></param>
        /// <returns>Users Batch ID</returns>
        public static uint? MCKspVPUserCreationBatch(byte JCCo, string role)
        {
            SqlParameter _co = new SqlParameter("@co", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
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

                    using (var _cmd = new SqlCommand("dbo.MCKspVPUserCreationBatch", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_co);
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
                _batchId = null;
                _co = null;
            }
        }
    }
}
