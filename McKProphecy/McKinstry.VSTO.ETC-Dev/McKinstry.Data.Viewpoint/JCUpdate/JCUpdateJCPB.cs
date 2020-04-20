using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
 
namespace McKinstry.Data.Viewpoint.JCUpdate
{
    public class JCUpdateJCPB
    {
        public static int SumUpdateJCPB(byte JCCo, DateTime projectionMonth, string Job, uint batchId, DataTable table)
        {
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _mth = new SqlParameter("@mth", SqlDbType.DateTime);
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            SqlParameter _phase = new SqlParameter("@Phase", SqlDbType.VarChar, 20);
            SqlParameter _costtype = new SqlParameter("@CostType", SqlDbType.TinyInt);
            SqlParameter _projhours = new SqlParameter("@ProjHours", SqlDbType.Int);
            SqlParameter _projcost = new SqlParameter("@ProjCost", SqlDbType.Float);
            SqlParameter _batchId = new SqlParameter("@BatchId", SqlDbType.Int);

            _co.SqlValue = JCCo == 0 ? (object)DBNull.Value : JCCo;
            _mth.SqlValue = projectionMonth == null ? (object)DBNull.Value : projectionMonth;
            _job.SqlValue = Job == null ? (object)DBNull.Value : Job;
            _batchId.SqlValue = batchId == 0x0 ? (object)DBNull.Value : batchId;
            
            int updated = 0;
            int updatedTotal = 0; 

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd;
            string _sql;

            try
            {
                _conn.Open();

                foreach (DataRow row in table.Rows)
                {
                    _phase.SqlValue = row.Field<string>("Phase Code"); 
                    _costtype.SqlValue = row.Field<char>("Cost Type");
                    _projhours.SqlValue = row.Field<decimal>("Projected Hours"); 
                    _projcost.SqlValue = row.Field<decimal>("Projected Cost"); 

                    _sql = @"UPDATE JCPB 
                            SET ProjFinalHrs = @ProjHours, ProjFinalCost = @ProjCost 
                            WHERE Co = @JCCo 
                            AND Mth = @mth 
                            AND Job = @Job 
                            AND Phase = @Phase
                            AND CostType = @CostType
                            AND BatchId = @BatchId;";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_mth);
                    _cmd.Parameters.Add(_job);
                    _cmd.Parameters.Add(_batchId);
                    _cmd.Parameters.Add(_phase);
                    _cmd.Parameters.Add(_costtype);
                    _cmd.Parameters.Add(_projhours);
                    _cmd.Parameters.Add(_projcost);
                    _cmd.CommandTimeout = 600000;
                    updated = _cmd.ExecuteNonQuery();
                    updatedTotal += updated;
                    _cmd.Parameters.Clear();
                }

                return updatedTotal;
            }
            catch (Exception){ throw; } // to UI
            finally
            {
                HelperData.SqlCleanup(out _sql, out _cmd, _conn);
            }
        }
    }
}
