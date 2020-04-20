using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint.JCDelete
{
    public static class DeleteRevBatch
    {
        public static bool DeleteBatchRev(byte JCCo, DateTime ProjMonth, uint batchId)
        {
            string _sqldelete = @"SET NOCOUNT OFF; declare @p5 varchar(60)
                                set @p5=NULL
                                exec dbo.bspJCBatchDelete @jcco=@JCCo, @mth=@Month, @batchid=@batchId, @source='JC RevProj',@errmsg=@p5 output";

            SqlParameter _jcco = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            if (JCCo == 0) throw new Exception("DeleteBatchRev: Invalid Company: " + _jcco);
            _jcco.SqlValue = JCCo;

            SqlParameter _projmonth = new SqlParameter("@Month", SqlDbType.DateTime);
            if (ProjMonth == null) throw new Exception("DeleteBatchRev: Invalid Month: " + _projmonth);
            _projmonth.SqlValue = ProjMonth;

            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
            if (batchId == 0) throw new Exception("DeleteBatchRev: Invalid Batch Id: " + _batchId);
            _batchId.SqlValue = batchId;

            try
            {
                using (SqlConnection dbConnection = new SqlConnection(HelperData._conn_string))
                {
                    dbConnection.Open();

                    SqlCommand _cmd = dbConnection.CreateCommand();
                    _cmd.Parameters.Add(_jcco);
                    _cmd.Parameters.Add(_projmonth);
                    _cmd.Parameters.Add(_batchId);
                    _cmd.CommandText = _sqldelete;
                    _cmd.CommandTimeout = 900;
                    _cmd.CommandType = CommandType.Text;

                    var retVal = _cmd.ExecuteScalar();
                    if (retVal != null) throw new Exception("DeleteBatchRevJC: Failed. Check for connectivity issues \nand make sure Viewpoint database is online.");

                    return true;
                }
            }
            catch (Exception) { throw; }
        }
    }
}
