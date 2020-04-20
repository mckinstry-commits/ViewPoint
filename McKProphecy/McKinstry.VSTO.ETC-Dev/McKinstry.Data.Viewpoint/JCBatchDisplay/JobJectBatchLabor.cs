﻿using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class JobJectBatchLabor
    {
        public static DataTable GetJobJectBatchLaborTable(byte Company, string JobId, string Pivot)
        {
            DataTable resultTable = new DataTable();
            
            string _sql = "exec mers.mspGetJCProjHrsDyn @JCCo, @Job, @Pivot";

            SqlParameter _co = new SqlParameter("@JCCo", SqlDbType.TinyInt);
            SqlParameter _job = new SqlParameter("@Job", SqlDbType.VarChar, 10);
            SqlParameter _pivot = new SqlParameter("@Pivot", SqlDbType.VarChar, 5);

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

            if (Pivot == null)
            {
                _pivot.SqlValue = "WEEK";
            }
            else
            {
                _pivot.SqlValue = Pivot;
            }
            
            SqlConnection _conn = new SqlConnection(HelperData._conn_string);

            try
            {
                _conn.Open();

                SqlCommand _cmd = new SqlCommand(_sql, _conn);
                _cmd.Parameters.Add(_co);
                _cmd.Parameters.Add(_job);
                _cmd.Parameters.Add(_pivot);
                _cmd.CommandTimeout = 600000;

                SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                _da.Fill(resultTable);
                resultTable.TableName = "Projected_Labor_Pivot_" + string.Format("Job_{0}", JobId.Trim().Replace("-","_") ) ;
            }
            catch (Exception e)
            {
                throw new Exception("Projected_Labor_Pivot Exception", e);
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