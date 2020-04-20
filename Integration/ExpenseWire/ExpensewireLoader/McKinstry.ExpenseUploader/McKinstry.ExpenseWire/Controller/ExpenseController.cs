using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Xml;
using System.Xml.Serialization;
using System.Xml.Schema;
using System.Xml.Linq;
using System.Xml.XPath;
using System.IO;
using System.Configuration;
using McKinstry.VPIntegration;
using System.Text.RegularExpressions;
using System.Net;

using model = McKinstry.ExpenseWire.Model;
using service = McKinstry.ExpenseWire.Services;

namespace McKinstry.ExpenseWire.Controller
{
    public class ExpenseController :IExpenseController
    {
        #region "Private properties"
        static ExpenseWireProxy.ExpenseWireServiceSoapClient svc = null;
        static string ExpenseWireServiceURL = ConfigurationManager.AppSettings.Get("ExpenseWireServiceURL");
        MCK_INTEGRATIONEntities DB = null;
        EmployeeVendorInfo E = null;
        static List<EWCheckNumber> CheckNumbers = null;
        private LogFactory messageFactory;
        private LogFactory exceptionFactory;
        #endregion

        #region "Public properties"
        public string BatchId { get; set; }
        public string Exception { get; set; }
        public bool IsFms { get; set; }
        #endregion

        public ExpenseController()     
        {
            System.Net.ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls11 | SecurityProtocolType.Tls12;
            messageFactory = new LogFactory(new ExpenseMessage());
            exceptionFactory = new LogFactory(new ExpenseException());
            //IsFms = true;
        }

        public void ProcessExpenses()
        {
            DB = new MCK_INTEGRATIONEntities();
            
            messageFactory.LogMe("Started");
            UploadExpensesToVP();

        }

        public void UpdateExpneseChecks()
        {
            string checkNum = "";
            string expenseID = "";
            try
            {
                
                model.ExpenseWire expenseObject = new model.ExpenseWire();
                expenseObject = GetExpenses();
                
                //Get Expenses from ExpenseWire to get GUIDs and expenses.
                string xmlString = Utility.SerializeObject(expenseObject);
                XDocument expenses = XDocument.Parse(xmlString);
                //Create root XML to send to ExpenseWire.
                XDocument sendXML =
                    new XDocument(
                    new XElement("ExpenseWire",
                        new XElement("DataTransaction",
                            new XElement("Expense"))));

                //get check numbers from ViewPoint.
                CheckNumbers = new List<EWCheckNumber>();
                CheckNumbers = GetCheckNumbers();

                //Create XML to send to ExpenseWire for checkNumber update.
                foreach (XElement expense in expenses.XPathSelectElements("//ExpenseWire/SendDataTransaction/Expense/Search/Expense"))
                {
                    expenseID = "EW" + expense.XPathSelectElement("Ref/ID").Value;
                    if (CheckNumbers.Where(n => n.ExpenseID == expenseID).FirstOrDefault() != null)
                    {
                        checkNum = CheckNumbers.Where(n => n.ExpenseID == expenseID).FirstOrDefault().CMRef;
                    }
                    sendXML.Descendants("Expense").First().Add(new XElement("Update",
                        new XElement("Ref", expense.XPathSelectElement("Ref/Guid")),
                        new XElement("User", expense.XPathSelectElement("User/Guid")),
                        new XElement("Customer", expense.XPathSelectElement("Customer/Guid")),
                        new XElement("Project", expense.XPathSelectElement("Project/Guid")),
                        new XElement("Currency", expense.XPathSelectElement("Currency/ID")),
                        new XElement("CheckNbr", checkNum)
                        ));
                }
                XDocument xdoc = XDocument.Parse(sendXML.ToString());
                //xdoc.Save(@"c:\ExpensewireCheckNumberUpload.xml");

                string responseXML = sendTransaction(sendXML.ToString());

                XDocument xdoc1 = XDocument.Parse(responseXML.ToString());
                //xdoc1.Save(@"c:\ExpensewireCheckNumberUploadResponse.xml");                

            }
            catch (Exception ex)
            {
               exceptionFactory.LogMe("ERROR : " + ex.Message);
            }
        }

        private void UploadExpensesToVP()
        {
            

            //Prepare Search Object by passing the BatchID.
            model.ExpenseWire expenseWireObject = new model.ExpenseWire();


            expenseWireObject = GetExpenses();

            if (expenseWireObject == null)
            {
                this.Exception += " No expenses downloaded.";
                return;
            }    
                     
            #region  " VP Upload part"
            //if (!IsValid(expenseWireObject)) return;


            service.ViewPointIntegrationService svc = new service.ViewPointIntegrationService();         

            #region "Use Service here 
            //Process expenses into integration database.. 
            //each expense header
            foreach (model.ExpenseWireSendDataTransactionExpenseSearchExpense exp in expenseWireObject.SendDataTransaction.Expense.Search.Expense)
            {
                try
                {
                    svc.AddExpense(exp);
                }
                catch (Exception e) {
                    messageFactory.LogMe(e.StackTrace);
                    this.Exception = "Load expense to integration failed. \n" + e.Message + "\nStackTrace: " + e.StackTrace;
                    break;
                }
            }
            #endregion 
            #endregion


        }

        private static string getSessionKey(bool isFMS)
        {
            XmlDocument xmlparse = new XmlDocument();
            try
            {
                string userName;
                string password;
                string clientID;
                if (isFMS)
                {
                    userName = ConfigurationManager.AppSettings.Get("ExpenseWireServiceUserNameFMS");
                    password = ConfigurationManager.AppSettings.Get("ExpenseWireServicePasswordFMS");
                    clientID = ConfigurationManager.AppSettings.Get("ExpenseWireServiceClientIDFMS");
                }
                else
                {
                    userName = ConfigurationManager.AppSettings.Get("ExpenseWireServiceUserName");
                    password = ConfigurationManager.AppSettings.Get("ExpenseWireServicePassword");
                    clientID = ConfigurationManager.AppSettings.Get("ExpenseWireServiceClientID");
                }
                string xml = svc.OpenDataConnection(userName, password, clientID);
                xmlparse.LoadXml(xml);
                //xml.Save(@"c:\Expensewiresessionticket.xml");
                string session = xmlparse.SelectSingleNode("//ExpenseWire/OpenDataConnection/SessionKey").InnerText;
                return session;
            }
            catch (Exception e) { return ""; }
        }

        private bool IsValid(XDocument expenseObject)
        {
            string employeeNumber = "0";
            string employeeEmail = "";
            bool result = true;
          //  foreach (model.ExpenseWireSendDataTransactionExpenseSearchExpense e in expenseObject.SendDataTransaction.Expense.Search.Expense)
            foreach (XElement e in expenseObject.XPathSelectElements(XPaths.EXPENSES))
            {
                //get EmpId and VendorId 
                employeeNumber = e.XPathSelectElement(XPaths.EMPLOYEENUMBER).Value;
                employeeEmail = e.XPathSelectElement(XPaths.EMPLOYEEEMAIL).Value;
                if (employeeNumber == "" || employeeNumber == null)
                {
                    //employeeNumber = getEMployeeByEmail(employeeEmail).Trim();
                    result = false;
                    this.Exception = this.Exception + "User : " + employeeEmail + " has no employee number.";
                }
            }
            return result;
        }

      
        private string sendTransaction(string sendXML)
        {
            try
            {
                svc = new ExpenseWireProxy.ExpenseWireServiceSoapClient();
                // = 2000000;
                string sessionKey = getSessionKey(IsFms);
                string responeXML = svc.SendDataTransaction(sessionKey, sendXML);
                svc.CloseDataConnection(sessionKey);
                return responeXML;
            }
            catch(Exception ex)  { return null; }

        }

        private model.ExpenseWire GetExpenses()
        {

            try
            {
                model.ExpenseWire expenseObject = new model.ExpenseWire();
                model.ExpenseWireSend sendObject = new model.ExpenseWireSend();
                model.Search search = new model.Search();
                model.ExpenseWireDataTransactionExpenseSearchBatch batch = new model.ExpenseWireDataTransactionExpenseSearchBatch();

                sendObject.DataTransaction = new model.DataTransaction();
                sendObject.DataTransaction.Expense = new model.Expense();

                search.ApprovalDepth = "All";
                search.MaxRows = 20000;
                search.DetailLevel = "All";
                batch.BatchNumber = BatchId;
                search.Batch = batch;
                sendObject.DataTransaction.Expense.Search = search;

                // Serialize Search Object into XML string.
                string sendXML = Utility.SerializeObject(sendObject);
                XDocument xdocSend = XDocument.Parse(sendXML);
                //xdocSend.Save(@"C:\Users\LeoG\Documents\ExpensewireSend_11-8-19.xml");

                //Send XML to ExpenseWire web service
                string responseXML = sendTransaction(sendXML.ToString());

                XDocument xdoc = XDocument.Parse(responseXML);
                //xdoc.Save(@"C:\Users\LeoG\Documents\Expensewire_11-14-19.xml");
                //Validate the XML file before deserializing. 
                //if (!IsValid(xdoc)) return null;

                //Serialize the ExpenseWire web service XML response 
                expenseObject = (model.ExpenseWire)Utility.Deserialize(xdoc.ToString());
                return expenseObject;

            }
            catch (Exception ex)
            {
                this.Exception = "Download failed. " + ex.InnerException.ToString();
                return null;
            }
            
        }

        private List<EWCheckNumber> GetCheckNumbers()
        {
            MCK_INTEGRATIONEntities DB = null;
            using (DB = new MCK_INTEGRATIONEntities())
            {
                var result = DB.EWCheckNumbers.Where(e => e.ExpenseWireBatchID == BatchId);
                return result.ToList<EWCheckNumber>();
            }          
        }

    }

   
}
