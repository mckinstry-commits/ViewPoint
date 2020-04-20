using System;
using System.Data.SqlClient;
using System.IO;
using System.Configuration;
using System.Data;

namespace XML_Maker
{
    class TSQL
    {
        private string connString = "";

        public TSQL()
        {
            connString = ConfigurationManager.AppSettings["ConnectionString"];
        }

        /// <summary>
        /// Takes the data from the database and writes it to a CSV file
        /// </summary>
        /// <param name="reader">SqlDataReader it is the results of the database query passed as an input parameter</param>
        private bool CreateCsvFile(SqlDataReader reader)
        {
            string Delimiter = "\"";
            string Separator = ",";
            try
            {
                string pathToFile = System.Reflection.Assembly.GetExecutingAssembly().Location;
                pathToFile = Path.GetDirectoryName(pathToFile);
                string source = ConfigurationManager.AppSettings["Source"];
                source = pathToFile + "\\" +  source;

                using (StreamWriter writer = new StreamWriter(source))
                {
                    // write header row
                    for (int columnCounter = 0; columnCounter < reader.FieldCount; columnCounter++)
                    {
                        if (columnCounter > 0)
                        {
                            writer.Write(Separator);
                        }
                        writer.Write(Delimiter + reader.GetName(columnCounter) + Delimiter);
                    }
                    writer.WriteLine(string.Empty);

                    // data loop
                    while (reader.Read())
                    {
                        // column loop
                        for (int columnCounter = 0; columnCounter < reader.FieldCount; columnCounter++)
                        {
                            if (columnCounter > 0)
                            {
                                writer.Write(Separator);
                            }
                            writer.Write(Delimiter + reader.GetValue(columnCounter).ToString().Replace('"', '\'') + Delimiter);
                        }   // end of column loop
                        writer.WriteLine(string.Empty);
                    }   // data loop

                    writer.Flush();
                }
                return true;
            }
            catch(Exception ex)
            {
            //// Log exception to logfile
            //sftp.Logger(System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in CreateCsvFile " + ex.Message);
            //// Send email notification of a failure within this routine.
            //EmailUtils.SendEmail("Exception thrown in CreateCsvFile " + ex.Message);
                return false;
            }
        }

        public DataSet GetEthnicities
            ()
        {
            try
            {
                using (SqlConnection connection = new SqlConnection(connString))
                {
                    string queryString = "SELECT * from udxrefWaLNIEthnicity";
                    SqlCommand command = new SqlCommand(queryString, connection);

                    connection.Open();
                    SqlDataAdapter da = new SqlDataAdapter(command);
                    DataSet ds = new DataSet();
                    da.Fill(ds);
                    return ds;
                }
            }
            catch (Exception ex)
            {
                //// Log exception to logfile
                //sftp.Logger( System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in GetDataSet " + ex.Message);
                //// Send email notification of a failure within this routine.
                //EmailUtils.SendEmail("Exception thrown in GetDataSet " + ex.Message);
                return null;
            }
}

        public DataSet CraftClassElements(string empID)
        {
            try
            {
                //                string connectionString = "Data Source=MCKTESTSQL05\\Viewpoint" + ";Initial Catalog=Viewpoint;Integrated Security=true;";
                using (SqlConnection connection = new SqlConnection(connString))
                {
                    string queryString = "select c.udWALNIEndStepHrs, c.udWALNIApprenticeStep, c.udWALNIBeginStepHrs from PRCC c join PREH p on p.PRCo = c.PRCo and p.Craft = c.Craft and p.Class = c.Class where p.Employee = '" +
                        empID + "'";

                    SqlCommand command = new SqlCommand(queryString, connection);
                    connection.Open();
                    SqlDataAdapter da = new SqlDataAdapter(command);
                    DataSet ds = new DataSet();
                    da.Fill(ds);

                    return ds;
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public bool ApprenticeFlgForAnEmployee(string empID)
        {
            try
            {
//                string connectionString = "Data Source=MCKTESTSQL05\\Viewpoint" + ";Initial Catalog=Viewpoint;Integrated Security=true;";
                using (SqlConnection connection = new SqlConnection(connString))
                {
                    string queryString = "select c.EEOClass from PRCC c join PREH p on p.PRCo = c.PRCo and p.Craft = c.Craft and p.Class = c.Class where p.Employee = '" +
                        empID + "'";

                    SqlCommand command = new SqlCommand(queryString, connection);
                    connection.Open();
                    SqlDataAdapter da = new SqlDataAdapter(command);
                    DataSet ds = new DataSet();
                    da.Fill(ds);
                    if ((Convert.ToString(ds.Tables[0].Rows[0]["EEOClass"]).Trim() == "A"))
                    {
                        return true;
                    }
                    else
                        return false;
                }
            }
            catch (Exception ex)
            {
                //// Log exception to logfile
                //sftp.Logger( System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in GetDataSet " + ex.Message);
                //// Send email notification of a failure within this routine.
                //EmailUtils.SendEmail("Exception thrown in GetDataSet " + ex.Message);
                return false;
            }
        }

        public string GetApprenticeID(string empID)
        {
            using (SqlConnection connection = new SqlConnection(connString))
            {
                string queryString = "select udApprenticeID from PREH  where Employee = '" + empID + "'";
                SqlCommand command = new SqlCommand(queryString, connection);
                connection.Open();
                SqlDataAdapter da = new SqlDataAdapter(command);
                DataSet ds = new DataSet();
                da.Fill(ds);
                return Convert.ToString(ds.Tables[0].Rows[0]["udApprenticeID"]);
            }
        }

        public string TradeCodeForAnEmployee(string empID)
        {
            try
            {
//                string connectionString = "Data Source=MCKTESTSQL05\\Viewpoint" + ";Initial Catalog=Viewpoint;Integrated Security=true;";
                using (SqlConnection connection = new SqlConnection(connString))
                {
                    string queryString = "select udTradeCode from PRCM cm join PREH eh on eh.Craft = cm.Craft and eh.PRCo = cm.PRCo where udTradeCode is not null and eh.Employee = '" +
                        empID + "'";
                    SqlCommand command = new SqlCommand(queryString, connection);
                    connection.Open();
                    SqlDataAdapter da = new SqlDataAdapter(command);
                    DataSet ds = new DataSet();
                    da.Fill(ds);
                    return Convert.ToString(ds.Tables[0].Rows[0]["udTradeCode"]);
                }
            }
            catch (Exception ex)
            {
                //// Log exception to logfile
                //sftp.Logger( System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in GetDataSet " + ex.Message);
                //// Send email notification of a failure within this routine.
                //EmailUtils.SendEmail("Exception thrown in GetDataSet " + ex.Message);
                return null;
            }


            
        }

        public DataSet GetTradeBenefits()
        {
            using (SqlConnection connection = new SqlConnection(connString))
            {
                SqlCommand command = new SqlCommand("PAKTradeBenefits", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                //   command.Parameters.AddWithValue("@Employee", Convert.ToInt32(employeeID));
                command.Parameters.AddWithValue("@PREndDate", DBNull.Value);
                command.Parameters.AddWithValue("@PRWeekFirstDate", DBNull.Value);
                command.Parameters.AddWithValue("@PRWeekLastDate", DBNull.Value);
                command.Parameters.AddWithValue("@Job", DBNull.Value);

                connection.Open();
                SqlDataAdapter da = new SqlDataAdapter(command);
                DataSet ds = new DataSet();
                da.Fill(ds);
                return ds;
            }
        }

        public DataSet GetOtherDeductions()
        {
            using (SqlConnection connection = new SqlConnection(connString))
            {
                SqlCommand command = new SqlCommand("PAKOtherDeductions", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

             //   command.Parameters.AddWithValue("@Employee", Convert.ToInt32(employeeID));
                command.Parameters.AddWithValue("@PREndDate", DBNull.Value);
                command.Parameters.AddWithValue("@PRWeekFirstDate", DBNull.Value);
                command.Parameters.AddWithValue("@PRWeekLastDate", DBNull.Value);
                command.Parameters.AddWithValue("@Job", DBNull.Value);

                connection.Open();
                SqlDataAdapter da = new SqlDataAdapter(command);
                DataSet ds = new DataSet();
                da.Fill(ds);
                return ds;
            }
        }

        /// <summary>
        /// GetDataSet executes the TSQL select statement to get the data for the CSV file.
        /// </summary>
        public DataSet GetDataSet()
        {
            try
            {
               
                //            string connectionString = "Server=mcktestsql05;Database=mcktestsql05\\Viewpoint;User Id=ETLProcess;Password=hence-WHAtrBK;";
              //  string db = ConfigurationManager.AppSettings["DataBase"];
              // string connectionString = "Data Source=MCKTESTSQL05\\Viewpoint" + ";Initial Catalog=Viewpoint;Integrated Security=true;";


                using (SqlConnection connection = new SqlConnection(connString))
                {
                    SqlCommand command = new SqlCommand("PAKExport", connection);
                    command.CommandType = System.Data.CommandType.StoredProcedure;

                    command.Parameters.AddWithValue("@PREndDate", DBNull.Value);
                    command.Parameters.AddWithValue("@PRWeekFirstDate", DBNull.Value);
                    command.Parameters.AddWithValue("@PRWeekLastDate", DBNull.Value);
                    command.Parameters.AddWithValue("@Job", DBNull.Value);

                    connection.Open();
                    SqlDataAdapter da = new SqlDataAdapter(command);
                    DataSet ds = new DataSet();
                    da.Fill(ds);
                //    SqlDataReader reader = command.ExecuteReader();
                    //try
                    //{
                    //    //while (reader.Read())
                    //    //{
                    //    //    Console.WriteLine(String.Format("{0}, {1}",
                    //    //    reader["Service Center"], reader["Status"]));
                    //    //}
                    //    if (!CreateCsvFile(reader))
                    //    {
                    //        return false;
                    //    }
                    //}
                    //finally
                    //{
                    //    // Always call Close when done reading.
                    //    reader.Close();
                    //}
                    return ds;
                }
            }
            catch (Exception ex)
            {
                //// Log exception to logfile
                //sftp.Logger( System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in GetDataSet " + ex.Message);
                //// Send email notification of a failure within this routine.
                //EmailUtils.SendEmail("Exception thrown in GetDataSet " + ex.Message);
                return null;
            }
        }
    }
}
