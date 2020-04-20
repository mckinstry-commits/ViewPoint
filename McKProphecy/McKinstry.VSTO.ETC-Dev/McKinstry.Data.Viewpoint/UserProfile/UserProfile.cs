using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class UserProfile
    {
        public static DataTable GetUserProfile(int? Company, string Login)
        {

            string _sql = "select * from mers.mfnGetUserProfile(@Company,@Login)";

            DataTable resultTable = new DataTable();
            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlParameter _co = new SqlParameter("@Company", SqlDbType.TinyInt);
            SqlParameter _login = new SqlParameter("@Login", SqlDbType.VarChar);

            _login.SqlValue = DBNull.Value;

            if (Company != null)
            {
                _co.SqlValue = Company;
            }
            else
            {
                throw new Exception("Missing JC Company!");
            }

            SqlCommand _cmd = null;
            SqlDataAdapter _da  = null;

            try
            {
                _conn.Open();

                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_login);

                _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "UserProfile";
            }
            catch (Exception e)
            {
                throw new Exception("GetUserProfile Exception", e);
            }
            finally
            {
                HelperData.SqlCleanup(out _sql, out _cmd, _conn);
            }

            return resultTable;
        }

    }


}
