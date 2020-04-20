using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class JobJectBatchLabor
    {
        public static DataTable GetJobJectBatchLaborTable(byte Company, string JobId, string Pivot)
        {
            DataTable resultTable = new DataTable();
            
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = Company != 0 ? Company : (object)DBNull.Value
            };

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10)
            {
                SqlValue = JobId ?? (object)DBNull.Value
            };

            SqlParameter _pivot = new SqlParameter("@Pivot", SqlDbType.VarChar, 5)
            {
                SqlValue = Pivot ?? "WEEK"
            };

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand("dbo.mspGetJCProjHrsDyn", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_job);
                        _cmd.Parameters.Add(_pivot);
                        _cmd.CommandTimeout = 900;

                        using (SqlDataAdapter _da = new SqlDataAdapter(_cmd))
                        {
                            _da.Fill(resultTable);
                            resultTable.TableName = "Projected_Labor_Pivot_" + string.Format("Job_{0}", JobId.Trim().Replace("-", "_"));
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetJobJectBatchLaborTable:\n" + e.Message, e); }

            return resultTable;
        }
    }
}
