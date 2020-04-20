using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Xml.Serialization;

namespace XML_Maker
{
    /// <summary>
    /// Summary description for XMLMakerWS
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
    // [System.Web.Script.Services.ScriptService]
    public class XMLMakerWS : System.Web.Services.WebService
    {
        private AssembleXML AssXML = new AssembleXML();

        [WebMethod]
        public string HelloWorld()
        {
            return "Hello World";
        }

        [WebMethod]
        public string LandIFileMaker(string intentID, string startDate, string endDate)
        {

            // var  = new WaPWCPRPayrollWeek { amendedDate = System.DateTime.Today, amendedFlag = false };
            //var data = new WaPWCPRPayrollWeek { endOfWeekDate =  System.DateTime.Today, noWorkPerformFlag = true };
            //var serializer = new XmlSerializer(typeof(WaPWCPRPayrollWeek));
            //using (var stream = new StreamWriter("c:\\projects\\test.xml"))
            //    serializer.Serialize(stream, data);
            AssXML.AssembleXMLFiles(intentID, startDate, endDate);


            return "Hello World";
        }

        public string LandI(string intentID, string startDate, string endDate, string incIntent)
        {

            AssXML.AssembleXMLFiles(intentID, startDate, endDate);
            return "Finished";
        }

        private static void NewMethod()
        {
            using (var stream = new StreamWriter("c:\\projects\\test.xml")) ;
        }
    }
}
