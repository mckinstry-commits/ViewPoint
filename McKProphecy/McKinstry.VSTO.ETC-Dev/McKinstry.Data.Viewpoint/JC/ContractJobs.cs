using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class ContractJobs
    {
        public static DataTable GetContractJobTable(byte Company, string ContractId, string JobId)
        {
            DataTable resultTable = new DataTable();

            string _sql = "select * from mers.mfnGetJobsList(@JCCo, @Contract, @Job)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            //SqlParameter _projmonth = new SqlParameter("@ProjectionMonth", SqlDbType.DateTime);

            if (Company == 0)
            {
                _co.SqlValue = DBNull.Value;
            }
            else
            {
                _co.SqlValue = Company;
            }

            if (ContractId == null)
            {
                _contract.SqlValue = DBNull.Value;
            }
            else
            {
                _contract.SqlValue = ContractId;
            }

            if (JobId == null)
            {
                _job.SqlValue = DBNull.Value;
            }
            else
            {
                _job.SqlValue = JobId;
            }


            //if (ProjectionMonth == null)
            //{
            //    _projmonth.SqlValue = DBNull.Value;
            //}
            //else
            //{
            //    _projmonth.SqlValue = ProjectionMonth;
            //}


            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_contract);
                _cmd.Parameters.Add(_job);
                //_cmd.Parameters.Add(_projmonth);

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "ContractProjects";
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
