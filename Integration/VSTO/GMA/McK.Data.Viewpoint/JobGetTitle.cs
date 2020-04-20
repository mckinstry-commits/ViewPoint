using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public class JobGetTitle
    {
        public static string GetTitle(int? JCCo, string ContractOrJob)
        {
            string _sql = null;

            string[] _tmp = ContractOrJob.Split('-');
            if (_tmp.Length == 2)
            {
                if (_tmp[1] == "")
                {
                    _sql = "select CONCAT(Description,' - ', Contract) FROM JCCM WHERE JCCo = @JCCo AND Contract = @ContractOrJob;";
                }
                else //if (_tmp[1] != "")
                {
                    _sql = "select CONCAT(Description,' - ', Job) FROM JCJM WHERE JCCo = @JCCo AND Job = @ContractOrJob;";
                }
            }
            else
            {
                throw new Exception("JobGetTitle: Invalid Contract or Job Id: " + ContractOrJob);
            }

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            if (JCCo == 0) throw new Exception("JobGetTitle: Invalid JC Company.");
            _co.SqlValue = JCCo;


            SqlParameter _contractORjob = new SqlParameter("@ContractOrJob", SqlDbType.VarChar, 10)
            {
                SqlValue = ContractOrJob ?? throw new Exception("JobGetTitle: Missing Project (Contract or Job ID)")
            };

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_contractORjob);
                        _cmd.CommandTimeout = 900;

                        var result = _cmd.ExecuteScalar();

                        if (result != null) return result.ToString();
                    }
                }
            }
            catch (Exception e)
            {
                e.Data.Add(0, "JobGetTitle:");
                throw e;
            }
            return null;
        }
    }
}

