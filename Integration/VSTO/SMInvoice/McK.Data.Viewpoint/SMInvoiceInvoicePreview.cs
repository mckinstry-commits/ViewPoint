using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class SMInvoiceInvoicePreview
    {
        /// <summary>
        /// Get SM Invoice table for Invoice Preview
        /// </summary>
        /// <param name="invoicePreviewList"></param>
        /// <remarks>Use SheetBuilderDynamic.cs to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetInvoicePreview(dynamic invoicePreviewList)
        {
            SqlParameter _invoicePreviewList = new SqlParameter("@InvoicePreviewList", SqlDbType.Structured)
            {
                SqlValue = invoicePreviewList,
                TypeName = "dbo.McKtyInvoicePreview"
            };

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("dbo.McKspSMWorkOrderBillingInvoiceNoSession", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_invoicePreviewList);

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
                ex.Data.Add(0, "SMInvoiceInvoicePreview.GetInvoicePreview");
                throw ex;
            }
            return tableOut;
        }

    }
}
