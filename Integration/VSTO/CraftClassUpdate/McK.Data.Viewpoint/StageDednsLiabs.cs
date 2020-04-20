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
        /// Insert Deductions and Liabilities 2-pairs and 3-pairs into MCKPRCDSLoad and MCKPRCDVLoad tables
        /// </summary>
        /// <param name="batchId">Batch Id of current Craft Class Update</param>
        /// <param name="craftClasses">Craft Class Meta data</param>
        /// <param name="dednsLiabs2pairs"></param>
        /// <param name="dednsLiabs3pairs"></param>
        /// <param name="cancelToken">Cancellation token</param> 
        /// <returns>inserted record count</returns>
        public static uint DednsLiabs(uint? batchId
                                    , object[,] craftClasses 
                                    , Dictionary<uint, List<KeyValuePair<int, decimal>>> dednsLiabs2pairs
                                    , Dictionary<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>> dednsLiabs3pairs
                                    , dynamic headers
                                    , CancellationTokenSource cancelToken)
        {
            if (batchId == 0 || batchId == null) throw new Exception("Missing Batch ID required to insert 'Deductions and Liabilities'");
            SqlParameter _co = new SqlParameter("@Co", SqlDbType.Int);
            SqlParameter _craft = new SqlParameter("@Craft", SqlDbType.VarChar, 10);
            SqlParameter _class = new SqlParameter("@Class", SqlDbType.VarChar, 10);
            SqlParameter _dlcode = new SqlParameter("@DLCode", SqlDbType.Int);
            SqlParameter _factor = new SqlParameter("@Factor", SqlDbType.Decimal)
            {
                Precision = 8,
                Scale = 6
            };
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
            uint insertedCnt = 0;
            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    _cmd = new SqlCommand("dbo.MCKspPRCDSInsert", _conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    };
                    cancelToken.Token.Register(() => _cmd?.Cancel());

                    if (dednsLiabs2pairs != null)
                    {
                        _factor.SqlValue = 0.00000m;

                        foreach (KeyValuePair<uint, List<KeyValuePair<int, decimal>>> row in dednsLiabs2pairs)
                        {
                            foreach (KeyValuePair<int, decimal> addon_earning in row.Value)
                            {
                                cancelToken.Token.ThrowIfCancellationRequested();

                                _co.SqlValue     = craftClasses.GetValue(row.Key, headers.Company);
                                _craft.SqlValue  = craftClasses.GetValue(row.Key, headers.MasterCraft);
                                _class.SqlValue  = craftClasses.GetValue(row.Key, headers.CraftClass);
                                _dlcode.SqlValue = addon_earning.Key;
                                _rate.SqlValue   = addon_earning.Value;

                                _cmd.Parameters.Add(_co);
                                _cmd.Parameters.Add(_batchId);
                                _cmd.Parameters.Add(_craft);
                                _cmd.Parameters.Add(_class);
                                _cmd.Parameters.Add(_dlcode);
                                _cmd.Parameters.Add(_factor);
                                _cmd.Parameters.Add(_rate);
                                _cmd.CommandTimeout = 600;
                                _cmd.ExecuteNonQuery();
                                _cmd.Parameters.Clear();
                                ++insertedCnt;
                            }
                        }
                    }

                    if (dednsLiabs3pairs != null)
                    {
                        // 3-PAIRS - variable
                        //_sql = @"EXEC dbo.MCKspPRCDVInsert @Co=@Co, @Craft=@Craft, @Class=@Class, @DLCode=@DLCode, @Factor=@Factor, @Rate=@Rate, @Rbatchid=@batchId;";
                        _cmd = new SqlCommand("dbo.MCKspPRCDVInsert", _conn)
                        {
                            CommandType = CommandType.StoredProcedure
                        };
                        cancelToken.Token.Register(() => _cmd?.Cancel());

                        foreach (KeyValuePair<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>> row in dednsLiabs3pairs)
                        {
                            foreach (KeyValuePair<int, KeyValuePair<decimal, decimal>> dlcode_rate_amount in row.Value)
                            {
                                cancelToken.Token.ThrowIfCancellationRequested();

                                _co.SqlValue     = craftClasses.GetValue(row.Key, headers.Company);
                                _craft.SqlValue  = craftClasses.GetValue(row.Key, headers.MasterCraft);
                                _class.SqlValue  = craftClasses.GetValue(row.Key, headers.CraftClass);
                                _dlcode.SqlValue = dlcode_rate_amount.Key;
                                _factor.SqlValue = dlcode_rate_amount.Value.Key;
                                _rate.SqlValue   = dlcode_rate_amount.Value.Value;
                                
                                _cmd.Parameters.Add(_co);
                                _cmd.Parameters.Add(_batchId);
                                _cmd.Parameters.Add(_craft);
                                _cmd.Parameters.Add(_class);
                                _cmd.Parameters.Add(_dlcode);
                                _cmd.Parameters.Add(_factor);
                                _cmd.Parameters.Add(_rate);
                                _cmd.CommandTimeout = 900;
                                _cmd.ExecuteNonQuery();
                                _cmd.Parameters.Clear();
                                ++insertedCnt;
                            }
                        }
                    }
                } // close connection
            }
            catch (OperationCanceledException) { }    // suppress cancel exception, re-throw others
            catch (SqlException) { }
            finally
            {
                _cmd = null;
                _co = null;
                _batchId = null;
                _craft = null;
                _class = null;
                _dlcode = null;
                _factor = null;
                _rate = null;
            }
            return insertedCnt;
        }
    }
}
