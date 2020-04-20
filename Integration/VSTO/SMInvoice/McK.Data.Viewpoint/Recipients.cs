using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class Recipients
    {
        /// <summary>
        /// Get the McKinstry recipient data for the SM Invoice
        /// </summary>
        /// <param name="invoices"></param>
        /// <returns></returns>
        public static List<dynamic> GetRecipients(List<dynamic> invoices)
        {
            SqlParameter _customer = new SqlParameter("@BillToCustomer", SqlDbType.Int);
            SqlParameter _invoiceNumber = new SqlParameter("@InvoiceNumber", SqlDbType.VarChar, 10);
            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    tableOut = new List<dynamic>();

                    foreach (IDictionary<string, object> c in invoices)
                    {   
                        _customer.SqlValue = c["Customer"] ?? (object)DBNull.Value;
                        _invoiceNumber.SqlValue = c["InvoiceNumber"] ?? (object)DBNull.Value;

                        using (var _cmd = new SqlCommand("dbo.MCKspSMRecipients", _conn))
                        {
                            _cmd.CommandType = CommandType.StoredProcedure;
                            _cmd.CommandTimeout = 600;
                            _cmd.Parameters.Add(_customer);
                            _cmd.Parameters.Add(_invoiceNumber);

                            using (var reader = _cmd.ExecuteReader())
                            {
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
                            _cmd.Parameters.Clear();
                        }
                    } // foreach
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "SMRecipients.GetRecipients");
                throw ex;
            }
            return tableOut;
        }

    }
}
