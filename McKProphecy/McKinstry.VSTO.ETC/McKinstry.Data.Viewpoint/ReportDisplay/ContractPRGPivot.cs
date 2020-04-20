using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class ContractPRGPivot
    {
        public static DataTable GetContractPRGPivotTable(byte Company, string ContractId)
        {
            DataTable resultTable = new DataTable();

            //string _sql = String.Format("select JCCo, Job, Description as JobDescription from JCJM where JCCo in (1,20) and Contract='{0}' order by JCCo, Job", ContractId);

            string _sql = "EXECUTE mers.mspJCPRGPivot @JCCo, @Contract";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt)
            {
                SqlValue = Company != 0 ? Company : (object)DBNull.Value
            };

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10)
            {
                SqlValue = ContractId ?? (object)DBNull.Value
            };

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_contract);
                        _cmd.CommandTimeout = 60;

                        using (SqlDataAdapter _da = new SqlDataAdapter(_cmd))
                        {
                            _da.Fill(resultTable);
                            resultTable.TableName = "ContractPRGPivot";
                        }
                    }
                }
            }
            catch (SqlException ex)
            {
                if (ex.Number == -2)
                {
                    //handle timeout
                    //throw new Exception("It's possible the WIP may be refreshing.", ex);

                    throw new Exception("This contract was unable to load a Projected Revenue Curve.  This is a known issue.\n\n" +
                                "We recommend using the MCK Projected Future Revenue report as an alternative.\n\n" +
                                "The Resource & Project Management (RPM) platform will eventually be replacing this functionality.", ex);
                }
            }
            catch (Exception e)
            {
                throw new Exception("GetContractPRGPivotTable:\n" + e.Message, e);
            }
            return resultTable;
        }
    }
}
