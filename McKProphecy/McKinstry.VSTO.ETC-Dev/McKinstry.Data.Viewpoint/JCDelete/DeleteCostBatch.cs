using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint.JCDelete
{
    public static class DeleteCostBatch
    {
        public static bool DeleteBatchCost(byte JCCo, DateTime ProjMonth, uint batchId)
        {
            string _sqldelete = @"SET NOCOUNT OFF; declare @p5 varchar(60)
                                set @p5=NULL
                                exec dbo.bspJCPBBatchDelete @jcco=@JCCo, @mth=@Month, @batchid=@batchId, @source='JC Projctn',@errmsg=@p5 output";

            SqlParameter _jcco = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _projmonth = new SqlParameter("@Month", SqlDbType.DateTime);
            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);

            if (JCCo != 0)
            {
                _jcco.SqlValue = JCCo;
            }
            else
            {
                throw new Exception("DeleteBatchCost: Invalid Company: " + _jcco);
            }
            if (ProjMonth != null)
            {
                _projmonth.SqlValue = ProjMonth;
            }
            else
            {
                throw new Exception("DeleteBatchCost: Invalid Month: " + _projmonth);
            }
            if (batchId != 0)
            {
                _batchId.SqlValue = batchId;
            }
            else
            {
                throw new Exception("DeleteBatchCost: Invalid Batch Id: " + _batchId);
            }

            using (SqlConnection dbConnection = new SqlConnection(HelperData._conn_string))
            {
                dbConnection.Open();

                string errmsg = "DeleteBatchCost: Failed. Check for connectivity issues \nand make sure Viewpoint database is online.";

                SqlCommand _cmd = dbConnection.CreateCommand();
                _cmd.Parameters.Add(_jcco);
                _cmd.Parameters.Add(_projmonth);
                _cmd.Parameters.Add(_batchId);
                _cmd.CommandText = _sqldelete;
                _cmd.CommandTimeout = 600000;
                _cmd.CommandType = CommandType.Text;

                var retVal = _cmd.ExecuteScalar();
                if (retVal != null) throw new Exception(errmsg);

                return true;
            }

        }

    }
}
