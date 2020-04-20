using System;
using System.Data;
using System.Data.SqlClient;

namespace McKinstry.Data.Viewpoint
{
    public class ProjectRevenue
    {
        public static bool GenerateRevenueProjection(byte JCCo, string contract, DateTime jectMonth, string login, out UInt32 batchId, out DateTime revBatchDateCreated)
        {
            string _sql;
            bool success;
            revBatchDateCreated = DateTime.Today;

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            if (JCCo == 0) throw new Exception("Invalid JC Company.");
            _co.SqlValue = JCCo;

            SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10);
            if (contract == null) throw new Exception("Missing contract!");
            _contract.SqlValue = contract;

            SqlParameter _projmonth = new SqlParameter("@projectionMonth", SqlDbType.DateTime);
            if (jectMonth == null) throw new Exception("Missing Projection Month");
            _projmonth.SqlValue = jectMonth;

            SqlParameter _login = new SqlParameter("@login", SqlDbType.VarChar);
            if (login == null) throw new Exception("Invalid login user name");
            _login.SqlValue = login;

            SqlParameter _openmonth = new SqlParameter("@openMonth", SqlDbType.DateTime);
            _openmonth.SqlValue = DBNull.Value;

            SqlParameter _actualdate = new SqlParameter("@actualdate", SqlDbType.DateTime);
            TimeSpan noTime = new TimeSpan(0, 0, 0);
            _actualdate.SqlValue = DateTime.Today + noTime;

            SqlParameter _source = new SqlParameter("@source", SqlDbType.VarChar, 10);
            _source.SqlValue = "JC RevProj";

            SqlParameter _errMsg = new SqlParameter("@errMsg", SqlDbType.VarChar, 255); //output
            _errMsg.SqlValue = DBNull.Value;
            _errMsg.Direction = ParameterDirection.Output;

            SqlParameter _batch = new SqlParameter("@batch", SqlDbType.Int);

            SqlCommand _cmd = null;

            uint OpenBatchID = 0x0;
            batchId = 0x0;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    // Are there projections for current contract?
                    _sql = "select DISTINCT(BatchId), Mth from JCIR where Contract=@contract AND Co=@JCCo;";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_contract);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_errMsg);

                    Object[] vals;

                    using (SqlDataReader reader = _cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            vals = new Object[reader.FieldCount];
                            int fieldCount = reader.GetValues(vals);
                            OpenBatchID = Convert.ToUInt32(vals[0]);
                            _openmonth.SqlValue = vals[1];
                        }
                        //else throw new Exception("GenerateCostProjection:  Unable to check for existing Batch");
                        else _batch.SqlValue = (object)DBNull.Value;
                    }

                    if (OpenBatchID != 0x0)
                    {
                        // Batch exist for contract.. who does it belongs to?
                        batchId = OpenBatchID;
                        _batch.SqlValue = OpenBatchID;

                        _cmd.Parameters.Clear();

                        _sql = "select CreatedBy, Mth, Status, DateCreated from HQBC WHERE Co=@JCCo AND BatchId=@batch AND Source=@source AND Mth=@openMonth;";
                        _cmd = new SqlCommand(_sql, _conn);
                        _cmd.Parameters.Add(_co);
                        _cmd.Parameters.Add(_batch);
                        _cmd.Parameters.Add(_source);
                        _cmd.Parameters.Add(_openmonth);
                        _cmd.CommandTimeout = 900;

                        Object[] values;

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                values = new Object[reader.FieldCount];
                                int fieldCount = reader.GetValues(values);
                            }
                            else
                            {
                                var ex = new Exception("Unable to check for existing Batch");
                                ex.Data.Add(0, 6);
                                throw ex;
                            }
                        }

                        if (values[0]?.ToString() != login)
                        {
                            batchId = 0;
                            // belongs to someone else, bail out and alert user
                            var ex = new Exception("Unable to open projection:\n" + values[0].ToString() + " has an open projection in a different month " +
                                                                                    string.Format("{0:MM/yyyy}", Convert.ToDateTime(values[1].ToString().Split(' ')[0]).Date));
                            ex.Data.Add(0, 6);
                            ex.Data.Add(1, "UTO: " + values[0].ToString() + " " + values[1].ToString().Split(' ')[0]); // what gets logged in the backend
                            throw ex;
                        }

                        if (DateTime.Parse(values[1]?.ToString()) != jectMonth)
                        {
                            batchId = 0;
                            var ex = new Exception("Unable to open projection:\n" + values[0].ToString() + " has open an projection in a different month " + 
                                                                                   string.Format("{0:MM/yyyy}", Convert.ToDateTime(values[1].ToString().Split(' ')[0]).Date));
                            ex.Data.Add(0, 6);
                            ex.Data.Add(1, "UTO: " + values[0].ToString() + " " + values[1].ToString().Split(' ')[0]);
                            throw ex;
                        }

                        if (values[2]?.ToString() != "0")
                        {
                            batchId = 0;
                            var ex = new Exception("Unable to open projection:\nOpen batch is not in editable status. Contact the system administrator");
                            ex.Data.Add(0, 6);
                            ex.Data.Add(1, "UTO: " + values[0].ToString() + " " + values[1].ToString().Split(' ')[0] + " " + values[2]?.ToString());
                            throw ex;
                        }

                        revBatchDateCreated = Convert.ToDateTime(values[3]);
                        // belongs to current user. Don't need to create new batch, just show projections and allow edits
                        success = true;

                        LogProphecyAction.InsProphecyLog(login, 6, JCCo, contract, null, jectMonth, batchId);

                        return success;
                    }
                    else
                    {
                        // No projections for the contract, let's create some..
                        _batch.SqlValue = (object)DBNull.Value;
                    }

                    _cmd.Parameters.Clear();


                    // Insert a Batch ID
                    // get next available BatchId # and add entry to bHQBC. Status 0 = open
                    _sql = @"exec bspHQBCInsert @JCCo, @projectionMonth, @source, @batchtable='JCIR', @restrict='N', @adjust='N', @prgroup=NULL, 
                               @prenddate=NULL, @errmsg=@errMsg output";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_projmonth);
                    _cmd.Parameters.Add(_source);
                    _cmd.Parameters.Add(_errMsg);
                    _cmd.CommandTimeout = 900;
                    _cmd.ExecuteScalar();

                    var result = _cmd.Parameters["@errMsg"].Value;
                    if (result != DBNull.Value)
                    {
                        var ex = new Exception("GenerateRevenueProjection (bspHQBCInsert):\n\n" + result.ToString());
                        ex.Data.Add(0, 5);
                        throw ex;
                    }


                    _cmd.Parameters.Clear();

                    // find highest existing batch ID under current username, which will always be the one that was just created
                    _sql = "select MAX(BatchId), MAX(DateCreated) from HQBC WHERE Co=@JCCo AND Mth=@projectionMonth AND CreatedBy=@login AND Source=@source AND Status=0; ";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_projmonth);
                    _cmd.Parameters.Add(_login);
                    _cmd.Parameters.Add(_source);
                    _cmd.CommandTimeout = 900;

                    Object[] retvals;

                    using (SqlDataReader reader = _cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            retvals = new Object[reader.FieldCount];
                            reader.GetValues(retvals);
                        }
                        else
                        {
                            var ex = new Exception("Unable to retrieve newly created batch ID");
                            ex.Data.Add(0, 3);
                            throw ex;
                        }

                    }
                    if (retvals.Length > 0)
                    {
                        batchId = Convert.ToUInt32(retvals[0]);
                        _batch.SqlValue = batchId;
                        revBatchDateCreated = Convert.ToDateTime(retvals[1]);
                    }
                    else
                    {
                        var ex = new Exception("Unable to retrieve newly created batch ID");
                        ex.Data.Add(0, 3);
                        throw ex;
                    }


                    _cmd.Parameters.Clear();

                    //--OPTIONAL
                    // Insert User Projection Options into JCUP if they do not exist
                    _sql = @"exec dbo.bspJCUOInsert @jcco=@JCCo,@form='JCRevProj',@username=@login,@changedonly='N',@itemunitsonly='N',@phaseunitsonly = 'N',
                               @showlinkedct = 'N',@showfutureco = 'N',@remainunits = 'N',@remainhours = 'N',@remaincosts = 'N',@openform = 'N', @phaseoption = 'N',
                               @begphase = '',@endphase = '',@costtypeoption = '0',@selectedcosttypes = '',@visiblecolumns = '',@columnorder = '', @thrupriormonth = '',
                               @nolinkedct = 'N',@projmethod = '1',@production = '',@writeoverplug = '',@initoption = '',@projinactivephases = 'N',@orderby = 'P',
                               @cyclemode = 'N',@columnwidth = '',@msg=@errMsg output;";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_login);
                    _cmd.Parameters.Add(_errMsg);
                    _cmd.CommandTimeout = 900;
                    _cmd.ExecuteScalar();

                    result = _cmd.Parameters["@errMsg"].Value;
                    if (result != DBNull.Value)
                    {
                        var ex = new Exception("GenerateRevenueProjection (bspJCUOInsert):\n\n" + result.ToString());
                        ex.Data.Add(0, 5);
                        throw ex;
                    }


                    _cmd.Parameters.Clear();


                    //Initialize the project
                    _sql = @"declare @p6 varchar(255)
                        set @p6=''
                        exec dbo.bspJCRevProjInit @JCCo=@JCCo,@Mth=@projectionMonth,@BatchID=@batch,@ActualDate=@actualdate,@Contract=@contract,@errmsg=@errMsg output";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_projmonth);
                    _cmd.Parameters.Add(_batch);
                    _cmd.Parameters.Add(_actualdate);
                    _cmd.Parameters.Add(_contract);
                    _cmd.Parameters.Add(_errMsg);
                    _cmd.CommandTimeout = 900;
                    _cmd.ExecuteScalar();

                    result = _cmd.Parameters["@errMsg"].Value;
                    if (result == DBNull.Value)
                    {
                        var ex = new Exception("GenerateRevenueProjection (bspJCRevProjInit): " + result.ToString());
                        ex.Data.Add(0, 5);
                        throw ex;
                    }


                    _cmd.Parameters.Clear();


                    //--Get Projection Totals  - NOT SURE THAT WE NEED THIS SINCE CALCULATIONS WILL BE DONE IN EXCEL 7/20
                    _sql = @"declare @p6 numeric(12,2)
                        set @p6=NULL
                        declare @p7 numeric(12,2)
                        set @p7=NULL
                        declare @p8 varchar(255)
                        set @p8=NULL
                        exec vspJCRevenueProjectionsTotals @jcco=@JCCo,@mth=@projectionMonth,@batchid=@batch,@batchseq=1,@contract=@contract,
                            @totalcurrent=@p6 output,@totalprojected=@p7 output,@msg=@p8 output";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_projmonth);
                    _cmd.Parameters.Add(_batch);
                    _cmd.Parameters.Add(_contract);
                    _cmd.Parameters.Add(_errMsg);
                    _cmd.CommandTimeout = 900;
                    _cmd.ExecuteScalar();

                    result = _cmd.Parameters["@errMsg"].Value;
                    if (result != DBNull.Value)
                    {
                        var ex = new Exception("GenerateRevenueProjection (bspJCRevProjInit): " + result.ToString());
                        ex.Data.Add(0, 5);
                        throw ex;
                    }

                    _cmd.Parameters.Clear();


                    //--Lock the Batch Process
                    _sql = @"declare @p5 varchar(255)
                        set @p5=NULL
                        exec bspHQBatchProcessLock @co=@JCCo,@mth=@projectionMonth,@batchid=@batch,@mod='JC',@errmsg=@p5 output";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_projmonth);
                    _cmd.Parameters.Add(_batch);
                    _cmd.Parameters.Add(_errMsg);
                    _cmd.CommandTimeout = 900;
                    _cmd.ExecuteScalar();

                    result = _cmd.Parameters["@errMsg"].Value;

                    if (result != DBNull.Value)
                    {
                        var ex = new Exception("GenerateRevenueProjection (bspHQBatchProcessLock): " + result.ToString());
                        ex.Data.Add(0, 5);
                        throw ex;
                    }

                    _cmd.Parameters.Clear();

                    success = true;

                    LogProphecyAction.InsProphecyLog(login, 5, JCCo, contract, null, jectMonth, batchId);
                }
            }
            catch (Exception) { throw; } // to UI
            finally { _cmd?.Dispose(); }
            return success;
        }
    }
}
