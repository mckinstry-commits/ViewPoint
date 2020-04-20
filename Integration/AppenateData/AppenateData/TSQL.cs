using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.IO;
using IdentityModel.Client;
using System.Configuration;

namespace AppenateData
{
    class TSQL
    {
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
                // Log exception to logfile
                sftp.Logger(System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in CreateCsvFile " + ex.Message);
                // Send email notification of a failure within this routine.
                EmailUtils.SendEmail("Exception thrown in CreateCsvFile " + ex.Message);
                return false;
            }
        }
        /// <summary>
        /// GetDataSet executes the TSQL select statement to get the data for the CSV file.
        /// </summary>
        public bool GetDataSet()
        {
            try
            {


                string queryString = "SELECT DISTINCT   SMWorkOrder.SMCo AS [SMCo]" +
                    ", SMWorkOrder.ServiceCenter AS[Service Center] , SMWorkOrderScope.Division AS[Division] , SMWorkOrderScope.CallType as [Call Type] , SMWorkOrder.WorkOrder AS[Work Order]" +
                    ", SMWorkOrder.WorkOrderQuote as [Quote] , SMWorkOrder.EnteredBy as [Entered By] , SMWorkOrderStatus.Status , SMWorkOrder.[Description] AS[Description]  " +
                    ",(CASE WHEN dbo.SMWorkOrder.Customer IS NULL THEN 'J' ELSE 'C' END) AS WorkOrderType , SMWorkOrder.Job AS[Job], COALESCE(SMWorkOrder.Customer " +
                    ", JARCM.Customer) AS[Customer ID] , COALESCE(cinfo.Name, JARCM.Name) AS[Customer] , SMWorkOrderScope.CustomerPO as [Customer PO] " +
                    ", SMWorkOrder.ServiceSite AS[Service Site] , ssite.[Description] AS[Site Description]  , ssite.Address1 , ssite.Address2 , ssite.City " +
                    ", SMWorkOrder.ServiceCenter AS[Service Center] , RequestedBy AS[Requested By]  , RequestedDate AS[Requested Date] " +
                    ", CONVERT(VARCHAR(8), RequestedTime, 108) AS[Requested Time] , ContactName AS[Contact Name], ContactPhone AS[Contact Phone]  , SMWorkOrder.Notes AS[Notes] " +
                    ", SMWorkOrder.SMWorkOrderID AS[KeyID] , 'SMWorkOrder' AS[FormName] , SMWorkOrder.UniqueAttchID FROM dbo.SMWorkOrder     JOIN SMWorkOrderStatus " +
                    "        ON dbo.SMWorkOrder.SMCo = dbo.SMWorkOrderStatus.SMCo         AND dbo.SMWorkOrder.WorkOrder = dbo.SMWorkOrderStatus.WorkOrder JOIN dbo.SMWorkOrderScope " +
                    "    ON dbo.SMWorkOrder.SMCo = dbo.SMWorkOrderScope.SMCo     AND dbo.SMWorkOrder.WorkOrder = dbo.SMWorkOrderScope.WorkOrder LEFT JOIN dbo.SMCustomerInfo cinfo " +
                    "    ON dbo.SMWorkOrder.SMCo = cinfo.SMCo     AND dbo.SMWorkOrder.CustGroup = cinfo.CustGroup     AND dbo.SMWorkOrder.Customer = cinfo.Customer LEFT OUTER JOIN JCJM " +
                    "    ON dbo.SMWorkOrder.JCCo = JCJM.JCCo     AND dbo.SMWorkOrder.Job = JCJM.Job LEFT OUTER JOIN JCCM     ON JCJM.JCCo = JCCM.JCCo     AND JCJM.Contract = JCCM.Contract " +
                    "LEFT OUTER JOIN ARCM JARCM     ON JCCM.CustGroup = JARCM.CustGroup     AND JCCM.Customer = JARCM.Customer JOIN dbo.SMServiceSite ssite " +
                    "    ON dbo.SMWorkOrder.SMCo = ssite.SMCo     AND dbo.SMWorkOrder.ServiceSite = ssite.ServiceSite       JOIN SMWorkOrderStatus st     on SMWorkOrder.SMCo = st.SMCo " +
                    "    AND SMWorkOrder.WorkOrder = st.WorkOrder WHERE WOStatus IN (0) AND SMWorkOrder.SMCo = @Company ORDER BY SMWorkOrder.WorkOrder DESC";

                //            string connectionString = "Server=mcktestsql05;Database=mcktestsql05\\Viewpoint;User Id=ETLProcess;Password=hence-WHAtrBK;";
                string db = ConfigurationManager.AppSettings["DataBase"];
                string connectionString = "Data Source=" + db + ";Initial Catalog=Viewpoint;Integrated Security=true;";


                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    SqlCommand command = new SqlCommand(queryString, connection);
                    command.Parameters.AddWithValue("@Company", "1");
                    connection.Open();
                    SqlDataReader reader = command.ExecuteReader();
                    try
                    {
                        //while (reader.Read())
                        //{
                        //    Console.WriteLine(String.Format("{0}, {1}",
                        //    reader["Service Center"], reader["Status"]));
                        //}
                        if (!CreateCsvFile(reader))
                        {
                            return false;
                        }
                    }
                    finally
                    {
                        // Always call Close when done reading.
                        reader.Close();
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                // Log exception to logfile
                sftp.Logger( System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in GetDataSet " + ex.Message);
                // Send email notification of a failure within this routine.
                EmailUtils.SendEmail("Exception thrown in GetDataSet " + ex.Message);
                return false;
            }
        }
    }
}
