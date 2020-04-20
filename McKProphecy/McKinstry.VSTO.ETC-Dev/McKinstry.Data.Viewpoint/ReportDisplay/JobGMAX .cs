using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class JobGMAX
    {
        public static DataTable GetJobGMAXTable(int? Company, string JobId)
        {
            DataTable resultTable = new DataTable();

            string _sql = "select * from mers.mfnGetGMAXData(@JCCo, @Job)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);


            _co.SqlValue = Company == null ? (object)DBNull.Value : Company;
            _job.SqlValue = JobId == null ? (object)DBNull.Value : JobId;

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_job);
                _cmd.CommandTimeout = 600000;

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "Job_GMAX_" + string.Format("Job_{0}", JobId.Trim().Replace("-","_") );
            }
            catch (Exception e)
            {
                throw new Exception("GetJobGMAX Exception", e);
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
