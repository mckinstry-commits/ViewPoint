using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class UserProfile
    {
        public static string GetVPUserName(int? Company, string Login)
        {
            string _sql = "select * from mers.mfnGetUserProfile2(@Company,@Login)";

            SqlParameter _co = new SqlParameter("@Company", SqlDbType.TinyInt);
            _co.SqlValue = Company != null ? Company : (object)DBNull.Value;

            SqlParameter _login = new SqlParameter("@Login", SqlDbType.VarChar);
            _login.SqlValue = DBNull.Value;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_login);
                        return Convert.ToString(_cmd.ExecuteScalar());
                    }
                }
            }
            catch (Exception e) { throw new Exception("GetVPUserName\n" + e.Message, e);}
        }
    }
}
