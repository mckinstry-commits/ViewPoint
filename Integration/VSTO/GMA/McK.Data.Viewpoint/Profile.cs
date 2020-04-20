﻿using System;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using Mck.Data.Viewpoint;

namespace McK.Data.Viewpoint
{
    public class Profile
    {
        public static string GetVP_UserName(byte? JCCo = null, string Login = null)
        {
            string _sql = "select * from mers.mfnGetUserProfile2(@Company,@Login)";

            SqlParameter _co = new SqlParameter("@Company", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 && JCCo != null ? JCCo : 100
            };

            SqlParameter _login = new SqlParameter("@Login", SqlDbType.VarChar)
            {
                SqlValue = DBNull.Value
            };

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.CommandType = CommandType.Text;
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_login);
                        Login = Convert.ToString(_cmd.ExecuteScalar());
                        return Login;
                    }
                }
            }
            catch (Exception e) {
                GMALog.LogAction(GMALog.Action.INVALID_USER, JCCo, null, null, null, e.Message);
                throw new Exception("GetVP_UserName: \n" + e.Message, e);
            }
        }

    }
}
