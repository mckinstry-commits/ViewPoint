using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static class UserInsert
    {
        /// <summary>
        /// This will insert the data in the grid to MCKVPUserCreation table which also acts as a history/audit table
        /// </summary>
        /// <param name="JCCo"></param>
        /// <param name="role"></param>
        /// <param name="batchId"></param>
        /// <param name="users"></param>
        /// <returns>list of users that failed insertion</returns>
        public static List<string[]> MCKspUserCreationInsert(byte JCCo, string role, uint? batchId, object[,] users, List<uint> occupiedRowIndices)
        {
            if (batchId == 0 || batchId == null) throw new Exception("Missing Batch ID required to insert users into");

            SqlParameter _co = new SqlParameter("@co", SqlDbType.TinyInt)
            {
                SqlValue = JCCo != 0 ? JCCo : (object)DBNull.Value
            };
            SqlParameter _role = new SqlParameter("@Role", SqlDbType.VarChar, 255)
            {
                SqlValue = role ?? (object)DBNull.Value
            };
            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId
            };
            SqlParameter _username = new SqlParameter("@UserName", SqlDbType.VarChar, 255);
            SqlParameter _name = new SqlParameter("@Name", SqlDbType.VarChar, 255);
            SqlParameter _email = new SqlParameter("@Email", SqlDbType.VarChar, 255);
            SqlParameter _requestedby = new SqlParameter("@RequestedBy", SqlDbType.VarChar, 255);

            List<string[]> failedUsers = null;

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("dbo.MCKspUserCreationInsert", _conn))
                    {
                        _cmd.CommandType = CommandType.StoredProcedure;

                        for (int n = 0; n < occupiedRowIndices.Count; n++)
                        {
                            _username.SqlValue = users.GetValue(occupiedRowIndices[n], 1);
                            _name.SqlValue = users.GetValue(occupiedRowIndices[n], 2);
                            _email.SqlValue = users.GetValue(occupiedRowIndices[n], 3);
                            _requestedby.SqlValue = users.GetValue(occupiedRowIndices[n], 4);

                            _cmd.Parameters.Add(_co);
                            _cmd.Parameters.Add(_role);
                            _cmd.Parameters.Add(_username);
                            _cmd.Parameters.Add(_name);
                            _cmd.Parameters.Add(_email);
                            _cmd.Parameters.Add(_requestedby);
                            _cmd.Parameters.Add(_batchId);
                            _cmd.CommandTimeout = 600;

                            if (_cmd.ExecuteNonQuery() == 0)
                            {
                                failedUsers = failedUsers ?? new List<string[]>();

                                failedUsers.Add(new string[]
                                                {   _username.Value.ToString(),
                                                _name.Value.ToString(),
                                                _email.Value.ToString(),
                                                _requestedby.Value.ToString()
                                                });
                            }
                            _cmd.Parameters.Clear();
                        }
                    }
                } // close connection

                return failedUsers;
            }
            catch (Exception) { throw; } // to UI
            finally
            {
                _co = null;
                _role = null;
                _username = null;
                _name = null;
                _email = null;
                _requestedby = null;
                _batchId = null;
            }
        }
    }
}
