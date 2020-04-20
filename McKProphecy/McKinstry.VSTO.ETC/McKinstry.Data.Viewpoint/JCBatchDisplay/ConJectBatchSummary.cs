using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class ConJectBatchSummary
    {
        public static DataTable GetConJectBatchSumTable(byte Company, string Contract, DateTime ProjMonth)
        {
            DataTable resultTable = new DataTable();

            string _sql = "select * from dbo.mfnGetRevProjBatch(@JCCo, @Contract, @Month);";
            //string _sql = "EXEC mers.mspGetRevProjBatchPivot @JCCo=@JCCo, @Contract=@Contract;";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = Company != 0 ? Company : (object)DBNull.Value;

            SqlParameter _job = new SqlParameter("@Contract", SqlDbType.VarChar, 10);
            _job.SqlValue = Contract != null? Contract : (object)DBNull.Value;

            SqlParameter _month = new SqlParameter("@Month", SqlDbType.DateTime);
            _month.SqlValue = ProjMonth != null ? ProjMonth : (object)DBNull.Value;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_job);
                        _cmd.Parameters.Add(_month);
                        _cmd.CommandTimeout = 900;

                        using (SqlDataAdapter _da = new SqlDataAdapter(_cmd))
                        {
                            _da.Fill(resultTable);
                            resultTable.TableName = "Revenue_Projection_" + Contract.Trim().Replace("-", "_");
                            return resultTable;
                        }
                    }
                }
            }
            catch (Exception) { throw; }
        }
    }
}
