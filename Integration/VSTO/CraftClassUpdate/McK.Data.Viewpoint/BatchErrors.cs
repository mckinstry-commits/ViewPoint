using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class Batch
    {
        public static List<dynamic> GetCraftClassErrors(uint? batch)
        {
            string _sql = "Select * from dbo.MCKPRCCerror with(nolock) Where BatchNum = @Rbatchid;";
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

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
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
                                    // get type name
                                    string type = reader.GetFieldType(field).FullName;

                                    // trim out 'System.' from type name
                                    int dot = type.IndexOf('.') + 1;
                                    type = type.Substring(dot, type.Length - dot);

                                    // add ROW: Column Name | data type | value
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
                ex.Data.Add(0, "GetCraftClassErrors");
                throw ex;
            }
            return table;
        }

        public static List<dynamic> GetPayratesErrors(uint? batch)
        {
            string _sql = "Select * from dbo.MCKPRCPerror with(nolock) Where BatchNum = @Rbatchid;";
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

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
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
                ex.Data.Add(0, "GetPayratesErrors");
                throw ex;
            }
            return table;
        }

        public static List<dynamic> GetDednsLiabsErrors(uint? batch)
        {
            string _sql = "Select * from dbo.MCKPRCDerror with(nolock) Where BatchNum = @Rbatchid;";
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

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
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
                ex.Data.Add(0, "GetDednsLiabsErrors");
                throw ex;
            }
            return table;
        }

        public static List<dynamic> GetAddonEarningsErrors(uint? batch)
        {
            string _sql = "Select * from dbo.MCKPRCFerror with(nolock) Where BatchNum = @Rbatchid;";
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

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
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
                ex.Data.Add(0, "GetAddonEarningsErrors");
                throw ex;
            }
            return table;
        }
    }
}