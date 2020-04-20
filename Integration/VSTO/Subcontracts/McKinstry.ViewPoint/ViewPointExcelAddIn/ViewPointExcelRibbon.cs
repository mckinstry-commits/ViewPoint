using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.Office.Tools.Ribbon;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;
using Microsoft.Office.Tools.Excel;

using VP = ViewPointExcelAddIn.VPService;
//using VP = ViewPointExcelAddIn.Dev;
namespace McKinstry.ViewPoint.ExcelAddIn
{
    public partial class ViewPointExcelRibbon
    {
        private object CraftInfoCell1 = "A2:L1000";
        private object ShiftRateCell1 = "M2:BF1000";
        private object EarningsCell1 = "BG2:BY1000";
        private object DeductionsCell1 = "BZ2:IZ1000";
        private object ContractBeginDateCell1 = "JA2";
        private object ContractEndDateCell1 = "JB2";
        private List<VP.ShiftRate> ShiftRates = null;
        private VP.UnionClassServiceClient svc = null;
        private Excel._Worksheet sheet = null;
        private Excel.Worksheet logsheet = null;
        private Excel.Range logrange = null;
        private int lastRow = 2;
        private List<VP.MasterCraft> craftvalues = null;
        private List<VP.CraftInfo> CraftInfos = null;
        private List<VP.Earning> Earnings = null;
        private List<VP.Deduction> Deductions = null;
        private List<VP.MasterEarning> masterearnings = null;
        private List<VP.MasterDeduction> masterdeductions = null;


        private void ViewPointExcelRibbon_Load(object sender, RibbonUIEventArgs e)
        {
           
        }

        private void Initlization()
        {
            if (svc == null)
            {
                sheet = Globals.ThisAddIn.Application.ActiveSheet;
                ShiftRates = new List<VP.ShiftRate>();
                CraftInfos = new List<VP.CraftInfo>();
                Earnings = new List<VP.Earning>();
                Deductions = new List<VP.Deduction>();
                svc = new VP.UnionClassServiceClient();
                if (svc.ClientCredentials.Windows.AllowedImpersonationLevel != System.Security.Principal.TokenImpersonationLevel.Delegation)
                    svc.ClientCredentials.Windows.AllowedImpersonationLevel = System.Security.Principal.TokenImpersonationLevel.Delegation;
                
            }
        }

        private void bSyncRates_Click(object sender, RibbonControlEventArgs e)
        {
            Initlization();
            try
            {
                // Validate master Info i.e Company, CraftMaster, ClassCode, Description, EEOClass and ShopFlag
                //ValidateCraftInfo()
                ProcessCraftsInfo();
                ProcessShiftRates();
                ////MessageBox.Show("Successfully added/updated shiftrates"); 
                ProcessEarnings();
                MessageBox.Show("Successfully added/updated shiftrates");
                ProcessDeductions();
                MessageBox.Show("Successfully added/updated deductions"); 
            }
            catch (Exception ex)
            {
                ExceptionLog(ex.Message + " \n " + ex.InnerException , "OnClick");
            }
            finally
            {
                ShiftRates.Clear();
                Earnings.Clear();
                Deductions.Clear();
                CraftInfos.Clear();
            }
        }

        private void ValidateCraftsInfo()
        {

        }

        private void ProcessCraftsInfo()
        {
            Excel.Range CraftInfoRange = sheet.get_Range(CraftInfoCell1, Type.Missing);

            try
            {
                foreach (Excel.Range r in CraftInfoRange.Offset[2, 0].Rows)
                {

                    if (r.Cells[1, 1].Text == "" && r.Cells[1, 2].Text == "" && r.Cells[1, 9].Text == "" && r.Cells[1, 10].Text == "" && r.Cells[1, 11].Text == "")
                        break;

                    if (r.Cells[1, 1].Text == "" || r.Cells[1, 2].Text == "" || r.Cells[1, 9].Text == "" || r.Cells[1, 10].Text == "" || r.Cells[1, 11].Text == "")
                    {
                        MessageBox.Show("Blank value at row# " + r.Row + ". Please make sure no blank values for Company or CraftMaster or ClassCode or Description or EEOClass or ShopFlag.");
                        r.EntireRow.Select();
                        throw new Exception("Blank value at row# " + r.Row + ". Please make sure no blank values for Company or CraftMaster or ClassCode or Description or EEOClass or ShopFlag.");
                    }
                    VP.CraftInfo CI = new VP.CraftInfo();
                    try
                    {
                        if (!IsCraftExists(r.Cells[1, 2].Text, Convert.ToByte(r.Cells[1, 1].Text)))
                        {
                            throw new Exception("Craft value :" + r.Cells[1, 2].Text + " doesn't exists");
                        }
                        CI.PRCo = Convert.ToByte(r.Cells[1, 1].Text);
                        CI.Craft = r.Cells[1, 2].Text;
                        CI.Notes = r.Cells[1, 4].Text;
                        CI.Class = r.Cells[1, 9].Text;
                        CI.Description = r.Cells[1, 10].Text;
                        CI.EEOClass = r.Cells[1, 11].Text;
                        CI.WghtAvgOT = "N";
                        CI.OldCapLimit = 0;
                        CI.NewCapLimit = 0;
                        CI.udShopYN = r.Cells[1, 12].Text;

                        CraftInfos.Add(CI);
                    }
                    catch (Exception ex)
                    {
                        ExceptionLog("Error While Processing Craft/Class : " + CI.Craft + " / " + CI.Class + " System Error: \n" + ex.Message +"\n Inner Exception:" +ex.InnerException  , "Crafts info processing");
                        return;
                    }
                }
                svc.AddUpdateCraftClass(CraftInfos);
            }

            catch (Exception ex2)
            {
                ExceptionLog("Error While Processing Craft/Class :  System Error: " + ex2.Message + "\n Inner Exception:" + ex2.InnerException, "Crafts info processing");
                return;
            }
            finally
            {
                CraftInfos.Clear();
            }

            
        }

        private void ProcessShiftRates()
        {
            Excel.Range shiftRange = sheet.get_Range(ShiftRateCell1, Type.Missing);

            try
            {
                foreach (Excel.Range r in shiftRange.Offset[2, 0].Rows)
                {
                    if (r.Offset[0, -12].Cells[1, 1].Text == "") break;
                    VP.ShiftRate SR = null;
                    try
                    {
                        for (int i = 1; i <= r.Columns.Count; i += 2)
                        {
                            SR = new VP.ShiftRate();
                            SR.PRCo = Convert.ToByte(r.Offset[0, -12].Cells[1, 1].Text);
                            SR.Craft = r.Offset[0, -(11)].Cells[1, 1].Text;
                            SR.Class = r.Offset[0, -(4)].Cells[1, 1].Text;

                            if (r.Cells[1, i].Text != "")   // Shift #
                                // SR.Shift = Convert.ToByte(i);
                                SR.Shift = Convert.ToByte(r.Cells[1, i].Text);
                            if (r.Cells[1, i + 1].Text != "") // New Rate
                                SR.NewRate = Convert.ToDecimal(r.Cells[1, i + 1].Text);
                            if (r.Cells[1, 251].Text == "Y")  //If the row is just for correction.
                                SR.KeyID = 1;

                            if (SR.Shift != 0)
                                ShiftRates.Add(SR);
                        }
                    }
                    catch (Exception ex)
                    {
                        ExceptionLog("Error While Processing Craft/Class : " + SR.Craft + " / " + SR.Class + " System Error: " + ex.Message + "\n Inner Exception:" + ex.InnerException, "Crafts info processing");
                        return;
                    }
                }

                svc.AddUpdateShiftRate(ShiftRates);
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                ShiftRates.Clear();
            }

        }

        private void ProcessEarnings()
        {
            Excel.Range EarningRange = sheet.get_Range(EarningsCell1, Type.Missing);

            try
            {

                foreach (Excel.Range r in EarningRange.Offset[2, 0].Rows)
                {

                    for (int i = 1; i <= r.Columns.Count; i += 2)
                    {
                        VP.Earning ER = new VP.Earning();
                        if (r.Offset[0, -(58)].Cells[1, 1].Text == "") break;
                        ER.PRCo = Convert.ToByte(r.Offset[0, -58].Cells[1, 1].Text);
                        ER.Craft = r.Offset[0, -(57)].Cells[1, 1].Text;
                        ER.Class = r.Offset[0, -(50)].Cells[1, 1].Text;

                        if (r.Cells[1, 205].Text == "Y")  //If the row is just for correction.
                            ER.KeyID = 1;

                        if (r.Cells[1, i].Text != "")   // Earning code #
                            ER.EarnCode = Convert.ToInt16(r.Cells[1, i].Text);
                        else
                            continue;

                        if (!isEarningCodeExists(ER.PRCo, ER.EarnCode))
                        {
                            ExceptionLog("EarnCode: " + ER.EarnCode.ToString() + " doesn't exists. \nCraft :" + ER.Craft + " Class : " + ER.Class, "Earning codes");
                            Earnings.Clear();
                            return;
                        }


                        // Check if earncode method is "V" 
                        if (isEarningMethodV(ER.PRCo, ER.EarnCode))
                        {
                            if (r.Offset[-(r.Row - 2), i].Cells[1, 0].Text == "AddOnCode7")
                            {
                                // 3 factors for 3 values for each factor.
                                for (int j = 1; j <= 6; j += 2)
                                {
                                    VP.Earning VER = new VP.Earning();
                                    VER.Craft = ER.Craft;
                                    VER.Class = ER.Class;
                                    VER.PRCo = ER.PRCo;
                                    VER.EarnCode = ER.EarnCode;
                                    VER.Factor = Convert.ToDecimal(r.Cells[1, i + j].Text);
                                    if (VER.Factor < 0)
                                    {
                                        ExceptionLog("EarnCode: " + ER.EarnCode.ToString() + " has method V but the factor is less than zero. \nCraft :" + ER.Craft + " Class : " + ER.Class, "Earning codes");
                                        Earnings.Clear();
                                        return;
                                    }
                                    VER.NewRate = Convert.ToDecimal(r.Cells[1, i + j + 1].Text);
                                    Earnings.Add(VER);
                                }

                                i = i + 5; //Move into next earning codes if any exists.


                            }
                            else
                            {
                                ExceptionLog("EarnCode: " + ER.EarnCode.ToString() + " has method V but there is no factor defined in the spreadsheet. Craft :" + ER.Craft + " Class : " + ER.Class, "Earning codes");
                                Earnings.Clear();
                                return;
                            }
                        }
                        else
                        {

                            if (r.Cells[1, i + 1].Text != "") // New Rate
                                ER.NewRate = Convert.ToDecimal(r.Cells[1, i + 1].Text);

                            bool check = Earnings.Exists(e => e.PRCo == ER.PRCo && e.Class == ER.Class && e.EarnCode == ER.EarnCode);
                            if (check)
                            {
                                ExceptionLog("EarnCode: " + ER.EarnCode.ToString() + " for Craft : " + ER.Craft + " Class : " + ER.Class + " already exists.", "Earning codes");
                                Earnings.Clear();
                                return;
                            }
                            Earnings.Add(ER);
                        }
                    }
                }
                svc.AddUpdateEarnings(Earnings);
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
            finally
            {
                Earnings.Clear();
            }
        }

        private void ProcessDeductions()
        {
            Excel.Range DeductionRange = sheet.get_Range(DeductionsCell1, Type.Missing);

            try
            {
                foreach (Excel.Range r in DeductionRange.Offset[2, 0].Rows)
                {

                    for (int i = 1; i <= r.Columns.Count; i += 2)
                    {
                        VP.Deduction DD = new VP.Deduction();
                        if (r.Offset[0, -(77)].Cells[1, 1].Text == "") break;
                        DD.PRCo = Convert.ToByte(r.Offset[0, -77].Cells[1, 1].Text);
                        DD.Craft = r.Offset[0, -(76)].Cells[1, 1].Text;
                        DD.Class = r.Offset[0, -(69)].Cells[1, 1].Text;
                        if (r.Cells[1, 186].Text == "Y")  //If the row is just for correction.
                            DD.KeyID = 1;
                        //if dlcode and amount is null or blank then skip.
                        if (r.Cells[1, i].Text == "")
                        {
                            if (r.Offset[-(r.Row - 2), i].Cells[1, 0].Text == "DLCode26")
                                i = i + 5;

                            continue;
                        }

                        if (r.Cells[1, i].Text != "")   // deduction code #
                            DD.DLCode = Convert.ToInt16(r.Cells[1, i].Text);
                        //else
                        //{
                        //    ExceptionLog("DLCode: " + DD.DLCode.ToString() + " has method V but there is no factor defined in the spreadsheet. Craft :" + DD.Craft + " Class : " + DD.Class, "Deduction codes");
                        //    Deductions.Clear();
                        //    return;
                        //}

                        //if (!isDLExists(DD.PRCo, DD.DLCode))
                        //{
                        //    ExceptionLog("DLCode: " + DD.DLCode.ToString() + " doesn't exists. \nCraft :" + DD.Craft + " Class : " + DD.Class, "DL codes");
                        //    Earnings.Clear();
                        //    return;
                        //}

                        if (isDLMethodV(DD.PRCo, DD.DLCode))    //Process DLcode with method 'V'
                        {
                            if (r.Offset[-(r.Row - 2), i].Cells[1, 0].Text == "DLCode26")
                            {
                                // 3 factors for 3 values for each factor.
                                for (int j = 1; j <= 6; j += 2)
                                {
                                    VP.Deduction VDD = new VP.Deduction();
                                    VDD.Craft = DD.Craft;
                                    VDD.Class = DD.Class;
                                    VDD.PRCo = DD.PRCo;
                                    VDD.DLCode = DD.DLCode;
                                    VDD.Factor = Convert.ToDecimal(r.Cells[1, i + j].Text);
                                    if (VDD.Factor < 0)
                                    {
                                        ExceptionLog("DLCode: " + DD.DLCode.ToString() + " has method V but the factor is less than zero. \nCraft :" + DD.Craft + " Class : " + DD.Class, "Deduction codes");
                                        Deductions.Clear();
                                        return;
                                    }
                                    VDD.NewRate = Convert.ToDecimal(r.Cells[1, i + j + 1].Text);
                                    Deductions.Add(VDD);
                                }
                                i = i + 5; //Move into next earning codes if any exists.
                            }
                            else
                            {
                                ExceptionLog("DLCode: " + DD.DLCode.ToString() + " has method V but there is no factor defined in the spreadsheet. Craft :" + DD.Craft + " Class : " + DD.Class, "Deduction codes");
                                Deductions.Clear();
                                return;
                            }
                        }
                        else
                        {

                            if (r.Cells[1, i + 1].Text != "") // New Rate
                                DD.NewRate = Convert.ToDecimal(r.Cells[1, i + 1].Text);

                            bool check = Deductions.Exists(e => e.PRCo == DD.PRCo && e.Class == DD.Class && e.DLCode == DD.DLCode);
                            if (check)
                            {
                                ExceptionLog("DLCode: " + DD.DLCode.ToString() + " for Craft : " + DD.Craft + " Class : " + DD.Class + " already exists.", "Deduction codes");
                                Deductions.Clear();
                                return;
                            }
                            Deductions.Add(DD);
                        }

                    }
                }

                svc.AddUpdateDeductions(Deductions);
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message + "  Source: " + " Deductions");
            }
            finally
            {
                Deductions.Clear();
            }
        }

        private bool IsCraftExists(string craft,byte PRCo)
        {
            if (craftvalues == null)
            {
                craftvalues = new List<VP.MasterCraft>();
                craftvalues = svc.GetMasterCrafts();
            }

            var craftvalue = craftvalues.Where(cv => cv.PRCo == PRCo && cv.Craft == craft).FirstOrDefault();
            if (craftvalue != null)
                return true;
            else
                return false;
        }

        private bool isEarningMethodV(byte PRCo, int earnCode)
        {
            if (masterearnings == null)
            {
                masterearnings = new List<VP.MasterEarning>();
                masterearnings = svc.GetMasterEarnings();
            }
            var obj = masterearnings.Where(me => me.PRCo == PRCo && me.EarnCode == earnCode && me.Method == "V").FirstOrDefault();

            if (obj != null)
                return true;
            else
                return false;
        }

        private bool isEarningCodeExists(byte PRCo, int earnCode)
        {
            if (masterearnings == null)
            {
                masterearnings = new List<VP.MasterEarning>();
                masterearnings = svc.GetMasterEarnings();
            }
            var obj = masterearnings.Where(me => me.PRCo == PRCo && me.EarnCode == earnCode).FirstOrDefault();

            if (obj != null)
                return true;
            else
                return false;
        }

        private bool isDLMethodV(byte PRCo, int DLCode)
        {
            if (masterdeductions == null)
            {
                masterdeductions = new List<VP.MasterDeduction>();
                masterdeductions = svc.GetMasterDeductions();
            }
            var obj = masterdeductions.Where(md => md.PRCo == PRCo && md.DLCode == DLCode && md.Method == "V").FirstOrDefault();

            if (obj != null)
                return true;
            else
                return false;
        }

        private bool isDLExists(byte PRCo, int DLCode)
        {
            if (masterdeductions == null)
            {
                masterdeductions = new List<VP.MasterDeduction>();
                masterdeductions = svc.GetMasterDeductions();
            }
            var obj = masterdeductions.Where(md => md.PRCo == PRCo && md.DLCode == DLCode).FirstOrDefault();

            if (obj != null)
                return true;
            else
                return false;
        }

        private void ExceptionLog(string msg, string source)
        {
            if (logsheet == null)
            {
               
                    logsheet = Globals.ThisAddIn.Application.Worksheets.Add(Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    logsheet.Name = "ExceptionLog";
                    logrange = logsheet.get_Range("A1:D1", Type.Missing);
                    logrange.Cells[1, 1].Value2 = "Error Message";
                    logrange.Cells[1, 2].Value2 = "Source";
                
            }
            if (logrange != null)
            {
                logrange.Cells[lastRow, 1].Value2 = msg;
                logrange.Cells[lastRow, 2].Value2 = source;
            }
            lastRow++;
            
        }


    }
}
