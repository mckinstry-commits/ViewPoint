using System;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;

namespace McKinstry.Data.Viewpoint
{
    public class LogProphecyAction
    {
        public static void InsProphecyLog(string User, byte ActionInt, byte JCCo, string Contract, string Job = null, DateTime? ProjMonth = null, uint BatchId = 0, string ErrorTxt = null, string Details = null)
        {
            System.Reflection.Assembly assembly = System.Reflection.Assembly.GetExecutingAssembly();
            FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(assembly.Location);
            string version = fvi.FileVersion;

            string _sql = "EXEC mers.mspLogProphecyAction @User, @ActionInt, @Version, @JCCo, @Contract, @Job, @bMonth, @BatchId, @Details, @ErrorTxt";

            //      //  SET @Action = CASE @ActionInt
            //		WHEN 1 THEN 'REPORT'
            //      WHEN 2 THEN 'NEW COST JECT'
            //		WHEN 3 THEN 'LOAD COST JECT'
            //		WHEN 4 THEN 'SAVE COST JECT'
            //		WHEN 5 THEN 'NEW REV JECT'
            //		WHEN 6 THEN 'LOAD REV JECT'
            //		WHEN 7 THEN 'SAVE REV JECT'
            //		WHEN 8 THEN 'INVALID USER'
            //		WHEN 9 THEN 'ERROR'
            //		WHEN 10 THEN 'CANCEL COST'
            //		WHEN 11 THEN 'POST COST'
            //		WHEN 12 THEN 'CANCEL REV'
            //		WHEN 13 THEN 'POST REV'
            //		WHEN 14 THEN 'ERROR POST REV'
            //		WHEN 15 THEN 'ERROR POST COST'
            //		WHEN 16 THEN 'ERROR SAVE REV'
            //		WHEN 17 THEN 'ERROR SAVE COST'
            //		WHEN 18 THEN 'LOAD GMAX REPORT
            //		ELSE 'UNKNOWN' 
            //END


            //User Mapping
            SqlParameter _user = new SqlParameter("@User", SqlDbType.VarChar, 128);
            if (User == null)
            {
                _user.SqlValue = "UNKNOWN";
            }
            else
            {
                _user.SqlValue = User;
            }
            //ActionInt Mapping
            SqlParameter _actionint = new SqlParameter("@ActionInt", SqlDbType.TinyInt);

             _actionint.SqlValue = ActionInt;
            
            //Version Mapping
            SqlParameter _version = new SqlParameter("@Version", SqlDbType.VarChar, 5);
            _version.SqlValue = version;
            //Company Mapping
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            if (JCCo == 0)
            {
                _co.SqlValue = 100;
            }
            else
            {
                _co.SqlValue = JCCo;
            }
            //Contract Mapping
            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);
            if (Contract == null)
            {
                _contract.SqlValue = DBNull.Value;
            }
            else
            {
                _contract.SqlValue = Contract;
            }
            //Job ID Mapping
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            if (Job == null)
            {
                _job.SqlValue = DBNull.Value;
            }
            else
            {
                _job.SqlValue = Job;
            }
            //Batch Month Mapping
            SqlParameter _mth = new SqlParameter("@bMonth", SqlDbType.DateTime);
            if (ProjMonth == null)
            {
                _mth.SqlValue = DBNull.Value;
            }
            else
            {
                _mth.SqlValue = ProjMonth;
            }
            //BatchId Mapping
            SqlParameter _batchid = new SqlParameter("@BatchId", SqlDbType.Int);
            if (BatchId == 0)
            {
                _batchid.SqlValue = 0;
            }
            else
            {
                _batchid.SqlValue = Convert.ToInt32(BatchId);
            }
            //Details Mapping
            SqlParameter _detail = new SqlParameter("@Details", SqlDbType.VarChar, 50);
            if (Details == null)
            {
                _detail.SqlValue = DBNull.Value;
            }
            else
            {
                _detail.SqlValue = Details;
            }
            //Error Text Mapping
            SqlParameter _error = new SqlParameter("@ErrorTxt", SqlDbType.VarChar, 255);
            if (ErrorTxt == null)
            {
                _error.SqlValue = DBNull.Value;
            }
            else
            {
                _error.SqlValue = ErrorTxt;
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_user);
                _cmd.Parameters.Add(_actionint);
                _cmd.Parameters.Add(_version);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_contract);
                _cmd.Parameters.Add(_job);
                _cmd.Parameters.Add(_mth);
                _cmd.Parameters.Add(_batchid);
                _cmd.Parameters.Add(_detail);
                _cmd.Parameters.Add(_error);
                _cmd.CommandTimeout = 600000;

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);
                _cmd.ExecuteScalar();
                
            }
            catch (Exception e)
            {
                throw new Exception("Prophecy Log Exception", e);
            }
            finally
            {
                if (!(_conn.State == ConnectionState.Closed))
                {
                    _conn.Close();
                }
                _conn = null;
            }

        }
    }
}
