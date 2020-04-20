using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class QuotePreview
    {
        /// <summary>
        /// Get the McKinstry contacts for the Quotes
        /// </summary>
        /// <remarks>Use SheetBuilderDynamic.cs to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetMcKQuoteContacts()
        {
            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    tableOut = new List<dynamic>();

                    using (var _cmd = new SqlCommand("SELECT Alias, FullName, Email, Phone FROM mckfnMcKQuoteContacts()", _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    string datatype = reader.GetFieldType(field).FullName;

                                    // field name | data type | value
                                    row.Add(reader.GetName(field), new KeyValuePair<string, object>(datatype, reader[field]));
                                }
                                tableOut.Add(row);
                            }
                        }
                        _cmd.Parameters.Clear();
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "QuotePreview.GetMcKQuoteContacts");
                throw ex;
            }
            return tableOut;
        }

    }
}
