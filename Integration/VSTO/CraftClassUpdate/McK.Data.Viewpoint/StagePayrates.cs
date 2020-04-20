using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading;

namespace McK.Data.Viewpoint
{
    /// <summary>
    /// PRCP PR Class Pay Rate
    /// </summary>
    public static partial class Stage
    {
        /// <summary>
        /// Insert Payrates into the PRCPInsert table
        /// </summary>
        /// <param name="batchId">Batch Id of current Craft Class Update</param>
        /// <param name="craftClasses">Craft Class Meta data</param>
        /// <param name="shiftPayrates">All shift and payrate records</param>
        /// <param name="cancelToken">Cancellation token</param> 
        /// <returns>inserted record count</returns>
        public static uint Payrates(
                                    uint? batchId, 
                                    object[,] craftClasses, 
                                    Dictionary<uint,List<KeyValuePair<int, decimal>>> shiftPayrates,
                                    dynamic headers,
                                    CancellationTokenSource cancelToken)
        {
            if (batchId == 0 || batchId == null) throw new Exception("Missing Batch ID required to insert 'Pay Rates'");

            SqlParameter _co    = new SqlParameter("@Co", SqlDbType.Int);
            SqlParameter _craft = new SqlParameter("@Craft", SqlDbType.VarChar, 10);
            SqlParameter _class = new SqlParameter("@Class", SqlDbType.VarChar, 10);
            SqlParameter _shift = new SqlParameter("@Shift", SqlDbType.Int);
            SqlParameter _rate  = new SqlParameter("@Rate", SqlDbType.Decimal)
            {
                Precision = 16,
                Scale = 5
            };
            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.VarChar, 30)
            {
                SqlValue = batchId
            };

            SqlCommand _cmd;
            uint insertCnt = 0;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    _cmd = new SqlCommand("dbo.MCKspPRCPInsert", _conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    };
                    cancelToken.Token.Register(() => _cmd?.Cancel());

                    foreach (KeyValuePair<uint, List<KeyValuePair<int, decimal>>> row in shiftPayrates)
                    {
                        // shiftPayrates.Key   = row
                        // shiftPayrates.Value = shift and payrate
                        foreach (KeyValuePair<int, decimal> shift_payrate in row.Value)
                        {
                            cancelToken.Token.ThrowIfCancellationRequested();

                            _co.SqlValue    = craftClasses.GetValue(row.Key, headers.Company);
                            _craft.SqlValue = craftClasses.GetValue(row.Key, headers.MasterCraft); 
                            _class.SqlValue = craftClasses.GetValue(row.Key, headers.CraftClass);
                            _shift.SqlValue = shift_payrate.Key;
                            _rate.SqlValue  = shift_payrate.Value;

                            _cmd.Parameters.Add(_co);
                            _cmd.Parameters.Add(_batchId);
                            _cmd.Parameters.Add(_craft);
                            _cmd.Parameters.Add(_class);
                            _cmd.Parameters.Add(_shift);
                            _cmd.Parameters.Add(_rate);
                            _cmd.CommandTimeout = 600;
                            _cmd.ExecuteNonQuery();

                            ++insertCnt;
                            _cmd.Parameters.Clear();
                        }
                    }

                } // close connection
            }
            catch (OperationCanceledException) {  }    // suppress cancel exception, re-throw others
            catch (SqlException) { }
            //catch (Exception ex)
            //{
            //    ex.Data.Add(0, "MCKspPRCPInsert");
            //    throw;
            //}
            finally
            {
                _cmd = null;
                _co = null;
                _batchId = null;
                _craft = null;
                _class = null;
                _shift = null;
                _rate = null;
            }
            return insertCnt;
        }
    }
}
