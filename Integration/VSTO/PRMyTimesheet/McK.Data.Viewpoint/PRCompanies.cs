using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class PRCompanies
    {
        public static List<string> GetPRCompanies()
        {
            string _sql = "select PRCo from PRCO with(nolock)";

            List<string> result = new List<string>();

            try
            {
                result.Add("Any");

                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.CommandTimeout = 600;
                        _conn.Open();

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                result.Add(reader.GetByte(0).ToString());
                            }
                        }
                    }
                }
            }
            catch (Exception e)
            {
                throw new Exception("GetCompanies: " + e.Message);
            }
            return result;
        }
    }
}
