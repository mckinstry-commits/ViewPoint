using System;
using System.Data;
using System.Configuration;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using System.Text;
using System.IO;

namespace VPLookup.UI
{
/// <summary>
/// Summary description for Parser: Parser for files like csv, excel etc.
/// </summary>
    public abstract class Parser
    {
        // The type of file. ie, extension of the file.
        public enum FileTypes
        {
            CSV,
            XLS,
            XLSX,
            MDB,
            ACCDB,
            TAB
        }

        // Constructor
        public Parser(){}

        // Reset resources
        public abstract void Reset();

        // Get one record at a time
        public abstract string[] GetNextRow();

        //Close parser and dispose parser object
        public abstract void Close();
      
        // Generic function to get instance of parser class based on file type.
        public static Parser GetParser(string filePath, FileTypes type)
        {
            Parser parsr = null;
            switch (type)
            {
                case FileTypes.CSV:
                    parsr = new CsvParser(filePath, System.Globalization.CultureInfo.CurrentUICulture.TextInfo.ListSeparator[0]);
                    break;
                case FileTypes.TAB:
                    parsr = new CsvParser(filePath, '\t');
                    break;
                case FileTypes.XLS:
                    try
                    {
                        parsr = new ExcelParser(filePath, HttpContext.Current.Session["SheetName"].ToString());
                    }
                    catch (Exception ex)
                    {
                        throw new Exception(ex.Message);
                    }
                    break;
                case FileTypes.XLSX:
                    try
                    {
                        parsr = new ExcelParser(filePath, HttpContext.Current.Session["SheetName"].ToString());
                    }
                    catch (Exception ex)
                    {
                        throw new Exception(ex.Message);
                    }
                    break;
                case FileTypes.MDB:
                    try
                    {
                        parsr = new AccessParser(filePath, HttpContext.Current.Session["TableName"].ToString());
                    }
                    catch (Exception ex)
                    {
                        throw new Exception(ex.Message);
                    }
                    break;
                case FileTypes.ACCDB:
                    try
                    {
                        parsr = new AccessParser(filePath, HttpContext.Current.Session["TableName"].ToString());
                    }
                    catch (Exception ex)
                    {
                        throw new Exception(ex.Message);
                    }
                    break;
            }
            return parsr;
        }
    }
}