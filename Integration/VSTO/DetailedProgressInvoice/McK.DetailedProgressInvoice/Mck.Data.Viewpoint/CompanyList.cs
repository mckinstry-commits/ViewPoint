using Mck.Data.Viewpoint;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class CompanyList
    {
        public static Dictionary<byte, string> GetCompanyList()
        {
            string _sql = "select Cast (HQCo as Varchar) + '-' + Name as Co, HQCo from HQCO with (nolock) where udTESTCo = 'N';";

            Dictionary<byte, string> result = new Dictionary<byte, string>();

            try
            {
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
                                result.Add(reader.GetByte(1), reader.GetString(0));
                            }
                        }
                    }
                }
            }
            catch (Exception e)
            {
                DetailInvoiceLog.LogAction(DetailInvoiceLog.Action.ERROR, null, null, null, null, null, null, e.Message);
                throw new Exception("GetCompanyList: " + e.Message);
            }
            return result;
        }
    }
}
