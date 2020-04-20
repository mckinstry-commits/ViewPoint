using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using McKinstry.Data.Models.Viewpoint;

namespace McKinstry.Data.Viewpoint
{
    public class ContractJectAudit
    {
        public static List<ProjectionAudit> GetProjectionAudit(byte JCCo, string contract)
        {
            string _sql = "SELECT * FROM dbo.mckfnConProphHist (@JCCo, @contract);";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value;

            SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10);
            _contract.SqlValue = contract != null ? contract : (object)DBNull.Value;

            List<ProjectionAudit> auditList = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_contract);
                        _cmd.CommandTimeout = 300;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            auditList = new List<ProjectionAudit>();

                            while (reader.Read())
                            {
                                ProjectionAudit jobAudit = new ProjectionAudit(reader.GetString(0), reader.GetValue(1), reader.GetValue(2), reader.GetValue(3), reader.GetValue(4), reader.GetValue(5));
                                auditList.Add(jobAudit);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetContractJobAudit: " + e.Message); }

            return auditList;
        }
    }
}
