using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public static class HelperData
    {
        public static AppSettingsReader _config
        {
            get { return new AppSettingsReader(); }
        }

        public static string _conn_string
        {
            get { return (string)_config.GetValue("ViewpointConnection", typeof(string)); }
        }

        public static List<DateTime> GetValidMonths(byte JCCo)
        {
            // setup database connectivity
            DataTable resultTable = new DataTable();
            //DateTime dtEndMonth;
            //DateTime dtBeginMonth;
            List<DateTime> lstMonths = new List<DateTime>();

            // setup query
            string _sql = "select * from mers.mfnJCBatchAllowedDates (@JCCo)";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);

            _co.Value = DBNull.Value;

            if (JCCo == 0)
            {
                _co.SqlValue = DBNull.Value;
            }
            else
            {
                _co.SqlValue = JCCo;
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();
                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "Valid Months";

                //DateTime ValidMonth;

                foreach (DataRow dr in resultTable.Rows)
                {
                    //ValidMonth = dr.Field<DateTime>("batchmonth");
                    lstMonths.Add(dr.Field<DateTime>("batchmonth"));

                    //dtEndMonth = resultTable.Rows[0].Field<DateTime>("LastMthSubClsd");
                    //int maxOpen = resultTable.Rows[0].Field<byte>("MaxOpen");
                    //set begin month (default to Sub Ledgers)
                    //dtBeginMonth = dtEndMonth.AddMonths(1);
                    //lstMonths.Add(dtBeginMonth);
                    //set end month to last mth closed in subledgers + max # of open mths
                    //dtEndMonth = dtEndMonth.AddMonths(maxOpen);
                    //lstMonths.Add(dtEndMonth);

                }
            }
            catch (Exception)
            {
                throw; // to UI
            }

            finally
            {
                if (!(_conn.State == ConnectionState.Closed))
                {
                    _conn.Close();
                }
                _conn = null;
            }
            return lstMonths;
        }

        public static bool JobHasProjections(string jobId)
        {
            DataTable resultTable = new DataTable();
            List<DateTime> lstMonths = new List<DateTime>();

            string _sql = "select count(*) from JCPB where Job=@jobId;";
            int count = 0;

            SqlParameter _jobId = new SqlParameter("@jobId", SqlDbType.VarChar, 10);
            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            _jobId.Value = DBNull.Value;
            _jobId.SqlValue = jobId == null ? (object)DBNull.Value : jobId;

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_jobId);
                SqlDataAdapter _da = new SqlDataAdapter(_cmd);
                count = (int)_cmd.ExecuteScalar();
            }
            catch (Exception)
            {
                throw; // to UI
            }

            finally
            {
                if (!(_conn.State == ConnectionState.Closed))
                {
                    _conn.Close();
                }
                _conn = null;
            }
            return count > 0;
        }

        public static object[] GetBatchSeqPhaseGroup(byte JCCo, DateTime projectionMonth, string job, uint batchId, string phase, byte CostType)
        {
            string _sql;
            const string func = "GetBatchSeqPhaseGroup: ";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _mth = new SqlParameter("@mth", SqlDbType.DateTime);
            SqlParameter _job = new SqlParameter("@job", SqlDbType.VarChar, 10);
            SqlParameter _batchid = new SqlParameter("@batchId", SqlDbType.Int);
            SqlParameter _phase = new SqlParameter("@phase", SqlDbType.VarChar, 20);
            SqlParameter _costtype = new SqlParameter("@CostType", SqlDbType.TinyInt);
            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd;

            if (JCCo != 0)
            {
                _co.SqlValue = JCCo;
            }
            else
            {
                throw new Exception(func + "Invalid JC Company:" + JCCo);
            }

            if (projectionMonth != null)
            {
                _mth.SqlValue = projectionMonth;
            }
            else
            {
                throw new Exception(func + "Missing Projection Month");
            }

            if (job != "")
            {
                _job.SqlValue = job;
            }
            else
            {
                throw new Exception(func + "Missing Project (Job ID)");
            }

            if (batchId != 0)
            {
                _batchid.SqlValue = batchId;
            }
            else
            {
                throw new Exception(func + "Invalid Batch ID: " + batchId);
            }

            if (phase != "")
            {
                _phase.SqlValue = phase;
            }
            else
            {
                throw new Exception(func + "Missing Phase ID");
            }
            if (CostType != 0)
            {
                _costtype.SqlValue = CostType;
            }
            else
            {
                throw new Exception(func + "Invalid Cost Type" + CostType);
            }
            try
            {
                _conn.Open();

                _sql = @"SET NOCOUNT ON; select x.BatchSeq, x.PhaseGroup from JCPB x
                             WHERE Co = @JCCo
                             AND Mth = @mth
                             AND Job = @job
                             AND BatchId = @batchId
                             AND Phase = @phase
                             AND CostType = @CostType";
                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_mth);
                _cmd.Parameters.Add(_job);
                _cmd.Parameters.Add(_batchid);
                _cmd.Parameters.Add(_phase);
                _cmd.Parameters.Add(_costtype);
                _cmd.CommandTimeout = 600000;

                using (SqlDataReader reader = _cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        Object[] values = new Object[reader.FieldCount];
                        int fieldCount = reader.GetValues(values);
                        return values;
                    }
                    else throw new Exception("Unable to get BatchSeq and PhaseGroup.  Please verify that this Batch is still open in Viewpoint, if not the McKinstry Projections tool should be relaunched.");
                }
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                HelperData.SqlCleanup(out _sql, out _cmd, _conn);
            }
        }

        public static void SqlCleanup(out string _sql, out SqlCommand _cmd, SqlConnection _conn)
        {
            _sql = null;
            _cmd = null;
            if (!(_conn?.State == ConnectionState.Closed))
            {
                _conn.Close();
            }
            _conn = null;
        }

    }
}
