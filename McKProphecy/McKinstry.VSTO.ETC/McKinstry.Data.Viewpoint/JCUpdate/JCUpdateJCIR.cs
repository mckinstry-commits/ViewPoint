using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint.JCUpdate
{
    public class JCUpdateJCIR
    {
        public static int SumUpdateJCIR(byte JCCo, DateTime jectMonth, string contract, uint batchId, DataTable table, string login)
        {
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo == 0 ? (object)DBNull.Value : JCCo;

            SqlParameter _mth = new SqlParameter("@mth", SqlDbType.DateTime);
            _mth.SqlValue = jectMonth == null ? (object)DBNull.Value : jectMonth;

            SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10);
            _contract.SqlValue = contract == null ? (object)DBNull.Value : contract;

            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
            _batchId.SqlValue = batchId == 0x0 ? (object)DBNull.Value : batchId;

            SqlParameter _contractItem = new SqlParameter("@contractItem", SqlDbType.VarChar, 20);
            SqlParameter _jectChanges = new SqlParameter("@jectChanges", SqlDbType.Decimal);
            SqlParameter _rNotes = new SqlParameter("@RNotes", SqlDbType.VarChar, 255);

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
                        _contractItem.SqlValue = row["Contract Item"];
                        _jectChanges.SqlValue = row["Projected Contract"] == DBNull.Value ? 0 : row["Projected Contract"];
                        _rNotes.SqlValue = row["Notes"] == DBNull.Value ? " " : row["Notes"];

                        string _sql = @"UPDATE JCIR 
                            SET RevProjDollars = @jectChanges
                            , RevProjPlugged = 'Y'
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
                            _cmd.CommandTimeout = 900;

                            updated = _cmd.ExecuteNonQuery();

                            updatedTotal += updated;
                            _cmd.Parameters.Clear();

                        //Add Revenue Projection Notes field Update
                        string _sql2 = @"UPDATE JCCI
                            SET ProjNotes = @RNotes
                            WHERE JCCo = @JCCo
                            AND Contract = @contract
                            AND RTRIM(LTRIM(Item)) =  RTRIM(LTRIM(@contractItem))";

                        _cmd = new SqlCommand(_sql2, _conn);
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_contract);
                        _cmd.Parameters.Add(_contractItem);
                        _cmd.Parameters.Add(_rNotes);
                        _cmd.CommandTimeout = 900;

                        updated = _cmd.ExecuteNonQuery();

                       // updatedTotal += updated;
                        _cmd.Parameters.Clear();

                    }
                    if (updatedTotal == table.Rows.Count)
                    {
                        LogProphecyAction.InsProphecyLog(login, 7, JCCo, contract, null, jectMonth, batchId, null, updatedTotal + " of " + table.Rows.Count);
                    }
                    else
                    {
                        LogProphecyAction.InsProphecyLog(login, 16, JCCo, contract, null, jectMonth, batchId, null, updatedTotal + " of " + table.Rows.Count);
                    }
                    return updatedTotal;
                }
            }
            catch (Exception)
            {
                LogProphecyAction.InsProphecyLog(login, 16, JCCo, contract, null, jectMonth, batchId, null, updatedTotal + " of " + table.Rows.Count);
                throw new Exception("SumUpdateJCIR: there were errors saving your batch - access Viewpoint/JC Revenue Projections to determine the issue");
            }
            finally { _cmd?.Dispose(); }
        }
    }
}
