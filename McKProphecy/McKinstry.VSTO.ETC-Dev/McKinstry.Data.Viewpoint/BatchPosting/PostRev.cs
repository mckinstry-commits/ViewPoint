using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class PostRev
    {
        public static bool PostRevBatch(byte JCCo, DateTime projectionMonth, uint batchId, string login, string contract)
        {

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            _co.SqlValue = JCCo == 0 ? (object)DBNull.Value : JCCo;

            SqlParameter _mth = new SqlParameter("@mth", SqlDbType.DateTime);
            TimeSpan noTime = new TimeSpan(0, 0, 0);
            _mth.SqlValue = projectionMonth == null ? (object)DBNull.Value : projectionMonth + noTime; 

            SqlParameter _datePosted = new SqlParameter("@datePosted", SqlDbType.DateTime);
            _datePosted.SqlValue = DateTime.Today + noTime;

            SqlParameter _batchId = new SqlParameter("@batchId", SqlDbType.Int);
            _batchId.SqlValue = batchId == 0x0 ? (object)DBNull.Value : batchId;

            SqlParameter _source = new SqlParameter("@source", SqlDbType.VarChar, 10);
            _source.SqlValue = "JC RevProj";

            SqlParameter _msg = new SqlParameter("@msg", SqlDbType.VarChar, 255);
            _msg.Direction = ParameterDirection.Output;
            _msg.SqlValue = DBNull.Value;

            SqlParameter _outputCode = new SqlParameter("@outputCode", SqlDbType.TinyInt);
            _outputCode.Direction = ParameterDirection.Output;
            _outputCode.SqlValue = DBNull.Value;

            SqlConnection _conn = new SqlConnection(HelperData._conn_string);
            SqlCommand _cmd;
            string _sql = null;
            object result = 0;

            try
            {
                _conn.Open();

                _sql = @"exec dbo.bspJCIRVal @co=@JCCo, @mth=@mth, @batchid=@batchId, @source=@source, @errmsg=@msg output";
                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_mth);
                _cmd.Parameters.Add(_batchId);
                _cmd.Parameters.Add(_source);
                _cmd.Parameters.Add(_msg);
                _cmd.CommandTimeout = 600000;
                result = _cmd.ExecuteScalar();

                if (result != null)
                {
                    LogProphecyAction.InsProphecyLog(login, 14, JCCo, contract, null, projectionMonth, batchId, _cmd.Parameters["@msg"].Value.ToString(), result.ToString());
                    throw new Exception("PostRevBatch failed: " + _cmd.Parameters["@msg"].Value.ToString());
                }

                _cmd.Parameters.Clear();

                _sql = @"SELECT Status from HQBC WHERE Co=@JCCo and Mth=@mth AND BatchId=@batchId AND Source=@source";
                _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_mth);
                _cmd.Parameters.Add(_batchId);
                _cmd.Parameters.Add(_source);
                _cmd.Parameters.Add(_msg);
                _cmd.CommandTimeout = 600000;
                var code = _cmd.ExecuteScalar();

                // result should be the Number 3
                if (uint.Parse(code.ToString()) != 3)
                {
                    // fire an update statement, otherwise the user can't see the batch online anymore
                    _cmd.Parameters.Clear();

                    _sql = @"SET NOCOUNT ON; UPDATE HQBC SET Status = 0 WHERE Co=@JCCo and Mth=@mth AND BatchId=@batchId AND Source=@source;";
                    _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_co);
                    _cmd.Parameters.Add(_mth);
                    _cmd.Parameters.Add(_batchId);
                    _cmd.Parameters.Add(_source);
                    _cmd.Parameters.Add(_msg);
                    _cmd.CommandTimeout = 600000;
                    _cmd.ExecuteScalar();
                    LogProphecyAction.InsProphecyLog(login, 14, JCCo, contract, null, projectionMonth, batchId, "batch status " + code.ToString());
                    throw new Exception("PostRevBatch failed: " + result.ToString());
                }

                _cmd.Parameters.Clear();

                _sql = @"exec @outputCode = dbo.bspJCIRPost @co=@JCCo, @mth=@mth, @batchid=@batchId, @dateposted=@datePosted, @source=@source, @errmsg=@msg output";
                _cmd = new SqlCommand(_sql, _conn);
                _msg.SqlValue = DBNull.Value;
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_mth);
                _cmd.Parameters.Add(_batchId);
                _cmd.Parameters.Add(_datePosted);
                _cmd.Parameters.Add(_source);
                _cmd.Parameters.Add(_msg);
                _cmd.Parameters.Add(_outputCode);
                _cmd.CommandTimeout = 600000;
                _cmd.ExecuteScalar();

                result = _cmd.Parameters["@outputCode"].Value;

                if ((byte)result == 1)
                {
                    LogProphecyAction.InsProphecyLog(login, 14, JCCo, contract, null, projectionMonth, batchId, _cmd.Parameters["@msg"].Value.ToString());
                    throw new Exception("PostRevBatch failed: " + _cmd.Parameters["@msg"].Value.ToString());
                }

                LogProphecyAction.InsProphecyLog(login, 13, JCCo, contract, null, projectionMonth, batchId);
                return true;
            }
            catch (Exception) { throw; }// to UI
            finally
            {
                HelperData.SqlCleanup(out _sql, out _cmd, _conn);
            }
        }
    }
}
