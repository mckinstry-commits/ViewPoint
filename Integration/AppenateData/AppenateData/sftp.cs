using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Renci.SshNet;
using System.IO;
using System.Configuration;
using System.Net.Mail;

namespace AppenateData
{
    class sftp
    {
        /// <summary>
        /// UploadSFTPFile will put a file on an SFTP site.  The required items site, un, pw, etc. are passed in as parameters to the routine.
        /// In this case it is being used to move a .CSV file of data from Viewpoint to the McKinstry SFTP site for Appenate.  This routine uses the
        /// Renci.SshNet Nuget package to accomplish SFTP activities.
        /// </summary>
        /// <param name="host">string SFTP Host</param>
        /// <param name="username">SFTP username to use</param>
        /// <param name="password">Password for the account</param>
        /// <param name="sourcefile">File to be moved to the SFTP server</param>
        /// <param name="destinationpath">path and Destination file name</param>
        /// <param name="port">SFTP port to use</param>
        /// <returns></returns>
        public static bool UploadSFTPFile(string host, string username,
            string password, string sourcefile, string destinationpath, int port)
        {
            try
            {
                using (SftpClient client = new SftpClient(host, port, username, password))
                {
                    client.Connect();
                    //client.Delete(destinationpath);
                    //client.ChangeDirectory(destinationpath);
                    using (FileStream fs = new FileStream(sourcefile, FileMode.Open))
                    {
                        client.BufferSize = 4 * 1024;
                        client.UploadFile(fs, Path.GetFileName(sourcefile));
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                EmailUtils.SendEmail("An error was thrown during the SFTP move.  " + ex.Message);
                sftp.Logger(System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + "   " +  "An error was thrown during the SFTP move.  " + ex.Message);
                return false;
            }
        }

        /// <summary>
        /// Simple little logging routine that will append the input parameter to the log file located in the .exe directory.
        /// </summary>
        /// <param name="logMessage">The message to be written to the log file.</param>
        static public void Logger(string logMessage)
        {
            try
            {
                string dir = System.Reflection.Assembly.GetEntryAssembly().Location;
                dir = Path.GetDirectoryName(dir);
                dir = dir + "//logfile.txt";

                // Create a writer and open the file:
                StreamWriter log;

                log = File.AppendText(dir);

                // Write to the file:
                log.WriteLine(logMessage);
                log.WriteLine();

                // Close the stream:
                log.Close();
            }
            catch (Exception ex)
            {
                EmailUtils.SendEmail("AppenateData application logger routine failed.  " + ex.Message);
            }
        }
    }

    class EmailUtils
    {
        /// <summary>
        /// Simple little routine to send email notifications from application.  This uses the latest prescribed 
        /// McKinstry methodology for this as of 1/1/2020.  i.e. not anonymous ftp or any other method.  The account being used
        /// has been setup specifically for this.
        /// </summary>
        /// <param name="body">Message body to be sent in the email</param>
        static public void SendEmail(string body)
        {
            try
            {
                // # Sender Credentials
                string userName = "log@mckinstry.com";
                string passWord = "McK1nStRy2020!";
                SmtpClient mySmtpClient = new SmtpClient("smtp.office365.com");

                mySmtpClient.UseDefaultCredentials = false;
                System.Net.NetworkCredential basicAuthenticationInfo = new
                   System.Net.NetworkCredential(userName, passWord);
                mySmtpClient.Credentials = basicAuthenticationInfo;
                mySmtpClient.Port = 587;
                mySmtpClient.EnableSsl = true;

                string toEmail = ConfigurationManager.AppSettings["ToEmail"];
                // add from,to mailaddresses
                MailAddress from = new MailAddress("log@mckinstry.com", "LogEmail");
                MailAddress to = new MailAddress(toEmail, toEmail);
                MailMessage myMail = new System.Net.Mail.MailMessage(from, to);

                // add ReplyTo
                MailAddress replyTo = new MailAddress("peterk@mckinstry.com");
                myMail.ReplyToList.Add(replyTo);

                // set subject and encoding
                myMail.Subject = "Appenate Data Failure!";
                myMail.SubjectEncoding = System.Text.Encoding.UTF8;

                // set body-message and encoding
                myMail.Body = body;
                myMail.BodyEncoding = System.Text.Encoding.UTF8;
                // text or html
                myMail.IsBodyHtml = true;

                mySmtpClient.Send(myMail);
            }

            catch (SmtpException ex)
            {
                throw new ApplicationException
                  ("SmtpException has occured: " + ex.Message);
            }
            catch (Exception ex)
            {
               sftp.Logger("Exception thrown in SendConfirmationEmail message is: " + ex.Message);
            }

        }
    }

}
