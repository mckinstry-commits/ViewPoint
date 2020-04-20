using System;
using System.Collections.Generic;
using Excel = Microsoft.Office.Interop.Excel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using McK.Data.Viewpoint;

namespace McK.SMQuotes.Viewpoint
{
    internal static class SMQuotes
    {
        // in-Memory for quick lookup ONLY because there's 9 records (as of 11.30.18 ) LG
        //internal static List<dynamic> tblMcKContacts = null;

        public static bool ToExcel(List<dynamic> tblQuotes)
        {
            Excel.Worksheet ws = null;
            Excel.Range rng = null;
            Excel.Range rngMerged = null;
            Excel.Range rngUnmerged = null;
            bool success = false;
            string quoteID = "";

            try
            {
                Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                var uniqueQuotes = tblQuotes.GroupBy(r => r.QuoteID).Distinct();

                foreach (var _quote in uniqueQuotes)
                {
                    dynamic quoteDyn = _quote.First();
                    IDictionary<string, object> quote = (IDictionary<string, object>)quoteDyn;
                    //KeyValuePair<string,object> quote = (IDictionary<string, object>)q;
                    
                    quoteID = quoteDyn.QuoteID.Value.GetType() == typeof(DBNull) ? string.Empty : ((string)quoteDyn.QuoteID.Value).Replace(" ", "");

                    ws = HelperUI.GetSheet(quoteID);

                    HelperUI.AlertOff();
                    if (HelperUI.GetSheet(quoteID) != null)
                    {
                        ws.Delete();
                    }
                    HelperUI.AlertON();

                    // create sheet from template
                    switch (Globals.ThisWorkbook._myActionPane.QuoteFormat)
                    {
                        case "Standard":
                            Globals.QuoteStandard.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.QuoteStandard.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                            break;
                        case "Detailed":
                            Globals.QuoteDetail.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.QuoteDetail.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                            break;
                        case "Detailed with Equip":
                            Globals.QuoteDetail.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.QuoteDetail.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                            break;
                        default:
                            Globals.QuoteStandard.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.QuoteStandard.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                            break;
                    }

                    ws = Globals.ThisWorkbook.Worksheets.get_Item(((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Index);
                    ws.Name = quoteID;

                    #region GET FIELD VALUES

                    var enteredDate = ((KeyValuePair<string, object>)quote["Entered Date"]).Value;
                        enteredDate = enteredDate.GetType() == typeof(DBNull) ? string.Empty : enteredDate.ToString().Substring(0, enteredDate.ToString().IndexOf(" "));  // remove time stamp

                    var smco = quoteDyn.SMCo.Value.GetType() == typeof(DBNull) ? null : quoteDyn.SMCo.Value;

                    //var customerNumber = quoteDyn.Customer.Value.GetType() == typeof(DBNull) ? null : quoteDyn.Customer.Value;

                    var customerName = ((KeyValuePair<string, object>)quote["Customer Name"]).Value;
                        customerName = customerName.GetType() == typeof(DBNull) ? string.Empty : customerName;

                    var customerContactName = ((KeyValuePair<string, object>)quote["Customer Contact Name"]).Value;
                        customerContactName = customerContactName.GetType() == typeof(DBNull) ? string.Empty : customerContactName;

                    var customerContactPhone = ((KeyValuePair<string, object>)quote["Customer Contact Phone"]).Value;
                        customerContactPhone = customerContactPhone.GetType() == typeof(DBNull) ? string.Empty : customerContactPhone;

                    var customerContactEmail = ((KeyValuePair<string, object>)quote["Customer Contact Email"]).Value;
                        customerContactEmail = customerContactEmail.GetType() == typeof(DBNull) ? string.Empty : customerContactEmail;

                    var serviceSiteDescription = ((KeyValuePair<string, object>)quote["Service Site Description"]).Value;
                        serviceSiteDescription= serviceSiteDescription.GetType() == typeof(DBNull) ? string.Empty : serviceSiteDescription;

                    var serviceSite = ((KeyValuePair<string, object>)quote["Service Site"]).Value;
                        serviceSite = serviceSite.GetType() == typeof(DBNull) ? string.Empty : serviceSite;

                    var customerPO = ((KeyValuePair<string, object>)quote["Customer PO"]).Value;
                        customerPO = customerPO.GetType() == typeof(DBNull) ? string.Empty : customerPO;

                    var serviceSiteAddress1 = ((KeyValuePair<string, object>)quote["Service Site Address1"]).Value;
                        serviceSiteAddress1 = serviceSiteAddress1.GetType() == typeof(DBNull) ? string.Empty : serviceSiteAddress1;

                    var serviceSiteAddress2 = ((KeyValuePair<string, object>)quote["Service Site Address2"]).Value;
                        serviceSiteAddress2 = serviceSiteAddress2.GetType() == typeof(DBNull) ? string.Empty : serviceSiteAddress2;

                    var serviceSiteCity = ((KeyValuePair<string, object>)quote["Service Site City"]).Value;
                        serviceSiteCity = serviceSiteCity.GetType() == typeof(DBNull) ? string.Empty : serviceSiteCity;

                    var serviceSiteState = ((KeyValuePair<string, object>)quote["Service Site State"]).Value;
                        serviceSiteState = serviceSiteState.GetType() == typeof(DBNull) ? string.Empty : serviceSiteState;

                    var serviceSiteZip = ((KeyValuePair<string, object>)quote["Service Site Zip"]).Value;
                        serviceSiteZip = serviceSiteZip.GetType() == typeof(DBNull) ? string.Empty : serviceSiteZip;

                    var scopeOfWork = ((KeyValuePair<string, object>)quote["Scope Of Work"]).Value;
                        scopeOfWork = scopeOfWork.GetType() == typeof(DBNull) ? string.Empty : scopeOfWork;

                    var udExpirationDate = ((KeyValuePair<string, object>)quote["Expiration Date"]).Value;
                        udExpirationDate = udExpirationDate.GetType() == typeof(DBNull) ? string.Empty : udExpirationDate.ToString().Substring(0, udExpirationDate.ToString().IndexOf(" "));  // remove time stamp

                    var priceMethod = ((KeyValuePair<string, object>)quote["Price Method"]).Value;
                        priceMethod = priceMethod.GetType() == typeof(DBNull) ? string.Empty : priceMethod;

                    //var price = quoteDyn.Price.Value.GetType() == typeof(DBNull) ? string.Empty : quoteDyn.Price.Value;

                    var enteredBy = quoteDyn.EnteredBy.Value.GetType() == typeof(DBNull) ? string.Empty : quoteDyn.EnteredBy.Value;
                    #endregion

                    ws.Names.Item("QuoteID").RefersToRange.Value = quoteID;
                    ws.Names.Item("EnteredDate").RefersToRange.Value = enteredDate;
                    ws.Names.Item("Customer").RefersToRange.Value = customerName;
                    ws.Names.Item("CustomerContactName").RefersToRange.Value = customerContactName;
                    ws.Names.Item("CustomerContactPhone").RefersToRange.Value = customerContactPhone;
                    ws.Names.Item("CustomerContactEmail").RefersToRange.Value = customerContactEmail;
                    ws.Names.Item("ServiceSiteDescription").RefersToRange.Value = serviceSiteDescription;
                    ws.Names.Item("ServiceSite").RefersToRange.Value = serviceSite;
                    ws.Names.Item("CustomerPO").RefersToRange.Value = customerPO;
                    ws.Names.Item("ServiceSiteAddress1").RefersToRange.Value = serviceSiteAddress1;

                    // bring up 1 row city , wa and zip when no address 2
                    if (serviceSiteAddress2.ToString() != "")
                    {
                        ws.Names.Item("ServiceSiteAddress2").RefersToRange.Value = serviceSiteAddress2;
                        ws.Names.Item("ServiceSiteCityStateZip").RefersToRange.Value = serviceSiteCity + ", " + serviceSiteState + ", " + serviceSiteZip;
                    }
                    else
                    {
                        ws.Names.Item("ServiceSiteAddress2").RefersToRange.Value = serviceSiteCity + ", " + serviceSiteState + ", " + serviceSiteZip;
                    }

                    ws.Names.Item("ScopeOfWork").RefersToRange.Value = scopeOfWork;
                    ws.Names.Item("udExpirationDate").RefersToRange.Value = udExpirationDate;

                    if ((string)priceMethod == "Time & Material")
                    {
                        ws.Names.Item("PriceMethod").RefersToRange.Value = priceMethod;
                    }

                    // OLD WAY VIA UD TABLE 
                    //dynamic mckContact = tblMcKContacts.Where(n => n.Alias.Value.GetType() == typeof(string) ? n.Alias.Value.ToLower() == enteredBy.ToLower() : null).FirstOrDefault();
                    //if (mckContact != null)
                    //{
                    //    ws.Names.Item("EnteredBy").RefersToRange.Value = mckContact.FullName.Value;
                    //    ws.Names.Item("Email").RefersToRange.Value = mckContact.Email.Value;
                    //    ws.Names.Item("PhoneNumber").RefersToRange.Value = mckContact.Phone.Value;
                    //}
                    //else
                    //{
                    //    ws.Names.Item("EnteredBy").RefersToRange.Value = enteredBy;
                    //}

                    /* Task 3815: Automate population of Mck Contact Full Name, Phone # & Email via Active Directory */

                    try
                    {
                        dynamic mckContact = AD.GetUserInfo(enteredBy);

                        if (mckContact != null)
                        {
                            ws.Names.Item("EnteredBy").RefersToRange.Value = mckContact.Properties.Contains("DisplayName") ? mckContact.Properties["DisplayName"][0].ToString() : "";
                            ws.Names.Item("Email").RefersToRange.Value = mckContact.Properties.Contains("Mail") ? mckContact.Properties["Mail"][0].ToString() : "";
                            ws.Names.Item("PhoneNumber").RefersToRange.Value = mckContact.Properties.Contains("TelephoneNumber") ? mckContact.Properties["TelephoneNumber"][0].ToString() : "";
                        }
                        else
                        {
                            ws.Names.Item("EnteredBy").RefersToRange.Value = enteredBy;
                        }
                    }
                    catch (Exception)
                    {
                        // continue.. let it go
                    }

                    switch (Globals.ThisWorkbook._myActionPane.QuoteFormat)
                    {
                        case "Standard":

                            int cellMaxRowHeight = 409;

                            string content = scopeOfWork.ToString();

                            rngMerged = ws.Names.Item("ScopeOfWork").RefersToRange;
                            rngUnmerged = ws.get_Range("T35");

                            dynamic mergedAreaRowHeight = float.Parse(rngMerged.MergeArea.Height.ToString());

                            rngUnmerged.ColumnWidth = float.Parse(rngMerged.MergeArea.Width.ToString()) / 8; //means 8 of the default font's characters fit into a cell
                            rngUnmerged.Formula = content;
                            rngUnmerged.EntireRow.AutoFit();

                            if (rngUnmerged.RowHeight > mergedAreaRowHeight)
                            {
                                // expand merged area to fit content
                                rngMerged.RowHeight = Convert.ToDouble(rngUnmerged.RowHeight) > cellMaxRowHeight ? cellMaxRowHeight : rngUnmerged.RowHeight;
                            }

                            double numberOfMergedRangeNeeded = (mergedAreaRowHeight / cellMaxRowHeight);

                            //int mergeCntsNeeded = Convert.ToInt32(Math.Round(numberOfMergedRangeNeeded, MidpointRounding.AwayFromZero)) - 1;

                            #region AUTO-EXPAND CELLS TO FIT CONTENT

                            int from = 1;
                            int increment = 2261;
                            int step = increment;
                            dynamic mergeCntsNeeded   = content.Length / increment; 
                            int remainCharsAfterSplit = content.Length % increment;
                            int r = 13;

                            if (mergeCntsNeeded > 0)
                            {
                                rngMerged.UnMerge();
                            }
                            else
                            {
                                goto skip;
                            }
                            for (int i = 0; i <= mergeCntsNeeded; i++)
                            {
                                if (r > 30)
                                {
                                    // for when super huge summary exceeds row 30 (current template cap)
                                    ws.get_Range("B" + r).EntireRow.Insert();
                                }

                                ws.get_Range("B" + r + ":Q" + r).Merge();
                                ws.get_Range("B" + r).HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                ws.get_Range("T35").Formula = content.Substring(from, step);
                                ws.get_Range("B" + r).Formula = content.Substring(from, step);
                                ws.get_Range("B" + r).RowHeight = Convert.ToDouble(ws.get_Range("T35").RowHeight) > cellMaxRowHeight ? cellMaxRowHeight : ws.get_Range("T35").RowHeight;

                                from += step;

                                if (from == content.Length)
                                {
                                    if (ws.get_Range("B" + r).RowHeight <= 394)
                                    {
                                        ws.get_Range("B" + r).RowHeight += 15; // add 1 line cushion to last merge
                                    }
                                }

                                int remainingCharCnt = content.Substring(from, content.Length - from).Length;

                                int nextChunk = remainingCharCnt >= increment ? 
                                                   remainingCharCnt - increment  // avoid negative chunks
                                                   : remainingCharCnt;

                                step = nextChunk > increment ? increment : nextChunk;

                                r++;

                                if (step == 0) // done with all merges?
                                {
                                    ws.get_Range("B" + r + ":Q" + r).Merge(); // leave 1 bottom row for cushion 

                                    if (((ws.get_Range("B" + (r-1)).RowHeight / cellMaxRowHeight) * 100) >= 90) // if last merged text length is at least 90% of cellMaxChars (409)
                                    {
                                        ws.get_Range("B" + (r-1)).RowHeight = cellMaxRowHeight; // add 1 line cushion
                                    }

                                    if (r < 30)
                                    {
                                        // delete unused rows at bottom
                                        r++;
                                        ws.get_Range("B" + r + ":Q" + 30).EntireRow.Delete();
                                        break;
                                    }
                                }
                            }


                            #endregion

                            #region fit content based on char pixels
                            //ws.get_Range("T13").Formula = "Merged Area Height: " + mergedAreaRowHeight;
                            //ws.get_Range("T14").Formula = "Merges Need: " + (numberOfMergedRangeNeeded > 1 ? numberOfMergedRangeNeeded : 0);
                            //ws.get_Range("T15").Formula = "Chars Count Exceeds: " + Math.Round(numberOfMergedRangeNeeded * 100,2) + " %";

                            //ws.get_Range("T16").Formula = a.Length;

                            //int contentCharCount = content.Length;

                            //// convert points to pixels
                            //dynamic widthInPixels = rng.Width / .75;  // 1 pixel = 0.75 points

                            //// convert pixels to characters > characters = (Pixels - 5) / 7
                            //dynamic charsFitPerRow = (widthInPixels - 5) / 7;

                            //// how many rows are needed to fit the content ?
                            //dynamic rowsNeededToFitContent = contentCharCount / charsFitPerRow;

                            //dynamic rowHeightPts = rowsNeededToFitContent * 15;
                            //rng.RowHeight = rowHeightPts;

                            //dynamic rowHeightLimit = 27.26666666666667; // or 409 points (rowHeightLimit * 15)

                            //if (rowsNeededToFitContent <= rowHeightLimit)
                            //{
                            //    // entire content will show
                            //    rowHeightPts = rowsNeededToFitContent * 15;
                            //    rng.RowHeight = rowHeightPts;
                            //}
                            //else
                            //{
                            //    // part of content will hide
                            //}

                            //decimal rowHeight = HelperUI.GetRowHeightToFitContent(content, charCntVisibleInFirstRow: 82);
                            // MAX ROW HEIGHT IS 409
                            //int rowHeightLimit = 409; // 27 rows with 15 pt. row height (default)
                            #endregion
skip:
                            rngUnmerged.EntireColumn.Delete();

                            var totalPrice = ((KeyValuePair<string, object>)quote["Derived Pricing Est"]).Value;
                            totalPrice = totalPrice.GetType() == typeof(DBNull) ? string.Empty : totalPrice;
                            ws.Names.Item("TotalPrice").RefersToRange.Value = totalPrice;

                            break;
                        case "Detailed":

                            if ((string)priceMethod == "Flat Price")
                            {
                                var flatPrice = ((KeyValuePair<string, object>)quote["Derived Pricing Est"]).Value;
                                ws.Names.Item("TotalPrice").RefersToRange.Value = flatPrice;
                                break;
                            }

                            //var quoteScopes = tblQuotes.GroupBy(r => r.QuoteID && r.QuoteScope).Distinct();
                            //string scopes = "";
                            //foreach (var s in quoteScopes)
                            //{
                            //    scopes += (string)s.First().QuoteScope.Value + ",";
                            //}
                       
                            List<dynamic> tbldetail = QuotePreview.GetQuoteDetail(smco, quoteID);

                            if (tbldetail.Count > 0)
                            {
                                //var detail = tbldetail.FirstOrDefault();

                                int rowAt = ws.Names.Item("LineType").RefersToRange.Row - 1;
                                int typeCol = ws.Names.Item("LineType").RefersToRange.Column;
                                int descCol = ws.Names.Item("LineDescription").RefersToRange.Column;
                                int priceCol = ws.Names.Item("ExtendedPrice").RefersToRange.Column;

                                //bool flatPrice = tbldetail.Where(n => n.PriceMethod.Value == "F").Skip(0).Any();
                                var f = tbldetail.Where(n => (n.PriceMethod.Value.GetType() == typeof(DBNull) ? string.Empty : n.PriceMethod.Value) == "F");

                                dynamic flatPrice = null;

                                if (f.Skip(0).Any())
                                {
                                    flatPrice = f.First();
                                }

                                // get detail rows
                                foreach (dynamic row in tbldetail)
                                {
                                    var type = row.Type.Value.GetType() == typeof(DBNull) ? string.Empty : row.Type.Value;
                                    var desc = row.Description.Value.GetType() == typeof(DBNull) ? string.Empty : row.Description.Value;
                                    var price = row.TotalBillable.Value.GetType() == typeof(DBNull) ? 0 : row.TotalBillable.Value;
                                    //var totalAmt = row.TotalPrice.Value.GetType() == typeof(DBNull) ? 0 : row.TotalPrice.Value;
                                    //var po = row.CustomerPO.Value.GetType() == typeof(DBNull) ? 0 : row.CustomerPO.Value;

                                    //ws.Names.Item("CustomerPO").RefersToRange.Value = po;

                                    ++rowAt;

                                    if (flatPrice != null)
                                    {
                                        ws.Cells[rowAt, typeCol].Value = flatPrice.Type.Value;
                                        ws.Cells[rowAt, descCol].Value = flatPrice.Description.Value; 
                                        ws.Cells[rowAt, priceCol].Value = flatPrice.TotalBillable.Value;
                                        break;
                                    }

                                    if (rowAt <= 31)
                                    {
                                        ws.Cells[rowAt, typeCol].Value = type;
                                        ws.Cells[rowAt, descCol].Value = desc;
                                        ws.Cells[rowAt, priceCol].Value = price;
                                    }
                                    else
                                    {
                                        rng = ws.get_Range("A32").EntireRow;
                                        ws.get_Range("A" + rowAt).EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown, rng);
                                        ws.get_Range("D" + rowAt + ":N" + rowAt).Merge();
                                        ws.get_Range("O" + rowAt + ":Q" + rowAt).Merge();
                                        ws.Cells[rowAt, typeCol].Value = type;
                                        ws.Cells[rowAt, descCol].Value = desc;
                                        ws.Cells[rowAt, priceCol].Value = price;
                                    }

                                    //ws.Cells[rowAt, priceCol].Value = rate > 0 && qty > 0 ? rate : price;

                                }
                            }
                            break;
                        case "Detailed with Equip":

                            break;
                        default:

                            break;
                    }

                    if (serviceSiteDescription.ToString().Length > 29)
                    {
                        rng = ws.Names.Item("ServiceSiteDescription").RefersToRange;
                        rng.WrapText = true;
                        rng.RowHeight = 32.25;
                    }

                    // parse SMCo e.g. "1-McKinstry Co, LLC: 616 SM Project cln0509"
                    string co = Globals.ThisWorkbook._myActionPane.cboCompany.Text;
                    int start = co.IndexOf("-")+1;
                    //int end = co.IndexOf(":");
                    int end = co.Length;
                    co = co.Substring(start, end-start);
                    ws.Names.Item("SMCo").RefersToRange.Value = co;
                    ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal;
                }

                success = true;
            }
            catch (Exception)
            {
                success = false;
                throw;
            }
            finally
            {
                Globals.QuoteStandard.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.QuoteDetail.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                HelperUI.AlertON();
                HelperUI.RenderON();

                if (success)
                {
                    Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                }
                else
                {
                    ws?.get_Range("T35").EntireRow.Delete();
                }

                #region CLEAN UP
                    if (ws != null) Marshal.ReleaseComObject(ws);
                #endregion

            }
            return success;
        }
    }
}
