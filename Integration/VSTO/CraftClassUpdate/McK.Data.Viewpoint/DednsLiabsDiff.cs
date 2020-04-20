using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class Batch
    {

        public static List<dynamic> DednsLiabsDiff(uint? batch)
        {
            SqlParameter _batch = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batch ?? (object)DBNull.Value
            };
            List<dynamic> table = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspPRCDdiff", _conn))
                    {
                        CancelToken.Token.ThrowIfCancellationRequested();
                        CancelToken.Token.Register(() => _cmd?.Cancel());

                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_batch);
                        _cmd.CommandTimeout = 600;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            table = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    string type = reader.GetFieldType(field).FullName;
                                    int dot = type.IndexOf('.') + 1;
                                    type = type.Substring(dot, type.Length - dot);
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
                ex.Data.Add(0, "Batch.DednsLiabsDiff");
                throw ex;
            }
            return table;
        }

        //public static List<dynamic> DednsLiabsNotInVP(uint? batch)
        //{
        //    SqlParameter _batch = new SqlParameter("@Rbatchid", SqlDbType.Int)
        //    {
        //        SqlValue = batch ?? (object)DBNull.Value
        //    };
        //    List<dynamic> table = null;

        //    try
        //    {
        //        using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
        //        {
        //            _conn.Open();

        //            using (var _cmd = new SqlCommand("dbo.MCKspPRCDnotInVP", _conn))
        //            {
        //                CancelToken.Token.ThrowIfCancellationRequested();
        //                CancelToken.Token.Register(() => _cmd?.Cancel());

        //                _cmd.CommandType = CommandType.StoredProcedure;
        //                _cmd.Parameters.Add(_batch);
        //                _cmd.CommandTimeout = 600;

        //                using (SqlDataReader reader = _cmd.ExecuteReader())
        //                {
        //                    table = new List<dynamic>();

        //                    while (reader.Read())
        //                    {
        //                        var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

        //                        for (int field = 0; field <= reader.FieldCount - 1; field++)
        //                        {
        //                            string type = reader.GetFieldType(field).FullName;
        //                            int dot = type.IndexOf('.') + 1;
        //                            type = type.Substring(dot, type.Length - dot);
        //                            row.Add(reader.GetName(field), new KeyValuePair<string, object>(type, reader[field]));
        //                        }
        //                        table.Add(row);
        //                    }
        //                }
        //            }
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        ex.Data.Add(0, "Batch.DednsLiabsNotInVP");
        //        throw ex;
        //    }
        //    return table;
        //}
    }
}

