using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class QuotePreview
    {
        /// <summary>
        /// Get SM Quotes Detail 
        /// </summary>
        /// <param name="SMCo">SM Company</param>
        /// <param name="customer">SM Customer ID</param>
        /// <param name="workOrderQuote">Quote ID</param>
        /// <remarks>Use SheetBuilderDynamic.cs  to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetQuoteDetail(byte SMCo, string workOrderQuote)
        {
            SqlParameter _smco = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = SMCo != 0x0 ? SMCo : (object)DBNull.Value
            };
            SqlParameter _quoteID = new SqlParameter("@WorkOrderQuote", SqlDbType.VarChar, 10)
            {
                SqlValue = workOrderQuote ?? (object)DBNull.Value
            };

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("Select * From dbo.mckfnSMQuoteDetail(@SMCo, @WorkOrderQuote)", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_smco);
                        _cmd.Parameters.Add(_quoteID);

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
                ex.Data.Add(0, "QuotePreview.mckfnSMQuoteDetail");
                throw ex;
            }
            return tableOut;
        }

    }
}
