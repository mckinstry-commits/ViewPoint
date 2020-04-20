using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class ContractHeader
    {
        public static DataTable GetContractHeaderTable(byte? JCCo, string ContractId)
        {
            DataTable resultTable = new DataTable();

            //string _sql = String.Format("select JCCo, Job, Description as JobDescription from JCJM where JCCo in (1,20) and Contract='{0}' order by JCCo, Job", ContractId);
            //string _sql = string.Format("select * from mers.mfnContractHeader(null,'{0}')", ContractId);
            string _sql = "select * from mers.mfnContractHeader(@JCCo, @Contract)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);

            _co.Value = DBNull.Value;

            if (JCCo == null)
            {
                _co.SqlValue = DBNull.Value;
            }
            else
            {
                _co.SqlValue = JCCo;
            }

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
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_contract);

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "ContractHeader";
            }
            catch (Exception e)
            {
                throw new Exception("GetContractHeader Exception", e);
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

        public static DataTable GetContractKey(string ContractId)
        {

            DataTable resultTable = new DataTable();

            string _sql = "select JCCo, Contract from dbo.JCCM where JCCo < 100 and Contract=@Contract";

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
                resultTable.TableName = "ContractKey";
            }
            catch (Exception e)
            {
                throw new Exception("ContractKey Exception", e);
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
