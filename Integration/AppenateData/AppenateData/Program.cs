using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Configuration;

/*
 * Author: Peter Knudson 
 * Date: 1/3/2020
 * Description:
 * This application executes a TSQL query against the ViewPoint database.  The results of the query, are made into a .CSV file.  The CSV file is then
 * SFTP'd to the McKinstry SFTP site.
 * This file is created to be picked up and ingested by Appenate.  We subscribe to a service they provide.  These are preconfigured forms on Mobile devices.  The file will allow
 * for "prefilling" items on the forms; and thus saving time for the mobile device user.
 * 
 * Ideas and enhancements:
 * 
 * TSQL query instead of being inline; move it to a SPROC
 * 
 * The emailing subsystem could be made into a DLL which could then be used by multiple applications software engineers with the need to send email from their
 * applications.
 *
 *Introduce encrypted items for some of the app.config settings.  This would remove cleartext passwords, etc. from the app.config.
 * 
 * Logging subsystem could be made into a dll and enhanced such that it could be used by other s/w engineers for logging within their applications.
 * Similar to emailing.
 * 
 * Auto house cleaning of the log file.  Normally, a run will write two lines to the logfile.  So, it will take a long time for it to grow unwieldly.  However, I could implement
 * some automatic housecleaning of this file.  Such as, if the file is more than one month old, then purge it and start over.  Or, check the size of the file, and if it is over
 * 20 meg. in size, then purge and start over.  There are multiple ways this could be implemented.
 * 
 * */

namespace AppenateData
{
    class Program
    {
        static void Main(string[] args)
        {
            sftp.Logger("Application start at: " + System.DateTime.Now.ToString("MM/dd/yyyy HH:mm"));
            TSQL tSQL = new TSQL();
           
            if (tSQL.GetDataSet())
            {
                bool methodResults = true;
                string source = ConfigurationManager.AppSettings["Source"];
                string destination = @".";
                string host = ConfigurationManager.AppSettings["Host"];
                string username = ConfigurationManager.AppSettings["UserName"];
                string password = ConfigurationManager.AppSettings["SFTPPassword"];
                int port = 22;  //Port 22 is default for SFTP upload

                // upload to the McK SFTP folder
                methodResults = sftp.UploadSFTPFile(host, username, password, source, destination, port);
            }
            else
            { 
                // If retrieving the dataset errored out, there is no need to try and do any of the subsequent steps.  So, we exit.
                System.Environment.Exit(0); 
            }
            sftp.Logger("Completed at: " + System.DateTime.Now.ToString("MM/dd/yyyy HH:mm"));
        }
    }
}
