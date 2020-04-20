using System;
using System.Data;
using System.Data.SqlClient;
using McK.Data.Viewpoint;

namespace Mck.Data.Viewpoint
{
    public static class GMALog
    {

        public enum Action
        {
            REPORT,
            COPY_OFFLINE,
            NEW_CONTRACT,
            INVALID_USER,
            ERROR
        }

        public static void LogAction(Action action, byte? JCCo, string contract = null, string job = null, string details = null, string ErrorTxt = null)
        {

            SqlParameter _user = new SqlParameter("@User", SqlDbType.VarChar, 128)
            {
                SqlValue = HelperData.VPuser ?? "UNKNOWN"
            };

            SqlParameter _action = new SqlParameter("@ActionInt", SqlDbType.TinyInt)
            {
                SqlValue = action
            };

            SqlParameter _version = new SqlParameter("@Version", SqlDbType.VarChar, 7)
            {
                SqlValue = HelperData.VSTO_Version
            };

            SqlParameter _jcco = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 || JCCo != null ? JCCo : 100
            };

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10)
            {
                SqlValue = contract ?? (object)DBNull.Value
            };

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 13)
            {
                SqlValue = job ?? (object)DBNull.Value
            };

            SqlParameter _detail = new SqlParameter("@Details", SqlDbType.VarChar, 60)
            {
                SqlValue = details ?? (object)DBNull.Value
            };

            SqlParameter _error = new SqlParameter("@ErrorTxt", SqlDbType.VarChar, 255)
            {
                SqlValue = ErrorTxt ?? (object)DBNull.Value
            };

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    using (var _cmd = new SqlCommand("dbo.mspLogGMAaction", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 900;

                        _cmd.Parameters.Add(_user);
                        _cmd.Parameters.Add(_action);
                        _cmd.Parameters.Add(_version);
                        _cmd.Parameters.Add(_jcco);
                        _cmd.Parameters.Add(_contract);
                        _cmd.Parameters.Add(_job);
                        _cmd.Parameters.Add(_detail);
                        _cmd.Parameters.Add(_error);
                        _cmd.ExecuteScalar();
                    }
                }
            }
            catch (Exception e) { throw new Exception("GMALog.LogAction: \n" + e.Message, e); }
        }
    }
}
