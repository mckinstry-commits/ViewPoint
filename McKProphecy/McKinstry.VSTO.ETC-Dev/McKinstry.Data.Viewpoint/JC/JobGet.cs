using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class Jobs
    {
        public static DataTable GetJobs(string ContractId)
        {
            DataTable resultTable = new DataTable();

            string _sql = "select * from mers.mfnJobSelectorList (@Contract)";

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);


            if (ContractId == null)
            {
                _contract.SqlValue = DBNull.Value;
            }
            else
            {
                _contract.SqlValue = ContractId;
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_contract);

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
