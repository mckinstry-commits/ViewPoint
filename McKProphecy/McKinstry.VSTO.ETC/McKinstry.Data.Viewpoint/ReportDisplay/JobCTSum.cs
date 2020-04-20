using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class JobCTSum
    {
        public static DataTable GetJobCTSumTable(int? Company, string ContractId, string JobId, DateTime ThroughMth)
        {
            DataTable resultTable = new DataTable();

            string _sql = "select * from dbo.mfnProjectCTSum(@JCCo, @Contract, @Job, @ThroughMth)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = Company != 0 ? Company : (object)DBNull.Value;

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);
            _contract.SqlValue = ContractId == null ? (object)DBNull.Value : ContractId;

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            _job.SqlValue = JobId != null ? JobId : (object)DBNull.Value;

            SqlParameter _Mth = new SqlParameter("@ThroughMth", SqlDbType.DateTime);
            _Mth.SqlValue = ThroughMth != null ? ThroughMth: (object)DBNull.Value;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_contract);
                        _cmd.Parameters.Add(_job);
                        _cmd.Parameters.Add(_Mth);
                        _cmd.CommandTimeout = 900;

                        using (SqlDataAdapter _da = new SqlDataAdapter(_cmd))
                        {
                            _da.Fill(resultTable);
                            resultTable.TableName = "CostType_Sum_" + string.Format("Job_{0}", JobId.Trim().Replace("-", "_"));
                            return resultTable;
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetJobCTSumTable:\n" + e.Message, e); }
        }
    }
}
