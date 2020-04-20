using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using McKinstry.Data.Models.Viewpoint;

namespace McKinstry.Data.Viewpoint
{
    public class OpenBatches
    {
        public static List<Batch> GetOpenBatches(string login)
        {
            string _sql = "SELECT * FROM dbo.mckfnOpenBatches (@login);";

            SqlParameter _login = new SqlParameter("@login", SqlDbType.VarChar);
            _login.SqlValue = login != null ? login : (object)DBNull.Value;

            List<Batch> batches = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_login);
                        _cmd.CommandTimeout = 300;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            batches = new List<Batch>();

                            while (reader.Read())
                            {
                                batches.Add(new Batch(reader.GetString(0), Convert.ToUInt32(reader.GetInt32(1)), reader.GetDateTime(2), reader.GetString(3), reader.GetByte(4)));
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetOpenBatches: " + e.Message); }

            return batches;
        }
    }
}
