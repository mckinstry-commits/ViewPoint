using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace McK.Data.Viewpoint
{
    public static class Batch
    {
        /// <summary>
        /// Get last batch number created 
        /// </summary>
        /// <returns>Errors list, if any</returns>
        public static string GetLastBatchNum()
        {
            string batchCreated = "" ;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand("Select ISNULL(MAX(ISNULL(CAST(BatchNum AS INT),0)), 1) FROM dbo.MCKWOCloseStage;", _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        batchCreated = _cmd.ExecuteScalar().GetType() == typeof(DBNull) ? "Error" : _cmd.ExecuteScalar().ToString();
                    }
                }
            }
            catch (Exception) { throw; } // to UI
            return batchCreated;
        }
    }
}
