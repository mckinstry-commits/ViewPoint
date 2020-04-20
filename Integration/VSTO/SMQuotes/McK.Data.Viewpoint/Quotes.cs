using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class Quotes
    {
        /// <summary>
        /// Get all Quotes numbers
        /// </summary>
        /// <remarks>Use SheetBuilderDynamic.cs to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetQuoteList()
        {
            string sql_select = "SELECT DISTINCT Q.WorkOrderQuote " + 
                                "FROM Viewpoint.dbo.SMWorkOrderQuoteExt X " +
                                    "INNER JOIN vrvSMWorkOrderQuote Q ON X.SMCo = Q.SMCo AND X.WorkOrderQuote = Q.WorkOrderQuote; ";
            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    tableOut = new List<dynamic>();

                    using (var _cmd = new SqlCommand(sql_select, _conn))
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
                ex.Data.Add(0, "Quotes.GetQuoteList");
                throw ex;
            }
            return tableOut;
        }

    }
}
