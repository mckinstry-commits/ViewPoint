using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading;

namespace McK.Data.Viewpoint
{
    public static partial class Stage
    {
        /// <summary>
        /// Insert PRCC Craft Class rows into the PRCCInsert table which also acts as a history/audit table
        /// </summary>
        /// <param name="batchId">Batch Id of current Craft Class Update</param>
        /// <param name="craftClasses">Craft Class Meta data</param>
        /// <param name="loadRows">dirty rows</param>
        ///// <param name="iProgress">IProgress<int> reports back progress to UI thread</param> 
        /// <param name="cancelToken">Cancellation token</param> 
        /// <returns>inserted record count</returns>
        public static uint CraftClasses(
                       uint? batchId, 
                       object[,] craftClasses,
                       dynamic headers,
                       List<uint> loadRows, 
                       //IProgress<int> iProgress,
                       CancellationTokenSource cancelToken) 
        {
            if (batchId == 0 || batchId == null) throw new Exception("Missing Batch ID required to insert 'Info and Notes'");
            SqlParameter _co = new SqlParameter("@Co", SqlDbType.Int);
            SqlParameter _craft = new SqlParameter("@Craft", SqlDbType.VarChar, 10);
            SqlParameter _class = new SqlParameter("@Class", SqlDbType.VarChar, 10);
            SqlParameter _desc = new SqlParameter("@Description", SqlDbType.VarChar, 30);
            SqlParameter _EEOClass = new SqlParameter("@EEOClass", SqlDbType.Char, 1);
            SqlParameter _caplimit = new SqlParameter("@CapLimit", SqlDbType.Decimal)
            {
                Precision = 16,
                Scale = 6
            };
            SqlParameter _notes = new SqlParameter("@Notes", SqlDbType.VarChar, 255);
            SqlParameter _shopYN = new SqlParameter("@udShopYN", SqlDbType.Char, 1);
            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.VarChar, 30)
            {
                SqlValue = batchId
            };

            uint insertedCnt = 0;

            SqlCommand _cmd;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    _cmd = new SqlCommand("dbo.MCKspPRCCInsert", _conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    };
                    cancelToken.Token.Register(() => _cmd?.Cancel());

                    _caplimit.SqlValue = DBNull.Value;
                
                    for (int n = 0; n < loadRows.Count; n++)
                    {
                        cancelToken.Token.ThrowIfCancellationRequested();

                        _co.SqlValue        = craftClasses.GetValue(loadRows[n], headers.Company);
                        _craft.SqlValue     = craftClasses.GetValue(loadRows[n], headers.MasterCraft);
                        _class.SqlValue     = craftClasses.GetValue(loadRows[n], headers.CraftClass);
                        _desc.SqlValue      = craftClasses.GetValue(loadRows[n], headers.Description);
                        _EEOClass.SqlValue  = craftClasses.GetValue(loadRows[n], headers.EEOClass);
                        _notes.SqlValue     = craftClasses.GetValue(loadRows[n], headers.NotesSubTrade);
                        _shopYN.SqlValue    = craftClasses.GetValue(loadRows[n], headers.Shop);

                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.Parameters.Add(_craft);
                        _cmd.Parameters.Add(_class);
                        _cmd.Parameters.Add(_desc);
                        _cmd.Parameters.Add(_EEOClass);
                        _cmd.Parameters.Add(_caplimit);
                        _cmd.Parameters.Add(_notes);
                        _cmd.Parameters.Add(_shopYN);
                        _cmd.CommandTimeout = 600;
                        _cmd.ExecuteNonQuery();

                        //iProgress.Report(1);
                        ++insertedCnt;
                        _cmd.Parameters.Clear();
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
                _desc = null;
                _EEOClass = null;
                _caplimit = null;
                _notes = null;
                _shopYN = null;
            }
                return insertedCnt;
        }
    }
}
