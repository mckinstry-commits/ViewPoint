using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class ContractItem
    {
        public static DataTable GetContractItemTable(byte Company, string ContractId, DateTime ProjectionMonth)
        {

            DataTable resultTable = new DataTable();

            //string _sql = String.Format("select JCCo, Job, Description as JobDescription from JCJM where JCCo in (1,20) and Contract='{0}' order by JCCo, Job", ContractId);

            string _sql = "select * from mers.mfnContractItemProjectionSum(@JCCo,@Contract,@ProjectionMonth)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar,10);
            SqlParameter _projmonth = new SqlParameter("@ProjectionMonth", SqlDbType.DateTime);

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

            if (ProjectionMonth == null)
            {
                _projmonth.SqlValue = DBNull.Value;
            }
            else
            {
                _projmonth.SqlValue = ProjectionMonth;
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_contract);
                _cmd.Parameters.Add(_projmonth);

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "ContractItems";
            }
            catch (Exception e)
            {
                throw new Exception("GetContractItems Exception", e);
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
