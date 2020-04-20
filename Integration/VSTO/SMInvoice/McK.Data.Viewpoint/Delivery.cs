using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class Delivery
    {
        /// <summary>
        ///  Mark invoice as delivered
        /// </summary>
        /// <param name="invoices"></param>
        /// <returns>True if success, else false.</returns>
        public static List<dynamic> DeliverInvoice(byte smco, dynamic invoice)
        {
            SqlParameter _smco = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = smco != 0x0 ? smco : (object)DBNull.Value
            };
            SqlParameter _invoiceNumber = new SqlParameter("@InvoiceNumber", SqlDbType.VarChar, 10)
            {
                SqlValue = invoice ?? (object)DBNull.Value
            };

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspDeliverInvoice", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_smco);
                        _cmd.Parameters.Add(_invoiceNumber);

                        tableOut = new List<dynamic>();

                        using (var reader = _cmd.ExecuteReader())
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
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Delivery.MCKspDeliverInvoice");
                throw ex;
            }
            return tableOut;
        }

    }
}
