using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public class JCBatchAllowedDates
    {
        public static List<string> GetValidMonths(byte JCCo)
        {
            List<string> lstMonths = new List<string>();

            const string _sql = "select * from mers.mfnJCBatchAllowedDates (@JCCo)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                Value = DBNull.Value,
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
            };
            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                lstMonths.Add(reader.GetDateTime(1).ToString("MM/yyyy"));
                            }
                        }
                    }
                } 
            }
            catch (Exception)
            {
                throw; // to UI
            }

            return lstMonths;
        }

    }
}
