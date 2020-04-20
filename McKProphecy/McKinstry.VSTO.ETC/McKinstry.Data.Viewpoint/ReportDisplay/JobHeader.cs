using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class JobHeader
    {
        public static DataTable GetJobHeaderTable(int? JCCo, string JobId)
        {
            DataTable resultTable = new DataTable();

            string _sql = "select * from dbo.mfnJobHeaderSM(@JCCo, @Job)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10)
            {
                SqlValue = JobId ?? (object)DBNull.Value
            };
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
                            resultTable.TableName = "Job_Header_" + string.Format("Job_{0}", JobId.Trim().Replace("-", "_"));
                            return resultTable;
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetJobHeaderTable:\n" + e.Message, e); }
        }
    }
}
