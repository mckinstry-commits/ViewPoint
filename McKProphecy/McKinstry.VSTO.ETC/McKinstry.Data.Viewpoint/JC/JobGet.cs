﻿using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.Data.Viewpoint
{
    public class Jobs
    {
        public static DataTable GetJobs(string ContractId)
        {
            DataTable resultTable = new DataTable();

            string _sql = "select * from mers.mfnJobSelectorList (@Contract)";

            SqlParameter _contract = new SqlParameter("@Contract", SqlDbType.VarChar, 10);


            _contract.SqlValue = ContractId != null ? ContractId: (object)DBNull.Value;


            try
            {
                using (SqlConnection _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();

                    SqlCommand _cmd = new SqlCommand(_sql, _conn);
                    _cmd.Parameters.Add(_contract);

                    SqlDataAdapter _da = new SqlDataAdapter(_cmd);

                    _da.Fill(resultTable);
                    resultTable.TableName = "ContractProjects";
                }
            }
            catch (Exception e) { throw new Exception("GetContractJobs Exception", e); }

            return resultTable;
        }
    }
}