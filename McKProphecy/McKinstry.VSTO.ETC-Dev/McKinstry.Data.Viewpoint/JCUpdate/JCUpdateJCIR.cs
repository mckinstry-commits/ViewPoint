using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
 
namespace McKinstry.Data.Viewpoint.JCUpdate
{
    public class JCUpdateJCIR
    {
        public static int SumUpdateJCIR(byte JCCo, DateTime projectionMonth, string contract, uint batchId, DataTable table, string login)
        {
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _mth = new SqlParameter("@mth", SqlDbType.DateTime);
            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
            SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10);
            SqlParameter _contractItem = new SqlParameter("@contractItem", SqlDbType.VarChar, 20);
            SqlParameter _jectChanges = new SqlParameter("@jectChanges", SqlDbType.Float);

            _co.SqlValue = JCCo == 0 ? (object)DBNull.Value : JCCo;
            _mth.SqlValue = projectionMonth == null ? (object)DBNull.Value : projectionMonth;
            _contract.SqlValue = contract == null ? (object)DBNull.Value : contract;
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
                    _contractItem.SqlValue = row.Field<string>("Contract Item"); 
                    _jectChanges.SqlValue = row.Field<decimal>("Projected Contract"); 

                    _sql = @"UPDATE JCIR 
                            SET RevProjDollars = @jectChanges
                            WHERE Co = @JCCo
                            AND Mth = @mth
                            AND BatchId = @batchId
                            AND Contract = @contract
                            AND RTRIM(LTRIM(Item)) =  RTRIM(LTRIM(@contractItem))";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_mth);
                    _cmd.Parameters.Add(_batchId);
                    _cmd.Parameters.Add(_contract);
                    _cmd.Parameters.Add(_contractItem);
                    _cmd.Parameters.Add(_jectChanges);
                    _cmd.CommandTimeout = 600000;
                    updated = _cmd.ExecuteNonQuery();
                    updatedTotal += updated;
                    _cmd.Parameters.Clear();
                }
                if (updatedTotal == table.Rows.Count)
                {
                    LogProphecyAction.InsProphecyLog(login, 7, JCCo, contract, null, projectionMonth, batchId, null, updatedTotal + " of " + table.Rows.Count);
                }
                else
                {
                    LogProphecyAction.InsProphecyLog(login, 16, JCCo, contract, null, projectionMonth, batchId, null, updatedTotal + " of " + table.Rows.Count);
                }
                return updatedTotal;
            }
            catch (Exception) {
                LogProphecyAction.InsProphecyLog(login, 16, JCCo, contract, null, projectionMonth, batchId, null, updatedTotal + " of " + table.Rows.Count);
                throw new Exception("SumUpdateJCIR: there were errors saving your batch - access Viewpoint/JC Revenue Projections to determine the issue");
            } // to UI
            finally
            {
                HelperData.SqlCleanup(out _sql, out _cmd, _conn);
            }
        }
    }
}
