using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class InvoicePreview
    {
        public static List<dynamic> GetAgreementInvoiceDetail(byte smco, dynamic agreement, dynamic invoiceNumber)
        {
            SqlParameter _smco = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = smco != 0x0 ? smco : (object)DBNull.Value
            };

            SqlParameter _agreement = new SqlParameter("@Agreement", SqlDbType.VarChar, 15)
            {
                SqlValue = agreement ?? (object)DBNull.Value
            };

            SqlParameter _invoiceNumber = new SqlParameter("@InvoiceNumber", SqlDbType.VarChar, 10)
            {
                SqlValue = invoiceNumber ?? (object)DBNull.Value
            };

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("Select * From dbo.mckfnAgreement(@SMCo, @Agreement, @InvoiceNumber)", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_smco);
                        _cmd.Parameters.Add(_invoiceNumber);
                        _cmd.Parameters.Add(_agreement);

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
            catch (Exception e) { throw new Exception("InvoiceDetail.GetAgreementInvoiceDetail: \n" + e.Message); }
            return tableOut;
        }
    }
}
