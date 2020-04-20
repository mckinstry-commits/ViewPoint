﻿using System;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;

namespace McKinstry.Data.Viewpoint
{
    public class JobJectCostProj
    {
        public static bool GenerateCostProjection(byte JCCo, string contractId, string jobId, DateTime projectionMonth, string login, out uint batchId, out DateTime costBatchDateCreated)
        {
            string _sql;
            bool success;
            costBatchDateCreated = DateTime.Today;
            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _projmonth = new SqlParameter("@projectionMonth", SqlDbType.DateTime);
            SqlParameter _openmonth = new SqlParameter("@openMonth", SqlDbType.DateTime);
            SqlParameter _actualdate = new SqlParameter("@actualdate", SqlDbType.DateTime);
            SqlParameter _source = new SqlParameter("@source", SqlDbType.VarChar, 10);
            SqlParameter _errMsg = new SqlParameter("@errMsg", SqlDbType.VarChar, 255); //output
            SqlParameter _contract = new SqlParameter("@contract", SqlDbType.VarChar, 10);
            SqlParameter _jobId = new SqlParameter("@jobId", SqlDbType.VarChar, 10);
            SqlParameter _login = new SqlParameter("@login", SqlDbType.VarChar);
            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
            TimeSpan noTime = new TimeSpan(0, 0, 0);
            
            _source.SqlValue = "JC Projctn";
            _errMsg.SqlValue =  DBNull.Value;
            _errMsg.Direction = ParameterDirection.Output;
            _actualdate.SqlValue = DateTime.Today + noTime;

            uint OpenBatchID = 0x0;

            if (JCCo != 0)
            {
                _co.SqlValue = JCCo;
            }
            else
            {
                throw new Exception("Invalid JC Company.");
            }

            _openmonth.SqlValue = DBNull.Value;

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

            if (contractId != null)
            {
                _contract.SqlValue = contractId;
            }
            else
            {
                throw new Exception("Missing contract!");
            }

            if (jobId != null)
            {
                _jobId.SqlValue = jobId;
            }
            else
            {
                throw new Exception("Missing Project (Job ID)");
            }

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd;

            try
            {
                _conn.Open();
                // Are there projections current job?
                _sql = "select DISTINCT(BatchId), Mth from JCPB where Job=@jobId AND Co=@JCCo;";
                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_jobId);
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
                    else _batchId.SqlValue = (object)DBNull.Value;
                }

                if (OpenBatchID != 0x0)
                {
                    // Batch exist for Job.. who does it belongs to?
                    batchId = OpenBatchID;
                    _batchId.SqlValue = OpenBatchID;

                    _cmd.Parameters.Clear();

                    _sql = "select CreatedBy, Mth, Status, DateCreated from HQBC WHERE Co=@JCCo AND BatchId=@batchId AND Source=@source AND Mth=@openMonth;";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_batchId);
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
                            var ex = new Exception("GenerateCostProjection:  Unable to check for existing Batch");
                            ex.Data.Add(0, 3);
                            throw ex;
                        }

                    }

                    if (values[0]?.ToString() != login)
                    {
                        // belongs to someone else, bail out and alert user
                        batchId = 0;
                        var ex = new Exception("Unable to open projection: User " + values[0].ToString() + " has open projection " +
                            values[1].ToString().Split(' ')[0]);
                        ex.Data.Add(0, 3);
                        throw ex;
                    }

                    if (DateTime.Parse(values[1]?.ToString()) != projectionMonth)
                    {
                        batchId = 0;
                        var ex = new Exception("Unable to open projection: User " + values[0].ToString() + " has open projection in different month " +
                                           values[1].ToString().Split(' ')[0]);
                        ex.Data.Add(0, 3);
                        throw ex;
                    }

                    if (values[2]?.ToString() != "0")
                    {
                        batchId = 0;
                        var ex = new Exception("Unable to open projection: Open batch is not in editable status. Contact the system administrator");
                        ex.Data.Add(0, 3);
                        throw ex;
                    }

                    costBatchDateCreated = Convert.ToDateTime(values[3]);
                    // belongs to current user. Don't need create new batch, just show projections to allow edits
                    success = true;

                    LogProphecyAction.InsProphecyLog(login, 3, JCCo, contractId, jobId, projectionMonth, batchId);

                    return success;
                }
                else
                {
                    // No projections for the job, let's create some..
                    _batchId.SqlValue = (object)DBNull.Value;
                }

                _cmd.Parameters.Clear();


                /* Validate job doesn't exist in another Batch:
                * INPUT:
                *	JCCo		    JC Company
                *	job	Id	        
                *	batch Id 
                *   projectionMonth  
                *   actualdate      Today's date  
                */
                /*_sql = @"
                        exec bspJCJMValForProj @jcco=@JCCo, @job=@jobId, @batch=@batchId, @mth=@projectionMonth, @actualdate=@actualdate, @contract=@p6 output,@contractdesc=@p7 output,
                            @hrspermanday=@p8 output,@projminpct=@p9 output,@wcode=@p10 output,@wmsg=@p11 output,@jobdesc=@p12 output,@begitem=@p13 output,@enditem=@p14 output,@begphase=@p15 output,
                            @endphase=@p16 output,@msg=@errMsg output";
                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_jobId);
                _cmd.Parameters.Add(_batchId);
                _cmd.Parameters.Add(_projmonth);
                _cmd.Parameters.Add(_actualdate);
                _cmd.Parameters.Add(_errMsg);
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                result = _cmd.Parameters["@errMsg"].Value;
                if (result.ToString() != "")
                {
                    throw new Exception(result.ToString());
                }


                _cmd.Parameters.Clear();
                */

                // Insert a Batch ID
                // get next available BatchId # and add entry to bHQBC. Status 0 = open
                _sql = @"exec bspHQBCInsert @JCCo, @projectionMonth, @source, @batchtable='JCPB', @restrict='N', @adjust='N', @prgroup=NULL, 
                               @prenddate=NULL, @errmsg=@errMsg output";
                _cmd =  new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_projmonth);
                _cmd.Parameters.Add(_source);
                _cmd.Parameters.Add(_errMsg);
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                var result = _cmd.Parameters["@errMsg"].Value;
                if (result == DBNull.Value)
                {
                    var ex = new Exception(result.ToString());
                    ex.Data.Add(0, 2);
                    throw ex;
                }
                // success e.g. result = "McKinstry Co, LLC (Dev:Clone01/14/2016)"


                _cmd.Parameters.Clear();


                // find highest existing batch ID under current username, which will always be the one that was just created
                _sql = "select MAX(BatchId), MAX(DateCreated) from HQBC WHERE Co=@JCCo AND Mth=@projectionMonth AND CreatedBy=@login AND Source=@source AND Status=0;";
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
                    _batchId.SqlValue = batchId;
                    costBatchDateCreated = Convert.ToDateTime(retvals[1]);
                }
                else {
                    var ex = new Exception("Unable to retrieve newly created batch ID");
                    ex.Data.Add(0, 3);
                    throw ex;
                }

                _cmd.Parameters.Clear();

                /* Insert User Projection Options into JCUP if they do not exist ?
                * INPUT PARAMETERS
                *	JCCo		JC Company
                *	username	login
                */
                _sql = @"exec dbo.bspJCUOInsert @jcco=@JCCo,@form='JCProjection',@username=@login,@changedonly='N',@itemunitsonly='N',@phaseunitsonly = 'N',
                               @showlinkedct = 'N',@showfutureco = 'N',@remainunits = 'N',@remainhours = 'N',@remaincosts = 'N',@openform = 'N', @phaseoption = 'N',
                               @begphase = '',@endphase = '',@costtypeoption = '0',@selectedcosttypes = '',@visiblecolumns = '',@columnorder = '', @thrupriormonth = '',
                               @nolinkedct = 'N',@projmethod = NULL,@production = '',@writeoverplug = '',@initoption = '',@projinactivephases = 'Y',@orderby = 'P',
                               @cyclemode = 'N',@columnwidth = '',@msg=@errMsg output;";
                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_login);
                _cmd.Parameters.Add(_errMsg);
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                result = _cmd.Parameters["@errMsg"].Value;
                if (result != DBNull.Value)
                {
                    var ex = new Exception(result.ToString());
                    ex.Data.Add(0, 2);
                    throw ex;
                }


                _cmd.Parameters.Clear();


                /* Get the JCUO Options for the user?
                * INPUT PARAMETERS
                *	JCCo		JC Company
                *	username	login
                */
                   //CURRENTLY NOT NECESSARY AT THIS TIME

                /****  Populate the JCPB Table with blank data
                * INPUT PARAMETERS
                *   VP User         login username
                *	JCCo		    JC Company
                *   projectionMonth  
                *	batch Id  	   
                *	job	Id	        
                *   actualdate      Today's date  
                */
                _sql = @"exec dbo.bspJCProjTableFill @username=@login, @co=@JCCo, @mth=@projectionMonth, @batchid=@batchId, @job=@jobId, @phasegroup=1, @actualdate=@actualdate,
                               @projminpct=NULL,@form='JCProjection',@msg=@errMsg output;";
                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_login);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_projmonth);
                _cmd.Parameters.Add(_batchId);
                _cmd.Parameters.Add(_jobId);
                _cmd.Parameters.Add(_actualdate);
                _cmd.Parameters.Add(_errMsg);
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                result = _cmd.Parameters["@errMsg"].Value;
                if (result != DBNull.Value)
                {
                    var ex = new Exception(result.ToString());
                    ex.Data.Add(0, 2);
                    throw ex;
                }

                _cmd.Parameters.Clear();


                /****  Initialize the NonLabor projection values with the previous projection data
                *****  @detailinit=N'2' means it will populates with values
                * INPUT PARAMETERS
                *   VP User         login username
                *	JCCo		    JC Company
                *   projectionMonth  
                *	batch Id  	   
                *	job	Id	        
                *   actualdate      Today's date  
                */
                //_sql = @"exec bspJCProjInitialize @jcco=@JCCo, @bjob=@jobId, @ejob=@jobId, @projectmgr=0, @phasegroup=1, @actualdate=@actualdate, @writeoverplug=1, 
                //               @mth=@projectionMonth, @batchid=@batchId, @username=@login, @detailinit=N'1', @msg=@errMsg output";
                //_cmd = new SqlCommand(_sql, _conn);
                //_cmd.Parameters.Add(_co);
                //_cmd.Parameters.Add(_jobId);
                //_cmd.Parameters.Add(_actualdate);
                //_cmd.Parameters.Add(_projmonth);
                //_cmd.Parameters.Add(_batchId);
                //_cmd.Parameters.Add(_login);
                //_cmd.Parameters.Add(_errMsg);
                //_cmd.CommandTimeout = 600000;
                //_cmd.ExecuteScalar();

                //result = _cmd.Parameters["@errMsg"].Value;
                //if (!(result.ToString().Contains("projections initialized.")))
                //{
                //    throw new Exception(result.ToString());
                //}

                //_cmd.Parameters.Clear();

                /****  Initialize the NonLabor projection values with the previous projection data
                *****  @detailinit=N'2' means it will populates with values
                * INPUT PARAMETERS
                *   VP User         login username
                *	JCCo		    JC Company
                *   projectionMonth  
                *	batch Id  	   
                *	job	Id	         
                */
                _sql = @"exec mers.mspJCProjInitJCPD @JCCo=@JCCo, @Job=@jobId, @bMonth=@projectionMonth, @BatchId=@batchId, @errmsg=@errMsg output";
                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_jobId);
                _cmd.Parameters.Add(_projmonth);
                _cmd.Parameters.Add(_batchId);
                _cmd.Parameters.Add(_errMsg);
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                result = _cmd.Parameters["@errMsg"].Value;
               // if (!(result.ToString().Contains("NonLabor projections initialized.")))
              //  {
              //      throw new Exception(result.ToString());
              //  }

                _cmd.Parameters.Clear();
                success = true;

                LogProphecyAction.InsProphecyLog(login, 2, JCCo, contractId, jobId, projectionMonth, batchId);

            }
            catch (Exception) { throw; } // to UI
            finally
            {
                HelperData.SqlCleanup(out _sql, out _cmd, _conn);
            }
            return success;
        }

    }
}