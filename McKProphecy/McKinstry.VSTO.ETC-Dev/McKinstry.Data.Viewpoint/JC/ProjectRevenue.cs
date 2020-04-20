using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class ProjectRevenue
    {
        public static bool GenerateRevenueProjection(byte JCCo, string contract, DateTime projectionMonth, string login, out UInt32 batchId, out DateTime revBatchDateCreated)
        {
            string _sql;
            bool success;
            revBatchDateCreated = DateTime.Today;

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _projmonth = new SqlParameter("@projectionMonth", SqlDbType.DateTime);
            SqlParameter _openmonth = new SqlParameter("@openMonth", SqlDbType.DateTime);
            SqlParameter _actualdate = new SqlParameter("@actualdate", SqlDbType.DateTime);
            SqlParameter _source = new SqlParameter("@source", SqlDbType.VarChar, 10);
            SqlParameter _errMsg = new SqlParameter("@errMsg", SqlDbType.VarChar, 255); //output
            SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10);
            SqlParameter _login = new SqlParameter("@login", SqlDbType.VarChar);
            SqlParameter _batch = new SqlParameter("@batch", SqlDbType.Int);
            TimeSpan noTime = new TimeSpan(0, 0, 0);

            _source.SqlValue = "JC RevProj";
            _errMsg.SqlValue = DBNull.Value;
            uint OpenBatchID = 0x0;
            _errMsg.Direction = ParameterDirection.Output;
            _actualdate.SqlValue = DateTime.Today + noTime;
            batchId = 0x0;

            _openmonth.SqlValue = DBNull.Value;

            if (JCCo != 0)
            {
                _co.SqlValue = JCCo;
            }
            else
            {
                throw new Exception("Invalid JC Company.");
            }

            if (projectionMonth != null)
            {
                _projmonth.SqlValue = projectionMonth;
            }
            else
            {
                throw new Exception("Missing Projection Month");
            }

            if (login != null)
            {
                _login.SqlValue = login;
            }
            else
            {
                throw new Exception("Invalid login user name");
            }

            if (contract != null)
            {
                _contract.SqlValue = contract;
            }
            else
            {
                throw new Exception("Missing contract!");
            }


            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd;

            try
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
                    _cmd.CommandTimeout = 600000;

                    Object[] values;

                    using (SqlDataReader reader = _cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            values = new Object[reader.FieldCount];
                            int fieldCount = reader.GetValues(values);
                        }
                        else {

                            var ex = new Exception("Unable to check for existing Batch");
                            ex.Data.Add(0, 6);
                            throw ex;
                        }
                    }

                    if (values[0]?.ToString() != login)
                    {
                        batchId = 0;
                        // belongs to someone else, bail out and alert user
                        var ex = new Exception("Unable to open projection: User " + values[0].ToString() + " has open projection in different month " +
                            values[1].ToString().Split(' ')[0]);
                        ex.Data.Add(0, 6);
                        throw ex;
                    }

                    if (DateTime.Parse(values[1]?.ToString()) != projectionMonth)
                    {
                        batchId = 0;
                        var ex = new Exception("Unable to open projection: User " + values[0].ToString() + " has open projection in different month " + values[1].ToString().Split(' ')[0]);
                        ex.Data.Add(0, 6);
                        throw ex;
                    }

                    if (values[2]?.ToString() != "0")
                    {
                        batchId = 0;
                        var ex = new Exception("Unable to open projection: Open batch is not in editable status. Contact the system administrator");
                        ex.Data.Add(0, 6);
                        throw ex;
                    }

                    revBatchDateCreated = Convert.ToDateTime(values[3]);
                    // belongs to current user. Don't need to create new batch, just show projections and allow edits
                    success = true;

                    LogProphecyAction.InsProphecyLog(login, 6, JCCo, contract, null, projectionMonth, batchId);

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
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                var result = _cmd.Parameters["@errMsg"].Value;
                if (result == DBNull.Value) {
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
                _cmd.CommandTimeout = 600000;

                Object[] retvals;

                using (SqlDataReader reader = _cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        retvals = new Object[reader.FieldCount];
                        reader.GetValues(retvals);
                    }
                    else {
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
                else {
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
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                result = _cmd.Parameters["@errMsg"].Value;
                if (result != DBNull.Value) {
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
                _cmd.CommandTimeout = 600000;
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
                _cmd.CommandTimeout = 600000;
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
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                result = _cmd.Parameters["@errMsg"].Value;

                if (result != DBNull.Value) {
                    var ex = new Exception("GenerateRevenueProjection (bspHQBatchProcessLock): " + result.ToString());
                    ex.Data.Add(0, 5);
                    throw ex;
                }

                _cmd.Parameters.Clear();

                success = true;

                LogProphecyAction.InsProphecyLog(login, 5, JCCo, contract, null, projectionMonth, batchId);

            }
            catch (Exception) { throw; } // to UI
            finally { HelperData.SqlCleanup(out _sql, out _cmd, _conn); }
            return success;
        }
    }
}
