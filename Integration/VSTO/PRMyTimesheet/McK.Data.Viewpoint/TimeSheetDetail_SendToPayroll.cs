using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class TimesheetDetail
    {
        /// <summary>
        /// Send fully approved timesheets to PR Batch. Uses PR MyTimesheet form's Send function in Viewpoint. 
        /// </summary>
        /// <remarks>No partially approved timesheets here</remarks>
        /// <param name="prco"></param>
        /// <param name="prgroup"></param>
        /// <param name="prstartdate"></param>
        /// <param name="prenddate"></param>
        /// <param name="payseq"></param>
        /// <returns></returns>
        public static string SendApprovedTimesheetsToPRBatch(byte? prco, byte? prgroup, dynamic prstartdate, dynamic prenddate, int payseq)
        {
            SqlParameter _prco = new SqlParameter("@prco", SqlDbType.TinyInt)
            {
                Value = prco ?? (object)DBNull.Value
            };
            SqlParameter _prgroup = new SqlParameter("@prgroup", SqlDbType.TinyInt)
            {
                Value = prgroup ?? (object)DBNull.Value
            };
            SqlParameter _prstartdate = new SqlParameter("@throughdate", SqlDbType.SmallDateTime)
            {
                Value = prstartdate ?? (object)DBNull.Value
            };
            SqlParameter _prenddate = new SqlParameter("@enddate", SqlDbType.SmallDateTime)
            {
                Value = prenddate ?? (object)DBNull.Value
            };
            SqlParameter _payseq = new SqlParameter("@payseq", SqlDbType.SmallInt)
            {
                Value = payseq 
            };
            SqlParameter _msg = new SqlParameter("@msg", SqlDbType.VarChar, 1000)
            {
                Direction = ParameterDirection.Output
            };
            SqlParameter _prrestrict = new SqlParameter("@prrestrict", SqlDbType.Char, 1)
            {
                Value = "N"
            };

            string msgret = "";

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.McKvspPRMyTimesheetSend", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_prco);
                        _cmd.Parameters.Add(_prgroup);
                        _cmd.Parameters.Add(_prstartdate);
                        _cmd.Parameters.Add(_prenddate);
                        _cmd.Parameters.Add(_payseq);
                        _cmd.Parameters.Add(_prrestrict);
                        _cmd.Parameters.Add(_msg);

                        _cmd.ExecuteScalar();

                        var msg = _cmd.Parameters["@msg"].Value;

                        msgret = msg?.ToString();

                        if (!msgret.Contains("Created Batch"))
                        {
                            var ex = new Exception(msgret);
                            throw ex;
                        }
                    }
                }
            }
            catch (Exception) { throw; }

            return msgret;
        }
    }
}

