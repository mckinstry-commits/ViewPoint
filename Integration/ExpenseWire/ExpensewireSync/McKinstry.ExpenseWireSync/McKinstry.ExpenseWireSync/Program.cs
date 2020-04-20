﻿using System;
using System.Collections.Generic;
using System.Text;

using System.Data;
using System.Xml;
using System.Xml.Serialization;
using System.Xml.Schema;
using System.Xml.Linq;
using System.Xml.XPath;
using System.Linq;
using System.IO;

using Microsoft.Practices.EnterpriseLibrary.Data;
using Microsoft.Practices.EnterpriseLibrary.Common;
using Microsoft.Practices.EnterpriseLibrary.Logging;
using System.Data.Common;
//using IBM.Data.DB2.iSeries;
//using McKinstry.Data;
using System.Configuration;
namespace McKinstry.ExpenseWireSync
{
    class Program
    {

        //static DataSet thisDataSet = null;
        static ExpenseWireProxy.ExpenseWireService svc = null;
        static string ExpenseWireServiceURL = ConfigurationManager.AppSettings.Get("ExpenseWireServiceURL");
        static FileStream fs = File.Open("Log.txt", FileMode.OpenOrCreate, FileAccess.ReadWrite);
        static StreamWriter sw;
        static void Main(string[] args)
        {
            //Create ExpenseWire Services Proxy.
            svc = new ExpenseWireProxy.ExpenseWireService();
            svc.Url = ExpenseWireServiceURL;
            svc.Timeout = 9000000;
            sw = new StreamWriter(fs);

            //Add-Update Jobs/Pay Items .
            sw.WriteLine("Job Sync process has started at " + DateTime.Now.ToString());
            //ExecuteNonQuery("syncCGCJobs");
            //ExecuteNonQuery("syncCGCPayItems");
            ProcessJobs();
            processPayItems("");
            sw.WriteLine("Job Sync process has ended at " + DateTime.Now.ToString());

            if (sw != null) { sw.Flush(); sw = null; }

        }
        static void ProcessJobs()
        {
           // string strJobSQL = getJOBsQuery();
            try
            {
               // DataTable dtResult = getCGCData(strJobSQL);
                DataTable dtResult = getJobs();
                if (dtResult == null) return;
                if (dtResult.Rows.Count == 0) return;

                // XML to send for update or inseert.
                XDocument sendXML = XDocument.Load(@".\XML\ExpenseWire.xml");

                var cgcRows = from row in dtResult.AsEnumerable()
                              select new XElement("Upsert", 
                                    new XElement("Ref", new XElement("ExternalID", row["EXTERNALID"].ToString().Trim())),
                                    new XElement("ContactName", row["CONTACTNAME"] == null ? "" : row["CONTACTNAME"]),
                                    new XElement("Name", row["NAME"]),
                                    new XElement("Addr1", row["ADDR1"] == null ? "" : row["ADDR1"]),
                                    new XElement("Addr2", row["ADDR2"] == null ? "" : row["ADDR2"]),
                                    new XElement("City", row["CITY"] == null ? "" : row["CITY"]),
                                    new XElement("State", row["STATE"] == null ? "" : row["STATE"]),
                                    new XElement("Zip", row["ZIP"] == null ? "" : row["ZIP"]),
                                    new XElement("Country", "USA"),
                                    new XElement("Phone", row["PHONE"] == null ? "" : row["PHONE"]),
                                    new XElement("EmailAddress", ""),
                                    new XElement("WebSite", ""),
                                    new XElement ("UpdatedDate",row["UpdatedDate"]),
                                    new XElement("ExternalID", row["EXTERNALID"].ToString().Trim()),
                                    new XElement("IsActive", row["IsActive"].ToString() == "True" ? true : false));


                //updateJobXML(cgcRows.AsQueryable(),true);

                ////Load existing jobs fom temp xml file.
                //XDocument ewJobs = XDocument.Load(@"Jobs.xml");

                //var updatedRows = from cgcRow in cgcRows
                //                join job in ewJobs.XPathSelectElements("//Jobs/Job")
                //                on new { ID = cgcRow.XPathSelectElement("ExternalID").Value.ToString(), Status = cgcRow.XPathSelectElement("IsActive").Value } equals new { ID = job.Value.ToString(), Status = job.FirstAttribute.Value }
                //                into groups             
                //                where !groups.Any()             
                //                select cgcRow; 

               // Update/Insert jobs to expenseWire
               int i = 0; 
               int j = 500;
               string jobs = "";
               foreach (XElement x in cgcRows)
               {
                   x.XPathSelectElement("UpdatedDate").Remove();
                   sendXML.Descendants("Customer").First().Add(x);
                   jobs += "'" + x.XPathSelectElement("Ref/ExternalID").Value + "'";
                   i++;
                   if (i == j || cgcRows.Count<XElement>() == i)
                   {
                       try
                       {
                           string sessionKey = getSessionKey();
                           string responeXML = svc.SendDataTransaction(sessionKey, sendXML.ToString());
                           svc.CloseDataConnection(sessionKey);
                          // processPayItems(jobs);
                       }
                       catch (Exception ex) { sw.WriteLine("ERROR : " + ex.Message); }
                       //reset for next set of jobs.
                       j = i + 500;
                       sendXML = XDocument.Load(@".\XML\ExpenseWire.xml");
                       jobs = "";
                   }
                   else
                       jobs += ",";
               }

            //   updateJobXML(updatedRows.AsQueryable(), false);
             
            }
            catch(Exception ex) { sw.WriteLine("ERROR @ ProcessJobs: " + ex.Message); }
        }

     

        private static string getJOBsQuery()
        {
            string strJobSQL = "";
            DateTime yesterday = DateTime.Now.AddDays(-5);


            string lastUpdatedJobs = string.Format("{0}{1}{2}", yesterday.Year.ToString(), yesterday.Month.ToString("d2"), yesterday.Day.ToString("d2"));
            strJobSQL = strJobSQL + "SELECT DISTINCT GJBNO as ExternalID, GJBST as IsActive , (GJBNO || ' - ' || GD20A) as Name , GA25A as Addr1, GA25b as Addr2, GCITY as City,GST as State,GZIP as Zip,'USA' as Country, MPHNO as Phone, (rtrim(MFN25)  || ' ' || rtrim(MLN25)) as ContactName, '' as EmailAddress, '' as WebSite, GDTLU as UpdatedDate";
            strJobSQL = strJobSQL + " FROM  CMSFIL.JCPDSC   LEFT join CMSFIL.PRPMST  on  MEENO = GPJMG AND MSTAT='A' ";
            strJobSQL = strJobSQL + " WHERE GSTAT = 'A' " ;
            strJobSQL = strJobSQL + " and (GDTLU > " + lastUpdatedJobs + " OR GDTLU  = 0 )";
     
            //strJobSQL = strJobSQL + " and GJBNO like 'C600%'";

            strJobSQL = strJobSQL + " and GJBNO not like '*%'  and GJBNO  IN ( SELECT CJBNO FROM CMSFIL.JCPMST WHERE CCSTY ='M')";
            strJobSQL = strJobSQL + " order by GJBNO";

            return strJobSQL;
        }

        static XElement processPayItems(string JobNumbers)
        {
            string strJobSQL = "";
            string sessionKey, responeXML = "";
          
            try
            {
                XDocument requestXML = XDocument.Load(@".\XML\ExpenseWire.xml");
                int i = 0, j = 500;

               // DataTable dtResult = getCGCData(strJobSQL);

                DataTable dtResult = getPayItems();

                if (dtResult == null) return null;
                if (dtResult.Rows.Count >= 0)
                {
                  
                }
                   //LINQ to get updated/new rows.
                   var updatedRows = from row in dtResult.AsEnumerable()
                                  select new XElement("Upsert",
                                          new XElement("Ref", new XElement("ExternalID", row["PayItemName"].ToString().Trim())),
                                          new XElement("ProjectNumber", row["PayItemName"] == null ? "" : row["PayItemName"].ToString().Trim()),
                                          new XElement("ProjectDescription", row["Description"]),
                                          new XElement("ExternalID", row["PayItemName"].ToString().Trim()),
                                          new XElement("IsActive", row["Status"].ToString() == "True" ? true : false),
                                          new XElement("GLSuffix", ""),
                                          new XElement("Customer", new XElement("ExternalID", row["JobNumber"].ToString().Trim())));
              
                foreach (XElement x in updatedRows)
                {
                    requestXML.Descendants("Project").First().Add(x);

                    i++;
                    if (i == j || updatedRows.Count<XElement>() == i)
                    {
                        try
                        {
                             //send update/insert XML to ExpenseWire.
                            sessionKey = getSessionKey();
                            responeXML = svc.SendDataTransaction(sessionKey, requestXML.ToString());
                            svc.CloseDataConnection(sessionKey);
                        }
                        catch (Exception ex)
                        {
                           sw.WriteLine("ERROR @ ProcessPayItems : " + ex.Message );
                        }
                        //reset.
                        j = i + 500;
                        requestXML = XDocument.Load(@".\XML\ExpenseWire.xml");
                    }
                }
              
                
                return null;
            }
            catch (Exception ex) { sw.WriteLine("ERROR @ ProcessPayItems : " + ex.Message);  return null; }
        }
        
        private static DataTable getJobs()
        {
            try
            {
                Database DB = DatabaseFactory.CreateDatabase();

                DbCommand cmd = DB.GetStoredProcCommand("getCGCJobs");
                cmd.CommandTimeout = 6000;
              
                DataSet ds = DB.ExecuteDataSet(cmd);

                
                if (ds != null)
                {
                    return ds.Tables[0];
                }
            }
            catch(Exception ex) { }
            
            return null;
        }

        private static DataTable getPayItems()
        {
            try
            {
                Database DB = DatabaseFactory.CreateDatabase();
                DbCommand cmd = DB.GetStoredProcCommand("getCGCPayItems");
                cmd.CommandTimeout = 6000;
                DataSet ds = DB.ExecuteDataSet(cmd);


                if (ds != null)
                {
                    return ds.Tables[0];
                }
            }
            catch (Exception ex) { sw.WriteLine(ex.Message); }

            return null;
        }

        private static void ExecuteNonQuery(string StoredProc)
        {
            try
            {
                Database DB = DatabaseFactory.CreateDatabase();
                DbCommand cmd = DB.GetStoredProcCommand(StoredProc);
                cmd.CommandTimeout = 6000;
                int affected= DB.ExecuteNonQuery(cmd);
            }
            catch (Exception ex) { }
        }
               
        private static string getSessionKey()
        {
            XmlDocument xmlparse = new XmlDocument();
            try
            {
                string userName = ConfigurationManager.AppSettings.Get("ExpenseWireServiceUserName");
                string password = ConfigurationManager.AppSettings.Get("ExpenseWireServicePassword");
                string clientID = ConfigurationManager.AppSettings.Get("ExpenseWireServiceClientID");
                string xml = svc.OpenDataConnection(userName, password, clientID);
                xmlparse.LoadXml(xml);
                string session = xmlparse.SelectSingleNode("//ExpenseWire/OpenDataConnection/SessionKey").InnerText;
                return session;
            }
            catch { return ""; }
        }
               
        static DataTable getCGCData(string strJobSQL)
        {
            DataTable dt = null;
            cgcService.Utility CGCService = null;
            //get Active/payitems jobs from CGC.
            try
            {
                CGCService = new cgcService.Utility();
                CGCService.Url = ConfigurationManager.AppSettings.Get("CGCServiceURL");
                dt = CGCService.GetCGCDataByQuery(strJobSQL);
            }
            catch (Exception ex)
            {
                if (CGCService != null) CGCService.Dispose();
            }
            return dt;
        }

        #region "Help Functions"

        private static DateTime defaultDate = DateTime.Parse("1/1/1900");
        public static DateTime ConvertFromCGCDate(string Date)
        {
            char _padChar = '0';
            string strDate = Date;
            if (!(strDate.Trim().Equals("0")))
            {

                if (!(strDate.Length.Equals(8)))
                {
                    strDate = PadLeft(strDate.ToString(), 6, _padChar);
                    strDate = DateTime.Now.Year.ToString().Substring(0, 2) + strDate;
                }


                try
                {
                    string strDateYear = Date.Substring(0, 4);
                    string strDateMonth = Date.Substring(4, 2);
                    string strDateDay = Date.Substring(6, 2);

                    return System.Convert.ToDateTime(String.Format("{0}/{1}/{2}", strDateMonth, strDateDay, strDateYear));
                }
                catch (Exception e)
                {
                    Console.WriteLine(e.Message);
                    return defaultDate;
                }
            }
            else
            {
                return defaultDate;
            }
        }
        private static string PadLeft(string Value, int Length, char PadCharacter)
        {
            if (!(Value.Length.Equals(Length)))
            {
                return Value.PadLeft(Length, PadCharacter);
            }
            else
            {
                return Value;
            }
        }
        #endregion
       
        static string getSearchXML()
        {
            return "";

            #region " Updated records from ExpenseWire"

            // Convert CGC DataTable to XDocument.
            //XDocument cgcXD = new XDocument();
            //using (XmlWriter w = cgcXD.CreateWriter())
            //{
            //    dtResult.WriteXml(w, System.Data.XmlWriteMode.IgnoreSchema, true);
            //}

            ////LINQ to get updated rows.
            // var updatedRows = from ExpElement in expXD.XPathSelectElements("//ExpenseWire/SendDataTransaction/Customer/Search/Customer")
            //                   join CgcElement in cgcXD.XPathSelectElements("/DocumentElement/Table")
            //                   on new { ID = ExpElement.Element("ExternalID").Value } equals new { ID = CgcElement.Element("EXTERNALID").Value }
            //                   where ExpElement.Element("IsActive").Value != CgcElement.Element("ISACTIVE").Value
            //                   select new XElement("Upsert",
            //                         new XElement("IsActive", !(Convert.ToBoolean(Convert.ToInt32(CgcElement.Element("ISACTIVE").Value)))),
            //                         new XElement("ExternalID", CgcElement.Element("EXTERNALID").Value),
            //                         new XElement("WebSite", ""),
            //                         new XElement("EmailAddress", ""),
            //                         new XElement("Phone", CgcElement.Element("PHONE") == null ? "" : CgcElement.Element("PHONE").Value),
            //                         new XElement("Country", "USA"),
            //                         new XElement("Zip", CgcElement.Element("ZIP") == null ? "" : CgcElement.Element("ZIP").Value),
            //                         new XElement("State", CgcElement.Element("STATE") == null ? "" : CgcElement.Element("STATE").Value),
            //                         new XElement("City", CgcElement.Element("CITY") == null ? "" : CgcElement.Element("CITY").Value),
            //                         new XElement("Addr2", CgcElement.Element("ADDR2") == null ? "" : CgcElement.Element("ADDR2").Value),
            //                         new XElement("Addr1", CgcElement.Element("ADDR1") == null ? "" : CgcElement.Element("ADDR1").Value),
            //                         new XElement("ContactName", CgcElement.Element("CONTACTNAME") == null ? "" : CgcElement.Element("CONTACTNAME").Value),
            //                         new XElement("Name", "TEST2 : " + CgcElement.Element("NAME").Value),
            //                         new XElement("Ref", ExpElement.XPathSelectElement("//Ref/Guid"))                                
            //                         );

            // var NewRows = from CgcElement in cgcXD.XPathSelectElements("/DocumentElement/Table")
            //               join ExpElement in expXD.XPathSelectElements("//ExpenseWire/SendDataTransaction/Customer/Search/Customer")
            //                   on CgcElement.Element("ISACTIVE").Value equals "0"
            //                   where (ExpElement.Element("ExternalID").Value !=CgcElement.Element("EXTERNALID").Value )
            //                   select new XElement("Upsert",
            //                       new XElement("IsActive", !(Convert.ToBoolean(Convert.ToInt32(CgcElement.Element("ISACTIVE").Value)))),
            //                       new XElement("ExternalID", CgcElement.Element("EXTERNALID").Value),
            //                       new XElement("WebSite", ""),
            //                       new XElement("EmailAddress", ""),
            //                       new XElement("Phone", CgcElement.Element("PHONE") == null ? "" : CgcElement.Element("PHONE").Value),
            //                       new XElement("Country", "USA"),
            //                       new XElement("Zip", CgcElement.Element("ZIP") == null ? "" : CgcElement.Element("ZIP").Value),
            //                       new XElement("State", CgcElement.Element("STATE") == null ? "" : CgcElement.Element("STATE").Value),
            //                       new XElement("City", CgcElement.Element("CITY") == null ? "" : CgcElement.Element("CITY").Value),
            //                       new XElement("Addr2", CgcElement.Element("ADDR2") == null ? "" : CgcElement.Element("ADDR2").Value),
            //                       new XElement("Addr1", CgcElement.Element("ADDR1") == null ? "" : CgcElement.Element("ADDR1").Value),
            //                       new XElement("ContactName", CgcElement.Element("CONTACTNAME") == null ? "" : CgcElement.Element("CONTACTNAME").Value),
            //                       new XElement("Name", "TEST2 : " + CgcElement.Element("NAME").Value),
            //                         new XElement("Ref")
            //                         );

            // foreach (XElement e in updatedRows)
            // {
            //     Console.Write(e.Value);
            // }
            #endregion

            #region " DONT NEED"
            ////Convert ExoenseWire XML string to LINQ XML document.
            //XDocument expXD = XDocument.Parse(responeXML);



            //foreach (DataRow row in dtResult.Rows)
            //{
            //    XElement x = new XElement("Upsert",
            //                        new XElement("IsActive", row["IsActive"].ToString() == "0" ? true:false ),
            //                        new XElement("ExternalID", row["ExternalID"].ToString()),
            //                        new XElement("WebSite", "www.mckinstry.com"),
            //                        new XElement("EmailAddress", "mahendarb@mckinstry.com"),
            //                        new XElement("Phone", row["Phone"].ToString()),
            //                        new XElement("Country", "USA"),
            //                        new XElement("Zip", row["Zip"].ToString()),
            //                        new XElement("State", row["State"].ToString()),
            //                        new XElement("City", row["City"].ToString()),
            //                        new XElement("Addr2", row["Addr1"].ToString()),
            //                        new XElement("Addr1", row["Addr2"].ToString()),
            //                        new XElement("ContactName", row["ContactName"].ToString()),
            //                        new XElement("Name", "TEST3 : " + row["Name"].ToString()));

            //    //check if job existing in expensewire. If exist , then add Guid ID.
            //    string XPathString = "//ExpenseWire/SendDataTransaction/Customer/Search/Customer[ExternalID = '" + row["ExternalID"] + "']";
            //    IEnumerable<XElement> elements = expXD.XPathSelectElements(XPathString);


            //    if (elements.Count<XElement>() > 0)
            //    {
            //        x.Add(new XElement("Ref", elements.First<XElement>().XPathSelectElement("//Ref/Guid")));
            //        sendXML.Descendants("Customer").First().Add(x);
            //    }
            //    else //add new job if active job.
            //    {
            //        if (row["IsActive"].ToString() == "0")
            //        {
            //            x.Add(new XElement("Ref"));
            //            sendXML.Descendants("Customer").First().Add(x);
            //        }
            //    }

            //}
            #endregion

        }

        #region "Unused Methods"
        private static void updateJobXML(IQueryable updatedRows, bool IsBeforeSync)
        {

            try
            {
                //Load existing jobs fom temp xml file.
                XDocument ewJobs = XDocument.Load(@"Jobs.xml");
                // update the Jobs XML file.
                foreach (XElement e in updatedRows)
                {
                    if (ewJobs.XPathSelectElement("//Job[text() = " + e.XPathSelectElement("ExternalID").Value + "]") != null)
                    {
                        if (e.XPathSelectElement("UpdatedDate").Value != "0")
                            ewJobs.XPathSelectElement("//Job[text() = " + e.XPathSelectElement("ExternalID").Value + "]").Remove();
                        else
                            ewJobs.XPathSelectElement("//Jobs[Job='" + e.XPathSelectElement("ExternalID").Value + "']").SetAttributeValue("Status", e.Element("IsActive").Value.ToString());
                    }
                    else
                    {
                        if (e.XPathSelectElement("UpdatedDate").Value == "0" && !IsBeforeSync)
                        {
                            XElement newJob = new XElement("Job", e.XPathSelectElement("ExternalID").Value);
                            newJob.SetAttributeValue("Status", e.Element("IsActive").Value);
                            ewJobs.Descendants("Jobs").First().Add(newJob);
                        }
                    }
                }
                ewJobs.Save("Jobs.Xml");
                ewJobs = null;
            }
            catch (Exception ex) { sw.WriteLine("ERROR @ updateJobXML : " + ex.Message); }
        }
        static XDocument addBlankPayItem(string JobNumbers, DataTable PayItems)
        {
            XElement blankPayitem = null;
            string[] jobs = JobNumbers.Split(',');
            char charString = "'".ToCharArray(0, 1)[0];
            XDocument XDoc = XDocument.Load(@".\XML\ExpenseWire.xml");
            foreach (string job in jobs)
            {
                DataRow[] rows = PayItems.Select("JobNumber = " + job);
                if (rows == null || rows.Count<DataRow>() == 0)
                {
                    blankPayitem = new XElement("Upsert",
                                        new XElement("Ref", new XElement("ExternalID", "NA" + job.Replace(charString, ' '))),
                                        new XElement("ProjectNumber", job.Replace(charString, ' ') + " - NoPayItems"),
                                        new XElement("ProjectDescription", "No PayItems"),
                                        new XElement("ExternalID", "NA" + job.Replace(charString, ' ')),
                                        new XElement("IsActive", true),
                                        new XElement("GLSuffix", ""),
                                        new XElement("Customer", new XElement("ExternalID", job.Replace(charString, ' ').Trim())));


                    XDoc.Descendants("Project").First().Add(blankPayitem);
                }
            }

            return XDoc;

        }
        private static void ProcessUsers()
        {

            try
            {
                XDocument sendXML = null;
                XDocument sendXML2 = null;
                DataTable result = null;
                string sessionKey = "";
                string responeXML = "";
                for (int i = 0; i < 1; i++)
                {
                    //XML to send for update or inseert.
                    sendXML = XDocument.Load(@"..\..\XML\UserSearch.xml");
                    //send update/insert XML to ExpenseWire.
                    sessionKey = getSessionKey();
                    responeXML = svc.SendDataTransaction(sessionKey, sendXML.ToString());
                    @svc.CloseDataConnection(sessionKey);

                    XDocument projects = XDocument.Parse(responeXML);
                    //string whereProjects = "";
                    //string _job = "";
                    //foreach (XElement project in projects.XPathSelectElements("//ExpenseWire/SendDataTransaction/Project/Search/Project"))
                    //{

                    //    _job = project.XPathSelectElement("Ref/ProjectNumber").Value.Split('-')[0].ToString().Trim();

                    //    if (whereProjects != "" && whereProjects.IndexOf(_job, 0) <= 0)
                    //        whereProjects += ",";

                    //    if (_job != "")
                    //    {
                    //        //_job = "'" + _job.Trim() + "'";
                    //        if (whereProjects.IndexOf(_job, 0) <= 0)
                    //            whereProjects += "'" + _job.Trim() + "'";
                    //    }


                    //}






                    //get  lastupdated PayItems
                    //DateTime yesterday = DateTime.Now.AddDays(-100);
                    //string lastUpdatedJobs = string.Format("{0}{1}{2}", yesterday.Year.ToString(), yesterday.Month.ToString("d2"), yesterday.Day.ToString("d2"));
                    ////string lastUpdatedJobs = "0";
                    //string strJobSQL = "SELECT GCONO, CJCDI as PayItemID, GJBNO as JobNumber,GJBST as Status,CD20A as Description";
                    string strJobSQL = "SELECT GCONO, CJCDI as PayItemID, (trim(GJBNO) || ' - ' || trim(CJCDI) || ' - ' || trim(CD20A)) as PayItemName, GJBNO as JobNumber,GJBST as Status,CD20A as Description";
                    strJobSQL = strJobSQL + " FROM  CMSFIL.JCPMST Join CMSFIL.JCPDSC on (GCONO = CCONO  AND GDVNO = CDVNO and GJBNO = CJBNO AND CCONO in (1,15,20,30,50,60)  and CCSTY = 'M' and CSTAT = 'A'  ) ";
                    strJobSQL = strJobSQL + " WHERE  GJBNO = '04587' and GJBST = 0";
                    //strJobSQL = strJobSQL + " and GCONO = CCONO  and GDVNO = CDVNO and GJBNO = CJBNO and GSJNO = CSJNO ";
                    //strJobSQL = strJobSQL + " and GJBNO in (" + JobNumbers + ")";
                    //strJobSQL = strJobSQL + " and GJBST = 0 and GJBNO in (" + whereProjects + ")";
                    strJobSQL = strJobSQL + "  order by GCONO,GDVNO,GJBNO,GSJNO,CJCDI";

                    //if(result == null)
                    //    result = getCGCData(strJobSQL);

                    //var cgcRows = from row in result.AsEnumerable()
                    //              select new XElement("Upsert",
                    //                      new XElement("Ref", new XElement("ExternalID", row["PayItemName"].ToString().Trim())),
                    //                      new XElement("ProjectNumber", row["PayItemName"] == null ? "" : row["PayItemName"].ToString().Trim()),
                    //                      new XElement("ProjectDescription", row["Description"].ToString().Replace("*","BLANK PAY ITEM")),
                    //                      new XElement("ExternalID", row["PayItemName"].ToString().Trim()),
                    //                      new XElement("IsActive", row["Status"].ToString() == "0" ? true : false),
                    //                      new XElement("GLSuffix", ""),
                    //                      new XElement("Customer", new XElement("ExternalID", row["JobNumber"].ToString().Trim())));



                    sendXML2 = XDocument.Load(@"..\..\XML\ExpenseWire.xml");
                    ////if (result.Rows.Count == 0)
                    ////{
                    //var updatedRows = from project in projects.XPathSelectElements("//ExpenseWire/SendDataTransaction/Project/Search/Project")
                    //                  join cgcRow in cgcRows
                    //                 on new { JobID = project.XPathSelectElement("Ref/ProjectNumber").Value.Split('-')[0].ToString().Trim() } equals
                    //                    new { JobID = cgcRow.XPathSelectElement("//Customer/ExternalID").Value.Trim() }
                    //                  // where project.XPathSelectElement("ProjectDescription").Value == "*"
                    //                  //into groups
                    //                  //where !groups.Any()
                    //                  select (new XElement("Upsert",
                    //                               new XElement("Ref", new XElement("Guid", project.XPathSelectElement("Ref/Guid").Value)),
                    //                               new XElement("IsActive", cgcRow.XPathSelectElement("IsActive").Value),
                    //                               new XElement("ExternalID", cgcRow.XPathSelectElement("ExternalID").Value),
                    //                               new XElement("BudgetedAmount", project.XPathSelectElement("BudgetedAmount").Value),
                    //                               new XElement("ProjectDescription", cgcRow.XPathSelectElement("ProjectDescription").Value),
                    //                               new XElement("GLSuffix", project.XPathSelectElement("ExternalID").Value),
                    //                               new XElement("Customer", new XElement("Guid", project.XPathSelectElement("Customer/Guid").Value)),
                    //                               new XElement("ProjectNumber", cgcRow.XPathSelectElement("ProjectNumber").Value.Replace("*", "BLANK PAY ITEM"))));

                    var deleteRows = from project in projects.XPathSelectElements("//ExpenseWire/SendDataTransaction/Project/Search/Project")
                                     //where project.XPathSelectElement("Ref/ProjectNumber").Value.Split('-')[1].ToString().Trim() == "" && project.XPathSelectElement("ProjectDescription").Value == "*"
                                     select (new XElement("Upsert",
                                                  new XElement("Ref", new XElement("Guid", project.XPathSelectElement("Ref/Guid").Value)),
                                                  new XElement("IsActive", true),
                                                  new XElement("ExternalID", project.XPathSelectElement("Ref/ProjectNumber").Value.Replace("*", "BLANK PAY ITEM")),
                                                  new XElement("BudgetedAmount", project.XPathSelectElement("BudgetedAmount").Value),
                                                  new XElement("ProjectDescription", project.XPathSelectElement("ProjectDescription").Value.Replace("*", "BLANK PAY ITEM")),
                                                  new XElement("GLSuffix", ""),
                                                  new XElement("Customer", new XElement("Guid", project.XPathSelectElement("Customer/Guid").Value)),
                                                  new XElement("ProjectNumber", project.XPathSelectElement("Ref/ProjectNumber").Value.Replace("*", "BLANK PAY ITEM"))));

                    string _PayItem, _processed = "";
                    int j = 0;
                    int z = 100;
                    foreach (XElement e in deleteRows)
                    {
                        sendXML2.Descendants("Project").First().Add(e);
                        j++;
                        if ((j == z) || (j == deleteRows.Count<XElement>()))
                        {
                            sessionKey = getSessionKey();
                            responeXML = svc.SendDataTransaction(sessionKey, sendXML2.ToString());
                            svc.CloseDataConnection(sessionKey);

                            z = 100 + j;
                            sendXML2 = XDocument.Load(@"..\..\XML\ExpenseWire.xml");
                        }

                    }



                    //Delete /Inactivate blank rows.
                    //j = 0;
                    //z = 100;

                    //foreach (XElement d in deleteRows)
                    //{
                    //    sendXML2.Descendants("Project").First().Add(d);
                    //    j++;
                    //    if ((j == z) || (j == deleteRows.Count<XElement>()))
                    //    {
                    //        sessionKey = getSessionKey();
                    //        responeXML = svc.SendDataTransaction(sessionKey, sendXML2.ToString());
                    //        svc.CloseDataConnection(sessionKey);

                    //        z = 100 + j;
                    //        sendXML2 = XDocument.Load(@"..\..\XML\ExpenseWire.xml");
                    //    }
                    //}





                    //}
                    //  int i = 0;

                    //foreach (XElement project in projects.XPathSelectElements("//ExpenseWire/SendDataTransaction/Project/Search/Project"))
                    //{


                    //    _job = project.XPathSelectElement("Ref/ProjectNumber").Value.Split('-')[0].ToString().Trim();
                    //    _PayItem = project.XPathSelectElement("Ref/ProjectNumber").Value.Split('-')[1].ToString().Trim();

                    //    if (_processed.IndexOf(_job, 0) > 0)
                    //        continue;


                    //    var InActiverows = from cgcRow in cgcRows
                    //                       where cgcRow.XPathSelectElement("ExternalID").Value.Trim() == _job
                    //                       select new XElement("Update",
                    //                                 new XElement("Ref", new XElement("Guid", project.XPathSelectElement("Ref/Guid").Value)),
                    //                                 new XElement("IsActive", false),
                    //                                 new XElement("ExternalID", cgcRow.XPathSelectElement("ExternalID").Value),
                    //                                 new XElement("BudgetedAmount", project.XPathSelectElement("BudgetedAmount").Value),
                    //                                 new XElement("ProjectDescription", cgcRow.XPathSelectElement("ProjectDescription").Value),
                    //                                 new XElement("GLSuffix", cgcRow.XPathSelectElement("ExternalID").Value),
                    //                                 new XElement("Customer", new XElement("Guid", project.XPathSelectElement("Customer/Guid").Value)),
                    //                                 new XElement("ProjectNumber", project.XPathSelectElement("Ref/ProjectNumber").Value.ToString().Replace(" *", " " + cgcRow.XPathSelectElement("ProjectDescription").Value)));
                    ////    var ActiveRow = from cgcRow in cgcRows
                    ////                    where cgcRow.XPathSelectElement("Status").Value == "0" && cgcRow.XPathSelectElement("JobNumber").Value.Trim() == _job
                    ////                    select new XElement("Update",
                    ////                              new XElement("Ref", new XElement("Guid", project.XPathSelectElement("Ref/Guid").Value)),
                    ////                              new XElement("IsActive", false),
                    ////                              new XElement("ExternalID", cgcRow.XPathSelectElement("ExternalID").Value),
                    ////                              new XElement("BudgetedAmount", project.XPathSelectElement("BudgetedAmount").Value),
                    ////                              new XElement("ProjectDescription", cgcRow.XPathSelectElement("ProjectDescription").Value),
                    ////                              new XElement("GLSuffix", cgcRow.XPathSelectElement("ExternalID").Value),
                    ////                              new XElement("Customer", new XElement("Guid", project.XPathSelectElement("Customer/Guid").Value)),
                    ////                              new XElement("ProjectNumber", project.XPathSelectElement("Ref/ProjectNumber").Value.ToString().Replace(" *", " " + cgcRow.XPathSelectElement("ProjectDescription").Value)));



                    //foreach (XElement row in InActiverows)
                    //{
                    //    sendXML2.Descendants("Project").First().Add(row);

                    //    if ((j == z) || (j == cgcRows.Count<XElement>()))
                    //    {
                    //        sessionKey = getSessionKey();
                    //        responeXML = svc.SendDataTransaction(sessionKey, sendXML2.ToString());
                    //        @svc.CloseDataConnection(sessionKey);

                    //        z = 100 + j;
                    //        sendXML2 = XDocument.Load(@"..\..\XML\ExpenseWire.xml");
                    //    }
                    //    j++;
                    //}

                    //    //foreach (XElement row in cgcRows)
                    //    //{
                    //    //    sendXML2.Descendants("Project").First().Add(row);

                    //    //    if ((j == z) || (j == cgcRows.Count<XElement>()))
                    //    //    {
                    //    //        sessionKey = getSessionKey();
                    //    //        responeXML = svc.SendDataTransaction(sessionKey, sendXML2.ToString());
                    //    //        @svc.CloseDataConnection(sessionKey);

                    //    //        z = 100 + j;
                    //    //        sendXML2 = XDocument.Load(@"..\..\XML\ExpenseWire.xml");
                    //    //    }
                    //    //    j++;
                    //    //}



                    //}





                    //i++;

                    sendXML = null;
                    sendXML2 = null;
                }
            }
            catch (Exception ex) { Console.WriteLine(ex.Message); }

        }

        private static void ProcessDummiePayItems()
        {

            try
            {
                XDocument sendXML = null;
                XDocument sendXML2 = null;
                for (int i = 0; i <= 1000; i++)
                {
                    //XML to send for update or inseert.
                    sendXML = XDocument.Load(@"..\..\XML\UserSearch.xml");
                    //send update/insert XML to ExpenseWire.
                    string sessionKey = getSessionKey();
                    string responeXML = svc.SendDataTransaction(sessionKey, sendXML.ToString());
                    @svc.CloseDataConnection(sessionKey);

                    XDocument projects = XDocument.Parse(responeXML);
                    var updatedRows = from project in projects.XPathSelectElements("//ExpenseWire/SendDataTransaction/Project/Search/Project")
                                      select (new XElement("Update",
                                                   new XElement("Ref", new XElement("Guid", project.XPathSelectElement("Ref/Guid").Value)),
                                                   new XElement("IsActive", false),
                                                   new XElement("ExternalID", project.XPathSelectElement("ExternalID").Value),
                                                   new XElement("BudgetedAmount", project.XPathSelectElement("BudgetedAmount").Value),
                                                   new XElement("ProjectDescription", project.XPathSelectElement("ProjectDescription").Value),
                                                   new XElement("GLSuffix", project.XPathSelectElement("ExternalID").Value),
                                                   new XElement("Customer", new XElement("Guid", project.XPathSelectElement("Customer/Guid").Value)),
                                                   new XElement("ProjectNumber", project.XPathSelectElement("ProjectNumber").Value)));
                    int j = 0;
                    int z = 100;
                    sendXML2 = XDocument.Load(@"..\..\XML\ExpenseWire.xml");
                    XDocument jobs = XDocument.Load(@"..\..\XML\Jobs.xml");

                    foreach (XElement e in updatedRows)
                    {
                        sendXML2.Descendants("Project").First().Add(e);
                        jobs.Add(new XElement("Job", e.XPathSelectElement("ProjectNumber").Value.Split('-')[0]));
                        j++;
                        if ((j == z) || (j == updatedRows.Count<XElement>()))
                        {
                            sessionKey = getSessionKey();
                            responeXML = svc.SendDataTransaction(sessionKey, sendXML2.ToString());
                            @svc.CloseDataConnection(sessionKey);

                            z = 100 + j;
                            sendXML2 = XDocument.Load(@"..\..\XML\ExpenseWire.xml");
                        }

                    }


                }
            }
            catch (Exception ex) { Console.WriteLine(ex.Message); }

        }

        private static string getEMployeeByEmail(string email)
        {
            //string strSQL = "select REFERENCENUMBER from PEOPLE where EMAILPRIMARY = '" + email + "'";

            //IDbCommand command = null;
            //IDbConnection conn = null;
            //string empID = "";

            //try
            //{
            //    conn = getHRNETConnection();
            //    command = Command.GetCommand(conn);
            //    command.CommandType = CommandType.Text;
            //    command.CommandText = strSQL;
            //    if (command.ExecuteScalar() != null)
            //        empID = (string)command.ExecuteScalar();

            //}
            //catch (Exception ex) { if (conn.State == ConnectionState.Open) conn.Close(); }
            //finally { if (conn.State == ConnectionState.Open) conn.Close(); }
            //return empID;
            return null;
        }
        #endregion


    }

}
