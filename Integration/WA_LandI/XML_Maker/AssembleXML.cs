using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml;
using System.IO;
using System.Xml.Serialization;
using System.Data.SqlClient;
using System.Data;
using System.Reflection;

namespace XML_Maker
{
    public class AssembleXML
    {
        private string FolderLocation = "c:\\LandIFiles\\";

       //private DataSet ethnicityTable;
        TSQL tsql = new TSQL();
        public AssembleXML()
        {
            // Fill 2 dimensional string array to hold the ethnicity xref values.
         //   ethnicityTable = tsql.GetEthnicities();
        }

        private string newFolder;
        private DateTime theLastSunday;
        private int numOfPayRollWeeks = 0;
        private DateTime startingSunday, endingSunday;
        private DataSet dsOtherDeductions = new DataSet();
        private DataSet dsTradeBenefits = new DataSet();

        // array of otherdeductions
        private WaPWCPRPayrollWeekEmployeeOtherDeduction[] others;
        private WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit[] tradeBenefits;

        public bool AssembleXMLFiles(string intentID, string stDT, string endDT)
        {
            try
            {
                startingSunday = Convert.ToDateTime(stDT);
                endingSunday = Convert.ToDateTime(endDT);
                // calculate the number of payroll weeks during the dates picked.
                TimeSpan tt = endingSunday - startingSunday;
                numOfPayRollWeeks = (tt.Days / 7) + 1;
                WaPWCPRPayrollWeek[] weeks;
                weeks = new WaPWCPRPayrollWeek[numOfPayRollWeeks - 1];


                CreateFolderBasedOnInputData(stDT, endDT);
                if (intentID.Trim() == "")
                {

                }
                else  // Do a single intentID 
                {
                    // DataForIntentID(intentID, stDT, endDT);
                    //                    DataFromClasses(intentID, stDT, endDT);

                    TSQL t = new TSQL();
                    DataSet ds = t.GetDataSet();

                    BeginXMLStep1(stDT, endDT, ds);
                   
                    

                }
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        private bool BeginXMLStep1(string stDT, string endDT, DataSet ds1)
        {
            try
            {
                string project = "1234"; //PAK for development
                DataRow[] res = ds1.Tables[0].Select("WaLNIIntentId = 111111");

                DataTable ds = res.CopyToDataTable();

                // only do this for rows all for the same intentID
                string intentID =   Convert.ToString(ds.Rows[0]["WaLNIIntentId"]);
                string pathString;
                pathString = project + "_" + intentID + "_" + McKDesiredDateFormatter(stDT) + "_" + McKDesiredDateFormatter(endDT) + "_" + DateTime.Now.ToString("HHmm") + ".xml";

                WaPWCPR pwc = new WaPWCPR();
                WaPWCPRProjectIntent intent = new WaPWCPRProjectIntent();
                intent.intentId = Convert.ToUInt32(intentID);
                pwc.projectIntent = intent;

                
                // payrollweek 
                WaPWCPRPayrollWeek week = new WaPWCPRPayrollWeek();
                week.amendedFlag = false;
                week.endOfWeekDate = Convert.ToDateTime(endDT);
                week.noWorkPerformFlag = false;
                week.amendedFlag = false;

                // Employees

                int empCnt = ds
                    .AsEnumerable()
                    .Select(r => r.Field<Int32>("Employee"))
                    .Distinct()
                    .Count();

                WaPWCPRPayrollWeekEmployee[] emps = new WaPWCPRPayrollWeekEmployee[empCnt - 1];
                int numOftradHoursWages = 0;

                int currEmp = 0;
                int rowNumber = 0;

                if (empCnt == 0)
                {
                    week.noWorkPerformFlag = true;
                }
                else
                {
                    // Get the dataset containing the otherdeductions for all employees in this group to save processing time of getting them one by one.
                    dsOtherDeductions = tsql.GetOtherDeductions();
                    dsTradeBenefits = tsql.GetTradeBenefits();


                    while (rowNumber < ds.Rows.Count - 1)
                    {
                        DataRow pRow = ds.Rows[rowNumber];
                        numOftradHoursWages = ds.Select("Employee = " + Convert.ToString(pRow["Employee"])).Length;
                        WaPWCPRPayrollWeekEmployeeTradeHoursWage[] trades = new WaPWCPRPayrollWeekEmployeeTradeHoursWage[numOftradHoursWages];
                        WaPWCPRPayrollWeekEmployee emp = CreateAnEmployee(pRow);
                        // Get TradeHoursWage for this employee
                        // Each row in the DS, that has same EmployeeID and is same craft and class and intentID (within one payweek) represents data for an individual TradeHoursWage
                        for (int prwthw = 0; prwthw < numOftradHoursWages; prwthw++)
                        {
                            trades[prwthw] = CreateTradeHours(pRow, Convert.ToString(pRow["Employee"]));
                            rowNumber++;
                            pRow = ds.Rows[rowNumber];
                        }

                        emp.tradeHoursWages = trades;
                        // other deductions section
                        OtherDeductions(Convert.ToString(pRow["Employee"]));
                        emp.otherDeductions = others;

                        emps[currEmp] = emp;
                        currEmp++;
                    }
                    week.employees = emps;
                }

                WaPWCPRPayrollWeek[] weeks;
                weeks = new WaPWCPRPayrollWeek[1];
                weeks[0] = week;

                pwc.payroll = weeks;

                var serializer = new XmlSerializer(typeof(WaPWCPR));
                using (var stream = new StreamWriter(newFolder + pathString))
                    serializer.Serialize(stream, pwc);


                




                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }


        private int OtherDeductions(string employeeID)
        {
            // DataSet ds = tsql.GetOtherDeductions(employeeID);
            DataRow[] res = dsOtherDeductions.Tables[0].Select("Employee = " + employeeID);

            int numOfOthers = res.Length; // ds.Tables[0].Rows.Count;
            others = new WaPWCPRPayrollWeekEmployeeOtherDeduction[numOfOthers];
            int cnt = 0;
            foreach (DataRow pRow in res)
            {
                WaPWCPRPayrollWeekEmployeeOtherDeduction other = new WaPWCPRPayrollWeekEmployeeOtherDeduction();
                other.deductionHourlyAmt = Convert.ToDecimal(pRow["Amount"]);
                other.deductionName = Convert.ToString(pRow["Description"]);
                others[cnt] = other;
                cnt++;
            }


            return 0;
        }
        private void PAKtest(DataSet dSet)
        {
            string Separator = ",";
            try
            {
                string source = newFolder + "\\PAKtest.csv";
                using (StreamWriter writer = new StreamWriter(source))
                {
                    // write header row
                    for (int columnCounter = 0; columnCounter < dSet.Tables[0].Columns.Count; columnCounter++)
                    {
                        if (columnCounter == (dSet.Tables[0].Columns.Count - 1))
                        {
                            writer.WriteLine(dSet.Tables[0].Columns[columnCounter].ColumnName);
                        }
                        else
                        {
                            writer.Write(dSet.Tables[0].Columns[columnCounter].ColumnName + Separator);
                        }
                    }
                    //writer.WriteLine(string.Empty);

                    //// data loop
                    foreach (DataRow pRow in dSet.Tables[0].Rows)
                    {
                        for (int columnCounter = 0; columnCounter < dSet.Tables[0].Columns.Count; columnCounter++)
                        {
                            if (columnCounter == (dSet.Tables[0].Columns.Count - 1))
                            {
                                writer.WriteLine(pRow[columnCounter].ToString());
                            }
                            else
                            {
                                writer.Write(pRow[columnCounter].ToString() + Separator);
                            }
                        }
                    }
                    writer.WriteLine(string.Empty);
                    writer.Flush();
                }
                return;
            }
            catch (Exception ex)
            {
                //// Log exception to logfile
                //sftp.Logger(System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in CreateCsvFile " + ex.Message);
                //// Send email notification of a failure within this routine.
                //EmailUtils.SendEmail("Exception thrown in CreateCsvFile " + ex.Message);
                return;
            }
        }




        private void PAKtest2(DataSet dSet)
        {
            string Separator = ",";
            try
            {

                DataTable tblIntent = dSet.Tables[0]; //.Select("WaLNIIntentId = 817011");
                DataRow[] res =   tblIntent.Select("WaLNIIntentId = 817011");
                int num = res.Length;
                

                //string source = newFolder + "\\PAKtest.csv";

                //using (StreamWriter writer = new StreamWriter(source))
                //{


                //    // write header row
                //    for (int columnCounter = 0; columnCounter < dSet.Tables[0].Columns.Count; columnCounter++)
                //    {

                //        if (columnCounter == (dSet.Tables[0].Columns.Count - 1))
                //        {
                //            writer.WriteLine(dSet.Tables[0].Columns[columnCounter].ColumnName);
                //        }
                //        else
                //        {
                //            writer.Write(dSet.Tables[0].Columns[columnCounter].ColumnName + Separator);
                //        }
                //    }
                //    //writer.WriteLine(string.Empty);

                //    //// data loop
                //    foreach (DataRow pRow in dSet.Tables[0].Rows)
                //    {
                //        for (int columnCounter = 0; columnCounter < dSet.Tables[0].Columns.Count; columnCounter++)
                //        {
                //            if (columnCounter == (dSet.Tables[0].Columns.Count - 1))
                //            {
                //                writer.WriteLine(pRow[columnCounter].ToString());
                //            }
                //            else
                //            {
                //                writer.Write(pRow[columnCounter].ToString() + Separator);
                //            }

                //        }
                //    }
                //    writer.WriteLine(string.Empty);

                //    writer.Flush();
                //}
                return;
            }
            catch (Exception ex)
            {
                //// Log exception to logfile
                //sftp.Logger(System.DateTime.Now.ToString("MM/dd/yyyy HH:mm") + " Exception thrown in CreateCsvFile " + ex.Message);
                //// Send email notification of a failure within this routine.
                //EmailUtils.SendEmail("Exception thrown in CreateCsvFile " + ex.Message);
                return;
            }
        }

      
        private string CreateFolderBasedOnInputData(string stDT, string endDT)
        {
            try
            {
                // 2020.02.10_2020.02.16_1346
                newFolder = McKDesiredDateFormatter(stDT) + "_" + McKDesiredDateFormatter(endDT) + "_" + DateTime.Now.ToString("HHmm");
                newFolder = FolderLocation + newFolder;
                System.IO.Directory.CreateDirectory(newFolder);
                newFolder = newFolder + "//";
                return newFolder;
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
            
        }

        private string McKDesiredDateFormatter(string inDate)
        {
            try
            {
                return Convert.ToDateTime(inDate).ToString("yyy.MM.dd");
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

       
        private int CreateATradeBenefit(DataRow[] dataRows)
        {
          //  int numOfOthers = res.Length; // ds.Tables[0].Rows.Count;
           // others = new WaPWCPRPayrollWeekEmployeeOtherDeduction[numOfOthers];
            int cnt = 0;
            foreach (DataRow pRow in dataRows)
            {
                WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit benefit = new WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit();
                benefit.benefitHourlyAmt = Convert.ToDecimal(pRow["RateLiab"]);
                benefit.benefitHourlyName = Convert.ToString(pRow["Description"]);
                tradeBenefits[cnt] = benefit;
                cnt++;
            }
            return 0;
        }

        private WaPWCPRPayrollWeekEmployeeTradeHoursWage CreateTradeHours(DataRow pRow, string empID)
        {
            WaPWCPRPayrollWeekEmployeeTradeHoursWage tradeHW = new WaPWCPRPayrollWeekEmployeeTradeHoursWage();
            // Get trade for this employye
            TSQL tsql = new TSQL();

            string tradeCode = tsql.TradeCodeForAnEmployee(empID);
            if (tradeCode == null)
            {

                WaPWCPRPayrollWeekEmployeeTradeHoursWageTrade trwt = new WaPWCPRPayrollWeekEmployeeTradeHoursWageTrade();
                trwt = WaPWCPRPayrollWeekEmployeeTradeHoursWageTrade.MISSINGTRADE;
                tradeHW.trade = trwt;
            }
            else 
            {
                Enum.TryParse(tradeCode, out WaPWCPRPayrollWeekEmployeeTradeHoursWageTrade tr);
                tradeHW.trade = tr;
                
            }
            bool appFlag = tsql.ApprenticeFlgForAnEmployee(empID);
            tradeHW.apprenticeFlg = appFlag;
            if (!appFlag)
            {
                tradeHW.jobClass = "Journey Level";
            }

            // WaPWCPRPayrollWeekEmployeeTradeHoursWageCounty.
            Enum.TryParse(Convert.ToString(pRow["County"]), out WaPWCPRPayrollWeekEmployeeTradeHoursWageCounty cnty);
            tradeHW.county = cnty;


            // PAK Wave 2  regularHourRateAmt
            //tradeHW.regularHourRateAmt = regRateAmnt;
            //tradeHW.overtimeHourRateAmt = overTime;
            //tradeHW.doubletimeHourRateAmt = doubleTime;            
            //tradeHW.apprenticeBenefitAmt = appBeneAmnt;

            // Wave 2 above here


            tradeHW.hourlyHolidayAmt = 0;
            tradeHW.hourlyVacationAmt = 0;
            tradeHW.hourlyMedicalAmt = Convert.ToDecimal(pRow["AmtLiabH"]) / Convert.ToDecimal(pRow["HoursPosted"]);
            tradeHW.hourlyPensionRateAmt = Convert.ToDecimal(pRow["AmtLiabP"]) / Convert.ToDecimal(pRow["HoursPosted"]);

            tradeHW.apprenticeId = tsql.GetApprenticeID(empID);
            if (tradeHW.apprenticeFlg)
                tradeHW.apprenticeState = "WA";

            //PAK not to be included in XML per Ed's Excel spreadsheet.
            //tradeHW.apprenticeOccpnName = appOccName;

            // PAK in prcc udWALNIApprenticeStep key to prcc is prco, craft class
            DataSet dsCC = tsql.CraftClassElements(empID);
            tradeHW.apprenticeStepName = Convert.ToString(dsCC.Tables[0].Rows[0]["udWALNIApprenticeStep"]);
            if (dsCC.Tables[0].Rows[0]["udWALNIBeginStepHrs"] != DBNull.Value )
                tradeHW.apprenticeStepBeginHours = Convert.ToDecimal(dsCC.Tables[0].Rows[0]["udWALNIBeginStepHrs"]);
            if (dsCC.Tables[0].Rows[0]["udWALNIEndStepHrs"] != DBNull.Value)
                tradeHW.apprenticeStepEndHours = Convert.ToDecimal(dsCC.Tables[0].Rows[0]["udWALNIEndStepHrs"]);

            tradeHW.regularDay1HoursSpecified = true;
            tradeHW.regularDay2HoursSpecified = true;
            tradeHW.regularDay3HoursSpecified = true;
            tradeHW.regularDay4HoursSpecified = true;
            tradeHW.regularDay5HoursSpecified = true;
            tradeHW.regularDay6HoursSpecified = true;
            tradeHW.regularDay7HoursSpecified = true;

            tradeHW.regularDay1Hours = Convert.ToDecimal(pRow["HoursSTDay1"]);
            tradeHW.regularDay2Hours = Convert.ToDecimal(pRow["HoursSTDay2"]);
            tradeHW.regularDay3Hours = Convert.ToDecimal(pRow["HoursSTDay3"]);
            tradeHW.regularDay4Hours = Convert.ToDecimal(pRow["HoursSTDay4"]);
            tradeHW.regularDay5Hours = Convert.ToDecimal(pRow["HoursSTDay5"]);
            tradeHW.regularDay6Hours = Convert.ToDecimal(pRow["HoursSTDay6"]);
            tradeHW.regularDay7Hours = Convert.ToDecimal(pRow["HoursSTDay7"]);

            tradeHW.overtimeDay1HoursSpecified = true;
            tradeHW.overtimeDay2HoursSpecified = true;
            tradeHW.overtimeDay3HoursSpecified = true;
            tradeHW.overtimeDay4HoursSpecified = true;
            tradeHW.overtimeDay5HoursSpecified = true;
            tradeHW.overtimeDay6HoursSpecified = true;
            tradeHW.overtimeDay7HoursSpecified = true;

            tradeHW.overtimeDay1Hours = Convert.ToDecimal(pRow["HoursOTDay1"]);
            tradeHW.overtimeDay2Hours = Convert.ToDecimal(pRow["HoursOTDay2"]);
            tradeHW.overtimeDay3Hours = Convert.ToDecimal(pRow["HoursOTDay3"]);
            tradeHW.overtimeDay4Hours = Convert.ToDecimal(pRow["HoursOTDay4"]);
            tradeHW.overtimeDay5Hours = Convert.ToDecimal(pRow["HoursOTDay5"]);
            tradeHW.overtimeDay6Hours = Convert.ToDecimal(pRow["HoursOTDay6"]);
            tradeHW.overtimeDay7Hours = Convert.ToDecimal(pRow["HoursOTDay7"]);


            tradeHW.doubletimeDay1HoursSpecified = true;
            tradeHW.doubletimeDay2HoursSpecified = true;
            tradeHW.doubletimeDay3HoursSpecified = true;
            tradeHW.doubletimeDay4HoursSpecified = true;
            tradeHW.doubletimeDay5HoursSpecified = true;
            tradeHW.doubletimeDay6HoursSpecified = true;
            tradeHW.doubletimeDay7HoursSpecified = true;

            tradeHW.doubletimeDay1Hours = Convert.ToDecimal(pRow["HoursDTDay1"]);
            tradeHW.doubletimeDay2Hours = Convert.ToDecimal(pRow["HoursDTDay2"]);
            tradeHW.doubletimeDay3Hours = Convert.ToDecimal(pRow["HoursDTDay3"]);
            tradeHW.doubletimeDay4Hours = Convert.ToDecimal(pRow["HoursDTDay4"]);
            tradeHW.doubletimeDay5Hours = Convert.ToDecimal(pRow["HoursDTDay5"]); 
            tradeHW.doubletimeDay6Hours = Convert.ToDecimal(pRow["HoursDTDay6"]);
            tradeHW.doubletimeDay7Hours = Convert.ToDecimal(pRow["HoursDTDay7"]);


            //tradeHW.tradeBenefits = tradeBenefits;
            //  DataRow[] res = dsOtherDeductions.Tables[0].Select("Employee = " + employeeID);
            string selectCriteria = "Employee = '" + Convert.ToString(pRow["Employee"]) + "' AND Job = '" + Convert.ToString(pRow["Job"]) + "' AND Craft = '" +
                Convert.ToString(pRow["Craft"]) + "' and Class = '" + Convert.ToString(pRow["Class"]) + "'";
            DataRow[] res = dsTradeBenefits.Tables[0].Select(selectCriteria);
            tradeBenefits = new WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit[res.Length];
            CreateATradeBenefit(res);


            tradeHW.tradeBenefits = tradeBenefits;

            return tradeHW;
        }


        

        private WaPWCPRPayrollWeekEmployee CreateAnEmployee(DataRow dr)
            
           // string firstName, string midName, string lastName, string sSN, WaPWCPRPayrollWeekEmployeeEthnicity ethnicity,
           //WaPWCPRPayrollWeekEmployeeGender gender, WaPWCPRPayrollWeekEmployeeVeteranStatus vetStatus, string address1, string address2, string city, string state, string zipCode,
           //Decimal grossPay, Decimal fica, Decimal taxWitholding, WaPWCPRPayrollWeekEmployeeOtherDeduction[] otherDeducs, WaPWCPRPayrollWeekEmployeeTradeHoursWage[] tradeWages )
        {
            WaPWCPRPayrollWeekEmployee emp = new WaPWCPRPayrollWeekEmployee();
            emp.firstName = Convert.ToString(dr["NameFirst"]);
            emp.midName = Convert.ToString(dr["MidName"]);
            emp.lastName = Convert.ToString(dr["NameLast"]);
            emp.ssn = Convert.ToString(dr["SSN"]);
            emp.ethnicity =  GetTheEthnicity( Convert.ToString(dr["Ethnicity"]));
            emp.gender = GetGender(Convert.ToString(dr["Sex"]));

            // See requirements doc.  We don't have this value
            emp.veteranStatus = WaPWCPRPayrollWeekEmployeeVeteranStatus.Item1;
            emp.address1 = Convert.ToString(dr["Address1"]);
            emp.address2 = Convert.ToString(dr["Address2"]);
            emp.city = Convert.ToString(dr["City"]);
            emp.state = Convert.ToString(dr["State"]);
            emp.zip = Convert.ToString(dr["Zip"]);
            emp.grossPay = Convert.ToDecimal(dr["AmtEarnGross"]);


            // [AmtDednXSocSec] + [AmtDednXMedicare].
            emp.fica = Convert.ToDecimal(dr["AmtDednXSocSec"]) * Convert.ToDecimal(dr["AmtDednXMedicare"]);

            // PAK wave2
            //emp.taxWitholding = taxWitholding;
            //emp.otherDeductions = otherDeducs;
            //emp.tradeHoursWages = tradeWages;

            return emp;
        }

       private WaPWCPRPayrollWeekEmployeeGender GetGender(string gender)
        {
            if (gender == "M")
                return WaPWCPRPayrollWeekEmployeeGender.M;
            if (gender == "F")
                return WaPWCPRPayrollWeekEmployeeGender.F;
            // fall out male
            return WaPWCPRPayrollWeekEmployeeGender.M;
        }
        private WaPWCPRPayrollWeekEmployeeEthnicity GetTheEthnicity(string eth)
        {

            switch (eth)
            {
                case @"American Indian/Alaska Native":
                    {
                        return WaPWCPRPayrollWeekEmployeeEthnicity.AmericanIndianAlaskanAleut;
                    }
                case "Asian (not Hispanic or Latino)":
                    {
                        return WaPWCPRPayrollWeekEmployeeEthnicity.Asian;
                    }
                case "Black or African American":
                    {
                        return WaPWCPRPayrollWeekEmployeeEthnicity.BlackorAfricanAmerican;
                    }
                case "Do Not Wish to Disclose":
                    {
                        return WaPWCPRPayrollWeekEmployeeEthnicity.Prefernottoanswer;
                    }
                case "Hispanic or Latino":
                    {
                        return WaPWCPRPayrollWeekEmployeeEthnicity.HispanicorLatino;
                    }
                case "Native Hawaiian/Pacific Island":
                    {
                        return WaPWCPRPayrollWeekEmployeeEthnicity.NativeHawaiianorotherPacificIslander;
                    }
                case "Two or more Races":
                    {
                        return WaPWCPRPayrollWeekEmployeeEthnicity.Other;
                    }
                case "White (not Hispanic or Latino)":
                    { return WaPWCPRPayrollWeekEmployeeEthnicity.WhiteorCaucasian; }
            }
            //1
            var res = WaPWCPRPayrollWeekEmployeeEthnicity.AmericanIndianAlaskanAleut;
            var result = res.XmlEnumToString();

            if (eth == result)
                return WaPWCPRPayrollWeekEmployeeEthnicity.AmericanIndianAlaskanAleut;

            res = WaPWCPRPayrollWeekEmployeeEthnicity.Asian;
            result = res.XmlEnumToString();
            if (eth == result)
                return WaPWCPRPayrollWeekEmployeeEthnicity.Asian;

            if (eth == WaPWCPRPayrollWeekEmployeeEthnicity.BlackorAfricanAmerican.ToString())
                return WaPWCPRPayrollWeekEmployeeEthnicity.BlackorAfricanAmerican;

            res = WaPWCPRPayrollWeekEmployeeEthnicity.HispanicorLatino;
            result = res.XmlEnumToString();
            if (eth == result)
                return WaPWCPRPayrollWeekEmployeeEthnicity.HispanicorLatino;

            res = WaPWCPRPayrollWeekEmployeeEthnicity.WhiteorCaucasian;
            result = res.XmlEnumToString();
            if (eth == result)
                return WaPWCPRPayrollWeekEmployeeEthnicity.WhiteorCaucasian;

            //switch (eth)
            //{
            //    case WaPWCPRPayrollWeekEmployeeEthnicity.AmericanIndianAlaskanAleut.ToString():
            //        return WaPWCPRPayrollWeekEmployeeEthnicity.AmericanIndianAlaskanAleut;

            //    case WaPWCPRPayrollWeekEmployeeEthnicity.AmericanIndianAlaskanAleut.ToString():
            //        return WaPWCPRPayrollWeekEmployeeEthnicity.AmericanIndianAlaskanAleut;

            //}

            else
                return WaPWCPRPayrollWeekEmployeeEthnicity.Other;

        }
        private WaPWCPRPayrollWeek CreatePayrollWeek(DateTime endofWeekDate, bool noWorkPerformFlag, WaPWCPRPayrollWeekEmployee[] emps)
        {
            WaPWCPRPayrollWeek week = new WaPWCPRPayrollWeek();
            week.endOfWeekDate = endofWeekDate;
            week.noWorkPerformFlag = noWorkPerformFlag;
            week.employees = emps;

            return week;
        }

        //private bool DataFromClasses(string intentID, string stDT, string endDT)
        //{
        //    try
        //    {
        //        string project = "1234"; //PAK for development

        //        string pathString;
        //        pathString = project + "_" + intentID + "_" + McKDesiredDateFormatter(stDT) + "_" + McKDesiredDateFormatter(endDT) + "_" + DateTime.Now.ToString("HHmm") + ".xml";

        //        WaPWCPR pwc = new WaPWCPR();
        //        WaPWCPRProjectIntent intent = new WaPWCPRProjectIntent();
        //        intent.intentId = Convert.ToUInt32(intentID);
        //        pwc.projectIntent = intent;

        //        WaPWCPRPayrollWeek week = new WaPWCPRPayrollWeek();
        //        week.amendedFlag = false;
        //        week.endOfWeekDate = new DateTime(2020, 1, 21);
        //        week.noWorkPerformFlag = false;
        //        week.amendedFlag = false;

        //        WaPWCPRPayrollWeekEmployee emp = new WaPWCPRPayrollWeekEmployee();
        //        emp.firstName = "Zane";
        //        emp.lastName = "Zally";
        //        emp.ssn = "99999999";
        //        emp.ethnicity = WaPWCPRPayrollWeekEmployeeEthnicity.Prefernottoanswer;
        //        emp.gender = WaPWCPRPayrollWeekEmployeeGender.F;
        //        emp.veteranStatus = WaPWCPRPayrollWeekEmployeeVeteranStatus.N;
        //        emp.address1 = "111 1111st Street";
        //        emp.city = "Olympia";
        //        emp.state = "WA";
        //        emp.zip = "99502";
        //        emp.grossPay = 2254;
        //        emp.fica = 172.43M;
        //        emp.taxWitholding = 462.00M;
        //        WaPWCPRPayrollWeekEmployeeOtherDeduction other = new WaPWCPRPayrollWeekEmployeeOtherDeduction();
        //        other.deductionName = "Tax Lien";
        //        other.deductionHourlyAmt = 75.00M;

        //        WaPWCPRPayrollWeekEmployeeOtherDeduction[] others = new WaPWCPRPayrollWeekEmployeeOtherDeduction[1];
        //        others[0] = other;
        //        emp.otherDeductions = others;

        //        WaPWCPRPayrollWeekEmployeeTradeHoursWage trade = new WaPWCPRPayrollWeekEmployeeTradeHoursWage();
        //        trade.trade = WaPWCPRPayrollWeekEmployeeTradeHoursWageTrade.CARP;
        //        trade.jobClass = "Floor Layer";
        //        trade.county = WaPWCPRPayrollWeekEmployeeTradeHoursWageCounty.Island;
        //        trade.regularHourRateAmt = 46.00M;
        //        trade.overtimeHourRateAmt = 69.00M;

        //        WaPWCPRPayrollWeekEmployeeTradeHoursWage[] trades = new WaPWCPRPayrollWeekEmployeeTradeHoursWage[1];
        //        trades[0] = trade;
        //        emp.tradeHoursWages = trades;

        //        WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit ben = new WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit();
        //        ben.benefitHourlyName = "Wellness Program";
        //        ben.benefitHourlyAmt = .50M;
        //        WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit[] bens = new WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit[1];

        //        bens[0] = ben;

        //        trade.tradeBenefits = bens;

        //        WaPWCPRPayrollWeekEmployee[] emps = new WaPWCPRPayrollWeekEmployee[1];
        //        emps[0] = emp;
        //        week.employees = emps;

               

        //        WaPWCPRPayrollWeek[] weeks;
        //        weeks = new WaPWCPRPayrollWeek[2];
        //        weeks[1] = week;

        //        pwc.payroll = weeks;

        //        var serializer = new XmlSerializer(typeof(WaPWCPR));
        //        using (var stream = new StreamWriter(newFolder + pathString))
        //            serializer.Serialize(stream, pwc);



        //        //WaPWCPRPayrollWeek[] weeks = new WaPWCPRPayrollWeek[2];
        //        //weeks[0].amendedFlag = true;
        //        //weeks[0].endOfWeekDate = new DateTime(2020, 1, 21);
        //        //weeks[0].noWorkPerformFlag = false;
        //        //weeks[0].amendedFlag = false;

        //        //weeks[1].endOfWeekDate = new DateTime(2020, 2, 3);
        //        //weeks[1].noWorkPerformFlag = false;
        //        //weeks[1].amendedFlag = false;
        //        //WaPWCPRPayrollWeek p = new WaPWCPRPayrollWeek();
        //        //p.endOfWeekDate = new DateTime(2020, 1, 21);
        //        //p.noWorkPerformFlag = false;
        //        //p.amendedFlag = false;

        //        //var serializer = new XmlSerializer(typeof(WaPWCPRPayrollWeek));
        //        //p.employees[ = new WaPWCPRPayrollWeekEmployee();

        //        //
        //        //WaPWCPRPayrollWeek week = new WaPWCPRPayrollWeek();
        //        //pwc.payroll[1] = week;
        //        //pwc.payroll[2] = week;


        //        // var  = new WaPWCPRPayrollWeek { amendedDate = System.DateTime.Today, amendedFlag = false };
        //        //var data = new WaPWCPRPayrollWeek { endOfWeekDate =  System.DateTime.Today, noWorkPerformFlag = true };
        //        //var serializer = new XmlSerializer(typeof(WaPWCPRPayrollWeek));
        //        //using (var stream = new StreamWriter("c:\\projects\\test.xml"))
        //        //    serializer.Serialize(stream, data);





        //        //XmlTextWriter writer = new XmlTextWriter(newFolder + pathString, System.Text.Encoding.UTF8);

        //        //writer.WriteStartDocument(true);
        //        //writer.Formatting = Formatting.Indented;
        //        //writer.Indentation = 2;
        //        //writer.WriteStartElement("WaPWCPR");

        //        ////< WaPWCPR >
        //        ////      < projectIntent >
        //        ////        < intentId > 796910 </ intentId >
        //        ////      </ projectIntent >
        //        ////      < payroll >
        //        //writer.WriteStartElement("projectIntent");
        //        //writer.WriteStartElement("intentId");
        //        //writer.WriteString(intentID);
        //        //writer.WriteEndElement();
        //        //writer.WriteEndElement();
        //        //writer.WriteStartElement("payroll");
        //        //writer.WriteStartElement("payrollWeek");
        //        //writer.WriteStartElement("endOfWeekDate");
        //        //writer.WriteString("2017-01-21");
        //        //writer.WriteEndElement();
        //        //writer.WriteStartElement("noWorkPerformFlag");
        //        //writer.WriteString("false");
        //        //writer.WriteEndElement();
        //        //writer.WriteStartElement("amendedFlag");
        //        //writer.WriteString("false");
        //        //writer.WriteEndElement();
        //        //writer.WriteEndElement();
        //        //writer.WriteEndElement();
        //        //writer.WriteEndElement();
        //        //writer.WriteEndDocument();
        //        //writer.Close();

        //        return true;
        //    }
        //    catch (Exception ex)
        //    {
        //        return false;
        //    }
        //}

        private bool DataForIntentID(string intentID, string stDT, string endDT)
        {
            try
            {
                string project = "1234"; //PAK for development

                string pathString;
                pathString = project + "_" + intentID + "_" + McKDesiredDateFormatter(stDT) + "_" + McKDesiredDateFormatter(endDT) + "_" + DateTime.Now.ToString("HHmm") + ".xml";

                XmlTextWriter writer = new XmlTextWriter(newFolder+pathString, System.Text.Encoding.UTF8);

                writer.WriteStartDocument(true);
                writer.Formatting = Formatting.Indented;
                writer.Indentation = 2;
                writer.WriteStartElement("WaPWCPR");

                //< WaPWCPR >
                //      < projectIntent >
                //        < intentId > 796910 </ intentId >
                //      </ projectIntent >
                //      < payroll >
                writer.WriteStartElement("projectIntent");
                    writer.WriteStartElement("intentId");
                    writer.WriteString(intentID);
                    writer.WriteEndElement();
                writer.WriteEndElement();
                writer.WriteStartElement("payroll");
                    writer.WriteStartElement("payrollWeek");
                        writer.WriteStartElement("endOfWeekDate");
                        writer.WriteString("2017-01-21");
                        writer.WriteEndElement();
                        writer.WriteStartElement("noWorkPerformFlag");
                        writer.WriteString("false");
                        writer.WriteEndElement();
                        writer.WriteStartElement("amendedFlag");
                        writer.WriteString("false");
                        writer.WriteEndElement();

                    writer.WriteEndElement();
                writer.WriteEndElement();
                
                
                
                
                //WaPWCPRPayrollWeek p = new WaPWCPRPayrollWeek();
                ////  < endOfWeekDate > 2017 - 01 - 21 </ endOfWeekDate >
                ////< noWorkPerformFlag > false </ noWorkPerformFlag >
                ////< amendedFlag > true </ amendedFlag >
                ////< amendedDate > 2017 - 06 - 07 </ amendedDate >
                //p.endOfWeekDate = new DateTime(2020, 1, 21);
                //p.noWorkPerformFlag = false;
                //p.amendedFlag = false;

                //var serializer = new XmlSerializer(typeof(WaPWCPRPayrollWeek));
                //p.employees[ = new WaPWCPRPayrollWeekEmployee();

                //WaPWCPR pwc = new WaPWCPR();
                //WaPWCPRPayrollWeek week = new WaPWCPRPayrollWeek();
                //pwc.payroll[1] = week;
                //pwc.payroll[2] = week;


                // var  = new WaPWCPRPayrollWeek { amendedDate = System.DateTime.Today, amendedFlag = false };
                //var data = new WaPWCPRPayrollWeek { endOfWeekDate =  System.DateTime.Today, noWorkPerformFlag = true };
                //var serializer = new XmlSerializer(typeof(WaPWCPRPayrollWeek));
                //using (var stream = new StreamWriter("c:\\projects\\test.xml"))
                //    serializer.Serialize(stream, data);


                writer.WriteEndElement();
                writer.WriteEndDocument();
                writer.Close();

                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }
        private void createNode(string pID, string pName, string pPrice, XmlTextWriter writer)
        {
            writer.WriteStartElement("Product");
            writer.WriteStartElement("Product_id");
            writer.WriteString(pID);
            writer.WriteEndElement();
            writer.WriteStartElement("Product_name");
            writer.WriteString(pName);
            writer.WriteEndElement();
            writer.WriteStartElement("Product_price");
            writer.WriteString(pPrice);
            writer.WriteEndElement();
            writer.WriteEndElement();
        }
    }

    static class x
    {
        public static string XmlEnumToString<TEnum>(this TEnum value) where TEnum : struct, IConvertible
        {
            Type enumType = typeof(TEnum);
            if (!enumType.IsEnum)
                return null;

            MemberInfo member = enumType.GetMember(value.ToString()).FirstOrDefault();
            if (member == null)
                return null;

            XmlEnumAttribute attribute = member.GetCustomAttributes(false).OfType<XmlEnumAttribute>().FirstOrDefault();
            if (attribute == null)
                return member.Name; // Fallback to the member name when there's no attribute

            return attribute.Name;
        }
    }
    //    WaPWCPRPayrollWeekEmployee emp = new WaPWCPRPayrollWeekEmployee();
    //emp.firstName = "Zane";
    //emp.lastName = "Zally";
    //emp.ssn = "99999999";
    //emp.ethnicity = WaPWCPRPayrollWeekEmployeeEthnicity.Prefernottoanswer;
    //emp.gender = WaPWCPRPayrollWeekEmployeeGender.F;
    //emp.veteranStatus = WaPWCPRPayrollWeekEmployeeVeteranStatus.N;
    //emp.address1 = "111 1111st Street";
    //emp.city = "Olympia";
    //emp.state = "WA";
    //emp.zip = "99502";
    //emp.grossPay = 2254;
    //emp.fica = 172.43M;
    //emp.taxWitholding = 462.00M;
    //WaPWCPRPayrollWeekEmployeeOtherDeduction other = new WaPWCPRPayrollWeekEmployeeOtherDeduction();
    //other.deductionName = "Tax Lien";
    //other.deductionHourlyAmt = 75.00M;

    //WaPWCPRPayrollWeekEmployeeOtherDeduction[] others = new WaPWCPRPayrollWeekEmployeeOtherDeduction[1];
    //others[0] = other;
    //emp.otherDeductions = others;

    //WaPWCPRPayrollWeekEmployeeTradeHoursWage trade = new WaPWCPRPayrollWeekEmployeeTradeHoursWage();
    //trade.trade = WaPWCPRPayrollWeekEmployeeTradeHoursWageTrade.CARP;
    //trade.jobClass = "Floor Layer";
    //trade.county = WaPWCPRPayrollWeekEmployeeTradeHoursWageCounty.Island;
    //trade.regularHourRateAmt = 46.00M;
    //trade.overtimeHourRateAmt = 69.00M;

    //WaPWCPRPayrollWeekEmployeeTradeHoursWage[] trades = new WaPWCPRPayrollWeekEmployeeTradeHoursWage[1];
    //trades[0] = trade;
    //emp.tradeHoursWages = trades;

    //WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit ben = new WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit();
    //ben.benefitHourlyName = "Wellness Program";
    //ben.benefitHourlyAmt = .50M;
    //WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit[] bens = new WaPWCPRPayrollWeekEmployeeTradeHoursWageTradeBenefit[1];

    //bens[0] = ben;

    //trade.tradeBenefits = bens;

    //WaPWCPRPayrollWeekEmployee[] emps = new WaPWCPRPayrollWeekEmployee[1];
    //emps[0] = emp;
    //week.employees = emps;



    //WaPWCPRPayrollWeek[] weeks;
    //weeks = new WaPWCPRPayrollWeek[2];
    //weeks[1] = week;

    //pwc.payroll = weeks;

}