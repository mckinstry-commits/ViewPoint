using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class TimesheetDetail
    {
        /// <summary>
        /// Fully approved timesheets only.  No unapproved or partially approved timesheets.
        /// </summary>
        /// <param name="prco"></param>
        /// <param name="prgroup"></param>
        /// <param name="prenddate"></param>
        /// <param name="payseqincl"></param>
        /// <param name="payseqexcl"></param>
        /// <returns></returns>
        public static List<dynamic> GetMyTimesheetsUnapprv(byte? prco, byte? prgroup, dynamic prenddate, dynamic payseqincl = null, dynamic payseqexcl = null)
        {
            SqlParameter _prco = new SqlParameter("@PRCo", SqlDbType.TinyInt)
            {
                Value = prco ?? (object)DBNull.Value
            };
            SqlParameter _prgroup = new SqlParameter("@PRGroup", SqlDbType.TinyInt)
            {
                Value = prgroup ?? (object)DBNull.Value
            };
            SqlParameter _prenddate = new SqlParameter("@PREndDate", SqlDbType.SmallDateTime)
            {
                Value = prenddate ?? (object)DBNull.Value
            };
            SqlParameter _payseqincl = new SqlParameter("@PaySeqIncl", SqlDbType.VarChar, 8000)
            {
                Value = payseqincl ?? (object)DBNull.Value
            };
            SqlParameter _payseqexcl = new SqlParameter("@PaySeqExcl", SqlDbType.VarChar, 8000)
            {
                Value = payseqexcl ?? (object)DBNull.Value
            };

            List<dynamic> table = null;

            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand("Select * from mckfnPRMyTimesheetUnapprv(@PRCo, @PRGroup, @PREndDate, @PaySeqIncl, @PaySeqExcl)", _conn))
                    {
                        _cmd.CommandTimeout = 600;
                        _cmd.Parameters.Add(_prco);
                        _cmd.Parameters.Add(_prgroup);
                        _cmd.Parameters.Add(_prenddate);
                        _cmd.Parameters.Add(_payseqincl);
                        _cmd.Parameters.Add(_payseqexcl);

                        using (SqlDataReader reader = _cmd.ExecuteReader())
                        {
                            table = new List<dynamic>();

                            while (reader.Read())
                            {
                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                for (int ordinal = 0; ordinal <= reader.FieldCount - 1; ordinal++)
                                {
                                    // column data type
                                    string type = reader.GetFieldType(ordinal).FullName;

                                    row.Add(
                                            reader.GetName(ordinal),  // column Name
                                            new KeyValuePair<string, object>(type, reader[ordinal]) // data type | value
                                           );
                                }
                                table.Add(row);
                            }
                        }
                    }
                }
            }
            catch (Exception) { throw; }

            return table;
        }
    }
}

