using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class QuotesSearch
    {
        /// <summary>
        /// Get SM Quotes Summary 
        /// </summary>
        /// <param name="SMCo">SM Company</param>
        /// <param name="customer">SM Customer ID</param>
        /// <param name="workOrderQuote">Quote ID</param>
        /// <remarks>Use SheetBuilderDynamic.cs to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetQuotesDetailView(byte SMCo, int customer, string workOrderQuote, char quoteStatus)
        {
            SqlParameter _smco = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = SMCo != 0x0 ? SMCo : (object)DBNull.Value
            };
            SqlParameter _customer = new SqlParameter("@Customer", SqlDbType.Int)
            {
                SqlValue = customer != 0 ? customer : (object)DBNull.Value
            };
            SqlParameter _quoteID = new SqlParameter("@WorkOrderQuote", SqlDbType.VarChar, 10)
            {
                SqlValue = workOrderQuote ?? (object)DBNull.Value
            };
            SqlParameter _quoteStatus = new SqlParameter("@QuoteStatus", SqlDbType.Char)
            {
                SqlValue = quoteStatus != '\0' ? quoteStatus : (object)DBNull.Value
            };

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("Select * From dbo.mckfnGetSMQuotesDetailView(@SMCo, @Customer, @WorkOrderQuote, @QuoteStatus)", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_smco);
                        _cmd.Parameters.Add(_quoteStatus);
                        _cmd.Parameters.Add(_customer);
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
                ex.Data.Add(0, "QuotesSearch.GetQuoteDetailView");
                throw ex;
            }
            return tableOut;
        }

    }
}
