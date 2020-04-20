using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
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
                else if (_tmp[1] != "")
                {
                    _sql = "select CONCAT(Description,' - ', Job) FROM JCJM WHERE JCCo = @JCCo AND Job = @ContractOrJob;";
                }
            }
            else
            {
                throw new Exception("GetTitle: Invalid Contract or Job Id: " + ContractOrJob);
            }

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            if (JCCo != 0)
            {
                _co.SqlValue = JCCo;
            }
            else
            {
                throw new Exception("Invalid JC Company.");
            }

            SqlParameter _contractORjob = new SqlParameter("@ContractOrJob", SqlDbType.VarChar, 10);
            if (ContractOrJob != null)
            {
                _contractORjob.SqlValue = ContractOrJob;
            }
            else
            {
                throw new Exception("Missing Project (Contract or Job ID)");
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd = new SqlCommand(_sql, _conn);

            try
            {
                _conn.Open();

                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_contractORjob);
                _cmd.CommandTimeout = 600000;
                var result = _cmd.ExecuteScalar();
                if (result != null)
                {
                    return result.ToString();
                }
            }
            catch (Exception e) { throw new Exception("JobGetTitle: ", e); }
            finally
            {
                HelperData.SqlCleanup(out _sql, out _cmd, _conn);
            }
            return null;
        }
    }
}

