using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class ContractJobJectNonLabor
    {
        public static DataTable GetContractJobJectDetTable(int? Company, string JobId, string Pivot)
        {
            DataTable resultTable = new DataTable();

            //string _sql = "select * from mers.mfnContractProjectPhaseCostTypeProjectionSum(@JCCo, @Contract, @Job, @ProjectionMonth)";
            string _sql = "exec mers.mspGetCostProjectionPivot_Dyn @JCCo, @Job, @Pivot";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            SqlParameter _pivot = new SqlParameter("@Pivot", SqlDbType.VarChar, 5);

            if (Company == null)
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

            if (Pivot == null)
            {
                _pivot.SqlValue = "MONTH";
            }
            else
            {
                _pivot.SqlValue = Pivot;
            }
            
            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_job);
                _cmd.Parameters.Add(_pivot);
                _cmd.CommandTimeout = 900;

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "Job_Projection_Pivot_" + string.Format("Job_{0}", JobId.Trim().Replace("-","_") ) ;
            }
            catch (Exception e)
            {
                throw new Exception("GetContractJobs Exception", e);
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
