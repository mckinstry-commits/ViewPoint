using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class JobJectBatchSummary
    {
        public static DataTable GetJobJectBatchSummaryTable(byte Company, string JobId, DateTime Month)
        {
            DataTable resultTable = new DataTable();

            string _sql = "SELECT * FROM mers.mfnJCProjPhaseSummary (@JCCo, @Job, @Month) ORDER BY 3, 5";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            SqlParameter _bMonth = new SqlParameter("@Month", SqlDbType.Date);

            if (Company == 0)
            {
                _co.SqlValue = DBNull.Value;
            }
            else
            {
                _co.SqlValue = Company;
            }

            if (JobId == null)
            {
                _job.SqlValue = DBNull.Value;
            }
            else
            {
                _job.SqlValue = JobId;
            }

            if (Month == null)
            {
                _bMonth.SqlValue = "01-JUL-2016";
            }
            else
            {
                _bMonth.SqlValue = Month;
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_job);
                _cmd.Parameters.Add(_bMonth);
                _cmd.CommandTimeout = 600000;

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "Projection_Summary_" + string.Format("Job_{0}", JobId.Trim().Replace("-", "_"));
            }
            catch (Exception e)
            {
                throw new Exception("Batch_Projection_Pivot Exception", e);
            }
            finally
            {
                if (!(_conn.State == ConnectionState.Closed))
                {
                    _conn.Close();
                }
                _conn = null;
            }

            return resultTable;
        }
    }
}
