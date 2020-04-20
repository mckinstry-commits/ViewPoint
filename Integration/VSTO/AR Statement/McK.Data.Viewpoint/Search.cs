using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class Search
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="company"></param>
        /// <param name="customer"></param>
        /// <remarks>Use SheetBuilderDynamic.cs to convert ExpandoObject table to Excel table</remarks>
        /// <returns></returns>
        public static List<dynamic> GetStatements(dynamic company, dynamic customer, char? customerType, dynamic statementMth, dynamic transThruDate)
        {
            SqlParameter _smco = new SqlParameter("@ARCO", SqlDbType.TinyInt)
            {
                SqlValue = company != (Byte?)null ? company : (object)DBNull.Value
            };
            SqlParameter _customer = new SqlParameter("@Customer", SqlDbType.Int)
            {
                SqlValue = customer ?? (object)DBNull.Value
            };
            SqlParameter _customerType = new SqlParameter("@CustomerType", SqlDbType.Char)
            {
                SqlValue = customerType != (Byte?)null ? customerType : (object)DBNull.Value
            };
            SqlParameter _statementMth = new SqlParameter("@StatementMonth", SqlDbType.Date)
            {
                SqlValue = statementMth ?? (object)DBNull.Value
            };
            SqlParameter _transThruDate = new SqlParameter("@TransThruDate", SqlDbType.Date)
            {
                SqlValue = transThruDate ?? (object)DBNull.Value
            };
            List<dynamic> tableOut = null;


            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("dbo.MCKsp_AROpenItemStatement", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandTimeout = 2700; // 30 minutes
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_smco);
                        _cmd.Parameters.Add(_customer);
                        _cmd.Parameters.Add(_customerType);
                        _cmd.Parameters.Add(_statementMth);
                        _cmd.Parameters.Add(_transThruDate);

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
                ex.Data.Add(0, "Search.GetStatements");
                throw ex;
            }
            return tableOut;
        }

    }
}
