using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class LaborPivotSearch
    {
        public static string GetLaborPivot(byte Company, string JobId)
        {
            string _sql = @"SELECT @laborPivot = ISNULL(udProjectionTemplate,'MTH') 
                            FROM JCJM 
                            WHERE JCCo = @JCCo 
                            AND Job = @Job";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = Company != 0 ? Company : (object)DBNull.Value
            };

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10)
            {
                SqlValue = JobId ?? (object)DBNull.Value
            };

            SqlParameter _laborPivot = new SqlParameter("@laborPivot", SqlDbType.VarChar, 3)
            {
                SqlValue = DBNull.Value,
                Direction = ParameterDirection.Output
            };

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_job);
                        _cmd.Parameters.Add(_laborPivot);
                        _cmd.CommandTimeout = 900;
                        _cmd.ExecuteScalar();
                        var result = _cmd.Parameters["@laborPivot"].Value;

                        if (result == null) throw new Exception("Unable get Labor pivot");

                        return _cmd.Parameters["@laborPivot"].Value.ToString();
                    }
                }
            }
            catch (Exception e){ throw new Exception("GetLaborPivot: " +  e.Message); }
        }
    }
}
