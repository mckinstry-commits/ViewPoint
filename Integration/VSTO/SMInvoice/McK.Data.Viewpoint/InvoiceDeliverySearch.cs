using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class InvoiceDeliverySearch
    {
        /// <summary>
        /// Get SM Invoice table
        /// </summary>
        /// <param name="SMCo">SM Company</param>
        /// <param name="invoiceStatus">I-Invoiced , P-pending</param>
        /// <param name="printStatus">N-No Delivered , P-Delivered</param>
        /// <param name="billToCustomer">Customer #</param>
        /// <param name="invoiceStart">Invoice number start of range</param>
        /// <param name="invoiceEnd">Invoice number end of range</param>
        /// <param name="invoiceStartDate">Invoice date start of range</param>
        /// <param name="invoiceEndDate">Invoice date end of range</param>
        /// <param name="printStartDate">Delivered date start of range</param>
        /// <param name="printEndDat">Delivered date end of range</param>
        /// <param name="invoiceList"></param>
        /// <remarks>Use SheetBuilderDynamic.cs to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetInvoices(byte SMCo, char invoiceStatus, char printStatus, int billToCustomerID, string invoiceStart, string invoiceEnd, dynamic invoiceList, 
                                                string division, dynamic serviceCenter)
        {
            SqlParameter _smco = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = SMCo != 0x0 ? SMCo : (object)DBNull.Value
            };

            SqlParameter _invoiceStatus = new SqlParameter("@InvoiceStatus", SqlDbType.Char)
            {
                SqlValue = invoiceStatus != '\0' ? invoiceStatus : (object)DBNull.Value
            };

            SqlParameter _printStatus = new SqlParameter("@PrintStatus", SqlDbType.Char)
            {
                SqlValue = printStatus != '\0' ? printStatus : (object)DBNull.Value
            };

            SqlParameter _billToCustomerID = new SqlParameter("@BillToCustomer", SqlDbType.Int)
            {
                SqlValue = billToCustomerID != 0 ? billToCustomerID : (object)DBNull.Value
            };

            SqlParameter _divison = new SqlParameter("@Division", SqlDbType.VarChar, 10)
            {
                SqlValue = division ?? (object)DBNull.Value
            };

            SqlParameter _serviceCenter = new SqlParameter("@ServiceCenter", SqlDbType.VarChar, 10)
            {
                SqlValue = serviceCenter ?? (object)DBNull.Value
            };

            SqlParameter _invoiceStart = new SqlParameter("@InvoiceStart", SqlDbType.VarChar, 10)
            {
                SqlValue = invoiceStart ?? (object)DBNull.Value
            };

            SqlParameter _invoiceEnd = new SqlParameter("@InvoiceEnd", SqlDbType.VarChar, 10)
            {
                SqlValue = invoiceEnd ?? (object)DBNull.Value
            };

            SqlParameter _invoiceList = new SqlParameter("@InvoiceList", SqlDbType.Structured)
            {
                SqlValue = invoiceList,
                TypeName = "dbo.McKtyInvoiceList"
            };


            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("dbo.McKspSMInvoiceDeliverySearch", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_smco);
                        _cmd.Parameters.Add(_invoiceStatus);
                        _cmd.Parameters.Add(_printStatus);
                        _cmd.Parameters.Add(_billToCustomerID);
                        _cmd.Parameters.Add(_invoiceStart);
                        _cmd.Parameters.Add(_invoiceEnd);
                        _cmd.Parameters.Add(_invoiceList);
                        _cmd.Parameters.Add(_divison);
                        _cmd.Parameters.Add(_serviceCenter);

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
                ex.Data.Add(0, "InvoiceDeliverySearch.GetInvoices");
                throw ex;
            }
            return tableOut;
        }

    }
}
