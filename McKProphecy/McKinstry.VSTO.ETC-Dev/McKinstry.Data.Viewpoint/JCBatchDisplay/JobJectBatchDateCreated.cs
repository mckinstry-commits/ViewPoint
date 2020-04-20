using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class JobJectBatchDateCreated
    {
        public static DataTable GetJobJectBatchDateCreated(byte Company, string JobId, DateTime Month)
        {
            DataTable resultTable = new DataTable();

            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            SqlParameter _bMonth = new SqlParameter("@Month", SqlDbType.Date);

            SqlParameter _source = new SqlParameter("@source", SqlDbType.VarChar, 10);
            _source.SqlValue = "JC Projctn";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = Company == 0 ? (object)DBNull.Value : Company;

            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
            _batchId.SqlValue = JobId == null ? (object)DBNull.Value : JobId;


            _co.SqlValue = JobId == null ? (object)DBNull.Value : JobId;


            _co.SqlValue = Month == null ? (object)"01-JUL-2016" : Month;



            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd = new SqlCommand("select DateCreated from HQBC WHERE Co=@JCCo AND BatchId=@batchId AND Source=@source AND Mth=@openMonth;", _conn);

            try
            {
                _conn.Open();
                _cmd.Parameters.Add(_co);
                //_cmd.Parameters.Add(_batch);
                //_cmd.Parameters.Add(_source);
                //_cmd.Parameters.Add(_openmonth);
                _cmd.CommandTimeout = 600000;
                var result = _cmd
            }
            catch (Exception e)
            {
                throw new Exception("Batch_Projection_Pivot Exception", e);
            }
            finally
            {
                if (!(_conn.State == ConnectionState.Closed))
                {
                    _conn.Close();
                }
                _conn = null;
            }

            return resultTable;
        }
    }
}
