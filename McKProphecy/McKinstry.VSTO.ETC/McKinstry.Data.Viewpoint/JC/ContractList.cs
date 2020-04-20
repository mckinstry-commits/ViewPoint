using System;
using System.Data;
using System.Data.SqlClient;
using McKinstry.Data.Models.Viewpoint;

namespace McKinstry.Data.Viewpoint
{
    public class ContractList
    {
        public static Contracts GetContractList(byte? JCCo, string contract)
        {
            Contracts contracts;

            string _sql = "select * from mers.mfnContractJobSelector (@JCCo, @Contract);";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value;

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);
            _contract.SqlValue = contract != null ? contract : (object)DBNull.Value;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_contract);

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            int _jcco = reader.GetOrdinal("JCCo");
                            int _trimTract = reader.GetOrdinal("TrimContract");
                            int _tract = reader.GetOrdinal("Contract");
                            int _job = reader.GetOrdinal("Job");
                            Contract temp_c = new Contract();

                            contracts = new Contracts();

                            while (reader.Read())
                            {
                                Contract c = new Contract();
                                c.JCCo = reader.GetByte(_jcco);
                                c.TrimContractId = reader.GetString(_trimTract);
                                c.ContractId = reader.GetString(_tract);
                                string job = reader.GetString(_job);

                                if (temp_c.JCCo == c.JCCo && temp_c.TrimContractId == c.TrimContractId)
                                {
                                    temp_c.Projects.Add(job);
                                }
                                else
                                {
                                    c.Projects.Add("All Projects");
                                    c.Projects.Add(job);
                                    contracts.Add(c);
                                    temp_c = c;
                                }
                            }
                            return contracts;
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetContractList: " + e.Message); }
        }
    }
}
