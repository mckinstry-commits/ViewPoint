using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public class ContractJobs
    {
        public static Dictionary<string, string> GetContractJobTable(byte JCCo, string contract, string job)
        {
            string _sql = "select * from mers.mfnGetJobsList(@JCCo, @contract, @job)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10)
            {
                SqlValue = contract ?? (object)DBNull.Value
            };
            SqlParameter _job = new SqlParameter("@job", SqlDbType.VarChar, 10)
            {
                SqlValue = job ?? (object)DBNull.Value
            };
            Dictionary<string, string> jobList = null; 

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_contract);
                        _cmd.Parameters.Add(_job);
                        _cmd.CommandTimeout = 600;
                        jobList = new Dictionary<string, string>();

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read()) jobList.Add(reader.GetString(0), reader.GetString(1));
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "GetContractJobTable");
                throw ex;
            }

            return jobList;
        }

    }
}
