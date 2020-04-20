using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class LaborPivotSearch
    {
        public static string GetLaborPivot(byte Company, string JobId)
        {
            DataTable resultTable = new DataTable();

            string _sql = @"SELECT @laborPivot = ISNULL(udProjectionTemplate,'MTH') 
                            FROM JCJM 
                            WHERE JCCo = @JCCo 
                            AND Job = @Job";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            SqlParameter _laborPivot = new SqlParameter("@laborPivot", SqlDbType.VarChar, 3);

            _laborPivot.SqlValue = DBNull.Value;
            _laborPivot.Direction = ParameterDirection.Output;

            if (Company == 0)
            {
                _co.SqlValue = DBNull.Value;
            }
            else
            {
                _co.SqlValue = Company;
            }

            if (JobId == null)
            {
                _job.SqlValue = DBNull.Value;
            }
            else
            {
                _job.SqlValue = JobId;
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_job);
                _cmd.Parameters.Add(_laborPivot);
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();
                var result = _cmd.Parameters["@laborPivot"].Value;

                if (result == null) throw new Exception("GetLaborPivot: Unable get Labor pivot"); 

                return _cmd.Parameters["@laborPivot"].Value.ToString();
            }
            catch (Exception e)
            {
                throw new Exception("GetLaborPivot: " +  e.Message);
            }
            finally
            {
                if (!(_conn.State == ConnectionState.Closed))
                {
                    _conn.Close();
                }
                _conn = null;
            }
        }
    }
}
