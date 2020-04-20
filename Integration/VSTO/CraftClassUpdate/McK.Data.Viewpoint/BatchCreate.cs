using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class Batch
    {
        /// <summary>
        /// Creates a batch associated w/ the updates on the 'Staging' tables 
        /// </summary>
        /// <param name="JCCo"></param>
        /// <returns>Batch ID</returns>
        public static uint? CreateBatch()
        {
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

                    using (var _cmd = new SqlCommand("dbo.MCKspPRClassRateBatch", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_batchId);
                        _cmd.CommandTimeout = 600;
                        _cmd.ExecuteScalar();
                        return Convert.ToUInt32(_batchId.Value); //returns zero if null
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Batch.CreateBatch");
                throw ex;
            }
            finally
            {
                _batchId = null;
            }
        }
    }
}
