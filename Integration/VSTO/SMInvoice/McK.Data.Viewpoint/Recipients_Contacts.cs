using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class Recipients
    {
        public static List<dynamic> GetDivServCenterContacts()
        {
            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    tableOut = new List<dynamic>();

                    using (var _cmd = new SqlCommand("Select Division, ServiceCenter, Email, PhoneNumber from udxrefSMFromEmail order by 1;", _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            if (reader.HasRows)
                            {
                                while (reader.Read())
                                {
                                    var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                    for (int field = 0; field <= reader.FieldCount - 1; field++)
                                    {
                                        string datatype = reader.GetFieldType(field).FullName;

                                        // Column Name | data type | value
                                        row.Add(reader.GetName(field), new KeyValuePair<string, object>(datatype, reader[field]));
                                    }
                                    tableOut.Add(row);
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("Recipients.GetDivServCenterContacts: \n" + e.Message); }
            return tableOut;
        }
    }
}
