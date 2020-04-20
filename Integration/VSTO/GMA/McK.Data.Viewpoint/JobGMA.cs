using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public class JobGMA
    {
        public static List<dynamic> GetJobGMATable(int? Company, string JobId)
        {
            string _sql = "select * from dbo.mfnGetGMAXData(@JCCo, @Job)";
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = Company ?? (object)DBNull.Value
            };
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10)
            {
                SqlValue = JobId ?? (object)DBNull.Value
            };
            List<dynamic> jobs = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_job);
                        _cmd.CommandTimeout = 600;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            jobs = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    row.Add(reader.GetName(field), reader[field]);
                                }
                                jobs.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0,"GetJobGMATable");
                throw ex;
            }
            return jobs;
        }
    }
}
