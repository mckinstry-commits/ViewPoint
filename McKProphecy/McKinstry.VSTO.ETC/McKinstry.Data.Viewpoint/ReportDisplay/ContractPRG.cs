using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class ContractPRG
    {
        public static DataTable GetContractPRGTable(byte Company, string ContractId)
        {
            DataTable resultTable = new DataTable();
            //string _sql = String.Format("select JCCo, Job, Description as JobDescription from JCJM where JCCo in (1,20) and Contract='{0}' order by JCCo, Job", ContractId);

            string _sql = "select * from mers.mfnJCPRGSummary (@JCCo,@Contract) ORDER BY PRG";

            // TEST TIMEOUT: 
            //string _sql = "DECLARE @i int WHILE EXISTS (SELECT 1 from sysobjects) BEGIN SELECT @i = 1 END";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = Company != 0 ? Company : (object)DBNull.Value
            };

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10)
            {
                SqlValue = ContractId ?? (object)DBNull.Value
            };

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

                        //_cmd.ExecuteNonQuery(); // This line will timeout.

                        using (SqlDataAdapter _da = new SqlDataAdapter(_cmd))
                        {
                            _da.Fill(resultTable);
                            resultTable.TableName = "ContractPRG";
                        }
                    }
                }
            }
            catch( SqlException ex)
            {
                if (ex.Number == -2)
                {
                    //handle timeout
                    throw new Exception("It's possible the WIP may be refreshing." , ex);
                }
            }
            catch (Exception ex)
            {
                throw new Exception("GetContractPRGTable:\n" + ex.Message, ex);
            }
            return resultTable;
        }
    }
}
