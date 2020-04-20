using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

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

        public static List<string> GetValidMonths(byte JCCo)
        {
            string _sql = "select * from mers.mfnJCBatchAllowedDates (@JCCo)";

            //DateTime dtEndMonth;
            //DateTime dtBeginMonth;
            List<string> lstMonths;

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo != 0x0 ? JCCo : (object)DBNull.Value;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.CommandTimeout = 900;

                        //DateTime ValidMonth;
                        lstMonths = new List<string>();

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                lstMonths.Add(reader.GetDateTime(1).ToString("MM/yyyy"));
                            }
                        }
                        return lstMonths;

                        //ValidMonth = dr.Field<DateTime>("batchmonth");
                        // lstMonths.Add(dr.Field<DateTime>("batchmonth"));

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
            }
            catch (Exception) { throw; } // to UI
        }

        //public static bool JobHasProjections(string jobId)
        //{
        //    string _sql = "select count(*) from JCPB where Job=@jobId;";

        //    SqlParameter _jobId = new SqlParameter("@jobId", SqlDbType.VarChar, 10);
        //    _jobId.SqlValue = jobId == null ? (object)DBNull.Value : jobId;

        //    try
        //    {
        //        using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
        //        {
        //            _conn.Open();

        //            using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
        //            {
        //                _cmd.Parameters.Add(_jobId);

        //                using (SqlDataAdapter _da = new SqlDataAdapter(_cmd))
        //                {
        //                    return (int)_cmd.ExecuteScalar() > 0;
        //                }
        //            }
        //        }
        //    }
        //    catch (Exception) { throw; } // to UI
        //}

        public static object[] GetBatchSeqPhaseGroup(byte JCCo, DateTime jectMonth, string job, uint batchId, string phase, byte CostType)
        {
            string _sql;
            const string func = "GetBatchSeqPhaseGroup: ";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            if (JCCo == 0x0) throw new Exception(func + "Invalid JC Company:" + JCCo);
            _co.SqlValue =  JCCo;

            SqlParameter _mth = new SqlParameter("@mth", SqlDbType.DateTime);
            if (jectMonth == null) throw new Exception(func + "Missing Projection Month");
            _mth.SqlValue = jectMonth;

            SqlParameter _job = new SqlParameter("@job", SqlDbType.VarChar, 10);
            if (job == "") throw new Exception(func + "Missing Project (Job ID)");
            _job.SqlValue = job;

            SqlParameter _batchid = new SqlParameter("@batchId", SqlDbType.Int);
            if (batchId == 0)throw new Exception(func + "Invalid Batch ID: " + batchId);
            _batchid.SqlValue = batchId;

            SqlParameter _phase = new SqlParameter("@phase", SqlDbType.VarChar, 20);
            if (phase == "") throw new Exception(func + "Missing Phase ID");
            _phase.SqlValue = phase;

            SqlParameter _costtype = new SqlParameter("@CostType", SqlDbType.TinyInt);
            
            if (CostType == 0) throw new Exception(func + "Invalid Cost Type" + CostType);
            _costtype.SqlValue = CostType;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    _sql = @"SET NOCOUNT ON; select x.BatchSeq, x.PhaseGroup from JCPB x
                             WHERE Co = @JCCo
                             AND Mth = @mth
                             AND Job = @job
                             AND BatchId = @batchId
                             AND Phase = @phase
                             AND CostType = @CostType";
                    using (SqlCommand _cmd = new SqlCommand(_sql, _conn))
                    {
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_mth);
                        _cmd.Parameters.Add(_job);
                        _cmd.Parameters.Add(_batchid);
                        _cmd.Parameters.Add(_phase);
                        _cmd.Parameters.Add(_costtype);
                        _cmd.CommandTimeout = 900;

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
                }
            }
            catch (Exception) { throw; } // to UI
        }
    }
}
