using System;
using System.Data;
using System.Data.SqlClient;
using McK.Data.Viewpoint;

namespace Mck.Data.Viewpoint
{
    public static class DetailInvoiceLog
    {

        public enum Action
        {
            REPORT,
            COPY_OFFLINE,
            EMAIL,
            INVALID_USER,
            ERROR
        }

        public static void LogAction(Action action, byte? JCCo, string invoiceFrom = null, string invoiceTo = null, dynamic dateFrom = null, dynamic dateTo = null, string details = null, string ErrorTxt = null)
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

            SqlParameter _invoiceFrom = new SqlParameter("@InvoiceFrom", SqlDbType.VarChar, 10)
            {
                SqlValue = invoiceFrom ?? (object)DBNull.Value
            };

            SqlParameter _invoiceTo = new SqlParameter("@InvoiceTo", SqlDbType.VarChar, 10)
            {
                SqlValue = invoiceTo ?? (object)DBNull.Value
            };

            SqlParameter _dateFrom = new SqlParameter("@DateFrom", SqlDbType.DateTime)
            {
                SqlValue = dateFrom ?? (object)DBNull.Value
            };

            SqlParameter _dateTo = new SqlParameter("@DateTo", SqlDbType.DateTime)
            {
                SqlValue = dateTo ?? (object)DBNull.Value
            };

            SqlParameter _detail = new SqlParameter("@Details", SqlDbType.VarChar, 50)
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
                    using (var _cmd = new SqlCommand("dbo.mspLogDetailInvoiceAction", _conn))
                    {
                        _conn.Open();

                        _cmd.CommandType = CommandType.StoredProcedure;

                        _cmd.Parameters.Add(_user);
                        _cmd.Parameters.Add(_action);
                        _cmd.Parameters.Add(_version);
                        _cmd.Parameters.Add(_jcco);
                        _cmd.Parameters.Add(_invoiceFrom);
                        _cmd.Parameters.Add(_invoiceTo);
                        _cmd.Parameters.Add(_dateFrom);
                        _cmd.Parameters.Add(_dateTo);
                        _cmd.Parameters.Add(_detail);
                        _cmd.Parameters.Add(_error);
                        _cmd.ExecuteScalar();
                    }
                }
            }
            catch (Exception e) { throw new Exception("Detail Invoice Log: \n" + e.Message, e); }
        }
    }
}
