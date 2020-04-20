using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class DivisionCenters
    {
        public static List<dynamic> GetDivisionServiceCenters(dynamic division = null)
        {
            SqlParameter _division = new SqlParameter("@Division", System.Data.SqlDbType.VarChar, 10)
            {
                SqlValue = division ?? DBNull.Value
            };

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    tableOut = new List<dynamic>();

                    using (var _cmd = new SqlCommand("Select * from mckfnDivisionServiceCenters(@Division);", _conn))
                    {
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_division);

                        using (var reader = _cmd.ExecuteReader())
                        {
                            if (reader.HasRows)
                            {
                                var rowAny = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;
                                rowAny.Add("Division", "Any");
                                rowAny.Add("ServiceCenter", "Any");
                                rowAny.Add("ServiceCenterDescription", "Any");

                                tableOut = new List<dynamic>
                                {
                                    rowAny
                                };

                                while (reader.Read())
                                {
                                    var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                    for (int field = 0; field <= reader.FieldCount - 1; field++)
                                    {
                                        // Column Name | Value
                                        row.Add(reader.GetName(field), reader[field]);
                                    }
                                    tableOut.Add(row);
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("DivisionCenters.GetDivisionServiceCenters: \n" + e.Message); }
            return tableOut;
        }
    }
}
