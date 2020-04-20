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
        /// Insert Add-on Earnings 2-pairs and 3-pairs into MCKPRCFSLoad and MCKPRCFVLoad table
        /// </summary>
        /// <param name="batchId">Batch Id of current Craft Class Update</param>
        /// <param name="craftClasses">Craft Class Meta data</param>
        /// <param name="addonEarnings2pairs"></param>
        /// <param name="addonEarnings3pairs"></param>
        /// <param name="cancelToken">Cancellation token</param> 
        /// <returns>inserted record count</returns>
        public static uint AddonEarnings(uint? batchId
                                        , object[,] craftClasses
                                        , Dictionary<uint, List<KeyValuePair<int, decimal>>> addonEarnings2pairs
                                        , Dictionary<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>> addonEarnings3pairs
                                        , dynamic headers
                                        , CancellationTokenSource cancelToken)
        {
            if (batchId == 0 || batchId == null) throw new Exception("Missing Batch ID required to insert 'Addon Earnings'");
            SqlParameter _co = new SqlParameter("@Co", SqlDbType.Int);
            SqlParameter _craft = new SqlParameter("@Craft", SqlDbType.VarChar, 10);
            SqlParameter _class = new SqlParameter("@Class", SqlDbType.VarChar, 10);
            SqlParameter _earnCode = new SqlParameter("@EarnCode", SqlDbType.Int);
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
                    _cmd = new SqlCommand("dbo.MCKspPRCFSInsert", _conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    };
                    cancelToken.Token.Register(() => _cmd?.Cancel());

                    if (addonEarnings2pairs != null)
                    {
                        _factor.SqlValue = 0.00000m;

                        foreach (KeyValuePair<uint, List<KeyValuePair<int, decimal>>> row in addonEarnings2pairs)
                        {
                            foreach (KeyValuePair<int, decimal> addon_earning in row.Value)
                            {
                                cancelToken.Token.ThrowIfCancellationRequested();

                                _co.SqlValue    = craftClasses.GetValue(row.Key, headers.Company);
                                _craft.SqlValue = craftClasses.GetValue(row.Key, headers.MasterCraft);
                                _class.SqlValue = craftClasses.GetValue(row.Key, headers.CraftClass);
                                _earnCode.SqlValue = addon_earning.Key;
                                _rate.SqlValue = addon_earning.Value;

                                _cmd.Parameters.Add(_co);
                                _cmd.Parameters.Add(_batchId);
                                _cmd.Parameters.Add(_craft);
                                _cmd.Parameters.Add(_class);
                                _cmd.Parameters.Add(_earnCode);
                                _cmd.Parameters.Add(_factor);
                                _cmd.Parameters.Add(_rate);
                                _cmd.CommandTimeout = 600;
                                _cmd.ExecuteNonQuery();
                                _cmd.Parameters.Clear();
                                ++insertedCnt;
                            }
                        }
                    }

                    if (addonEarnings3pairs != null)
                    {
                        // 3-PAIRS - variable
                        //_sql = @"EXEC dbo.MCKspPRCFVInsert @Co=@Co, @Craft=@Craft, @Class=@Class, @EarnCode=@EarnCode, @Factor=@Factor, @Rate=@Rate, @Rbatchid=@batchId;";

                        _cmd = new SqlCommand("dbo.MCKspPRCFVInsert", _conn)
                        {
                            CommandType = CommandType.StoredProcedure
                        };
                        cancelToken.Token.Register(() => _cmd?.Cancel());

                        foreach (KeyValuePair<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>> row in addonEarnings3pairs)
                        {
                            foreach (KeyValuePair<int, KeyValuePair<decimal, decimal>> earnCode_rate_amount in row.Value)
                            {
                                cancelToken.Token.ThrowIfCancellationRequested();

                                _co.SqlValue    = craftClasses.GetValue(row.Key, headers.Company);
                                _craft.SqlValue = craftClasses.GetValue(row.Key, headers.MasterCraft);
                                _class.SqlValue = craftClasses.GetValue(row.Key, headers.CraftClass);
                                _earnCode.SqlValue = earnCode_rate_amount.Key;
                                _factor.SqlValue = earnCode_rate_amount.Value.Key;   // factor 
                                _rate.SqlValue = earnCode_rate_amount.Value.Value; // amount

                                _cmd.Parameters.Add(_co);
                                _cmd.Parameters.Add(_batchId);
                                _cmd.Parameters.Add(_craft);
                                _cmd.Parameters.Add(_class);
                                _cmd.Parameters.Add(_earnCode);
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
                _earnCode = null;
                _factor = null;
                _rate = null;
            }
            return insertedCnt;
        }
    }
}
