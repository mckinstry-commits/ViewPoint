using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;
using System.Configuration;
using System.Xml.Serialization;
using System.IO;

using model = McKinstry.ExpenseWire.Model;

namespace McKinstry.ExpenseWire.Controller
{
    public class Utility
    {
        public static byte[] GetBytes(string str)
        {
            byte[] bytes = new byte[str.Length * sizeof(char)];
            System.Buffer.BlockCopy(str.ToCharArray(), 0, bytes, 0, bytes.Length);
            return bytes;
        }


        private static DateTime defaultDate = DateTime.Parse("1/1/1900");
       

        public static string PraseToCGCString(string value)
        {
            Regex re = new Regex("[;\\\\/:*?\"<>|&/']");

            //string outputString = re.Replace(value, " "); 

            if (value != null)
            {
                value = value.Trim().Replace("\r\n", " ").Replace("\n", " ");
                return re.Replace(value, " ");
            }

            else
                return "";
        }

        #region "Help Functions"

        public static string SerializeObject(object obj)
        {
            System.Xml.XmlDocument xmlDoc = new System.Xml.XmlDocument();
            System.Xml.Serialization.XmlSerializer serializer = new System.Xml.Serialization.XmlSerializer(obj.GetType());
            using (System.IO.MemoryStream ms = new System.IO.MemoryStream())
            {
                serializer.Serialize(ms, obj);
                ms.Position = 0;
                xmlDoc.Load(ms);
                return xmlDoc.InnerXml;
            }
        }

        public static Object Deserialize(string Xml)
        {
            XmlSerializer serialize = new XmlSerializer(typeof(model.ExpenseWire));
            MemoryStream memoryStream = new MemoryStream(Encoding.UTF8.GetBytes(Xml));
            Object obj = serialize.Deserialize((memoryStream));
            memoryStream.Dispose();
            return obj;
        }

        

      
        //private static void messageFactory.LogMe(string message)
        //{
        //    if (sw == null)
        //        sw = new StreamWriter(fs, System.Text.Encoding.UTF8);
        //    sw.WriteLine(message);
        //    sb.AppendLine(message);
        //}

        //private static void ExceptionLog(string Value)
        //{
        //    if (swException == null)
        //        swException = new StreamWriter(fsException, System.Text.Encoding.UTF8);
        //    swException.WriteLine(Value);
        //}


        #endregion
    }
}
