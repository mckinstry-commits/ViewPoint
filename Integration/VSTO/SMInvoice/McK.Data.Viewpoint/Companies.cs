using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class Companies
    {
        public static List<dynamic> GetCompanyList()
        {
            string _sql = "SELECT CAST (HQCo as Varchar) + '-' + Name as CompanyName, HQCo, FedTaxId FROM HQCO WHERE udTESTCo = 'N';";

            List<dynamic> tableOut = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.CommandTimeout = 60;

                        tableOut = new List<dynamic>();

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int field = 0; field <= reader.FieldCount - 1; field++)
                                {
                                    // field name | value
                                    row.Add(reader.GetName(field), reader[field]);
                                }
                                tableOut.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetCompanyList: " + e.Message, e.InnerException); }
            return tableOut;
        }
    }
}
