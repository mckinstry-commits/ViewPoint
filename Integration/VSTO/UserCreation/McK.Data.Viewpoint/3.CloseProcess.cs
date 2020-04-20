using McK.Data.Viewpoint;
using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class UserCreationProcess
    {
        /// <summary>
        /// This will process the records and return the count which needs to displayed in VSTO panel
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="role"></param>
        /// <param name="batchId"></param>
        /// <returns>records processed count</returns>
        public static uint? MCKspVPUserCreationProcess(byte JCCo, uint? batchId)
        {
            if (batchId == 0 || batchId == null) throw new Exception("Missing required Batch ID to process users");

            SqlParameter _co = new SqlParameter("@co", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId
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

                    using (var _cmd = new SqlCommand("dbo.MCKspVPUserCreationProcess", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.Parameters.Add(_cnt);
                        _cmd.CommandTimeout = 600;
                        _cmd.ExecuteNonQuery();

                        return (uint?)Convert.ToUInt32(_cnt.Value); //returns zero if null
                    }
                } 
            }
            catch (Exception)
            {
                throw; // to UI
            }
            finally
            {
                _cnt = null;
                _co = null;
                _batchId = null;
            }
        }
    }
}
