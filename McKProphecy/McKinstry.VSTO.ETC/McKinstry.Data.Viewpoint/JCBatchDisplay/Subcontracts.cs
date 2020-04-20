using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using McKinstry.Data.Models.Viewpoint;
using System.Dynamic;

namespace McKinstry.Data.Viewpoint
{
    public class Subcontracts
    {
        public static List<dynamic> GetSubcontracts(string job)
        {
            string _sql = "Select * From dbo.mckfnSLSubByJob(@Job);";

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10)
            {
                SqlValue = job ?? (object)DBNull.Value
            };

            List<dynamic> subcontracts = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_job);
                        _cmd.CommandTimeout = 300;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            subcontracts = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount-1; field++)
                                {
                                    string type = reader.GetFieldType(field).FullName;
                                    int dot = type.IndexOf('.') + 1;
                                       type = type.Substring(dot, type.Length - dot);
                                    row.Add(reader.GetName(field), new KeyValuePair<string, object>(type, reader[field]));
                                }
                                subcontracts.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetSubcontracts: " + e.Message); }

            return subcontracts;
        }
    }
}
