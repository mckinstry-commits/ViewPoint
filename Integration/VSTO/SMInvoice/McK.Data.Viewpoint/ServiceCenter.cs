using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class ServiceCenter
    {
        public static List<string> GetServiceCenters(string division)
        {
            SqlParameter _division = new SqlParameter("@Division", System.Data.SqlDbType.VarChar, 10)
            {
                SqlValue = division ?? (object)DBNull.Value
            };

            List<string> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("Select * From dbo.mckfnServiceSites(@Division)", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_division);

                        using (var reader = _cmd.ExecuteReader())
                        {
                            tableOut = new List<string>
                            {
                                "Any"
                            };

                            while (reader.Read())
                            {
                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    tableOut.Add(reader[field].ToString());
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("ServiceSites.GetServiceSiteList: \n" + e.Message); }
            return tableOut;
        }
    }
}
