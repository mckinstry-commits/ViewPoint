using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class Batch
    {

        /// <summary>
        /// Process all records in batch and return processed count
        /// </summary>
        /// <param name="batchId">Batch Id of current Craft Class Update</param>
        /// <returns>Records processed count</returns>
        public static bool Validate(uint? batchId)
        {
            if (batchId == null) throw new Exception("Missing required Batch ID to process users");

            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId // 'Value' will get assigned but that's okay, it will use 'Value'
            };

            SqlCommand _cmd = null;
            bool success;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (_cmd = new SqlCommand("dbo.MCKspPRClassRateVal", _conn))
                    {
                        CancelToken.Token.ThrowIfCancellationRequested();
                        CancelToken.Token.Register(() => _cmd?.Cancel());

                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_batchId);
                        _cmd.CommandTimeout = 3600; // 1 hour

                        success = Convert.ToBoolean(_cmd.ExecuteScalar());
                    }
                } 
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Batch.Validate");
                throw ex;
            }
            finally
            {
                _batchId = null;
            }
            //returns zero if null
            return success;
        }
    }
}

