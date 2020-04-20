
// This file implements the TableControl, TableControlRow, and RecordControl classes for the 
// Show_MvwISDJobPhaseXref_Table.aspx page.  The Row or RecordControl classes are the 
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

  
namespace VPLookup.UI.Controls.Show_MvwISDJobPhaseXref_Table
{
  

#region "Section 1: Place your customizations here."

    
public class MvwISDJobPhaseXrefTableControlRow : BaseMvwISDJobPhaseXrefTableControlRow
{
      
        // The BaseMvwISDJobPhaseXrefTableControlRow implements code for a ROW within the
        // the MvwISDJobPhaseXrefTableControl table.  The BaseMvwISDJobPhaseXrefTableControlRow implements the DataBind and SaveData methods.
        // The loading of data is actually performed by the LoadData method in the base class of MvwISDJobPhaseXrefTableControl.

        // This is the ideal place to add your code customizations. For example, you can override the DataBind, 
        // SaveData, GetUIData, and Validate methods.
        
}

  

public class MvwISDJobPhaseXrefTableControl : BaseMvwISDJobPhaseXrefTableControl
{
    // The BaseMvwISDJobPhaseXrefTableControl class implements the LoadData, DataBind, CreateWhereClause
    // and other methods to load and display the data in a table control.

    // This is the ideal place to add your code customizations. You can override the LoadData and CreateWhereClause,
    // The MvwISDJobPhaseXrefTableControlRow class offers another place where you can customize
    // the DataBind, GetUIData, SaveData and Validate methods specific to each row displayed on the table.

}

  
public class MvwISDJobXrefRecordControl : BaseMvwISDJobXrefRecordControl
{
      
        // The BaseMvwISDJobXrefRecordControl implements the LoadData, DataBind and other
        // methods to load and display the data in a table control.

        // This is the ideal place to add your code customizations. For example, you can override the LoadData, 
        // CreateWhereClause, DataBind, SaveData, GetUIData, and Validate methods.
        
}

  

#endregion

  

#region "Section 2: Do not modify this section."
    
    
// Base class for the MvwISDJobPhaseXrefTableControlRow control on the Show_MvwISDJobPhaseXref_Table page.
// Do not modify this class. Instead override any method in MvwISDJobPhaseXrefTableControlRow.
public class BaseMvwISDJobPhaseXrefTableControlRow : VPLookup.UI.BaseApplicationRecordControl
{
        public BaseMvwISDJobPhaseXrefTableControlRow()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        // To customize, override this method in MvwISDJobPhaseXrefTableControlRow.
        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
                
            this.ClearControlsFromSession();
        }

        // To customize, override this method in MvwISDJobPhaseXrefTableControlRow.
        protected virtual void Control_Load(object sender, System.EventArgs e)
        {      
        
              // Show confirmation message on Click
              this.DeleteRowButton.Attributes.Add("onClick", "return (confirm(\"" + ((BaseApplicationPage)this.Page).GetResourceValue("DeleteRecordConfirm", "VPLookup") + "\"));");            
        
              // Register the event handlers.

          
                    this.DeleteRowButton.Click += DeleteRowButton_Click;
                        
                    this.EditRowButton.Click += EditRowButton_Click;
                        
                    this.ExpandRowButton.Click += ExpandRowButton_Click;
                        
        }

        public virtual void LoadData()  
        {
            // Load the data from the database into the DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            // It is better to make changes to functions called by LoadData such as
            // CreateWhereClause, rather than making changes here.
            
        
            // The RecordUniqueId is set the first time a record is loaded, and is
            // used during a PostBack to load the record.
            if (this.RecordUniqueId != null && this.RecordUniqueId.Length > 0) {
              
                this.DataSource = MvwISDJobPhaseXrefView.GetRecord(this.RecordUniqueId, true);
              
                return;
            }
      
            // Since this is a row in the table, the data for this row is loaded by the 
            // LoadData method of the BaseMvwISDJobPhaseXrefTableControl when the data for the entire
            // table is loaded.
            
            this.DataSource = new MvwISDJobPhaseXrefRecord();
            
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
                SetCGCCoLabel();
                SetCGCJob();
                SetCGCJobLabel();
                SetConversionNotes();
                SetConversionNotesLabel();
                SetCostTypeCode();
                SetCostTypeCodeLabel();
                SetCostTypeDesc();
                SetCostTypeDescLabel();
                SetCustomerKey();
                SetCustomerKeyLabel();
                
                
                
                SetMvwISDJobPhaseXrefTabContainer();
                
                
                SetPhaseKey();
                SetPhaseKeyLabel();
                SetPOC();
                SetPOCLabel();
                SetPOCName();
                SetPOCNameLabel();
                SetSalesPerson();
                SetSalesPersonLabel();
                SetSalesPersonName();
                SetSalesPersonNameLabel();
                SetVPCo();
                SetVPCoLabel();
                SetVPCustomer();
                SetVPCustomerLabel();
                SetVPCustomerName();
                SetVPCustomerNameLabel();
                SetVPJob();
                SetVPJobDesc();
                SetVPJobDescLabel();
                SetVPJobLabel();
                SetVPPhase();
                SetVPPhaseDescription();
                SetVPPhaseDescriptionLabel();
                SetVPPhaseGroup();
                SetVPPhaseGroupLabel();
                SetVPPhaseLabel();
                SetDeleteRowButton();
              
                SetEditRowButton();
              
                SetExpandRowButton();
              

      

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
                      
        SetMvwISDJobXrefRecordControl();

        
        }
        
        
        public virtual void SetCGCCo()
        {
            
                    
            // Set the CGCCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CGCCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCCoSpecified) {
                								
                // If the CGCCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CGCCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CGCCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCCo.Text = MvwISDJobPhaseXrefView.CGCCo.Format(MvwISDJobPhaseXrefView.CGCCo.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CGCJob is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCJobSpecified) {
                								
                // If the CGCJob is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CGCJob);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CGCJob.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCJob is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCJob.Text = MvwISDJobPhaseXrefView.CGCJob.Format(MvwISDJobPhaseXrefView.CGCJob.DefaultValue);
            		
            }
            
            // If the CGCJob is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CGCJob.Text == null ||
                this.CGCJob.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CGCJob.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetConversionNotes()
        {
            
                    
            // Set the ConversionNotes Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.ConversionNotes is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ConversionNotesSpecified) {
                								
                // If the ConversionNotes is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.ConversionNotes);
                                
                if(formattedValue != null){
                    int popupThreshold = (int)(300);
                              
                    int maxLength = formattedValue.Length;
                    int originalLength = maxLength;
                    if (maxLength >= (int)(300)){
                        // Truncate based on FieldMaxLength on Properties.
                        maxLength = (int)(300);
                        //First strip of all html tags:
                        formattedValue = StringUtils.ConvertHTMLToPlainText(formattedValue);
                        
                        formattedValue = HttpUtility.HtmlEncode(formattedValue); 
                    }
                                
                              
                    // For fields values larger than the PopupTheshold on Properties, display a popup.
                    if (originalLength >= popupThreshold) {
                        String name = HttpUtility.HtmlEncode(MvwISDJobPhaseXrefView.ConversionNotes.Name);

                        if (!HttpUtility.HtmlEncode("%ISD_DEFAULT%").Equals("%ISD_DEFAULT%")) {
                           name = HttpUtility.HtmlEncode(this.Page.GetResourceValue("%ISD_DEFAULT%"));
                        }

                        formattedValue = "<a onclick=\'gPersist=true;\' class=\'truncatedText\' onmouseout=\'detailRolloverPopupClose();\' " +
                            "onmouseover=\'SaveMousePosition(event); delayRolloverPopup(\"PageMethods.GetRecordFieldValue(\\\"" + "NULL" + "\\\", \\\"VPLookup.Business.MvwISDJobPhaseXrefView, VPLookup.Business\\\",\\\"" +
                              (HttpUtility.UrlEncode(this.DataSource.GetID().ToString())).Replace("\\","\\\\\\\\") + "\\\", \\\"ConversionNotes\\\", \\\"ConversionNotes\\\", \\\"" +NetUtils.EncodeStringForHtmlDisplay(name.Substring(0, name.Length)) + "\\\",\\\"" + Page.GetResourceValue("Btn:Close", "VPLookup") + "\\\", " +
                        " false, 200," +
                            " 300, true, PopupDisplayWindowCallBackWith20);\", 500);'>" + NetUtils.EncodeStringForHtmlDisplay(formattedValue.Substring(0, Math.Min(maxLength, formattedValue.Length)));
                        if (maxLength == (int)(300))
                            {
                            formattedValue = formattedValue + "..." + "</a>";
                        }
                        else
                        {
                            formattedValue = formattedValue + "</a>";
                            
                            formattedValue = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"><tr><td>" + formattedValue + "</td></tr></table>";
                        }
                    }
                    else{
                        if (maxLength == (int)(300)) {
                          formattedValue = NetUtils.EncodeStringForHtmlDisplay(formattedValue.Substring(0,Math.Min(maxLength, formattedValue.Length)));
                          formattedValue = formattedValue + "...";
                        }
                        
                        else
                        {
                          formattedValue = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"><tr><td>" + formattedValue + "</td></tr></table>";
                        }
                          
                    }
                }
                
                this.ConversionNotes.Text = formattedValue;
                   
            } 
            
            else {
            
                // ConversionNotes is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.ConversionNotes.Text = MvwISDJobPhaseXrefView.ConversionNotes.Format(MvwISDJobPhaseXrefView.ConversionNotes.DefaultValue);
            		
            }
            
            // If the ConversionNotes is NULL or blank, then use the value specified  
            // on Properties.
            if (this.ConversionNotes.Text == null ||
                this.ConversionNotes.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.ConversionNotes.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCostTypeCode()
        {
            
                    
            // Set the CostTypeCode Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CostTypeCode is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CostTypeCodeSpecified) {
                								
                // If the CostTypeCode is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CostTypeCode);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CostTypeCode.Text = formattedValue;
                   
            } 
            
            else {
            
                // CostTypeCode is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CostTypeCode.Text = MvwISDJobPhaseXrefView.CostTypeCode.Format(MvwISDJobPhaseXrefView.CostTypeCode.DefaultValue);
            		
            }
            
            // If the CostTypeCode is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CostTypeCode.Text == null ||
                this.CostTypeCode.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CostTypeCode.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCostTypeDesc()
        {
            
                    
            // Set the CostTypeDesc Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CostTypeDesc is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CostTypeDescSpecified) {
                								
                // If the CostTypeDesc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CostTypeDesc);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CostTypeDesc.Text = formattedValue;
                   
            } 
            
            else {
            
                // CostTypeDesc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CostTypeDesc.Text = MvwISDJobPhaseXrefView.CostTypeDesc.Format(MvwISDJobPhaseXrefView.CostTypeDesc.DefaultValue);
            		
            }
            
            // If the CostTypeDesc is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CostTypeDesc.Text == null ||
                this.CostTypeDesc.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CostTypeDesc.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCustomerKey()
        {
            
                    
            // Set the CustomerKey Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CustomerKey is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CustomerKeySpecified) {
                								
                // If the CustomerKey is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CustomerKey);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CustomerKey.Text = formattedValue;
                   
            } 
            
            else {
            
                // CustomerKey is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CustomerKey.Text = MvwISDJobPhaseXrefView.CustomerKey.Format(MvwISDJobPhaseXrefView.CustomerKey.DefaultValue);
            		
            }
            
            // If the CustomerKey is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CustomerKey.Text == null ||
                this.CustomerKey.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CustomerKey.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPhaseKey()
        {
            
                    
            // Set the PhaseKey Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.PhaseKey is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PhaseKeySpecified) {
                								
                // If the PhaseKey is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.PhaseKey);
                                
                if(formattedValue != null){
                    int popupThreshold = (int)(300);
                              
                    int maxLength = formattedValue.Length;
                    int originalLength = maxLength;
                    if (maxLength >= (int)(300)){
                        // Truncate based on FieldMaxLength on Properties.
                        maxLength = (int)(300);
                        //First strip of all html tags:
                        formattedValue = StringUtils.ConvertHTMLToPlainText(formattedValue);
                        
                        formattedValue = HttpUtility.HtmlEncode(formattedValue); 
                    }
                                
                              
                    // For fields values larger than the PopupTheshold on Properties, display a popup.
                    if (originalLength >= popupThreshold) {
                        String name = HttpUtility.HtmlEncode(MvwISDJobPhaseXrefView.PhaseKey.Name);

                        if (!HttpUtility.HtmlEncode("%ISD_DEFAULT%").Equals("%ISD_DEFAULT%")) {
                           name = HttpUtility.HtmlEncode(this.Page.GetResourceValue("%ISD_DEFAULT%"));
                        }

                        formattedValue = "<a onclick=\'gPersist=true;\' class=\'truncatedText\' onmouseout=\'detailRolloverPopupClose();\' " +
                            "onmouseover=\'SaveMousePosition(event); delayRolloverPopup(\"PageMethods.GetRecordFieldValue(\\\"" + "NULL" + "\\\", \\\"VPLookup.Business.MvwISDJobPhaseXrefView, VPLookup.Business\\\",\\\"" +
                              (HttpUtility.UrlEncode(this.DataSource.GetID().ToString())).Replace("\\","\\\\\\\\") + "\\\", \\\"PhaseKey\\\", \\\"PhaseKey\\\", \\\"" +NetUtils.EncodeStringForHtmlDisplay(name.Substring(0, name.Length)) + "\\\",\\\"" + Page.GetResourceValue("Btn:Close", "VPLookup") + "\\\", " +
                        " false, 200," +
                            " 300, true, PopupDisplayWindowCallBackWith20);\", 500);'>" + NetUtils.EncodeStringForHtmlDisplay(formattedValue.Substring(0, Math.Min(maxLength, formattedValue.Length)));
                        if (maxLength == (int)(300))
                            {
                            formattedValue = formattedValue + "..." + "</a>";
                        }
                        else
                        {
                            formattedValue = formattedValue + "</a>";
                            
                            formattedValue = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"><tr><td>" + formattedValue + "</td></tr></table>";
                        }
                    }
                    else{
                        if (maxLength == (int)(300)) {
                          formattedValue = NetUtils.EncodeStringForHtmlDisplay(formattedValue.Substring(0,Math.Min(maxLength, formattedValue.Length)));
                          formattedValue = formattedValue + "...";
                        }
                        
                        else
                        {
                          formattedValue = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"><tr><td>" + formattedValue + "</td></tr></table>";
                        }
                          
                    }
                }
                
                this.PhaseKey.Text = formattedValue;
                   
            } 
            
            else {
            
                // PhaseKey is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PhaseKey.Text = MvwISDJobPhaseXrefView.PhaseKey.Format(MvwISDJobPhaseXrefView.PhaseKey.DefaultValue);
            		
            }
            
            // If the PhaseKey is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PhaseKey.Text == null ||
                this.PhaseKey.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PhaseKey.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOC()
        {
            
                    
            // Set the POC Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.POC is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCSpecified) {
                								
                // If the POC is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.POC);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POC.Text = formattedValue;
                   
            } 
            
            else {
            
                // POC is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POC.Text = MvwISDJobPhaseXrefView.POC.Format(MvwISDJobPhaseXrefView.POC.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.POCName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCNameSpecified) {
                								
                // If the POCName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.POCName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POCName.Text = formattedValue;
                   
            } 
            
            else {
            
                // POCName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POCName.Text = MvwISDJobPhaseXrefView.POCName.Format(MvwISDJobPhaseXrefView.POCName.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.SalesPerson is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SalesPersonSpecified) {
                								
                // If the SalesPerson is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.SalesPerson);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SalesPerson.Text = formattedValue;
                   
            } 
            
            else {
            
                // SalesPerson is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SalesPerson.Text = MvwISDJobPhaseXrefView.SalesPerson.Format(MvwISDJobPhaseXrefView.SalesPerson.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.SalesPersonName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SalesPersonNameSpecified) {
                								
                // If the SalesPersonName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.SalesPersonName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SalesPersonName.Text = formattedValue;
                   
            } 
            
            else {
            
                // SalesPersonName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SalesPersonName.Text = MvwISDJobPhaseXrefView.SalesPersonName.Format(MvwISDJobPhaseXrefView.SalesPersonName.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCoSpecified) {
                								
                // If the VPCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCo.Text = MvwISDJobPhaseXrefView.VPCo.Format(MvwISDJobPhaseXrefView.VPCo.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPCustomer is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerSpecified) {
                								
                // If the VPCustomer is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPCustomer);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCustomer.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomer is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomer.Text = MvwISDJobPhaseXrefView.VPCustomer.Format(MvwISDJobPhaseXrefView.VPCustomer.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPCustomerName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerNameSpecified) {
                								
                // If the VPCustomerName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPCustomerName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCustomerName.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomerName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomerName.Text = MvwISDJobPhaseXrefView.VPCustomerName.Format(MvwISDJobPhaseXrefView.VPCustomerName.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPJob is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPJobSpecified) {
                								
                // If the VPJob is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPJob);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPJob.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPJob is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPJob.Text = MvwISDJobPhaseXrefView.VPJob.Format(MvwISDJobPhaseXrefView.VPJob.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPJobDesc is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPJobDescSpecified) {
                								
                // If the VPJobDesc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPJobDesc);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPJobDesc.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPJobDesc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPJobDesc.Text = MvwISDJobPhaseXrefView.VPJobDesc.Format(MvwISDJobPhaseXrefView.VPJobDesc.DefaultValue);
            		
            }
            
            // If the VPJobDesc is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPJobDesc.Text == null ||
                this.VPJobDesc.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPJobDesc.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPPhase()
        {
            
                    
            // Set the VPPhase Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPPhase is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPPhaseSpecified) {
                								
                // If the VPPhase is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPPhase);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPPhase.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPPhase is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPPhase.Text = MvwISDJobPhaseXrefView.VPPhase.Format(MvwISDJobPhaseXrefView.VPPhase.DefaultValue);
            		
            }
            
            // If the VPPhase is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPPhase.Text == null ||
                this.VPPhase.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPPhase.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPPhaseDescription()
        {
            
                    
            // Set the VPPhaseDescription Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPPhaseDescription is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPPhaseDescriptionSpecified) {
                								
                // If the VPPhaseDescription is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPPhaseDescription);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPPhaseDescription.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPPhaseDescription is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPPhaseDescription.Text = MvwISDJobPhaseXrefView.VPPhaseDescription.Format(MvwISDJobPhaseXrefView.VPPhaseDescription.DefaultValue);
            		
            }
            
            // If the VPPhaseDescription is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPPhaseDescription.Text == null ||
                this.VPPhaseDescription.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPPhaseDescription.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPPhaseGroup()
        {
            
                    
            // Set the VPPhaseGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPPhaseGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPPhaseGroupSpecified) {
                								
                // If the VPPhaseGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPPhaseGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPPhaseGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPPhaseGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPPhaseGroup.Text = MvwISDJobPhaseXrefView.VPPhaseGroup.Format(MvwISDJobPhaseXrefView.VPPhaseGroup.DefaultValue);
            		
            }
            
            // If the VPPhaseGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPPhaseGroup.Text == null ||
                this.VPPhaseGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPPhaseGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCGCCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetCGCJobLabel()
                  {
                  
                    
        }
                
        public virtual void SetConversionNotesLabel()
                  {
                  
                    
        }
                
        public virtual void SetCostTypeCodeLabel()
                  {
                  
                    
        }
                
        public virtual void SetCostTypeDescLabel()
                  {
                  
                    
        }
                
        public virtual void SetCustomerKeyLabel()
                  {
                  
                    
        }
                
        public virtual void SetPhaseKeyLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOCLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOCNameLabel()
                  {
                  
                    
        }
                
        public virtual void SetSalesPersonLabel()
                  {
                  
                    
        }
                
        public virtual void SetSalesPersonNameLabel()
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
                
        public virtual void SetVPJobDescLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPJobLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPPhaseDescriptionLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPPhaseGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPPhaseLabel()
                  {
                  
                    
        }
                
        public virtual void SetMvwISDJobPhaseXrefTabContainer()    
        
        {
                            
                   
            if (EvaluateFormula("URL(\"TabVisible\")").ToLower() == "true") 
                MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTabContainer").Visible = true;
            else if (EvaluateFormula("URL(\"TabVisible\")").ToLower() == "false") 
                MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTabContainer").Visible = false;
         
  
        }      
      
        public virtual void SetMvwISDJobXrefRecordControl()           
        
        {        
            if (MvwISDJobXrefRecordControl.Visible)
            {
                MvwISDJobXrefRecordControl.LoadData();
                MvwISDJobXrefRecordControl.DataBind();
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
                ((MvwISDJobPhaseXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDJobPhaseXrefTableControl")).DataChanged = true;
                ((MvwISDJobPhaseXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDJobPhaseXrefTableControl")).ResetData = true;
            }
            
      
            // update session or cookie by formula
             		  
      
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            this.ResetData = true;
            
            this.CheckSum = "";
            // For Master-Detail relationships, save data on the Detail table(s)            
          MvwISDJobXrefRecordControl recMvwISDJobXrefRecordControl = (MvwISDJobXrefRecordControl)(MiscUtils.FindControlRecursively(this, "MvwISDJobXrefRecordControl"));
        recMvwISDJobXrefRecordControl.SaveData();
        
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
            GetConversionNotes();
            GetCostTypeCode();
            GetCostTypeDesc();
            GetCustomerKey();
            GetPhaseKey();
            GetPOC();
            GetPOCName();
            GetSalesPerson();
            GetSalesPersonName();
            GetVPCo();
            GetVPCustomer();
            GetVPCustomerName();
            GetVPJob();
            GetVPJobDesc();
            GetVPPhase();
            GetVPPhaseDescription();
            GetVPPhaseGroup();
        }
        
        
        public virtual void GetCGCCo()
        {
            
        }
                
        public virtual void GetCGCJob()
        {
            
        }
                
        public virtual void GetConversionNotes()
        {
            
        }
                
        public virtual void GetCostTypeCode()
        {
            
        }
                
        public virtual void GetCostTypeDesc()
        {
            
        }
                
        public virtual void GetCustomerKey()
        {
            
        }
                
        public virtual void GetPhaseKey()
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
                
        public virtual void GetVPPhase()
        {
            
        }
                
        public virtual void GetVPPhaseDescription()
        {
            
        }
                
        public virtual void GetVPPhaseGroup()
        {
            
        }
                

      // To customize, override this method in MvwISDJobPhaseXrefTableControlRow.
      
        public virtual WhereClause CreateWhereClause()
         
        {
//Bryan Check
    
            bool hasFiltersMvwISDJobPhaseXrefTableControl = false;
            hasFiltersMvwISDJobPhaseXrefTableControl = hasFiltersMvwISDJobPhaseXrefTableControl && false; // suppress warning
      
            bool hasFiltersMvwISDJobXrefRecordControl = false;
            hasFiltersMvwISDJobXrefRecordControl = hasFiltersMvwISDJobXrefRecordControl && false; // suppress warning
      
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
          MvwISDJobPhaseXrefView.DeleteRecord(pkValue);
          
              
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            ((MvwISDJobPhaseXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDJobPhaseXrefTableControl")).DataChanged = true;
            ((MvwISDJobPhaseXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDJobPhaseXrefTableControl")).ResetData = true;
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
        
        public virtual void SetDeleteRowButton()                
              
        {
        
   
        }
            
        public virtual void SetEditRowButton()                
              
        {
        
   
        }
            
        public virtual void SetExpandRowButton()                
              
        {
        
   
        }
            
        // event handler for ImageButton
        public virtual void DeleteRowButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                
            if (!this.Page.IsPageRefresh) {
        
                this.Delete();
              
            }
      this.Page.CommitTransaction(sender);
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
        public virtual void EditRowButton_Click(object sender, ImageClickEventArgs args)
        {
              
            // The redirect URL is set on the Properties, Custom Properties or Actions.
            // The ModifyRedirectURL call resolves the parameters before the
            // Response.Redirect redirects the page to the URL.  
            // Any code after the Response.Redirect call will not be executed, since the page is
            // redirected to the URL.
            
            string url = @"../mvwISDJobPhaseXref/Edit-MvwISDJobPhaseXref.aspx?MvwISDJobPhaseXref={PK}";
            
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
            
            
        
        // event handler for ImageButton
        public virtual void ExpandRowButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                MvwISDJobPhaseXrefTableControl panelControl = (MiscUtils.GetParentControlObject(this, "MvwISDJobPhaseXrefTableControl") as MvwISDJobPhaseXrefTableControl);

          MvwISDJobPhaseXrefTableControlRow[] repeatedRows = panelControl.GetRecordControls();
          foreach (MvwISDJobPhaseXrefTableControlRow repeatedRow in repeatedRows)
          {
              System.Web.UI.Control altRow = (MiscUtils.FindControlRecursively(repeatedRow, "MvwISDJobPhaseXrefTableControlAltRow") as System.Web.UI.Control);
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
                return (string)this.ViewState["BaseMvwISDJobPhaseXrefTableControlRow_Rec"];
            }
            set {
                this.ViewState["BaseMvwISDJobPhaseXrefTableControlRow_Rec"] = value;
            }
        }
        
        public MvwISDJobPhaseXrefRecord DataSource {
            get {
                return (MvwISDJobPhaseXrefRecord)(this._DataSource);
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
            
        public System.Web.UI.WebControls.Literal CGCCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CGCJob {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCJob");
            }
        }
            
        public System.Web.UI.WebControls.Literal CGCJobLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCJobLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal ConversionNotes {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ConversionNotes");
            }
        }
            
        public System.Web.UI.WebControls.Literal ConversionNotesLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ConversionNotesLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CostTypeCode {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeCode");
            }
        }
            
        public System.Web.UI.WebControls.Literal CostTypeCodeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeCodeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CostTypeDesc {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeDesc");
            }
        }
            
        public System.Web.UI.WebControls.Literal CostTypeDescLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeDescLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CustomerKey {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CustomerKey");
            }
        }
            
        public System.Web.UI.WebControls.Literal CustomerKeyLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CustomerKeyLabel");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton DeleteRowButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "DeleteRowButton");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton EditRowButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "EditRowButton");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton ExpandRowButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ExpandRowButton");
            }
        }
        
        public AjaxControlToolkit.TabContainer MvwISDJobPhaseXrefTabContainer {
            get {
                return (AjaxControlToolkit.TabContainer)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTabContainer");
            }
        }
        
        public MvwISDJobXrefRecordControl MvwISDJobXrefRecordControl {
            get {
                return (MvwISDJobXrefRecordControl)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDJobXrefRecordControl");
            }
        }
        
        public System.Web.UI.WebControls.Literal PhaseKey {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PhaseKey");
            }
        }
            
        public System.Web.UI.WebControls.Literal PhaseKeyLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PhaseKeyLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POC {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POC");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POCName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCName");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCNameLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SalesPerson {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPerson");
            }
        }
            
        public System.Web.UI.WebControls.Literal SalesPersonLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SalesPersonName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonName");
            }
        }
            
        public System.Web.UI.WebControls.Literal SalesPersonNameLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPCustomer {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomer");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomerLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPCustomerName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerName");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomerNameLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerNameLabel");
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
            
        public System.Web.UI.WebControls.Literal VPJobDescLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobDescLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPJobLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPPhase {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhase");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPPhaseDescription {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhaseDescription");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPPhaseDescriptionLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhaseDescriptionLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPPhaseGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhaseGroup");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPPhaseGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhaseGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPPhaseLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhaseLabel");
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
    MvwISDJobPhaseXrefRecord rec = null;
             
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
    MvwISDJobPhaseXrefRecord rec = null;
    
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

    
        public virtual MvwISDJobPhaseXrefRecord GetRecord()
             
        {
        
            if (this.DataSource != null) {
                return this.DataSource;
            }
            
            if (this.RecordUniqueId != null) {
              
                return MvwISDJobPhaseXrefView.GetRecord(this.RecordUniqueId, true);
              
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

  
// Base class for the MvwISDJobPhaseXrefTableControl control on the Show_MvwISDJobPhaseXref_Table page.
// Do not modify this class. Instead override any method in MvwISDJobPhaseXrefTableControl.
public class BaseMvwISDJobPhaseXrefTableControl : VPLookup.UI.BaseApplicationTableControl
{
         

       public BaseMvwISDJobPhaseXrefTableControl()
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
                
                  if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                  {
                  initialVal = "";
                  }
                
                if  (this.InSession(this.OrderSort)) 				
                    initialVal = this.GetFromSession(this.OrderSort);
                
                if (initialVal != null && initialVal != "")		
                {
                        
                    this.OrderSort.Items.Add(new ListItem(initialVal, initialVal));
                        
                    this.OrderSort.SelectedValue = initialVal;
                            
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.CostTypeCodeFilter)) 				
                    initialVal = this.GetFromSession(this.CostTypeCodeFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"CostTypeCode\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    string[] CostTypeCodeFilteritemListFromSession = initialVal.Split(',');
                    int index = 0;
                    foreach (string item in CostTypeCodeFilteritemListFromSession)
                    {
                        if (index == 0 && item.ToString().Equals(""))
                        {
                            // do nothing
                        }
                        else
                        {
                            this.CostTypeCodeFilter.Items.Add(item);
                            this.CostTypeCodeFilter.Items[index].Selected = true;
                            index += 1;
                        }
                    }
                    foreach (ListItem listItem in this.CostTypeCodeFilter.Items)
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


      
      
            // Control Initializations.
            // Initialize the table's current sort order.

            if (this.InSession(this, "Order_By"))
                this.CurrentSortOrder = OrderBy.FromXmlString(this.GetFromSession(this, "Order_By", null));         
            else
            {
                   
                this.CurrentSortOrder = new OrderBy(true, false);
            
        }


    
            // Setup default pagination settings.
    
            this.PageSize = Convert.ToInt32(this.GetFromSession(this, "Page_Size", "10"));
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
          
            // Setup the button events.
          
                    this.ExcelButton.Click += ExcelButton_Click;
                        
                    this.ImportButton.Click += ImportButton_Click;
                        
                    this.NewButton.Click += NewButton_Click;
                        
                    this.PDFButton.Click += PDFButton_Click;
                        
                    this.ResetButton.Click += ResetButton_Click;
                        
                    this.SearchButton.Click += SearchButton_Click;
                        
                    this.WordButton.Click += WordButton_Click;
                        
                    this.ActionsButton.Button.Click += ActionsButton_Click;
                        
                    this.FilterButton.Button.Click += FilterButton_Click;
                        
                    this.FiltersButton.Button.Click += FiltersButton_Click;
                        
            this.OrderSort.SelectedIndexChanged += new EventHandler(OrderSort_SelectedIndexChanged);
            
              this.CostTypeCodeFilter.SelectedIndexChanged += CostTypeCodeFilter_SelectedIndexChanged;                  
                        
        
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
                      Type myrec = typeof(VPLookup.Business.MvwISDJobPhaseXrefRecord);
                      this.DataSource = (MvwISDJobPhaseXrefRecord[])(alist.ToArray(myrec));
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
                    foreach (MvwISDJobPhaseXrefTableControlRow rc in this.GetRecordControls()) {
                        if (!rc.IsNewRecord) {
                            rc.DataSource = rc.GetRecord();
                            rc.GetUIData();
                            postdata.Add(rc.DataSource);
                            UIData.Add(rc.PreservedUIData());
                        }
                    }
                    Type myrec = typeof(VPLookup.Business.MvwISDJobPhaseXrefRecord);
                    this.DataSource = (MvwISDJobPhaseXrefRecord[])(postdata.ToArray(myrec));
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
        
        public virtual MvwISDJobPhaseXrefRecord[] GetRecords(BaseFilter join, WhereClause where, OrderBy orderBy, int pageIndex, int pageSize)
        {    
            // by default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               
    
            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecordCount as well
            // selCols.Add(MvwISDJobPhaseXrefView.Column1, true);          
            // selCols.Add(MvwISDJobPhaseXrefView.Column2, true);          
            // selCols.Add(MvwISDJobPhaseXrefView.Column3, true);          
            

            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                  
            {
              
                return MvwISDJobPhaseXrefView.GetRecords(join, where, orderBy, this.PageIndex, this.PageSize);
                 
            }
            else
            {
                MvwISDJobPhaseXrefView databaseTable = new MvwISDJobPhaseXrefView();
                databaseTable.SelectedColumns.Clear();
                databaseTable.SelectedColumns.AddRange(selCols);
                
            
                
                ArrayList recList; 
                orderBy.ExpandForeignKeyColums = false;
                recList = databaseTable.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
                return (recList.ToArray(typeof(MvwISDJobPhaseXrefRecord)) as MvwISDJobPhaseXrefRecord[]);
            }            
            
        }
        
        
        public virtual int GetRecordCount(BaseFilter join, WhereClause where)
        {

            // By default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               


            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecords as well
            // selCols.Add(MvwISDJobPhaseXrefView.Column1, true);          
            // selCols.Add(MvwISDJobPhaseXrefView.Column2, true);          
            // selCols.Add(MvwISDJobPhaseXrefView.Column3, true);          


            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                     
            
                return MvwISDJobPhaseXrefView.GetRecordCount(join, where);
            else
            {
                MvwISDJobPhaseXrefView databaseTable = new MvwISDJobPhaseXrefView();
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
        System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTableControlRepeater"));
        if (rep == null){return;}
        rep.DataSource = this.DataSource;
        rep.DataBind();
          
        int index = 0;
        foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
        {
            // Loop through all rows in the table, set its DataSource and call DataBind().
            MvwISDJobPhaseXrefTableControlRow recControl = (MvwISDJobPhaseXrefTableControlRow)(repItem.FindControl("MvwISDJobPhaseXrefTableControlRow"));
            recControl.DataSource = this.DataSource[index];            
            if (this.UIData.Count > index)
                recControl.PreviousUIData = this.UIData[index];
            recControl.DataBind();
            
           
            recControl.Visible = !this.InDeletedRecordIds(recControl);
        
            index++;
        }
           
    
            // Call the Set methods for each controls on the panel
        
                
                SetCostTypeCodeFilter();
                SetCostTypeCodeLabel1();
                
                
                
                
                
                SetOrderSort();
                
                
                
                
                SetSearchText();
                SetSortByLabel();
                
                
                SetExcelButton();
              
                SetImportButton();
              
                SetNewButton();
              
                SetPDFButton();
              
                SetResetButton();
              
                SetSearchButton();
              
                SetWordButton();
              
                SetActionsButton();
              
                SetFilterButton();
              
                SetFiltersButton();
              
            // setting the state of expand or collapse alternative rows
      
            bool expandFirstRow = true;
        MvwISDJobPhaseXrefTableControlRow[] recControls = this.GetRecordControls();
            for (int i = 0; i < recControls.Length; i++)
            {
                System.Web.UI.Control altRow = (MiscUtils.FindControlRecursively(recControls[i], "MvwISDJobPhaseXrefTableControlAltRow") as System.Web.UI.Control);
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


            
            this.CostTypeCodeFilter.ClearSelection();
            
            this.OrderSort.ClearSelection();
            
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
    
            // Bind the buttons for MvwISDJobPhaseXrefTableControl pagination.
        
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
              
            foreach (MvwISDJobPhaseXrefTableControlRow recCtl in this.GetRecordControls())
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
            foreach (MvwISDJobPhaseXrefTableControlRow recCtl in this.GetRecordControls()){
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
            MvwISDJobPhaseXrefView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
    
            // CreateWhereClause() Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
        
            if (MiscUtils.IsValueSelected(this.CostTypeCodeFilter)) {
                        
                int selectedItemCount = 0;
                foreach (ListItem item in this.CostTypeCodeFilter.Items){
                    if (item.Selected) {
                        selectedItemCount += 1;
                        
                          
                    }
                }
                WhereClause filter = new WhereClause();
                foreach (ListItem item in this.CostTypeCodeFilter.Items){
                    if ((item.Selected) && ((item.Value == "--ANY--") || (item.Value == "--PLEASE_SELECT--")) && (selectedItemCount > 1)){
                        item.Selected = false;
                    }
                    if (item.Selected){
                        filter.iOR(MvwISDJobPhaseXrefView.CostTypeCode, BaseFilter.ComparisonOperator.EqualsTo, item.Value, false, false);
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
        
      cols.Add(MvwISDJobPhaseXrefView.VPCustomerName);
      
      foreach(BaseColumn col in cols)
      {
      
                    search.iOR(col, BaseFilter.ComparisonOperator.Contains, MiscUtils.GetSelectedValue(this.SearchText, this.GetFromSession(this.SearchText)), true, false);
        
      }
    
                    wc.iAND(search);
                  
                }
            }
                  
            return wc;
        }
        
         
        public virtual WhereClause CreateWhereClause(String searchText, String fromSearchControl, String AutoTypeAheadSearch, String AutoTypeAheadWordSeparators)
        {
            // This CreateWhereClause is used for loading list of suggestions for Auto Type-Ahead feature.
            MvwISDJobPhaseXrefView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
        
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
            String appRelativeVirtualPath = (String)HttpContext.Current.Session["AppRelativeVirtualPath"];
            
            // Adds clauses if values are selected in Filter controls which are configured in the page.
          
      String CostTypeCodeFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "CostTypeCodeFilter_Ajax"];
            if (MiscUtils.IsValueSelected(CostTypeCodeFilterSelectedValue)) {

              
        if (CostTypeCodeFilterSelectedValue != null){
                        string[] CostTypeCodeFilteritemListFromSession = CostTypeCodeFilterSelectedValue.Split(',');
                        int index = 0;
                        WhereClause filter = new WhereClause();
                        foreach (string item in CostTypeCodeFilteritemListFromSession)
                        {
                            if (index == 0 && item.ToString().Equals(""))
                            {
                            }
                            else
                            {
                                filter.iOR(MvwISDJobPhaseXrefView.CostTypeCode, BaseFilter.ComparisonOperator.EqualsTo, item, false, false);
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
        
      cols.Add(MvwISDJobPhaseXrefView.VPCustomerName);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Starts_With, formatedSearchText, true, false);
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, AutoTypeAheadWordSeparators + formatedSearchText, true, false);
                
      }
    
                    } else {
                        
      ColumnList cols = new ColumnList();    
        
      cols.Add(MvwISDJobPhaseXrefView.VPCustomerName);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, formatedSearchText, true, false);
      }
    
                    } 
                    wc.iAND(search);
                  
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
            VPLookup.Business.MvwISDJobPhaseXrefRecord[] recordList  = MvwISDJobPhaseXrefView.GetRecords(filterJoin, wc, null, 0, count, ref count);
            String resultItem = "";
            if (resultItem == "") resultItem = "";
            foreach (MvwISDJobPhaseXrefRecord rec in recordList ){
                // Exit the loop if recordList count has reached AutoTypeAheadListSize.
                if (resultList.Count >= count) {
                    break;
                }
                // If the field is configured to Display as Foreign key, Format() method returns the 
                // Display as Forien Key value instead of original field value.
                // Since search had to be done in multiple fields (selected in Control's page property, binding tab) in a record,
                // We need to find relevent field to display which matches the prefixText and is not already present in the result list.
        
                resultItem = rec.Format(MvwISDJobPhaseXrefView.VPCustomerName);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDJobPhaseXrefView.VPCustomerName.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDJobPhaseXrefView.VPCustomerName.IsFullTextSearchable);
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
    System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTableControlRepeater"));
    if (rep == null){return;}

    foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
    {
    // Loop through all rows in the table, set its DataSource and call DataBind().
    MvwISDJobPhaseXrefTableControlRow recControl = (MvwISDJobPhaseXrefTableControlRow)(repItem.FindControl("MvwISDJobPhaseXrefTableControlRow"));

      if (recControl.Visible && recControl.IsNewRecord) {
      MvwISDJobPhaseXrefRecord rec = new MvwISDJobPhaseXrefRecord();
        
                        if (recControl.CGCCo.Text != "") {
                            rec.Parse(recControl.CGCCo.Text, MvwISDJobPhaseXrefView.CGCCo);
                  }
                
                        if (recControl.CGCJob.Text != "") {
                            rec.Parse(recControl.CGCJob.Text, MvwISDJobPhaseXrefView.CGCJob);
                  }
                
                        if (recControl.ConversionNotes.Text != "") {
                            rec.Parse(recControl.ConversionNotes.Text, MvwISDJobPhaseXrefView.ConversionNotes);
                  }
                
                        if (recControl.CostTypeCode.Text != "") {
                            rec.Parse(recControl.CostTypeCode.Text, MvwISDJobPhaseXrefView.CostTypeCode);
                  }
                
                        if (recControl.CostTypeDesc.Text != "") {
                            rec.Parse(recControl.CostTypeDesc.Text, MvwISDJobPhaseXrefView.CostTypeDesc);
                  }
                
                        if (recControl.CustomerKey.Text != "") {
                            rec.Parse(recControl.CustomerKey.Text, MvwISDJobPhaseXrefView.CustomerKey);
                  }
                
                        if (recControl.PhaseKey.Text != "") {
                            rec.Parse(recControl.PhaseKey.Text, MvwISDJobPhaseXrefView.PhaseKey);
                  }
                
                        if (recControl.POC.Text != "") {
                            rec.Parse(recControl.POC.Text, MvwISDJobPhaseXrefView.POC);
                  }
                
                        if (recControl.POCName.Text != "") {
                            rec.Parse(recControl.POCName.Text, MvwISDJobPhaseXrefView.POCName);
                  }
                
                        if (recControl.SalesPerson.Text != "") {
                            rec.Parse(recControl.SalesPerson.Text, MvwISDJobPhaseXrefView.SalesPerson);
                  }
                
                        if (recControl.SalesPersonName.Text != "") {
                            rec.Parse(recControl.SalesPersonName.Text, MvwISDJobPhaseXrefView.SalesPersonName);
                  }
                
                        if (recControl.VPCo.Text != "") {
                            rec.Parse(recControl.VPCo.Text, MvwISDJobPhaseXrefView.VPCo);
                  }
                
                        if (recControl.VPCustomer.Text != "") {
                            rec.Parse(recControl.VPCustomer.Text, MvwISDJobPhaseXrefView.VPCustomer);
                  }
                
                        if (recControl.VPCustomerName.Text != "") {
                            rec.Parse(recControl.VPCustomerName.Text, MvwISDJobPhaseXrefView.VPCustomerName);
                  }
                
                        if (recControl.VPJob.Text != "") {
                            rec.Parse(recControl.VPJob.Text, MvwISDJobPhaseXrefView.VPJob);
                  }
                
                        if (recControl.VPJobDesc.Text != "") {
                            rec.Parse(recControl.VPJobDesc.Text, MvwISDJobPhaseXrefView.VPJobDesc);
                  }
                
                        if (recControl.VPPhase.Text != "") {
                            rec.Parse(recControl.VPPhase.Text, MvwISDJobPhaseXrefView.VPPhase);
                  }
                
                        if (recControl.VPPhaseDescription.Text != "") {
                            rec.Parse(recControl.VPPhaseDescription.Text, MvwISDJobPhaseXrefView.VPPhaseDescription);
                  }
                
                        if (recControl.VPPhaseGroup.Text != "") {
                            rec.Parse(recControl.VPPhaseGroup.Text, MvwISDJobPhaseXrefView.VPPhaseGroup);
                  }
                
      newUIDataList.Add(recControl.PreservedUIData());
      newRecordList.Add(rec);
      }
      }
      }
    
            // Add any new record to the list.
            for (int count = 1; count <= this.AddNewRecord; count++) {
              
                newRecordList.Insert(0, new MvwISDJobPhaseXrefRecord());
                newUIDataList.Insert(0, new Hashtable());
              
            }
            this.AddNewRecord = 0;

            // Finally, add any new records to the DataSource.
            if (newRecordList.Count > 0) {
              
                ArrayList finalList = new ArrayList(this.DataSource);
                finalList.InsertRange(0, newRecordList);

                Type myrec = typeof(VPLookup.Business.MvwISDJobPhaseXrefRecord);
                this.DataSource = (MvwISDJobPhaseXrefRecord[])(finalList.ToArray(myrec));
              
            }
            
            // Add the existing UI data to this hash table
            if (newUIDataList.Count > 0)
                this.UIData.InsertRange(0, newUIDataList);
        }

        
        public void AddToDeletedRecordIds(MvwISDJobPhaseXrefTableControlRow rec)
        {
            if (rec.IsNewRecord) {
                return;
            }

            if (this.DeletedRecordIds != null && this.DeletedRecordIds.Length > 0) {
                this.DeletedRecordIds += ",";
            }

            this.DeletedRecordIds += "[" + rec.RecordUniqueId + "]";
        }

        protected virtual bool InDeletedRecordIds(MvwISDJobPhaseXrefTableControlRow rec)            
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
        
        public virtual void SetCostTypeCodeLabel1()
                  {
                  
                    
        }
                
        public virtual void SetSortByLabel()
                  {
                  
                      //Code for the text property is generated inside the .aspx file. 
                      //To override this property you can uncomment the following property and add you own value.
                      //this.SortByLabel.Text = "Some value";
                    
                    
        }
                
        public virtual void SetOrderSort()
        {
            
                this.PopulateOrderSort(MiscUtils.GetSelectedValue(this.OrderSort,  GetFromSession(this.OrderSort)), 500);					
                    

        }
            
        public virtual void SetCostTypeCodeFilter()
        {
            
            ArrayList CostTypeCodeFilterselectedFilterItemList = new ArrayList();
            string CostTypeCodeFilteritemsString = null;
            if (this.InSession(this.CostTypeCodeFilter))
                CostTypeCodeFilteritemsString = this.GetFromSession(this.CostTypeCodeFilter);
            
            if (CostTypeCodeFilteritemsString != null)
            {
                string[] CostTypeCodeFilteritemListFromSession = CostTypeCodeFilteritemsString.Split(',');
                foreach (string item in CostTypeCodeFilteritemListFromSession)
                {
                    CostTypeCodeFilterselectedFilterItemList.Add(item);
                }
            }
              
            			
            this.PopulateCostTypeCodeFilter(MiscUtils.GetSelectedValueList(this.CostTypeCodeFilter, CostTypeCodeFilterselectedFilterItemList), 500);
                    
              string url = this.ModifyRedirectUrl("../mvwISDJobPhaseXref/MvwISDJobPhaseXref-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.CostTypeCodeFilter.PostBackUrl = url + "?Target=" + this.CostTypeCodeFilter.ClientID + "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("CostTypeCode")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--ANY--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:All")) + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.CostTypeCodeFilter.Attributes["onClick"] = "initializePopupPage(this, '" + this.CostTypeCodeFilter.PostBackUrl + "', false, event); return false;";                  
                                   
        }
            
        public virtual void SetSearchText()
        {
                                            
            this.SearchText.Attributes.Add("onfocus", "if(this.value=='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "') {this.value='';this.className='Search_Input';}");
            this.SearchText.Attributes.Add("onblur", "if(this.value=='') {this.value='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "';this.className='Search_InputHint';}");
                                   
        }
            
        // Get the filters' data for OrderSort.
                
        protected virtual void PopulateOrderSort(string selectedValue, int maxItems)
                    
        {
            
              
                this.OrderSort.Items.Clear();
                
              // 1. Setup the static list items
              							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("{Txt:PleaseSelect}"), "--PLEASE_SELECT--"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("CGC Company {Txt:Ascending}"), "CGCCo Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("CGC Company {Txt:Descending}"), "CGCCo Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("CGC Job {Txt:Ascending}"), "CGCJob Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("CGC Job {Txt:Descending}"), "CGCJob Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Cost Type Code {Txt:Ascending}"), "CostTypeCode Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Cost Type Code {Txt:Descending}"), "CostTypeCode Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Cost Type Description {Txt:Ascending}"), "CostTypeDesc Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Cost Type Description {Txt:Descending}"), "CostTypeDesc Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("POC {Txt:Ascending}"), "POC Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("POC {Txt:Descending}"), "POC Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("POC Name {Txt:Ascending}"), "POCName Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("POC Name {Txt:Descending}"), "POCName Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Sales Person {Txt:Ascending}"), "SalesPerson Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Sales Person {Txt:Descending}"), "SalesPerson Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Sales Person Name {Txt:Ascending}"), "SalesPersonName Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Sales Person Name {Txt:Descending}"), "SalesPersonName Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("VP Company {Txt:Ascending}"), "VPCo Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("VP Company {Txt:Descending}"), "VPCo Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("VP Customer Name {Txt:Ascending}"), "VPCustomerName Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("VP Customer Name {Txt:Descending}"), "VPCustomerName Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Is Phase Active {Txt:Ascending}"), "IsPhaseActive Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Is Phase Active {Txt:Descending}"), "IsPhaseActive Desc"));
                            
            try
            {          
                // Set the selected value.
                MiscUtils.SetSelectedValue(this.OrderSort, selectedValue);

               
            }
            catch
            {
            }
              
            if (this.OrderSort.SelectedValue != null && this.OrderSort.Items.FindByValue(this.OrderSort.SelectedValue) == null)
                this.OrderSort.SelectedValue = null;
              
        }
            
        // Get the filters' data for CostTypeCodeFilter.
                
        protected virtual void PopulateCostTypeCodeFilter(ArrayList selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            WhereClause wc = this.CreateWhereClause_CostTypeCodeFilter();            
            this.CostTypeCodeFilter.Items.Clear();
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_CostTypeCodeFilter function.
            // It is better to customize the where clause there.
          
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDJobPhaseXrefView.CostTypeCode, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDJobPhaseXrefView.GetValues(MvwISDJobPhaseXrefView.CostTypeCode, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDJobPhaseXrefView.CostTypeCode.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDJobPhaseXrefView.CostTypeCode.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.CostTypeCodeFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.CostTypeCodeFilter.Items.Add(newItem);

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
            
            
            this.CostTypeCodeFilter.SetFieldMaxLength(50);
                                 
                  
            // Add the selected value.
            if (this.CostTypeCodeFilter.Items.Count == 0)
                this.CostTypeCodeFilter.Items.Add(new ListItem(Page.GetResourceValue("Txt:All", "VPLookup"), "--ANY--"));
            
            // Mark all items to be selected.
            foreach (ListItem item in this.CostTypeCodeFilter.Items)
            {
                item.Selected = true;
            }
                               
        }
            
        public virtual WhereClause CreateWhereClause_CostTypeCodeFilter()
        {
            // Create a where clause for the filter CostTypeCodeFilter.
            // This function is called by the Populate method to load the items 
            // in the CostTypeCodeFilterQuickSelector
        
            ArrayList CostTypeCodeFilterselectedFilterItemList = new ArrayList();
            string CostTypeCodeFilteritemsString = null;
            if (this.InSession(this.CostTypeCodeFilter))
                CostTypeCodeFilteritemsString = this.GetFromSession(this.CostTypeCodeFilter);
            
            if (CostTypeCodeFilteritemsString != null)
            {
                string[] CostTypeCodeFilteritemListFromSession = CostTypeCodeFilteritemsString.Split(',');
                foreach (string item in CostTypeCodeFilteritemListFromSession)
                {
                    CostTypeCodeFilterselectedFilterItemList.Add(item);
                }
            }
              
            CostTypeCodeFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CostTypeCodeFilter, CostTypeCodeFilterselectedFilterItemList); 
            WhereClause wc = new WhereClause();
            if (CostTypeCodeFilterselectedFilterItemList == null || CostTypeCodeFilterselectedFilterItemList.Count == 0)
                wc.RunQuery = false;
            else            
            {
                foreach (string item in CostTypeCodeFilterselectedFilterItemList)
                {
            
      
   
                    wc.iOR(MvwISDJobPhaseXrefView.CostTypeCode, BaseFilter.ComparisonOperator.EqualsTo, item);

                                
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
        
            this.SaveToSession(this.OrderSort, this.OrderSort.SelectedValue);
                  
            ArrayList CostTypeCodeFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CostTypeCodeFilter, null);
            string CostTypeCodeFilterSessionString = "";
            if (CostTypeCodeFilterselectedFilterItemList != null){
                foreach (string item in CostTypeCodeFilterselectedFilterItemList){
                    CostTypeCodeFilterSessionString = String.Concat(CostTypeCodeFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession(this.CostTypeCodeFilter, CostTypeCodeFilterSessionString);
                  
            this.SaveToSession(this.SearchText, this.SearchText.Text);
                  
            
                    
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
          
            this.SaveToSession(this.OrderSort, this.OrderSort.SelectedValue);
                  
            ArrayList CostTypeCodeFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CostTypeCodeFilter, null);
            string CostTypeCodeFilterSessionString = "";
            if (CostTypeCodeFilterselectedFilterItemList != null){
                foreach (string item in CostTypeCodeFilterselectedFilterItemList){
                    CostTypeCodeFilterSessionString = String.Concat(CostTypeCodeFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession("CostTypeCodeFilter_Ajax", CostTypeCodeFilterSessionString);
          
      this.SaveToSession("SearchText_Ajax", this.SearchText.Text);
              
           HttpContext.Current.Session["AppRelativeVirtualPath"] = this.Page.AppRelativeVirtualPath;
         
        }
        
        
        protected override void ClearControlsFromSession()
        {
            base.ClearControlsFromSession();
            // Clear filter controls values from the session.
        
            this.RemoveFromSession(this.OrderSort);
            this.RemoveFromSession(this.CostTypeCodeFilter);
            this.RemoveFromSession(this.SearchText);
            
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

            string orderByStr = (string)ViewState["MvwISDJobPhaseXrefTableControl_OrderBy"];
          
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
                this.ViewState["MvwISDJobPhaseXrefTableControl_OrderBy"] = this.CurrentSortOrder.ToXmlString();
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
        							
                    this.ImportButton.PostBackUrl = "../Shared/SelectFileToImport.aspx?TableName=MvwISDJobPhaseXref" ;
                    this.ImportButton.Attributes["onClick"] = "window.open('" + this.Page.EncryptUrlParameter(this.ImportButton.PostBackUrl) + "','importWindow', 'width=700, height=500,top=' +(screen.availHeight-500)/2 + ',left=' + (screen.availWidth-700)/2+ ', resizable=yes, scrollbars=yes,modal=yes'); return false;";
                        
   
        }
            
        public virtual void SetNewButton()                
              
        {
        
              try
              {
                    string url = "../mvwISDJobPhaseXref/Add-MvwISDJobPhaseXref.aspx?TabVisible=False&SaveAndNewVisible=False";
              
                      
                    url = this.ModifyRedirectUrl(url, "", true);
                    
                    url = this.Page.ModifyRedirectUrl(url, "", true);                                  
                    
                    url = url + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup") + "&Target=" + (this.Page as BaseApplicationPage).Encrypt(MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTableControl_PostbackTracker").ClientID);                           
                                
                string javascriptCall = "";
                
                    javascriptCall = "initializePopupPage(document.getElementById('" + MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTableControl_PostbackTracker").ClientID + "'), '" + url + "', true, event);";                                      
                       
                    this.NewButton.Attributes["onClick"] = javascriptCall + "return false;";            
                }
                catch
                {
                    // do nothing.  If the code above fails, server side click event, NewButton_ClickNewButton_Click will be trigger when user click the button.
                }
                  
   
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
    
      
            if (MiscUtils.IsValueSelected(CostTypeCodeFilter))
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


              this.TotalRecords = MvwISDJobPhaseXrefView.GetRecordCount(join, wc);
              if (this.TotalRecords > 10000)
              {
              
                // Add each of the columns in order of export.
                BaseColumn[] columns = new BaseColumn[] {
                             MvwISDJobPhaseXrefView.VPCo,
             MvwISDJobPhaseXrefView.VPJob,
             MvwISDJobPhaseXrefView.CGCCo,
             MvwISDJobPhaseXrefView.CGCJob,
             MvwISDJobPhaseXrefView.VPJobDesc,
             MvwISDJobPhaseXrefView.VPCustomer,
             MvwISDJobPhaseXrefView.VPCustomerName,
             MvwISDJobPhaseXrefView.POC,
             MvwISDJobPhaseXrefView.POCName,
             MvwISDJobPhaseXrefView.SalesPerson,
             MvwISDJobPhaseXrefView.SalesPersonName,
             MvwISDJobPhaseXrefView.VPPhaseGroup,
             MvwISDJobPhaseXrefView.VPPhase,
             MvwISDJobPhaseXrefView.CostTypeCode,
             MvwISDJobPhaseXrefView.CostTypeDesc,
             MvwISDJobPhaseXrefView.VPPhaseDescription,
             MvwISDJobPhaseXrefView.ConversionNotes,
             MvwISDJobPhaseXrefView.PhaseKey,
             MvwISDJobPhaseXrefView.CustomerKey,
             null};
                ExportDataToCSV exportData = new ExportDataToCSV(MvwISDJobPhaseXrefView.Instance,wc,orderBy,columns);
                exportData.StartExport(this.Page.Response, true);

                DataForExport dataForCSV = new DataForExport(MvwISDJobPhaseXrefView.Instance, wc, orderBy, columns,join);

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
              ExportDataToExcel excelReport = new ExportDataToExcel(MvwISDJobPhaseXrefView.Instance, wc, orderBy);
              // Add each of the columns in order of export.
              // To customize the data type, change the second parameter of the new ExcelColumn to be
              // a format string from Excel's Format Cell menu. For example "dddd, mmmm dd, yyyy h:mm AM/PM;@", "#,##0.00"

              if (this.Page.Response == null)
              return;

              excelReport.CreateExcelBook();

              int width = 0;
              int columnCounter = 0;
              DataForExport data = new DataForExport(MvwISDJobPhaseXrefView.Instance, wc, orderBy, null,join);
                           data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.VPCo, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.VPJob, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.CGCCo, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.CGCJob, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.VPJobDesc, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.VPCustomer, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.VPCustomerName, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.POC, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.POCName, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.SalesPerson, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.SalesPersonName, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.VPPhaseGroup, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.VPPhase, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.CostTypeCode, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.CostTypeDesc, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.VPPhaseDescription, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.ConversionNotes, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.PhaseKey, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDJobPhaseXrefView.CustomerKey, "Default"));


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
                val = MvwISDJobPhaseXrefView.GetDFKA(rec.GetValue(col.DisplayColumn).ToString(), col.DisplayColumn, null) as string;
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
        public virtual void NewButton_Click(object sender, ImageClickEventArgs args)
        {
              
            // The redirect URL is set on the Properties, Custom Properties or Actions.
            // The ModifyRedirectURL call resolves the parameters before the
            // Response.Redirect redirects the page to the URL.  
            // Any code after the Response.Redirect call will not be executed, since the page is
            // redirected to the URL.
            
            string url = @"../mvwISDJobPhaseXref/Add-MvwISDJobPhaseXref.aspx?TabVisible=False&SaveAndNewVisible=False";
            
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
      
                    url = url + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup") + "&Target=" + (this.Page as BaseApplicationPage).Encrypt(MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTableControl_PostbackTracker").ClientID);                           
                                
                string javascriptCall = "";
                
                    javascriptCall = "initializePopupPage(document.getElementById('" + MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefTableControl_PostbackTracker").ClientID + "'), '" + url + "', true, event);";                                      
                AjaxControlToolkit.ToolkitScriptManager.RegisterStartupScript(this, this.GetType(), "NewButton_Click", javascriptCall, true);
        
            }
        
        }
            
            
        
        // event handler for ImageButton
        public virtual void PDFButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                

                PDFReport report = new PDFReport();

                report.SpecificReportFileName = Page.Server.MapPath("Show-MvwISDJobPhaseXref-Table.PDFButton.report");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "mvwISDJobPhaseXref";
                // If Show-MvwISDJobPhaseXref-Table.PDFButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.   
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(MvwISDJobPhaseXrefView.VPCo.Name, ReportEnum.Align.Right, "${VPCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPJob.Name, ReportEnum.Align.Left, "${VPJob}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.CGCCo.Name, ReportEnum.Align.Right, "${CGCCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.CGCJob.Name, ReportEnum.Align.Left, "${CGCJob}", ReportEnum.Align.Left, 17);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPJobDesc.Name, ReportEnum.Align.Left, "${VPJobDesc}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPCustomer.Name, ReportEnum.Align.Right, "${VPCustomer}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPCustomerName.Name, ReportEnum.Align.Left, "${VPCustomerName}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.POC.Name, ReportEnum.Align.Right, "${POC}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.POCName.Name, ReportEnum.Align.Left, "${POCName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobPhaseXrefView.SalesPerson.Name, ReportEnum.Align.Right, "${SalesPerson}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.SalesPersonName.Name, ReportEnum.Align.Left, "${SalesPersonName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPPhaseGroup.Name, ReportEnum.Align.Right, "${VPPhaseGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPPhase.Name, ReportEnum.Align.Left, "${VPPhase}", ReportEnum.Align.Left, 20);
                 report.AddColumn(MvwISDJobPhaseXrefView.CostTypeCode.Name, ReportEnum.Align.Left, "${CostTypeCode}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.CostTypeDesc.Name, ReportEnum.Align.Left, "${CostTypeDesc}", ReportEnum.Align.Left, 19);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPPhaseDescription.Name, ReportEnum.Align.Left, "${VPPhaseDescription}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.ConversionNotes.Name, ReportEnum.Align.Left, "${ConversionNotes}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.PhaseKey.Name, ReportEnum.Align.Left, "${PhaseKey}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.CustomerKey.Name, ReportEnum.Align.Left, "${CustomerKey}", ReportEnum.Align.Left, 18);

  
                int rowsPerQuery = 5000;
                int recordCount = 0;
                                
                report.Page = Page.GetResourceValue("Txt:Page", "VPLookup");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                
                ColumnList columns = MvwISDJobPhaseXrefView.GetColumnList();
                
                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                
                int pageNum = 0;
                int totalRows = MvwISDJobPhaseXrefView.GetRecordCount(joinFilter,whereClause);
                MvwISDJobPhaseXrefRecord[] records = null;
                
                do
                {
                    
                    records = MvwISDJobPhaseXrefView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                     if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( MvwISDJobPhaseXrefRecord record in records)
                    
                        {
                            // AddData method takes four parameters   
                            // The 1st parameter represent the data format
                            // The 2nd parameter represent the data value
                            // The 3rd parameter represent the default alignment of column using the data
                            // The 4th parameter represent the maximum length of the data value being shown
                                                 report.AddData("${VPCo}", record.Format(MvwISDJobPhaseXrefView.VPCo), ReportEnum.Align.Right, 300);
                             report.AddData("${VPJob}", record.Format(MvwISDJobPhaseXrefView.VPJob), ReportEnum.Align.Left, 300);
                             report.AddData("${CGCCo}", record.Format(MvwISDJobPhaseXrefView.CGCCo), ReportEnum.Align.Right, 300);
                             report.AddData("${CGCJob}", record.Format(MvwISDJobPhaseXrefView.CGCJob), ReportEnum.Align.Left, 300);
                             report.AddData("${VPJobDesc}", record.Format(MvwISDJobPhaseXrefView.VPJobDesc), ReportEnum.Align.Left, 300);
                             report.AddData("${VPCustomer}", record.Format(MvwISDJobPhaseXrefView.VPCustomer), ReportEnum.Align.Right, 300);
                             report.AddData("${VPCustomerName}", record.Format(MvwISDJobPhaseXrefView.VPCustomerName), ReportEnum.Align.Left, 300);
                             report.AddData("${POC}", record.Format(MvwISDJobPhaseXrefView.POC), ReportEnum.Align.Right, 300);
                             report.AddData("${POCName}", record.Format(MvwISDJobPhaseXrefView.POCName), ReportEnum.Align.Left, 300);
                             report.AddData("${SalesPerson}", record.Format(MvwISDJobPhaseXrefView.SalesPerson), ReportEnum.Align.Right, 300);
                             report.AddData("${SalesPersonName}", record.Format(MvwISDJobPhaseXrefView.SalesPersonName), ReportEnum.Align.Left, 300);
                             report.AddData("${VPPhaseGroup}", record.Format(MvwISDJobPhaseXrefView.VPPhaseGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${VPPhase}", record.Format(MvwISDJobPhaseXrefView.VPPhase), ReportEnum.Align.Left, 300);
                             report.AddData("${CostTypeCode}", record.Format(MvwISDJobPhaseXrefView.CostTypeCode), ReportEnum.Align.Left, 300);
                             report.AddData("${CostTypeDesc}", record.Format(MvwISDJobPhaseXrefView.CostTypeDesc), ReportEnum.Align.Left, 300);
                             report.AddData("${VPPhaseDescription}", record.Format(MvwISDJobPhaseXrefView.VPPhaseDescription), ReportEnum.Align.Left, 300);
                             report.AddData("${ConversionNotes}", record.Format(MvwISDJobPhaseXrefView.ConversionNotes), ReportEnum.Align.Left, 300);
                             report.AddData("${PhaseKey}", record.Format(MvwISDJobPhaseXrefView.PhaseKey), ReportEnum.Align.Left, 300);
                             report.AddData("${CustomerKey}", record.Format(MvwISDJobPhaseXrefView.CustomerKey), ReportEnum.Align.Left, 300);

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
                
              this.CostTypeCodeFilter.ClearSelection();
            
           
            this.OrderSort.ClearSelection();
          
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

                report.SpecificReportFileName = Page.Server.MapPath("Show-MvwISDJobPhaseXref-Table.WordButton.word");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "mvwISDJobPhaseXref";
                // If Show-MvwISDJobPhaseXref-Table.WordButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(MvwISDJobPhaseXrefView.VPCo.Name, ReportEnum.Align.Right, "${VPCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPJob.Name, ReportEnum.Align.Left, "${VPJob}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.CGCCo.Name, ReportEnum.Align.Right, "${CGCCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.CGCJob.Name, ReportEnum.Align.Left, "${CGCJob}", ReportEnum.Align.Left, 17);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPJobDesc.Name, ReportEnum.Align.Left, "${VPJobDesc}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPCustomer.Name, ReportEnum.Align.Right, "${VPCustomer}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPCustomerName.Name, ReportEnum.Align.Left, "${VPCustomerName}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.POC.Name, ReportEnum.Align.Right, "${POC}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.POCName.Name, ReportEnum.Align.Left, "${POCName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobPhaseXrefView.SalesPerson.Name, ReportEnum.Align.Right, "${SalesPerson}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.SalesPersonName.Name, ReportEnum.Align.Left, "${SalesPersonName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPPhaseGroup.Name, ReportEnum.Align.Right, "${VPPhaseGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPPhase.Name, ReportEnum.Align.Left, "${VPPhase}", ReportEnum.Align.Left, 20);
                 report.AddColumn(MvwISDJobPhaseXrefView.CostTypeCode.Name, ReportEnum.Align.Left, "${CostTypeCode}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDJobPhaseXrefView.CostTypeDesc.Name, ReportEnum.Align.Left, "${CostTypeDesc}", ReportEnum.Align.Left, 19);
                 report.AddColumn(MvwISDJobPhaseXrefView.VPPhaseDescription.Name, ReportEnum.Align.Left, "${VPPhaseDescription}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.ConversionNotes.Name, ReportEnum.Align.Left, "${ConversionNotes}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.PhaseKey.Name, ReportEnum.Align.Left, "${PhaseKey}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDJobPhaseXrefView.CustomerKey.Name, ReportEnum.Align.Left, "${CustomerKey}", ReportEnum.Align.Left, 18);

                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
            
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                

                int rowsPerQuery = 5000;
                int pageNum = 0;
                int recordCount = 0;
                int totalRows = MvwISDJobPhaseXrefView.GetRecordCount(joinFilter,whereClause);

                report.Page = Page.GetResourceValue("Txt:Page", "VPLookup");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                ColumnList columns = MvwISDJobPhaseXrefView.GetColumnList();
                MvwISDJobPhaseXrefRecord[] records = null;
                do
                {
                    records = MvwISDJobPhaseXrefView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                    if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( MvwISDJobPhaseXrefRecord record in records)
                        {
                            // AddData method takes four parameters
                            // The 1st parameter represents the data format
                            // The 2nd parameter represents the data value
                            // The 3rd parameter represents the default alignment of column using the data
                            // The 4th parameter represents the maximum length of the data value being shown
                             report.AddData("${VPCo}", record.Format(MvwISDJobPhaseXrefView.VPCo), ReportEnum.Align.Right, 300);
                             report.AddData("${VPJob}", record.Format(MvwISDJobPhaseXrefView.VPJob), ReportEnum.Align.Left, 300);
                             report.AddData("${CGCCo}", record.Format(MvwISDJobPhaseXrefView.CGCCo), ReportEnum.Align.Right, 300);
                             report.AddData("${CGCJob}", record.Format(MvwISDJobPhaseXrefView.CGCJob), ReportEnum.Align.Left, 300);
                             report.AddData("${VPJobDesc}", record.Format(MvwISDJobPhaseXrefView.VPJobDesc), ReportEnum.Align.Left, 300);
                             report.AddData("${VPCustomer}", record.Format(MvwISDJobPhaseXrefView.VPCustomer), ReportEnum.Align.Right, 300);
                             report.AddData("${VPCustomerName}", record.Format(MvwISDJobPhaseXrefView.VPCustomerName), ReportEnum.Align.Left, 300);
                             report.AddData("${POC}", record.Format(MvwISDJobPhaseXrefView.POC), ReportEnum.Align.Right, 300);
                             report.AddData("${POCName}", record.Format(MvwISDJobPhaseXrefView.POCName), ReportEnum.Align.Left, 300);
                             report.AddData("${SalesPerson}", record.Format(MvwISDJobPhaseXrefView.SalesPerson), ReportEnum.Align.Right, 300);
                             report.AddData("${SalesPersonName}", record.Format(MvwISDJobPhaseXrefView.SalesPersonName), ReportEnum.Align.Left, 300);
                             report.AddData("${VPPhaseGroup}", record.Format(MvwISDJobPhaseXrefView.VPPhaseGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${VPPhase}", record.Format(MvwISDJobPhaseXrefView.VPPhase), ReportEnum.Align.Left, 300);
                             report.AddData("${CostTypeCode}", record.Format(MvwISDJobPhaseXrefView.CostTypeCode), ReportEnum.Align.Left, 300);
                             report.AddData("${CostTypeDesc}", record.Format(MvwISDJobPhaseXrefView.CostTypeDesc), ReportEnum.Align.Left, 300);
                             report.AddData("${VPPhaseDescription}", record.Format(MvwISDJobPhaseXrefView.VPPhaseDescription), ReportEnum.Align.Left, 300);
                             report.AddData("${ConversionNotes}", record.Format(MvwISDJobPhaseXrefView.ConversionNotes), ReportEnum.Align.Left, 300);
                             report.AddData("${PhaseKey}", record.Format(MvwISDJobPhaseXrefView.PhaseKey), ReportEnum.Align.Left, 300);
                             report.AddData("${CustomerKey}", record.Format(MvwISDJobPhaseXrefView.CustomerKey), ReportEnum.Align.Left, 300);

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
        
        // event handler for OrderSort
        protected virtual void OrderSort_SelectedIndexChanged(object sender, EventArgs args)
        {
              
                  string SelVal1 = this.OrderSort.SelectedValue.ToUpper();
                  string[] words1 = SelVal1.Split(' ');
                  if (SelVal1 != "" )
                  {
                  SelVal1 = SelVal1.Replace(words1[words1.Length - 1], "").TrimEnd();
                  foreach (BaseClasses.Data.BaseColumn ColumnNam in MvwISDJobPhaseXrefView.GetColumns())
                  {
                  if (ColumnNam.Name.ToUpper().Equals(SelVal1))
                  {
                  SelVal1 = ColumnNam.InternalName;
                  }
                  }
                  }

                
                OrderByItem sd = this.CurrentSortOrder.Find(MvwISDJobPhaseXrefView.GetColumnByName(SelVal1));
                if (sd == null || this.CurrentSortOrder.Items != null)
                {
                // First time sort, so add sort order for Discontinued.
                if (MvwISDJobPhaseXrefView.GetColumnByName(SelVal1) != null)
                {
                  this.CurrentSortOrder.Reset();
                }

                //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
                if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

                
                  if (SelVal1 != "--PLEASE_SELECT--" && MvwISDJobPhaseXrefView.GetColumnByName(SelVal1) != null)
                  {
                    if (words1[words1.Length - 1].Contains("ASC"))
                  {
                  this.CurrentSortOrder.Add(MvwISDJobPhaseXrefView.GetColumnByName(SelVal1),OrderByItem.OrderDir.Asc);
                    }
                    else
                    {
                      if (words1[words1.Length - 1].Contains("DESC"))
                  {
                  this.CurrentSortOrder.Add(MvwISDJobPhaseXrefView.GetColumnByName(SelVal1),OrderByItem.OrderDir.Desc );
                      }
                    }
                  }
                
                }
                this.DataChanged = true;
              				
        }
            
        // event handler for FieldFilter
        protected virtual void CostTypeCodeFilter_SelectedIndexChanged(object sender, EventArgs args)
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
                    _TotalRecords = MvwISDJobPhaseXrefView.GetRecordCount(CreateCompoundJoinFilter(), CreateWhereClause());
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
        
        public  MvwISDJobPhaseXrefRecord[] DataSource {
             
            get {
                return (MvwISDJobPhaseXrefRecord[])(base._DataSource);
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
        
        public BaseClasses.Web.UI.WebControls.QuickSelector CostTypeCodeFilter {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeCodeFilter");
            }
        }              
        
        public System.Web.UI.WebControls.Literal CostTypeCodeLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeCodeLabel1");
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
        
        public System.Web.UI.WebControls.ImageButton ImportButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ImportButton");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton NewButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "NewButton");
            }
        }
        
          public System.Web.UI.WebControls.DropDownList OrderSort {
          get {
          return (System.Web.UI.WebControls.DropDownList)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrderSort");
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
        
        public System.Web.UI.WebControls.ImageButton ResetButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ResetButton");
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
        
        public System.Web.UI.WebControls.Label SortByLabel {
            get {
                return (System.Web.UI.WebControls.Label)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SortByLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal Title {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Title");
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
                MvwISDJobPhaseXrefTableControlRow recCtl = this.GetSelectedRecordControl();
                if (recCtl == null && url.IndexOf("{") >= 0) {
                    // Localization.
                    throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
                }

        MvwISDJobPhaseXrefRecord rec = null;
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
                MvwISDJobPhaseXrefTableControlRow recCtl = this.GetSelectedRecordControl();
                if (recCtl == null && url.IndexOf("{") >= 0) {
                    // Localization.
                    throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
                }

        MvwISDJobPhaseXrefRecord rec = null;
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
          
        public virtual MvwISDJobPhaseXrefTableControlRow GetSelectedRecordControl()
        {
        
            return null;
          
        }

        public virtual MvwISDJobPhaseXrefTableControlRow[] GetSelectedRecordControls()
        {
        
            return (MvwISDJobPhaseXrefTableControlRow[])((new ArrayList()).ToArray(Type.GetType("VPLookup.UI.Controls.Show_MvwISDJobPhaseXref_Table.MvwISDJobPhaseXrefTableControlRow")));
          
        }

        public virtual void DeleteSelectedRecords(bool deferDeletion)
        {
            MvwISDJobPhaseXrefTableControlRow[] recordList = this.GetSelectedRecordControls();
            if (recordList.Length == 0) {
                // Localization.
                throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
            }
            
            foreach (MvwISDJobPhaseXrefTableControlRow recCtl in recordList)
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

        public MvwISDJobPhaseXrefTableControlRow[] GetRecordControls()
        {
            ArrayList recordList = new ArrayList();
            System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)this.FindControl("MvwISDJobPhaseXrefTableControlRepeater");
            if (rep == null){return null;}
            foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
            {
              MvwISDJobPhaseXrefTableControlRow recControl = (MvwISDJobPhaseXrefTableControlRow)repItem.FindControl("MvwISDJobPhaseXrefTableControlRow");
                  recordList.Add(recControl);
                
            }

            return (MvwISDJobPhaseXrefTableControlRow[])recordList.ToArray(Type.GetType("VPLookup.UI.Controls.Show_MvwISDJobPhaseXref_Table.MvwISDJobPhaseXrefTableControlRow"));
        }

        public new BaseApplicationPage Page 
        {
            get {
                return ((BaseApplicationPage)base.Page);
            }
        }
        
                

        
        
#endregion


    }
  
// Base class for the MvwISDJobXrefRecordControl control on the Show_MvwISDJobPhaseXref_Table page.
// Do not modify this class. Instead override any method in MvwISDJobXrefRecordControl.
public class BaseMvwISDJobXrefRecordControl : VPLookup.UI.BaseApplicationRecordControl
{
        public BaseMvwISDJobXrefRecordControl()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        // To customize, override this method in MvwISDJobXrefRecordControl.
        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
        
            
            string url = "";
            if (url == null) url = ""; //avoid warning on VS
            // Setup the filter and search events.
                
            this.ClearControlsFromSession();
        }

        // To customize, override this method in MvwISDJobXrefRecordControl.
        protected virtual void Control_Load(object sender, System.EventArgs e)
        {      
        
              // Setup the pagination events.	  
                     
        
              // Register the event handlers.

          
        }

        public virtual void LoadData()  
        {
            // Load the data from the database into the DataSource DatabaseViewpoint%dbo.mvwISDJobXref record.
            // It is better to make changes to functions called by LoadData such as
            // CreateWhereClause, rather than making changes here.
            
        
            // This is the first time a record is being retrieved from the database.
            // So create a Where Clause based on the staic Where clause specified
            // on the Query wizard and the dynamic part specified by the end user
            // on the search and filter controls (if any).
            
            WhereClause wc = this.CreateWhereClause();
            
            System.Web.UI.WebControls.Panel Panel = (System.Web.UI.WebControls.Panel)MiscUtils.FindControlRecursively(this, "MvwISDJobXrefRecordControlPanel");
            if (Panel != null){
                Panel.Visible = true;
            }
            
            // If there is no Where clause, then simply create a new, blank record.
            
            if (wc == null || !(wc.RunQuery)) {
                this.DataSource = new MvwISDJobXrefRecord();
            
                if (Panel != null){
                    Panel.Visible = false;
                }
              
                return;
            }
          
            // Retrieve the record from the database.  It is possible
            MvwISDJobXrefRecord[] recList = MvwISDJobXrefView.GetRecords(wc, null, 0, 2);
            if (recList.Length == 0) {
                // There is no data for this Where clause.
                wc.RunQuery = false;
                
                if (Panel != null){
                    Panel.Visible = false;
                }
                
                return;
            }
            
            // Set DataSource based on record retrieved from the database.
            this.DataSource = MvwISDJobXrefView.GetRecord(recList[0].GetID().ToXmlString(), true);
                  
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
        
                SetCGCCo2();
                SetCGCCoLabel1();
                SetCGCJob2();
                SetCGCJobLabel1();
                SetJobKey();
                SetJobKeyLabel();
                SetMailAddress();
                SetMailAddress2();
                SetMailAddress2Label();
                SetMailAddressLabel();
                SetMailCity();
                SetMailCityLabel();
                SetMailState();
                SetMailStateLabel();
                SetMailZip();
                SetMailZipLabel();
                SetPOC2();
                SetPOCLabel1();
                SetPOCName2();
                SetPOCNameLabel1();
                SetSalesPerson2();
                SetSalesPersonLabel1();
                SetSalesPersonName2();
                SetSalesPersonNameLabel1();
                SetVPCo2();
                SetVPCoLabel1();
                SetVPCustomer1();
                SetVPCustomerLabel1();
                SetVPCustomerName2();
                SetVPCustomerNameLabel1();
                SetVPJob1();
                SetVPJobDesc1();
                SetVPJobDescLabel1();
                SetVPJobLabel1();

      

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
        
        
        public virtual void SetCGCCo2()
        {
            
                    
            // Set the CGCCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.CGCCo2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCCoSpecified) {
                								
                // If the CGCCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.CGCCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CGCCo2.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCCo2.Text = MvwISDJobXrefView.CGCCo.Format(MvwISDJobXrefView.CGCCo.DefaultValue);
            		
            }
            
            // If the CGCCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CGCCo2.Text == null ||
                this.CGCCo2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CGCCo2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCGCJob2()
        {
            
                    
            // Set the CGCJob Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.CGCJob2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCJobSpecified) {
                								
                // If the CGCJob is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.CGCJob);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CGCJob2.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCJob is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCJob2.Text = MvwISDJobXrefView.CGCJob.Format(MvwISDJobXrefView.CGCJob.DefaultValue);
            		
            }
            
            // If the CGCJob is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CGCJob2.Text == null ||
                this.CGCJob2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CGCJob2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJobKey()
        {
            
                    
            // Set the JobKey Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.JobKey is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JobKeySpecified) {
                								
                // If the JobKey is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.JobKey);
                                
                if(formattedValue != null){
                    int popupThreshold = (int)(300);
                              
                    int maxLength = formattedValue.Length;
                    int originalLength = maxLength;
                    if (maxLength >= (int)(300)){
                        // Truncate based on FieldMaxLength on Properties.
                        maxLength = (int)(300);
                        //First strip of all html tags:
                        formattedValue = StringUtils.ConvertHTMLToPlainText(formattedValue);
                        
                        formattedValue = HttpUtility.HtmlEncode(formattedValue); 
                    }
                                
                              
                    // For fields values larger than the PopupTheshold on Properties, display a popup.
                    if (originalLength >= popupThreshold) {
                        String name = HttpUtility.HtmlEncode(MvwISDJobXrefView.JobKey.Name);

                        if (!HttpUtility.HtmlEncode("%ISD_DEFAULT%").Equals("%ISD_DEFAULT%")) {
                           name = HttpUtility.HtmlEncode(this.Page.GetResourceValue("%ISD_DEFAULT%"));
                        }

                        formattedValue = "<a onclick=\'gPersist=true;\' class=\'truncatedText\' onmouseout=\'detailRolloverPopupClose();\' " +
                            "onmouseover=\'SaveMousePosition(event); delayRolloverPopup(\"PageMethods.GetRecordFieldValue(\\\"" + "NULL" + "\\\", \\\"VPLookup.Business.MvwISDJobXrefView, VPLookup.Business\\\",\\\"" +
                              (HttpUtility.UrlEncode(this.DataSource.GetID().ToString())).Replace("\\","\\\\\\\\") + "\\\", \\\"JobKey\\\", \\\"JobKey\\\", \\\"" +NetUtils.EncodeStringForHtmlDisplay(name.Substring(0, name.Length)) + "\\\",\\\"" + Page.GetResourceValue("Btn:Close", "VPLookup") + "\\\", " +
                        " false, 200," +
                            " 300, true, PopupDisplayWindowCallBackWith20);\", 500);'>" + NetUtils.EncodeStringForHtmlDisplay(formattedValue.Substring(0, Math.Min(maxLength, formattedValue.Length)));
                        if (maxLength == (int)(300))
                            {
                            formattedValue = formattedValue + "..." + "</a>";
                        }
                        else
                        {
                            formattedValue = formattedValue + "</a>";
                            
                            formattedValue = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"><tr><td>" + formattedValue + "</td></tr></table>";
                        }
                    }
                    else{
                        if (maxLength == (int)(300)) {
                          formattedValue = NetUtils.EncodeStringForHtmlDisplay(formattedValue.Substring(0,Math.Min(maxLength, formattedValue.Length)));
                          formattedValue = formattedValue + "...";
                        }
                        
                        else
                        {
                          formattedValue = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"><tr><td>" + formattedValue + "</td></tr></table>";
                        }
                          
                    }
                }
                
                this.JobKey.Text = formattedValue;
                   
            } 
            
            else {
            
                // JobKey is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.JobKey.Text = MvwISDJobXrefView.JobKey.Format(MvwISDJobXrefView.JobKey.DefaultValue);
            		
            }
            
            // If the JobKey is NULL or blank, then use the value specified  
            // on Properties.
            if (this.JobKey.Text == null ||
                this.JobKey.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.JobKey.Text = "&nbsp;";
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
                
        public virtual void SetPOC2()
        {
            
                    
            // Set the POC Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.POC2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCSpecified) {
                								
                // If the POC is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.POC);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POC2.Text = formattedValue;
                   
            } 
            
            else {
            
                // POC is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POC2.Text = MvwISDJobXrefView.POC.Format(MvwISDJobXrefView.POC.DefaultValue);
            		
            }
            
            // If the POC is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POC2.Text == null ||
                this.POC2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POC2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOCName2()
        {
            
                    
            // Set the POCName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.POCName2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCNameSpecified) {
                								
                // If the POCName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.POCName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POCName2.Text = formattedValue;
                   
            } 
            
            else {
            
                // POCName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POCName2.Text = MvwISDJobXrefView.POCName.Format(MvwISDJobXrefView.POCName.DefaultValue);
            		
            }
            
            // If the POCName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POCName2.Text == null ||
                this.POCName2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POCName2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSalesPerson2()
        {
            
                    
            // Set the SalesPerson Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.SalesPerson2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SalesPersonSpecified) {
                								
                // If the SalesPerson is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.SalesPerson);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SalesPerson2.Text = formattedValue;
                   
            } 
            
            else {
            
                // SalesPerson is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SalesPerson2.Text = MvwISDJobXrefView.SalesPerson.Format(MvwISDJobXrefView.SalesPerson.DefaultValue);
            		
            }
            
            // If the SalesPerson is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SalesPerson2.Text == null ||
                this.SalesPerson2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SalesPerson2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSalesPersonName2()
        {
            
                    
            // Set the SalesPersonName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.SalesPersonName2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SalesPersonNameSpecified) {
                								
                // If the SalesPersonName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.SalesPersonName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SalesPersonName2.Text = formattedValue;
                   
            } 
            
            else {
            
                // SalesPersonName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SalesPersonName2.Text = MvwISDJobXrefView.SalesPersonName.Format(MvwISDJobXrefView.SalesPersonName.DefaultValue);
            		
            }
            
            // If the SalesPersonName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SalesPersonName2.Text == null ||
                this.SalesPersonName2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SalesPersonName2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPCo2()
        {
            
                    
            // Set the VPCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPCo2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCoSpecified) {
                								
                // If the VPCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCo2.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCo2.Text = MvwISDJobXrefView.VPCo.Format(MvwISDJobXrefView.VPCo.DefaultValue);
            		
            }
            
            // If the VPCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPCo2.Text == null ||
                this.VPCo2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPCo2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPCustomer1()
        {
            
                    
            // Set the VPCustomer Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPCustomer1 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerSpecified) {
                								
                // If the VPCustomer is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPCustomer);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCustomer1.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomer is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomer1.Text = MvwISDJobXrefView.VPCustomer.Format(MvwISDJobXrefView.VPCustomer.DefaultValue);
            		
            }
            
            // If the VPCustomer is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPCustomer1.Text == null ||
                this.VPCustomer1.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPCustomer1.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPCustomerName2()
        {
            
                    
            // Set the VPCustomerName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPCustomerName2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerNameSpecified) {
                								
                // If the VPCustomerName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPCustomerName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPCustomerName2.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomerName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomerName2.Text = MvwISDJobXrefView.VPCustomerName.Format(MvwISDJobXrefView.VPCustomerName.DefaultValue);
            		
            }
            
            // If the VPCustomerName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPCustomerName2.Text == null ||
                this.VPCustomerName2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPCustomerName2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPJob1()
        {
            
                    
            // Set the VPJob Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPJob1 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPJobSpecified) {
                								
                // If the VPJob is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPJob);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPJob1.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPJob is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPJob1.Text = MvwISDJobXrefView.VPJob.Format(MvwISDJobXrefView.VPJob.DefaultValue);
            		
            }
            
            // If the VPJob is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPJob1.Text == null ||
                this.VPJob1.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPJob1.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPJobDesc1()
        {
            
                    
            // Set the VPJobDesc Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobXref record retrieved from the database.
            // this.VPJobDesc1 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPJobDescSpecified) {
                								
                // If the VPJobDesc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobXrefView.VPJobDesc);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPJobDesc1.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPJobDesc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPJobDesc1.Text = MvwISDJobXrefView.VPJobDesc.Format(MvwISDJobXrefView.VPJobDesc.DefaultValue);
            		
            }
            
            // If the VPJobDesc is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPJobDesc1.Text == null ||
                this.VPJobDesc1.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPJobDesc1.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCGCCoLabel1()
                  {
                  
                    
        }
                
        public virtual void SetCGCJobLabel1()
                  {
                  
                    
        }
                
        public virtual void SetJobKeyLabel()
                  {
                  
                    
        }
                
        public virtual void SetMailAddress2Label()
                  {
                  
                    
        }
                
        public virtual void SetMailAddressLabel()
                  {
                  
                    
        }
                
        public virtual void SetMailCityLabel()
                  {
                  
                    
        }
                
        public virtual void SetMailStateLabel()
                  {
                  
                    
        }
                
        public virtual void SetMailZipLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOCLabel1()
                  {
                  
                    
        }
                
        public virtual void SetPOCNameLabel1()
                  {
                  
                    
        }
                
        public virtual void SetSalesPersonLabel1()
                  {
                  
                    
        }
                
        public virtual void SetSalesPersonNameLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVPCoLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVPCustomerLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVPCustomerNameLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVPJobDescLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVPJobLabel1()
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
        
            System.Web.UI.WebControls.Panel Panel = (System.Web.UI.WebControls.Panel)MiscUtils.FindControlRecursively(this, "MvwISDJobXrefRecordControlPanel");
            if ( (Panel != null && !Panel.Visible) || this.DataSource == null){
                return;
            }
          MvwISDJobPhaseXrefTableControlRow parentCtrl;
      				  
          parentCtrl = (MvwISDJobPhaseXrefTableControlRow)MiscUtils.GetParentControlObject(this, "MvwISDJobPhaseXrefTableControlRow");		  
              			
          if (parentCtrl != null && parentCtrl.DataSource == null) {
                // Load the record if it is not loaded yet.
                parentCtrl.LoadData();
            }
            if (parentCtrl == null || parentCtrl.DataSource == null) {
                // Get the error message from the application resource file.
                throw new Exception(Page.GetResourceValue("Err:NoParentRecId", "VPLookup"));
            }
            			
            this.DataSource.JobKey = parentCtrl.DataSource.JobKey;
            
          
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
        
            GetCGCCo2();
            GetCGCJob2();
            GetJobKey();
            GetMailAddress();
            GetMailAddress2();
            GetMailCity();
            GetMailState();
            GetMailZip();
            GetPOC2();
            GetPOCName2();
            GetSalesPerson2();
            GetSalesPersonName2();
            GetVPCo2();
            GetVPCustomer1();
            GetVPCustomerName2();
            GetVPJob1();
            GetVPJobDesc1();
        }
        
        
        public virtual void GetCGCCo2()
        {
            
        }
                
        public virtual void GetCGCJob2()
        {
            
        }
                
        public virtual void GetJobKey()
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
                
        public virtual void GetPOC2()
        {
            
        }
                
        public virtual void GetPOCName2()
        {
            
        }
                
        public virtual void GetSalesPerson2()
        {
            
        }
                
        public virtual void GetSalesPersonName2()
        {
            
        }
                
        public virtual void GetVPCo2()
        {
            
        }
                
        public virtual void GetVPCustomer1()
        {
            
        }
                
        public virtual void GetVPCustomerName2()
        {
            
        }
                
        public virtual void GetVPJob1()
        {
            
        }
                
        public virtual void GetVPJobDesc1()
        {
            
        }
                

      // To customize, override this method in MvwISDJobXrefRecordControl.
      
        public virtual WhereClause CreateWhereClause()
         
        {
//Bryan Check
    
            bool hasFiltersMvwISDJobPhaseXrefTableControl = false;
            hasFiltersMvwISDJobPhaseXrefTableControl = hasFiltersMvwISDJobPhaseXrefTableControl && false; // suppress warning
      
            bool hasFiltersMvwISDJobXrefRecordControl = false;
            hasFiltersMvwISDJobXrefRecordControl = hasFiltersMvwISDJobXrefRecordControl && false; // suppress warning
      
//
        
            WhereClause wc;
            MvwISDJobXrefView.Instance.InnerFilter = null;
            wc = new WhereClause();
            
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.

              
          KeyValue selectedRecordKeyValue = new KeyValue();
        
              KeyValue mvwISDJobPhaseXrefRecordObj = null;
              // make variable assignment here to avoid possible incorrect compiler warning
              KeyValue tmp = mvwISDJobPhaseXrefRecordObj;
              mvwISDJobPhaseXrefRecordObj = tmp;
            MvwISDJobPhaseXrefTableControlRow mvwISDJobPhaseXrefTableControlObjRow = (MiscUtils.GetParentControlObject(this, "MvwISDJobPhaseXrefTableControlRow") as MvwISDJobPhaseXrefTableControlRow);
              
                if (mvwISDJobPhaseXrefTableControlObjRow != null && mvwISDJobPhaseXrefTableControlObjRow.GetRecord() != null && mvwISDJobPhaseXrefTableControlObjRow.GetRecord().JobKey != null)
                {
                    wc.iAND(MvwISDJobXrefView.JobKey, BaseFilter.ComparisonOperator.EqualsTo, mvwISDJobPhaseXrefTableControlObjRow.GetRecord().JobKey.ToString());
                }
                else
                {
                    wc.RunQuery = false;
                    return wc;                    
                }
              
          HttpContext.Current.Session["MvwISDJobXrefRecordControlWhereClause"] = selectedRecordKeyValue.ToXmlString();
        
            return wc;
          
        }
        
        
        public virtual WhereClause CreateWhereClause(String searchText, String fromSearchControl, String AutoTypeAheadSearch, String AutoTypeAheadWordSeparators)
        {
            // This CreateWhereClause is used for loading list of suggestions for Auto Type-Ahead feature.
            MvwISDJobXrefView.Instance.InnerFilter = null;
            WhereClause wc= new WhereClause();
        
//Bryan Check
    
            bool hasFiltersMvwISDJobPhaseXrefTableControl = false;
            hasFiltersMvwISDJobPhaseXrefTableControl = hasFiltersMvwISDJobPhaseXrefTableControl && false; // suppress warning
      
            bool hasFiltersMvwISDJobXrefRecordControl = false;
            hasFiltersMvwISDJobXrefRecordControl = hasFiltersMvwISDJobXrefRecordControl && false; // suppress warning
      
//
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            String appRelativeVirtualPath = (String)HttpContext.Current.Session["AppRelativeVirtualPath"];
            
          string selectedRecordInMvwISDJobPhaseXrefTableControl = HttpContext.Current.Session["MvwISDJobXrefRecordControlWhereClause"] as string;
          
          if (selectedRecordInMvwISDJobPhaseXrefTableControl != null && KeyValue.IsXmlKey(selectedRecordInMvwISDJobPhaseXrefTableControl)) 
          {
              KeyValue selectedRecordKeyValue = KeyValue.XmlToKey(selectedRecordInMvwISDJobPhaseXrefTableControl);
            
              if (selectedRecordKeyValue != null && selectedRecordKeyValue.ContainsColumn(MvwISDJobXrefView.JobKey))
              {
                  wc.iAND(MvwISDJobXrefView.JobKey, BaseFilter.ComparisonOperator.EqualsTo, selectedRecordKeyValue.GetColumnValue(MvwISDJobXrefView.JobKey).ToString());
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
          MvwISDJobXrefView.DeleteRecord(pkValue);
          
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
                return (string)this.ViewState["BaseMvwISDJobXrefRecordControl_Rec"];
            }
            set {
                this.ViewState["BaseMvwISDJobXrefRecordControl_Rec"] = value;
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
        
        public System.Web.UI.WebControls.Literal CGCCo2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCo2");
            }
        }
            
        public System.Web.UI.WebControls.Literal CGCCoLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCoLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal CGCJob2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCJob2");
            }
        }
            
        public System.Web.UI.WebControls.Literal CGCJobLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCJobLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal JobKey {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobKey");
            }
        }
            
        public System.Web.UI.WebControls.Literal JobKeyLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobKeyLabel");
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
            
        public System.Web.UI.WebControls.Literal MailAddress2Label {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailAddress2Label");
            }
        }
        
        public System.Web.UI.WebControls.Literal MailAddressLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailAddressLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal MailCity {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailCity");
            }
        }
            
        public System.Web.UI.WebControls.Literal MailCityLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailCityLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal MailState {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailState");
            }
        }
            
        public System.Web.UI.WebControls.Literal MailStateLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailStateLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal MailZip {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailZip");
            }
        }
            
        public System.Web.UI.WebControls.Literal MailZipLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MailZipLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POC2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POC2");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal POCName2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCName2");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCNameLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCNameLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal SalesPerson2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPerson2");
            }
        }
            
        public System.Web.UI.WebControls.Literal SalesPersonLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal SalesPersonName2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonName2");
            }
        }
            
        public System.Web.UI.WebControls.Literal SalesPersonNameLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonNameLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPCo2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCo2");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCoLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCoLabel1");
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
        
        public System.Web.UI.WebControls.Literal VPCustomerName2 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerName2");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomerNameLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerNameLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPJob1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJob1");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPJobDesc1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobDesc1");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPJobDescLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobDescLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPJobLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobLabel1");
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

  