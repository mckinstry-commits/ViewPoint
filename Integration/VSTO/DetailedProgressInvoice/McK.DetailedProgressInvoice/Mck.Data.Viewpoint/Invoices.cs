using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.Data.Viewpoint
{
    public static class Invoices
    {
        public static List<dynamic> GetDetailProgressInvoices(byte Company, string invoiceFrom, string invoiceTo, dynamic dateFrom, dynamic dateTo, string sortBy)
        {
            SqlParameter _co = new SqlParameter("@co", SqlDbType.TinyInt)
            {
                SqlValue = Company != 0x0 ? Company: (object)DBNull.Value
            };

            SqlParameter _invoiceFrom = new SqlParameter("@InvoiceFrom", SqlDbType.VarChar, 10)
            {
                SqlValue = invoiceFrom
            };

            SqlParameter _invoiceTo = new SqlParameter("@InvoiceTo", SqlDbType.VarChar, 10)
            {
                SqlValue = invoiceTo
            };

            SqlParameter _dateFrom = new SqlParameter("@DateFrom", SqlDbType.DateTime)
            {
                SqlValue = dateFrom ?? (object)DBNull.Value
            };

            SqlParameter _dateTo = new SqlParameter("@DateTo", SqlDbType.DateTime)
            {
                SqlValue = dateTo ?? (object)DBNull.Value
            };

            SqlParameter _sortBy = new SqlParameter("@SortBy", SqlDbType.VarChar, 1)
            {
                SqlValue = sortBy
            };

            List<dynamic> table = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("dbo.MCKspGetDetailedProgressInvoices", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_dateFrom);
                        _cmd.Parameters.Add(_dateTo);
                        _cmd.Parameters.Add(_sortBy);
                        _cmd.Parameters.Add(_invoiceFrom);
                        _cmd.Parameters.Add(_invoiceTo);

                        using (var reader = _cmd.ExecuteReader())
                        {
                            table = new List<dynamic>();

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
                                table.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Invoices.GetDetailProgressInvoices");
                throw ex;
            }
            return table;
        }

    }
}
