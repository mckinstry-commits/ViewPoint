using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class Deliver
    {
        /// <summary>
        /// Set Delivered Date to mark invoice as delivered
        /// </summary>
        /// <param name="invoices"></param>
        /// <returns></returns>
        public static List<dynamic> SetDelivered(List<dynamic> invoices)
        {
            SqlParameter _customer = new SqlParameter("@BillToCustomer", SqlDbType.Int);
            SqlParameter _invoiceNumber = new SqlParameter("@WorkOrderQuote", SqlDbType.VarChar, 10);

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();


                    foreach (IDictionary<string, object> c in invoices)
                    {
                        _customer.SqlValue = c["Customer"] ?? (object)DBNull.Value;
                        _invoiceNumber.SqlValue = c["Invoice Number"] ?? (object)DBNull.Value;

                        using (var _cmd = new SqlCommand("dbo.MCKspSetDelivered", _conn))
                        {
                            _cmd.CommandType = CommandType.StoredProcedure;
                            _cmd.CommandTimeout = 600;
                            _cmd.Parameters.Add(_customer);
                            _cmd.Parameters.Add(_invoiceNumber);

                            var result = _cmd.ExecuteScalar();

                            // success if 1, failure goes to exception
                            if (int.TryParse((string)result, out int tryInt))
                            {
                                var success = Convert.ToBoolean(result);

                                if (!success)
                                {
                                    tableOut = tableOut ?? new List<dynamic>();

                                    var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                    row.Add("Customer", new KeyValuePair<string, object>(typeof(string).ToString(), c["Customer"]));
                                    row.Add("Invoice Number", new KeyValuePair<string, object>(typeof(string).ToString(), c["Invoice Number"]));

                                    tableOut.Add(row);
                                }
                            }
                        }
                    } // foreach
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Deliver.SetDelivered");
                throw ex;
            }
            return tableOut;
        }

    }
}
