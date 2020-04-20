using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class JobJectETC
    {
        public static List<dynamic> GetFullETC(string job, DateTime projectionMonth, uint batchId)
        {
            string _sql = @"SELECT z.FullETC, z.HoursWeeks from mers.ProphecyLog z 
                            WHERE z.Mth=@mth 
                            AND z.Job=@job 
                            AND (((z.Action='SAVE COST JECT') AND (z.BatchId=@batchId)) OR z.Action='POST COST')
                            AND z.DateTime = (Select MAX(z1.DateTime) 
                                              FROM mers.ProphecyLog z1 
                                              WHERE z1.Mth=z.Mth AND z1.Job=z.Job AND ((z1.Action='SAVE COST JECT' AND z1.BatchId=@batchId) OR z1.Action='POST COST'));";

            SqlParameter _job = new SqlParameter("@job", SqlDbType.VarChar, 10)
            {
                SqlValue = job != null ? job : (object)DBNull.Value
            };

            SqlParameter _jectmonth = new SqlParameter("@mth", SqlDbType.DateTime)
            {
                SqlValue = projectionMonth != null ? projectionMonth : (object)DBNull.Value
            };

            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int)
            {
                SqlValue = batchId != 0x0 ? batchId : (object)DBNull.Value
            };

            List<dynamic> table = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_job);
                        _cmd.Parameters.Add(_jectmonth);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.CommandTimeout = 900;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            table = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    row.Add(reader.GetName(field), reader[field]);
                                }
                                table.Add(row);
                            }

                            return table;
                        }
                    }
                }
            }
            catch (Exception) { throw; }
            finally
            {
                //_co = null;
                _job = null;
                _jectmonth = null;
                _batchId = null;
            }
        }
    }
}
