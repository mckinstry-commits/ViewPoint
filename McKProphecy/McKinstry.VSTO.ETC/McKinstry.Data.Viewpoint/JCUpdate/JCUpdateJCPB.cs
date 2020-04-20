using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint.JCUpdate
{
    public class JCUpdateJCPB
    {
        public static int SumUpdateJCPB(byte JCCo, DateTime jectMonth, string Job, uint batchId, DataTable table)
        {
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo == 0 ? (object)DBNull.Value : JCCo;

            SqlParameter _mth = new SqlParameter("@mth", SqlDbType.DateTime);
            _mth.SqlValue = jectMonth == null ? (object)DBNull.Value : jectMonth;

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            _job.SqlValue = Job == null ? (object)DBNull.Value : Job;

            SqlParameter _batchId = new SqlParameter("@BatchId", SqlDbType.Int);
            _batchId.SqlValue = batchId == 0x0 ? (object)DBNull.Value : batchId;

            SqlParameter _phase = new SqlParameter("@Phase", SqlDbType.VarChar, 20);
            SqlParameter _costtype = new SqlParameter("@CostType", SqlDbType.TinyInt);
            SqlParameter _projhours = new SqlParameter("@ProjHours", SqlDbType.Decimal);
            SqlParameter _projcost = new SqlParameter("@ProjCost", SqlDbType.Float);

            int updated = 0;
            int updatedTotal = 0;

            SqlCommand _cmd = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    foreach (DataRow row in table.Rows)
                    {
                        _phase.SqlValue = row.Field<string>("Phase Code");
                        _costtype.SqlValue = row.Field<char>("Cost Type");
                        _projhours.SqlValue = row.Field<decimal>("Projected Hours");
                        _projcost.SqlValue = row.Field<decimal>("Projected Cost");

                        string _sql = @"UPDATE JCPB 
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
                        _cmd.CommandTimeout = 900;
                        updated = _cmd.ExecuteNonQuery();
                        updatedTotal += updated;
                        _cmd.Parameters.Clear();
                    }

                    return updatedTotal;
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, 4);
                throw ex;
            } 
            finally { _cmd?.Dispose(); }
        }
    }
}
