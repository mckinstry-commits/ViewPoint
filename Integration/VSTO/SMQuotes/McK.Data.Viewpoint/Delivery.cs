using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class Delivery
    {
        /// <summary>
        /// Set Delivered Date to mark invoice as delivered
        /// </summary>
        /// <param name="invoices"></param>
        /// <returns>True if success, else false.</returns>
        public static bool SetDelivered(byte smco, dynamic customer, dynamic invoice)
        {
            SqlParameter _smco = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = smco != 0x0 ? smco : (object)DBNull.Value
            };
            SqlParameter _customer = new SqlParameter("@BillToCustomer", SqlDbType.Int)
            {
                SqlValue = customer ?? (object)DBNull.Value
            };
            SqlParameter _invoiceNumber = new SqlParameter("@WorkOrderQuote", SqlDbType.VarChar, 10)
            {
                SqlValue = invoice ?? (object)DBNull.Value
            };

            bool success = false;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspSetDelivered", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_smco);
                        _cmd.Parameters.Add(_customer);
                        _cmd.Parameters.Add(_invoiceNumber);

                        var result = _cmd.ExecuteScalar();

                        // success if 1, failure goes to exception
                        if (int.TryParse(result.ToString(), out int tryInt))
                        {
                            success = Convert.ToBoolean(result);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Delivery.SetDelivered");
                throw ex;
            }
            return success;
        }

    }
}
