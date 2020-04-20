using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class InsertCostBatchNonLaborJCPD
    {
        // Bulk copy implementation - 1 atomic operation (fastest)
        public static int InsCostJCPD(byte JCCo, DateTime Month, uint costBatchId, DataTable dtCostProjections)
        {
            string _sql = "select count(*) from JCPD WHERE Mth=@mth AND Co=@JCCo AND BatchId=@batchId;";
            int selectCount = 0;
            int affectedCount = 0;
            int deletedRows = 0;

            try
            {
                // Copy Cost Projecion DataTable to SQL Server in 1 atomic operation (fastest)
                using (SqlConnection dbConnection = new SqlConnection(HelperData._conn_string))
                {
                    dbConnection.Open();

                    SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
                    _co.SqlValue = JCCo == 0 ? (object)DBNull.Value : JCCo;

                    SqlParameter _month = new SqlParameter("@mth", SqlDbType.DateTime);
                    _month.SqlValue = Month == null ? (object)DBNull.Value : Month;

                    SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
                    _batchId.SqlValue = costBatchId == 0x0 ? (object)DBNull.Value : costBatchId;

                    //  # of rows in the batch?
                    SqlCommand _cmd = dbConnection.CreateCommand();
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_batchId);
                    _cmd.Parameters.Add(_month);
                    _cmd.CommandText = _sql;
                    _cmd.CommandTimeout = 900;
                    _cmd.CommandType = CommandType.Text;

                    var result = _cmd.ExecuteScalar();
                    if (result == DBNull.Value) throw new Exception("InsCostJCPD: Failed. Check for connectivity issues \nand make sure Viewpoint is online.");

                    selectCount = (int)result;
                    if (selectCount == 0)
                    {
                        try
                        {
                            // bulk copy our table (SQL rollsback if unsuccessful)
                            using (SqlBulkCopy s = new SqlBulkCopy(dbConnection.ConnectionString, SqlBulkCopyOptions.FireTriggers | SqlBulkCopyOptions.CheckConstraints))
                            {
                                s.DestinationTableName = dtCostProjections.TableName;
                                foreach (var column in dtCostProjections.Columns)
                                {
                                    s.ColumnMappings.Add(column.ToString(), column.ToString());
                                }

                                s.WriteToServer(dtCostProjections);
                            }
                        }
                        catch (Exception) { throw; }
                    }
                    else if (selectCount > 0)
                    {
                        uint detSeq;
                        // batch already in JCPD; delete and re-insert batch with new values
                        if (JCDelete.DeleteBatchJCPD.DeleteBatchFromJCPD(JCCo, Month, costBatchId, out detSeq, out deletedRows))
                        {
                            foreach (DataRow row in dtCostProjections.Rows)
                            {
                                row["DetSeq"] = detSeq + 1;
                                detSeq += 1;
                            }
                            //SELECT MAX(DetSeq) FROM JCPD WHERE Co = @JCCo AND Mth = @Month AND BatchId=@batchId;
                            try
                            {
                                // bulk copy our table (SQL rollsback if unsuccessful)
                                using (SqlBulkCopy s = new SqlBulkCopy(dbConnection.ConnectionString, SqlBulkCopyOptions.FireTriggers | SqlBulkCopyOptions.CheckConstraints))
                                {
                                    s.DestinationTableName = dtCostProjections.TableName;
                                    foreach (var column in dtCostProjections.Columns)
                                    {
                                        s.ColumnMappings.Add(column.ToString(), column.ToString());
                                    }

                                    s.WriteToServer(dtCostProjections);
                                }
                            }
                            catch (Exception) { throw; }
                        }
                    }
                    // # of rows are there now?
                    var endResult = _cmd.ExecuteScalar();
                    if (endResult == DBNull.Value) throw new Exception("InsCostJCPD: Failed. Check for connectivity issues \nand make sure Viewpoint is online.");
                    affectedCount = (int)endResult;
                }

                // compare row count and return diff
                return Math.Abs(affectedCount - (selectCount - deletedRows));
            }
            catch(Exception) { throw; }
        }

        // Insert implementation 
        //public static bool InsCostJCPD(DataTable dtCostProjections, Int32 batchId)
        //{

        //            if (batchSeq == DBNull.Value) throw new Exception("Unable to get Batch Sequence");

        //            _cmd.Parameters.Clear();


        //            _sql = @"INSERT INTO JCPD(Co,DetSeq,Mth,BatchId,BatchSeq,Source,JCTransType,TransType,ResTrans,Job,PhaseGroup,Phase,CostType
        //                    ,BudgetCode,EMCo,Equipment,PRCo,Craft,Class,Employee,Description,DetMth,FromDate,ToDate,Quantity,Units,UM,UnitHours 
        //                    ,Hours,Rate,UnitCost,Amount,Notes) 
        //                    values 
        //                    (@JCCo, @DetSeq, @Mth, @BatchId, @BatchSeq, 'JC Projctn', 'PB', 'A', NULL, @Job, @PhaseGroup, @Phase, @CostType, NULL, NULL, NULL, 
        //                     @JCCo, @Craft, @Class, @Employee, @Description, @DetMth, @FromDate, @ToDate,0,0,'HRS',0,0,0,0,@Amount,' ')";

       //                switch (Pivot)
        //                {
        //                    case "MONTH":
        //                        _todate.SqlValue = ToDate = FromDate.AddMonths(1);
        //                        _detmth.SqlValue = new DateTime(ToDate.Year, ToDate.Month, 1);
        //                        break;

        //                    case "WEEK":
        //                        _todate.SqlValue = FromDate;
        //                        _detmth.SqlValue = FromDate;
        //                        break;
        //                }
        //            }


    }
}