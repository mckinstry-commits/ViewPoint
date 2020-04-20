using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class Companies
    {
        public static Dictionary<byte, string> GetCompanyList()
        {
            string _sql = "select Cast (HQCo as Varchar) + '-' + Name as Co, HQCo from HQCO with (nolock) where udTESTCo = 'N';";

            Dictionary<byte, string> result = new Dictionary<byte, string>();

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    SqlCommand _cmd = new SqlCommand(_sql, _conn);
                    _cmd.CommandTimeout = 600;

                    _conn.Open();

                    using (SqlDataReader reader = _cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.Add(reader.GetByte(1), reader.GetString(0));
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetCompanyList: " + e.Message); }
            return result;
        }
    }
}
