using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class POReport
    {
        public static DataTable POreport(byte Company, string job)
        {
            string _sql = "select * from mers.mfnJCPRGSummary (@JCCo,@Job)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = Company != 0 ? Company: (object)DBNull.Value;

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            _job.SqlValue = job != null ? job: (object)DBNull.Value;

            DataTable resultTable = new DataTable();

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd = null;

            try
            {
                _conn.Open();

                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_job);

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "POReport";
            }
            catch (Exception e) { throw new Exception("POReport Exception", e); }
            finally
            {
                HelperData.SqlCleanup(out _sql, out _cmd, _conn);
            }

            return resultTable;
        }
    }
}
