using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.Data.Viewpoint
{
    public class JCBatchAllowedDates
    {
        public static List<string> GetValidMonths(byte SMCo)
        {
            List<string> lstMonths = new List<string>();

            const string _sql = "select * from dbo.mfnJCBatchAllowedDates (@SMCo)";

            SqlParameter _co = new SqlParameter("@SMCo", SqlDbType.TinyInt)
            {
                Value = DBNull.Value,
                SqlValue = SMCo != 0 ? SMCo : (object)DBNull.Value
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
