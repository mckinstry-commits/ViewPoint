using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace McK.Data.Viewpoint
{
    public static class ProcessBatch
    {
        /// <summary>
        /// Closes WOs; if open; Scopes get closed. 
        /// </summary>
        /// <param name="JCCo">Compnay</param>work in progress better error reporting
        /// <param name="mth">Close month</param>
        /// <returns>Errors list, if any</returns>
        public static List<dynamic> MCKspWOCloseProcess(byte JCCo, string mth)
        {
            SqlParameter _jcco = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _mth = new SqlParameter("@BatchMonth", SqlDbType.DateTime)
            {
                SqlValue = mth ?? (object)DBNull.Value
            };
            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = DBNull.Value,
                Direction = ParameterDirection.Output
            };

            List<dynamic> tblErrors = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspWOCloseProcess", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_jcco);
                        _cmd.Parameters.Add(_mth);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.CommandTimeout = 600;

                        using (var reader = _cmd.ExecuteReader())
                        {
                            tblErrors = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    string datatype = reader.GetFieldType(field).FullName;

                                    // field name | data type | value
                                    row.Add(reader.GetName(field), new KeyValuePair<string, object>(datatype, reader[field]));
                                }
                                tblErrors.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                _jcco = null;
                _mth = null;
            }
            return tblErrors;
        }
    }
}
