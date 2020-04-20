using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class PRGroups
    {
        public static Dictionary<byte, string> GetPRGroups()
        {
            string _sql = @"Select Distinct a.PRGroup, a.Description
                            From PRGR a with(nolock)
	                            INNER JOIN PRGR b with(nolock) 
	                            ON  a.PRCo = b.PRCo 
	                            AND a.PRGroup = b.PRGroup";

            Dictionary<byte, string> result = new Dictionary<byte, string>();

            try
            {
                result.Add(0, "Any");

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
                                result.Add(reader.GetByte(0), reader.GetString(1));
                            }
                        }
                    }
                }
            }
            catch (Exception e)
            {
                throw new Exception("GetPRGroups: " + e.Message);
            }
            return result;
        }
    }
}
