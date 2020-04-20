using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using McKinstry.VPIntegration;
using McKinstry.ExpenseWire.Model;
using McKinstry.ExpenseWire.Controller;

namespace McKinstry.ExpenseWire.Services
{
    public class ViewPointIntegrationService:IViewPointIntegrationService
    {
        MCK_INTEGRATIONEntities DB = null;
        EmployeeVendorInfo E = null;
        int employeeNumber = 0;
        int seq = 1;
        string phasecode = "";
        public ViewPointIntegrationService()
        {
            DB = new MCK_INTEGRATIONEntities();
        }

        public void AddExpense(ExpenseWireSendDataTransactionExpenseSearchExpense exp)
        {
            // Variable Declaraion          
            seq = 1;
            try
            {
                //if (exp.Ref.ID.ToString() == "43798" || exp.Ref.ID.ToString() == "44302")
                //{
                    
                //}
                int.TryParse(exp.User.ExternalID, out employeeNumber);
                E = DB.EmployeeVendorInfoes.Where(EV => EV.Employee == employeeNumber).FirstOrDefault();
                ExpenseHeader EH = new ExpenseHeader();
                EH.ExpenseID = "EW" + exp.Ref.ID.ToString();
                EH.EmployeeNumber = exp.User.ExternalID.ToString();
                EH.ExpenseTitle = exp.ExpenseTitle;
                EH.ExpenseTotal = exp.ExpenseTotal;
                EH.EmployeeCompany = E != null ? Convert.ToByte(E.PRCo) : Convert.ToByte(0);
                EH.EmployeeGLDept = E != null ? E.GLDept : "0";
                EH.InvoiceNumber = exp.Ref.ID.ToString();
                EH.DueDate = exp.CreatedDate.AddDays(7);
                EH.CreatedDate = exp.CreatedDate;
                EH.ExpenseWireBatchID = exp.Batch.BatchNumber.ToString();
                EH.EmployeeVendorNumber = E != null ? E.Vendor.ToString() : "";
                EH.ProcessStatus = "N";
                DB.ExpenseHeaders.AddObject(EH);
                foreach (ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetail detail in exp.ExpenseDetail)
                {
                    ExpenseDetail ED = new ExpenseDetail();
                    string expenseJob = detail.Customer.ExternalID != null ? detail.Customer.ExternalID : "";
                    JobPhaseCodeInfo JP = DB.JobPhaseCodeInfoes.Where(J => J.Job.TrimStart() == expenseJob).FirstOrDefault();
                    ED.ExpenseID = "EW" + detail.Expense.ID.ToString();
                    ED.EmployeeNumber = exp.User.ExternalID.ToString();
                    ED.SequenceNumber = Convert.ToInt16(seq);
                    ED.GLAccount = detail.ExpenseType.GLCode;
                    if (detail.Description.Length < 499)
                        ED.ExpenseTitle = Utility.PraseToCGCString(detail.Description);
                    else
                        ED.ExpenseTitle = " ";
                    //else
                    //    ED.ExpenseTitle = PraseToCGCString(expenseItem.XPathSelectElement("Description").Value).Substring(0,499);

                    ED.EmployeeGLDept = E != null ? E.GLDept : "0";
                    ED.CostType = "4";
                    ED.ExpenseAmount = detail.ExpenseAmount;
                    ED.ExpenseWireBatchID = exp.Batch.BatchNumber.ToString();
                    ED.JobNumber = expenseJob.Trim();
                    ED.JobCompany = JP != null ? Convert.ToByte(JP.JCCo) : E != null ? Convert.ToByte(E.PRCo) : Convert.ToByte(1);
                    if (ED.JobNumber == "OH")
                        ED.JobGLDept = E != null ? E.GLDept : "0";
                    ED.ProcessStatus = "N";
                    if (detail.Project.ExternalID != null)
                    {
                        if (detail.Project.ExternalID != "")
                            phasecode = detail.Project.ExternalID.Split(':') != null ? detail.Project.ExternalID.Split(':')[1] : "";
                    }
                    ED.PhaseCode = phasecode.Trim();
                    seq++;
                    DB.ExpenseDetails.AddObject(ED);
                }
                DB.SaveChanges();
            }
            catch (Exception e) { throw new Exception(e.Message + " \n Inner Expection:" + e.InnerException + "\n Trace :" + e.StackTrace); }
        }

       

        void IViewPointIntegrationService.AddHeader(ExpenseWireSendDataTransactionExpenseSearchExpense expense)
        {
            throw new NotImplementedException();
        }

        void IViewPointIntegrationService.AddDetail(ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetail detail)
        {
           
        }

        void IViewPointIntegrationService.AddTimeSheet()
        {
            throw new NotImplementedException();
        }
    }
}
