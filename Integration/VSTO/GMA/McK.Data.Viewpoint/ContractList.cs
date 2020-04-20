using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;
using McK.Models.Viewpoint;

namespace McK.Data.Viewpoint
{
    public class ContractList
    {
        public static Contracts GetContractList(byte JCCo, string contract)
        {
            string _sql = "select * from mers.mfnContractJobSelector (@JCCo, @Contract);";
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10)
            {
                SqlValue = contract ?? (object)DBNull.Value
            };
            Contracts contracts;

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
                            int _jcco       = reader.GetOrdinal("JCCo");
                            int _trimTract  = reader.GetOrdinal("TrimContract");
                            int _tract      = reader.GetOrdinal("Contract");
                            int _job        = reader.GetOrdinal("Job");
                            Contract temp_c = new Contract();

                            contracts = new Contracts();

                            while (reader.Read())
                            {
                                Contract c = new Contract()
                                {
                                    JCCo            = reader.GetByte(_jcco),
                                    TrimContractId  = reader.GetString(_trimTract),
                                    ContractId      = reader.GetString(_tract)
                                };
                                string job = reader.GetString(_job);

                                /* Normalize FROM:
                                 
                                    JCCo	TrimContract	Contract	Job
                                    ----    ------------    --------   ----------
                                    1	    104825-	        104825-	    104825-001
                                    1	    104825-	        104825-	    104825-002
                                    1	    104825-	        104825-	    104825-003
                                    1	    104825-	        104825-	    104825-004
                                    1	    104825-	        104825-	    104825-005
                                    1	    104825-	        104825-	    104825-006
                                    
                                    TO:

                                    JCCo	TrimContract	Contract	Job
                                    ----    ------------    --------    ----------
                                    1	    104825-	        104825-	    104825-001
                                                                        104825-002
                                                                        104825-003
                                                                        104825-004
                                                                        104825-005
                                                                        104825-006
                                 */
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
            catch (Exception ex)
            {
                ex.Data.Add(0, "GetContractList");
                throw ex;
            }
        }
    }
}
