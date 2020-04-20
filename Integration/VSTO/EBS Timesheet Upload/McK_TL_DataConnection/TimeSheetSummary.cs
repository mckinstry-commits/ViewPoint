using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class TimeSheetSummary
    {
        public static List<dynamic> GetTimeSheetSummary()
        {
            List<dynamic> table = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspEBSTimesheetTotals", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 600;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            table = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    string type = reader.GetFieldType(field).FullName;
                                    row.Add(reader.GetName(field), new KeyValuePair<string, object>(type, reader[field]));
                                }
                                table.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception) { throw; }

            return table;
        }
    }
}

