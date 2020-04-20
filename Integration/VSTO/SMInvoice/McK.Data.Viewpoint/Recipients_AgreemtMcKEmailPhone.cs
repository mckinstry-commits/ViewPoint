using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace McK.Data.Viewpoint
{
    public static partial class Recipients
    {
        /// <summary>
        /// Get the McKinstry recipient data for the SM Invoice
        /// </summary>
        /// <param name="invoices"></param>
        /// <returns></returns>
        public static List<dynamic> GetAgreemtMcKEmailPhone(List<dynamic> invoices)
        {
            SqlParameter _billToCustomer = new SqlParameter("@BillToCustomer", SqlDbType.Int);
            SqlParameter _agreemt = new SqlParameter("@Agreement", SqlDbType.VarChar, 10);
            SqlParameter _invoiceNumber = new SqlParameter("@InvoiceNumber", SqlDbType.VarChar, 10);
            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    tableOut = new List<dynamic>();

                    var uniqueInvoices = invoices.GroupBy(r => r.InvoiceNumber).Distinct();

                    foreach (var c in uniqueInvoices)
                    {
                        dynamic inv = c.First();
                        _billToCustomer.SqlValue = inv.Customer ?? (object)DBNull.Value;
                        _agreemt.SqlValue = inv.Agreement ?? (object)DBNull.Value;
                        _invoiceNumber.SqlValue = inv.InvoiceNumber ?? (object)DBNull.Value;

                        using (var _cmd = new SqlCommand("SELECT * FROM dbo.mckfnGetAgreemtMcKContact(@BillToCustomer, @Agreement, @InvoiceNumber)", _conn))
                        {
                            _cmd.CommandTimeout = 600;
                            _cmd.Parameters.Add(_billToCustomer);
                            _cmd.Parameters.Add(_agreemt);
                            _cmd.Parameters.Add(_invoiceNumber);

                            using (var reader = _cmd.ExecuteReader())
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
                            _cmd.Parameters.Clear();
                        }
                    } // foreach
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Recipients.GetAgreemtMcKEmailPhone");
                throw ex;
            }
            return tableOut;
        }

    }
}
