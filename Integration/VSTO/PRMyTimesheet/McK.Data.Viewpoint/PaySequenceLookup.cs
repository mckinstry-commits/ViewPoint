using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.Data.Viewpoint
{
    public static class PaySequenceLookup
    {
        public static List<dynamic> GetPaySequences()
        {
            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("Select PaySeq, Description from dbo.udStandardPS", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            tableOut = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    // get type name
                                    string type = reader.GetFieldType(field).FullName;

                                    // ROW: Column Name | data type | value
                                    row.Add(reader.GetName(field), new KeyValuePair<string, object>(type, reader[field]));
                                }
                                tableOut.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "PaySequenceLookup.GetPaySequences");
                throw ex;
            }
            return tableOut;
        }
    }
}
