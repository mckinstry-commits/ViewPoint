using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class InvoicePreview
    {
        /// <summary>
        /// Get SM Invoice scope detail
        /// </summary>
        /// <remarks>Use SheetBuilderDynamic.cs to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetInvoiceDetailWO(byte smco, dynamic workorder, string invoiceNumber, bool? detailTandM)
        {
            SqlParameter _smco = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = smco != 0x0 ? smco : (object)DBNull.Value
            };
            SqlParameter _wo = new SqlParameter("@WordOrder", SqlDbType.Int)
            {
                SqlValue = workorder ?? (object)DBNull.Value
            };
            SqlParameter _invoiceNumber = new SqlParameter("@InvoiceNumber", SqlDbType.VarChar, 10)
            {
                SqlValue = invoiceNumber ?? (object)DBNull.Value
            };
            SqlParameter _detailTandM = new SqlParameter("@HideTandMLaborRate", SqlDbType.Bit)
            {
                SqlValue = detailTandM
            };

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspInvoiceDetail", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_smco);
                        _cmd.Parameters.Add(_wo);
                        _cmd.Parameters.Add(_invoiceNumber);
                        _cmd.Parameters.Add(_detailTandM);

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
            catch (Exception e) { throw new Exception("InvoiceDetail.GetInvoiceDetailWO: \n" + e.Message); }
            return tableOut;
        }
    }
}
