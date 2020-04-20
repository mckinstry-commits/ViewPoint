using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Windows.Forms;
using Office = Microsoft.Office.Core;
using Word = Microsoft.Office.Interop.Word;

using System.Reflection;
using VP = McKinstry.ViewPoint.Subcontract.VPService;
//using VP = McKinstry.ViewPoint.Subcontract.DEVS;
namespace McKinstry.ViewPoint.Subcontract
{
   
    class CreateDocument 
    {
        private static object what = Word.WdGoToItem.wdGoToLine;
        private static object which = Word.WdGoToDirection.wdGoToLast;
        private static object name = System.Type.Missing;
        private static object missing = System.Type.Missing;
        private static object isTrue = true;
        private static object notTrue = false;
        private static string exchibitfilePath = "";
        private static string exhibitfileName = "";
        private static string html = "";
        private static object contractFileName = Type.Missing;
        private static Word.Document docCurrent =null;
        private static object oEndOfDoc = "\\endofdoc"; /* \endofdoc is a predefined bookmark */
        private static VP.ContractServiceClient svc =  svc = null;
        private static VP.DocLocation location = null;
        private static VP.Subcontract contract = null;
        private static VP.SubcontractCO subcontractCO = null;
        private static VP.MasterContract mastercontract = null;
        private static List<VP.DocLocation> locations = null;
        private static List<VP.Subcontract> contracts = null;
        private static List<VP.MasterContract> mastercontracts = null;
        private static List<VP.SubcontractCO> subcontractCOs = null;
        private static object templatePath = @"\\mckviewpoint\Viewpoint Repository\Document Templates\Custom\SubExhibits\Templates\";
        //private static object templatePath = @"\\sestgviewpoint\Viewpoint Repository\Document Templates\Custom\SubExhibits\Templates\";
        private static object templateName = "";  
        private Word.Application Wordapp = null;
        public static List<VP.Company> Companies()
        {
            //TODO uncomment.
            Initilizate();
            setServiceDelegation();
            return svc.getCompanies().ToList<VP.Company>();
        }

        public static void Initilizate()
        {
            svc =  svc = new VP.ContractServiceClient();
            location = new VP.DocLocation();
            contract = new VP.Subcontract();
            mastercontract = new VP.MasterContract();
            subcontractCO = new VP.SubcontractCO();
            locations = new List<VP.DocLocation>();
            contracts = new List<VP.Subcontract>();
            mastercontracts = new List<VP.MasterContract>();
            subcontractCOs = new List<VP.SubcontractCO>();
        }

        public static string CreateSubContractChangeOrder(Word.Application app, string SL, string CO)
        {
            try
            {
                Initilizate();
                setServiceDelegation();
                subcontractCOs = svc.getSubcontractCOs(SL, CO).ToList();

                if (subcontractCOs != null)
                {
                    subcontractCO = subcontractCOs.FirstOrDefault();

                    if (subcontractCO == null) MessageBox.Show("No subcontract record found with this number. Please entere a valid SL#.");

                    templateName = templatePath + "McK Subcontract CO- Final.dotx";
                    docCurrent = app.Documents.Add(ref templateName);

                    //Update Book Marks on the document.
                    updateBookMarkFields(subcontractCO);

                    //Insert Table data
                    InsertTableData();
                    //Delete Bookmarks
                    removeBookMarks();
                    DeleteBlankPage(app);
                }
                else
                    MessageBox.Show("No subcontract record found with this number. Please entere a valid SL#.");

                return "Success";
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                Dispose();
            }

        }

        private static void InsertTableData()
        {
            Decimal currentAmount = 0;
            Word.Range r = docCurrent.Bookmarks["ItemTable"].Range;
            Word.Table t = docCurrent.Tables.Add(r, 1, 8, Word.WdDefaultTableBehavior.wdWord9TableBehavior, Word.WdAutoFitBehavior.wdAutoFitFixed);
            Word.Style style = r.get_Style();
            style.Font.Name = "Times New Roman";
            style.Font.Size = 8;
            t.set_Style(style);

            Word.Row row = t.Rows[1];

            //Header
            row.Cells[1].Range.Text = "Sub. Item";
            row.Cells[2].Range.Text = "Contract Item";
            row.Cells[3].Range.Text = "Phase";
            row.Cells[4].Range.Text = "Description";
            row.Cells[5].Range.Text = "Units";
            row.Cells[6].Range.Text = "U/M";
            row.Cells[7].Range.Text = "Unit Price";
            row.Cells[8].Range.Text = "Amount";

            foreach (VP.SubcontractCO co in subcontractCOs)
            {
                Word.Row rw = t.Rows.Add(ref missing);
                rw.Cells[1].Range.Text = co.SubCO.ToString();
                rw.Cells[2].Range.Text = co.CostTypeValue;
                rw.Cells[3].Range.Text = co.Phase;
                rw.Cells[4].Range.Text = co.SLItemDescription;
                rw.Cells[5].Range.Text = co.Units.ToString();
                rw.Cells[6].Range.Text = co.UM;
                rw.Cells[7].Range.Text = co.UnitCost.ToString();
                rw.Cells[8].Range.Text = co.Amount;
                currentAmount += Decimal.Parse(co.Amount,System.Globalization.NumberStyles.Currency);
            }
            docCurrent.Bookmarks["AmountThisSubCO"].Range.Text = string.Format("{0:c}", currentAmount);  
        }

        public static string CreateSubContract(Word.Application app, string SL)
        {
            try
            {
                Initilizate();
                setServiceDelegation();
                contracts = svc.getContract(SL).ToList();
                locations = svc.getLocations().OrderBy(r => r.Sequence).ToList();


                if (contracts != null)
                {
                    contract = contracts.FirstOrDefault();
                    if (contract == null)
                    {
                        MessageBox.Show("No subcontract record found with this number. Please entere a valid SL#.");
                        return "Failed";
                    }
                    if (contract.DocType == "MSO")
                    {
                        templateName = templatePath + "McK Subcontract Order - Final.dotx";

                    }
                    else
                        templateName = templatePath + "McK Subcontract- Final.dotx";

                    docCurrent = app.Documents.Add(ref templateName);
                    
                    //Update Book Marks on the document.
                    updateBookMarkFields(contract);
                    //Insert all selected exhibits.
                    loadExhibits(contract);
                    //Load State Exhibit
                    loadStateExhibits(0,"");
                    //Delete Bookmarks
                    removeBookMarks();
                    DeleteBlankPage(app);
                }
                else
                    MessageBox.Show("No subcontract record found with this number. Please entere a valid SL#.");

                return "Success";
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                Dispose();
            }

        }
        public static string CreateSampleSubContract(Word.Application app, string VendorNum,string Company, string VendorGroup, int Sequence)
        {
            try
            {
                Initilizate();
                setServiceDelegation();
                mastercontracts = svc.getMasterContract(VendorNum,Company,VendorGroup).ToList();
                locations = svc.getLocations().OrderBy(r => r.Sequence).ToList();

                //TODO : add multiple state Exhibits ...

                if (mastercontracts != null)
                {
                    mastercontract = mastercontracts.Where(m => m.Seq == Sequence && m.Sample == "S").FirstOrDefault();
                    if (mastercontract == null)
                    {
                        MessageBox.Show("No records found with this vendor# & Seq#. Please entere a valid numbers");
                        return "Failed";
                    }
                    templateName = templatePath + "McK Sample Subcontract- Final.dotx";
                    docCurrent = app.Documents.Add(ref templateName);

                    //Update Book Marks on the document.
                    updateBookMarkFields(mastercontract);
                    //Insert all selected exhibits.
                    loadExhibits(mastercontract);
                    //Load State Exhibit
                    loadStateExhibits(Sequence,"S");
                    //Delete Bookmarks
                    removeBookMarks();
                    //AddWatermark(app, "Sample");
                    DeleteBlankPage(app);
                }
                else
                    MessageBox.Show("No records found with this vendor# & Seq#. Please entere a valid numbers");

                return "Success";
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                Dispose();
            }

        }

        public static string CreateMasterContract(Word.Application app, string VendorNum, string Company, string VendorGroup,int Sequence)
        {
            templateName = templatePath + "McK Master Subcontract- Final.dotx";
            try
            {
                Initilizate();
                setServiceDelegation();
                mastercontracts = svc.getMasterContract(VendorNum, Company, VendorGroup).ToList();
                locations = svc.getLocations().OrderBy(r => r.Sequence).ToList();

                if (mastercontracts != null)
                {
                    mastercontract = mastercontracts.Where(m => m.Seq == Sequence && m.Sample == "M").FirstOrDefault();
                    if (mastercontract == null)
                    {
                        MessageBox.Show("No records found with this vendor# & Seq#. Please entere a valid numbers");
                        return "Failed";
                    }

                    docCurrent = app.Documents.Add(ref templateName);
                    //Update Book Marks on the document.
                    updateBookMarkFields(mastercontract);
                    //Insert all selected exhibits.
                    loadExhibits(mastercontract);
                    //Load State Exhibit
                    loadStateExhibits(Sequence,"M");
                    //Delete Bookmarks
                    removeBookMarks();
                    DeleteBlankPage(app);
                }
                else
                    MessageBox.Show("No records found with this vendor#. Please entere a valid#");


                return "Success";
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                Dispose();
            }

        }

        private static void SaveAsPDF()
        {
            object format = Word.WdSaveFormat.wdFormatPDF;
            contractFileName = "SL_" + contract.SLCo.ToString("D") + "_" + contract.SL + ".pdf";
            contractFileName = "c:\\" + contractFileName;   //TODO: File path ???
            docCurrent.SaveAs(ref contractFileName, ref format);

            //docCurrent.Close(Word.WdSaveOptions.wdDoNotSaveChanges);
            //docCurrent = null;
            MessageBox.Show("Contract has been saved successfully at " + contractFileName);
        }

    
        private static void loadExhibits(object obj)
        {
            Type type = obj.GetType();
            string fileName = "";
            PropertyInfo[] properties = type.GetProperties();
            exchibitfilePath = locations.FirstOrDefault(l => l.Path == "PMExhibits").FilePath;

            foreach (VP.DocLocation loc in locations)
            {
               try
               {
                   PropertyInfo p = properties.First(pi => pi.Name == loc.Description);
                   fileName = "";
                   //Import Exhibits for each ud Property..
                   if (p.Name.StartsWith("ud") && p.GetValue(obj, null) != null)
                   {

                       switch (p.GetValue(obj, null).ToString())
                       {
                           case "Y":
                               fileName = loc.Filename;
                               break;
                           case "CON":
                               fileName = loc.Filename.Replace("VALUE", "Construction");
                               break;
                           case "SVC":
                               fileName = loc.Filename.Replace("VALUE", "Services");
                               break;
                           case "1":
                               fileName = loc.Filename.Replace("VALUE", "High");
                               break;
                           case "2":
                               fileName = loc.Filename.Replace("VALUE", "Med");
                               break;
                           case "3":
                               fileName = loc.Filename.Replace("VALUE", "Low");
                               break;

                       }

                       if (fileName != "")
                       {
                           //exhibitfileName = locations.FirstOrDefault(l => l.Path == "PMExhibits" && l.Description == p.Name).Filename;
                           if (fileName.Contains(".docx"))
                           {
                               InsertExhibit(exchibitfilePath + @"\" + fileName);
                           }
                       }
                   }

               }
               catch (Exception e2)
               { continue; }
            }
        }

        private static void loadStateExhibits(int Seq,string Type)
        {
            if (contracts != null)
            {
                foreach (VP.Subcontract s in contracts)
                {
                    if (s.StateExhibit != "0")
                    {
                        InsertExhibit(exchibitfilePath + @"\State Exhibits\" + s.StateExhibit.ToString() + ".docx");
                    }
                }
            }

            if (mastercontracts != null)
            {
                foreach (VP.MasterContract m in mastercontracts.Where(m => m.Seq == Seq && m.Sample == Type).ToList())
                {
                    if (m.StateExhibit != "0")
                    {
                        InsertExhibit(exchibitfilePath + @"\State Exhibits\" + m.StateExhibit.ToString() + ".docx");
                    }
                }
            }

        }
        private static void removeBookMarks()
        {
            foreach (Word.Bookmark b in docCurrent.Bookmarks)
            {
                b.Delete();
            }
        }

        private static void InsertExhibit(string fileName)
        {
            object range = docCurrent.Bookmarks.get_Item(ref oEndOfDoc).Range;
            Word.Paragraph p = docCurrent.Content.Paragraphs.Add(ref range);
            //p.Range.InsertBreak(Word.WdBreakType.wdPageBreak);
            Word.Style style = p.Range.get_Style();
            p.Range.ImportFragment(fileName, false);
            p.Range.InsertBreak(Word.WdBreakType.wdPageBreak);
            style.Font.Name = "Times New Roman";
            style.Font.Size = 9;
            p.Range.set_Style(style);
            //DeleteBlankPage(docCurrent.Application);

        }

        private static String RemoveTag(String html, String startTag, String endTag)
        {

            Boolean bAgain;
            do
            {
                bAgain = false;
                Int32 startTagPos = html.IndexOf(startTag, 0, StringComparison.CurrentCultureIgnoreCase);
                if (startTagPos < 0)
                    continue;
                Int32 endTagPos = html.IndexOf(endTag, startTagPos + 1, StringComparison.CurrentCultureIgnoreCase);
                if (endTagPos <= startTagPos)
                    continue;
                html = html.Remove(startTagPos, endTagPos - startTagPos + endTag.Length);
                bAgain = true;
            } while (bAgain);
            return html;
        }

        private static void updateBookMarkFields(object obj)
        {
            Type type = obj.GetType();
            PropertyInfo[] properties = type.GetProperties();
            foreach (PropertyInfo p in properties)
            {
                try
                {   // Update books marks those matches with the field name.
                    if (docCurrent.Bookmarks.Exists(p.Name))
                    {
                        if (p.GetValue(obj, null) != null)
                            docCurrent.Bookmarks[p.Name].Range.Text = p.GetValue(obj, null).ToString();
                        else
                            docCurrent.Bookmarks[p.Name].Range.Text = "MISSING";
                    }

                    //Update Other Bookmarks those doesnt match with the field names.
                    switch (p.Name)
                    {
                        case "OurCompany" :
                            docCurrent.Bookmarks["OurCompanySign"].Range.Text = p.GetValue(obj, null).ToString();
                            if(docCurrent.Bookmarks.Exists("OurCompanyHeader"))
                                docCurrent.Bookmarks["OurCompanyHeader"].Range.Text = p.GetValue(obj, null).ToString();
                            break;
                        case "VendorName" :
                            docCurrent.Bookmarks["VendorNameSign"].Range.Text = p.GetValue(obj, null).ToString();
                            if (docCurrent.Bookmarks.Exists("VendorNametext"))
                                docCurrent.Bookmarks["VendorNametext"].Range.Text = p.GetValue(obj, null).ToString();
                            break;
                        case "SL":
                            if(docCurrent.Bookmarks.Exists("SLHeader"))
                                docCurrent.Bookmarks["SLHeader"].Range.Text = p.GetValue(obj, null).ToString();
                            break;
                        case "SLTotalOrig":
                            if (docCurrent.Bookmarks.Exists("Amount") && p.GetValue(obj, null) !=null)
                                docCurrent.Bookmarks["Amount"].Range.Text = string.Format("{0:c}", p.GetValue(obj, null).ToString());
                            break;
                        case "udSbstntlComp":
                            if (docCurrent.Bookmarks.Exists("CompleteDate"))
                                docCurrent.Bookmarks["CompleteDate"].Range.Text = Convert.ToDateTime(p.GetValue(obj, null).ToString()).ToShortDateString();
                            break;
                    }
                }
                catch (Exception e2) { continue; }
            }
        }

        private static void setServiceDelegation()
        {

            if (svc.ClientCredentials.Windows.AllowedImpersonationLevel != System.Security.Principal.TokenImpersonationLevel.Delegation)
                svc.ClientCredentials.Windows.AllowedImpersonationLevel = System.Security.Principal.TokenImpersonationLevel.Delegation;
           
        }

        public static void Dispose()
        {
            if (contracts != null) contracts = null;
            if (mastercontracts != null) mastercontracts = null;
            if (svc != null) svc = null;
            if (docCurrent != null) docCurrent = null;
        }

        private static void DeleteBlankPage(Word.Application app)
        {
            Word.Range range = docCurrent.Bookmarks.get_Item(ref oEndOfDoc).Range;
            if (range.Text == string.Empty || range.Paragraphs != null)
            {
                range.Paragraphs[1].Range.Select();
                app.Selection.Delete();
            }

        }


        private static void AddWatermark(Word.Application app, string WatermarkText)
        {


            Word.Selection Selection;
            Word.Shape wmShape;

            foreach (Word.Section s in docCurrent.Sections)
            {
                s.Range.Select();
                Selection = app.Selection;
                app.ActiveWindow.ActivePane.View.SeekView =
                            Word.WdSeekView.wdSeekCurrentPageHeader;
                //Create the watermar shape
                wmShape = Selection.HeaderFooter.Shapes.AddTextEffect(
                            Microsoft.Office.Core.MsoPresetTextEffect.msoTextEffect1,
                            WatermarkText, "Times New Roman", 1,
                            Microsoft.Office.Core.MsoTriState.msoFalse,
                            Microsoft.Office.Core.MsoTriState.msoFalse,
                            0, 0, ref missing);
                //Set all of the attributes of the watermark
                wmShape.Select(ref missing);
                wmShape.Name = "PowerPlusWaterMarkObject1";
                wmShape.TextEffect.NormalizedHeight = Microsoft.Office.Core.MsoTriState.msoFalse;
                wmShape.Line.Visible = Microsoft.Office.Core.MsoTriState.msoFalse;
                wmShape.Fill.Visible = Microsoft.Office.Core.MsoTriState.msoTrue;
                wmShape.Fill.Solid();
                wmShape.Fill.ForeColor.RGB = (int)Word.WdColor.wdColorGray25;
                wmShape.Fill.Transparency = 0.5f;
                wmShape.Rotation = 315.0f;
                wmShape.LockAspectRatio = Microsoft.Office.Core.MsoTriState.msoTrue;
                wmShape.Height = app.InchesToPoints(2.82f);
                wmShape.Width = app.InchesToPoints(5.64f);
                wmShape.WrapFormat.AllowOverlap = -1; //true
                wmShape.WrapFormat.Side = Word.WdWrapSideType.wdWrapBoth;
                wmShape.WrapFormat.Type = Word.WdWrapType.wdWrapNone;  //3
                wmShape.RelativeHorizontalPosition =
                            Word.WdRelativeHorizontalPosition.wdRelativeHorizontalPositionMargin;
                wmShape.RelativeVerticalPosition =
                            Word.WdRelativeVerticalPosition.wdRelativeVerticalPositionMargin;
                wmShape.Left = (float)Word.WdShapePosition.wdShapeCenter;
                wmShape.Top = (float)Word.WdShapePosition.wdShapeCenter;

                //set focus back to document
                app.ActiveWindow.ActivePane.View.SeekView =
                            Word.WdSeekView.wdSeekMainDocument;
            }
        }
    }
}
