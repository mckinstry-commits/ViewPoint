using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class InsertCostBatchJCPBETC
    {
        // Bulk copy implementation - 1 atomic operation (fastest)
        public static void InsCostJCPBETC(byte JCCo, DateTime Month, uint costBatchId, DataTable dtJCPBETC)
        {
        
            string _sql = "select count(*) from mckJCPBETC WHERE Mth=@mth AND JCCo=@JCCo AND BatchId=@batchId;";

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

                    int selectCount = (int)result;

                    if (selectCount > 0)
                    {
                        _sql = "delete from mckJCPBETC WHERE Mth=@mth AND JCCo=@JCCo AND BatchId=@batchId;";

                        _cmd.Parameters.Clear();

                        _cmd = dbConnection.CreateCommand();
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_batchId);
                        _cmd.Parameters.Add(_month);
                        _cmd.CommandText = _sql;
                        _cmd.CommandTimeout = 900;
                        _cmd.CommandType = CommandType.Text;
                        _cmd.ExecuteScalar();
                    }

                    // bulk copy our table (SQL rollsback if unsuccessful)
                    using (SqlBulkCopy s = new SqlBulkCopy(dbConnection.ConnectionString, SqlBulkCopyOptions.FireTriggers | SqlBulkCopyOptions.CheckConstraints))
                    {
                        s.DestinationTableName = dtJCPBETC.TableName;
                        foreach (var column in dtJCPBETC.Columns)
                        {
                            s.ColumnMappings.Add(column.ToString(), column.ToString());
                        }

                        s.WriteToServer(dtJCPBETC);
                    }
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, 4);
                throw ex;
            }
        }
    }
}