using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint.JCDelete
{
    public static class DeleteBatchJCPD
    {
        public static bool DeleteBatchFromJCPD(byte JCCo, DateTime ProjMonth, uint batchId, out uint DetSeq, out int deletedRows)
        {
            string _sqlselect = "SET NOCOUNT OFF; select count(*) from JCPD where Co = @JCCo AND Mth = @Month AND BatchId=@batchId AND TransType='A';";
            string _sqldelete = "SET NOCOUNT OFF; delete from JCPD where Co = @JCCo AND Mth = @Month AND BatchId=@batchId AND TransType='A';";
            string _sqlupdate = "SET NOCOUNT OFF; UPDATE JCPD SET TransType = 'D', Employee= NULL WHERE Co = @JCCo AND Mth = @Month AND BatchId=@batchId AND TransType='C';";
            string _sqlmaxdetseq = "SET NOCOUNT OFF; SELECT MAX(DetSeq) FROM JCPD WHERE Co = @JCCo AND Mth = @Month AND BatchId=@batchId;";

            int batchRowCnt = 0;
            int affectedRows = 0;
            int updatedRows = 0;
            uint DetSeqCheck = 0;
            DetSeq = 0;

            SqlParameter _jcco = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            if (JCCo == 0) throw new Exception("DeleteBatchFromJCPD: Invalid Company: " + _jcco);
            _jcco.SqlValue = JCCo;

            SqlParameter _projmonth = new SqlParameter("@Month", SqlDbType.DateTime);
            if (ProjMonth == null) throw new Exception("DeleteBatchFromJCPD: Invalid Month: " + _projmonth);
            _projmonth.SqlValue = ProjMonth;

            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
            if (batchId == 0) throw new Exception("DeleteBatchFromJCPD: Invalid Batch Id: " + _batchId);
            _batchId.SqlValue = batchId;

            using (SqlConnection dbConnection = new SqlConnection(HelperData._conn_string))
            {
                dbConnection.Open();

                string errmsg = "DeleteBatchFromJCPD: Failed. Check for connectivity issues \nand make sure Viewpoint database is online.";

                //  # of rows in the batch?
                using (SqlCommand _cmd = dbConnection.CreateCommand())
                {
                    _cmd.Parameters.Add(_jcco);
                    _cmd.Parameters.Add(_projmonth);
                    _cmd.Parameters.Add(_batchId);
                    _cmd.CommandText = _sqlselect;
                    _cmd.CommandTimeout = 900;
                    _cmd.CommandType = CommandType.Text;

                    var retVal = _cmd.ExecuteScalar();
                    if (retVal == DBNull.Value) throw new Exception(errmsg);
                    batchRowCnt = (int)retVal;

                    _cmd.CommandText = _sqldelete;
                    affectedRows = _cmd.ExecuteNonQuery();
                    deletedRows = affectedRows;

                    _cmd.CommandText = _sqlupdate;
                    updatedRows = _cmd.ExecuteNonQuery();

                    _cmd.CommandText = _sqlmaxdetseq;
                    var res = _cmd.ExecuteScalar();

                    if (res != DBNull.Value)
                    {
                        DetSeqCheck = UInt32.Parse(res.ToString());
                    }

                    if (DetSeqCheck > 0)
                    {
                        DetSeq = DetSeqCheck;
                    }
                }
            }

            // compare row count and return diff
            return affectedRows == batchRowCnt;
        }
    }
}
