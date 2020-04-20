using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class JobParentPhaseSum
    {
        public static DataTable GetJobParentPhaseSumTable(int? JCCo, string JobId)
        {
            DataTable resultTable = new DataTable();

            string _sql = "Select * from mers.mfnJCParentPhaseSummary(@JCCo, @Job) ORDER BY 1";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value;

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            _job.SqlValue = JobId != null ? JobId : (object)DBNull.Value; 

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_job);
                        _cmd.CommandTimeout = 900;

                        using (SqlDataAdapter _da = new SqlDataAdapter(_cmd))
                        {
                            _da.Fill(resultTable);
                            resultTable.TableName = "ParentPhaseSum_" + string.Format("Job_{0}", JobId.Trim().Replace("-", "_"));
                            return resultTable;
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("ParentPhaseSum Exception", e); }
        }
    }
}
