using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class InvoicePreview
    {
        /// <summary>
        /// Get SM Work Order Invoice header information
        /// </summary>
        /// <remarks>Use SheetBuilderDynamic.cs to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetWOinvoiceHeader(List<dynamic> invoices) //dynamic customer, dynamic invoice, dynamic workorder )
        {
            SqlParameter _invoiceNumber = new SqlParameter("@InvoiceNumber", SqlDbType.VarChar, 10);
            SqlParameter _workorder = new SqlParameter("@WorkOrder", SqlDbType.Int);

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    tableOut = new List<dynamic>();

                    foreach (dynamic c in invoices)
                    {
                        _invoiceNumber.SqlValue = c.InvoiceNumber ?? (object)DBNull.Value;

                        //WO is be a comma - separated list, just grab the first one
                        if (c.WorkOrders != null)
                        {
                            _workorder.SqlValue = ((string)c.WorkOrders).Split(',')[0];
                        }
                        else
                        {
                            _workorder.SqlValue = (object)DBNull.Value;
                        }

                        using (var _cmd = new SqlCommand("Select * From dbo.mckfnGetWOinvoiceHeader(@InvoiceNumber, @WorkOrder)", _conn))
                        {
                            _cmd.CommandTimeout = 600;
                            _cmd.Parameters.Add(_invoiceNumber);
                            _cmd.Parameters.Add(_workorder);

                            using (SqlDataReader reader = _cmd.ExecuteReader())
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
                            _cmd.Parameters.Clear();
                        }
                    } 
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "InvoicePreview.GetWOinvoiceHeader");
                throw ex;
            }
            return tableOut;
        }

    }
}
