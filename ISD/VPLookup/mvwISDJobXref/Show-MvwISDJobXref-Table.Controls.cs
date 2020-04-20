
// This file implements the TableControl, TableControlRow, and RecordControl classes for the 
// Show_MvwISDJobXref_Table.aspx page.  The Row or RecordControl classes are the 
// ideal place to add code customizations. For example, you can override the LoadData, 
// CreateWhereClause, DataBind, SaveData, GetUIData, and Validate methods.

#region "Using statements"    

using Microsoft.VisualBasic;
using BaseClasses.Web.UI.WebControls;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Web.Script.Serialization;

using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Utils;
using ReportTools.ReportCreator;
using ReportTools.Shared;

        
using VPLookup.Business;
using VPLookup.Data;
using VPLookup.UI;
using VPLookup;
		

#endregion

  
namespace VPLookup.UI.Controls.Show_MvwISDJobXref_Table
{
  

#region "Section 1: Place your customizations here."

    
public class MvwISDJobXrefTableControlRow : BaseMvwISDJobXrefTableControlRow
{
      
        // The BaseMvwISDJobXrefTableControlRow implements code for a ROW within the
        // the MvwISDJobXrefTableControl table.  The BaseMvwISDJobXrefTableControlRow implements the DataBind and SaveData methods.
        // The loading of data is actually performed by the LoadData method in the base class of MvwISDJobXrefTableControl.

        // This is the ideal place to add your code customizations. For example, you can override the DataBind, 
        // SaveData, GetUIData, and Validate methods.
        
}

  

public class MvwISDJobXrefTableControl : BaseMvwISDJobXrefTableControl
{
    // The BaseMvwISDJobXrefTableControl class implements the LoadData, DataBind, CreateWhereClause
    // and other methods to load and display the data in a table control.

    // This is the ideal place to add your code customizations. You can override the LoadData and CreateWhereClause,
    // The MvwISDJobXrefTableControlRow class offers another place where you can customize
    // the DataBind, GetUIData, SaveData and Validate methods specific to each row displayed on the table.

}

  
public class MvwISDCustomerXrefRecordControl : BaseMvwISDCustomerXrefRecordControl
{
      
        // The BaseMvwISDCustomerXrefRecordControl implements the LoadData, DataBind and other
        // methods to load and display the data in a table control.

        // This is the ideal place to add your code customizations. For example, you can override the LoadData, 
        // CreateWhereClause, DataBind, SaveData, GetUIData, and Validate methods.
        
}

  

//public class MvwISDJobPhaseXrefTableControl : BaseMvwISDJobPhaseXrefTableControl
//{
//    // The BaseMvwISDJobPhaseXrefTableControl class implements the LoadData, DataBind, CreateWhereClause
//    // and other methods to load and display the data in a table control.
//
//    // This is the ideal place to add your code customizations. You can override the LoadData and CreateWhereClause,
//    // The MvwISDJobPhaseXrefTableControlRow class offers another place where you can customize
//    // the DataBind, GetUIData, SaveData and Validate methods specific to each row displayed on the table.
//
//}
//
//public class MvwISDJobPhaseXrefTableControlRow : BaseMvwISDJobPhaseXrefTableControlRow
//{
//      
//        // The BaseMvwISDJobPhaseXrefTableControlRow implements code for a ROW within the
//        // the MvwISDJobPhaseXrefTableControl table.  The BaseMvwISDJobPhaseXrefTableControlRow implements the DataBind and SaveData methods.
//        // The loading of data is actually performed by the LoadData method in the base class of MvwISDJobPhaseXrefTableControl.
//
//        // This is the ideal place to add your code customizations. For example, you can override the DataBind, 
//        // SaveData, GetUIData, and Validate methods.
//        
//}
//
#endregion

  

#region "Section 2: Do not modify this section."
    
    
// Base class for the MvwISDJobXrefTableControlRow control on the Show_MvwISDJobXref_Table page.
// Do not modify this class. Instead override any method in MvwISDJobXrefTableControlRow.
public class BaseMvwISDJobXrefTableControlRow : VPLookup.UI.BaseApplicationRecordControl
{
        public BaseMvwISDJobXrefTableControlRow()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        // To customize, override this method in MvwISDJobXrefTableControlRow.
        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
                
            this.ClearControlsFromSession();
        }

        // To customize, override this method in MvwISDJobXrefTableControlRow.
        protected virtual void Control_Load(object sender, System.EventArgs e)
        {      
                    
        
              // Register the event handlers.

          
                    this.ExpandRowButton.Click += ExpandRowButton_Click;
                        
                    this.ViewRowButton.Click += ViewRowButton_Click;
                        
        }

        public virtual void LoadData()  
        {
            // Load the data from the database into the DataSource DatabaseViewpoint%dbo.mvwISDJobXref record.
            // It is better to make changes to functions called by LoadData such as
            // CreateWhereClause, rather than making changes here.
            
        
            // The RecordUniqueId is set the first time a record is loaded, and is
            // used during a PostBack to load the record.
            if (this.RecordUniqueId != null && this.RecordUniqueId.Length > 0) {
              
                this.DataSource = MvwISDJobXrefView.GetRecord(this.RecordUniqueId, true);
              
                return;
            }
      
            // Since this is a row in the table, the data for this row is loaded by the 
            // LoadData method of the BaseMvwISDJobXrefTableControl when the data for the entire
            // table is loaded.
            
            this.DataSource = new MvwISDJobXrefRecord();
            
        }

        public override void DataBind()
        {
            // The DataBind method binds the user interface controls to the values
            // from the database record.  To do this, it calls the Set methods for 
            // each of the field displayed on the webpage.  It is better to make 
            // changes in the Set methods, rather than making changes here.
            
            base.DataBind();
            
            // Make sure that the DataSource is initialized.
            
            if (this.DataSource == null) {
             //This is to make sure all the controls will be invisible if no record is present in the cell
             
                return;
            }
              
            // LoadData for DataSource for chart and report if they exist
          
            // Store the checksum. The checksum is used to
            // ensure the record was not changed by another user.
            if (this.DataSource.GetCheckSumValue() != null)
                this.CheckSum = this.DataSource.GetCheckSumValue().Value;
            

            // Call the Set methods for each controls on the panel
        
                SetCGCCo();
                SetCGCJob();
                
                SetGLDepartmentName();
                SetGLDepartmentNumber();
                SetJobStatus();
                SetMailAddress();
                SetMailAddress2();
                SetMailCity();
                SetMailState();
                SetMailZip();
                
                
                SetMvwISDJobXrefTabContainer();
                SetPOC();
                SetPOCName();
                SetSalesPerson();
                SetSalesPersonName();
                
                SetVPCo();
                SetVPCustomer();
                SetVPCustomerName();
                SetVPJob();
                SetVPJobDesc();
                SetExpandRowButton();
              
                SetViewRowButton();
              

      

            this.IsNewRecord = true;
          
            if (this.DataSource.IsCreated) {
                this.IsNewRecord = false;
              
                if (this.DataSource.GetID() != null)
                    this.RecordUniqueId = this.DataSource.GetID().ToXmlString();
              
            }
            

            // Now load data for each record and table child UI controls.
            // Ordering is important because child controls get 
            // their parent ids from their parent UI controls.
            bool shouldResetControl = false;
            if (shouldResetControl) { }; // prototype usage to void compiler warnings
                      
        SetMvwISDCustomerXrefRecordControl();

        
        }
        
        
        public virtual void SetCGCCo()
        {
            
                    
            // Set the CGCCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.CGCCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCCoSpecified) {
                								
                // If the CGCCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.CGCCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CGCCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCCo.Text = MvwISDJobXrefView.CGCCo.Format(MvwISDJobXrefView.CGCCo.DefaultValue);
            		
            }
            
            // If the CGCCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CGCCo.Text == null ||
                this.CGCCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CGCCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCGCJob()
        {
            
                    
            // Set the CGCJob Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.CGCJob is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCJobSpecified) {
                								
                // If the CGCJob is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.CGCJob);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CGCJob.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCJob is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCJob.Text = MvwISDJobXrefView.CGCJob.Format(MvwISDJobXrefView.CGCJob.DefaultValue);
            		
            }
            
            // If the CGCJob is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CGCJob.Text == null ||
                this.CGCJob.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CGCJob.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetGLDepartmentName()
        {
            
                    
            // Set the GLDepartmentName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.GLDepartmentName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.GLDepartmentNameSpecified) {
                								
                // If the GLDepartmentName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.GLDepartmentName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.GLDepartmentName.Text = formattedValue;
                   
            } 
            
            else {
            
                // GLDepartmentName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.GLDepartmentName.Text = MvwISDJobXrefView.GLDepartmentName.Format(MvwISDJobXrefView.GLDepartmentName.DefaultValue);
            		
            }
            
            // If the GLDepartmentName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.GLDepartmentName.Text == null ||
                this.GLDepartmentName.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.GLDepartmentName.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetGLDepartmentNumber()
        {
            
                    
            // Set the GLDepartmentNumber Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.GLDepartmentNumber is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.GLDepartmentNumberSpecified) {
                								
                // If the GLDepartmentNumber is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.GLDepartmentNumber);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.GLDepartmentNumber.Text = formattedValue;
                   
            } 
            
            else {
            
                // GLDepartmentNumber is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.GLDepartmentNumber.Text = MvwISDJobXrefView.GLDepartmentNumber.Format(MvwISDJobXrefView.GLDepartmentNumber.DefaultValue);
            		
            }
            
            // If the GLDepartmentNumber is NULL or blank, then use the value specified  
            // on Properties.
            if (this.GLDepartmentNumber.Text == null ||
                this.GLDepartmentNumber.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.GLDepartmentNumber.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJobStatus()
        {
            
                    
            // Set the JobStatus Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.JobStatus is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JobStatusSpecified) {
                								
                // If the JobStatus is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.JobStatus);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.JobStatus.Text = formattedValue;
                   
            } 
            
            else {
            
                // JobStatus is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.JobStatus.Text = MvwISDJobXrefView.JobStatus.Format(MvwISDJobXrefView.JobStatus.DefaultValue);
            		
            }
            
            // If the JobStatus is NULL or blank, then use the value specified  
            // on Properties.
            if (this.JobStatus.Text == null ||
                this.JobStatus.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.JobStatus.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMailAddress()
        {
            
                    
            // Set the MailAddress Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.MailAddress is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.MailAddressSpecified) {
                								
                // If the MailAddress is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.MailAddress);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.MailAddress.Text = formattedValue;
                   
            } 
            
            else {
            
                // MailAddress is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.MailAddress.Text = MvwISDJobXrefView.MailAddress.Format(MvwISDJobXrefView.MailAddress.DefaultValue);
            		
            }
            
            // If the MailAddress is NULL or blank, then use the value specified  
            // on Properties.
            if (this.MailAddress.Text == null ||
                this.MailAddress.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.MailAddress.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMailAddress2()
        {
            
                    
            // Set the MailAddress2 Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.MailAddress2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.MailAddress2Specified) {
                								
                // If the MailAddress2 is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.MailAddress2);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.MailAddress2.Text = formattedValue;
                   
            } 
            
            else {
            
                // MailAddress2 is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.MailAddress2.Text = MvwISDJobXrefView.MailAddress2.Format(MvwISDJobXrefView.MailAddress2.DefaultValue);
            		
            }
            
            // If the MailAddress2 is NULL or blank, then use the value specified  
            // on Properties.
            if (this.MailAddress2.Text == null ||
                this.MailAddress2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.MailAddress2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMailCity()
        {
            
                    
            // Set the MailCity Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.MailCity is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.MailCitySpecified) {
                								
                // If the MailCity is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.MailCity);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.MailCity.Text = formattedValue;
                   
            } 
            
            else {
            
                // MailCity is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.MailCity.Text = MvwISDJobXrefView.MailCity.Format(MvwISDJobXrefView.MailCity.DefaultValue);
            		
            }
            
            // If the MailCity is NULL or blank, then use the value specified  
            // on Properties.
            if (this.MailCity.Text == null ||
                this.MailCity.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.MailCity.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMailState()
        {
            
                    
            // Set the MailState Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.MailState is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.MailStateSpecified) {
                								
                // If the MailState is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.MailState);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.MailState.Text = formattedValue;
                   
            } 
            
            else {
            
                // MailState is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.MailState.Text = MvwISDJobXrefView.MailState.Format(MvwISDJobXrefView.MailState.DefaultValue);
            		
            }
            
            // If the MailState is NULL or blank, then use the value specified  
            // on Properties.
            if (this.MailState.Text == null ||
                this.MailState.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.MailState.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMailZip()
        {
            
                    
            // Set the MailZip Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.MailZip is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.MailZipSpecified) {
                								
                // If the MailZip is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.MailZip);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.MailZip.Text = formattedValue;
                   
            } 
            
            else {
            
                // MailZip is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.MailZip.Text = MvwISDJobXrefView.MailZip.Format(MvwISDJobXrefView.MailZip.DefaultValue);
            		
            }
            
            // If the MailZip is NULL or blank, then use the value specified  
            // on Properties.
            if (this.MailZip.Text == null ||
                this.MailZip.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.MailZip.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOC()
        {
            
                    
            // Set the POC Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.POC is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCSpecified) {
                								
                // If the POC is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.POC);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POC.Text = formattedValue;
                   
            } 
            
            else {
            
                // POC is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POC.Text = MvwISDJobXrefView.POC.Format(MvwISDJobXrefView.POC.DefaultValue);
            		
            }
            
            // If the POC is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POC.Text == null ||
                this.POC.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POC.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOCName()
        {
            
                    
            // Set the POCName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.POCName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.IsCreated) {
                								
                // If the POCName is non-NULL, then format the value.
                // The Format method will use the Display Format
                string formattedValue = EvaluateFormula("\"<a href='mailto:\" + Trim(POCEmail) +\"?subject=\" + VPJobDesc + \" (\" + VPJob + \")&body=\" + VPJobDesc + \" (\" + VPJob + \")'>\" + POCName + \"</a>\"", this.DataSource);
                    
                this.POCName.Text = formattedValue;
                   
            } 
            
            else {
            
                // POCName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POCName.Text = MvwISDJobXrefView.POCName.Format(MvwISDJobXrefView.POCName.DefaultValue);
            		
            }
            
            // If the POCName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POCName.Text == null ||
                this.POCName.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POCName.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSalesPerson()
        {
            
                    
            // Set the SalesPerson Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.SalesPerson is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SalesPersonSpecified) {
                								
                // If the SalesPerson is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.SalesPerson);
                                
                this.SalesPerson.Text = formattedValue;
                   
            } 
            
            else {
            
                // SalesPerson is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SalesPerson.Text = MvwISDJobXrefView.SalesPerson.Format(MvwISDJobXrefView.SalesPerson.DefaultValue);
            		
            }
            
            // If the SalesPerson is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SalesPerson.Text == null ||
                this.SalesPerson.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SalesPerson.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSalesPersonName()
        {
            
                    
            // Set the SalesPersonName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.SalesPersonName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.IsCreated) {
                								
                // If the SalesPersonName is non-NULL, then format the value.
                // The Format method will use the Display Format
                string formattedValue = EvaluateFormula("\"<a href='mailto:\" + Trim(SalesPersonEmail) +\"?subject=\" + VPJobDesc + \" (\" + VPJob + \")&body=\" + VPJobDesc + \" (\" + VPJob + \")'>\" + SalesPersonName + \"</a>\"", this.DataSource);
                    
                this.SalesPersonName.Text = formattedValue;
                   
            } 
            
            else {
            
                // SalesPersonName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SalesPersonName.Text = MvwISDJobXrefView.SalesPersonName.Format(MvwISDJobXrefView.SalesPersonName.DefaultValue);
            		
            }
            
            // If the SalesPersonName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SalesPersonName.Text == null ||
                this.SalesPersonName.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SalesPersonName.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPCo()
        {
            
                    
            // Set the VPCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCoSpecified) {
                								
                // If the VPCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCo.Text = MvwISDJobXrefView.VPCo.Format(MvwISDJobXrefView.VPCo.DefaultValue);
            		
            }
            
            // If the VPCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPCo.Text == null ||
                this.VPCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPCustomer()
        {
            
                    
            // Set the VPCustomer Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPCustomer is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerSpecified) {
                								
                // If the VPCustomer is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPCustomer);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCustomer.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomer is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomer.Text = MvwISDJobXrefView.VPCustomer.Format(MvwISDJobXrefView.VPCustomer.DefaultValue);
            		
            }
            
            // If the VPCustomer is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPCustomer.Text == null ||
                this.VPCustomer.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPCustomer.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPCustomerName()
        {
            
                    
            // Set the VPCustomerName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPCustomerName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerNameSpecified) {
                								
                // If the VPCustomerName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPCustomerName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCustomerName.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomerName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomerName.Text = MvwISDJobXrefView.VPCustomerName.Format(MvwISDJobXrefView.VPCustomerName.DefaultValue);
            		
            }
            
            // If the VPCustomerName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPCustomerName.Text == null ||
                this.VPCustomerName.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPCustomerName.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPJob()
        {
            
                    
            // Set the VPJob Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPJob is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPJobSpecified) {
                								
                // If the VPJob is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPJob);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPJob.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPJob is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPJob.Text = MvwISDJobXrefView.VPJob.Format(MvwISDJobXrefView.VPJob.DefaultValue);
            		
            }
            
            // If the VPJob is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPJob.Text == null ||
                this.VPJob.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPJob.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPJobDesc()
        {
            
                    
            // Set the VPJobDesc Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPJobDesc is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPJobDescSpecified) {
                								
                // If the VPJobDesc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPJobDesc);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPJobDesc.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPJobDesc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPJobDesc.Text = MvwISDJobXrefView.VPJobDesc.Format(MvwISDJobXrefView.VPJobDesc.DefaultValue);
            		
            }
            
            // If the VPJobDesc is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPJobDesc.Text == null ||
                this.VPJobDesc.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPJobDesc.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMvwISDJobXrefTabContainer()    
        
        {
                            
                   
            if (EvaluateFormula("URL(\"TabVisible\")").ToLower() == "true") 
                MiscUtils.FindControlRecursively(this, "MvwISDJobXrefTabContainer").Visible = true;
            else if (EvaluateFormula("URL(\"TabVisible\")").ToLower() == "false") 
                MiscUtils.FindControlRecursively(this, "MvwISDJobXrefTabContainer").Visible = false;
         
  
        }      
      
        public virtual void SetMvwISDCustomerXrefRecordControl()           
        
        {        
            if (MvwISDCustomerXrefRecordControl.Visible)
            {
                MvwISDCustomerXrefRecordControl.LoadData();
                MvwISDCustomerXrefRecordControl.DataBind();
            }
        }
      
        public BaseClasses.Data.DataSource.EvaluateFormulaDelegate EvaluateFormulaDelegate;

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables, bool includeDS, FormulaEvaluator e)
        {
            if (e == null)
                e = new FormulaEvaluator();

            e.Variables.Clear();
            // add variables for formula evaluation
            if (variables != null)
            {
                System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<string, object>> enumerator = variables.GetEnumerator();
                while (enumerator.MoveNext())
                {
                    e.Variables.Add(enumerator.Current.Key, enumerator.Current.Value);
                }
            }
            
            
            if (includeDS)
            {
                
            }
            
            // All variables referred to in the formula are expected to be
            // properties of the DataSource.  For example, referring to
            // UnitPrice as a variable will refer to DataSource.UnitPrice
            if (dataSourceForEvaluate == null)
                e.DataSource = this.DataSource;
            else
                e.DataSource = dataSourceForEvaluate;

            // Define the calling control.  This is used to add other 
            // related table and record controls as variables.
            e.CallingControl = this;

            object resultObj = e.Evaluate(formula);
            if (resultObj == null)
                return "";
            
            if ( !string.IsNullOrEmpty(format) && (string.IsNullOrEmpty(formula) || formula.IndexOf("Format(") < 0) )
                return FormulaUtils.Format(resultObj, format);
            else
                return resultObj.ToString();
        }
                
        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables, bool includeDS)
        {
          return EvaluateFormula(formula, dataSourceForEvaluate, format, variables, includeDS, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables)
        {
          return EvaluateFormula(formula, dataSourceForEvaluate, format, variables, true, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, format, null, true, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, System.Collections.Generic.IDictionary<string, object> variables, FormulaEvaluator e)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, null, variables, true, e);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, null, null, true, null);
        }

        public virtual string EvaluateFormula(string formula, bool includeDS)
        {
          return this.EvaluateFormula(formula, null, null, null, includeDS, null);
        }

        public virtual string EvaluateFormula(string formula)
        {
          return this.EvaluateFormula(formula, null, null, null, true, null);
        }
        
      

        public virtual void RegisterPostback()
        {
            
        }
    
        

        public virtual void SaveData()
        {
            // Saves the associated record in the database.
            // SaveData calls Validate and Get methods - so it may be more appropriate to
            // customize those methods.

            // 1. Load the existing record from the database. Since we save the entire record, this ensures 
            // that fields that are not displayed are also properly initialized.
            this.LoadData();
        
            // The checksum is used to ensure the record was not changed by another user.
            if (this.DataSource != null && this.DataSource.GetCheckSumValue() != null) {
                if (this.CheckSum != null && this.CheckSum != this.DataSource.GetCheckSumValue().Value) {
                    throw new Exception(Page.GetResourceValue("Err:RecChangedByOtherUser", "VPLookup"));
                }
            }
        
          
            // 2. Perform any custom validation.
            this.Validate();

            
            // 3. Set the values in the record with data from UI controls.
            // This calls the Get() method for each of the user interface controls.
            this.GetUIData();
   
            // 4. Save in the database.
            // We should not save the record if the data did not change. This
            // will save a database hit and avoid triggering any database triggers.
            
            if (this.DataSource.IsAnyValueChanged) {
                // Save record to database but do not commit yet.
                // Auto generated ids are available after saving for use by child (dependent) records.
                this.DataSource.Save();
                
                // Set the DataChanged flag to True for the for the related panels so they get refreshed as well.
                ((MvwISDJobXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDJobXrefTableControl")).DataChanged = true;
                ((MvwISDJobXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDJobXrefTableControl")).ResetData = true;
            }
            
      
            // update session or cookie by formula
             		  
      
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            this.ResetData = true;
            
            this.CheckSum = "";
            // For Master-Detail relationships, save data on the Detail table(s)            
          MvwISDCustomerXrefRecordControl recMvwISDCustomerXrefRecordControl = (MvwISDCustomerXrefRecordControl)(MiscUtils.FindControlRecursively(this, "MvwISDCustomerXrefRecordControl"));
        recMvwISDCustomerXrefRecordControl.SaveData();
        
        }

        public virtual void GetUIData()
        {
            // The GetUIData method retrieves the updated values from the user interface 
            // controls into a database record in preparation for saving or updating.
            // To do this, it calls the Get methods for each of the field displayed on 
            // the webpage.  It is better to make changes in the Get methods, rather 
            // than making changes here.
      
            // Call the Get methods for each of the user interface controls.
        
            GetCGCCo();
            GetCGCJob();
            GetGLDepartmentName();
            GetGLDepartmentNumber();
            GetJobStatus();
            GetMailAddress();
            GetMailAddress2();
            GetMailCity();
            GetMailState();
            GetMailZip();
            GetPOC();
            GetPOCName();
            GetSalesPerson();
            GetSalesPersonName();
            GetVPCo();
            GetVPCustomer();
            GetVPCustomerName();
            GetVPJob();
            GetVPJobDesc();
        }
        
        
        public virtual void GetCGCCo()
        {
            
        }
                
        public virtual void GetCGCJob()
        {
            
        }
                
        public virtual void GetGLDepartmentName()
        {
            
        }
                
        public virtual void GetGLDepartmentNumber()
        {
            
        }
                
        public virtual void GetJobStatus()
        {
            
        }
                
        public virtual void GetMailAddress()
        {
            
        }
                
        public virtual void GetMailAddress2()
        {
            
        }
                
        public virtual void GetMailCity()
        {
            
        }
                
        public virtual void GetMailState()
        {
            
        }
                
        public virtual void GetMailZip()
        {
            
        }
                
        public virtual void GetPOC()
        {
            
        }
                
        public virtual void GetPOCName()
        {
            
        }
                
        public virtual void GetSalesPerson()
        {
            
        }
                
        public virtual void GetSalesPersonName()
        {
            
        }
                
        public virtual void GetVPCo()
        {
            
        }
                
        public virtual void GetVPCustomer()
        {
            
        }
                
        public virtual void GetVPCustomerName()
        {
            
        }
                
        public virtual void GetVPJob()
        {
            
        }
                
        public virtual void GetVPJobDesc()
        {
            
        }
                

      // To customize, override this method in MvwISDJobXrefTableControlRow.
      
        public virtual WhereClause CreateWhereClause()
         
        {
//Bryan Check
    
            bool hasFiltersMvwISDCustomerXrefRecordControl = false;
            hasFiltersMvwISDCustomerXrefRecordControl = hasFiltersMvwISDCustomerXrefRecordControl && false; // suppress warning
      
            bool hasFiltersMvwISDJobXrefTableControl = false;
            hasFiltersMvwISDJobXrefTableControl = hasFiltersMvwISDJobXrefTableControl && false; // suppress warning
      
//
        
            return null;
        
        }
        
        
    
        public virtual void Validate()
        {
            // Add custom validation for any control within this panel.
            // Example.  If you have a State ASP:Textbox control
            // if (this.State.Text != "CA")
            //    throw new Exception("State must be CA (California).");
            // The Validate method is common across all controls within
            // this panel so you can validate multiple fields, but report
            // one error message.
            
            
            
        }

        public virtual void Delete()
        {
        
            if (this.IsNewRecord) {
                return;
            }

            KeyValue pkValue = KeyValue.XmlToKey(this.RecordUniqueId);
          MvwISDJobXrefView.DeleteRecord(pkValue);
          
              
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            ((MvwISDJobXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDJobXrefTableControl")).DataChanged = true;
            ((MvwISDJobXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDJobXrefTableControl")).ResetData = true;
        }

        protected virtual void Control_PreRender(object sender, System.EventArgs e)
        {
            // PreRender event is raised just before page is being displayed.
            try {
                DbUtils.StartTransaction();
                this.RegisterPostback();
                if (!this.Page.ErrorOnPage && (this.Page.IsPageRefresh || this.DataChanged || this.ResetData)) {
                  
                
                    // Re-load the data and update the web page if necessary.
                    // This is typically done during a postback (filter, search button, sort, pagination button).
                    // In each of the other click handlers, simply set DataChanged to True to reload the data.
                    this.LoadData();
                    this.DataBind();
                }
                				
            } catch (Exception ex) {
                BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
            } finally {
                DbUtils.EndTransaction();
            }
        }
        
            
        protected override void SaveControlsToSession()
        {
            base.SaveControlsToSession();
        
    
            // Save pagination state to session.
          
        }
        
        
    
        protected override void ClearControlsFromSession()
        {
            base.ClearControlsFromSession();

        

            // Clear pagination state from session.
        
        }
        
        protected override void LoadViewState(object savedState)
        {
            base.LoadViewState(savedState);
            string isNewRecord = (string)ViewState["IsNewRecord"];
            if (isNewRecord != null && isNewRecord.Length > 0) {
                this.IsNewRecord = Boolean.Parse(isNewRecord);
            }
        
            string myCheckSum = (string)ViewState["CheckSum"];
            if (myCheckSum != null && myCheckSum.Length > 0) {
                this.CheckSum = myCheckSum;
            }
        
    
            // Load view state for pagination control.
                 
        }

        protected override object SaveViewState()
        {
            ViewState["IsNewRecord"] = this.IsNewRecord.ToString();
            ViewState["CheckSum"] = this.CheckSum;
        

            // Load view state for pagination control.
               
            return base.SaveViewState();
        }

        
    
        // Generate set method for buttons
        
        public virtual void SetExpandRowButton()                
              
        {
        
   
        }
            
        public virtual void SetViewRowButton()                
              
        {
        
   
        }
            
        // event handler for ImageButton
        public virtual void ExpandRowButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                MvwISDJobXrefTableControl panelControl = (MiscUtils.GetParentControlObject(this, "MvwISDJobXrefTableControl") as MvwISDJobXrefTableControl);

          MvwISDJobXrefTableControlRow[] repeatedRows = panelControl.GetRecordControls();
          foreach (MvwISDJobXrefTableControlRow repeatedRow in repeatedRows)
          {
              System.Web.UI.Control altRow = (MiscUtils.FindControlRecursively(repeatedRow, "MvwISDJobXrefTableControlAltRow") as System.Web.UI.Control);
              if (altRow != null)
              {
                  if (sender == repeatedRow.ExpandRowButton)
                      altRow.Visible = !altRow.Visible;
                  
                  if (altRow.Visible)
                  {
                   
                     repeatedRow.ExpandRowButton.ImageUrl = "../Images/icon_expandcollapserow.gif";
                     repeatedRow.ExpandRowButton.Attributes.Add("onmouseover", "this.src='../Images/icon_expandcollapserow_over.gif'");
                     repeatedRow.ExpandRowButton.Attributes.Add("onmouseout", "this.src='../Images/icon_expandcollapserow.gif'");
                           
                  }
                  else
                  {
                   
                     repeatedRow.ExpandRowButton.ImageUrl = "../Images/icon_expandcollapserow2.gif";
                     repeatedRow.ExpandRowButton.Attributes.Add("onmouseover", "this.src='../Images/icon_expandcollapserow_over2.gif'");
                     repeatedRow.ExpandRowButton.Attributes.Add("onmouseout", "this.src='../Images/icon_expandcollapserow2.gif'");
                   
                  }
            
              }
              else
              {
                  this.Page.Response.Redirect("../Shared/ConfigureCollapseExpandRowBtn.aspx");
              }
          }
          
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void ViewRowButton_Click(object sender, ImageClickEventArgs args)
        {
              
            // The redirect URL is set on the Properties, Custom Properties or Actions.
            // The ModifyRedirectURL call resolves the parameters before the
            // Response.Redirect redirects the page to the URL.  
            // Any code after the Response.Redirect call will not be executed, since the page is
            // redirected to the URL.
            
            string url = @"../mvwISDJobXref/Show-MvwISDJobXref.aspx?MvwISDJobXref={PK}";
            
            if (!string.IsNullOrEmpty(this.Page.Request["RedirectStyle"]))
                url += "&RedirectStyle=" + this.Page.Request["RedirectStyle"];
            
        bool shouldRedirect = true;
        string target = null;
        if (target == null) target = ""; // avoid warning on VS
      
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                
                url = this.ModifyRedirectUrl(url, "",true);
                url = this.Page.ModifyRedirectUrl(url, "",true);
              
            } catch (Exception ex) {
                  // Upon error, rollback the transaction
                  this.Page.RollBackTransaction(sender);
                  shouldRedirect = false;
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
                DbUtils.EndTransaction();
            }
            if (shouldRedirect) {
                this.Page.ShouldSaveControlsToSession = true;
      this.Page.Response.Redirect(url);
        
            }
        
        }
            
            
        
  
        private Hashtable _PreviousUIData = new Hashtable();
        public virtual Hashtable PreviousUIData {
            get {
                return this._PreviousUIData;
            }
            set {
                this._PreviousUIData = value;
            }
        }
  

        
        public String RecordUniqueId {
            get {
                return (string)this.ViewState["BaseMvwISDJobXrefTableControlRow_Rec"];
            }
            set {
                this.ViewState["BaseMvwISDJobXrefTableControlRow_Rec"] = value;
            }
        }
        
        public MvwISDJobXrefRecord DataSource {
            get {
                return (MvwISDJobXrefRecord)(this._DataSource);
            }
            set {
                this._DataSource = value;
            }
        }
        

        private string _checkSum;
        public virtual string CheckSum {
            get {
                return (this._checkSum);
            }
            set {
                this._checkSum = value;
            }
        }
    
        private int _TotalPages;
        public virtual int TotalPages {
            get {
                return (this._TotalPages);
            }
            set {
                this._TotalPages = value;
            }
        }
        
        private int _PageIndex;
        public virtual int PageIndex {
            get {
                return (this._PageIndex);
            }
            set {
                this._PageIndex = value;
            }
        }
        
        private bool _DisplayLastPage;
        public virtual bool DisplayLastPage {
            get {
                return (this._DisplayLastPage);
            }
            set {
                this._DisplayLastPage = value;
            }
        }
        
        
    
        private KeyValue selectedParentKeyValue;
        public KeyValue SelectedParentKeyValue
        {
            get
            {
                return this.selectedParentKeyValue;
            }
            set
            {
                this.selectedParentKeyValue = value;
            }
        }
       
#region "Helper Properties"
        
        public System.Web.UI.WebControls.Literal CGCCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal CGCJob {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCJob");
            }
        }
            
        public System.Web.UI.WebControls.ImageButton ExpandRowButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ExpandRowButton");
            }
        }
        
        public System.Web.UI.WebControls.Literal GLDepartmentName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLDepartmentName");
            }
        }
            
        public System.Web.UI.WebControls.Literal GLDepartmentNumber {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLDepartmentNumber");
            }
        }
            
        public System.Web.UI.WebControls.Literal JobStatus {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobStatus");
            }
        }
            
        public System.Web.UI.WebControls.Literal MailAddress {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailAddress");
            }
        }
            
        public System.Web.UI.WebControls.Literal MailAddress2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailAddress2");
            }
        }
            
        public System.Web.UI.WebControls.Literal MailCity {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailCity");
            }
        }
            
        public System.Web.UI.WebControls.Literal MailState {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailState");
            }
        }
            
        public System.Web.UI.WebControls.Literal MailZip {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailZip");
            }
        }
            
        public MvwISDCustomerXrefRecordControl MvwISDCustomerXrefRecordControl {
            get {
                return (MvwISDCustomerXrefRecordControl)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDCustomerXrefRecordControl");
            }
        }
        
        public AjaxControlToolkit.TabContainer MvwISDJobXrefTabContainer {
            get {
                return (AjaxControlToolkit.TabContainer)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDJobXrefTabContainer");
            }
        }
        
        public System.Web.UI.WebControls.Literal POC {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POC");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCName");
            }
        }
            
        public System.Web.UI.WebControls.Literal SalesPerson {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPerson");
            }
        }
            
        public System.Web.UI.WebControls.Literal SalesPersonName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonName");
            }
        }
            
        public System.Web.UI.WebControls.ImageButton ViewRowButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ViewRowButton");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomer {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomer");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomerName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerName");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPJob {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJob");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPJobDesc {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobDesc");
            }
        }
            
    #endregion

    #region "Helper Functions"
    public override string ModifyRedirectUrl(string url, string arg, bool bEncrypt)
    {
        return this.Page.EvaluateExpressions(url, arg, bEncrypt, this);
    }

    public override string ModifyRedirectUrl(string url, string arg, bool bEncrypt,bool includeSession)
    {
        return this.Page.EvaluateExpressions(url, arg, bEncrypt, this,includeSession);
    }

    public override string EvaluateExpressions(string url, string arg, bool bEncrypt)
    {
    MvwISDJobXrefRecord rec = null;
             
            try {
                rec = this.GetRecord();
            }
            catch (Exception ) {
                // Do Nothing
            }
            
            if (rec == null && url.IndexOf("{") >= 0) {
                // Localization.
                
                throw new Exception(Page.GetResourceValue("Err:RecDataSrcNotInitialized", "VPLookup"));
                    
            }
        
            return EvaluateExpressions(url, arg, rec, bEncrypt);
        
    }


    public override string EvaluateExpressions(string url, string arg, bool bEncrypt,bool includeSession)
    {
    MvwISDJobXrefRecord rec = null;
    
          try {
               rec = this.GetRecord();
          }
          catch (Exception ) {
          // Do Nothing
          }

          if (rec == null && url.IndexOf("{") >= 0) {
          // Localization.
    
              throw new Exception(Page.GetResourceValue("Err:RecDataSrcNotInitialized", "VPLookup"));
      
          }
    
          if (includeSession)
          {
              return EvaluateExpressions(url, arg, rec, bEncrypt);
          }
          else
          {
              return EvaluateExpressions(url, arg, rec, bEncrypt,includeSession);
          }
    
    }

    
        public virtual MvwISDJobXrefRecord GetRecord()
             
        {
        
            if (this.DataSource != null) {
                return this.DataSource;
            }
            
            if (this.RecordUniqueId != null) {
              
                return MvwISDJobXrefView.GetRecord(this.RecordUniqueId, true);
              
            }
            
            // Localization.
            
            throw new Exception(Page.GetResourceValue("Err:RetrieveRec", "VPLookup"));
                
        }

        public new BaseApplicationPage Page
        {
            get {
                return ((BaseApplicationPage)base.Page);
            }
        }

#endregion

}

  
// Base class for the MvwISDJobXrefTableControl control on the Show_MvwISDJobXref_Table page.
// Do not modify this class. Instead override any method in MvwISDJobXrefTableControl.
public class BaseMvwISDJobXrefTableControl : VPLookup.UI.BaseApplicationTableControl
{
         

       public BaseMvwISDJobXrefTableControl()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
      
    
           // Setup the filter and search.
        
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.GLDepartmentNumberFilter)) 				
                    initialVal = this.GetFromSession(this.GLDepartmentNumberFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"GLDepartmentNumber\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    this.GLDepartmentNumberFilter.Items.Add(new ListItem(initialVal, initialVal));
                        
                    this.GLDepartmentNumberFilter.SelectedValue = initialVal;
                            
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.JobStatusFilter)) 				
                    initialVal = this.GetFromSession(this.JobStatusFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"JobStatus\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    this.JobStatusFilter.Items.Add(new ListItem(initialVal, initialVal));
                        
                    this.JobStatusFilter.SelectedValue = initialVal;
                            
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.MailStateFilter)) 				
                    initialVal = this.GetFromSession(this.MailStateFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"MailState\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    string[] MailStateFilteritemListFromSession = initialVal.Split(',');
                    int index = 0;
                    foreach (string item in MailStateFilteritemListFromSession)
                    {
                        if (index == 0 && item.ToString().Equals(""))
                        {
                            // do nothing
                        }
                        else
                        {
                            this.MailStateFilter.Items.Add(item);
                            this.MailStateFilter.Items[index].Selected = true;
                            index += 1;
                        }
                    }
                    foreach (ListItem listItem in this.MailStateFilter.Items)
                    {
                        listItem.Selected = true;
                    }
                        
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.POCNameFilter)) 				
                    initialVal = this.GetFromSession(this.POCNameFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"POCName\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    string[] POCNameFilteritemListFromSession = initialVal.Split(',');
                    int index = 0;
                    foreach (string item in POCNameFilteritemListFromSession)
                    {
                        if (index == 0 && item.ToString().Equals(""))
                        {
                            // do nothing
                        }
                        else
                        {
                            this.POCNameFilter.Items.Add(item);
                            this.POCNameFilter.Items[index].Selected = true;
                            index += 1;
                        }
                    }
                    foreach (ListItem listItem in this.POCNameFilter.Items)
                    {
                        listItem.Selected = true;
                    }
                        
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.SalesPersonNameFilter)) 				
                    initialVal = this.GetFromSession(this.SalesPersonNameFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"SalesPersonName\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    string[] SalesPersonNameFilteritemListFromSession = initialVal.Split(',');
                    int index = 0;
                    foreach (string item in SalesPersonNameFilteritemListFromSession)
                    {
                        if (index == 0 && item.ToString().Equals(""))
                        {
                            // do nothing
                        }
                        else
                        {
                            this.SalesPersonNameFilter.Items.Add(item);
                            this.SalesPersonNameFilter.Items[index].Selected = true;
                            index += 1;
                        }
                    }
                    foreach (ListItem listItem in this.SalesPersonNameFilter.Items)
                    {
                        listItem.Selected = true;
                    }
                        
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.SearchText)) 				
                    initialVal = this.GetFromSession(this.SearchText);
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    this.SearchText.Text = initialVal;
                            
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.VPCustomerNameFilter)) 				
                    initialVal = this.GetFromSession(this.VPCustomerNameFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"VPCustomerName\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    string[] VPCustomerNameFilteritemListFromSession = initialVal.Split(',');
                    int index = 0;
                    foreach (string item in VPCustomerNameFilteritemListFromSession)
                    {
                        if (index == 0 && item.ToString().Equals(""))
                        {
                            // do nothing
                        }
                        else
                        {
                            this.VPCustomerNameFilter.Items.Add(item);
                            this.VPCustomerNameFilter.Items[index].Selected = true;
                            index += 1;
                        }
                    }
                    foreach (ListItem listItem in this.VPCustomerNameFilter.Items)
                    {
                        listItem.Selected = true;
                    }
                        
                    }
            }


      
      
            // Control Initializations.
            // Initialize the table's current sort order.

            if (this.InSession(this, "Order_By"))
                this.CurrentSortOrder = OrderBy.FromXmlString(this.GetFromSession(this, "Order_By", null));         
            else
            {
                   
                this.CurrentSortOrder = new OrderBy(true, false);
            
        }


    
            // Setup default pagination settings.
    
            this.PageSize = Convert.ToInt32(this.GetFromSession(this, "Page_Size", "30"));
            this.PageIndex = Convert.ToInt32(this.GetFromSession(this, "Page_Index", "0"));
          
                    
            this.ClearControlsFromSession();
        }

        protected virtual void Control_Load(object sender, EventArgs e)
        {
        
            SaveControlsToSession_Ajax();
        
            // Setup the pagination events.
            
                    this.Pagination.FirstPage.Click += Pagination_FirstPage_Click;
                        
                    this.Pagination.LastPage.Click += Pagination_LastPage_Click;
                        
                    this.Pagination.NextPage.Click += Pagination_NextPage_Click;
                        
                    this.Pagination.PageSizeButton.Click += Pagination_PageSizeButton_Click;
                        
                    this.Pagination.PreviousPage.Click += Pagination_PreviousPage_Click;
                                    
            string url = "";
            // Setup the sorting events.
          
              this.CGCCoLabel.Click += CGCCoLabel_Click;
            
              this.CGCJobLabel.Click += CGCJobLabel_Click;
            
              this.GLDepartmentNameLabel.Click += GLDepartmentNameLabel_Click;
            
              this.GLDepartmentNumberLabel.Click += GLDepartmentNumberLabel_Click;
            
              this.JobStatusLabel1.Click += JobStatusLabel1_Click;
            
              this.MailAddress2Label.Click += MailAddress2Label_Click;
            
              this.MailAddressLabel.Click += MailAddressLabel_Click;
            
              this.MailCityLabel.Click += MailCityLabel_Click;
            
              this.MailStateLabel.Click += MailStateLabel_Click;
            
              this.MailZipLabel.Click += MailZipLabel_Click;
            
              this.POCLabel.Click += POCLabel_Click;
            
              this.POCNameLabel.Click += POCNameLabel_Click;
            
              this.SalesPersonLabel.Click += SalesPersonLabel_Click;
            
              this.SalesPersonNameLabel.Click += SalesPersonNameLabel_Click;
            
              this.VPCoLabel.Click += VPCoLabel_Click;
            
              this.VPCustomerLabel.Click += VPCustomerLabel_Click;
            
              this.VPCustomerNameLabel.Click += VPCustomerNameLabel_Click;
            
              this.VPJobDescLabel.Click += VPJobDescLabel_Click;
            
              this.VPJobLabel.Click += VPJobLabel_Click;
            
            // Setup the button events.
          
                    this.ExcelButton.Click += ExcelButton_Click;
                        
                    this.ImportButton.Click += ImportButton_Click;
                        
                    this.PDFButton.Click += PDFButton_Click;
                        
                    this.ResetButton.Click += ResetButton_Click;
                        
                    this.SearchButton.Click += SearchButton_Click;
                        
                    this.WordButton.Click += WordButton_Click;
                        
                    this.ActionsButton.Button.Click += ActionsButton_Click;
                        
                    this.FilterButton.Button.Click += FilterButton_Click;
                        
                    this.FiltersButton.Button.Click += FiltersButton_Click;
                        
            this.GLDepartmentNumberFilter.SelectedIndexChanged += new EventHandler(GLDepartmentNumberFilter_SelectedIndexChanged);
            
            this.JobStatusFilter.SelectedIndexChanged += new EventHandler(JobStatusFilter_SelectedIndexChanged);
            
              this.MailStateFilter.SelectedIndexChanged += MailStateFilter_SelectedIndexChanged;                  
                
              this.POCNameFilter.SelectedIndexChanged += POCNameFilter_SelectedIndexChanged;                  
                
              this.SalesPersonNameFilter.SelectedIndexChanged += SalesPersonNameFilter_SelectedIndexChanged;                  
                
              this.VPCustomerNameFilter.SelectedIndexChanged += VPCustomerNameFilter_SelectedIndexChanged;                  
                        
        
         //' Setup events for others
            AjaxControlToolkit.ToolkitScriptManager.RegisterStartupScript(this, this.GetType(), "SearchTextSearchBoxText", "setSearchBoxText(\"" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "\", \"" + SearchText.ClientID + "\");", true);
          
    
    
    
        }

        public virtual void LoadData()
        {
          
            // Read data from database. Returns an array of records that can be assigned
            // to the DataSource table control property.
            try {
                  CompoundFilter joinFilter = CreateCompoundJoinFilter();
                
                  // The WHERE clause will be empty when displaying all records in table.
                  WhereClause wc = CreateWhereClause();
                  if (wc != null && !wc.RunQuery) {
                        // Initialize an empty array of records
                      ArrayList alist = new ArrayList(0);
                      Type myrec = typeof(VPLookup.Business.MvwISDJobXrefRecord);
                      this.DataSource = (MvwISDJobXrefRecord[])(alist.ToArray(myrec));
                      // Add records to the list if needed.
                      this.AddNewRecords();
                      this._TotalRecords = 0;
                      this._TotalPages = 0;
                      return;
                  }

                  // Call OrderBy to determine the order - either use the order defined
                  // on the Query Wizard, or specified by user (by clicking on column heading)

                  OrderBy orderBy = CreateOrderBy();

      
                // Get the pagesize from the pagesize control.
                this.GetPageSize();
                if (this.DisplayLastPage)
                {
                    int totalRecords = this._TotalRecords < 0? GetRecordCount(CreateCompoundJoinFilter(), CreateWhereClause()): this._TotalRecords;
                     
                        int totalPages = Convert.ToInt32(Math.Ceiling(Convert.ToDouble(totalRecords) / Convert.ToDouble(this.PageSize)));
                       
                    this.PageIndex = totalPages - 1;                
                }
                
                // Make sure PageIndex (current page) and PageSize are within bounds.
                if (this.PageIndex < 0)
                    this.PageIndex = 0;
                if (this.PageSize < 1)
                    this.PageSize = 1;
                
                
                // Retrieve the records and set the table DataSource.
                // Only PageSize records are fetched starting at PageIndex (zero based).
                if (this.AddNewRecord > 0) {
                    // Make sure to preserve the previously entered data on new rows.
                    ArrayList postdata = new ArrayList(0);
                    foreach (MvwISDJobXrefTableControlRow rc in this.GetRecordControls()) {
                        if (!rc.IsNewRecord) {
                            rc.DataSource = rc.GetRecord();
                            rc.GetUIData();
                            postdata.Add(rc.DataSource);
                            UIData.Add(rc.PreservedUIData());
                        }
                    }
                    Type myrec = typeof(VPLookup.Business.MvwISDJobXrefRecord);
                    this.DataSource = (MvwISDJobXrefRecord[])(postdata.ToArray(myrec));
                } 
                else {
                    // Get the records from the database
                    
                        this.DataSource = GetRecords(joinFilter, wc, orderBy, this.PageIndex, this.PageSize);
                                          
                }
                
                // if the datasource contains no records contained in database, then load the last page.
                if (DbUtils.GetCreatedRecords(this.DataSource).Length == 0 && !this.DisplayLastPage)
                {
                      this.DisplayLastPage = true;
                      LoadData();
                }
                else
                {
                    // Add any new rows desired by the user.
                    this.AddNewRecords();
                    
    
                    // Initialize the page and grand totals. now
                
                }                 
                

    
            } catch (Exception ex) {
                // Report the error message to the end user
                    String msg = ex.Message;
                    if (ex.InnerException != null)
                        msg += " InnerException: " + ex.InnerException.Message;

                    throw new Exception(msg, ex.InnerException);
            }
        }
        
        public virtual MvwISDJobXrefRecord[] GetRecords(BaseFilter join, WhereClause where, OrderBy orderBy, int pageIndex, int pageSize)
        {    
            // by default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               
    
            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecordCount as well
            // selCols.Add(MvwISDJobXrefView.Column1, true);          
            // selCols.Add(MvwISDJobXrefView.Column2, true);          
            // selCols.Add(MvwISDJobXrefView.Column3, true);          
            

            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                  
            {
              
                return MvwISDJobXrefView.GetRecords(join, where, orderBy, this.PageIndex, this.PageSize);
                 
            }
            else
            {
                MvwISDJobXrefView databaseTable = new MvwISDJobXrefView();
                databaseTable.SelectedColumns.Clear();
                databaseTable.SelectedColumns.AddRange(selCols);
                
            
                
                ArrayList recList; 
                orderBy.ExpandForeignKeyColums = false;
                recList = databaseTable.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
                return (recList.ToArray(typeof(MvwISDJobXrefRecord)) as MvwISDJobXrefRecord[]);
            }            
            
        }
        
        
        public virtual int GetRecordCount(BaseFilter join, WhereClause where)
        {

            // By default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               


            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecords as well
            // selCols.Add(MvwISDJobXrefView.Column1, true);          
            // selCols.Add(MvwISDJobXrefView.Column2, true);          
            // selCols.Add(MvwISDJobXrefView.Column3, true);          


            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                     
            
                return MvwISDJobXrefView.GetRecordCount(join, where);
            else
            {
                MvwISDJobXrefView databaseTable = new MvwISDJobXrefView();
                databaseTable.SelectedColumns.Clear();
                databaseTable.SelectedColumns.AddRange(selCols);        
                
                return (int)(databaseTable.GetRecordListCount(join, where.GetFilter(), null, null));
            }

        }
        
      
    
      public override void DataBind()
      {
          // The DataBind method binds the user interface controls to the values
          // from the database record for each row in the table.  To do this, it calls the
          // DataBind for each of the rows.
          // DataBind also populates any filters above the table, and sets the pagination
          // control to the correct number of records and the current page number.

          base.DataBind();

          // Make sure that the DataSource is initialized.
          if (this.DataSource == null) {
              return;
          }
          
          //  LoadData for DataSource for chart and report if they exist
               

            // Setup the pagination controls.
            BindPaginationControls();

    
        
        // Bind the repeater with the list of records to expand the UI.
        System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDJobXrefTableControlRepeater"));
        if (rep == null){return;}
        rep.DataSource = this.DataSource;
        rep.DataBind();
          
        int index = 0;
        foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
        {
            // Loop through all rows in the table, set its DataSource and call DataBind().
            MvwISDJobXrefTableControlRow recControl = (MvwISDJobXrefTableControlRow)(repItem.FindControl("MvwISDJobXrefTableControlRow"));
            recControl.DataSource = this.DataSource[index];            
            if (this.UIData.Count > index)
                recControl.PreviousUIData = this.UIData[index];
            recControl.DataBind();
            
           
            recControl.Visible = !this.InDeletedRecordIds(recControl);
        
            index++;
        }
           
    
            // Call the Set methods for each controls on the panel
        
                
                SetCGCCoLabel();
                SetCGCJobLabel();
                
                
                
                SetGLDepartmentNameLabel();
                SetGLDepartmentNumberFilter();
                SetGLDepartmentNumberLabel();
                SetGLDepartmentNumberLabel1();
                
                SetJobStatusFilter();
                SetJobStatusLabel();
                SetJobStatusLabel1();
                SetMailAddress2Label();
                SetMailAddressLabel();
                SetMailCityLabel();
                SetMailStateFilter();
                SetMailStateLabel();
                SetMailStateLabel1();
                SetMailZipLabel();
                
                
                SetPOCLabel();
                SetPOCNameFilter();
                SetPOCNameLabel();
                SetPOCNameLabel1();
                
                SetSalesPersonLabel();
                SetSalesPersonNameFilter();
                SetSalesPersonNameLabel();
                SetSalesPersonNameLabel1();
                
                SetSearchText();
                
                SetVPCoLabel();
                SetVPCustomerLabel();
                SetVPCustomerNameFilter();
                SetVPCustomerNameLabel();
                SetVPCustomerNameLabel1();
                SetVPJobDescLabel();
                SetVPJobLabel();
                
                SetExcelButton();
              
                SetImportButton();
              
                SetPDFButton();
              
                SetResetButton();
              
                SetSearchButton();
              
                SetWordButton();
              
                SetActionsButton();
              
                SetFilterButton();
              
                SetFiltersButton();
              
            // setting the state of expand or collapse alternative rows
      
            bool expandFirstRow = false;          
        MvwISDJobXrefTableControlRow[] recControls = this.GetRecordControls();
            for (int i = 0; i < recControls.Length; i++)
            {
                System.Web.UI.Control altRow = (MiscUtils.FindControlRecursively(recControls[i], "MvwISDJobXrefTableControlAltRow") as System.Web.UI.Control);
                if (altRow != null){
                    if (expandFirstRow && i == 0){
                        altRow.Visible = true;
                   
                         recControls[i].ExpandRowButton.ImageUrl = "../Images/icon_expandcollapserow.gif";
                         recControls[i].ExpandRowButton.Attributes.Add("onmouseover", "this.src='../Images/icon_expandcollapserow_over.gif'");
                         recControls[i].ExpandRowButton.Attributes.Add("onmouseout", "this.src='../Images/icon_expandcollapserow.gif'");
                   
                    }
                    else{
                        altRow.Visible = false;
                   
                         recControls[i].ExpandRowButton.ImageUrl = "../Images/icon_expandcollapserow2.gif";
                         recControls[i].ExpandRowButton.Attributes.Add("onmouseover", "this.src='../Images/icon_expandcollapserow_over2.gif'");
                         recControls[i].ExpandRowButton.Attributes.Add("onmouseout", "this.src='../Images/icon_expandcollapserow2.gif'");
                   
                    }
                }
            }
    
            // Load data for each record and table UI control.
            // Ordering is important because child controls get 
            // their parent ids from their parent UI controls.
                
      
            // this method calls the set method for controls with special formula like running total, sum, rank, etc
            SetFormulaControls();
            
             
              SetFiltersButton();
                     
        }
        
        
        public virtual void SetFormulaControls()
        {
            // this method calls Set methods for the control that has special formula
        

    }

        
    public virtual void AddWarningMessageOnClick() {
    
        if (this.TotalRecords > 10000)
          this.ExcelButton.Attributes.Add("onClick", "return (confirm('" + ((BaseApplicationPage)this.Page).GetResourceValue("ExportConfirm", "VPLookup") + "'));");
        else
          this.ExcelButton.Attributes.Remove("onClick");
      
    }
  

        public virtual void RegisterPostback()
        {
        
              this.Page.RegisterPostBackTrigger(MiscUtils.FindControlRecursively(this,"ExcelButton"));
                        
              this.Page.RegisterPostBackTrigger(MiscUtils.FindControlRecursively(this,"PDFButton"));
                        
              this.Page.RegisterPostBackTrigger(MiscUtils.FindControlRecursively(this,"WordButton"));
                                
        }
        

        
          public BaseClasses.Data.DataSource.EvaluateFormulaDelegate EvaluateFormulaDelegate;

          public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables, bool includeDS, FormulaEvaluator e)
          {
            if (e == null)
                e = new FormulaEvaluator();

            e.Variables.Clear();

            // add variables for formula evaluation
            if (variables != null)
            {
                System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<string, object>> enumerator = variables.GetEnumerator();
                while (enumerator.MoveNext())
                {
                    e.Variables.Add(enumerator.Current.Key, enumerator.Current.Value);
                }
            }
            if (includeDS)
            {
                
            }

            // All variables referred to in the formula are expected to be
            // properties of the DataSource.  For example, referring to
            // UnitPrice as a variable will refer to DataSource.UnitPrice
            e.DataSource = dataSourceForEvaluate;

            // Define the calling control.  This is used to add other 
            // related table and record controls as variables.
            e.CallingControl = this;

            object resultObj = e.Evaluate(formula);
            if (resultObj == null)
                return "";
            
            if ( !string.IsNullOrEmpty(format) && (string.IsNullOrEmpty(formula) || formula.IndexOf("Format(") < 0) )
                return FormulaUtils.Format(resultObj, format);
            else
                return resultObj.ToString();
        }
        
        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables, bool includeDS)
        {
          return EvaluateFormula(formula, dataSourceForEvaluate, format, variables, includeDS, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables)
        {
          return EvaluateFormula(formula, dataSourceForEvaluate, format, variables, true, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, format, null, true, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, System.Collections.Generic.IDictionary<string, object> variables, FormulaEvaluator e)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, null, variables, true, e);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, null, null, true, null);
        }

        public virtual string EvaluateFormula(string formula, bool includeDS)
        {
          return this.EvaluateFormula(formula, null, null, null, includeDS, null);
        }

        public virtual string EvaluateFormula(string formula)
        {
          return this.EvaluateFormula(formula, null, null, null, true, null);
        }
           
        public virtual void ResetControl()
        {


            
            this.GLDepartmentNumberFilter.ClearSelection();
            
            this.JobStatusFilter.ClearSelection();
            
            this.MailStateFilter.ClearSelection();
            
            this.POCNameFilter.ClearSelection();
            
            this.SalesPersonNameFilter.ClearSelection();
            
            this.VPCustomerNameFilter.ClearSelection();
            
            this.SearchText.Text = "";
            
            this.CurrentSortOrder.Reset();
            if (this.InSession(this, "Order_By")) {
                this.CurrentSortOrder = OrderBy.FromXmlString(this.GetFromSession(this, "Order_By", null));
            }
            else {
            
                this.CurrentSortOrder = new OrderBy(true, false);
               
            }
                
            this.PageIndex = 0;
        }
        
        public virtual void ResetPageControl()
        {
            this.PageIndex = 0;
        }
        
        protected virtual void BindPaginationControls()
        {
            // Setup the pagination controls.   

            // Bind the pagination labels.
        
            if (DbUtils.GetCreatedRecords(this.DataSource).Length > 0)                      
                    
            {
                this.Pagination.CurrentPage.Text = (this.PageIndex + 1).ToString();
            } 
            else
            {
                this.Pagination.CurrentPage.Text = "0";
            }
            this.Pagination.PageSize.Text = this.PageSize.ToString();
    
            // Bind the buttons for MvwISDJobXrefTableControl pagination.
        
            this.Pagination.FirstPage.Enabled = !(this.PageIndex == 0);
            if (this._TotalPages < 0)             // if the total pages is not determined yet, enable last and next buttons
                this.Pagination.LastPage.Enabled = true;
            else if (this._TotalPages == 0)          // if the total pages is determined and it is 0, enable last and next buttons
                this.Pagination.LastPage.Enabled = false;            
            else                                     // if the total pages is the last page, disable last and next buttons
                this.Pagination.LastPage.Enabled = !(this.PageIndex == this.TotalPages - 1);            
          
            if (this._TotalPages < 0)             // if the total pages is not determined yet, enable last and next buttons
                this.Pagination.NextPage.Enabled = true;
            else if (this._TotalPages == 0)          // if the total pages is determined and it is 0, enable last and next buttons
                this.Pagination.NextPage.Enabled = false;            
            else                                     // if the total pages is the last page, disable last and next buttons
                this.Pagination.NextPage.Enabled = !(this.PageIndex == this.TotalPages - 1);            
          
            this.Pagination.PreviousPage.Enabled = !(this.PageIndex == 0);    
        }
 
        public virtual void SaveData()
        {
            // Save the data from the entire table.  Calls each row's Save Data
            // to save their data.  This function is called by the Click handler of the
            // Save button.  The button handler should Start/Commit/End a transaction.
              
            foreach (MvwISDJobXrefTableControlRow recCtl in this.GetRecordControls())
            {
        
                if (this.InDeletedRecordIds(recCtl)) {
                    // Delete any pending deletes. 
                    recCtl.Delete();
                }
                else {
                    if (recCtl.Visible) {
                        recCtl.SaveData();
                    }
                }
          
            }

          
    
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            this.ResetData = true;
          
            // Set IsNewRecord to False for all records - since everything has been saved and is no longer "new"
            foreach (MvwISDJobXrefTableControlRow recCtl in this.GetRecordControls()){
                recCtl.IsNewRecord = false;
            }
      
            // Set DeletedRecordsIds to Nothing since we have deleted all pending deletes.
            this.DeletedRecordIds = null;
                
        }
        
        public virtual CompoundFilter CreateCompoundJoinFilter()
        {
            CompoundFilter jFilter = new CompoundFilter();
        
           return jFilter;
        }      
        
    
        public virtual OrderBy CreateOrderBy()
        {
            // The CurrentSortOrder is initialized to the sort order on the 
            // Query Wizard.  It may be modified by the Click handler for any of
            // the column heading to sort or reverse sort by that column.
            // You can add your own sort order, or modify it on the Query Wizard.
            return this.CurrentSortOrder;
        }
         
        
        private string parentSelectedKeyValue;
        public string ParentSelectedKeyValue
        {
          get
          {
            return parentSelectedKeyValue;
          }
          set
          {
            parentSelectedKeyValue = value;
          }
        }

    
        public virtual WhereClause CreateWhereClause()
        {
            // This CreateWhereClause is used for loading the data.
            MvwISDJobXrefView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
    
            // CreateWhereClause() Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
        
            if (MiscUtils.IsValueSelected(this.GLDepartmentNumberFilter)) {
                        
                wc.iAND(MvwISDJobXrefView.GLDepartmentNumber, BaseFilter.ComparisonOperator.EqualsTo, MiscUtils.GetSelectedValue(this.GLDepartmentNumberFilter, this.GetFromSession(this.GLDepartmentNumberFilter)), false, false);
                    
            }
                      
            if (MiscUtils.IsValueSelected(this.JobStatusFilter)) {
                        
                wc.iAND(MvwISDJobXrefView.JobStatus, BaseFilter.ComparisonOperator.EqualsTo, MiscUtils.GetSelectedValue(this.JobStatusFilter, this.GetFromSession(this.JobStatusFilter)), false, false);
                    
            }
                      
            if (MiscUtils.IsValueSelected(this.MailStateFilter)) {
                        
                int selectedItemCount = 0;
                foreach (ListItem item in this.MailStateFilter.Items){
                    if (item.Selected) {
                        selectedItemCount += 1;
                        
                          
                    }
                }
                WhereClause filter = new WhereClause();
                foreach (ListItem item in this.MailStateFilter.Items){
                    if ((item.Selected) && ((item.Value == "--ANY--") || (item.Value == "--PLEASE_SELECT--")) && (selectedItemCount > 1)){
                        item.Selected = false;
                    }
                    if (item.Selected){
                        filter.iOR(MvwISDJobXrefView.MailState, BaseFilter.ComparisonOperator.EqualsTo, item.Value, false, false);
                    }
                }
                wc.iAND(filter);
                    
            }
                      
            if (MiscUtils.IsValueSelected(this.POCNameFilter)) {
                        
                int selectedItemCount = 0;
                foreach (ListItem item in this.POCNameFilter.Items){
                    if (item.Selected) {
                        selectedItemCount += 1;
                        
                          
                    }
                }
                WhereClause filter = new WhereClause();
                foreach (ListItem item in this.POCNameFilter.Items){
                    if ((item.Selected) && ((item.Value == "--ANY--") || (item.Value == "--PLEASE_SELECT--")) && (selectedItemCount > 1)){
                        item.Selected = false;
                    }
                    if (item.Selected){
                        filter.iOR(MvwISDJobXrefView.POCName, BaseFilter.ComparisonOperator.EqualsTo, item.Value, false, false);
                    }
                }
                wc.iAND(filter);
                    
            }
                      
            if (MiscUtils.IsValueSelected(this.SalesPersonNameFilter)) {
                        
                int selectedItemCount = 0;
                foreach (ListItem item in this.SalesPersonNameFilter.Items){
                    if (item.Selected) {
                        selectedItemCount += 1;
                        
                          
                    }
                }
                WhereClause filter = new WhereClause();
                foreach (ListItem item in this.SalesPersonNameFilter.Items){
                    if ((item.Selected) && ((item.Value == "--ANY--") || (item.Value == "--PLEASE_SELECT--")) && (selectedItemCount > 1)){
                        item.Selected = false;
                    }
                    if (item.Selected){
                        filter.iOR(MvwISDJobXrefView.SalesPersonName, BaseFilter.ComparisonOperator.EqualsTo, item.Value, false, false);
                    }
                }
                wc.iAND(filter);
                    
            }
                      
            if (MiscUtils.IsValueSelected(this.SearchText)) {
                if (this.SearchText.Text == BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) ) {
                        this.SearchText.Text = "";
                } else {
                  // Strip "..." from begin and ending of the search text, otherwise the search will return 0 values as in database "..." is not stored.
                  if (this.SearchText.Text.StartsWith("...")) {
                      this.SearchText.Text = this.SearchText.Text.Substring(3,this.SearchText.Text.Length-3);
                  }
                  if (this.SearchText.Text.EndsWith("...")) {
                      this.SearchText.Text = this.SearchText.Text.Substring(0,this.SearchText.Text.Length-3);
                      // Strip the last word as well as it is likely only a partial word
                      int endindex = this.SearchText.Text.Length - 1;
                      while (!Char.IsWhiteSpace(SearchText.Text[endindex]) && endindex > 0) {
                          endindex--;
                      }
                      if (endindex > 0) {
                          this.SearchText.Text = this.SearchText.Text.Substring(0, endindex);
                      }
                  }
                }
                string formatedSearchText = MiscUtils.GetSelectedValue(this.SearchText, this.GetFromSession(this.SearchText));
                // After stripping "..." see if the search text is null or empty.
                if (MiscUtils.IsValueSelected(this.SearchText)) {
                      
                    // These clauses are added depending on operator and fields selected in Control's property page, bindings tab.
                  
                    WhereClause search = new WhereClause();
                    
      ColumnList cols = new ColumnList();    
        
      cols.Add(MvwISDJobXrefView.VPJobDesc);
      
      cols.Add(MvwISDJobXrefView.VPJob);
      
      cols.Add(MvwISDJobXrefView.CGCJob);
      
      cols.Add(MvwISDJobXrefView.POC);
      
      cols.Add(MvwISDJobXrefView.POCName);
      
      cols.Add(MvwISDJobXrefView.SalesPerson);
      
      cols.Add(MvwISDJobXrefView.SalesPersonName);
      
      cols.Add(MvwISDJobXrefView.VPCustomer);
      
      cols.Add(MvwISDJobXrefView.VPCustomerName);
      
      foreach(BaseColumn col in cols)
      {
      
                    search.iOR(col, BaseFilter.ComparisonOperator.Contains, MiscUtils.GetSelectedValue(this.SearchText, this.GetFromSession(this.SearchText)), true, false);
        
      }
    
                    wc.iAND(search);
                  
                }
            }
                  
            if (MiscUtils.IsValueSelected(this.VPCustomerNameFilter)) {
                        
                int selectedItemCount = 0;
                foreach (ListItem item in this.VPCustomerNameFilter.Items){
                    if (item.Selected) {
                        selectedItemCount += 1;
                        
                          
                    }
                }
                WhereClause filter = new WhereClause();
                foreach (ListItem item in this.VPCustomerNameFilter.Items){
                    if ((item.Selected) && ((item.Value == "--ANY--") || (item.Value == "--PLEASE_SELECT--")) && (selectedItemCount > 1)){
                        item.Selected = false;
                    }
                    if (item.Selected){
                        filter.iOR(MvwISDJobXrefView.VPCustomerName, BaseFilter.ComparisonOperator.EqualsTo, item.Value, false, false);
                    }
                }
                wc.iAND(filter);
                    
            }
                      
            bool bAnyFiltersChanged = false;
            
            if (MiscUtils.IsValueSelected(this.GLDepartmentNumberFilter) || this.InSession(this.GLDepartmentNumberFilter)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.JobStatusFilter) || this.InSession(this.JobStatusFilter)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.MailStateFilter) || this.InSession(this.MailStateFilter)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.POCNameFilter) || this.InSession(this.POCNameFilter)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.SalesPersonNameFilter) || this.InSession(this.SalesPersonNameFilter)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.SearchText) || this.InSession(this.SearchText)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.VPCustomerNameFilter) || this.InSession(this.VPCustomerNameFilter)){
                bAnyFiltersChanged = true;
                }
            
            if (!bAnyFiltersChanged) {
                wc.RunQuery = false;
            }
        
            return wc;
        }
        
         
        public virtual WhereClause CreateWhereClause(String searchText, String fromSearchControl, String AutoTypeAheadSearch, String AutoTypeAheadWordSeparators)
        {
            // This CreateWhereClause is used for loading list of suggestions for Auto Type-Ahead feature.
            MvwISDJobXrefView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
        
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
            String appRelativeVirtualPath = (String)HttpContext.Current.Session["AppRelativeVirtualPath"];
            
            // Adds clauses if values are selected in Filter controls which are configured in the page.
          
      String GLDepartmentNumberFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "GLDepartmentNumberFilter_Ajax"];
            if (MiscUtils.IsValueSelected(GLDepartmentNumberFilterSelectedValue)) {

              
                wc.iAND(MvwISDJobXrefView.GLDepartmentNumber, BaseFilter.ComparisonOperator.EqualsTo, GLDepartmentNumberFilterSelectedValue, false, false);
                      
      }
                      
      String JobStatusFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "JobStatusFilter_Ajax"];
            if (MiscUtils.IsValueSelected(JobStatusFilterSelectedValue)) {

              
                wc.iAND(MvwISDJobXrefView.JobStatus, BaseFilter.ComparisonOperator.EqualsTo, JobStatusFilterSelectedValue, false, false);
                      
      }
                      
      String MailStateFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "MailStateFilter_Ajax"];
            if (MiscUtils.IsValueSelected(MailStateFilterSelectedValue)) {

              
        if (MailStateFilterSelectedValue != null){
                        string[] MailStateFilteritemListFromSession = MailStateFilterSelectedValue.Split(',');
                        int index = 0;
                        WhereClause filter = new WhereClause();
                        foreach (string item in MailStateFilteritemListFromSession)
                        {
                            if (index == 0 && item.ToString().Equals(""))
                            {
                            }
                            else
                            {
                                filter.iOR(MvwISDJobXrefView.MailState, BaseFilter.ComparisonOperator.EqualsTo, item, false, false);
                                index += 1;
                            }
                        }
                        wc.iAND(filter);
        }
                
      }
                      
      String POCNameFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "POCNameFilter_Ajax"];
            if (MiscUtils.IsValueSelected(POCNameFilterSelectedValue)) {

              
        if (POCNameFilterSelectedValue != null){
                        string[] POCNameFilteritemListFromSession = POCNameFilterSelectedValue.Split(',');
                        int index = 0;
                        WhereClause filter = new WhereClause();
                        foreach (string item in POCNameFilteritemListFromSession)
                        {
                            if (index == 0 && item.ToString().Equals(""))
                            {
                            }
                            else
                            {
                                filter.iOR(MvwISDJobXrefView.POCName, BaseFilter.ComparisonOperator.EqualsTo, item, false, false);
                                index += 1;
                            }
                        }
                        wc.iAND(filter);
        }
                
      }
                      
      String SalesPersonNameFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "SalesPersonNameFilter_Ajax"];
            if (MiscUtils.IsValueSelected(SalesPersonNameFilterSelectedValue)) {

              
        if (SalesPersonNameFilterSelectedValue != null){
                        string[] SalesPersonNameFilteritemListFromSession = SalesPersonNameFilterSelectedValue.Split(',');
                        int index = 0;
                        WhereClause filter = new WhereClause();
                        foreach (string item in SalesPersonNameFilteritemListFromSession)
                        {
                            if (index == 0 && item.ToString().Equals(""))
                            {
                            }
                            else
                            {
                                filter.iOR(MvwISDJobXrefView.SalesPersonName, BaseFilter.ComparisonOperator.EqualsTo, item, false, false);
                                index += 1;
                            }
                        }
                        wc.iAND(filter);
        }
                
      }
                      
            if (MiscUtils.IsValueSelected(searchText) && fromSearchControl == "SearchText") {
                String formatedSearchText = searchText;
                // strip "..." from begin and ending of the search text, otherwise the search will return 0 values as in database "..." is not stored.
                if (searchText.StartsWith("...")) {
                    formatedSearchText = searchText.Substring(3,searchText.Length-3);
                }
                if (searchText.EndsWith("...")) {
                    formatedSearchText = searchText.Substring(0,searchText.Length-3);
                }
                // After stripping "...", trim any leading and trailing whitespaces 
                formatedSearchText = formatedSearchText.Trim();
                // After stripping "..." see if the search text is null or empty.
                if (MiscUtils.IsValueSelected(searchText)) {
                      
                    // These clauses are added depending on operator and fields selected in Control's property page, bindings tab.
                  
                    WhereClause search = new WhereClause();
                    
                    if (StringUtils.InvariantLCase(AutoTypeAheadSearch).Equals("wordsstartingwithsearchstring")) {
                
      ColumnList cols = new ColumnList();    
        
      cols.Add(MvwISDJobXrefView.VPJobDesc);
      
      cols.Add(MvwISDJobXrefView.VPJob);
      
      cols.Add(MvwISDJobXrefView.CGCJob);
      
      cols.Add(MvwISDJobXrefView.POC);
      
      cols.Add(MvwISDJobXrefView.POCName);
      
      cols.Add(MvwISDJobXrefView.SalesPerson);
      
      cols.Add(MvwISDJobXrefView.SalesPersonName);
      
      cols.Add(MvwISDJobXrefView.VPCustomer);
      
      cols.Add(MvwISDJobXrefView.VPCustomerName);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Starts_With, formatedSearchText, true, false);
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, AutoTypeAheadWordSeparators + formatedSearchText, true, false);
                
      }
    
                    } else {
                        
      ColumnList cols = new ColumnList();    
        
      cols.Add(MvwISDJobXrefView.VPJobDesc);
      
      cols.Add(MvwISDJobXrefView.VPJob);
      
      cols.Add(MvwISDJobXrefView.CGCJob);
      
      cols.Add(MvwISDJobXrefView.POC);
      
      cols.Add(MvwISDJobXrefView.POCName);
      
      cols.Add(MvwISDJobXrefView.SalesPerson);
      
      cols.Add(MvwISDJobXrefView.SalesPersonName);
      
      cols.Add(MvwISDJobXrefView.VPCustomer);
      
      cols.Add(MvwISDJobXrefView.VPCustomerName);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, formatedSearchText, true, false);
      }
    
                    } 
                    wc.iAND(search);
                  
                }
            }
                  
      String VPCustomerNameFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "VPCustomerNameFilter_Ajax"];
            if (MiscUtils.IsValueSelected(VPCustomerNameFilterSelectedValue)) {

              
        if (VPCustomerNameFilterSelectedValue != null){
                        string[] VPCustomerNameFilteritemListFromSession = VPCustomerNameFilterSelectedValue.Split(',');
                        int index = 0;
                        WhereClause filter = new WhereClause();
                        foreach (string item in VPCustomerNameFilteritemListFromSession)
                        {
                            if (index == 0 && item.ToString().Equals(""))
                            {
                            }
                            else
                            {
                                filter.iOR(MvwISDJobXrefView.VPCustomerName, BaseFilter.ComparisonOperator.EqualsTo, item, false, false);
                                index += 1;
                            }
                        }
                        wc.iAND(filter);
        }
                
      }
                      

            return wc;
        }

        
        public virtual string[] GetAutoCompletionList_SearchText(String prefixText,int count)
        {
            ArrayList resultList = new ArrayList();
            ArrayList wordList= new ArrayList();
            
            CompoundFilter filterJoin = CreateCompoundJoinFilter();    
            WhereClause wc = CreateWhereClause(prefixText,"SearchText", "WordsStartingWithSearchString", "[^a-zA-Z0-9]");
            if(count==0) count = 10;
            VPLookup.Business.MvwISDJobXrefRecord[] recordList  = MvwISDJobXrefView.GetRecords(filterJoin, wc, null, 0, count, ref count);
            String resultItem = "";
            if (resultItem == "") resultItem = "";
            foreach (MvwISDJobXrefRecord rec in recordList ){
                // Exit the loop if recordList count has reached AutoTypeAheadListSize.
                if (resultList.Count >= count) {
                    break;
                }
                // If the field is configured to Display as Foreign key, Format() method returns the 
                // Display as Forien Key value instead of original field value.
                // Since search had to be done in multiple fields (selected in Control's page property, binding tab) in a record,
                // We need to find relevent field to display which matches the prefixText and is not already present in the result list.
        
                resultItem = rec.Format(MvwISDJobXrefView.VPJobDesc);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.VPJobDesc.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.VPJobDesc.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDJobXrefView.VPJob);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.VPJob.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.VPJob.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDJobXrefView.CGCJob);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.CGCJob.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.CGCJob.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDJobXrefView.POC);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.POC.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.POC.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDJobXrefView.POCName);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.POCName.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.POCName.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDJobXrefView.SalesPerson);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.SalesPerson.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.SalesPerson.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDJobXrefView.SalesPersonName);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.SalesPersonName.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.SalesPersonName.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDJobXrefView.VPCustomer);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.VPCustomer.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.VPCustomer.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDJobXrefView.VPCustomerName);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobXrefView.VPCustomerName.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobXrefView.VPCustomerName.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
                      
            }
              
            resultList.Sort();
            string[] result = new string[resultList.Count];
            Array.Copy(resultList.ToArray(), result, resultList.Count);
            return result;
        }
          
          
         public virtual bool FormatSuggestions(String prefixText, String resultItem,
                                              int columnLength, String AutoTypeAheadDisplayFoundText,
                                              String autoTypeAheadSearch, String AutoTypeAheadWordSeparators,
                                              ArrayList resultList)
        {
            return this.FormatSuggestions(prefixText, resultItem, columnLength, AutoTypeAheadDisplayFoundText,
                                              autoTypeAheadSearch, AutoTypeAheadWordSeparators, resultList, false);
        }          
          
        public virtual bool FormatSuggestions(String prefixText, String resultItem,
                                              int columnLength, String AutoTypeAheadDisplayFoundText,
                                              String autoTypeAheadSearch, String AutoTypeAheadWordSeparators,
                                              ArrayList resultList, bool stripHTML)
        {
            if (stripHTML){
                prefixText = StringUtils.ConvertHTMLToPlainText(prefixText);
                resultItem = StringUtils.ConvertHTMLToPlainText(resultItem);
            }
            // Formats the result Item and adds it to the list of suggestions.
            int index  = resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).IndexOf(prefixText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture));
            String itemToAdd = null;
            bool isFound = false;
            bool isAdded = false;
            if (StringUtils.InvariantLCase(autoTypeAheadSearch).Equals("wordsstartingwithsearchstring") && !(index == 0)) {
                // Expression to find word which contains AutoTypeAheadWordSeparators followed by prefixText
                System.Text.RegularExpressions.Regex regex1 = new System.Text.RegularExpressions.Regex( AutoTypeAheadWordSeparators + prefixText, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                if (regex1.IsMatch(resultItem)) {
                    index = regex1.Match(resultItem).Index;
                    isFound = true;
                }
                //If the prefixText is found immediatly after white space then starting of the word is found so don not search any further
                if (resultItem[index].ToString() != " ") {
                    // Expression to find beginning of the word which contains AutoTypeAheadWordSeparators followed by prefixText
                    System.Text.RegularExpressions.Regex regex = new System.Text.RegularExpressions.Regex("\\S*" + AutoTypeAheadWordSeparators + prefixText, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                    if (regex.IsMatch(resultItem)) {
                        index = regex.Match(resultItem).Index;
                        isFound = true;
                    }
                }
            }
            // If autoTypeAheadSearch value is wordsstartingwithsearchstring then, extract the substring only if the prefixText is found at the 
            // beginning of the resultItem (index = 0) or a word in resultItem is found starts with prefixText. 
            if (index == 0 || isFound || StringUtils.InvariantLCase(autoTypeAheadSearch).Equals("anywhereinstring")) {
                if (StringUtils.InvariantLCase(AutoTypeAheadDisplayFoundText).Equals("atbeginningofmatchedstring")) {
                    // Expression to find beginning of the word which contains prefixText
                    System.Text.RegularExpressions.Regex regex1 = new System.Text.RegularExpressions.Regex("\\S*" + prefixText, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                    //  Find the beginning of the word which contains prefexText
                    if (StringUtils.InvariantLCase(autoTypeAheadSearch).Equals("anywhereinstring") && regex1.IsMatch(resultItem)) {
                        index = regex1.Match(resultItem).Index;
                        isFound = true;
                    }
                    // Display string from the index till end of the string if, sub string from index till end of string is less than columnLength value.
                    if ((resultItem.Length - index) <= columnLength) {
                        if (index == 0) {
                            itemToAdd = resultItem;
                        } else {
                            itemToAdd = resultItem.Substring(index);
                        }
                    }
                    else {
                            itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, index, index + columnLength, StringUtils.Direction.forward);
                    }
                }
                else if (StringUtils.InvariantLCase(AutoTypeAheadDisplayFoundText).Equals("inmiddleofmatchedstring")) {
                    int subStringBeginIndex = (int)(columnLength / 2);
                    if (resultItem.Length <= columnLength) {
                        itemToAdd = resultItem;
                    }
                    else {
                        // Sanity check at end of the string
                        if (((index + prefixText.Length) >= resultItem.Length - 1)||(resultItem.Length - index < subStringBeginIndex)) {
                            itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, resultItem.Length - 1 - columnLength, resultItem.Length - 1, StringUtils.Direction.backward);
                        }
                        else if (index <= subStringBeginIndex) {
                            // Sanity check at beginning of the string
                            itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, 0, columnLength, StringUtils.Direction.forward);
                        } 
                        else {
                            // Display string containing text before the prefixText occures and text after the prefixText
                            itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, index - subStringBeginIndex, index - subStringBeginIndex + columnLength, StringUtils.Direction.both);
                        }
                    }
                }
                else if (StringUtils.InvariantLCase(AutoTypeAheadDisplayFoundText).Equals("atendofmatchedstring")) {
                     // Expression to find ending of the word which contains prefexText
                    System.Text.RegularExpressions.Regex regex1 = new System.Text.RegularExpressions.Regex("\\s", System.Text.RegularExpressions.RegexOptions.IgnoreCase); 
                    // Find the ending of the word which contains prefexText
                    if (regex1.IsMatch(resultItem, index + 1)) {
                        index = regex1.Match(resultItem, index + 1).Index;
                    }
                    else{
                        // If the word which contains prefexText is the last word in string, regex1.IsMatch returns false.
                        index = resultItem.Length;
                    }
                    
                    if (index > resultItem.Length) {
                        index = resultItem.Length;
                    }
                    // If text from beginning of the string till index is less than columnLength value then, display string from the beginning till index.
                    if (index <= columnLength) {
                        itemToAdd = resultItem.Substring(0, index);
                    } 
                    else {
                        // Truncate the string to show only columnLength has to be appended.
                        itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, index - columnLength, index, StringUtils.Direction.backward);
                    }
                }
                
                // Remove newline character from itemToAdd
                int prefixTextIndex = itemToAdd.IndexOf(prefixText, StringComparison.CurrentCultureIgnoreCase);
                if(prefixTextIndex < 0) return false;
                // If itemToAdd contains any newline after the search text then show text only till newline
                System.Text.RegularExpressions.Regex regex2 = new System.Text.RegularExpressions.Regex("(\r\n|\n)", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                int newLineIndexAfterPrefix = -1;
                if (regex2.IsMatch(itemToAdd, prefixTextIndex)){
                    newLineIndexAfterPrefix = regex2.Match(itemToAdd, prefixTextIndex).Index;
                }
                if ((newLineIndexAfterPrefix > -1)) {                   
                    itemToAdd = itemToAdd.Substring(0, newLineIndexAfterPrefix);                   
                }
                // If itemToAdd contains any newline before search text then show text which comes after newline
                System.Text.RegularExpressions.Regex regex3 = new System.Text.RegularExpressions.Regex("(\r\n|\n)", System.Text.RegularExpressions.RegexOptions.IgnoreCase | System.Text.RegularExpressions.RegexOptions.RightToLeft );
                int newLineIndexBeforePrefix = -1;
                if (regex3.IsMatch(itemToAdd, prefixTextIndex)){
                    newLineIndexBeforePrefix = regex3.Match(itemToAdd, prefixTextIndex).Index;
                }
                if ((newLineIndexBeforePrefix > -1)) {
                    itemToAdd = itemToAdd.Substring(newLineIndexBeforePrefix +regex3.Match(itemToAdd, prefixTextIndex).Length);
                }

                if (!string.IsNullOrEmpty(itemToAdd) && !resultList.Contains(itemToAdd)) {
                    
                    resultList.Add(itemToAdd);
          								
                    isAdded = true;
                }
            }
            return isAdded;
        }        
        
    
        protected virtual void GetPageSize()
        {
        
            if (this.Pagination.PageSize.Text.Length > 0) {
                try {
                    // this.PageSize = Convert.ToInt32(this.Pagination.PageSize.Text);
                } catch (Exception ) {
                }
            }
        }

        protected virtual void AddNewRecords()
        {
          
            ArrayList newRecordList = new ArrayList();
          
            System.Collections.Generic.List<Hashtable> newUIDataList = new System.Collections.Generic.List<Hashtable>();
    // Loop though all the record controls and if the record control
    // does not have a unique record id set, then create a record
    // and add to the list.
    if (!this.ResetData)
    {
    System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDJobXrefTableControlRepeater"));
    if (rep == null){return;}

    foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
    {
    // Loop through all rows in the table, set its DataSource and call DataBind().
    MvwISDJobXrefTableControlRow recControl = (MvwISDJobXrefTableControlRow)(repItem.FindControl("MvwISDJobXrefTableControlRow"));

      if (recControl.Visible && recControl.IsNewRecord) {
      MvwISDJobXrefRecord rec = new MvwISDJobXrefRecord();
        
                        if (recControl.CGCCo.Text != "") {
                            rec.Parse(recControl.CGCCo.Text, MvwISDJobXrefView.CGCCo);
                  }
                
                        if (recControl.CGCJob.Text != "") {
                            rec.Parse(recControl.CGCJob.Text, MvwISDJobXrefView.CGCJob);
                  }
                
                        if (recControl.GLDepartmentName.Text != "") {
                            rec.Parse(recControl.GLDepartmentName.Text, MvwISDJobXrefView.GLDepartmentName);
                  }
                
                        if (recControl.GLDepartmentNumber.Text != "") {
                            rec.Parse(recControl.GLDepartmentNumber.Text, MvwISDJobXrefView.GLDepartmentNumber);
                  }
                
                        if (recControl.JobStatus.Text != "") {
                            rec.Parse(recControl.JobStatus.Text, MvwISDJobXrefView.JobStatus);
                  }
                
                        if (recControl.MailAddress.Text != "") {
                            rec.Parse(recControl.MailAddress.Text, MvwISDJobXrefView.MailAddress);
                  }
                
                        if (recControl.MailAddress2.Text != "") {
                            rec.Parse(recControl.MailAddress2.Text, MvwISDJobXrefView.MailAddress2);
                  }
                
                        if (recControl.MailCity.Text != "") {
                            rec.Parse(recControl.MailCity.Text, MvwISDJobXrefView.MailCity);
                  }
                
                        if (recControl.MailState.Text != "") {
                            rec.Parse(recControl.MailState.Text, MvwISDJobXrefView.MailState);
                  }
                
                        if (recControl.MailZip.Text != "") {
                            rec.Parse(recControl.MailZip.Text, MvwISDJobXrefView.MailZip);
                  }
                
                        if (recControl.POC.Text != "") {
                            rec.Parse(recControl.POC.Text, MvwISDJobXrefView.POC);
                  }
                
                        if (recControl.POCName.Text != "") {
                            rec.Parse(recControl.POCName.Text, MvwISDJobXrefView.POCName);
                  }
                
                        if (recControl.SalesPerson.Text != "") {
                            rec.Parse(recControl.SalesPerson.Text, MvwISDJobXrefView.SalesPerson);
                  }
                
                        if (recControl.SalesPersonName.Text != "") {
                            rec.Parse(recControl.SalesPersonName.Text, MvwISDJobXrefView.SalesPersonName);
                  }
                
                        if (recControl.VPCo.Text != "") {
                            rec.Parse(recControl.VPCo.Text, MvwISDJobXrefView.VPCo);
                  }
                
                        if (recControl.VPCustomer.Text != "") {
                            rec.Parse(recControl.VPCustomer.Text, MvwISDJobXrefView.VPCustomer);
                  }
                
                        if (recControl.VPCustomerName.Text != "") {
                            rec.Parse(recControl.VPCustomerName.Text, MvwISDJobXrefView.VPCustomerName);
                  }
                
                        if (recControl.VPJob.Text != "") {
                            rec.Parse(recControl.VPJob.Text, MvwISDJobXrefView.VPJob);
                  }
                
                        if (recControl.VPJobDesc.Text != "") {
                            rec.Parse(recControl.VPJobDesc.Text, MvwISDJobXrefView.VPJobDesc);
                  }
                
      newUIDataList.Add(recControl.PreservedUIData());
      newRecordList.Add(rec);
      }
      }
      }
    
            // Add any new record to the list.
            for (int count = 1; count <= this.AddNewRecord; count++) {
              
                newRecordList.Insert(0, new MvwISDJobXrefRecord());
                newUIDataList.Insert(0, new Hashtable());
              
            }
            this.AddNewRecord = 0;

            // Finally, add any new records to the DataSource.
            if (newRecordList.Count > 0) {
              
                ArrayList finalList = new ArrayList(this.DataSource);
                finalList.InsertRange(0, newRecordList);

                Type myrec = typeof(VPLookup.Business.MvwISDJobXrefRecord);
                this.DataSource = (MvwISDJobXrefRecord[])(finalList.ToArray(myrec));
              
            }
            
            // Add the existing UI data to this hash table
            if (newUIDataList.Count > 0)
                this.UIData.InsertRange(0, newUIDataList);
        }

        
        public void AddToDeletedRecordIds(MvwISDJobXrefTableControlRow rec)
        {
            if (rec.IsNewRecord) {
                return;
            }

            if (this.DeletedRecordIds != null && this.DeletedRecordIds.Length > 0) {
                this.DeletedRecordIds += ",";
            }

            this.DeletedRecordIds += "[" + rec.RecordUniqueId + "]";
        }

        protected virtual bool InDeletedRecordIds(MvwISDJobXrefTableControlRow rec)            
        {
            if (this.DeletedRecordIds == null || this.DeletedRecordIds.Length == 0) {
                return (false);
            }

            return (this.DeletedRecordIds.IndexOf("[" + rec.RecordUniqueId + "]") >= 0);
        }

        private String _DeletedRecordIds;
        public String DeletedRecordIds {
            get {
                return (this._DeletedRecordIds);
            }
            set {
                this._DeletedRecordIds = value;
            }
        }
        
      
        // Create Set, WhereClause, and Populate Methods
        
        public virtual void SetCGCCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetCGCJobLabel()
                  {
                  
                    
        }
                
        public virtual void SetGLDepartmentNameLabel()
                  {
                  
                    
        }
                
        public virtual void SetGLDepartmentNumberLabel()
                  {
                  
                    
        }
                
        public virtual void SetGLDepartmentNumberLabel1()
                  {
                  
                    
        }
                
        public virtual void SetJobStatusLabel()
                  {
                  
                    
        }
                
        public virtual void SetJobStatusLabel1()
                  {
                  
                    
        }
                
        public virtual void SetMailAddress2Label()
                  {
                  
                      //Code for the text property is generated inside the .aspx file. 
                      //To override this property you can uncomment the following property and add you own value.
                      //this.MailAddress2Label.Text = "Some value";
                    
                    
        }
                
        public virtual void SetMailAddressLabel()
                  {
                  
                      //Code for the text property is generated inside the .aspx file. 
                      //To override this property you can uncomment the following property and add you own value.
                      //this.MailAddressLabel.Text = "Some value";
                    
                    
        }
                
        public virtual void SetMailCityLabel()
                  {
                  
                      //Code for the text property is generated inside the .aspx file. 
                      //To override this property you can uncomment the following property and add you own value.
                      //this.MailCityLabel.Text = "Some value";
                    
                    
        }
                
        public virtual void SetMailStateLabel()
                  {
                  
                      //Code for the text property is generated inside the .aspx file. 
                      //To override this property you can uncomment the following property and add you own value.
                      //this.MailStateLabel.Text = "Some value";
                    
                    
        }
                
        public virtual void SetMailStateLabel1()
                  {
                  
                      //Code for the text property is generated inside the .aspx file. 
                      //To override this property you can uncomment the following property and add you own value.
                      //this.MailStateLabel1.Text = "Some value";
                    
                    
        }
                
        public virtual void SetMailZipLabel()
                  {
                  
                      //Code for the text property is generated inside the .aspx file. 
                      //To override this property you can uncomment the following property and add you own value.
                      //this.MailZipLabel.Text = "Some value";
                    
                    
        }
                
        public virtual void SetPOCLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOCNameLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOCNameLabel1()
                  {
                  
                    
        }
                
        public virtual void SetSalesPersonLabel()
                  {
                  
                    
        }
                
        public virtual void SetSalesPersonNameLabel()
                  {
                  
                    
        }
                
        public virtual void SetSalesPersonNameLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVPCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPCustomerLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPCustomerNameLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPCustomerNameLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVPJobDescLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPJobLabel()
                  {
                  
                    
        }
                
        public virtual void SetGLDepartmentNumberFilter()
        {
            
            this.PopulateGLDepartmentNumberFilter(MiscUtils.GetSelectedValue(this.GLDepartmentNumberFilter,  GetFromSession(this.GLDepartmentNumberFilter)), 500);					
                                     
        }
            
        public virtual void SetJobStatusFilter()
        {
            
            this.PopulateJobStatusFilter(MiscUtils.GetSelectedValue(this.JobStatusFilter,  GetFromSession(this.JobStatusFilter)), 500);					
                                     
        }
            
        public virtual void SetMailStateFilter()
        {
            
            ArrayList MailStateFilterselectedFilterItemList = new ArrayList();
            string MailStateFilteritemsString = null;
            if (this.InSession(this.MailStateFilter))
                MailStateFilteritemsString = this.GetFromSession(this.MailStateFilter);
            
            if (MailStateFilteritemsString != null)
            {
                string[] MailStateFilteritemListFromSession = MailStateFilteritemsString.Split(',');
                foreach (string item in MailStateFilteritemListFromSession)
                {
                    MailStateFilterselectedFilterItemList.Add(item);
                }
            }
              
            			
            this.PopulateMailStateFilter(MiscUtils.GetSelectedValueList(this.MailStateFilter, MailStateFilterselectedFilterItemList), 500);
                    
              string url = this.ModifyRedirectUrl("../mvwISDJobXref/MvwISDJobXref-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.MailStateFilter.PostBackUrl = url + "?Target=" + this.MailStateFilter.ClientID + "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("MailState")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--PLEASE_SELECT--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:PleaseSelect")) + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.MailStateFilter.Attributes["onClick"] = "initializePopupPage(this, '" + this.MailStateFilter.PostBackUrl + "', false, event); return false;";                  
                                   
        }
            
        public virtual void SetPOCNameFilter()
        {
            
            ArrayList POCNameFilterselectedFilterItemList = new ArrayList();
            string POCNameFilteritemsString = null;
            if (this.InSession(this.POCNameFilter))
                POCNameFilteritemsString = this.GetFromSession(this.POCNameFilter);
            
            if (POCNameFilteritemsString != null)
            {
                string[] POCNameFilteritemListFromSession = POCNameFilteritemsString.Split(',');
                foreach (string item in POCNameFilteritemListFromSession)
                {
                    POCNameFilterselectedFilterItemList.Add(item);
                }
            }
              
            			
            this.PopulatePOCNameFilter(MiscUtils.GetSelectedValueList(this.POCNameFilter, POCNameFilterselectedFilterItemList), 500);
                    
              string url = this.ModifyRedirectUrl("../mvwISDJobXref/MvwISDJobXref-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.POCNameFilter.PostBackUrl = url + "?Target=" + this.POCNameFilter.ClientID + "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("POCName")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--PLEASE_SELECT--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:PleaseSelect")) + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.POCNameFilter.Attributes["onClick"] = "initializePopupPage(this, '" + this.POCNameFilter.PostBackUrl + "', false, event); return false;";                  
                                   
        }
            
        public virtual void SetSalesPersonNameFilter()
        {
            
            ArrayList SalesPersonNameFilterselectedFilterItemList = new ArrayList();
            string SalesPersonNameFilteritemsString = null;
            if (this.InSession(this.SalesPersonNameFilter))
                SalesPersonNameFilteritemsString = this.GetFromSession(this.SalesPersonNameFilter);
            
            if (SalesPersonNameFilteritemsString != null)
            {
                string[] SalesPersonNameFilteritemListFromSession = SalesPersonNameFilteritemsString.Split(',');
                foreach (string item in SalesPersonNameFilteritemListFromSession)
                {
                    SalesPersonNameFilterselectedFilterItemList.Add(item);
                }
            }
              
            			
            this.PopulateSalesPersonNameFilter(MiscUtils.GetSelectedValueList(this.SalesPersonNameFilter, SalesPersonNameFilterselectedFilterItemList), 500);
                    
              string url = this.ModifyRedirectUrl("../mvwISDJobXref/MvwISDJobXref-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.SalesPersonNameFilter.PostBackUrl = url + "?Target=" + this.SalesPersonNameFilter.ClientID + "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("SalesPersonName")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--PLEASE_SELECT--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:PleaseSelect")) + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.SalesPersonNameFilter.Attributes["onClick"] = "initializePopupPage(this, '" + this.SalesPersonNameFilter.PostBackUrl + "', false, event); return false;";                  
                                   
        }
            
        public virtual void SetSearchText()
        {
                                            
            this.SearchText.Attributes.Add("onfocus", "if(this.value=='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "') {this.value='';this.className='Search_Input';}");
            this.SearchText.Attributes.Add("onblur", "if(this.value=='') {this.value='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "';this.className='Search_InputHint';}");
                                   
        }
            
        public virtual void SetVPCustomerNameFilter()
        {
            
            ArrayList VPCustomerNameFilterselectedFilterItemList = new ArrayList();
            string VPCustomerNameFilteritemsString = null;
            if (this.InSession(this.VPCustomerNameFilter))
                VPCustomerNameFilteritemsString = this.GetFromSession(this.VPCustomerNameFilter);
            
            if (VPCustomerNameFilteritemsString != null)
            {
                string[] VPCustomerNameFilteritemListFromSession = VPCustomerNameFilteritemsString.Split(',');
                foreach (string item in VPCustomerNameFilteritemListFromSession)
                {
                    VPCustomerNameFilterselectedFilterItemList.Add(item);
                }
            }
              
            			
            this.PopulateVPCustomerNameFilter(MiscUtils.GetSelectedValueList(this.VPCustomerNameFilter, VPCustomerNameFilterselectedFilterItemList), 500);
                    
              string url = this.ModifyRedirectUrl("../mvwISDJobXref/MvwISDJobXref-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.VPCustomerNameFilter.PostBackUrl = url + "?Target=" + this.VPCustomerNameFilter.ClientID + "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("VPCustomerName")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--PLEASE_SELECT--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:PleaseSelect")) + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.VPCustomerNameFilter.Attributes["onClick"] = "initializePopupPage(this, '" + this.VPCustomerNameFilter.PostBackUrl + "', false, event); return false;";                  
                                   
        }
            
        // Get the filters' data for GLDepartmentNumberFilter.
                
        protected virtual void PopulateGLDepartmentNumberFilter(string selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            this.GLDepartmentNumberFilter.Items.Clear();
            WhereClause wc = this.CreateWhereClause_GLDepartmentNumberFilter();            
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_GLDepartmentNumberFilter function.
            // It is better to customize the where clause there.
          
            // Setup the static list items        
            
            // Add the Please Select item.
            this.GLDepartmentNumberFilter.Items.Insert(0, new ListItem(this.Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
                            
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDJobXrefView.GLDepartmentNumber, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDJobXrefView.GetValues(MvwISDJobXrefView.GLDepartmentNumber, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDJobXrefView.GLDepartmentNumber.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDJobXrefView.GLDepartmentNumber.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.GLDepartmentNumberFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.GLDepartmentNumberFilter.Items.Add(newItem);

                if (listDuplicates.Contains(fvalue) &&  !string.IsNullOrEmpty(cvalue)) {
                    newItem.Text = fvalue + " (ID " + cvalue.Substring(0, Math.Min(cvalue.Length,38)) + ")";
                }
            }

                          
            try
            {
      
                
                // Set the selected value.
                MiscUtils.SetSelectedValue(this.GLDepartmentNumberFilter, selectedValue);
                
            }
            catch
            {
            }
            
            
            if (this.GLDepartmentNumberFilter.SelectedValue != null && this.GLDepartmentNumberFilter.Items.FindByValue(this.GLDepartmentNumberFilter.SelectedValue) == null)
                this.GLDepartmentNumberFilter.SelectedValue = null;
                           
        }
            
        // Get the filters' data for JobStatusFilter.
                
        protected virtual void PopulateJobStatusFilter(string selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            this.JobStatusFilter.Items.Clear();
            WhereClause wc = this.CreateWhereClause_JobStatusFilter();            
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_JobStatusFilter function.
            // It is better to customize the where clause there.
          
            // Setup the static list items        
            
            // Add the Please Select item.
            this.JobStatusFilter.Items.Insert(0, new ListItem(this.Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
                            
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDJobXrefView.JobStatus, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDJobXrefView.GetValues(MvwISDJobXrefView.JobStatus, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDJobXrefView.JobStatus.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDJobXrefView.JobStatus.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.JobStatusFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.JobStatusFilter.Items.Add(newItem);

                if (listDuplicates.Contains(fvalue) &&  !string.IsNullOrEmpty(cvalue)) {
                    newItem.Text = fvalue + " (ID " + cvalue.Substring(0, Math.Min(cvalue.Length,38)) + ")";
                }
            }

                          
            try
            {
      
                
                // Set the selected value.
                MiscUtils.SetSelectedValue(this.JobStatusFilter, selectedValue);
                
            }
            catch
            {
            }
            
            
            if (this.JobStatusFilter.SelectedValue != null && this.JobStatusFilter.Items.FindByValue(this.JobStatusFilter.SelectedValue) == null)
                this.JobStatusFilter.SelectedValue = null;
                           
        }
            
        // Get the filters' data for MailStateFilter.
                
        protected virtual void PopulateMailStateFilter(ArrayList selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            WhereClause wc = this.CreateWhereClause_MailStateFilter();            
            this.MailStateFilter.Items.Clear();
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_MailStateFilter function.
            // It is better to customize the where clause there.
          
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDJobXrefView.MailState, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDJobXrefView.GetValues(MvwISDJobXrefView.MailState, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDJobXrefView.MailState.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDJobXrefView.MailState.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.MailStateFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.MailStateFilter.Items.Add(newItem);

                if (listDuplicates.Contains(fvalue) &&  !string.IsNullOrEmpty(cvalue)) {
                    newItem.Text = fvalue + " (ID " + cvalue.Substring(0, Math.Min(cvalue.Length,38)) + ")";
                }
            }

                          
            try
            {
      
                
            }
            catch
            {
            }
            
            
            this.MailStateFilter.SetFieldMaxLength(50);
                                 
                  
            // Add the selected value.
            if (this.MailStateFilter.Items.Count == 0)
                this.MailStateFilter.Items.Add(new ListItem(Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
            
            // Mark all items to be selected.
            foreach (ListItem item in this.MailStateFilter.Items)
            {
                item.Selected = true;
            }
                               
        }
            
        // Get the filters' data for POCNameFilter.
                
        protected virtual void PopulatePOCNameFilter(ArrayList selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            WhereClause wc = this.CreateWhereClause_POCNameFilter();            
            this.POCNameFilter.Items.Clear();
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_POCNameFilter function.
            // It is better to customize the where clause there.
          
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDJobXrefView.POCName, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDJobXrefView.GetValues(MvwISDJobXrefView.POCName, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDJobXrefView.POCName.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDJobXrefView.POCName.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.POCNameFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.POCNameFilter.Items.Add(newItem);

                if (listDuplicates.Contains(fvalue) &&  !string.IsNullOrEmpty(cvalue)) {
                    newItem.Text = fvalue + " (ID " + cvalue.Substring(0, Math.Min(cvalue.Length,38)) + ")";
                }
            }

                          
            try
            {
      
                
            }
            catch
            {
            }
            
            
            this.POCNameFilter.SetFieldMaxLength(50);
                                 
                  
            // Add the selected value.
            if (this.POCNameFilter.Items.Count == 0)
                this.POCNameFilter.Items.Add(new ListItem(Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
            
            // Mark all items to be selected.
            foreach (ListItem item in this.POCNameFilter.Items)
            {
                item.Selected = true;
            }
                               
        }
            
        // Get the filters' data for SalesPersonNameFilter.
                
        protected virtual void PopulateSalesPersonNameFilter(ArrayList selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            WhereClause wc = this.CreateWhereClause_SalesPersonNameFilter();            
            this.SalesPersonNameFilter.Items.Clear();
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_SalesPersonNameFilter function.
            // It is better to customize the where clause there.
          
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDJobXrefView.SalesPersonName, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDJobXrefView.GetValues(MvwISDJobXrefView.SalesPersonName, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDJobXrefView.SalesPersonName.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDJobXrefView.SalesPersonName.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.SalesPersonNameFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.SalesPersonNameFilter.Items.Add(newItem);

                if (listDuplicates.Contains(fvalue) &&  !string.IsNullOrEmpty(cvalue)) {
                    newItem.Text = fvalue + " (ID " + cvalue.Substring(0, Math.Min(cvalue.Length,38)) + ")";
                }
            }

                          
            try
            {
      
                
            }
            catch
            {
            }
            
            
            this.SalesPersonNameFilter.SetFieldMaxLength(50);
                                 
                  
            // Add the selected value.
            if (this.SalesPersonNameFilter.Items.Count == 0)
                this.SalesPersonNameFilter.Items.Add(new ListItem(Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
            
            // Mark all items to be selected.
            foreach (ListItem item in this.SalesPersonNameFilter.Items)
            {
                item.Selected = true;
            }
                               
        }
            
        // Get the filters' data for VPCustomerNameFilter.
                
        protected virtual void PopulateVPCustomerNameFilter(ArrayList selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            WhereClause wc = this.CreateWhereClause_VPCustomerNameFilter();            
            this.VPCustomerNameFilter.Items.Clear();
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_VPCustomerNameFilter function.
            // It is better to customize the where clause there.
          
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDJobXrefView.VPCustomerName, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDJobXrefView.GetValues(MvwISDJobXrefView.VPCustomerName, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDJobXrefView.VPCustomerName.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDJobXrefView.VPCustomerName.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.VPCustomerNameFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.VPCustomerNameFilter.Items.Add(newItem);

                if (listDuplicates.Contains(fvalue) &&  !string.IsNullOrEmpty(cvalue)) {
                    newItem.Text = fvalue + " (ID " + cvalue.Substring(0, Math.Min(cvalue.Length,38)) + ")";
                }
            }

                          
            try
            {
      
                
            }
            catch
            {
            }
            
            
            this.VPCustomerNameFilter.SetFieldMaxLength(50);
                                 
                  
            // Add the selected value.
            if (this.VPCustomerNameFilter.Items.Count == 0)
                this.VPCustomerNameFilter.Items.Add(new ListItem(Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
            
            // Mark all items to be selected.
            foreach (ListItem item in this.VPCustomerNameFilter.Items)
            {
                item.Selected = true;
            }
                               
        }
            
        public virtual WhereClause CreateWhereClause_GLDepartmentNumberFilter()
        {
            // Create a where clause for the filter GLDepartmentNumberFilter.
            // This function is called by the Populate method to load the items 
            // in the GLDepartmentNumberFilterDropDownList
        
            WhereClause wc = new WhereClause();
            return wc;
            
        }
      
        public virtual WhereClause CreateWhereClause_JobStatusFilter()
        {
            // Create a where clause for the filter JobStatusFilter.
            // This function is called by the Populate method to load the items 
            // in the JobStatusFilterDropDownList
        
            WhereClause wc = new WhereClause();
            return wc;
            
        }
      
        public virtual WhereClause CreateWhereClause_MailStateFilter()
        {
            // Create a where clause for the filter MailStateFilter.
            // This function is called by the Populate method to load the items 
            // in the MailStateFilterQuickSelector
        
            ArrayList MailStateFilterselectedFilterItemList = new ArrayList();
            string MailStateFilteritemsString = null;
            if (this.InSession(this.MailStateFilter))
                MailStateFilteritemsString = this.GetFromSession(this.MailStateFilter);
            
            if (MailStateFilteritemsString != null)
            {
                string[] MailStateFilteritemListFromSession = MailStateFilteritemsString.Split(',');
                foreach (string item in MailStateFilteritemListFromSession)
                {
                    MailStateFilterselectedFilterItemList.Add(item);
                }
            }
              
            MailStateFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.MailStateFilter, MailStateFilterselectedFilterItemList); 
            WhereClause wc = new WhereClause();
            if (MailStateFilterselectedFilterItemList == null || MailStateFilterselectedFilterItemList.Count == 0)
                wc.RunQuery = false;
            else            
            {
                foreach (string item in MailStateFilterselectedFilterItemList)
                {
            
      
   
                    wc.iOR(MvwISDJobXrefView.MailState, BaseFilter.ComparisonOperator.EqualsTo, item);

                                
                }
            }
            return wc;
        
        }
      
        public virtual WhereClause CreateWhereClause_POCNameFilter()
        {
            // Create a where clause for the filter POCNameFilter.
            // This function is called by the Populate method to load the items 
            // in the POCNameFilterQuickSelector
        
            ArrayList POCNameFilterselectedFilterItemList = new ArrayList();
            string POCNameFilteritemsString = null;
            if (this.InSession(this.POCNameFilter))
                POCNameFilteritemsString = this.GetFromSession(this.POCNameFilter);
            
            if (POCNameFilteritemsString != null)
            {
                string[] POCNameFilteritemListFromSession = POCNameFilteritemsString.Split(',');
                foreach (string item in POCNameFilteritemListFromSession)
                {
                    POCNameFilterselectedFilterItemList.Add(item);
                }
            }
              
            POCNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.POCNameFilter, POCNameFilterselectedFilterItemList); 
            WhereClause wc = new WhereClause();
            if (POCNameFilterselectedFilterItemList == null || POCNameFilterselectedFilterItemList.Count == 0)
                wc.RunQuery = false;
            else            
            {
                foreach (string item in POCNameFilterselectedFilterItemList)
                {
            
      
   
                    wc.iOR(MvwISDJobXrefView.POCName, BaseFilter.ComparisonOperator.EqualsTo, item);

                                
                }
            }
            return wc;
        
        }
      
        public virtual WhereClause CreateWhereClause_SalesPersonNameFilter()
        {
            // Create a where clause for the filter SalesPersonNameFilter.
            // This function is called by the Populate method to load the items 
            // in the SalesPersonNameFilterQuickSelector
        
            ArrayList SalesPersonNameFilterselectedFilterItemList = new ArrayList();
            string SalesPersonNameFilteritemsString = null;
            if (this.InSession(this.SalesPersonNameFilter))
                SalesPersonNameFilteritemsString = this.GetFromSession(this.SalesPersonNameFilter);
            
            if (SalesPersonNameFilteritemsString != null)
            {
                string[] SalesPersonNameFilteritemListFromSession = SalesPersonNameFilteritemsString.Split(',');
                foreach (string item in SalesPersonNameFilteritemListFromSession)
                {
                    SalesPersonNameFilterselectedFilterItemList.Add(item);
                }
            }
              
            SalesPersonNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.SalesPersonNameFilter, SalesPersonNameFilterselectedFilterItemList); 
            WhereClause wc = new WhereClause();
            if (SalesPersonNameFilterselectedFilterItemList == null || SalesPersonNameFilterselectedFilterItemList.Count == 0)
                wc.RunQuery = false;
            else            
            {
                foreach (string item in SalesPersonNameFilterselectedFilterItemList)
                {
            
      
   
                    wc.iOR(MvwISDJobXrefView.SalesPersonName, BaseFilter.ComparisonOperator.EqualsTo, item);

                                
                }
            }
            return wc;
        
        }
      
        public virtual WhereClause CreateWhereClause_VPCustomerNameFilter()
        {
            // Create a where clause for the filter VPCustomerNameFilter.
            // This function is called by the Populate method to load the items 
            // in the VPCustomerNameFilterQuickSelector
        
            ArrayList VPCustomerNameFilterselectedFilterItemList = new ArrayList();
            string VPCustomerNameFilteritemsString = null;
            if (this.InSession(this.VPCustomerNameFilter))
                VPCustomerNameFilteritemsString = this.GetFromSession(this.VPCustomerNameFilter);
            
            if (VPCustomerNameFilteritemsString != null)
            {
                string[] VPCustomerNameFilteritemListFromSession = VPCustomerNameFilteritemsString.Split(',');
                foreach (string item in VPCustomerNameFilteritemListFromSession)
                {
                    VPCustomerNameFilterselectedFilterItemList.Add(item);
                }
            }
              
            VPCustomerNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.VPCustomerNameFilter, VPCustomerNameFilterselectedFilterItemList); 
            WhereClause wc = new WhereClause();
            if (VPCustomerNameFilterselectedFilterItemList == null || VPCustomerNameFilterselectedFilterItemList.Count == 0)
                wc.RunQuery = false;
            else            
            {
                foreach (string item in VPCustomerNameFilterselectedFilterItemList)
                {
            
      
   
                    wc.iOR(MvwISDJobXrefView.VPCustomerName, BaseFilter.ComparisonOperator.EqualsTo, item);

                                
                }
            }
            return wc;
        
        }
      

    
        protected virtual void Control_PreRender(object sender, System.EventArgs e)
        {
            // PreRender event is raised just before page is being displayed.
            try {
                DbUtils.StartTransaction();
                this.RegisterPostback();
                if (!this.Page.ErrorOnPage && (this.Page.IsPageRefresh || this.DataChanged || this.ResetData)) {
                  
                
                    // Re-load the data and update the web page if necessary.
                    // This is typically done during a postback (filter, search button, sort, pagination button).
                    // In each of the other click handlers, simply set DataChanged to True to reload the data.
                    
                    this.LoadData();
                    this.DataBind();					
                    
                }
                                
            } catch (Exception ex) {
                BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
            } finally {
                DbUtils.EndTransaction();
            }
        }
        
        
        protected override void SaveControlsToSession()
        {
            base.SaveControlsToSession();
            // Save filter controls to values to session.
        
            this.SaveToSession(this.GLDepartmentNumberFilter, this.GLDepartmentNumberFilter.SelectedValue);
                  
            this.SaveToSession(this.JobStatusFilter, this.JobStatusFilter.SelectedValue);
                  
            ArrayList MailStateFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.MailStateFilter, null);
            string MailStateFilterSessionString = "";
            if (MailStateFilterselectedFilterItemList != null){
                foreach (string item in MailStateFilterselectedFilterItemList){
                    MailStateFilterSessionString = String.Concat(MailStateFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession(this.MailStateFilter, MailStateFilterSessionString);
                  
            ArrayList POCNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.POCNameFilter, null);
            string POCNameFilterSessionString = "";
            if (POCNameFilterselectedFilterItemList != null){
                foreach (string item in POCNameFilterselectedFilterItemList){
                    POCNameFilterSessionString = String.Concat(POCNameFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession(this.POCNameFilter, POCNameFilterSessionString);
                  
            ArrayList SalesPersonNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.SalesPersonNameFilter, null);
            string SalesPersonNameFilterSessionString = "";
            if (SalesPersonNameFilterselectedFilterItemList != null){
                foreach (string item in SalesPersonNameFilterselectedFilterItemList){
                    SalesPersonNameFilterSessionString = String.Concat(SalesPersonNameFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession(this.SalesPersonNameFilter, SalesPersonNameFilterSessionString);
                  
            this.SaveToSession(this.SearchText, this.SearchText.Text);
                  
            ArrayList VPCustomerNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.VPCustomerNameFilter, null);
            string VPCustomerNameFilterSessionString = "";
            if (VPCustomerNameFilterselectedFilterItemList != null){
                foreach (string item in VPCustomerNameFilterselectedFilterItemList){
                    VPCustomerNameFilterSessionString = String.Concat(VPCustomerNameFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession(this.VPCustomerNameFilter, VPCustomerNameFilterSessionString);
                  
            
                    
            // Save pagination state to session.
         
    
            // Save table control properties to the session.
          
            if (this.CurrentSortOrder != null) {
                this.SaveToSession(this, "Order_By", this.CurrentSortOrder.ToXmlString());
            }
          
            this.SaveToSession(this, "Page_Index", this.PageIndex.ToString());
            this.SaveToSession(this, "Page_Size", this.PageSize.ToString());
          
            this.SaveToSession(this, "DeletedRecordIds", this.DeletedRecordIds);
        
        }
        
        
        protected  void SaveControlsToSession_Ajax()
        {
            // Save filter controls to values to session.
          
      this.SaveToSession("GLDepartmentNumberFilter_Ajax", this.GLDepartmentNumberFilter.SelectedValue);
              
      this.SaveToSession("JobStatusFilter_Ajax", this.JobStatusFilter.SelectedValue);
              
            ArrayList MailStateFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.MailStateFilter, null);
            string MailStateFilterSessionString = "";
            if (MailStateFilterselectedFilterItemList != null){
                foreach (string item in MailStateFilterselectedFilterItemList){
                    MailStateFilterSessionString = String.Concat(MailStateFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession("MailStateFilter_Ajax", MailStateFilterSessionString);
          
            ArrayList POCNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.POCNameFilter, null);
            string POCNameFilterSessionString = "";
            if (POCNameFilterselectedFilterItemList != null){
                foreach (string item in POCNameFilterselectedFilterItemList){
                    POCNameFilterSessionString = String.Concat(POCNameFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession("POCNameFilter_Ajax", POCNameFilterSessionString);
          
            ArrayList SalesPersonNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.SalesPersonNameFilter, null);
            string SalesPersonNameFilterSessionString = "";
            if (SalesPersonNameFilterselectedFilterItemList != null){
                foreach (string item in SalesPersonNameFilterselectedFilterItemList){
                    SalesPersonNameFilterSessionString = String.Concat(SalesPersonNameFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession("SalesPersonNameFilter_Ajax", SalesPersonNameFilterSessionString);
          
      this.SaveToSession("SearchText_Ajax", this.SearchText.Text);
              
            ArrayList VPCustomerNameFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.VPCustomerNameFilter, null);
            string VPCustomerNameFilterSessionString = "";
            if (VPCustomerNameFilterselectedFilterItemList != null){
                foreach (string item in VPCustomerNameFilterselectedFilterItemList){
                    VPCustomerNameFilterSessionString = String.Concat(VPCustomerNameFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession("VPCustomerNameFilter_Ajax", VPCustomerNameFilterSessionString);
          
           HttpContext.Current.Session["AppRelativeVirtualPath"] = this.Page.AppRelativeVirtualPath;
         
        }
        
        
        protected override void ClearControlsFromSession()
        {
            base.ClearControlsFromSession();
            // Clear filter controls values from the session.
        
            this.RemoveFromSession(this.GLDepartmentNumberFilter);
            this.RemoveFromSession(this.JobStatusFilter);
            this.RemoveFromSession(this.MailStateFilter);
            this.RemoveFromSession(this.POCNameFilter);
            this.RemoveFromSession(this.SalesPersonNameFilter);
            this.RemoveFromSession(this.SearchText);
            this.RemoveFromSession(this.VPCustomerNameFilter);
            
            // Clear pagination state from session.
         

    // Clear table properties from the session.
    this.RemoveFromSession(this, "Order_By");
    this.RemoveFromSession(this, "Page_Index");
    this.RemoveFromSession(this, "Page_Size");
    
            this.RemoveFromSession(this, "DeletedRecordIds");
            
        }

        protected override void LoadViewState(object savedState)
        {
            base.LoadViewState(savedState);

            string orderByStr = (string)ViewState["MvwISDJobXrefTableControl_OrderBy"];
          
            if (orderByStr != null && orderByStr.Length > 0) {
                this.CurrentSortOrder = BaseClasses.Data.OrderBy.FromXmlString(orderByStr);
            }
          
            else {
                this.CurrentSortOrder = new OrderBy(true, false);
            }
          

            if (ViewState["Page_Index"] != null) {
              this.PageIndex = (int)ViewState["Page_Index"];
            }
            
            Control Pagination = this.FindControl("Pagination");
            String PaginationType = "";
            if (Pagination != null){
              Control Summary = Pagination.FindControl("_Summary");
              if (Summary != null){
                if (((System.Web.UI.WebControls.TextBox)(Summary)).Text == "Infinite Pagination"){
                  PaginationType = "Infinite Pagination";
                }
              }
            }
            
            if (PaginationType.Equals("Infinite Pagination")){
              if (ViewState["Page_Size"] != null && this.PageSize == 0){
                this.PageSize = (int)ViewState["Page_Size"];
              }
            }else{
              if (ViewState["Page_Size"] != null){
                this.PageSize = (int)ViewState["Page_Size"];
              }
            }
            
          
            // Load view state for pagination control.
    
            this.DeletedRecordIds = (string)this.ViewState["DeletedRecordIds"];
        
        }

        protected override object SaveViewState()
        {            
          
            if (this.CurrentSortOrder != null) {
                this.ViewState["MvwISDJobXrefTableControl_OrderBy"] = this.CurrentSortOrder.ToXmlString();
            }
          

    this.ViewState["Page_Index"] = this.PageIndex;
    this.ViewState["Page_Size"] = this.PageSize;
    
            this.ViewState["DeletedRecordIds"] = this.DeletedRecordIds;
        
    
            // Load view state for pagination control.
              
            return (base.SaveViewState());
        }

        // Generate set method for buttons
        
        public virtual void SetExcelButton()                
              
        {
        
   
        }
            
        public virtual void SetImportButton()                
              
        {
        							
                    this.ImportButton.PostBackUrl = "../Shared/SelectFileToImport.aspx?TableName=MvwISDJobXref" ;
                    this.ImportButton.Attributes["onClick"] = "window.open('" + this.Page.EncryptUrlParameter(this.ImportButton.PostBackUrl) + "','importWindow', 'width=700, height=500,top=' +(screen.availHeight-500)/2 + ',left=' + (screen.availWidth-700)/2+ ', resizable=yes, scrollbars=yes,modal=yes'); return false;";
                        
   
        }
            
        public virtual void SetPDFButton()                
              
        {
        
   
        }
            
        public virtual void SetResetButton()                
              
        {
        
   
        }
            
        public virtual void SetSearchButton()                
              
        {
        
   
        }
            
        public virtual void SetWordButton()                
              
        {
        
   
        }
            
        public virtual void SetActionsButton()                
              
        {
        
   
        }
            
        public virtual void SetFilterButton()                
              
        {
        
   
        }
            
        public virtual void SetFiltersButton()                
              
        {
                
         IThemeButtonWithArrow themeButtonFiltersButton = (IThemeButtonWithArrow)(MiscUtils.FindControlRecursively(this, "FiltersButton"));
         themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonExpandArrow.png";
    
      
            if (MiscUtils.IsValueSelected(GLDepartmentNumberFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
            if (MiscUtils.IsValueSelected(JobStatusFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
            if (MiscUtils.IsValueSelected(MailStateFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
            if (MiscUtils.IsValueSelected(POCNameFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
            if (MiscUtils.IsValueSelected(SalesPersonNameFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
            if (MiscUtils.IsValueSelected(VPCustomerNameFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
   
        }
               
        
        // Generate the event handling functions for pagination events.
        
        // event handler for ImageButton
        public virtual void Pagination_FirstPage_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                
            this.PageIndex = 0;
            this.DataChanged = true;
      
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void Pagination_LastPage_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                
            this.DisplayLastPage = true;
            this.DataChanged = true;
      
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void Pagination_NextPage_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                
            this.PageIndex += 1;
            this.DataChanged = true;
      
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for LinkButton
        public virtual void Pagination_PageSizeButton_Click(object sender, EventArgs args)
        {
              
            try {
                
            this.DataChanged = true;
      
            this.PageSize = this.Pagination.GetCurrentPageSize();
      
            this.PageIndex = Convert.ToInt32(this.Pagination.CurrentPage.Text) - 1;
      
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void Pagination_PreviousPage_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                
            if (this.PageIndex > 0) {
                this.PageIndex -= 1;
                this.DataChanged = true;
            }
      
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        

        // Generate the event handling functions for sorting events.
        
        public virtual void CGCCoLabel_Click(object sender, EventArgs args)
        {
            //Sorts by CGCCo when clicked.
              
            // Get previous sorting state for CGCCo.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.CGCCo);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for CGCCo.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.CGCCo, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by CGCCo, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void CGCJobLabel_Click(object sender, EventArgs args)
        {
            //Sorts by CGCJob when clicked.
              
            // Get previous sorting state for CGCJob.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.CGCJob);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for CGCJob.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.CGCJob, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by CGCJob, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void GLDepartmentNameLabel_Click(object sender, EventArgs args)
        {
            //Sorts by GLDepartmentName when clicked.
              
            // Get previous sorting state for GLDepartmentName.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.GLDepartmentName);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for GLDepartmentName.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.GLDepartmentName, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by GLDepartmentName, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void GLDepartmentNumberLabel_Click(object sender, EventArgs args)
        {
            //Sorts by GLDepartmentNumber when clicked.
              
            // Get previous sorting state for GLDepartmentNumber.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.GLDepartmentNumber);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for GLDepartmentNumber.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.GLDepartmentNumber, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by GLDepartmentNumber, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void JobStatusLabel1_Click(object sender, EventArgs args)
        {
            //Sorts by JobStatus when clicked.
              
            // Get previous sorting state for JobStatus.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.JobStatus);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for JobStatus.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.JobStatus, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by JobStatus, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void MailAddress2Label_Click(object sender, EventArgs args)
        {
            //Sorts by MailAddress2 when clicked.
              
            // Get previous sorting state for MailAddress2.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.MailAddress2);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for MailAddress2.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.MailAddress2, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by MailAddress2, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void MailAddressLabel_Click(object sender, EventArgs args)
        {
            //Sorts by MailAddress when clicked.
              
            // Get previous sorting state for MailAddress.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.MailAddress);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for MailAddress.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.MailAddress, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by MailAddress, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void MailCityLabel_Click(object sender, EventArgs args)
        {
            //Sorts by MailCity when clicked.
              
            // Get previous sorting state for MailCity.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.MailCity);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for MailCity.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.MailCity, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by MailCity, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void MailStateLabel_Click(object sender, EventArgs args)
        {
            //Sorts by MailState when clicked.
              
            // Get previous sorting state for MailState.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.MailState);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for MailState.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.MailState, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by MailState, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void MailZipLabel_Click(object sender, EventArgs args)
        {
            //Sorts by MailZip when clicked.
              
            // Get previous sorting state for MailZip.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.MailZip);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for MailZip.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.MailZip, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by MailZip, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void POCLabel_Click(object sender, EventArgs args)
        {
            //Sorts by POC when clicked.
              
            // Get previous sorting state for POC.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.POC);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for POC.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.POC, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by POC, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void POCNameLabel_Click(object sender, EventArgs args)
        {
            //Sorts by POCName when clicked.
              
            // Get previous sorting state for POCName.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.POCName);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for POCName.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.POCName, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by POCName, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void SalesPersonLabel_Click(object sender, EventArgs args)
        {
            //Sorts by SalesPerson when clicked.
              
            // Get previous sorting state for SalesPerson.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.SalesPerson);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for SalesPerson.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.SalesPerson, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by SalesPerson, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void SalesPersonNameLabel_Click(object sender, EventArgs args)
        {
            //Sorts by SalesPersonName when clicked.
              
            // Get previous sorting state for SalesPersonName.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.SalesPersonName);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for SalesPersonName.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.SalesPersonName, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by SalesPersonName, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void VPCoLabel_Click(object sender, EventArgs args)
        {
            //Sorts by VPCo when clicked.
              
            // Get previous sorting state for VPCo.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.VPCo);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for VPCo.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.VPCo, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by VPCo, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void VPCustomerLabel_Click(object sender, EventArgs args)
        {
            //Sorts by VPCustomer when clicked.
              
            // Get previous sorting state for VPCustomer.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.VPCustomer);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for VPCustomer.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.VPCustomer, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by VPCustomer, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void VPCustomerNameLabel_Click(object sender, EventArgs args)
        {
            //Sorts by VPCustomerName when clicked.
              
            // Get previous sorting state for VPCustomerName.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.VPCustomerName);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for VPCustomerName.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.VPCustomerName, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by VPCustomerName, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void VPJobDescLabel_Click(object sender, EventArgs args)
        {
            //Sorts by VPJobDesc when clicked.
              
            // Get previous sorting state for VPJobDesc.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.VPJobDesc);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for VPJobDesc.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.VPJobDesc, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by VPJobDesc, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void VPJobLabel_Click(object sender, EventArgs args)
        {
            //Sorts by VPJob when clicked.
              
            // Get previous sorting state for VPJob.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobXrefView.VPJob);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for VPJob.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDJobXrefView.VPJob, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by VPJob, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            

        // Generate the event handling functions for button events.
        
        // event handler for ImageButton
        public virtual void ExcelButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                
            
            // To customize the columns or the format, override this function in Section 1 of the page
            // and modify it to your liking.
            // Build the where clause based on the current filter and search criteria
            // Create the Order By clause based on the user's current sorting preference.
            
                WhereClause wc = null;
                wc = CreateWhereClause();
                OrderBy orderBy = null;
              
                orderBy = CreateOrderBy();
              
              bool done = false;
              object val = "";
              CompoundFilter join = CreateCompoundJoinFilter();
              
              // Read pageSize records at a time and write out the Excel file.
              int totalRowsReturned = 0;


              this.TotalRecords = MvwISDJobXrefView.GetRecordCount(join, wc);
              if (this.TotalRecords > 10000)
              {
              
                // Add each of the columns in order of export.
                BaseColumn[] columns = new BaseColumn[] {
                             MvwISDJobXrefView.VPCo,
             MvwISDJobXrefView.VPJob,
             MvwISDJobXrefView.CGCCo,
             MvwISDJobXrefView.CGCJob,
             MvwISDJobXrefView.VPJobDesc,
             MvwISDJobXrefView.VPCustomer,
             MvwISDJobXrefView.VPCustomerName,
             MvwISDJobXrefView.MailAddress,
             MvwISDJobXrefView.MailAddress2,
             MvwISDJobXrefView.MailCity,
             MvwISDJobXrefView.MailState,
             MvwISDJobXrefView.MailZip,
             MvwISDJobXrefView.POC,
             MvwISDJobXrefView.POCName,
             MvwISDJobXrefView.SalesPerson,
             MvwISDJobXrefView.SalesPersonName,
             MvwISDJobXrefView.JobStatus,
             MvwISDJobXrefView.GLDepartmentNumber,
             MvwISDJobXrefView.GLDepartmentName,
             null};
                ExportDataToCSV exportData = new ExportDataToCSV(MvwISDJobXrefView.Instance,wc,orderBy,columns);
                exportData.StartExport(this.Page.Response, true);

                DataForExport dataForCSV = new DataForExport(MvwISDJobXrefView.Instance, wc, orderBy, columns,join);

                //  Read pageSize records at a time and write out the CSV file.
                while (!done)
                {
                ArrayList recList = dataForCSV.GetRows(exportData.pageSize);
                if (recList == null)
                break; //we are done

                totalRowsReturned = recList.Count;
                foreach (BaseRecord rec in recList)
                {
                foreach (BaseColumn col in dataForCSV.ColumnList)
                {
                if (col == null)
                continue;

                if (!dataForCSV.IncludeInExport(col))
                continue;

                val = rec.GetValue(col).ToString();
                exportData.WriteColumnData(val, dataForCSV.IsString(col));
                }
                exportData.WriteNewRow();
                }

                //  If we already are below the pageSize, then we are done.
                if (totalRowsReturned < exportData.pageSize)
                {
                done = true;
                }
                }
                exportData.FinishExport(this.Page.Response);
              
              }
              else
              {
              // Create an instance of the ExportDataToExcel class with the table class, where clause and order by.
              ExportDataToExcel excelReport = new ExportDataToExcel(MvwISDJobXrefView.Instance, wc, orderBy);
              // Add each of the columns in order of export.
              // To customize the data type, change the second parameter of the new ExcelColumn to be
              // a format string from Excel's Format Cell menu. For example "dddd, mmmm dd, yyyy h:mm AM/PM;@", "#,##0.00"

              if (this.Page.Response == null)
              return;

              excelReport.CreateExcelBook();

              int width = 0;
              int columnCounter = 0;
              DataForExport data = new DataForExport(MvwISDJobXrefView.Instance, wc, orderBy, null,join);
                           data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.VPCo, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.VPJob, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.CGCCo, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.CGCJob, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.VPJobDesc, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.VPCustomer, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.VPCustomerName, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.MailAddress, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.MailAddress2, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.MailCity, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.MailState, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.MailZip, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.POC, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.POCName, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.SalesPerson, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.SalesPersonName, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.JobStatus, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.GLDepartmentNumber, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobXrefView.GLDepartmentName, "Default"));


              //  First write out the Column Headers
              foreach (ExcelColumn col in data.ColumnList)
              {
              width = excelReport.GetExcelCellWidth(col);
              if (data.IncludeInExport(col))
              {
              excelReport.AddColumnToExcelBook(columnCounter, col.ToString(), excelReport.GetExcelDataType(col), width, excelReport.GetDisplayFormat(col));
              columnCounter++;
              }
              }
              
              while (!done)
              {
              ArrayList recList = data.GetRows(excelReport.pageSize);

              if (recList == null)
              {
              break;
              }
              totalRowsReturned = recList.Count;

              foreach (BaseRecord rec in recList)
              {
              excelReport.AddRowToExcelBook();
              columnCounter = 0;
              foreach (ExcelColumn col in data.ColumnList)
              {
              if (!data.IncludeInExport(col))
              continue;

              Boolean _isExpandableNonCompositeForeignKey = col.DisplayColumn.TableDefinition.IsExpandableNonCompositeForeignKey(col.DisplayColumn);
              if (_isExpandableNonCompositeForeignKey && col.DisplayColumn.IsApplyDisplayAs)
              {
                val = MvwISDJobXrefView.GetDFKA(rec.GetValue(col.DisplayColumn).ToString(), col.DisplayColumn, null) as string;
                if (String.IsNullOrEmpty(val as string))
                {
                  val = rec.Format(col.DisplayColumn);
                }
              }
              else
                val = excelReport.GetValueForExcelExport(col, rec);
              
              excelReport.AddCellToExcelRow(columnCounter, excelReport.GetExcelDataType(col), val, col.DisplayFormat);

              columnCounter++;
              }
              }

              // If we already are below the pageSize, then we are done.
              if (totalRowsReturned < excelReport.pageSize)
              {
              done = true;
              }
              }
              excelReport.SaveExcelBook(this.Page.Response);
              }
            
            } catch (Exception ex) {
                  // Upon error, rollback the transaction
                  this.Page.RollBackTransaction(sender);
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
                DbUtils.EndTransaction();
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void ImportButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                
            } catch (Exception ex) {
                  // Upon error, rollback the transaction
                  this.Page.RollBackTransaction(sender);
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
                DbUtils.EndTransaction();
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void PDFButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                

                PDFReport report = new PDFReport();

                report.SpecificReportFileName = Page.Server.MapPath("Show-MvwISDJobXref-Table.PDFButton.report");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "mvwISDJobXref";
                // If Show-MvwISDJobXref-Table.PDFButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.   
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(MvwISDJobXrefView.VPCo.Name, ReportEnum.Align.Right, "${VPCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.VPJob.Name, ReportEnum.Align.Left, "${VPJob}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobXrefView.CGCCo.Name, ReportEnum.Align.Right, "${CGCCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.CGCJob.Name, ReportEnum.Align.Left, "${CGCJob}", ReportEnum.Align.Left, 17);
                 report.AddColumn(MvwISDJobXrefView.VPJobDesc.Name, ReportEnum.Align.Left, "${VPJobDesc}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobXrefView.VPCustomer.Name, ReportEnum.Align.Right, "${VPCustomer}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.VPCustomerName.Name, ReportEnum.Align.Left, "${VPCustomerName}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobXrefView.MailAddress.Name, ReportEnum.Align.Left, "${MailAddress}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobXrefView.MailAddress2.Name, ReportEnum.Align.Left, "${MailAddress2}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobXrefView.MailCity.Name, ReportEnum.Align.Left, "${MailCity}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobXrefView.MailState.Name, ReportEnum.Align.Left, "${MailState}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobXrefView.MailZip.Name, ReportEnum.Align.Left, "${MailZip}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobXrefView.POC.Name, ReportEnum.Align.Right, "${POC}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.POCName.Name, ReportEnum.Align.Left, "${POCName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobXrefView.SalesPerson.Name, ReportEnum.Align.Right, "${SalesPerson}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.SalesPersonName.Name, ReportEnum.Align.Left, "${SalesPersonName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobXrefView.JobStatus.Name, ReportEnum.Align.Left, "${JobStatus}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobXrefView.GLDepartmentNumber.Name, ReportEnum.Align.Left, "${GLDepartmentNumber}", ReportEnum.Align.Left, 20);
                 report.AddColumn(MvwISDJobXrefView.GLDepartmentName.Name, ReportEnum.Align.Left, "${GLDepartmentName}", ReportEnum.Align.Left, 24);

  
                int rowsPerQuery = 5000;
                int recordCount = 0;
                                
                report.Page = Page.GetResourceValue("Txt:Page", "VPLookup");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                
                ColumnList columns = MvwISDJobXrefView.GetColumnList();
                
                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                
                int pageNum = 0;
                int totalRows = MvwISDJobXrefView.GetRecordCount(joinFilter,whereClause);
                MvwISDJobXrefRecord[] records = null;
                
                do
                {
                    
                    records = MvwISDJobXrefView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                     if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( MvwISDJobXrefRecord record in records)
                    
                        {
                            // AddData method takes four parameters   
                            // The 1st parameter represent the data format
                            // The 2nd parameter represent the data value
                            // The 3rd parameter represent the default alignment of column using the data
                            // The 4th parameter represent the maximum length of the data value being shown
                                                 report.AddData("${VPCo}", record.Format(MvwISDJobXrefView.VPCo), ReportEnum.Align.Right, 300);
                             report.AddData("${VPJob}", record.Format(MvwISDJobXrefView.VPJob), ReportEnum.Align.Left, 300);
                             report.AddData("${CGCCo}", record.Format(MvwISDJobXrefView.CGCCo), ReportEnum.Align.Right, 300);
                             report.AddData("${CGCJob}", record.Format(MvwISDJobXrefView.CGCJob), ReportEnum.Align.Left, 300);
                             report.AddData("${VPJobDesc}", record.Format(MvwISDJobXrefView.VPJobDesc), ReportEnum.Align.Left, 300);
                             report.AddData("${VPCustomer}", record.Format(MvwISDJobXrefView.VPCustomer), ReportEnum.Align.Right, 300);
                             report.AddData("${VPCustomerName}", record.Format(MvwISDJobXrefView.VPCustomerName), ReportEnum.Align.Left, 300);
                             report.AddData("${MailAddress}", record.Format(MvwISDJobXrefView.MailAddress), ReportEnum.Align.Left, 300);
                             report.AddData("${MailAddress2}", record.Format(MvwISDJobXrefView.MailAddress2), ReportEnum.Align.Left, 300);
                             report.AddData("${MailCity}", record.Format(MvwISDJobXrefView.MailCity), ReportEnum.Align.Left, 300);
                             report.AddData("${MailState}", record.Format(MvwISDJobXrefView.MailState), ReportEnum.Align.Left, 300);
                             report.AddData("${MailZip}", record.Format(MvwISDJobXrefView.MailZip), ReportEnum.Align.Left, 300);
                             report.AddData("${POC}", record.Format(MvwISDJobXrefView.POC), ReportEnum.Align.Right, 300);
                             report.AddData("${POCName}", record.Format(MvwISDJobXrefView.POCName), ReportEnum.Align.Left, 300);
                             report.AddData("${SalesPerson}", record.Format(MvwISDJobXrefView.SalesPerson), ReportEnum.Align.Right, 300);
                             report.AddData("${SalesPersonName}", record.Format(MvwISDJobXrefView.SalesPersonName), ReportEnum.Align.Left, 300);
                             report.AddData("${JobStatus}", record.Format(MvwISDJobXrefView.JobStatus), ReportEnum.Align.Left, 300);
                             report.AddData("${GLDepartmentNumber}", record.Format(MvwISDJobXrefView.GLDepartmentNumber), ReportEnum.Align.Left, 300);
                             report.AddData("${GLDepartmentName}", record.Format(MvwISDJobXrefView.GLDepartmentName), ReportEnum.Align.Left, 300);

                            report.WriteRow();
                        }
                        pageNum++;
                        recordCount += records.Length;
                    }
                }
                while (records != null && recordCount < totalRows && whereClause.RunQuery);
                	
                
                report.Close();
                BaseClasses.Utils.NetUtils.WriteResponseBinaryAttachment(this.Page.Response, report.Title + ".pdf", report.ReportInByteArray, 0, true);
            
            } catch (Exception ex) {
                  // Upon error, rollback the transaction
                  this.Page.RollBackTransaction(sender);
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
                DbUtils.EndTransaction();
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void ResetButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                
              this.GLDepartmentNumberFilter.ClearSelection();
            
              this.JobStatusFilter.ClearSelection();
            
              this.MailStateFilter.ClearSelection();
            
              this.POCNameFilter.ClearSelection();
            
              this.SalesPersonNameFilter.ClearSelection();
            
              this.VPCustomerNameFilter.ClearSelection();
            
              this.SearchText.Text = "";
            
              this.CurrentSortOrder.Reset();
              if (this.InSession(this, "Order_By"))
                  this.CurrentSortOrder = OrderBy.FromXmlString(this.GetFromSession(this, "Order_By", null));
              else
              {
                  this.CurrentSortOrder = new OrderBy(true, false);
                  
              }
                

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
                
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void SearchButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                
            this.DataChanged = true;
          
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for ImageButton
        public virtual void WordButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                

                WordReport report = new WordReport();

                report.SpecificReportFileName = Page.Server.MapPath("Show-MvwISDJobXref-Table.WordButton.word");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "mvwISDJobXref";
                // If Show-MvwISDJobXref-Table.WordButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(MvwISDJobXrefView.VPCo.Name, ReportEnum.Align.Right, "${VPCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.VPJob.Name, ReportEnum.Align.Left, "${VPJob}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobXrefView.CGCCo.Name, ReportEnum.Align.Right, "${CGCCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.CGCJob.Name, ReportEnum.Align.Left, "${CGCJob}", ReportEnum.Align.Left, 17);
                 report.AddColumn(MvwISDJobXrefView.VPJobDesc.Name, ReportEnum.Align.Left, "${VPJobDesc}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobXrefView.VPCustomer.Name, ReportEnum.Align.Right, "${VPCustomer}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.VPCustomerName.Name, ReportEnum.Align.Left, "${VPCustomerName}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobXrefView.MailAddress.Name, ReportEnum.Align.Left, "${MailAddress}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobXrefView.MailAddress2.Name, ReportEnum.Align.Left, "${MailAddress2}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobXrefView.MailCity.Name, ReportEnum.Align.Left, "${MailCity}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobXrefView.MailState.Name, ReportEnum.Align.Left, "${MailState}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobXrefView.MailZip.Name, ReportEnum.Align.Left, "${MailZip}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobXrefView.POC.Name, ReportEnum.Align.Right, "${POC}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.POCName.Name, ReportEnum.Align.Left, "${POCName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobXrefView.SalesPerson.Name, ReportEnum.Align.Right, "${SalesPerson}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobXrefView.SalesPersonName.Name, ReportEnum.Align.Left, "${SalesPersonName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobXrefView.JobStatus.Name, ReportEnum.Align.Left, "${JobStatus}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobXrefView.GLDepartmentNumber.Name, ReportEnum.Align.Left, "${GLDepartmentNumber}", ReportEnum.Align.Left, 20);
                 report.AddColumn(MvwISDJobXrefView.GLDepartmentName.Name, ReportEnum.Align.Left, "${GLDepartmentName}", ReportEnum.Align.Left, 24);

                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
            
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                

                int rowsPerQuery = 5000;
                int pageNum = 0;
                int recordCount = 0;
                int totalRows = MvwISDJobXrefView.GetRecordCount(joinFilter,whereClause);

                report.Page = Page.GetResourceValue("Txt:Page", "VPLookup");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                ColumnList columns = MvwISDJobXrefView.GetColumnList();
                MvwISDJobXrefRecord[] records = null;
                do
                {
                    records = MvwISDJobXrefView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                    if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( MvwISDJobXrefRecord record in records)
                        {
                            // AddData method takes four parameters
                            // The 1st parameter represents the data format
                            // The 2nd parameter represents the data value
                            // The 3rd parameter represents the default alignment of column using the data
                            // The 4th parameter represents the maximum length of the data value being shown
                             report.AddData("${VPCo}", record.Format(MvwISDJobXrefView.VPCo), ReportEnum.Align.Right, 300);
                             report.AddData("${VPJob}", record.Format(MvwISDJobXrefView.VPJob), ReportEnum.Align.Left, 300);
                             report.AddData("${CGCCo}", record.Format(MvwISDJobXrefView.CGCCo), ReportEnum.Align.Right, 300);
                             report.AddData("${CGCJob}", record.Format(MvwISDJobXrefView.CGCJob), ReportEnum.Align.Left, 300);
                             report.AddData("${VPJobDesc}", record.Format(MvwISDJobXrefView.VPJobDesc), ReportEnum.Align.Left, 300);
                             report.AddData("${VPCustomer}", record.Format(MvwISDJobXrefView.VPCustomer), ReportEnum.Align.Right, 300);
                             report.AddData("${VPCustomerName}", record.Format(MvwISDJobXrefView.VPCustomerName), ReportEnum.Align.Left, 300);
                             report.AddData("${MailAddress}", record.Format(MvwISDJobXrefView.MailAddress), ReportEnum.Align.Left, 300);
                             report.AddData("${MailAddress2}", record.Format(MvwISDJobXrefView.MailAddress2), ReportEnum.Align.Left, 300);
                             report.AddData("${MailCity}", record.Format(MvwISDJobXrefView.MailCity), ReportEnum.Align.Left, 300);
                             report.AddData("${MailState}", record.Format(MvwISDJobXrefView.MailState), ReportEnum.Align.Left, 300);
                             report.AddData("${MailZip}", record.Format(MvwISDJobXrefView.MailZip), ReportEnum.Align.Left, 300);
                             report.AddData("${POC}", record.Format(MvwISDJobXrefView.POC), ReportEnum.Align.Right, 300);
                             report.AddData("${POCName}", record.Format(MvwISDJobXrefView.POCName), ReportEnum.Align.Left, 300);
                             report.AddData("${SalesPerson}", record.Format(MvwISDJobXrefView.SalesPerson), ReportEnum.Align.Right, 300);
                             report.AddData("${SalesPersonName}", record.Format(MvwISDJobXrefView.SalesPersonName), ReportEnum.Align.Left, 300);
                             report.AddData("${JobStatus}", record.Format(MvwISDJobXrefView.JobStatus), ReportEnum.Align.Left, 300);
                             report.AddData("${GLDepartmentNumber}", record.Format(MvwISDJobXrefView.GLDepartmentNumber), ReportEnum.Align.Left, 300);
                             report.AddData("${GLDepartmentName}", record.Format(MvwISDJobXrefView.GLDepartmentName), ReportEnum.Align.Left, 300);

                            report.WriteRow();
                        }
                        pageNum++;
                        recordCount += records.Length;
                    }
                }
                while (records != null && recordCount < totalRows && whereClause.RunQuery);
                report.save();
                BaseClasses.Utils.NetUtils.WriteResponseBinaryAttachment(this.Page.Response, report.Title + ".doc", report.ReportInByteArray, 0, true);
          
            } catch (Exception ex) {
                  // Upon error, rollback the transaction
                  this.Page.RollBackTransaction(sender);
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
                DbUtils.EndTransaction();
            }
    
        }
            
            
        
        // event handler for Button
        public virtual void ActionsButton_Click(object sender, EventArgs args)
        {
              
            try {
                
            //This method is initially empty to implement custom click handler.
      
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for Button
        public virtual void FilterButton_Click(object sender, EventArgs args)
        {
              
            try {
                
            this.DataChanged = true;
          
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for Button
        public virtual void FiltersButton_Click(object sender, EventArgs args)
        {
              
            try {
                
            //This method is initially empty to implement custom click handler.
      
            } catch (Exception ex) {
                  this.Page.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        


        // Generate the event handling functions for filter and search events.
        
        // event handler for FieldFilter
        protected virtual void GLDepartmentNumberFilter_SelectedIndexChanged(object sender, EventArgs args)
        {
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            
           				
        }
            
        // event handler for FieldFilter
        protected virtual void JobStatusFilter_SelectedIndexChanged(object sender, EventArgs args)
        {
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            
           				
        }
            
        // event handler for FieldFilter
        protected virtual void MailStateFilter_SelectedIndexChanged(object sender, EventArgs args)
        {
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            
           				
        }
            
        // event handler for FieldFilter
        protected virtual void POCNameFilter_SelectedIndexChanged(object sender, EventArgs args)
        {
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            
           				
        }
            
        // event handler for FieldFilter
        protected virtual void SalesPersonNameFilter_SelectedIndexChanged(object sender, EventArgs args)
        {
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            
           				
        }
            
        // event handler for FieldFilter
        protected virtual void VPCustomerNameFilter_SelectedIndexChanged(object sender, EventArgs args)
        {
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            
           				
        }
            
    
        // Generate the event handling functions for others
        	  

        protected int _TotalRecords = -1;
        public int TotalRecords 
        {
            get {
                if (_TotalRecords < 0)
                {
                    _TotalRecords = MvwISDJobXrefView.GetRecordCount(CreateCompoundJoinFilter(), CreateWhereClause());
                }
                return (this._TotalRecords);
            }
            set {
                if (this.PageSize > 0) {
                  
                      this.TotalPages = Convert.ToInt32(Math.Ceiling(Convert.ToDouble(value) / Convert.ToDouble(this.PageSize)));
                          
                }
                this._TotalRecords = value;
            }
        }

      
      
        protected int _TotalPages = -1;
        public int TotalPages {
            get {
                if (_TotalPages < 0) 
                
                    this.TotalPages = Convert.ToInt32(Math.Ceiling(Convert.ToDouble(TotalRecords) / Convert.ToDouble(this.PageSize)));
                  
                return this._TotalPages;
            }
            set {
                this._TotalPages = value;
            }
        }

        protected bool _DisplayLastPage;
        public bool DisplayLastPage {
            get {
                return this._DisplayLastPage;
            }
            set {
                this._DisplayLastPage = value;
            }
        }


        
        private OrderBy _CurrentSortOrder = null;
        public OrderBy CurrentSortOrder {
            get {
                return this._CurrentSortOrder;
            }
            set {
                this._CurrentSortOrder = value;
            }
        }
        
        public  MvwISDJobXrefRecord[] DataSource {
             
            get {
                return (MvwISDJobXrefRecord[])(base._DataSource);
            }
            set {
                this._DataSource = value;
            }
        }

#region "Helper Properties"
        
        public VPLookup.UI.IThemeButtonWithArrow ActionsButton {
            get {
                return (VPLookup.UI.IThemeButtonWithArrow)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ActionsButton");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton CGCCoLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton CGCJobLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCJobLabel");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton ExcelButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ExcelButton");
            }
        }
        
        public VPLookup.UI.IThemeButton FilterButton {
            get {
                return (VPLookup.UI.IThemeButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "FilterButton");
            }
        }
        
        public VPLookup.UI.IThemeButtonWithArrow FiltersButton {
            get {
                return (VPLookup.UI.IThemeButtonWithArrow)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "FiltersButton");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton GLDepartmentNameLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLDepartmentNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.DropDownList GLDepartmentNumberFilter {
            get {
                return (System.Web.UI.WebControls.DropDownList)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLDepartmentNumberFilter");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton GLDepartmentNumberLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLDepartmentNumberLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal GLDepartmentNumberLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLDepartmentNumberLabel1");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton ImportButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ImportButton");
            }
        }
        
        public System.Web.UI.WebControls.DropDownList JobStatusFilter {
            get {
                return (System.Web.UI.WebControls.DropDownList)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobStatusFilter");
            }
        }
        
        public System.Web.UI.WebControls.Literal JobStatusLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobStatusLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton JobStatusLabel1 {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobStatusLabel1");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton MailAddress2Label {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailAddress2Label");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton MailAddressLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailAddressLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton MailCityLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailCityLabel");
            }
        }
        
        public BaseClasses.Web.UI.WebControls.QuickSelector MailStateFilter {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailStateFilter");
            }
        }              
        
        public System.Web.UI.WebControls.LinkButton MailStateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailStateLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal MailStateLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailStateLabel1");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton MailZipLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailZipLabel");
            }
        }
        
        public VPLookup.UI.IPaginationModern Pagination {
            get {
                return (VPLookup.UI.IPaginationModern)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Pagination");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton PDFButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PDFButton");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton POCLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCLabel");
            }
        }
        
        public BaseClasses.Web.UI.WebControls.QuickSelector POCNameFilter {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCNameFilter");
            }
        }              
        
        public System.Web.UI.WebControls.LinkButton POCNameLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POCNameLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCNameLabel1");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton ResetButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ResetButton");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton SalesPersonLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonLabel");
            }
        }
        
        public BaseClasses.Web.UI.WebControls.QuickSelector SalesPersonNameFilter {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonNameFilter");
            }
        }              
        
        public System.Web.UI.WebControls.LinkButton SalesPersonNameLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SalesPersonNameLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonNameLabel1");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton SearchButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SearchButton");
            }
        }
        
        public System.Web.UI.WebControls.TextBox SearchText {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SearchText");
            }
        }
        
        public System.Web.UI.WebControls.Literal Title {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Title");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton VPCoLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton VPCustomerLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerLabel");
            }
        }
        
        public BaseClasses.Web.UI.WebControls.QuickSelector VPCustomerNameFilter {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerNameFilter");
            }
        }              
        
        public System.Web.UI.WebControls.LinkButton VPCustomerNameLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPCustomerNameLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerNameLabel1");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton VPJobDescLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobDescLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton VPJobLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobLabel");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton WordButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "WordButton");
            }
        }
        
#endregion

#region "Helper Functions"
        
        public override string ModifyRedirectUrl(string url, string arg, bool bEncrypt)
        {
            return this.Page.EvaluateExpressions(url, arg, bEncrypt, this);
        }
        
        public override string ModifyRedirectUrl(string url, string arg, bool bEncrypt,bool includeSession)
        {
            return this.Page.EvaluateExpressions(url, arg, bEncrypt, this,includeSession);
        }
        
        public override string EvaluateExpressions(string url, string arg, bool bEncrypt)
        {
            bool needToProcess = AreAnyUrlParametersForMe(url, arg);
            if (needToProcess) {
                MvwISDJobXrefTableControlRow recCtl = this.GetSelectedRecordControl();
                if (recCtl == null && url.IndexOf("{") >= 0) {
                    // Localization.
                    throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
                }

        MvwISDJobXrefRecord rec = null;
                if (recCtl != null) {
                    rec = recCtl.GetRecord();
                }
                return EvaluateExpressions(url, arg, rec, bEncrypt);
             
            }
            return url;
        }
        
        
        public override string EvaluateExpressions(string url, string arg, bool bEncrypt, bool includeSession)
        {
            bool needToProcess = AreAnyUrlParametersForMe(url, arg);
            if (needToProcess) {
                MvwISDJobXrefTableControlRow recCtl = this.GetSelectedRecordControl();
                if (recCtl == null && url.IndexOf("{") >= 0) {
                    // Localization.
                    throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
                }

        MvwISDJobXrefRecord rec = null;
                if (recCtl != null) {
                    rec = recCtl.GetRecord();
                }
                
                if (includeSession)
                {
                    return EvaluateExpressions(url, arg, rec, bEncrypt);
                }
                else
                {
                    return EvaluateExpressions(url, arg, rec, bEncrypt,false);
                }
             
            }
            return url;
        }
          
        public virtual MvwISDJobXrefTableControlRow GetSelectedRecordControl()
        {
        
            return null;
          
        }

        public virtual MvwISDJobXrefTableControlRow[] GetSelectedRecordControls()
        {
        
            return (MvwISDJobXrefTableControlRow[])((new ArrayList()).ToArray(Type.GetType("VPLookup.UI.Controls.Show_MvwISDJobXref_Table.MvwISDJobXrefTableControlRow")));
          
        }

        public virtual void DeleteSelectedRecords(bool deferDeletion)
        {
            MvwISDJobXrefTableControlRow[] recordList = this.GetSelectedRecordControls();
            if (recordList.Length == 0) {
                // Localization.
                throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
            }
            
            foreach (MvwISDJobXrefTableControlRow recCtl in recordList)
            {
                if (deferDeletion) {
                    if (!recCtl.IsNewRecord) {
                
                        this.AddToDeletedRecordIds(recCtl);
                  
                    }
                    recCtl.Visible = false;
                
                } else {
                
                    recCtl.Delete();
                    // Setting the DataChanged to True results in the page being refreshed with
                    // the most recent data from the database.  This happens in PreRender event
                    // based on the current sort, search and filter criteria.
                    this.DataChanged = true;
                    this.ResetData = true;
                  
                }
            }
        }

        public MvwISDJobXrefTableControlRow[] GetRecordControls()
        {
            ArrayList recordList = new ArrayList();
            System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)this.FindControl("MvwISDJobXrefTableControlRepeater");
            if (rep == null){return null;}
            foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
            {
              MvwISDJobXrefTableControlRow recControl = (MvwISDJobXrefTableControlRow)repItem.FindControl("MvwISDJobXrefTableControlRow");
                  recordList.Add(recControl);
                
            }

            return (MvwISDJobXrefTableControlRow[])recordList.ToArray(Type.GetType("VPLookup.UI.Controls.Show_MvwISDJobXref_Table.MvwISDJobXrefTableControlRow"));
        }

        public new BaseApplicationPage Page 
        {
            get {
                return ((BaseApplicationPage)base.Page);
            }
        }
        
                

        
        
#endregion


    }
  
// Base class for the MvwISDCustomerXrefRecordControl control on the Show_MvwISDJobXref_Table page.
// Do not modify this class. Instead override any method in MvwISDCustomerXrefRecordControl.
public class BaseMvwISDCustomerXrefRecordControl : VPLookup.UI.BaseApplicationRecordControl
{
        public BaseMvwISDCustomerXrefRecordControl()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        // To customize, override this method in MvwISDCustomerXrefRecordControl.
        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
        
            
            string url = "";
            if (url == null) url = ""; //avoid warning on VS
            // Setup the filter and search events.
                
            this.ClearControlsFromSession();
        }

        // To customize, override this method in MvwISDCustomerXrefRecordControl.
        protected virtual void Control_Load(object sender, System.EventArgs e)
        {      
        
              // Setup the pagination events.	  
                     
        
              // Register the event handlers.

          
        }

        public virtual void LoadData()  
        {
            // Load the data from the database into the DataSource DatabaseViewpoint%dbo.mvwISDCustomerXref record.
            // It is better to make changes to functions called by LoadData such as
            // CreateWhereClause, rather than making changes here.
            
        
            // This is the first time a record is being retrieved from the database.
            // So create a Where Clause based on the staic Where clause specified
            // on the Query wizard and the dynamic part specified by the end user
            // on the search and filter controls (if any).
            
            WhereClause wc = this.CreateWhereClause();
            
            System.Web.UI.WebControls.Panel Panel = (System.Web.UI.WebControls.Panel)MiscUtils.FindControlRecursively(this, "MvwISDCustomerXrefRecordControlPanel");
            if (Panel != null){
                Panel.Visible = true;
            }
            
            // If there is no Where clause, then simply create a new, blank record.
            
            if (wc == null || !(wc.RunQuery)) {
                this.DataSource = new MvwISDCustomerXrefRecord();
            
                if (Panel != null){
                    Panel.Visible = false;
                }
              
                return;
            }
          
            // Retrieve the record from the database.  It is possible
            MvwISDCustomerXrefRecord[] recList = MvwISDCustomerXrefView.GetRecords(wc, null, 0, 2);
            if (recList.Length == 0) {
                // There is no data for this Where clause.
                wc.RunQuery = false;
                
                if (Panel != null){
                    Panel.Visible = false;
                }
                
                return;
            }
            
            // Set DataSource based on record retrieved from the database.
            this.DataSource = MvwISDCustomerXrefView.GetRecord(recList[0].GetID().ToXmlString(), true);
                  
        }

        public override void DataBind()
        {
            // The DataBind method binds the user interface controls to the values
            // from the database record.  To do this, it calls the Set methods for 
            // each of the field displayed on the webpage.  It is better to make 
            // changes in the Set methods, rather than making changes here.
            
            base.DataBind();
            
            // Make sure that the DataSource is initialized.
            
            if (this.DataSource == null) {
             //This is to make sure all the controls will be invisible if no record is present in the cell
             
                return;
            }
              
            // LoadData for DataSource for chart and report if they exist
          
            // Store the checksum. The checksum is used to
            // ensure the record was not changed by another user.
            if (this.DataSource.GetCheckSumValue() != null)
                this.CheckSum = this.DataSource.GetCheckSumValue().Value;
            

            // Call the Set methods for each controls on the panel
        
                SetAddress();
                SetAddress2();
                SetAddressLabel();
                SetAsteaCustomer();
                SetAsteaCustomerLabel();
                SetCGCCustomer();
                SetCGCCustomerLabel();
                SetCity();
                SetCustomerMap();
                SetCustomerName1();
                SetCustomerNameLabel1();
                SetState();
                SetVPCustomer1();
                SetVPCustomerLabel1();
                SetZip();

      

            this.IsNewRecord = true;
          
            if (this.DataSource.IsCreated) {
                this.IsNewRecord = false;
              
                if (this.DataSource.GetID() != null)
                    this.RecordUniqueId = this.DataSource.GetID().ToXmlString();
              
            }
            

            // Now load data for each record and table child UI controls.
            // Ordering is important because child controls get 
            // their parent ids from their parent UI controls.
            bool shouldResetControl = false;
            if (shouldResetControl) { }; // prototype usage to void compiler warnings
            
        }
        
        
        public virtual void SetAddress()
        {
            
                    
            // Set the Address Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.Address is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AddressSpecified) {
                								
                // If the Address is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.Address);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Address.Text = formattedValue;
                   
            } 
            
            else {
            
                // Address is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Address.Text = MvwISDCustomerXrefView.Address.Format(MvwISDCustomerXrefView.Address.DefaultValue);
            		
            }
            
            // If the Address is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Address.Text == null ||
                this.Address.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Address.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetAddress2()
        {
            
                    
            // Set the Address2 Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.Address2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.Address2Specified) {
                								
                // If the Address2 is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.Address2);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Address2.Text = formattedValue;
                   
            } 
            
            else {
            
                // Address2 is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Address2.Text = MvwISDCustomerXrefView.Address2.Format(MvwISDCustomerXrefView.Address2.DefaultValue);
            		
            }
            
            // If the Address2 is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Address2.Text == null ||
                this.Address2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Address2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetAsteaCustomer()
        {
            
                    
            // Set the AsteaCustomer Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.AsteaCustomer is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AsteaCustomerSpecified) {
                								
                // If the AsteaCustomer is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.AsteaCustomer);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.AsteaCustomer.Text = formattedValue;
                   
            } 
            
            else {
            
                // AsteaCustomer is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.AsteaCustomer.Text = MvwISDCustomerXrefView.AsteaCustomer.Format(MvwISDCustomerXrefView.AsteaCustomer.DefaultValue);
            		
            }
            
            // If the AsteaCustomer is NULL or blank, then use the value specified  
            // on Properties.
            if (this.AsteaCustomer.Text == null ||
                this.AsteaCustomer.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.AsteaCustomer.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCGCCustomer()
        {
            
                    
            // Set the CGCCustomer Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.CGCCustomer is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCCustomerSpecified) {
                								
                // If the CGCCustomer is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.CGCCustomer);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CGCCustomer.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCCustomer is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCCustomer.Text = MvwISDCustomerXrefView.CGCCustomer.Format(MvwISDCustomerXrefView.CGCCustomer.DefaultValue);
            		
            }
            
            // If the CGCCustomer is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CGCCustomer.Text == null ||
                this.CGCCustomer.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CGCCustomer.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCity()
        {
            
                    
            // Set the City Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.City is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CitySpecified) {
                								
                // If the City is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.City);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.City.Text = formattedValue;
                   
            } 
            
            else {
            
                // City is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.City.Text = MvwISDCustomerXrefView.City.Format(MvwISDCustomerXrefView.City.DefaultValue);
            		
            }
            
            // If the City is NULL or blank, then use the value specified  
            // on Properties.
            if (this.City.Text == null ||
                this.City.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.City.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCustomerName1()
        {
            
                    
            // Set the CustomerName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.CustomerName1 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CustomerNameSpecified) {
                								
                // If the CustomerName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.CustomerName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CustomerName1.Text = formattedValue;
                   
            } 
            
            else {
            
                // CustomerName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CustomerName1.Text = MvwISDCustomerXrefView.CustomerName.Format(MvwISDCustomerXrefView.CustomerName.DefaultValue);
            		
            }
            
            // If the CustomerName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CustomerName1.Text == null ||
                this.CustomerName1.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CustomerName1.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetState()
        {
            
                    
            // Set the State Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.State is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.StateSpecified) {
                								
                // If the State is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.State);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.State.Text = formattedValue;
                   
            } 
            
            else {
            
                // State is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.State.Text = MvwISDCustomerXrefView.State.Format(MvwISDCustomerXrefView.State.DefaultValue);
            		
            }
            
            // If the State is NULL or blank, then use the value specified  
            // on Properties.
            if (this.State.Text == null ||
                this.State.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.State.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPCustomer1()
        {
            
                    
            // Set the VPCustomer Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.VPCustomer1 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerSpecified) {
                								
                // If the VPCustomer is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.VPCustomer);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCustomer1.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomer is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomer1.Text = MvwISDCustomerXrefView.VPCustomer.Format(MvwISDCustomerXrefView.VPCustomer.DefaultValue);
            		
            }
            
            // If the VPCustomer is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPCustomer1.Text == null ||
                this.VPCustomer1.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPCustomer1.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetZip()
        {
            
                    
            // Set the Zip Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDCustomerXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDCustomerXref record retrieved from the database.
            // this.Zip is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ZipSpecified) {
                								
                // If the Zip is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDCustomerXrefView.Zip);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Zip.Text = formattedValue;
                   
            } 
            
            else {
            
                // Zip is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Zip.Text = MvwISDCustomerXrefView.Zip.Format(MvwISDCustomerXrefView.Zip.DefaultValue);
            		
            }
            
            // If the Zip is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Zip.Text == null ||
                this.Zip.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Zip.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetAddressLabel()
                  {
                  
                    
        }
                
        public virtual void SetAsteaCustomerLabel()
                  {
                  
                    
        }
                
        public virtual void SetCGCCustomerLabel()
                  {
                  
                    
        }
                
        public virtual void SetCustomerMap()
                  {
                  
                        this.CustomerMap.Text = EvaluateFormula("GoogleMap(Address + ',' + City + ',' + State + ',' + Zip, 300, 300, \"maptype=hybrid&zoom=10\", \"\")");
                    
                    
        }
                
        public virtual void SetCustomerNameLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVPCustomerLabel1()
                  {
                  
                    
        }
                
        public BaseClasses.Data.DataSource.EvaluateFormulaDelegate EvaluateFormulaDelegate;

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables, bool includeDS, FormulaEvaluator e)
        {
            if (e == null)
                e = new FormulaEvaluator();

            e.Variables.Clear();
            // add variables for formula evaluation
            if (variables != null)
            {
                System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<string, object>> enumerator = variables.GetEnumerator();
                while (enumerator.MoveNext())
                {
                    e.Variables.Add(enumerator.Current.Key, enumerator.Current.Value);
                }
            }
            
            
            if (includeDS)
            {
                
            }
            
            // All variables referred to in the formula are expected to be
            // properties of the DataSource.  For example, referring to
            // UnitPrice as a variable will refer to DataSource.UnitPrice
            if (dataSourceForEvaluate == null)
                e.DataSource = this.DataSource;
            else
                e.DataSource = dataSourceForEvaluate;

            // Define the calling control.  This is used to add other 
            // related table and record controls as variables.
            e.CallingControl = this;

            object resultObj = e.Evaluate(formula);
            if (resultObj == null)
                return "";
            
            if ( !string.IsNullOrEmpty(format) && (string.IsNullOrEmpty(formula) || formula.IndexOf("Format(") < 0) )
                return FormulaUtils.Format(resultObj, format);
            else
                return resultObj.ToString();
        }
                
        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables, bool includeDS)
        {
          return EvaluateFormula(formula, dataSourceForEvaluate, format, variables, includeDS, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables)
        {
          return EvaluateFormula(formula, dataSourceForEvaluate, format, variables, true, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, format, null, true, null);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, System.Collections.Generic.IDictionary<string, object> variables, FormulaEvaluator e)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, null, variables, true, e);
        }

        public virtual string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate)
        {
          return this.EvaluateFormula(formula, dataSourceForEvaluate, null, null, true, null);
        }

        public virtual string EvaluateFormula(string formula, bool includeDS)
        {
          return this.EvaluateFormula(formula, null, null, null, includeDS, null);
        }

        public virtual string EvaluateFormula(string formula)
        {
          return this.EvaluateFormula(formula, null, null, null, true, null);
        }
        
      
        public virtual void ResetControl()
        {
          
        }
        

        public virtual void RegisterPostback()
        {
            
        }
    
        

        public virtual void SaveData()
        {
            // Saves the associated record in the database.
            // SaveData calls Validate and Get methods - so it may be more appropriate to
            // customize those methods.

            // 1. Load the existing record from the database. Since we save the entire record, this ensures 
            // that fields that are not displayed are also properly initialized.
            this.LoadData();
        
            // The checksum is used to ensure the record was not changed by another user.
            if (this.DataSource != null && this.DataSource.GetCheckSumValue() != null) {
                if (this.CheckSum != null && this.CheckSum != this.DataSource.GetCheckSumValue().Value) {
                    throw new Exception(Page.GetResourceValue("Err:RecChangedByOtherUser", "VPLookup"));
                }
            }
        
            System.Web.UI.WebControls.Panel Panel = (System.Web.UI.WebControls.Panel)MiscUtils.FindControlRecursively(this, "MvwISDCustomerXrefRecordControlPanel");
            if ( (Panel != null && !Panel.Visible) || this.DataSource == null){
                return;
            }
          MvwISDJobXrefTableControlRow parentCtrl;
      				  
          parentCtrl = (MvwISDJobXrefTableControlRow)MiscUtils.GetParentControlObject(this, "MvwISDJobXrefTableControlRow");		  
              			
          if (parentCtrl != null && parentCtrl.DataSource == null) {
                // Load the record if it is not loaded yet.
                parentCtrl.LoadData();
            }
            if (parentCtrl == null || parentCtrl.DataSource == null) {
                // Get the error message from the application resource file.
                throw new Exception(Page.GetResourceValue("Err:NoParentRecId", "VPLookup"));
            }
            			
            this.DataSource.CustomerKey = parentCtrl.DataSource.CustomerKey;
            
          
            // 2. Perform any custom validation.
            this.Validate();

            
            // 3. Set the values in the record with data from UI controls.
            // This calls the Get() method for each of the user interface controls.
            this.GetUIData();
   
            // 4. Save in the database.
            // We should not save the record if the data did not change. This
            // will save a database hit and avoid triggering any database triggers.
            
            if (this.DataSource.IsAnyValueChanged) {
                // Save record to database but do not commit yet.
                // Auto generated ids are available after saving for use by child (dependent) records.
                this.DataSource.Save();
                
            }
            
      
            // update session or cookie by formula
             		  
      
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            this.ResetData = true;
            
            this.CheckSum = "";
            // For Master-Detail relationships, save data on the Detail table(s)            
          
        }

        public virtual void GetUIData()
        {
            // The GetUIData method retrieves the updated values from the user interface 
            // controls into a database record in preparation for saving or updating.
            // To do this, it calls the Get methods for each of the field displayed on 
            // the webpage.  It is better to make changes in the Get methods, rather 
            // than making changes here.
      
            // Call the Get methods for each of the user interface controls.
        
            GetAddress();
            GetAddress2();
            GetAsteaCustomer();
            GetCGCCustomer();
            GetCity();
            GetCustomerName1();
            GetState();
            GetVPCustomer1();
            GetZip();
        }
        
        
        public virtual void GetAddress()
        {
            
        }
                
        public virtual void GetAddress2()
        {
            
        }
                
        public virtual void GetAsteaCustomer()
        {
            
        }
                
        public virtual void GetCGCCustomer()
        {
            
        }
                
        public virtual void GetCity()
        {
            
        }
                
        public virtual void GetCustomerName1()
        {
            
        }
                
        public virtual void GetState()
        {
            
        }
                
        public virtual void GetVPCustomer1()
        {
            
        }
                
        public virtual void GetZip()
        {
            
        }
                

      // To customize, override this method in MvwISDCustomerXrefRecordControl.
      
        public virtual WhereClause CreateWhereClause()
         
        {
//Bryan Check
    
            bool hasFiltersMvwISDCustomerXrefRecordControl = false;
            hasFiltersMvwISDCustomerXrefRecordControl = hasFiltersMvwISDCustomerXrefRecordControl && false; // suppress warning
      
            bool hasFiltersMvwISDJobXrefTableControl = false;
            hasFiltersMvwISDJobXrefTableControl = hasFiltersMvwISDJobXrefTableControl && false; // suppress warning
      
//
        
            WhereClause wc;
            MvwISDCustomerXrefView.Instance.InnerFilter = null;
            wc = new WhereClause();
            
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.

              
          KeyValue selectedRecordKeyValue = new KeyValue();
        
              KeyValue mvwISDJobXrefRecordObj = null;
              // make variable assignment here to avoid possible incorrect compiler warning
              KeyValue tmp = mvwISDJobXrefRecordObj;
              mvwISDJobXrefRecordObj = tmp;
            MvwISDJobXrefTableControlRow mvwISDJobXrefTableControlObjRow = (MiscUtils.GetParentControlObject(this, "MvwISDJobXrefTableControlRow") as MvwISDJobXrefTableControlRow);
              
                if (mvwISDJobXrefTableControlObjRow != null && mvwISDJobXrefTableControlObjRow.GetRecord() != null && mvwISDJobXrefTableControlObjRow.GetRecord().CustomerKey != null)
                {
                    wc.iAND(MvwISDCustomerXrefView.CustomerKey, BaseFilter.ComparisonOperator.EqualsTo, mvwISDJobXrefTableControlObjRow.GetRecord().CustomerKey.ToString());
                }
                else
                {
                    wc.RunQuery = false;
                    return wc;                    
                }
              
          HttpContext.Current.Session["MvwISDCustomerXrefRecordControlWhereClause"] = selectedRecordKeyValue.ToXmlString();
        
            return wc;
          
        }
        
        
        public virtual WhereClause CreateWhereClause(String searchText, String fromSearchControl, String AutoTypeAheadSearch, String AutoTypeAheadWordSeparators)
        {
            // This CreateWhereClause is used for loading list of suggestions for Auto Type-Ahead feature.
            MvwISDCustomerXrefView.Instance.InnerFilter = null;
            WhereClause wc= new WhereClause();
        
//Bryan Check
    
            bool hasFiltersMvwISDCustomerXrefRecordControl = false;
            hasFiltersMvwISDCustomerXrefRecordControl = hasFiltersMvwISDCustomerXrefRecordControl && false; // suppress warning
      
            bool hasFiltersMvwISDJobXrefTableControl = false;
            hasFiltersMvwISDJobXrefTableControl = hasFiltersMvwISDJobXrefTableControl && false; // suppress warning
      
//
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            String appRelativeVirtualPath = (String)HttpContext.Current.Session["AppRelativeVirtualPath"];
            
          string selectedRecordInMvwISDJobXrefTableControl = HttpContext.Current.Session["MvwISDCustomerXrefRecordControlWhereClause"] as string;
          
          if (selectedRecordInMvwISDJobXrefTableControl != null && KeyValue.IsXmlKey(selectedRecordInMvwISDJobXrefTableControl)) 
          {
              KeyValue selectedRecordKeyValue = KeyValue.XmlToKey(selectedRecordInMvwISDJobXrefTableControl);
            
              if (selectedRecordKeyValue != null && selectedRecordKeyValue.ContainsColumn(MvwISDCustomerXrefView.CustomerKey))
              {
                  wc.iAND(MvwISDCustomerXrefView.CustomerKey, BaseFilter.ComparisonOperator.EqualsTo, selectedRecordKeyValue.GetColumnValue(MvwISDCustomerXrefView.CustomerKey).ToString());
              }
     
            }
    
            // Adds clauses if values are selected in Filter controls which are configured in the page.
                
            return wc;
        }

        
        
         public virtual bool FormatSuggestions(String prefixText, String resultItem,
                                              int columnLength, String AutoTypeAheadDisplayFoundText,
                                              String autoTypeAheadSearch, String AutoTypeAheadWordSeparators,
                                              ArrayList resultList)
        {
            return this.FormatSuggestions(prefixText, resultItem, columnLength, AutoTypeAheadDisplayFoundText,
                                              autoTypeAheadSearch, AutoTypeAheadWordSeparators, resultList, false);
        }                                              
        
        public virtual bool FormatSuggestions(String prefixText, String resultItem,
                                              int columnLength, String AutoTypeAheadDisplayFoundText,
                                              String autoTypeAheadSearch, String AutoTypeAheadWordSeparators,
                                              ArrayList resultList, bool stripHTML)
        {
            if (stripHTML){
                prefixText = StringUtils.ConvertHTMLToPlainText(prefixText);
                resultItem = StringUtils.ConvertHTMLToPlainText(resultItem);
            }
            // Formats the result Item and adds it to the list of suggestions.
            int index  = resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).IndexOf(prefixText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture));
            String itemToAdd = null;
            bool isFound = false;
            bool isAdded = false;
            if (StringUtils.InvariantLCase(autoTypeAheadSearch).Equals("wordsstartingwithsearchstring") && !(index == 0)) {
                // Expression to find word which contains AutoTypeAheadWordSeparators followed by prefixText
                System.Text.RegularExpressions.Regex regex1 = new System.Text.RegularExpressions.Regex( AutoTypeAheadWordSeparators + prefixText, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                if (regex1.IsMatch(resultItem)) {
                    index = regex1.Match(resultItem).Index;
                    isFound = true;
                }
                //If the prefixText is found immediatly after white space then starting of the word is found so don not search any further
                if (resultItem[index].ToString() != " ") {
                    // Expression to find beginning of the word which contains AutoTypeAheadWordSeparators followed by prefixText
                    System.Text.RegularExpressions.Regex regex = new System.Text.RegularExpressions.Regex("\\S*" + AutoTypeAheadWordSeparators + prefixText, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                    if (regex.IsMatch(resultItem)) {
                        index = regex.Match(resultItem).Index;
                        isFound = true;
                    }
                }
            }
            // If autoTypeAheadSearch value is wordsstartingwithsearchstring then, extract the substring only if the prefixText is found at the 
            // beginning of the resultItem (index = 0) or a word in resultItem is found starts with prefixText. 
            if (index == 0 || isFound || StringUtils.InvariantLCase(autoTypeAheadSearch).Equals("anywhereinstring")) {
                if (StringUtils.InvariantLCase(AutoTypeAheadDisplayFoundText).Equals("atbeginningofmatchedstring")) {
                    // Expression to find beginning of the word which contains prefixText
                    System.Text.RegularExpressions.Regex regex1 = new System.Text.RegularExpressions.Regex("\\S*" + prefixText, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                    //  Find the beginning of the word which contains prefexText
                    if (StringUtils.InvariantLCase(autoTypeAheadSearch).Equals("anywhereinstring") && regex1.IsMatch(resultItem)) {
                        index = regex1.Match(resultItem).Index;
                        isFound = true;
                    }
                    // Display string from the index till end of the string if, sub string from index till end of string is less than columnLength value.
                    if ((resultItem.Length - index) <= columnLength) {
                        if (index == 0) {
                            itemToAdd = resultItem;
                        } else {
                            itemToAdd = resultItem.Substring(index);
                        }
                    }
                    else {
                            itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, index, index + columnLength, StringUtils.Direction.forward);
                    }
                }
                else if (StringUtils.InvariantLCase(AutoTypeAheadDisplayFoundText).Equals("inmiddleofmatchedstring")) {
                    int subStringBeginIndex = (int)(columnLength / 2);
                    if (resultItem.Length <= columnLength) {
                        itemToAdd = resultItem;
                    }
                    else {
                        // Sanity check at end of the string
                        if (((index + prefixText.Length) >= resultItem.Length - 1)||(resultItem.Length - index < subStringBeginIndex)) {
                            itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, resultItem.Length - 1 - columnLength, resultItem.Length - 1, StringUtils.Direction.backward);
                        }
                        else if (index <= subStringBeginIndex) {
                            // Sanity check at beginning of the string
                            itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, 0, columnLength, StringUtils.Direction.forward);
                        } 
                        else {
                            // Display string containing text before the prefixText occures and text after the prefixText
                            itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, index - subStringBeginIndex, index - subStringBeginIndex + columnLength, StringUtils.Direction.both);
                        }
                    }
                }
                else if (StringUtils.InvariantLCase(AutoTypeAheadDisplayFoundText).Equals("atendofmatchedstring")) {
                     // Expression to find ending of the word which contains prefexText
                    System.Text.RegularExpressions.Regex regex1 = new System.Text.RegularExpressions.Regex("\\s", System.Text.RegularExpressions.RegexOptions.IgnoreCase); 
                    // Find the ending of the word which contains prefexText
                    if (regex1.IsMatch(resultItem, index + 1)) {
                        index = regex1.Match(resultItem, index + 1).Index;
                    }
                    else{
                        // If the word which contains prefexText is the last word in string, regex1.IsMatch returns false.
                        index = resultItem.Length;
                    }
                    
                    if (index > resultItem.Length) {
                        index = resultItem.Length;
                    }
                    // If text from beginning of the string till index is less than columnLength value then, display string from the beginning till index.
                    if (index <= columnLength) {
                        itemToAdd = resultItem.Substring(0, index);
                    } 
                    else {
                        // Truncate the string to show only columnLength has to be appended.
                        itemToAdd = StringUtils.GetSubstringWithWholeWords(resultItem, index - columnLength, index, StringUtils.Direction.backward);
                    }
                }
                
                // Remove newline character from itemToAdd
                int prefixTextIndex = itemToAdd.IndexOf(prefixText, StringComparison.CurrentCultureIgnoreCase);
                if(prefixTextIndex < 0) return false;
                // If itemToAdd contains any newline after the search text then show text only till newline
                System.Text.RegularExpressions.Regex regex2 = new System.Text.RegularExpressions.Regex("(\r\n|\n)", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                int newLineIndexAfterPrefix = -1;
                if (regex2.IsMatch(itemToAdd, prefixTextIndex)){
                    newLineIndexAfterPrefix = regex2.Match(itemToAdd, prefixTextIndex).Index;
                }
                if ((newLineIndexAfterPrefix > -1)) {                   
                    itemToAdd = itemToAdd.Substring(0, newLineIndexAfterPrefix);                   
                }
                // If itemToAdd contains any newline before search text then show text which comes after newline
                System.Text.RegularExpressions.Regex regex3 = new System.Text.RegularExpressions.Regex("(\r\n|\n)", System.Text.RegularExpressions.RegexOptions.IgnoreCase | System.Text.RegularExpressions.RegexOptions.RightToLeft );
                int newLineIndexBeforePrefix = -1;
                if (regex3.IsMatch(itemToAdd, prefixTextIndex)){
                    newLineIndexBeforePrefix = regex3.Match(itemToAdd, prefixTextIndex).Index;
                }
                if ((newLineIndexBeforePrefix > -1)) {
                    itemToAdd = itemToAdd.Substring(newLineIndexBeforePrefix +regex3.Match(itemToAdd, prefixTextIndex).Length);
                }

                if (!string.IsNullOrEmpty(itemToAdd) && !resultList.Contains(itemToAdd)) {
                    resultList.Add(itemToAdd);
                    isAdded = true;
                }
            }
            return isAdded;
        }
        
    
        public virtual void Validate()
        {
            // Add custom validation for any control within this panel.
            // Example.  If you have a State ASP:Textbox control
            // if (this.State.Text != "CA")
            //    throw new Exception("State must be CA (California).");
            // The Validate method is common across all controls within
            // this panel so you can validate multiple fields, but report
            // one error message.
            
            
            
        }

        public virtual void Delete()
        {
        
            if (this.IsNewRecord) {
                return;
            }

            KeyValue pkValue = KeyValue.XmlToKey(this.RecordUniqueId);
          MvwISDCustomerXrefView.DeleteRecord(pkValue);
          
        }

        protected virtual void Control_PreRender(object sender, System.EventArgs e)
        {
            // PreRender event is raised just before page is being displayed.
            try {
                DbUtils.StartTransaction();
                this.RegisterPostback();
                if (!this.Page.ErrorOnPage && (this.Page.IsPageRefresh || this.DataChanged || this.ResetData)) {
                  
                
                    // Re-load the data and update the web page if necessary.
                    // This is typically done during a postback (filter, search button, sort, pagination button).
                    // In each of the other click handlers, simply set DataChanged to True to reload the data.
                    this.LoadData();
                    this.DataBind();
                }
                				
            } catch (Exception ex) {
                BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
            } finally {
                DbUtils.EndTransaction();
            }
        }
        
            
        protected override void SaveControlsToSession()
        {
            base.SaveControlsToSession();
        
    
            // Save pagination state to session.
          
        }
        
        
    
        protected override void ClearControlsFromSession()
        {
            base.ClearControlsFromSession();

        

            // Clear pagination state from session.
        
        }
        
        protected override void LoadViewState(object savedState)
        {
            base.LoadViewState(savedState);
            string isNewRecord = (string)ViewState["IsNewRecord"];
            if (isNewRecord != null && isNewRecord.Length > 0) {
                this.IsNewRecord = Boolean.Parse(isNewRecord);
            }
        
            string myCheckSum = (string)ViewState["CheckSum"];
            if (myCheckSum != null && myCheckSum.Length > 0) {
                this.CheckSum = myCheckSum;
            }
        
    
            // Load view state for pagination control.
                 
        }

        protected override object SaveViewState()
        {
            ViewState["IsNewRecord"] = this.IsNewRecord.ToString();
            ViewState["CheckSum"] = this.CheckSum;
        

            // Load view state for pagination control.
               
            return base.SaveViewState();
        }

        
        // Generate the event handling functions for pagination events.
            
      
        // Generate the event handling functions for filter and search events.
            
    
        // Generate set method for buttons
        
  
        private Hashtable _PreviousUIData = new Hashtable();
        public virtual Hashtable PreviousUIData {
            get {
                return this._PreviousUIData;
            }
            set {
                this._PreviousUIData = value;
            }
        }
  

        
        public String RecordUniqueId {
            get {
                return (string)this.ViewState["BaseMvwISDCustomerXrefRecordControl_Rec"];
            }
            set {
                this.ViewState["BaseMvwISDCustomerXrefRecordControl_Rec"] = value;
            }
        }
        
        public MvwISDCustomerXrefRecord DataSource {
            get {
                return (MvwISDCustomerXrefRecord)(this._DataSource);
            }
            set {
                this._DataSource = value;
            }
        }
        

        private string _checkSum;
        public virtual string CheckSum {
            get {
                return (this._checkSum);
            }
            set {
                this._checkSum = value;
            }
        }
    
        private int _TotalPages;
        public virtual int TotalPages {
            get {
                return (this._TotalPages);
            }
            set {
                this._TotalPages = value;
            }
        }
        
        private int _PageIndex;
        public virtual int PageIndex {
            get {
                return (this._PageIndex);
            }
            set {
                this._PageIndex = value;
            }
        }
        
        private int _PageSize;
        public int PageSize {
          get {
            return this._PageSize;
          }
          set {
            this._PageSize = value;
          }
        }
      
        private int _TotalRecords;
        public int TotalRecords {
          get {
            return (this._TotalRecords);
          }
          set {
            if (this.PageSize > 0) {
              this.TotalPages = Convert.ToInt32(Math.Ceiling(Convert.ToDouble(value) / Convert.ToDouble(this.PageSize)));
            }
            this._TotalRecords = value;
          }
        }
        
        private bool _DisplayLastPage;
        public virtual bool DisplayLastPage {
            get {
                return (this._DisplayLastPage);
            }
            set {
                this._DisplayLastPage = value;
            }
        }
        
        
    
        private KeyValue selectedParentKeyValue;
        public KeyValue SelectedParentKeyValue
        {
            get
            {
                return this.selectedParentKeyValue;
            }
            set
            {
                this.selectedParentKeyValue = value;
            }
        }
       
#region "Helper Properties"
        
        public System.Web.UI.WebControls.Literal Address {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Address");
            }
        }
            
        public System.Web.UI.WebControls.Literal Address2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Address2");
            }
        }
            
        public System.Web.UI.WebControls.Literal AddressLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AddressLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal AsteaCustomer {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AsteaCustomer");
            }
        }
            
        public System.Web.UI.WebControls.Literal AsteaCustomerLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AsteaCustomerLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CGCCustomer {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCustomer");
            }
        }
            
        public System.Web.UI.WebControls.Literal CGCCustomerLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCustomerLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal City {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "City");
            }
        }
            
        public System.Web.UI.WebControls.Literal CustomerMap {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CustomerMap");
            }
        }
        
        public System.Web.UI.WebControls.Literal CustomerName1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CustomerName1");
            }
        }
            
        public System.Web.UI.WebControls.Literal CustomerNameLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CustomerNameLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal State {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "State");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomer1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomer1");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomerLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal Zip {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Zip");
            }
        }
            
    #endregion

    #region "Helper Functions"
    public override string ModifyRedirectUrl(string url, string arg, bool bEncrypt)
    {
        return this.Page.EvaluateExpressions(url, arg, bEncrypt, this);
    }

    public override string ModifyRedirectUrl(string url, string arg, bool bEncrypt,bool includeSession)
    {
        return this.Page.EvaluateExpressions(url, arg, bEncrypt, this,includeSession);
    }

    public override string EvaluateExpressions(string url, string arg, bool bEncrypt)
    {
    MvwISDCustomerXrefRecord rec = null;
             
            try {
                rec = this.GetRecord();
            }
            catch (Exception ) {
                // Do Nothing
            }
            
            if (rec == null && url.IndexOf("{") >= 0) {
                // Localization.
                
                throw new Exception(Page.GetResourceValue("Err:RecDataSrcNotInitialized", "VPLookup"));
                    
            }
        
            return EvaluateExpressions(url, arg, rec, bEncrypt);
        
    }


    public override string EvaluateExpressions(string url, string arg, bool bEncrypt,bool includeSession)
    {
    MvwISDCustomerXrefRecord rec = null;
    
          try {
               rec = this.GetRecord();
          }
          catch (Exception ) {
          // Do Nothing
          }

          if (rec == null && url.IndexOf("{") >= 0) {
          // Localization.
    
              throw new Exception(Page.GetResourceValue("Err:RecDataSrcNotInitialized", "VPLookup"));
      
          }
    
          if (includeSession)
          {
              return EvaluateExpressions(url, arg, rec, bEncrypt);
          }
          else
          {
              return EvaluateExpressions(url, arg, rec, bEncrypt,includeSession);
          }
    
    }

    
        public virtual MvwISDCustomerXrefRecord GetRecord()
             
        {
        
            if (this.DataSource != null) {
                return this.DataSource;
            }
            
            if (this.RecordUniqueId != null) {
              
                return MvwISDCustomerXrefView.GetRecord(this.RecordUniqueId, true);
              
            }
            
            // Localization.
            
            return null;
                
        }

        public new BaseApplicationPage Page
        {
            get {
                return ((BaseApplicationPage)base.Page);
            }
        }

#endregion

}

  

#endregion
    
  
}

  