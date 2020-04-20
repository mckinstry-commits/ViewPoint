
// This file implements the TableControl, TableControlRow, and RecordControl classes for the 
// Show_POHD_Table.aspx page.  The Row or RecordControl classes are the 
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

        
using POViewer.Business;
using POViewer.Data;
using POViewer.UI;
using POViewer;
		

#endregion

  
namespace POViewer.UI.Controls.Show_POHD_Table
{
  

#region "Section 1: Place your customizations here."

    
public class POHDTableControlRow : BasePOHDTableControlRow
{
      
        // The BasePOHDTableControlRow implements code for a ROW within the
        // the POHDTableControl table.  The BasePOHDTableControlRow implements the DataBind and SaveData methods.
        // The loading of data is actually performed by the LoadData method in the base class of POHDTableControl.

        // This is the ideal place to add your code customizations. For example, you can override the DataBind, 
        // SaveData, GetUIData, and Validate methods.
        
}

  

public class POHDTableControl : BasePOHDTableControl
{
    // The BasePOHDTableControl class implements the LoadData, DataBind, CreateWhereClause
    // and other methods to load and display the data in a table control.

    // This is the ideal place to add your code customizations. You can override the LoadData and CreateWhereClause,
    // The POHDTableControlRow class offers another place where you can customize
    // the DataBind, GetUIData, SaveData and Validate methods specific to each row displayed on the table.

}

  

#endregion

  

#region "Section 2: Do not modify this section."
    
    
// Base class for the POHDTableControlRow control on the Show_POHD_Table page.
// Do not modify this class. Instead override any method in POHDTableControlRow.
public class BasePOHDTableControlRow : POViewer.UI.BaseApplicationRecordControl
{
        public BasePOHDTableControlRow()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        // To customize, override this method in POHDTableControlRow.
        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
                
            this.ClearControlsFromSession();
        }

        // To customize, override this method in POHDTableControlRow.
        protected virtual void Control_Load(object sender, System.EventArgs e)
        {      
                    
        
              // Register the event handlers.

          
        }

        public virtual void LoadData()  
        {
            // Load the data from the database into the DataSource DatabaseViewpoint%dbo.POHD record.
            // It is better to make changes to functions called by LoadData such as
            // CreateWhereClause, rather than making changes here.
            
        
            // Since this is a row in the table, the data for this row is loaded by the 
            // LoadData method of the BasePOHDTableControl when the data for the entire
            // table is loaded.
            
            this.DataSource = new POHDRecord();
            
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
          

            // Call the Set methods for each controls on the panel
        
                SetAddedBatchID();
                SetAddedMth();
                SetAddress();
                SetAddress2();
                SetApproved();
                SetApprovedBy();
                SetAttention();
                SetCity();
                SetCompGroup();
                SetCountry();
                SetDescription();
                SetDocType();
                SetExpDate();
                SetHoldCode();
                SetINCo();
                SetInUseBatchId();
                SetInUseMth();
                SetJCCo();
                SetJob();
                SetLoc();
                SetMthClosed();
                SetNotes();
                SetOrderDate();
                SetOrderedBy();
                SetPayAddressSeq();
                SetPayTerms();
                SetPO();
                SetPOAddressSeq();
                SetPOCloseBatchID();
                SetPOCo();
                SetPurge();
                SetShipIns();
                SetShipLoc();
                SetState();
                SetStatus();
                SetudAddressName();
                SetudCGCTable();
                SetudCGCTableID();
                SetudConv();
                SetudMCKPONumber();
                SetudOrderedBy();
                SetudPMSource();
                SetudPOFOB();
                SetudPRCo();
                SetudPurchaseContact();
                SetudShipMethod();
                SetudShipToJobYN();
                SetudSource();
                SetVendor();
                SetVendorGroup();
                SetZip();

      

            this.IsNewRecord = true;
          
            if (this.DataSource.IsCreated) {
                this.IsNewRecord = false;
              
            }
            

            // Now load data for each record and table child UI controls.
            // Ordering is important because child controls get 
            // their parent ids from their parent UI controls.
            bool shouldResetControl = false;
            if (shouldResetControl) { }; // prototype usage to void compiler warnings
            
        }
        
        
        public virtual void SetAddedBatchID()
        {
            
                    
            // Set the AddedBatchID Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.AddedBatchID is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AddedBatchIDSpecified) {
                								
                // If the AddedBatchID is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.AddedBatchID);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.AddedBatchID.Text = formattedValue;
                   
            } 
            
            else {
            
                // AddedBatchID is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.AddedBatchID.Text = POHDView.AddedBatchID.Format(POHDView.AddedBatchID.DefaultValue);
            		
            }
            
            // If the AddedBatchID is NULL or blank, then use the value specified  
            // on Properties.
            if (this.AddedBatchID.Text == null ||
                this.AddedBatchID.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.AddedBatchID.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetAddedMth()
        {
            
                    
            // Set the AddedMth Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.AddedMth is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AddedMthSpecified) {
                								
                // If the AddedMth is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.AddedMth, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.AddedMth.Text = formattedValue;
                   
            } 
            
            else {
            
                // AddedMth is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.AddedMth.Text = POHDView.AddedMth.Format(POHDView.AddedMth.DefaultValue, @"g");
            		
            }
            
            // If the AddedMth is NULL or blank, then use the value specified  
            // on Properties.
            if (this.AddedMth.Text == null ||
                this.AddedMth.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.AddedMth.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetAddress()
        {
            
                    
            // Set the Address Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Address is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AddressSpecified) {
                								
                // If the Address is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Address);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Address.Text = formattedValue;
                   
            } 
            
            else {
            
                // Address is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Address.Text = POHDView.Address.Format(POHDView.Address.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Address2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.Address2Specified) {
                								
                // If the Address2 is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Address2);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Address2.Text = formattedValue;
                   
            } 
            
            else {
            
                // Address2 is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Address2.Text = POHDView.Address2.Format(POHDView.Address2.DefaultValue);
            		
            }
            
            // If the Address2 is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Address2.Text == null ||
                this.Address2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Address2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetApproved()
        {
            
                    
            // Set the Approved Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Approved is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ApprovedSpecified) {
                								
                // If the Approved is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Approved);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Approved.Text = formattedValue;
                   
            } 
            
            else {
            
                // Approved is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Approved.Text = POHDView.Approved.Format(POHDView.Approved.DefaultValue);
            		
            }
            
            // If the Approved is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Approved.Text == null ||
                this.Approved.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Approved.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetApprovedBy()
        {
            
                    
            // Set the ApprovedBy Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.ApprovedBy is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ApprovedBySpecified) {
                								
                // If the ApprovedBy is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.ApprovedBy);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.ApprovedBy.Text = formattedValue;
                   
            } 
            
            else {
            
                // ApprovedBy is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.ApprovedBy.Text = POHDView.ApprovedBy.Format(POHDView.ApprovedBy.DefaultValue);
            		
            }
            
            // If the ApprovedBy is NULL or blank, then use the value specified  
            // on Properties.
            if (this.ApprovedBy.Text == null ||
                this.ApprovedBy.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.ApprovedBy.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetAttention()
        {
            
                    
            // Set the Attention Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Attention is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AttentionSpecified) {
                								
                // If the Attention is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Attention);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Attention.Text = formattedValue;
                   
            } 
            
            else {
            
                // Attention is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Attention.Text = POHDView.Attention.Format(POHDView.Attention.DefaultValue);
            		
            }
            
            // If the Attention is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Attention.Text == null ||
                this.Attention.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Attention.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCity()
        {
            
                    
            // Set the City Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.City is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CitySpecified) {
                								
                // If the City is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.City);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.City.Text = formattedValue;
                   
            } 
            
            else {
            
                // City is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.City.Text = POHDView.City.Format(POHDView.City.DefaultValue);
            		
            }
            
            // If the City is NULL or blank, then use the value specified  
            // on Properties.
            if (this.City.Text == null ||
                this.City.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.City.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCompGroup()
        {
            
                    
            // Set the CompGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.CompGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CompGroupSpecified) {
                								
                // If the CompGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.CompGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CompGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // CompGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CompGroup.Text = POHDView.CompGroup.Format(POHDView.CompGroup.DefaultValue);
            		
            }
            
            // If the CompGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CompGroup.Text == null ||
                this.CompGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CompGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCountry()
        {
            
                    
            // Set the Country Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Country is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CountrySpecified) {
                								
                // If the Country is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Country);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Country.Text = formattedValue;
                   
            } 
            
            else {
            
                // Country is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Country.Text = POHDView.Country.Format(POHDView.Country.DefaultValue);
            		
            }
            
            // If the Country is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Country.Text == null ||
                this.Country.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Country.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetDescription()
        {
            
                    
            // Set the Description Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Description is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.DescriptionSpecified) {
                								
                // If the Description is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Description);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Description.Text = formattedValue;
                   
            } 
            
            else {
            
                // Description is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Description.Text = POHDView.Description.Format(POHDView.Description.DefaultValue);
            		
            }
            
            // If the Description is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Description.Text == null ||
                this.Description.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Description.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetDocType()
        {
            
                    
            // Set the DocType Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.DocType is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.DocTypeSpecified) {
                								
                // If the DocType is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.DocType);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.DocType.Text = formattedValue;
                   
            } 
            
            else {
            
                // DocType is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.DocType.Text = POHDView.DocType.Format(POHDView.DocType.DefaultValue);
            		
            }
            
            // If the DocType is NULL or blank, then use the value specified  
            // on Properties.
            if (this.DocType.Text == null ||
                this.DocType.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.DocType.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetExpDate()
        {
            
                    
            // Set the ExpDate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.ExpDate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ExpDateSpecified) {
                								
                // If the ExpDate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.ExpDate, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.ExpDate.Text = formattedValue;
                   
            } 
            
            else {
            
                // ExpDate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.ExpDate.Text = POHDView.ExpDate.Format(POHDView.ExpDate.DefaultValue, @"g");
            		
            }
            
            // If the ExpDate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.ExpDate.Text == null ||
                this.ExpDate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.ExpDate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetHoldCode()
        {
            
                    
            // Set the HoldCode Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.HoldCode is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.HoldCodeSpecified) {
                								
                // If the HoldCode is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.HoldCode);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.HoldCode.Text = formattedValue;
                   
            } 
            
            else {
            
                // HoldCode is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.HoldCode.Text = POHDView.HoldCode.Format(POHDView.HoldCode.DefaultValue);
            		
            }
            
            // If the HoldCode is NULL or blank, then use the value specified  
            // on Properties.
            if (this.HoldCode.Text == null ||
                this.HoldCode.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.HoldCode.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetINCo()
        {
            
                    
            // Set the INCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.INCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.INCoSpecified) {
                								
                // If the INCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.INCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.INCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // INCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.INCo.Text = POHDView.INCo.Format(POHDView.INCo.DefaultValue);
            		
            }
            
            // If the INCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.INCo.Text == null ||
                this.INCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.INCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetInUseBatchId()
        {
            
                    
            // Set the InUseBatchId Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.InUseBatchId is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.InUseBatchIdSpecified) {
                								
                // If the InUseBatchId is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.InUseBatchId);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.InUseBatchId.Text = formattedValue;
                   
            } 
            
            else {
            
                // InUseBatchId is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.InUseBatchId.Text = POHDView.InUseBatchId.Format(POHDView.InUseBatchId.DefaultValue);
            		
            }
            
            // If the InUseBatchId is NULL or blank, then use the value specified  
            // on Properties.
            if (this.InUseBatchId.Text == null ||
                this.InUseBatchId.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.InUseBatchId.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetInUseMth()
        {
            
                    
            // Set the InUseMth Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.InUseMth is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.InUseMthSpecified) {
                								
                // If the InUseMth is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.InUseMth, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.InUseMth.Text = formattedValue;
                   
            } 
            
            else {
            
                // InUseMth is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.InUseMth.Text = POHDView.InUseMth.Format(POHDView.InUseMth.DefaultValue, @"g");
            		
            }
            
            // If the InUseMth is NULL or blank, then use the value specified  
            // on Properties.
            if (this.InUseMth.Text == null ||
                this.InUseMth.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.InUseMth.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJCCo()
        {
            
                    
            // Set the JCCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.JCCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JCCoSpecified) {
                								
                // If the JCCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.JCCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.JCCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // JCCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.JCCo.Text = POHDView.JCCo.Format(POHDView.JCCo.DefaultValue);
            		
            }
            
            // If the JCCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.JCCo.Text == null ||
                this.JCCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.JCCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJob()
        {
            
                    
            // Set the Job Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Job is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JobSpecified) {
                								
                // If the Job is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Job);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Job.Text = formattedValue;
                   
            } 
            
            else {
            
                // Job is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Job.Text = POHDView.Job.Format(POHDView.Job.DefaultValue);
            		
            }
            
            // If the Job is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Job.Text == null ||
                this.Job.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Job.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetLoc()
        {
            
                    
            // Set the Loc Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Loc is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.LocSpecified) {
                								
                // If the Loc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Loc);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Loc.Text = formattedValue;
                   
            } 
            
            else {
            
                // Loc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Loc.Text = POHDView.Loc.Format(POHDView.Loc.DefaultValue);
            		
            }
            
            // If the Loc is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Loc.Text == null ||
                this.Loc.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Loc.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMthClosed()
        {
            
                    
            // Set the MthClosed Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.MthClosed is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.MthClosedSpecified) {
                								
                // If the MthClosed is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.MthClosed, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.MthClosed.Text = formattedValue;
                   
            } 
            
            else {
            
                // MthClosed is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.MthClosed.Text = POHDView.MthClosed.Format(POHDView.MthClosed.DefaultValue, @"g");
            		
            }
            
            // If the MthClosed is NULL or blank, then use the value specified  
            // on Properties.
            if (this.MthClosed.Text == null ||
                this.MthClosed.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.MthClosed.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetNotes()
        {
            
                    
            // Set the Notes Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Notes is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.NotesSpecified) {
                								
                // If the Notes is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Notes);
                                
                if(formattedValue != null){
                    
                    int maxLength = formattedValue.Length;
                    if (maxLength >= (int)(300)){
                        // Truncate based on FieldMaxLength on Properties.
                        maxLength = (int)(300);
                        //First strip of all html tags:
                        formattedValue = StringUtils.ConvertHTMLToPlainText(formattedValue);
                      
                        formattedValue = HttpUtility.HtmlEncode(formattedValue); 
                      }
                  
                  if (maxLength == (int)(300)) {
                        formattedValue = NetUtils.EncodeStringForHtmlDisplay(formattedValue.Substring(0,Math.Min(maxLength, formattedValue.Length)));
                        formattedValue = formattedValue + "...";
                    }
                    else
                    {
                        formattedValue = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\"><tr><td>" + formattedValue + "</td></tr></table>";
                    }                   
                }                              
                
                this.Notes.Text = formattedValue;
                   
            } 
            
            else {
            
                // Notes is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Notes.Text = POHDView.Notes.Format(POHDView.Notes.DefaultValue);
            		
            }
            
            // If the Notes is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Notes.Text == null ||
                this.Notes.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Notes.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetOrderDate()
        {
            
                    
            // Set the OrderDate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.OrderDate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.OrderDateSpecified) {
                								
                // If the OrderDate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.OrderDate, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.OrderDate.Text = formattedValue;
                   
            } 
            
            else {
            
                // OrderDate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.OrderDate.Text = POHDView.OrderDate.Format(POHDView.OrderDate.DefaultValue, @"g");
            		
            }
            
            // If the OrderDate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.OrderDate.Text == null ||
                this.OrderDate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.OrderDate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetOrderedBy()
        {
            
                    
            // Set the OrderedBy Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.OrderedBy is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.OrderedBySpecified) {
                								
                // If the OrderedBy is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.OrderedBy);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.OrderedBy.Text = formattedValue;
                   
            } 
            
            else {
            
                // OrderedBy is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.OrderedBy.Text = POHDView.OrderedBy.Format(POHDView.OrderedBy.DefaultValue);
            		
            }
            
            // If the OrderedBy is NULL or blank, then use the value specified  
            // on Properties.
            if (this.OrderedBy.Text == null ||
                this.OrderedBy.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.OrderedBy.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPayAddressSeq()
        {
            
                    
            // Set the PayAddressSeq Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.PayAddressSeq is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PayAddressSeqSpecified) {
                								
                // If the PayAddressSeq is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.PayAddressSeq);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PayAddressSeq.Text = formattedValue;
                   
            } 
            
            else {
            
                // PayAddressSeq is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PayAddressSeq.Text = POHDView.PayAddressSeq.Format(POHDView.PayAddressSeq.DefaultValue);
            		
            }
            
            // If the PayAddressSeq is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PayAddressSeq.Text == null ||
                this.PayAddressSeq.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PayAddressSeq.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPayTerms()
        {
            
                    
            // Set the PayTerms Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.PayTerms is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PayTermsSpecified) {
                								
                // If the PayTerms is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.PayTerms);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PayTerms.Text = formattedValue;
                   
            } 
            
            else {
            
                // PayTerms is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PayTerms.Text = POHDView.PayTerms.Format(POHDView.PayTerms.DefaultValue);
            		
            }
            
            // If the PayTerms is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PayTerms.Text == null ||
                this.PayTerms.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PayTerms.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPO()
        {
            
                    
            // Set the PO Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.PO is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POSpecified) {
                								
                // If the PO is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.PO);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PO.Text = formattedValue;
                   
            } 
            
            else {
            
                // PO is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PO.Text = POHDView.PO.Format(POHDView.PO.DefaultValue);
            		
            }
            
            // If the PO is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PO.Text == null ||
                this.PO.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PO.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOAddressSeq()
        {
            
                    
            // Set the POAddressSeq Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.POAddressSeq is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POAddressSeqSpecified) {
                								
                // If the POAddressSeq is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.POAddressSeq);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POAddressSeq.Text = formattedValue;
                   
            } 
            
            else {
            
                // POAddressSeq is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POAddressSeq.Text = POHDView.POAddressSeq.Format(POHDView.POAddressSeq.DefaultValue);
            		
            }
            
            // If the POAddressSeq is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POAddressSeq.Text == null ||
                this.POAddressSeq.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POAddressSeq.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOCloseBatchID()
        {
            
                    
            // Set the POCloseBatchID Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.POCloseBatchID is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCloseBatchIDSpecified) {
                								
                // If the POCloseBatchID is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.POCloseBatchID);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POCloseBatchID.Text = formattedValue;
                   
            } 
            
            else {
            
                // POCloseBatchID is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POCloseBatchID.Text = POHDView.POCloseBatchID.Format(POHDView.POCloseBatchID.DefaultValue);
            		
            }
            
            // If the POCloseBatchID is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POCloseBatchID.Text == null ||
                this.POCloseBatchID.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POCloseBatchID.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOCo()
        {
            
                    
            // Set the POCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.POCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCoSpecified) {
                								
                // If the POCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.POCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // POCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POCo.Text = POHDView.POCo.Format(POHDView.POCo.DefaultValue);
            		
            }
            
            // If the POCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POCo.Text == null ||
                this.POCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPurge()
        {
            
                    
            // Set the Purge Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Purge is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PurgeSpecified) {
                								
                // If the Purge is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Purge);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Purge.Text = formattedValue;
                   
            } 
            
            else {
            
                // Purge is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Purge.Text = POHDView.Purge.Format(POHDView.Purge.DefaultValue);
            		
            }
            
            // If the Purge is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Purge.Text == null ||
                this.Purge.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Purge.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetShipIns()
        {
            
                    
            // Set the ShipIns Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.ShipIns is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ShipInsSpecified) {
                								
                // If the ShipIns is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.ShipIns);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.ShipIns.Text = formattedValue;
                   
            } 
            
            else {
            
                // ShipIns is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.ShipIns.Text = POHDView.ShipIns.Format(POHDView.ShipIns.DefaultValue);
            		
            }
            
            // If the ShipIns is NULL or blank, then use the value specified  
            // on Properties.
            if (this.ShipIns.Text == null ||
                this.ShipIns.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.ShipIns.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetShipLoc()
        {
            
                    
            // Set the ShipLoc Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.ShipLoc is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ShipLocSpecified) {
                								
                // If the ShipLoc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.ShipLoc);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.ShipLoc.Text = formattedValue;
                   
            } 
            
            else {
            
                // ShipLoc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.ShipLoc.Text = POHDView.ShipLoc.Format(POHDView.ShipLoc.DefaultValue);
            		
            }
            
            // If the ShipLoc is NULL or blank, then use the value specified  
            // on Properties.
            if (this.ShipLoc.Text == null ||
                this.ShipLoc.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.ShipLoc.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetState()
        {
            
                    
            // Set the State Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.State is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.StateSpecified) {
                								
                // If the State is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.State);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.State.Text = formattedValue;
                   
            } 
            
            else {
            
                // State is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.State.Text = POHDView.State.Format(POHDView.State.DefaultValue);
            		
            }
            
            // If the State is NULL or blank, then use the value specified  
            // on Properties.
            if (this.State.Text == null ||
                this.State.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.State.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetStatus()
        {
            
                    
            // Set the Status Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Status is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.StatusSpecified) {
                								
                // If the Status is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Status);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Status.Text = formattedValue;
                   
            } 
            
            else {
            
                // Status is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Status.Text = POHDView.Status.Format(POHDView.Status.DefaultValue);
            		
            }
            
            // If the Status is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Status.Text == null ||
                this.Status.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Status.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudAddressName()
        {
            
                    
            // Set the udAddressName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udAddressName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udAddressNameSpecified) {
                								
                // If the udAddressName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udAddressName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udAddressName.Text = formattedValue;
                   
            } 
            
            else {
            
                // udAddressName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udAddressName.Text = POHDView.udAddressName.Format(POHDView.udAddressName.DefaultValue);
            		
            }
            
            // If the udAddressName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udAddressName.Text == null ||
                this.udAddressName.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udAddressName.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudCGCTable()
        {
            
                    
            // Set the udCGCTable Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udCGCTable is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udCGCTableSpecified) {
                								
                // If the udCGCTable is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udCGCTable);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udCGCTable.Text = formattedValue;
                   
            } 
            
            else {
            
                // udCGCTable is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udCGCTable.Text = POHDView.udCGCTable.Format(POHDView.udCGCTable.DefaultValue);
            		
            }
            
            // If the udCGCTable is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udCGCTable.Text == null ||
                this.udCGCTable.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udCGCTable.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudCGCTableID()
        {
            
                    
            // Set the udCGCTableID Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udCGCTableID is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udCGCTableIDSpecified) {
                								
                // If the udCGCTableID is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udCGCTableID);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udCGCTableID.Text = formattedValue;
                   
            } 
            
            else {
            
                // udCGCTableID is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udCGCTableID.Text = POHDView.udCGCTableID.Format(POHDView.udCGCTableID.DefaultValue);
            		
            }
            
            // If the udCGCTableID is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udCGCTableID.Text == null ||
                this.udCGCTableID.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udCGCTableID.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudConv()
        {
            
                    
            // Set the udConv Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udConv is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udConvSpecified) {
                								
                // If the udConv is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udConv);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udConv.Text = formattedValue;
                   
            } 
            
            else {
            
                // udConv is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udConv.Text = POHDView.udConv.Format(POHDView.udConv.DefaultValue);
            		
            }
            
            // If the udConv is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udConv.Text == null ||
                this.udConv.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udConv.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudMCKPONumber()
        {
            
                    
            // Set the udMCKPONumber Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udMCKPONumber is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udMCKPONumberSpecified) {
                								
                // If the udMCKPONumber is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udMCKPONumber);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udMCKPONumber.Text = formattedValue;
                   
            } 
            
            else {
            
                // udMCKPONumber is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udMCKPONumber.Text = POHDView.udMCKPONumber.Format(POHDView.udMCKPONumber.DefaultValue);
            		
            }
            
            // If the udMCKPONumber is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udMCKPONumber.Text == null ||
                this.udMCKPONumber.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udMCKPONumber.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudOrderedBy()
        {
            
                    
            // Set the udOrderedBy Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udOrderedBy is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udOrderedBySpecified) {
                								
                // If the udOrderedBy is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udOrderedBy);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udOrderedBy.Text = formattedValue;
                   
            } 
            
            else {
            
                // udOrderedBy is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udOrderedBy.Text = POHDView.udOrderedBy.Format(POHDView.udOrderedBy.DefaultValue);
            		
            }
            
            // If the udOrderedBy is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udOrderedBy.Text == null ||
                this.udOrderedBy.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udOrderedBy.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudPMSource()
        {
            
                    
            // Set the udPMSource Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udPMSource is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udPMSourceSpecified) {
                								
                // If the udPMSource is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udPMSource);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udPMSource.Text = formattedValue;
                   
            } 
            
            else {
            
                // udPMSource is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udPMSource.Text = POHDView.udPMSource.Format(POHDView.udPMSource.DefaultValue);
            		
            }
            
            // If the udPMSource is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udPMSource.Text == null ||
                this.udPMSource.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udPMSource.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudPOFOB()
        {
            
                    
            // Set the udPOFOB Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udPOFOB is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udPOFOBSpecified) {
                								
                // If the udPOFOB is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udPOFOB);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udPOFOB.Text = formattedValue;
                   
            } 
            
            else {
            
                // udPOFOB is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udPOFOB.Text = POHDView.udPOFOB.Format(POHDView.udPOFOB.DefaultValue);
            		
            }
            
            // If the udPOFOB is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udPOFOB.Text == null ||
                this.udPOFOB.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udPOFOB.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudPRCo()
        {
            
                    
            // Set the udPRCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udPRCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udPRCoSpecified) {
                								
                // If the udPRCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udPRCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udPRCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // udPRCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udPRCo.Text = POHDView.udPRCo.Format(POHDView.udPRCo.DefaultValue);
            		
            }
            
            // If the udPRCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udPRCo.Text == null ||
                this.udPRCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udPRCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudPurchaseContact()
        {
            
                    
            // Set the udPurchaseContact Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udPurchaseContact is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udPurchaseContactSpecified) {
                								
                // If the udPurchaseContact is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udPurchaseContact);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udPurchaseContact.Text = formattedValue;
                   
            } 
            
            else {
            
                // udPurchaseContact is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udPurchaseContact.Text = POHDView.udPurchaseContact.Format(POHDView.udPurchaseContact.DefaultValue);
            		
            }
            
            // If the udPurchaseContact is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udPurchaseContact.Text == null ||
                this.udPurchaseContact.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udPurchaseContact.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudShipMethod()
        {
            
                    
            // Set the udShipMethod Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udShipMethod is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udShipMethodSpecified) {
                								
                // If the udShipMethod is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udShipMethod);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udShipMethod.Text = formattedValue;
                   
            } 
            
            else {
            
                // udShipMethod is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udShipMethod.Text = POHDView.udShipMethod.Format(POHDView.udShipMethod.DefaultValue);
            		
            }
            
            // If the udShipMethod is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udShipMethod.Text == null ||
                this.udShipMethod.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udShipMethod.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudShipToJobYN()
        {
            
                    
            // Set the udShipToJobYN Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udShipToJobYN is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udShipToJobYNSpecified) {
                								
                // If the udShipToJobYN is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udShipToJobYN);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udShipToJobYN.Text = formattedValue;
                   
            } 
            
            else {
            
                // udShipToJobYN is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udShipToJobYN.Text = POHDView.udShipToJobYN.Format(POHDView.udShipToJobYN.DefaultValue);
            		
            }
            
            // If the udShipToJobYN is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udShipToJobYN.Text == null ||
                this.udShipToJobYN.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udShipToJobYN.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudSource()
        {
            
                    
            // Set the udSource Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.udSource is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udSourceSpecified) {
                								
                // If the udSource is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.udSource);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udSource.Text = formattedValue;
                   
            } 
            
            else {
            
                // udSource is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udSource.Text = POHDView.udSource.Format(POHDView.udSource.DefaultValue);
            		
            }
            
            // If the udSource is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udSource.Text == null ||
                this.udSource.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udSource.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVendor()
        {
            
                    
            // Set the Vendor Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Vendor is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VendorSpecified) {
                								
                // If the Vendor is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Vendor);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Vendor.Text = formattedValue;
                   
            } 
            
            else {
            
                // Vendor is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Vendor.Text = POHDView.Vendor.Format(POHDView.Vendor.DefaultValue);
            		
            }
            
            // If the Vendor is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Vendor.Text == null ||
                this.Vendor.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Vendor.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVendorGroup()
        {
            
                    
            // Set the VendorGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.VendorGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VendorGroupSpecified) {
                								
                // If the VendorGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.VendorGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VendorGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // VendorGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VendorGroup.Text = POHDView.VendorGroup.Format(POHDView.VendorGroup.DefaultValue);
            		
            }
            
            // If the VendorGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VendorGroup.Text == null ||
                this.VendorGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VendorGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetZip()
        {
            
                    
            // Set the Zip Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POHD database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POHD record retrieved from the database.
            // this.Zip is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ZipSpecified) {
                								
                // If the Zip is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POHDView.Zip);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Zip.Text = formattedValue;
                   
            } 
            
            else {
            
                // Zip is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Zip.Text = POHDView.Zip.Format(POHDView.Zip.DefaultValue);
            		
            }
            
            // If the Zip is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Zip.Text == null ||
                this.Zip.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Zip.Text = "&nbsp;";
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
                ((POHDTableControl)MiscUtils.GetParentControlObject(this, "POHDTableControl")).DataChanged = true;
                ((POHDTableControl)MiscUtils.GetParentControlObject(this, "POHDTableControl")).ResetData = true;
            }
            
      
            // update session or cookie by formula
             		  
      
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            this.ResetData = true;
            
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
        
            GetAddedBatchID();
            GetAddedMth();
            GetAddress();
            GetAddress2();
            GetApproved();
            GetApprovedBy();
            GetAttention();
            GetCity();
            GetCompGroup();
            GetCountry();
            GetDescription();
            GetDocType();
            GetExpDate();
            GetHoldCode();
            GetINCo();
            GetInUseBatchId();
            GetInUseMth();
            GetJCCo();
            GetJob();
            GetLoc();
            GetMthClosed();
            GetNotes();
            GetOrderDate();
            GetOrderedBy();
            GetPayAddressSeq();
            GetPayTerms();
            GetPO();
            GetPOAddressSeq();
            GetPOCloseBatchID();
            GetPOCo();
            GetPurge();
            GetShipIns();
            GetShipLoc();
            GetState();
            GetStatus();
            GetudAddressName();
            GetudCGCTable();
            GetudCGCTableID();
            GetudConv();
            GetudMCKPONumber();
            GetudOrderedBy();
            GetudPMSource();
            GetudPOFOB();
            GetudPRCo();
            GetudPurchaseContact();
            GetudShipMethod();
            GetudShipToJobYN();
            GetudSource();
            GetVendor();
            GetVendorGroup();
            GetZip();
        }
        
        
        public virtual void GetAddedBatchID()
        {
            
        }
                
        public virtual void GetAddedMth()
        {
            
        }
                
        public virtual void GetAddress()
        {
            
        }
                
        public virtual void GetAddress2()
        {
            
        }
                
        public virtual void GetApproved()
        {
            
        }
                
        public virtual void GetApprovedBy()
        {
            
        }
                
        public virtual void GetAttention()
        {
            
        }
                
        public virtual void GetCity()
        {
            
        }
                
        public virtual void GetCompGroup()
        {
            
        }
                
        public virtual void GetCountry()
        {
            
        }
                
        public virtual void GetDescription()
        {
            
        }
                
        public virtual void GetDocType()
        {
            
        }
                
        public virtual void GetExpDate()
        {
            
        }
                
        public virtual void GetHoldCode()
        {
            
        }
                
        public virtual void GetINCo()
        {
            
        }
                
        public virtual void GetInUseBatchId()
        {
            
        }
                
        public virtual void GetInUseMth()
        {
            
        }
                
        public virtual void GetJCCo()
        {
            
        }
                
        public virtual void GetJob()
        {
            
        }
                
        public virtual void GetLoc()
        {
            
        }
                
        public virtual void GetMthClosed()
        {
            
        }
                
        public virtual void GetNotes()
        {
            
        }
                
        public virtual void GetOrderDate()
        {
            
        }
                
        public virtual void GetOrderedBy()
        {
            
        }
                
        public virtual void GetPayAddressSeq()
        {
            
        }
                
        public virtual void GetPayTerms()
        {
            
        }
                
        public virtual void GetPO()
        {
            
        }
                
        public virtual void GetPOAddressSeq()
        {
            
        }
                
        public virtual void GetPOCloseBatchID()
        {
            
        }
                
        public virtual void GetPOCo()
        {
            
        }
                
        public virtual void GetPurge()
        {
            
        }
                
        public virtual void GetShipIns()
        {
            
        }
                
        public virtual void GetShipLoc()
        {
            
        }
                
        public virtual void GetState()
        {
            
        }
                
        public virtual void GetStatus()
        {
            
        }
                
        public virtual void GetudAddressName()
        {
            
        }
                
        public virtual void GetudCGCTable()
        {
            
        }
                
        public virtual void GetudCGCTableID()
        {
            
        }
                
        public virtual void GetudConv()
        {
            
        }
                
        public virtual void GetudMCKPONumber()
        {
            
        }
                
        public virtual void GetudOrderedBy()
        {
            
        }
                
        public virtual void GetudPMSource()
        {
            
        }
                
        public virtual void GetudPOFOB()
        {
            
        }
                
        public virtual void GetudPRCo()
        {
            
        }
                
        public virtual void GetudPurchaseContact()
        {
            
        }
                
        public virtual void GetudShipMethod()
        {
            
        }
                
        public virtual void GetudShipToJobYN()
        {
            
        }
                
        public virtual void GetudSource()
        {
            
        }
                
        public virtual void GetVendor()
        {
            
        }
                
        public virtual void GetVendorGroup()
        {
            
        }
                
        public virtual void GetZip()
        {
            
        }
                

      // To customize, override this method in POHDTableControlRow.
      
        public virtual WhereClause CreateWhereClause()
         
        {
//Bryan Check
    
            bool hasFiltersPOHDTableControl = false;
            hasFiltersPOHDTableControl = hasFiltersPOHDTableControl && false; // suppress warning
      
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
        
  
        private Hashtable _PreviousUIData = new Hashtable();
        public virtual Hashtable PreviousUIData {
            get {
                return this._PreviousUIData;
            }
            set {
                this._PreviousUIData = value;
            }
        }
  

        
        public POHDRecord DataSource {
            get {
                return (POHDRecord)(this._DataSource);
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
        
        public System.Web.UI.WebControls.Literal AddedBatchID {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AddedBatchID");
            }
        }
            
        public System.Web.UI.WebControls.Literal AddedMth {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AddedMth");
            }
        }
            
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
            
        public System.Web.UI.WebControls.Literal Approved {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Approved");
            }
        }
            
        public System.Web.UI.WebControls.Literal ApprovedBy {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ApprovedBy");
            }
        }
            
        public System.Web.UI.WebControls.Literal Attention {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Attention");
            }
        }
            
        public System.Web.UI.WebControls.Literal City {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "City");
            }
        }
            
        public System.Web.UI.WebControls.Literal CompGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CompGroup");
            }
        }
            
        public System.Web.UI.WebControls.Literal Country {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Country");
            }
        }
            
        public System.Web.UI.WebControls.Literal Description {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Description");
            }
        }
            
        public System.Web.UI.WebControls.Literal DocType {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "DocType");
            }
        }
            
        public System.Web.UI.WebControls.Literal ExpDate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ExpDate");
            }
        }
            
        public System.Web.UI.WebControls.Literal HoldCode {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "HoldCode");
            }
        }
            
        public System.Web.UI.WebControls.Literal INCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "INCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal InUseBatchId {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InUseBatchId");
            }
        }
            
        public System.Web.UI.WebControls.Literal InUseMth {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InUseMth");
            }
        }
            
        public System.Web.UI.WebControls.Literal JCCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal Job {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Job");
            }
        }
            
        public System.Web.UI.WebControls.Literal Loc {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Loc");
            }
        }
            
        public System.Web.UI.WebControls.Literal MthClosed {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MthClosed");
            }
        }
            
        public System.Web.UI.WebControls.Literal Notes {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Notes");
            }
        }
            
        public System.Web.UI.WebControls.Literal OrderDate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrderDate");
            }
        }
            
        public System.Web.UI.WebControls.Literal OrderedBy {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrderedBy");
            }
        }
            
        public System.Web.UI.WebControls.Literal PayAddressSeq {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PayAddressSeq");
            }
        }
            
        public System.Web.UI.WebControls.Literal PayTerms {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PayTerms");
            }
        }
            
        public System.Web.UI.WebControls.Literal PO {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PO");
            }
        }
            
        public System.Web.UI.WebControls.Literal POAddressSeq {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POAddressSeq");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCloseBatchID {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCloseBatchID");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal Purge {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Purge");
            }
        }
            
        public System.Web.UI.WebControls.Literal ShipIns {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ShipIns");
            }
        }
            
        public System.Web.UI.WebControls.Literal ShipLoc {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ShipLoc");
            }
        }
            
        public System.Web.UI.WebControls.Literal State {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "State");
            }
        }
            
        public System.Web.UI.WebControls.Literal Status {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Status");
            }
        }
            
        public System.Web.UI.WebControls.Literal udAddressName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udAddressName");
            }
        }
            
        public System.Web.UI.WebControls.Literal udCGCTable {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udCGCTable");
            }
        }
            
        public System.Web.UI.WebControls.Literal udCGCTableID {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udCGCTableID");
            }
        }
            
        public System.Web.UI.WebControls.Literal udConv {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udConv");
            }
        }
            
        public System.Web.UI.WebControls.Literal udMCKPONumber {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udMCKPONumber");
            }
        }
            
        public System.Web.UI.WebControls.Literal udOrderedBy {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udOrderedBy");
            }
        }
            
        public System.Web.UI.WebControls.Literal udPMSource {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPMSource");
            }
        }
            
        public System.Web.UI.WebControls.Literal udPOFOB {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPOFOB");
            }
        }
            
        public System.Web.UI.WebControls.Literal udPRCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPRCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal udPurchaseContact {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPurchaseContact");
            }
        }
            
        public System.Web.UI.WebControls.Literal udShipMethod {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udShipMethod");
            }
        }
            
        public System.Web.UI.WebControls.Literal udShipToJobYN {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udShipToJobYN");
            }
        }
            
        public System.Web.UI.WebControls.Literal udSource {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udSource");
            }
        }
            
        public System.Web.UI.WebControls.Literal Vendor {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Vendor");
            }
        }
            
        public System.Web.UI.WebControls.Literal VendorGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VendorGroup");
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
    POHDRecord rec = null;
             
            try {
                rec = this.GetRecord();
            }
            catch (Exception ) {
                // Do Nothing
            }
            
            if (rec == null && url.IndexOf("{") >= 0) {
                // Localization.
                
                throw new Exception(Page.GetResourceValue("Err:RecDataSrcNotInitialized", "POViewer"));
                    
            }
        
            return EvaluateExpressions(url, arg, rec, bEncrypt);
        
    }


    public override string EvaluateExpressions(string url, string arg, bool bEncrypt,bool includeSession)
    {
    POHDRecord rec = null;
    
          try {
               rec = this.GetRecord();
          }
          catch (Exception ) {
          // Do Nothing
          }

          if (rec == null && url.IndexOf("{") >= 0) {
          // Localization.
    
              throw new Exception(Page.GetResourceValue("Err:RecDataSrcNotInitialized", "POViewer"));
      
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

    
        public virtual POHDRecord GetRecord()
             
        {
        
            if (this.DataSource != null) {
                return this.DataSource;
            }
            
            // Localization.
            
            throw new Exception(Page.GetResourceValue("Err:RetrieveRec", "POViewer"));
                
        }

        public new BaseApplicationPage Page
        {
            get {
                return ((BaseApplicationPage)base.Page);
            }
        }

#endregion

}

  
// Base class for the POHDTableControl control on the Show_POHD_Table page.
// Do not modify this class. Instead override any method in POHDTableControl.
public class BasePOHDTableControl : POViewer.UI.BaseApplicationTableControl
{
         

       public BasePOHDTableControl()
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
                if  (this.InSession(this.StatusFromFilter)) 				
                    initialVal = this.GetFromSession(this.StatusFromFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"StatusFrom\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    this.StatusFromFilter.Text = initialVal;
                            
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.StatusToFilter)) 				
                    initialVal = this.GetFromSession(this.StatusToFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"StatusTo\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    this.StatusToFilter.Text = initialVal;
                            
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
          
              this.AddedMthLabel.Click += AddedMthLabel_Click;
            
              this.Address2Label.Click += Address2Label_Click;
            
              this.AddressLabel.Click += AddressLabel_Click;
            
              this.CityLabel.Click += CityLabel_Click;
            
              this.CountryLabel.Click += CountryLabel_Click;
            
              this.ExpDateLabel.Click += ExpDateLabel_Click;
            
              this.ShipInsLabel.Click += ShipInsLabel_Click;
            
              this.StateLabel.Click += StateLabel_Click;
            
              this.udAddressNameLabel.Click += udAddressNameLabel_Click;
            
              this.ZipLabel.Click += ZipLabel_Click;
            
            // Setup the button events.
          
                    this.ExcelButton.Click += ExcelButton_Click;
                        
                    this.PDFButton.Click += PDFButton_Click;
                        
                    this.ResetButton.Click += ResetButton_Click;
                        
                    this.SearchButton.Click += SearchButton_Click;
                        
                    this.WordButton.Click += WordButton_Click;
                        
                    this.ActionsButton.Button.Click += ActionsButton_Click;
                        
                    this.FilterButton.Button.Click += FilterButton_Click;
                        
                    this.FiltersButton.Button.Click += FiltersButton_Click;
                                
        
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
                      Type myrec = typeof(POViewer.Business.POHDRecord);
                      this.DataSource = (POHDRecord[])(alist.ToArray(myrec));
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
                    foreach (POHDTableControlRow rc in this.GetRecordControls()) {
                        if (!rc.IsNewRecord) {
                            rc.DataSource = rc.GetRecord();
                            rc.GetUIData();
                            postdata.Add(rc.DataSource);
                            UIData.Add(rc.PreservedUIData());
                        }
                    }
                    Type myrec = typeof(POViewer.Business.POHDRecord);
                    this.DataSource = (POHDRecord[])(postdata.ToArray(myrec));
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
        
        public virtual POHDRecord[] GetRecords(BaseFilter join, WhereClause where, OrderBy orderBy, int pageIndex, int pageSize)
        {    
            // by default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               
    
            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecordCount as well
            // selCols.Add(POHDView.Column1, true);          
            // selCols.Add(POHDView.Column2, true);          
            // selCols.Add(POHDView.Column3, true);          
            

            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                  
            {
              
                return POHDView.GetRecords(join, where, orderBy, this.PageIndex, this.PageSize);
                 
            }
            else
            {
                POHDView databaseTable = new POHDView();
                databaseTable.SelectedColumns.Clear();
                databaseTable.SelectedColumns.AddRange(selCols);
                
                // Stored Procedures provided by Iron Speed Designer specifies to query all columns, in order to query a subset of columns, it is necessary to disable stored procedures
                databaseTable.DataAdapter.DisableStoredProcedures = true; 
                
            
                
                ArrayList recList; 
                orderBy.ExpandForeignKeyColums = false;
                recList = databaseTable.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
                return (recList.ToArray(typeof(POHDRecord)) as POHDRecord[]);
            }            
            
        }
        
        
        public virtual int GetRecordCount(BaseFilter join, WhereClause where)
        {

            // By default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               


            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecords as well
            // selCols.Add(POHDView.Column1, true);          
            // selCols.Add(POHDView.Column2, true);          
            // selCols.Add(POHDView.Column3, true);          


            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                     
            
                return POHDView.GetRecordCount(join, where);
            else
            {
                POHDView databaseTable = new POHDView();
                databaseTable.SelectedColumns.Clear();
                databaseTable.SelectedColumns.AddRange(selCols);        
                
                 // Stored Procedures provided by Iron Speed Designer specifies to query all columns, in order to query a subset of columns, it is necessary to disable stored procedures                  
                 databaseTable.DataAdapter.DisableStoredProcedures = true; 
                
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
        System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POHDTableControlRepeater"));
        if (rep == null){return;}
        rep.DataSource = this.DataSource;
        rep.DataBind();
          
        int index = 0;
        foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
        {
            // Loop through all rows in the table, set its DataSource and call DataBind().
            POHDTableControlRow recControl = (POHDTableControlRow)(repItem.FindControl("POHDTableControlRow"));
            recControl.DataSource = this.DataSource[index];            
            if (this.UIData.Count > index)
                recControl.PreviousUIData = this.UIData[index];
            recControl.DataBind();
            
           
            index++;
        }
           
    
            // Call the Set methods for each controls on the panel
        
                
                SetAddedBatchIDLabel();
                SetAddedMthLabel();
                SetAddress2Label();
                SetAddressLabel();
                SetApprovedByLabel();
                SetApprovedLabel();
                SetAttentionLabel();
                SetCityLabel();
                SetCompGroupLabel();
                SetCountryLabel();
                SetDescriptionLabel();
                SetDocTypeLabel();
                
                SetExpDateLabel();
                
                
                SetHoldCodeLabel();
                SetINCoLabel();
                SetInUseBatchIdLabel();
                SetInUseMthLabel();
                SetJCCoLabel();
                SetJobLabel();
                SetLocLabel();
                SetMthClosedLabel();
                SetNotesLabel();
                SetOrderDateLabel();
                SetOrderedByLabel();
                
                SetPayAddressSeqLabel();
                SetPayTermsLabel();
                
                SetPOAddressSeqLabel();
                SetPOCloseBatchIDLabel();
                SetPOCoLabel();
                SetPOLabel();
                SetPurgeLabel();
                
                
                SetSearchText();
                SetShipInsLabel();
                SetShipLocLabel();
                SetStateLabel();
                
                SetStatusLabel();
                SetStatusLabel1();
                
                
                
                SetudAddressNameLabel();
                SetudCGCTableIDLabel();
                SetudCGCTableLabel();
                SetudConvLabel();
                SetudMCKPONumberLabel();
                SetudOrderedByLabel();
                SetudPMSourceLabel();
                SetudPOFOBLabel();
                SetudPRCoLabel();
                SetudPurchaseContactLabel();
                SetudShipMethodLabel();
                SetudShipToJobYNLabel();
                SetudSourceLabel();
                SetVendorGroupLabel();
                SetVendorLabel();
                
                SetZipLabel();
                SetExcelButton();
              
                SetPDFButton();
              
                SetResetButton();
              
                SetSearchButton();
              
                SetWordButton();
              
                SetActionsButton();
              
                SetFilterButton();
              
                SetFiltersButton();
              
            // setting the state of expand or collapse alternative rows
      
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
          this.ExcelButton.Attributes.Add("onClick", "return (confirm('" + ((BaseApplicationPage)this.Page).GetResourceValue("ExportConfirm", "POViewer") + "'));");
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


            
            this.SearchText.Text = "";
            
            this.StatusFromFilter.Text = "";
            
            this.StatusToFilter.Text = "";
            
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
    
            // Bind the buttons for POHDTableControl pagination.
        
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
              
            foreach (POHDTableControlRow recCtl in this.GetRecordControls())
            {
        
                if (recCtl.Visible) {
                    recCtl.SaveData();
                }
          
            }

          
    
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            this.ResetData = true;
          
            // Set IsNewRecord to False for all records - since everything has been saved and is no longer "new"
            foreach (POHDTableControlRow recCtl in this.GetRecordControls()){
                recCtl.IsNewRecord = false;
            }
                
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
            POHDView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
    
            // CreateWhereClause() Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
        
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
        
      cols.Add(POHDView.udAddressName);
      
      foreach(BaseColumn col in cols)
      {
      
                    search.iOR(col, BaseFilter.ComparisonOperator.Contains, MiscUtils.GetSelectedValue(this.SearchText, this.GetFromSession(this.SearchText)), true, false);
        
      }
    
                    wc.iAND(search);
                  
                }
            }
                  

                          int totalSelectedItemCount = 0;
                          
            if (MiscUtils.IsValueSelected(this.StatusFromFilter)) {
                        
                //Check to see if the Byte value entered for the filter is valid.
                if (Convert.ToInt32(this.StatusFromFilter.Text) > 255) {
                    string errMssg = this.Page.GetResourceValue("Val:ValueTooLong", "POViewer");
                    errMssg = errMssg.Replace("{FieldName}", "StatusFromFilter");
                    BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this.StatusFromFilter, "BUTTON_CLICK_MESSAGE", errMssg);
                }
                            
                wc.iAND(POHDView.Status, BaseFilter.ComparisonOperator.Greater_Than_Or_Equal, MiscUtils.GetSelectedValue(this.StatusFromFilter, this.GetFromSession(this.StatusFromFilter)), false, false);
                    
            }
                      
            if (MiscUtils.IsValueSelected(this.StatusToFilter)) {
                        
                //Check to see if the Byte value entered for the filter is valid.
                if (Convert.ToInt32(this.StatusToFilter.Text) > 255) {
                    string errMssg = this.Page.GetResourceValue("Val:ValueTooLong", "POViewer");
                    errMssg = errMssg.Replace("{FieldName}", "StatusToFilter");
                    BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this.StatusToFilter, "BUTTON_CLICK_MESSAGE", errMssg);
                }
                            
                wc.iAND(POHDView.Status, BaseFilter.ComparisonOperator.Less_Than_Or_Equal, MiscUtils.GetSelectedValue(this.StatusToFilter, this.GetFromSession(this.StatusToFilter)), false, false);
                    
            }
                      
      if (totalSelectedItemCount > 50)
          throw new Exception(Page.GetResourceValue("Err:SelectedItemOverLimit", "POViewer").Replace("{Limit}", "50").Replace("{SelectedCount}", totalSelectedItemCount.ToString()));
    
            return wc;
        }
        
         
        public virtual WhereClause CreateWhereClause(String searchText, String fromSearchControl, String AutoTypeAheadSearch, String AutoTypeAheadWordSeparators)
        {
            // This CreateWhereClause is used for loading list of suggestions for Auto Type-Ahead feature.
            POHDView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
        
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
            String appRelativeVirtualPath = (String)HttpContext.Current.Session["AppRelativeVirtualPath"];
            
            // Adds clauses if values are selected in Filter controls which are configured in the page.
          
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
        
      cols.Add(POHDView.udAddressName);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Starts_With, formatedSearchText, true, false);
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, AutoTypeAheadWordSeparators + formatedSearchText, true, false);
                
      }
    
                    } else {
                        
      ColumnList cols = new ColumnList();    
        
      cols.Add(POHDView.udAddressName);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, formatedSearchText, true, false);
      }
    
                    } 
                    wc.iAND(search);
                  
                }
            }
                  
      String StatusFromFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "StatusFromFilter_Ajax"];
            if (MiscUtils.IsValueSelected(StatusFromFilterSelectedValue)) {

              
                wc.iAND(POHDView.Status, BaseFilter.ComparisonOperator.Greater_Than_Or_Equal, StatusFromFilterSelectedValue, false, false);
                      
      }
                      
      String StatusToFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "StatusToFilter_Ajax"];
            if (MiscUtils.IsValueSelected(StatusToFilterSelectedValue)) {

              
                wc.iAND(POHDView.Status, BaseFilter.ComparisonOperator.Less_Than_Or_Equal, StatusToFilterSelectedValue, false, false);
                      
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
            POViewer.Business.POHDRecord[] recordList  = POHDView.GetRecords(filterJoin, wc, null, 0, count, ref count);
            String resultItem = "";
            if (resultItem == "") resultItem = "";
            foreach (POHDRecord rec in recordList ){
                // Exit the loop if recordList count has reached AutoTypeAheadListSize.
                if (resultList.Count >= count) {
                    break;
                }
                // If the field is configured to Display as Foreign key, Format() method returns the 
                // Display as Forien Key value instead of original field value.
                // Since search had to be done in multiple fields (selected in Control's page property, binding tab) in a record,
                // We need to find relevent field to display which matches the prefixText and is not already present in the result list.
        
                resultItem = rec.Format(POHDView.udAddressName);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(POHDView.udAddressName.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, POHDView.udAddressName.IsFullTextSearchable);
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
    System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POHDTableControlRepeater"));
    if (rep == null){return;}

    foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
    {
    // Loop through all rows in the table, set its DataSource and call DataBind().
    POHDTableControlRow recControl = (POHDTableControlRow)(repItem.FindControl("POHDTableControlRow"));

      if (recControl.Visible && recControl.IsNewRecord) {
      POHDRecord rec = new POHDRecord();
        
                        if (recControl.AddedBatchID.Text != "") {
                            rec.Parse(recControl.AddedBatchID.Text, POHDView.AddedBatchID);
                  }
                
                        if (recControl.AddedMth.Text != "") {
                            rec.Parse(recControl.AddedMth.Text, POHDView.AddedMth);
                  }
                
                        if (recControl.Address.Text != "") {
                            rec.Parse(recControl.Address.Text, POHDView.Address);
                  }
                
                        if (recControl.Address2.Text != "") {
                            rec.Parse(recControl.Address2.Text, POHDView.Address2);
                  }
                
                        if (recControl.Approved.Text != "") {
                            rec.Parse(recControl.Approved.Text, POHDView.Approved);
                  }
                
                        if (recControl.ApprovedBy.Text != "") {
                            rec.Parse(recControl.ApprovedBy.Text, POHDView.ApprovedBy);
                  }
                
                        if (recControl.Attention.Text != "") {
                            rec.Parse(recControl.Attention.Text, POHDView.Attention);
                  }
                
                        if (recControl.City.Text != "") {
                            rec.Parse(recControl.City.Text, POHDView.City);
                  }
                
                        if (recControl.CompGroup.Text != "") {
                            rec.Parse(recControl.CompGroup.Text, POHDView.CompGroup);
                  }
                
                        if (recControl.Country.Text != "") {
                            rec.Parse(recControl.Country.Text, POHDView.Country);
                  }
                
                        if (recControl.Description.Text != "") {
                            rec.Parse(recControl.Description.Text, POHDView.Description);
                  }
                
                        if (recControl.DocType.Text != "") {
                            rec.Parse(recControl.DocType.Text, POHDView.DocType);
                  }
                
                        if (recControl.ExpDate.Text != "") {
                            rec.Parse(recControl.ExpDate.Text, POHDView.ExpDate);
                  }
                
                        if (recControl.HoldCode.Text != "") {
                            rec.Parse(recControl.HoldCode.Text, POHDView.HoldCode);
                  }
                
                        if (recControl.INCo.Text != "") {
                            rec.Parse(recControl.INCo.Text, POHDView.INCo);
                  }
                
                        if (recControl.InUseBatchId.Text != "") {
                            rec.Parse(recControl.InUseBatchId.Text, POHDView.InUseBatchId);
                  }
                
                        if (recControl.InUseMth.Text != "") {
                            rec.Parse(recControl.InUseMth.Text, POHDView.InUseMth);
                  }
                
                        if (recControl.JCCo.Text != "") {
                            rec.Parse(recControl.JCCo.Text, POHDView.JCCo);
                  }
                
                        if (recControl.Job.Text != "") {
                            rec.Parse(recControl.Job.Text, POHDView.Job);
                  }
                
                        if (recControl.Loc.Text != "") {
                            rec.Parse(recControl.Loc.Text, POHDView.Loc);
                  }
                
                        if (recControl.MthClosed.Text != "") {
                            rec.Parse(recControl.MthClosed.Text, POHDView.MthClosed);
                  }
                
                        if (recControl.Notes.Text != "") {
                            rec.Parse(recControl.Notes.Text, POHDView.Notes);
                  }
                
                        if (recControl.OrderDate.Text != "") {
                            rec.Parse(recControl.OrderDate.Text, POHDView.OrderDate);
                  }
                
                        if (recControl.OrderedBy.Text != "") {
                            rec.Parse(recControl.OrderedBy.Text, POHDView.OrderedBy);
                  }
                
                        if (recControl.PayAddressSeq.Text != "") {
                            rec.Parse(recControl.PayAddressSeq.Text, POHDView.PayAddressSeq);
                  }
                
                        if (recControl.PayTerms.Text != "") {
                            rec.Parse(recControl.PayTerms.Text, POHDView.PayTerms);
                  }
                
                        if (recControl.PO.Text != "") {
                            rec.Parse(recControl.PO.Text, POHDView.PO);
                  }
                
                        if (recControl.POAddressSeq.Text != "") {
                            rec.Parse(recControl.POAddressSeq.Text, POHDView.POAddressSeq);
                  }
                
                        if (recControl.POCloseBatchID.Text != "") {
                            rec.Parse(recControl.POCloseBatchID.Text, POHDView.POCloseBatchID);
                  }
                
                        if (recControl.POCo.Text != "") {
                            rec.Parse(recControl.POCo.Text, POHDView.POCo);
                  }
                
                        if (recControl.Purge.Text != "") {
                            rec.Parse(recControl.Purge.Text, POHDView.Purge);
                  }
                
                        if (recControl.ShipIns.Text != "") {
                            rec.Parse(recControl.ShipIns.Text, POHDView.ShipIns);
                  }
                
                        if (recControl.ShipLoc.Text != "") {
                            rec.Parse(recControl.ShipLoc.Text, POHDView.ShipLoc);
                  }
                
                        if (recControl.State.Text != "") {
                            rec.Parse(recControl.State.Text, POHDView.State);
                  }
                
                        if (recControl.Status.Text != "") {
                            rec.Parse(recControl.Status.Text, POHDView.Status);
                  }
                
                        if (recControl.udAddressName.Text != "") {
                            rec.Parse(recControl.udAddressName.Text, POHDView.udAddressName);
                  }
                
                        if (recControl.udCGCTable.Text != "") {
                            rec.Parse(recControl.udCGCTable.Text, POHDView.udCGCTable);
                  }
                
                        if (recControl.udCGCTableID.Text != "") {
                            rec.Parse(recControl.udCGCTableID.Text, POHDView.udCGCTableID);
                  }
                
                        if (recControl.udConv.Text != "") {
                            rec.Parse(recControl.udConv.Text, POHDView.udConv);
                  }
                
                        if (recControl.udMCKPONumber.Text != "") {
                            rec.Parse(recControl.udMCKPONumber.Text, POHDView.udMCKPONumber);
                  }
                
                        if (recControl.udOrderedBy.Text != "") {
                            rec.Parse(recControl.udOrderedBy.Text, POHDView.udOrderedBy);
                  }
                
                        if (recControl.udPMSource.Text != "") {
                            rec.Parse(recControl.udPMSource.Text, POHDView.udPMSource);
                  }
                
                        if (recControl.udPOFOB.Text != "") {
                            rec.Parse(recControl.udPOFOB.Text, POHDView.udPOFOB);
                  }
                
                        if (recControl.udPRCo.Text != "") {
                            rec.Parse(recControl.udPRCo.Text, POHDView.udPRCo);
                  }
                
                        if (recControl.udPurchaseContact.Text != "") {
                            rec.Parse(recControl.udPurchaseContact.Text, POHDView.udPurchaseContact);
                  }
                
                        if (recControl.udShipMethod.Text != "") {
                            rec.Parse(recControl.udShipMethod.Text, POHDView.udShipMethod);
                  }
                
                        if (recControl.udShipToJobYN.Text != "") {
                            rec.Parse(recControl.udShipToJobYN.Text, POHDView.udShipToJobYN);
                  }
                
                        if (recControl.udSource.Text != "") {
                            rec.Parse(recControl.udSource.Text, POHDView.udSource);
                  }
                
                        if (recControl.Vendor.Text != "") {
                            rec.Parse(recControl.Vendor.Text, POHDView.Vendor);
                  }
                
                        if (recControl.VendorGroup.Text != "") {
                            rec.Parse(recControl.VendorGroup.Text, POHDView.VendorGroup);
                  }
                
                        if (recControl.Zip.Text != "") {
                            rec.Parse(recControl.Zip.Text, POHDView.Zip);
                  }
                
      newUIDataList.Add(recControl.PreservedUIData());
      newRecordList.Add(rec);
      }
      }
      }
    
            // Add any new record to the list.
            for (int count = 1; count <= this.AddNewRecord; count++) {
              
                newRecordList.Insert(0, new POHDRecord());
                newUIDataList.Insert(0, new Hashtable());
              
            }
            this.AddNewRecord = 0;

            // Finally, add any new records to the DataSource.
            if (newRecordList.Count > 0) {
              
                ArrayList finalList = new ArrayList(this.DataSource);
                finalList.InsertRange(0, newRecordList);

                Type myrec = typeof(POViewer.Business.POHDRecord);
                this.DataSource = (POHDRecord[])(finalList.ToArray(myrec));
              
            }
            
            // Add the existing UI data to this hash table
            if (newUIDataList.Count > 0)
                this.UIData.InsertRange(0, newUIDataList);
        }

        
      
        // Create Set, WhereClause, and Populate Methods
        
        public virtual void SetAddedBatchIDLabel()
                  {
                  
                    
        }
                
        public virtual void SetAddedMthLabel()
                  {
                  
                    
        }
                
        public virtual void SetAddress2Label()
                  {
                  
                    
        }
                
        public virtual void SetAddressLabel()
                  {
                  
                    
        }
                
        public virtual void SetApprovedByLabel()
                  {
                  
                    
        }
                
        public virtual void SetApprovedLabel()
                  {
                  
                    
        }
                
        public virtual void SetAttentionLabel()
                  {
                  
                    
        }
                
        public virtual void SetCityLabel()
                  {
                  
                    
        }
                
        public virtual void SetCompGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetCountryLabel()
                  {
                  
                    
        }
                
        public virtual void SetDescriptionLabel()
                  {
                  
                    
        }
                
        public virtual void SetDocTypeLabel()
                  {
                  
                    
        }
                
        public virtual void SetExpDateLabel()
                  {
                  
                    
        }
                
        public virtual void SetHoldCodeLabel()
                  {
                  
                    
        }
                
        public virtual void SetINCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetInUseBatchIdLabel()
                  {
                  
                    
        }
                
        public virtual void SetInUseMthLabel()
                  {
                  
                    
        }
                
        public virtual void SetJCCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetJobLabel()
                  {
                  
                    
        }
                
        public virtual void SetLocLabel()
                  {
                  
                    
        }
                
        public virtual void SetMthClosedLabel()
                  {
                  
                    
        }
                
        public virtual void SetNotesLabel()
                  {
                  
                    
        }
                
        public virtual void SetOrderDateLabel()
                  {
                  
                    
        }
                
        public virtual void SetOrderedByLabel()
                  {
                  
                    
        }
                
        public virtual void SetPayAddressSeqLabel()
                  {
                  
                    
        }
                
        public virtual void SetPayTermsLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOAddressSeqLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOCloseBatchIDLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOLabel()
                  {
                  
                    
        }
                
        public virtual void SetPurgeLabel()
                  {
                  
                    
        }
                
        public virtual void SetShipInsLabel()
                  {
                  
                    
        }
                
        public virtual void SetShipLocLabel()
                  {
                  
                    
        }
                
        public virtual void SetStateLabel()
                  {
                  
                    
        }
                
        public virtual void SetStatusLabel()
                  {
                  
                    
        }
                
        public virtual void SetStatusLabel1()
                  {
                  
                    
        }
                
        public virtual void SetudAddressNameLabel()
                  {
                  
                    
        }
                
        public virtual void SetudCGCTableIDLabel()
                  {
                  
                    
        }
                
        public virtual void SetudCGCTableLabel()
                  {
                  
                    
        }
                
        public virtual void SetudConvLabel()
                  {
                  
                    
        }
                
        public virtual void SetudMCKPONumberLabel()
                  {
                  
                    
        }
                
        public virtual void SetudOrderedByLabel()
                  {
                  
                    
        }
                
        public virtual void SetudPMSourceLabel()
                  {
                  
                    
        }
                
        public virtual void SetudPOFOBLabel()
                  {
                  
                    
        }
                
        public virtual void SetudPRCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetudPurchaseContactLabel()
                  {
                  
                    
        }
                
        public virtual void SetudShipMethodLabel()
                  {
                  
                    
        }
                
        public virtual void SetudShipToJobYNLabel()
                  {
                  
                    
        }
                
        public virtual void SetudSourceLabel()
                  {
                  
                    
        }
                
        public virtual void SetVendorGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetVendorLabel()
                  {
                  
                    
        }
                
        public virtual void SetZipLabel()
                  {
                  
                    
        }
                
        public virtual void SetSearchText()
        {
                                            
            this.SearchText.Attributes.Add("onfocus", "if(this.value=='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "') {this.value='';this.className='Search_Input';}");
            this.SearchText.Attributes.Add("onblur", "if(this.value=='') {this.value='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "';this.className='Search_InputHint';}");
                                   
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
        
            this.SaveToSession(this.SearchText, this.SearchText.Text);
                  
            this.SaveToSession(this.StatusFromFilter, this.StatusFromFilter.Text);
                  
            this.SaveToSession(this.StatusToFilter, this.StatusToFilter.Text);
                  
            
                    
            // Save pagination state to session.
         
    
            // Save table control properties to the session.
          
            if (this.CurrentSortOrder != null) {
                this.SaveToSession(this, "Order_By", this.CurrentSortOrder.ToXmlString());
            }
          
            this.SaveToSession(this, "Page_Index", this.PageIndex.ToString());
            this.SaveToSession(this, "Page_Size", this.PageSize.ToString());
          
        }
        
        
        protected  void SaveControlsToSession_Ajax()
        {
            // Save filter controls to values to session.
          
      this.SaveToSession("SearchText_Ajax", this.SearchText.Text);
              
      this.SaveToSession("StatusFromFilter_Ajax", this.StatusFromFilter.Text);
              
      this.SaveToSession("StatusToFilter_Ajax", this.StatusToFilter.Text);
              
           HttpContext.Current.Session["AppRelativeVirtualPath"] = this.Page.AppRelativeVirtualPath;
         
        }
        
        
        protected override void ClearControlsFromSession()
        {
            base.ClearControlsFromSession();
            // Clear filter controls values from the session.
        
            this.RemoveFromSession(this.SearchText);
            this.RemoveFromSession(this.StatusFromFilter);
            this.RemoveFromSession(this.StatusToFilter);
            
            // Clear pagination state from session.
         

    // Clear table properties from the session.
    this.RemoveFromSession(this, "Order_By");
    this.RemoveFromSession(this, "Page_Index");
    this.RemoveFromSession(this, "Page_Size");
    
        }

        protected override void LoadViewState(object savedState)
        {
            base.LoadViewState(savedState);

            string orderByStr = (string)ViewState["POHDTableControl_OrderBy"];
          
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
    
        }

        protected override object SaveViewState()
        {            
          
            if (this.CurrentSortOrder != null) {
                this.ViewState["POHDTableControl_OrderBy"] = this.CurrentSortOrder.ToXmlString();
            }
          

    this.ViewState["Page_Index"] = this.PageIndex;
    this.ViewState["Page_Size"] = this.PageSize;
    
    
            // Load view state for pagination control.
              
            return (base.SaveViewState());
        }

        // Generate set method for buttons
        
        public virtual void SetExcelButton()                
              
        {
        
   
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
    
      
            if (MiscUtils.IsValueSelected(StatusFromFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
            if (MiscUtils.IsValueSelected(StatusToFilter))
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
        
        public virtual void AddedMthLabel_Click(object sender, EventArgs args)
        {
            //Sorts by AddedMth when clicked.
              
            // Get previous sorting state for AddedMth.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.AddedMth);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for AddedMth.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.AddedMth, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by AddedMth, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void Address2Label_Click(object sender, EventArgs args)
        {
            //Sorts by Address2 when clicked.
              
            // Get previous sorting state for Address2.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.Address2);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for Address2.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.Address2, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by Address2, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void AddressLabel_Click(object sender, EventArgs args)
        {
            //Sorts by Address when clicked.
              
            // Get previous sorting state for Address.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.Address);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for Address.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.Address, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by Address, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void CityLabel_Click(object sender, EventArgs args)
        {
            //Sorts by City when clicked.
              
            // Get previous sorting state for City.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.City);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for City.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.City, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by City, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void CountryLabel_Click(object sender, EventArgs args)
        {
            //Sorts by Country when clicked.
              
            // Get previous sorting state for Country.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.Country);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for Country.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.Country, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by Country, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void ExpDateLabel_Click(object sender, EventArgs args)
        {
            //Sorts by ExpDate when clicked.
              
            // Get previous sorting state for ExpDate.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.ExpDate);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for ExpDate.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.ExpDate, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by ExpDate, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void ShipInsLabel_Click(object sender, EventArgs args)
        {
            //Sorts by ShipIns when clicked.
              
            // Get previous sorting state for ShipIns.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.ShipIns);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for ShipIns.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.ShipIns, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by ShipIns, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void StateLabel_Click(object sender, EventArgs args)
        {
            //Sorts by State when clicked.
              
            // Get previous sorting state for State.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.State);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for State.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.State, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by State, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void udAddressNameLabel_Click(object sender, EventArgs args)
        {
            //Sorts by udAddressName when clicked.
              
            // Get previous sorting state for udAddressName.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.udAddressName);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for udAddressName.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.udAddressName, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by udAddressName, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void ZipLabel_Click(object sender, EventArgs args)
        {
            //Sorts by Zip when clicked.
              
            // Get previous sorting state for Zip.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POHDView.Zip);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for Zip.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POHDView.Zip, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by Zip, so just reverse.
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


              this.TotalRecords = POHDView.GetRecordCount(join, wc);
              if (this.TotalRecords > 10000)
              {
              
                // Add each of the columns in order of export.
                BaseColumn[] columns = new BaseColumn[] {
                             POHDView.POCo,
             POHDView.PO,
             POHDView.VendorGroup,
             POHDView.Vendor,
             POHDView.Description,
             POHDView.OrderDate,
             POHDView.OrderedBy,
             POHDView.ExpDate,
             POHDView.Status,
             POHDView.JCCo,
             POHDView.Job,
             POHDView.INCo,
             POHDView.Loc,
             POHDView.ShipLoc,
             POHDView.Address,
             POHDView.City,
             POHDView.State,
             POHDView.Zip,
             POHDView.ShipIns,
             POHDView.HoldCode,
             POHDView.PayTerms,
             POHDView.CompGroup,
             POHDView.MthClosed,
             POHDView.InUseMth,
             POHDView.InUseBatchId,
             POHDView.Approved,
             POHDView.ApprovedBy,
             POHDView.Purge,
             POHDView.Notes,
             POHDView.AddedMth,
             POHDView.AddedBatchID,
             POHDView.Attention,
             POHDView.PayAddressSeq,
             POHDView.POAddressSeq,
             POHDView.Address2,
             POHDView.Country,
             POHDView.POCloseBatchID,
             POHDView.udSource,
             POHDView.udConv,
             POHDView.udCGCTable,
             POHDView.udCGCTableID,
             POHDView.udOrderedBy,
             POHDView.DocType,
             POHDView.udMCKPONumber,
             POHDView.udShipToJobYN,
             POHDView.udPRCo,
             POHDView.udAddressName,
             POHDView.udPOFOB,
             POHDView.udShipMethod,
             POHDView.udPurchaseContact,
             POHDView.udPMSource,
             null};
                ExportDataToCSV exportData = new ExportDataToCSV(POHDView.Instance,wc,orderBy,columns);
                exportData.StartExport(this.Page.Response, true);

                DataForExport dataForCSV = new DataForExport(POHDView.Instance, wc, orderBy, columns,join);

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
              ExportDataToExcel excelReport = new ExportDataToExcel(POHDView.Instance, wc, orderBy);
              // Add each of the columns in order of export.
              // To customize the data type, change the second parameter of the new ExcelColumn to be
              // a format string from Excel's Format Cell menu. For example "dddd, mmmm dd, yyyy h:mm AM/PM;@", "#,##0.00"

              if (this.Page.Response == null)
              return;

              excelReport.CreateExcelBook();

              int width = 0;
              int columnCounter = 0;
              DataForExport data = new DataForExport(POHDView.Instance, wc, orderBy, null,join);
                           data.ColumnList.Add(new ExcelColumn(POHDView.POCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.PO, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.VendorGroup, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Vendor, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Description, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.OrderDate, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POHDView.OrderedBy, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.ExpDate, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Status, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.JCCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Job, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.INCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Loc, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.ShipLoc, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Address, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.City, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.State, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Zip, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.ShipIns, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.HoldCode, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.PayTerms, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.CompGroup, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.MthClosed, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POHDView.InUseMth, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POHDView.InUseBatchId, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Approved, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.ApprovedBy, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Purge, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Notes, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.AddedMth, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POHDView.AddedBatchID, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Attention, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.PayAddressSeq, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.POAddressSeq, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Address2, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.Country, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.POCloseBatchID, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udSource, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udConv, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udCGCTable, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udCGCTableID, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udOrderedBy, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.DocType, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udMCKPONumber, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udShipToJobYN, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udPRCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udAddressName, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udPOFOB, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udShipMethod, "Default"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udPurchaseContact, "0"));
             data.ColumnList.Add(new ExcelColumn(POHDView.udPMSource, "0"));


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
                val = POHDView.GetDFKA(rec.GetValue(col.DisplayColumn).ToString(), col.DisplayColumn, null) as string;
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
        public virtual void PDFButton_Click(object sender, ImageClickEventArgs args)
        {
              
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                

                PDFReport report = new PDFReport();

                report.SpecificReportFileName = Page.Server.MapPath("Show-POHD-Table.PDFButton.report");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "POHD";
                // If Show-POHD-Table.PDFButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.   
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(POHDView.POCo.Name, ReportEnum.Align.Right, "${POCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.PO.Name, ReportEnum.Align.Left, "${PO}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.VendorGroup.Name, ReportEnum.Align.Right, "${VendorGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Vendor.Name, ReportEnum.Align.Right, "${Vendor}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Description.Name, ReportEnum.Align.Left, "${Description}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.OrderDate.Name, ReportEnum.Align.Left, "${OrderDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.OrderedBy.Name, ReportEnum.Align.Left, "${OrderedBy}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.ExpDate.Name, ReportEnum.Align.Left, "${ExpDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.Status.Name, ReportEnum.Align.Right, "${Status}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.JCCo.Name, ReportEnum.Align.Right, "${JCCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Job.Name, ReportEnum.Align.Left, "${Job}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.INCo.Name, ReportEnum.Align.Right, "${INCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Loc.Name, ReportEnum.Align.Left, "${Loc}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.ShipLoc.Name, ReportEnum.Align.Left, "${ShipLoc}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.Address.Name, ReportEnum.Align.Left, "${Address}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.City.Name, ReportEnum.Align.Left, "${City}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.State.Name, ReportEnum.Align.Left, "${State}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.Zip.Name, ReportEnum.Align.Left, "${Zip}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.ShipIns.Name, ReportEnum.Align.Left, "${ShipIns}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.HoldCode.Name, ReportEnum.Align.Left, "${HoldCode}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.PayTerms.Name, ReportEnum.Align.Left, "${PayTerms}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.CompGroup.Name, ReportEnum.Align.Left, "${CompGroup}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.MthClosed.Name, ReportEnum.Align.Left, "${MthClosed}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.InUseMth.Name, ReportEnum.Align.Left, "${InUseMth}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.InUseBatchId.Name, ReportEnum.Align.Right, "${InUseBatchId}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Approved.Name, ReportEnum.Align.Left, "${Approved}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.ApprovedBy.Name, ReportEnum.Align.Left, "${ApprovedBy}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.Purge.Name, ReportEnum.Align.Left, "${Purge}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.Notes.Name, ReportEnum.Align.Left, "${Notes}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.AddedMth.Name, ReportEnum.Align.Left, "${AddedMth}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.AddedBatchID.Name, ReportEnum.Align.Right, "${AddedBatchID}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Attention.Name, ReportEnum.Align.Left, "${Attention}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.PayAddressSeq.Name, ReportEnum.Align.Right, "${PayAddressSeq}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.POAddressSeq.Name, ReportEnum.Align.Right, "${POAddressSeq}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Address2.Name, ReportEnum.Align.Left, "${Address2}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.Country.Name, ReportEnum.Align.Left, "${Country}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.POCloseBatchID.Name, ReportEnum.Align.Right, "${POCloseBatchID}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.udSource.Name, ReportEnum.Align.Left, "${udSource}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.udConv.Name, ReportEnum.Align.Left, "${udConv}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udCGCTable.Name, ReportEnum.Align.Left, "${udCGCTable}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udCGCTableID.Name, ReportEnum.Align.Right, "${udCGCTableID}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POHDView.udOrderedBy.Name, ReportEnum.Align.Right, "${udOrderedBy}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.DocType.Name, ReportEnum.Align.Left, "${DocType}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udMCKPONumber.Name, ReportEnum.Align.Left, "${udMCKPONumber}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.udShipToJobYN.Name, ReportEnum.Align.Left, "${udShipToJobYN}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udPRCo.Name, ReportEnum.Align.Right, "${udPRCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.udAddressName.Name, ReportEnum.Align.Left, "${udAddressName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.udPOFOB.Name, ReportEnum.Align.Left, "${udPOFOB}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udShipMethod.Name, ReportEnum.Align.Left, "${udShipMethod}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udPurchaseContact.Name, ReportEnum.Align.Right, "${udPurchaseContact}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.udPMSource.Name, ReportEnum.Align.Right, "${udPMSource}", ReportEnum.Align.Right, 15);

  
                int rowsPerQuery = 5000;
                int recordCount = 0;
                                
                report.Page = Page.GetResourceValue("Txt:Page", "POViewer");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                
                ColumnList columns = POHDView.GetColumnList();
                
                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                
                int pageNum = 0;
                int totalRows = POHDView.GetRecordCount(joinFilter,whereClause);
                POHDRecord[] records = null;
                
                do
                {
                    
                    records = POHDView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                     if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( POHDRecord record in records)
                    
                        {
                            // AddData method takes four parameters   
                            // The 1st parameter represent the data format
                            // The 2nd parameter represent the data value
                            // The 3rd parameter represent the default alignment of column using the data
                            // The 4th parameter represent the maximum length of the data value being shown
                                                 report.AddData("${POCo}", record.Format(POHDView.POCo), ReportEnum.Align.Right, 300);
                             report.AddData("${PO}", record.Format(POHDView.PO), ReportEnum.Align.Left, 300);
                             report.AddData("${VendorGroup}", record.Format(POHDView.VendorGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${Vendor}", record.Format(POHDView.Vendor), ReportEnum.Align.Right, 300);
                             report.AddData("${Description}", record.Format(POHDView.Description), ReportEnum.Align.Left, 300);
                             report.AddData("${OrderDate}", record.Format(POHDView.OrderDate), ReportEnum.Align.Left, 300);
                             report.AddData("${OrderedBy}", record.Format(POHDView.OrderedBy), ReportEnum.Align.Left, 300);
                             report.AddData("${ExpDate}", record.Format(POHDView.ExpDate), ReportEnum.Align.Left, 300);
                             report.AddData("${Status}", record.Format(POHDView.Status), ReportEnum.Align.Right, 300);
                             report.AddData("${JCCo}", record.Format(POHDView.JCCo), ReportEnum.Align.Right, 300);
                             report.AddData("${Job}", record.Format(POHDView.Job), ReportEnum.Align.Left, 300);
                             report.AddData("${INCo}", record.Format(POHDView.INCo), ReportEnum.Align.Right, 300);
                             report.AddData("${Loc}", record.Format(POHDView.Loc), ReportEnum.Align.Left, 300);
                             report.AddData("${ShipLoc}", record.Format(POHDView.ShipLoc), ReportEnum.Align.Left, 300);
                             report.AddData("${Address}", record.Format(POHDView.Address), ReportEnum.Align.Left, 300);
                             report.AddData("${City}", record.Format(POHDView.City), ReportEnum.Align.Left, 300);
                             report.AddData("${State}", record.Format(POHDView.State), ReportEnum.Align.Left, 300);
                             report.AddData("${Zip}", record.Format(POHDView.Zip), ReportEnum.Align.Left, 300);
                             report.AddData("${ShipIns}", record.Format(POHDView.ShipIns), ReportEnum.Align.Left, 300);
                             report.AddData("${HoldCode}", record.Format(POHDView.HoldCode), ReportEnum.Align.Left, 300);
                             report.AddData("${PayTerms}", record.Format(POHDView.PayTerms), ReportEnum.Align.Left, 300);
                             report.AddData("${CompGroup}", record.Format(POHDView.CompGroup), ReportEnum.Align.Left, 300);
                             report.AddData("${MthClosed}", record.Format(POHDView.MthClosed), ReportEnum.Align.Left, 300);
                             report.AddData("${InUseMth}", record.Format(POHDView.InUseMth), ReportEnum.Align.Left, 300);
                             report.AddData("${InUseBatchId}", record.Format(POHDView.InUseBatchId), ReportEnum.Align.Right, 300);
                             report.AddData("${Approved}", record.Format(POHDView.Approved), ReportEnum.Align.Left, 300);
                             report.AddData("${ApprovedBy}", record.Format(POHDView.ApprovedBy), ReportEnum.Align.Left, 300);
                             report.AddData("${Purge}", record.Format(POHDView.Purge), ReportEnum.Align.Left, 300);
                             report.AddData("${Notes}", record.Format(POHDView.Notes), ReportEnum.Align.Left, 300);
                             report.AddData("${AddedMth}", record.Format(POHDView.AddedMth), ReportEnum.Align.Left, 300);
                             report.AddData("${AddedBatchID}", record.Format(POHDView.AddedBatchID), ReportEnum.Align.Right, 300);
                             report.AddData("${Attention}", record.Format(POHDView.Attention), ReportEnum.Align.Left, 300);
                             report.AddData("${PayAddressSeq}", record.Format(POHDView.PayAddressSeq), ReportEnum.Align.Right, 300);
                             report.AddData("${POAddressSeq}", record.Format(POHDView.POAddressSeq), ReportEnum.Align.Right, 300);
                             report.AddData("${Address2}", record.Format(POHDView.Address2), ReportEnum.Align.Left, 300);
                             report.AddData("${Country}", record.Format(POHDView.Country), ReportEnum.Align.Left, 300);
                             report.AddData("${POCloseBatchID}", record.Format(POHDView.POCloseBatchID), ReportEnum.Align.Right, 300);
                             report.AddData("${udSource}", record.Format(POHDView.udSource), ReportEnum.Align.Left, 300);
                             report.AddData("${udConv}", record.Format(POHDView.udConv), ReportEnum.Align.Left, 300);
                             report.AddData("${udCGCTable}", record.Format(POHDView.udCGCTable), ReportEnum.Align.Left, 300);
                             report.AddData("${udCGCTableID}", record.Format(POHDView.udCGCTableID), ReportEnum.Align.Right, 300);
                             report.AddData("${udOrderedBy}", record.Format(POHDView.udOrderedBy), ReportEnum.Align.Right, 300);
                             report.AddData("${DocType}", record.Format(POHDView.DocType), ReportEnum.Align.Left, 300);
                             report.AddData("${udMCKPONumber}", record.Format(POHDView.udMCKPONumber), ReportEnum.Align.Left, 300);
                             report.AddData("${udShipToJobYN}", record.Format(POHDView.udShipToJobYN), ReportEnum.Align.Left, 300);
                             report.AddData("${udPRCo}", record.Format(POHDView.udPRCo), ReportEnum.Align.Right, 300);
                             report.AddData("${udAddressName}", record.Format(POHDView.udAddressName), ReportEnum.Align.Left, 300);
                             report.AddData("${udPOFOB}", record.Format(POHDView.udPOFOB), ReportEnum.Align.Left, 300);
                             report.AddData("${udShipMethod}", record.Format(POHDView.udShipMethod), ReportEnum.Align.Left, 300);
                             report.AddData("${udPurchaseContact}", record.Format(POHDView.udPurchaseContact), ReportEnum.Align.Right, 300);
                             report.AddData("${udPMSource}", record.Format(POHDView.udPMSource), ReportEnum.Align.Right, 300);

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
                
              this.SearchText.Text = "";
            
              this.StatusFromFilter.Text = "";
            
              this.StatusToFilter.Text = "";
            
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

                report.SpecificReportFileName = Page.Server.MapPath("Show-POHD-Table.WordButton.word");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "POHD";
                // If Show-POHD-Table.WordButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(POHDView.POCo.Name, ReportEnum.Align.Right, "${POCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.PO.Name, ReportEnum.Align.Left, "${PO}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.VendorGroup.Name, ReportEnum.Align.Right, "${VendorGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Vendor.Name, ReportEnum.Align.Right, "${Vendor}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Description.Name, ReportEnum.Align.Left, "${Description}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.OrderDate.Name, ReportEnum.Align.Left, "${OrderDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.OrderedBy.Name, ReportEnum.Align.Left, "${OrderedBy}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.ExpDate.Name, ReportEnum.Align.Left, "${ExpDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.Status.Name, ReportEnum.Align.Right, "${Status}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.JCCo.Name, ReportEnum.Align.Right, "${JCCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Job.Name, ReportEnum.Align.Left, "${Job}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.INCo.Name, ReportEnum.Align.Right, "${INCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Loc.Name, ReportEnum.Align.Left, "${Loc}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.ShipLoc.Name, ReportEnum.Align.Left, "${ShipLoc}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.Address.Name, ReportEnum.Align.Left, "${Address}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.City.Name, ReportEnum.Align.Left, "${City}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.State.Name, ReportEnum.Align.Left, "${State}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.Zip.Name, ReportEnum.Align.Left, "${Zip}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.ShipIns.Name, ReportEnum.Align.Left, "${ShipIns}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.HoldCode.Name, ReportEnum.Align.Left, "${HoldCode}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.PayTerms.Name, ReportEnum.Align.Left, "${PayTerms}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.CompGroup.Name, ReportEnum.Align.Left, "${CompGroup}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.MthClosed.Name, ReportEnum.Align.Left, "${MthClosed}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.InUseMth.Name, ReportEnum.Align.Left, "${InUseMth}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.InUseBatchId.Name, ReportEnum.Align.Right, "${InUseBatchId}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Approved.Name, ReportEnum.Align.Left, "${Approved}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.ApprovedBy.Name, ReportEnum.Align.Left, "${ApprovedBy}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.Purge.Name, ReportEnum.Align.Left, "${Purge}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.Notes.Name, ReportEnum.Align.Left, "${Notes}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.AddedMth.Name, ReportEnum.Align.Left, "${AddedMth}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POHDView.AddedBatchID.Name, ReportEnum.Align.Right, "${AddedBatchID}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Attention.Name, ReportEnum.Align.Left, "${Attention}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.PayAddressSeq.Name, ReportEnum.Align.Right, "${PayAddressSeq}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.POAddressSeq.Name, ReportEnum.Align.Right, "${POAddressSeq}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.Address2.Name, ReportEnum.Align.Left, "${Address2}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POHDView.Country.Name, ReportEnum.Align.Left, "${Country}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.POCloseBatchID.Name, ReportEnum.Align.Right, "${POCloseBatchID}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.udSource.Name, ReportEnum.Align.Left, "${udSource}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.udConv.Name, ReportEnum.Align.Left, "${udConv}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udCGCTable.Name, ReportEnum.Align.Left, "${udCGCTable}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udCGCTableID.Name, ReportEnum.Align.Right, "${udCGCTableID}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POHDView.udOrderedBy.Name, ReportEnum.Align.Right, "${udOrderedBy}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.DocType.Name, ReportEnum.Align.Left, "${DocType}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udMCKPONumber.Name, ReportEnum.Align.Left, "${udMCKPONumber}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.udShipToJobYN.Name, ReportEnum.Align.Left, "${udShipToJobYN}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udPRCo.Name, ReportEnum.Align.Right, "${udPRCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.udAddressName.Name, ReportEnum.Align.Left, "${udAddressName}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POHDView.udPOFOB.Name, ReportEnum.Align.Left, "${udPOFOB}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udShipMethod.Name, ReportEnum.Align.Left, "${udShipMethod}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POHDView.udPurchaseContact.Name, ReportEnum.Align.Right, "${udPurchaseContact}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POHDView.udPMSource.Name, ReportEnum.Align.Right, "${udPMSource}", ReportEnum.Align.Right, 15);

                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
            
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                

                int rowsPerQuery = 5000;
                int pageNum = 0;
                int recordCount = 0;
                int totalRows = POHDView.GetRecordCount(joinFilter,whereClause);

                report.Page = Page.GetResourceValue("Txt:Page", "POViewer");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                ColumnList columns = POHDView.GetColumnList();
                POHDRecord[] records = null;
                do
                {
                    records = POHDView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                    if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( POHDRecord record in records)
                        {
                            // AddData method takes four parameters
                            // The 1st parameter represents the data format
                            // The 2nd parameter represents the data value
                            // The 3rd parameter represents the default alignment of column using the data
                            // The 4th parameter represents the maximum length of the data value being shown
                             report.AddData("${POCo}", record.Format(POHDView.POCo), ReportEnum.Align.Right, 300);
                             report.AddData("${PO}", record.Format(POHDView.PO), ReportEnum.Align.Left, 300);
                             report.AddData("${VendorGroup}", record.Format(POHDView.VendorGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${Vendor}", record.Format(POHDView.Vendor), ReportEnum.Align.Right, 300);
                             report.AddData("${Description}", record.Format(POHDView.Description), ReportEnum.Align.Left, 300);
                             report.AddData("${OrderDate}", record.Format(POHDView.OrderDate), ReportEnum.Align.Left, 300);
                             report.AddData("${OrderedBy}", record.Format(POHDView.OrderedBy), ReportEnum.Align.Left, 300);
                             report.AddData("${ExpDate}", record.Format(POHDView.ExpDate), ReportEnum.Align.Left, 300);
                             report.AddData("${Status}", record.Format(POHDView.Status), ReportEnum.Align.Right, 300);
                             report.AddData("${JCCo}", record.Format(POHDView.JCCo), ReportEnum.Align.Right, 300);
                             report.AddData("${Job}", record.Format(POHDView.Job), ReportEnum.Align.Left, 300);
                             report.AddData("${INCo}", record.Format(POHDView.INCo), ReportEnum.Align.Right, 300);
                             report.AddData("${Loc}", record.Format(POHDView.Loc), ReportEnum.Align.Left, 300);
                             report.AddData("${ShipLoc}", record.Format(POHDView.ShipLoc), ReportEnum.Align.Left, 300);
                             report.AddData("${Address}", record.Format(POHDView.Address), ReportEnum.Align.Left, 300);
                             report.AddData("${City}", record.Format(POHDView.City), ReportEnum.Align.Left, 300);
                             report.AddData("${State}", record.Format(POHDView.State), ReportEnum.Align.Left, 300);
                             report.AddData("${Zip}", record.Format(POHDView.Zip), ReportEnum.Align.Left, 300);
                             report.AddData("${ShipIns}", record.Format(POHDView.ShipIns), ReportEnum.Align.Left, 300);
                             report.AddData("${HoldCode}", record.Format(POHDView.HoldCode), ReportEnum.Align.Left, 300);
                             report.AddData("${PayTerms}", record.Format(POHDView.PayTerms), ReportEnum.Align.Left, 300);
                             report.AddData("${CompGroup}", record.Format(POHDView.CompGroup), ReportEnum.Align.Left, 300);
                             report.AddData("${MthClosed}", record.Format(POHDView.MthClosed), ReportEnum.Align.Left, 300);
                             report.AddData("${InUseMth}", record.Format(POHDView.InUseMth), ReportEnum.Align.Left, 300);
                             report.AddData("${InUseBatchId}", record.Format(POHDView.InUseBatchId), ReportEnum.Align.Right, 300);
                             report.AddData("${Approved}", record.Format(POHDView.Approved), ReportEnum.Align.Left, 300);
                             report.AddData("${ApprovedBy}", record.Format(POHDView.ApprovedBy), ReportEnum.Align.Left, 300);
                             report.AddData("${Purge}", record.Format(POHDView.Purge), ReportEnum.Align.Left, 300);
                             report.AddData("${Notes}", record.Format(POHDView.Notes), ReportEnum.Align.Left, 300);
                             report.AddData("${AddedMth}", record.Format(POHDView.AddedMth), ReportEnum.Align.Left, 300);
                             report.AddData("${AddedBatchID}", record.Format(POHDView.AddedBatchID), ReportEnum.Align.Right, 300);
                             report.AddData("${Attention}", record.Format(POHDView.Attention), ReportEnum.Align.Left, 300);
                             report.AddData("${PayAddressSeq}", record.Format(POHDView.PayAddressSeq), ReportEnum.Align.Right, 300);
                             report.AddData("${POAddressSeq}", record.Format(POHDView.POAddressSeq), ReportEnum.Align.Right, 300);
                             report.AddData("${Address2}", record.Format(POHDView.Address2), ReportEnum.Align.Left, 300);
                             report.AddData("${Country}", record.Format(POHDView.Country), ReportEnum.Align.Left, 300);
                             report.AddData("${POCloseBatchID}", record.Format(POHDView.POCloseBatchID), ReportEnum.Align.Right, 300);
                             report.AddData("${udSource}", record.Format(POHDView.udSource), ReportEnum.Align.Left, 300);
                             report.AddData("${udConv}", record.Format(POHDView.udConv), ReportEnum.Align.Left, 300);
                             report.AddData("${udCGCTable}", record.Format(POHDView.udCGCTable), ReportEnum.Align.Left, 300);
                             report.AddData("${udCGCTableID}", record.Format(POHDView.udCGCTableID), ReportEnum.Align.Right, 300);
                             report.AddData("${udOrderedBy}", record.Format(POHDView.udOrderedBy), ReportEnum.Align.Right, 300);
                             report.AddData("${DocType}", record.Format(POHDView.DocType), ReportEnum.Align.Left, 300);
                             report.AddData("${udMCKPONumber}", record.Format(POHDView.udMCKPONumber), ReportEnum.Align.Left, 300);
                             report.AddData("${udShipToJobYN}", record.Format(POHDView.udShipToJobYN), ReportEnum.Align.Left, 300);
                             report.AddData("${udPRCo}", record.Format(POHDView.udPRCo), ReportEnum.Align.Right, 300);
                             report.AddData("${udAddressName}", record.Format(POHDView.udAddressName), ReportEnum.Align.Left, 300);
                             report.AddData("${udPOFOB}", record.Format(POHDView.udPOFOB), ReportEnum.Align.Left, 300);
                             report.AddData("${udShipMethod}", record.Format(POHDView.udShipMethod), ReportEnum.Align.Left, 300);
                             report.AddData("${udPurchaseContact}", record.Format(POHDView.udPurchaseContact), ReportEnum.Align.Right, 300);
                             report.AddData("${udPMSource}", record.Format(POHDView.udPMSource), ReportEnum.Align.Right, 300);

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
        
    
        // Generate the event handling functions for others
        	  

        protected int _TotalRecords = -1;
        public int TotalRecords 
        {
            get {
                if (_TotalRecords < 0)
                {
                    _TotalRecords = POHDView.GetRecordCount(CreateCompoundJoinFilter(), CreateWhereClause());
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
        
        public  POHDRecord[] DataSource {
             
            get {
                return (POHDRecord[])(base._DataSource);
            }
            set {
                this._DataSource = value;
            }
        }

#region "Helper Properties"
        
        public POViewer.UI.IThemeButtonWithArrow ActionsButton {
            get {
                return (POViewer.UI.IThemeButtonWithArrow)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ActionsButton");
            }
        }
        
        public System.Web.UI.WebControls.Literal AddedBatchIDLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AddedBatchIDLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton AddedMthLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AddedMthLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton Address2Label {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Address2Label");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton AddressLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AddressLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal ApprovedByLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ApprovedByLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal ApprovedLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ApprovedLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal AttentionLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AttentionLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton CityLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CityLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CompGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CompGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton CountryLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CountryLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal DescriptionLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "DescriptionLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal DocTypeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "DocTypeLabel");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton ExcelButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ExcelButton");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton ExpDateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ExpDateLabel");
            }
        }
        
        public POViewer.UI.IThemeButton FilterButton {
            get {
                return (POViewer.UI.IThemeButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "FilterButton");
            }
        }
        
        public POViewer.UI.IThemeButtonWithArrow FiltersButton {
            get {
                return (POViewer.UI.IThemeButtonWithArrow)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "FiltersButton");
            }
        }
        
        public System.Web.UI.WebControls.Literal HoldCodeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "HoldCodeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal INCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "INCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal InUseBatchIdLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InUseBatchIdLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal InUseMthLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InUseMthLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal JCCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal JobLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal LocLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "LocLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal MthClosedLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MthClosedLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal NotesLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "NotesLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal OrderDateLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrderDateLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal OrderedByLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrderedByLabel");
            }
        }
        
        public POViewer.UI.IPaginationModern Pagination {
            get {
                return (POViewer.UI.IPaginationModern)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Pagination");
            }
        }
        
        public System.Web.UI.WebControls.Literal PayAddressSeqLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PayAddressSeqLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal PayTermsLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PayTermsLabel");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton PDFButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PDFButton");
            }
        }
        
        public System.Web.UI.WebControls.Literal POAddressSeqLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POAddressSeqLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POCloseBatchIDLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCloseBatchIDLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal PurgeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PurgeLabel");
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
        
        public System.Web.UI.WebControls.LinkButton ShipInsLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ShipInsLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal ShipLocLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ShipLocLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton StateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "StateLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox StatusFromFilter {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "StatusFromFilter");
            }
        }
        
        public System.Web.UI.WebControls.Literal StatusLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "StatusLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal StatusLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "StatusLabel1");
            }
        }
        
        public System.Web.UI.WebControls.TextBox StatusToFilter {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "StatusToFilter");
            }
        }
        
        public System.Web.UI.WebControls.Literal Title {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Title");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton udAddressNameLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udAddressNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udCGCTableIDLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udCGCTableIDLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udCGCTableLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udCGCTableLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udConvLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udConvLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udMCKPONumberLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udMCKPONumberLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udOrderedByLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udOrderedByLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udPMSourceLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPMSourceLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udPOFOBLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPOFOBLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udPRCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPRCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udPurchaseContactLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPurchaseContactLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udShipMethodLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udShipMethodLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udShipToJobYNLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udShipToJobYNLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udSourceLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udSourceLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VendorGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VendorGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VendorLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VendorLabel");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton WordButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "WordButton");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton ZipLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ZipLabel");
            }
        }
        
#endregion

#region "Helper Functions"
        
        public override string ModifyRedirectUrl(string url, string arg, bool bEncrypt)
        {
            return EvaluateExpressions(url, arg, null, bEncrypt);
        }
        
        public override string ModifyRedirectUrl(string url, string arg, bool bEncrypt,bool includeSession)
        {
            return EvaluateExpressions(url, arg, null, bEncrypt,includeSession);
        }
        
        public override string EvaluateExpressions(string url, string arg, bool bEncrypt)
        {
            return EvaluateExpressions(url, arg, null, bEncrypt);
        }
        
        public override string EvaluateExpressions(string url, string arg, bool bEncrypt,bool includeSession)
        {
            return EvaluateExpressions(url, arg, null, bEncrypt);
        }
          
        public virtual POHDTableControlRow GetSelectedRecordControl()
        {
        
            return null;
          
        }

        public virtual POHDTableControlRow[] GetSelectedRecordControls()
        {
        
            return (POHDTableControlRow[])((new ArrayList()).ToArray(Type.GetType("POViewer.UI.Controls.Show_POHD_Table.POHDTableControlRow")));
          
        }

        public virtual void DeleteSelectedRecords(bool deferDeletion)
        {
            POHDTableControlRow[] recordList = this.GetSelectedRecordControls();
            if (recordList.Length == 0) {
                // Localization.
                throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "POViewer"));
            }
            
            foreach (POHDTableControlRow recCtl in recordList)
            {
                if (deferDeletion) {
                    if (!recCtl.IsNewRecord) {
                
                        // Localization.
                        throw new Exception(Page.GetResourceValue("Err:CannotDelRecs", "POViewer"));
                  
                    }
                    recCtl.Visible = false;
                
                } else {
                
                    // Localization.
                    throw new Exception(Page.GetResourceValue("Err:CannotDelRecs", "POViewer"));
                  
                }
            }
        }

        public POHDTableControlRow[] GetRecordControls()
        {
            ArrayList recordList = new ArrayList();
            System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)this.FindControl("POHDTableControlRepeater");
            if (rep == null){return null;}
            foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
            {
              POHDTableControlRow recControl = (POHDTableControlRow)repItem.FindControl("POHDTableControlRow");
                  recordList.Add(recControl);
                
            }

            return (POHDTableControlRow[])recordList.ToArray(Type.GetType("POViewer.UI.Controls.Show_POHD_Table.POHDTableControlRow"));
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

  