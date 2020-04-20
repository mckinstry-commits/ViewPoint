using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class ContractList
    {
        public static DataTable GetContractList(byte? JCCo, string contract)
        {
            DataTable resultTable = new DataTable();
            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value;

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);
            _contract.SqlValue = contract != null ? contract : (object)DBNull.Value;

            string _sql = "select * from mers.mfnContractJobSelector (@JCCo, @Contract);";

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                SqlDataAdapter _da = new SqlDataAdapter(_cmd);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_contract);

                _da.Fill(resultTable);
                resultTable.TableName = "ContractList";
            }
            catch (Exception e)
            {
                throw new Exception("GetContractList: " +  e.Message);
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
