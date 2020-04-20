using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class ContractJobs
    {
        //public static DataTable GetContractJobTable(byte JCCo, string contract, string job)
        //{
        //    DataTable resultTable = new DataTable();

        //    string _sql = "select * from mers.mfnGetJobsList(@JCCo, @contract, @job)";

        //    SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
        //    _co.SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value;

        //    SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10);
        //    _contract.SqlValue = contract != null ? contract : (object)DBNull.Value;

        //    SqlParameter _job = new SqlParameter("@job", SqlDbType.VarChar, 10);
        //    _job.SqlValue = job != null ? job : (object)DBNull.Value;

        //    SqlConnection _conn = new SqlConnection(HelperData._conn_string);

        //    try
        //    {
        //        _conn.Open();

        //        SqlCommand _cmd = new SqlCommand(_sql, _conn);
        //        _cmd.Parameters.Add(_co);
        //        _cmd.Parameters.Add(_contract);
        //        _cmd.Parameters.Add(_job);
        //        _cmd.CommandTimeout = 600;

        //        SqlDataAdapter _da = new SqlDataAdapter(_cmd);

        //        _da.Fill(resultTable);
        //        resultTable.TableName = "ContractProjects";
        //    }
        //    catch (Exception e)
        //    {
        //        throw new Exception("GetContractJobs Exception", e);
        //    }
        //    finally
        //    {
        //        if (!(_conn.State == ConnectionState.Closed))
        //        {
        //            _conn.Close();
        //        }
        //        _conn = null;
        //    }

        //    return resultTable;
        //}

        public static Dictionary<string, string> GetContractJobTable(byte JCCo, string contract, string job)
        {
            string _sql = "select * from mers.mfnGetJobsList(@JCCo, @contract, @job)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value;

            SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10);
            _contract.SqlValue = contract != null ? contract : (object)DBNull.Value;

            SqlParameter _job = new SqlParameter("@job", SqlDbType.VarChar, 10);
            _job.SqlValue = job != null ? job : (object)DBNull.Value;

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
                        _cmd.CommandTimeout = 900;
                        jobList = new Dictionary<string, string>();

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read()) jobList.Add(reader.GetString(0), reader.GetString(1));
                        }
                        return jobList;
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetContractJobs Exception", e); }
        }
    }
}
