using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class JobJectBatchSummary
    {
        public static DataTable GetJobJectBatchSummaryTable(byte Company, string JobId, DateTime Month)
        {
            DataTable resultTable = new DataTable();

            string _sql = "SELECT * FROM dbo.mfnJCProjPhaseSummary (@JCCo, @Job, @Month) ORDER BY 3, 5";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = Company != 0 ? Company : (object)DBNull.Value;

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            _job.SqlValue = JobId != null ? JobId : (object)DBNull.Value;

            SqlParameter _bMonth = new SqlParameter("@Month", SqlDbType.Date);
            _bMonth.SqlValue = Month != null ? Month : (object)DBNull.Value;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    SqlCommand _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_job);
                    _cmd.Parameters.Add(_bMonth);
                    _cmd.CommandTimeout = 900;

                    SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                    _da.Fill(resultTable);
                    resultTable.TableName = "Projection_Summary_" + string.Format("Job_{0}", JobId.Trim().Replace("-", "_"));
                }
            }
            catch (Exception e)
            {
                throw new Exception("GetJobJectBatchSummaryTable: " + e.Message, e);
            }

            return resultTable;
        }
    }
}
