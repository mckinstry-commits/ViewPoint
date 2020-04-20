using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class ContractRefresh
    {
        public static DataTable GetContractPostRefresh(byte Company, string ContractId)
        {
            DataTable resultTable = new DataTable();

            //string _sql = String.Format("select JCCo, Job, Description as JobDescription from JCJM where JCCo in (1,20) and Contract='{0}' order by JCCo, Job", ContractId);

            string _sql = "select * from mers.mckfnContractPostRefresh (@JCCo,@Contract)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = Company != 0 ? Company : (object)DBNull.Value;

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);
            _contract.SqlValue = ContractId == null ? (object)DBNull.Value : ContractId;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_contract);
                        _cmd.CommandTimeout = 60;

                        using (SqlDataAdapter _da = new SqlDataAdapter(_cmd))
                        {
                            _da.Fill(resultTable);
                            resultTable.TableName = "ContractRefresh";
                            return resultTable;
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetContractPostRefresh\n" + e.Message, e); }
        }
    }
}
