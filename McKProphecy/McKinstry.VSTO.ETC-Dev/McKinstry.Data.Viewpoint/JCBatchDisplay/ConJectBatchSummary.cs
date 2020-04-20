using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class ConJectBatchSummary
    {
        public static DataTable GetConJectBatchSumTable(byte Company, string Contract, DateTime ProjMonth)
        {
            DataTable resultTable = new DataTable();

            string _sql = "select * from mers.mfnGetRevProjBatch(@JCCo, @Contract, @Month);";
            //string _sql = "EXEC mers.mspGetRevProjBatchPivot @JCCo=@JCCo, @Contract=@Contract;";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _job = new SqlParameter("@Contract", SqlDbType.VarChar, 10);
            SqlParameter _month = new SqlParameter("@Month", SqlDbType.DateTime);

            if (Company == 0)
            {
                _co.SqlValue = DBNull.Value;
            }
            else
            {
                _co.SqlValue = Company;
            }

            if (Contract == null)
            {
                _job.SqlValue = DBNull.Value;
            }
            else
            {
                _job.SqlValue = Contract;
            }

            if (ProjMonth == null)
            {
                _month.SqlValue = DBNull.Value;
            }
            else
            {
                _month.SqlValue = ProjMonth;
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd = null;

            try
            {
                _conn.Open();

                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_job);
                _cmd.Parameters.Add(_month);
                _cmd.CommandTimeout = 600000;

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "Revenue_Projection_" + string.Format("Job_{0}", Contract.Trim().Replace("-", "_"));
                _da = null;
            }
            catch (Exception) { throw; }
            finally { HelperData.SqlCleanup(out _sql, out _cmd, _conn); }

            return resultTable;
        }
    }
}
