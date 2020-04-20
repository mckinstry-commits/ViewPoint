
// This file implements the TableControl, TableControlRow, and RecordControl classes for the 
// Show_POIT_Table.aspx page.  The Row or RecordControl classes are the 
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

  
namespace POViewer.UI.Controls.Show_POIT_Table
{
  

#region "Section 1: Place your customizations here."

    
public class POITTableControlRow : BasePOITTableControlRow
{
      
        // The BasePOITTableControlRow implements code for a ROW within the
        // the POITTableControl table.  The BasePOITTableControlRow implements the DataBind and SaveData methods.
        // The loading of data is actually performed by the LoadData method in the base class of POITTableControl.

        // This is the ideal place to add your code customizations. For example, you can override the DataBind, 
        // SaveData, GetUIData, and Validate methods.
        
}

  

public class POITTableControl : BasePOITTableControl
{
    // The BasePOITTableControl class implements the LoadData, DataBind, CreateWhereClause
    // and other methods to load and display the data in a table control.

    // This is the ideal place to add your code customizations. You can override the LoadData and CreateWhereClause,
    // The POITTableControlRow class offers another place where you can customize
    // the DataBind, GetUIData, SaveData and Validate methods specific to each row displayed on the table.

}

  

#endregion

  

#region "Section 2: Do not modify this section."
    
    
// Base class for the POITTableControlRow control on the Show_POIT_Table page.
// Do not modify this class. Instead override any method in POITTableControlRow.
public class BasePOITTableControlRow : POViewer.UI.BaseApplicationRecordControl
{
        public BasePOITTableControlRow()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        // To customize, override this method in POITTableControlRow.
        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
                
            this.ClearControlsFromSession();
        }

        // To customize, override this method in POITTableControlRow.
        protected virtual void Control_Load(object sender, System.EventArgs e)
        {      
                    
        
              // Register the event handlers.

          
        }

        public virtual void LoadData()  
        {
            // Load the data from the database into the DataSource DatabaseViewpoint%dbo.POIT record.
            // It is better to make changes to functions called by LoadData such as
            // CreateWhereClause, rather than making changes here.
            
        
            // Since this is a row in the table, the data for this row is loaded by the 
            // LoadData method of the BasePOITTableControl when the data for the entire
            // table is loaded.
            
            this.DataSource = new POITRecord();
            
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
                SetBOCost();
                SetBOUnits();
                SetComponent();
                SetCompType();
                SetCostCode();
                SetCurCost();
                SetCurECM();
                SetCurTax();
                SetCurUnitCost();
                SetCurUnits();
                SetDescription();
                SetEMCo();
                SetEMCType();
                SetEMGroup();
                SetEquip();
                SetGLAcct();
                SetGLCo();
                SetGSTRate();
                SetINCo();
                SetInUseBatchId();
                SetInUseMth();
                SetInvCost();
                SetInvMiscAmt();
                SetInvTax();
                SetInvUnits();
                SetItemType();
                SetJCCmtdTax();
                SetJCCo();
                SetJCCType();
                SetJCRemCmtdTax();
                SetJob();
                SetLoc();
                SetMaterial();
                SetMatlGroup();
                SetNotes();
                SetOrigCost();
                SetOrigECM();
                SetOrigTax();
                SetOrigUnitCost();
                SetOrigUnits();
                SetPayCategory();
                SetPayType();
                SetPhase();
                SetPhaseGroup();
                SetPO();
                SetPOCo();
                SetPOItem();
                SetPostedDate();
                SetPostToCo();
                SetRecvdCost();
                SetRecvdUnits();
                SetRecvYN();
                SetRemCost();
                SetRemTax();
                SetRemUnits();
                SetReqDate();
                SetRequisitionNum();
                SetSMCo();
                SetSMJCCostType();
                SetSMPhase();
                SetSMPhaseGroup();
                SetSMScope();
                SetSMWorkOrder();
                SetSupplier();
                SetSupplierGroup();
                SetTaxCode();
                SetTaxGroup();
                SetTaxRate();
                SetTaxType();
                SetTotalCost();
                SetTotalTax();
                SetTotalUnits();
                SetudActOffDate();
                SetudCGCTable();
                SetudCGCTableID();
                SetudConv();
                SetudOnDate();
                SetudPlnOffDate();
                SetudRentalNum();
                SetudSource();
                SetUM();
                SetVendMatId();
                SetWO();
                SetWOItem();

      

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
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.AddedBatchID is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AddedBatchIDSpecified) {
                								
                // If the AddedBatchID is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.AddedBatchID);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.AddedBatchID.Text = formattedValue;
                   
            } 
            
            else {
            
                // AddedBatchID is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.AddedBatchID.Text = POITView.AddedBatchID.Format(POITView.AddedBatchID.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.AddedMth is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AddedMthSpecified) {
                								
                // If the AddedMth is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.AddedMth, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.AddedMth.Text = formattedValue;
                   
            } 
            
            else {
            
                // AddedMth is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.AddedMth.Text = POITView.AddedMth.Format(POITView.AddedMth.DefaultValue, @"g");
            		
            }
            
            // If the AddedMth is NULL or blank, then use the value specified  
            // on Properties.
            if (this.AddedMth.Text == null ||
                this.AddedMth.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.AddedMth.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetBOCost()
        {
            
                    
            // Set the BOCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.BOCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.BOCostSpecified) {
                								
                // If the BOCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.BOCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.BOCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // BOCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.BOCost.Text = POITView.BOCost.Format(POITView.BOCost.DefaultValue);
            		
            }
            
            // If the BOCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.BOCost.Text == null ||
                this.BOCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.BOCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetBOUnits()
        {
            
                    
            // Set the BOUnits Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.BOUnits is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.BOUnitsSpecified) {
                								
                // If the BOUnits is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.BOUnits);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.BOUnits.Text = formattedValue;
                   
            } 
            
            else {
            
                // BOUnits is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.BOUnits.Text = POITView.BOUnits.Format(POITView.BOUnits.DefaultValue);
            		
            }
            
            // If the BOUnits is NULL or blank, then use the value specified  
            // on Properties.
            if (this.BOUnits.Text == null ||
                this.BOUnits.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.BOUnits.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetComponent()
        {
            
                    
            // Set the Component Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Component is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ComponentSpecified) {
                								
                // If the Component is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Component);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Component.Text = formattedValue;
                   
            } 
            
            else {
            
                // Component is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Component.Text = POITView.Component.Format(POITView.Component.DefaultValue);
            		
            }
            
            // If the Component is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Component.Text == null ||
                this.Component.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Component.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCompType()
        {
            
                    
            // Set the CompType Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.CompType is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CompTypeSpecified) {
                								
                // If the CompType is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.CompType);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CompType.Text = formattedValue;
                   
            } 
            
            else {
            
                // CompType is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CompType.Text = POITView.CompType.Format(POITView.CompType.DefaultValue);
            		
            }
            
            // If the CompType is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CompType.Text == null ||
                this.CompType.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CompType.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCostCode()
        {
            
                    
            // Set the CostCode Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.CostCode is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CostCodeSpecified) {
                								
                // If the CostCode is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.CostCode);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CostCode.Text = formattedValue;
                   
            } 
            
            else {
            
                // CostCode is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CostCode.Text = POITView.CostCode.Format(POITView.CostCode.DefaultValue);
            		
            }
            
            // If the CostCode is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CostCode.Text == null ||
                this.CostCode.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CostCode.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCurCost()
        {
            
                    
            // Set the CurCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.CurCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CurCostSpecified) {
                								
                // If the CurCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.CurCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CurCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // CurCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CurCost.Text = POITView.CurCost.Format(POITView.CurCost.DefaultValue);
            		
            }
            
            // If the CurCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CurCost.Text == null ||
                this.CurCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CurCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCurECM()
        {
            
                    
            // Set the CurECM Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.CurECM is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CurECMSpecified) {
                								
                // If the CurECM is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.CurECM);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CurECM.Text = formattedValue;
                   
            } 
            
            else {
            
                // CurECM is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CurECM.Text = POITView.CurECM.Format(POITView.CurECM.DefaultValue);
            		
            }
            
            // If the CurECM is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CurECM.Text == null ||
                this.CurECM.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CurECM.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCurTax()
        {
            
                    
            // Set the CurTax Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.CurTax is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CurTaxSpecified) {
                								
                // If the CurTax is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.CurTax);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CurTax.Text = formattedValue;
                   
            } 
            
            else {
            
                // CurTax is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CurTax.Text = POITView.CurTax.Format(POITView.CurTax.DefaultValue);
            		
            }
            
            // If the CurTax is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CurTax.Text == null ||
                this.CurTax.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CurTax.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCurUnitCost()
        {
            
                    
            // Set the CurUnitCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.CurUnitCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CurUnitCostSpecified) {
                								
                // If the CurUnitCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.CurUnitCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CurUnitCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // CurUnitCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CurUnitCost.Text = POITView.CurUnitCost.Format(POITView.CurUnitCost.DefaultValue);
            		
            }
            
            // If the CurUnitCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CurUnitCost.Text == null ||
                this.CurUnitCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CurUnitCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCurUnits()
        {
            
                    
            // Set the CurUnits Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.CurUnits is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CurUnitsSpecified) {
                								
                // If the CurUnits is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.CurUnits);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CurUnits.Text = formattedValue;
                   
            } 
            
            else {
            
                // CurUnits is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CurUnits.Text = POITView.CurUnits.Format(POITView.CurUnits.DefaultValue);
            		
            }
            
            // If the CurUnits is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CurUnits.Text == null ||
                this.CurUnits.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CurUnits.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetDescription()
        {
            
                    
            // Set the Description Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Description is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.DescriptionSpecified) {
                								
                // If the Description is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Description);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Description.Text = formattedValue;
                   
            } 
            
            else {
            
                // Description is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Description.Text = POITView.Description.Format(POITView.Description.DefaultValue);
            		
            }
            
            // If the Description is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Description.Text == null ||
                this.Description.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Description.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetEMCo()
        {
            
                    
            // Set the EMCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.EMCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.EMCoSpecified) {
                								
                // If the EMCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.EMCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.EMCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // EMCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.EMCo.Text = POITView.EMCo.Format(POITView.EMCo.DefaultValue);
            		
            }
            
            // If the EMCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.EMCo.Text == null ||
                this.EMCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.EMCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetEMCType()
        {
            
                    
            // Set the EMCType Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.EMCType is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.EMCTypeSpecified) {
                								
                // If the EMCType is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.EMCType);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.EMCType.Text = formattedValue;
                   
            } 
            
            else {
            
                // EMCType is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.EMCType.Text = POITView.EMCType.Format(POITView.EMCType.DefaultValue);
            		
            }
            
            // If the EMCType is NULL or blank, then use the value specified  
            // on Properties.
            if (this.EMCType.Text == null ||
                this.EMCType.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.EMCType.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetEMGroup()
        {
            
                    
            // Set the EMGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.EMGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.EMGroupSpecified) {
                								
                // If the EMGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.EMGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.EMGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // EMGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.EMGroup.Text = POITView.EMGroup.Format(POITView.EMGroup.DefaultValue);
            		
            }
            
            // If the EMGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.EMGroup.Text == null ||
                this.EMGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.EMGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetEquip()
        {
            
                    
            // Set the Equip Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Equip is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.EquipSpecified) {
                								
                // If the Equip is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Equip);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Equip.Text = formattedValue;
                   
            } 
            
            else {
            
                // Equip is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Equip.Text = POITView.Equip.Format(POITView.Equip.DefaultValue);
            		
            }
            
            // If the Equip is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Equip.Text == null ||
                this.Equip.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Equip.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetGLAcct()
        {
            
                    
            // Set the GLAcct Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.GLAcct is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.GLAcctSpecified) {
                								
                // If the GLAcct is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.GLAcct);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.GLAcct.Text = formattedValue;
                   
            } 
            
            else {
            
                // GLAcct is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.GLAcct.Text = POITView.GLAcct.Format(POITView.GLAcct.DefaultValue);
            		
            }
            
            // If the GLAcct is NULL or blank, then use the value specified  
            // on Properties.
            if (this.GLAcct.Text == null ||
                this.GLAcct.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.GLAcct.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetGLCo()
        {
            
                    
            // Set the GLCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.GLCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.GLCoSpecified) {
                								
                // If the GLCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.GLCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.GLCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // GLCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.GLCo.Text = POITView.GLCo.Format(POITView.GLCo.DefaultValue);
            		
            }
            
            // If the GLCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.GLCo.Text == null ||
                this.GLCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.GLCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetGSTRate()
        {
            
                    
            // Set the GSTRate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.GSTRate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.GSTRateSpecified) {
                								
                // If the GSTRate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.GSTRate);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.GSTRate.Text = formattedValue;
                   
            } 
            
            else {
            
                // GSTRate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.GSTRate.Text = POITView.GSTRate.Format(POITView.GSTRate.DefaultValue);
            		
            }
            
            // If the GSTRate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.GSTRate.Text == null ||
                this.GSTRate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.GSTRate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetINCo()
        {
            
                    
            // Set the INCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.INCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.INCoSpecified) {
                								
                // If the INCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.INCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.INCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // INCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.INCo.Text = POITView.INCo.Format(POITView.INCo.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.InUseBatchId is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.InUseBatchIdSpecified) {
                								
                // If the InUseBatchId is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.InUseBatchId);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.InUseBatchId.Text = formattedValue;
                   
            } 
            
            else {
            
                // InUseBatchId is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.InUseBatchId.Text = POITView.InUseBatchId.Format(POITView.InUseBatchId.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.InUseMth is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.InUseMthSpecified) {
                								
                // If the InUseMth is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.InUseMth, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.InUseMth.Text = formattedValue;
                   
            } 
            
            else {
            
                // InUseMth is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.InUseMth.Text = POITView.InUseMth.Format(POITView.InUseMth.DefaultValue, @"g");
            		
            }
            
            // If the InUseMth is NULL or blank, then use the value specified  
            // on Properties.
            if (this.InUseMth.Text == null ||
                this.InUseMth.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.InUseMth.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetInvCost()
        {
            
                    
            // Set the InvCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.InvCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.InvCostSpecified) {
                								
                // If the InvCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.InvCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.InvCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // InvCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.InvCost.Text = POITView.InvCost.Format(POITView.InvCost.DefaultValue);
            		
            }
            
            // If the InvCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.InvCost.Text == null ||
                this.InvCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.InvCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetInvMiscAmt()
        {
            
                    
            // Set the InvMiscAmt Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.InvMiscAmt is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.InvMiscAmtSpecified) {
                								
                // If the InvMiscAmt is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.InvMiscAmt);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.InvMiscAmt.Text = formattedValue;
                   
            } 
            
            else {
            
                // InvMiscAmt is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.InvMiscAmt.Text = POITView.InvMiscAmt.Format(POITView.InvMiscAmt.DefaultValue);
            		
            }
            
            // If the InvMiscAmt is NULL or blank, then use the value specified  
            // on Properties.
            if (this.InvMiscAmt.Text == null ||
                this.InvMiscAmt.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.InvMiscAmt.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetInvTax()
        {
            
                    
            // Set the InvTax Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.InvTax is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.InvTaxSpecified) {
                								
                // If the InvTax is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.InvTax);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.InvTax.Text = formattedValue;
                   
            } 
            
            else {
            
                // InvTax is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.InvTax.Text = POITView.InvTax.Format(POITView.InvTax.DefaultValue);
            		
            }
            
            // If the InvTax is NULL or blank, then use the value specified  
            // on Properties.
            if (this.InvTax.Text == null ||
                this.InvTax.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.InvTax.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetInvUnits()
        {
            
                    
            // Set the InvUnits Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.InvUnits is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.InvUnitsSpecified) {
                								
                // If the InvUnits is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.InvUnits);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.InvUnits.Text = formattedValue;
                   
            } 
            
            else {
            
                // InvUnits is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.InvUnits.Text = POITView.InvUnits.Format(POITView.InvUnits.DefaultValue);
            		
            }
            
            // If the InvUnits is NULL or blank, then use the value specified  
            // on Properties.
            if (this.InvUnits.Text == null ||
                this.InvUnits.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.InvUnits.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetItemType()
        {
            
                    
            // Set the ItemType Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.ItemType is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ItemTypeSpecified) {
                								
                // If the ItemType is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.ItemType);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.ItemType.Text = formattedValue;
                   
            } 
            
            else {
            
                // ItemType is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.ItemType.Text = POITView.ItemType.Format(POITView.ItemType.DefaultValue);
            		
            }
            
            // If the ItemType is NULL or blank, then use the value specified  
            // on Properties.
            if (this.ItemType.Text == null ||
                this.ItemType.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.ItemType.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJCCmtdTax()
        {
            
                    
            // Set the JCCmtdTax Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.JCCmtdTax is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JCCmtdTaxSpecified) {
                								
                // If the JCCmtdTax is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.JCCmtdTax);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.JCCmtdTax.Text = formattedValue;
                   
            } 
            
            else {
            
                // JCCmtdTax is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.JCCmtdTax.Text = POITView.JCCmtdTax.Format(POITView.JCCmtdTax.DefaultValue);
            		
            }
            
            // If the JCCmtdTax is NULL or blank, then use the value specified  
            // on Properties.
            if (this.JCCmtdTax.Text == null ||
                this.JCCmtdTax.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.JCCmtdTax.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJCCo()
        {
            
                    
            // Set the JCCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.JCCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JCCoSpecified) {
                								
                // If the JCCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.JCCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.JCCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // JCCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.JCCo.Text = POITView.JCCo.Format(POITView.JCCo.DefaultValue);
            		
            }
            
            // If the JCCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.JCCo.Text == null ||
                this.JCCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.JCCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJCCType()
        {
            
                    
            // Set the JCCType Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.JCCType is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JCCTypeSpecified) {
                								
                // If the JCCType is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.JCCType);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.JCCType.Text = formattedValue;
                   
            } 
            
            else {
            
                // JCCType is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.JCCType.Text = POITView.JCCType.Format(POITView.JCCType.DefaultValue);
            		
            }
            
            // If the JCCType is NULL or blank, then use the value specified  
            // on Properties.
            if (this.JCCType.Text == null ||
                this.JCCType.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.JCCType.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJCRemCmtdTax()
        {
            
                    
            // Set the JCRemCmtdTax Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.JCRemCmtdTax is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JCRemCmtdTaxSpecified) {
                								
                // If the JCRemCmtdTax is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.JCRemCmtdTax);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.JCRemCmtdTax.Text = formattedValue;
                   
            } 
            
            else {
            
                // JCRemCmtdTax is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.JCRemCmtdTax.Text = POITView.JCRemCmtdTax.Format(POITView.JCRemCmtdTax.DefaultValue);
            		
            }
            
            // If the JCRemCmtdTax is NULL or blank, then use the value specified  
            // on Properties.
            if (this.JCRemCmtdTax.Text == null ||
                this.JCRemCmtdTax.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.JCRemCmtdTax.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetJob()
        {
            
                    
            // Set the Job Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Job is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.JobSpecified) {
                								
                // If the Job is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Job);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Job.Text = formattedValue;
                   
            } 
            
            else {
            
                // Job is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Job.Text = POITView.Job.Format(POITView.Job.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Loc is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.LocSpecified) {
                								
                // If the Loc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Loc);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Loc.Text = formattedValue;
                   
            } 
            
            else {
            
                // Loc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Loc.Text = POITView.Loc.Format(POITView.Loc.DefaultValue);
            		
            }
            
            // If the Loc is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Loc.Text == null ||
                this.Loc.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Loc.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMaterial()
        {
            
                    
            // Set the Material Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Material is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.MaterialSpecified) {
                								
                // If the Material is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Material);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Material.Text = formattedValue;
                   
            } 
            
            else {
            
                // Material is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Material.Text = POITView.Material.Format(POITView.Material.DefaultValue);
            		
            }
            
            // If the Material is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Material.Text == null ||
                this.Material.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Material.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetMatlGroup()
        {
            
                    
            // Set the MatlGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.MatlGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.MatlGroupSpecified) {
                								
                // If the MatlGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.MatlGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.MatlGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // MatlGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.MatlGroup.Text = POITView.MatlGroup.Format(POITView.MatlGroup.DefaultValue);
            		
            }
            
            // If the MatlGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.MatlGroup.Text == null ||
                this.MatlGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.MatlGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetNotes()
        {
            
                    
            // Set the Notes Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Notes is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.NotesSpecified) {
                								
                // If the Notes is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Notes);
                                
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
        
              this.Notes.Text = POITView.Notes.Format(POITView.Notes.DefaultValue);
            		
            }
            
            // If the Notes is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Notes.Text == null ||
                this.Notes.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Notes.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetOrigCost()
        {
            
                    
            // Set the OrigCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.OrigCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.OrigCostSpecified) {
                								
                // If the OrigCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.OrigCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.OrigCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // OrigCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.OrigCost.Text = POITView.OrigCost.Format(POITView.OrigCost.DefaultValue);
            		
            }
            
            // If the OrigCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.OrigCost.Text == null ||
                this.OrigCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.OrigCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetOrigECM()
        {
            
                    
            // Set the OrigECM Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.OrigECM is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.OrigECMSpecified) {
                								
                // If the OrigECM is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.OrigECM);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.OrigECM.Text = formattedValue;
                   
            } 
            
            else {
            
                // OrigECM is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.OrigECM.Text = POITView.OrigECM.Format(POITView.OrigECM.DefaultValue);
            		
            }
            
            // If the OrigECM is NULL or blank, then use the value specified  
            // on Properties.
            if (this.OrigECM.Text == null ||
                this.OrigECM.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.OrigECM.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetOrigTax()
        {
            
                    
            // Set the OrigTax Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.OrigTax is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.OrigTaxSpecified) {
                								
                // If the OrigTax is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.OrigTax);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.OrigTax.Text = formattedValue;
                   
            } 
            
            else {
            
                // OrigTax is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.OrigTax.Text = POITView.OrigTax.Format(POITView.OrigTax.DefaultValue);
            		
            }
            
            // If the OrigTax is NULL or blank, then use the value specified  
            // on Properties.
            if (this.OrigTax.Text == null ||
                this.OrigTax.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.OrigTax.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetOrigUnitCost()
        {
            
                    
            // Set the OrigUnitCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.OrigUnitCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.OrigUnitCostSpecified) {
                								
                // If the OrigUnitCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.OrigUnitCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.OrigUnitCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // OrigUnitCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.OrigUnitCost.Text = POITView.OrigUnitCost.Format(POITView.OrigUnitCost.DefaultValue);
            		
            }
            
            // If the OrigUnitCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.OrigUnitCost.Text == null ||
                this.OrigUnitCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.OrigUnitCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetOrigUnits()
        {
            
                    
            // Set the OrigUnits Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.OrigUnits is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.OrigUnitsSpecified) {
                								
                // If the OrigUnits is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.OrigUnits);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.OrigUnits.Text = formattedValue;
                   
            } 
            
            else {
            
                // OrigUnits is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.OrigUnits.Text = POITView.OrigUnits.Format(POITView.OrigUnits.DefaultValue);
            		
            }
            
            // If the OrigUnits is NULL or blank, then use the value specified  
            // on Properties.
            if (this.OrigUnits.Text == null ||
                this.OrigUnits.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.OrigUnits.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPayCategory()
        {
            
                    
            // Set the PayCategory Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.PayCategory is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PayCategorySpecified) {
                								
                // If the PayCategory is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.PayCategory);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PayCategory.Text = formattedValue;
                   
            } 
            
            else {
            
                // PayCategory is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PayCategory.Text = POITView.PayCategory.Format(POITView.PayCategory.DefaultValue);
            		
            }
            
            // If the PayCategory is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PayCategory.Text == null ||
                this.PayCategory.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PayCategory.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPayType()
        {
            
                    
            // Set the PayType Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.PayType is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PayTypeSpecified) {
                								
                // If the PayType is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.PayType);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PayType.Text = formattedValue;
                   
            } 
            
            else {
            
                // PayType is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PayType.Text = POITView.PayType.Format(POITView.PayType.DefaultValue);
            		
            }
            
            // If the PayType is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PayType.Text == null ||
                this.PayType.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PayType.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPhase()
        {
            
                    
            // Set the Phase Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Phase is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PhaseSpecified) {
                								
                // If the Phase is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Phase);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Phase.Text = formattedValue;
                   
            } 
            
            else {
            
                // Phase is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Phase.Text = POITView.Phase.Format(POITView.Phase.DefaultValue);
            		
            }
            
            // If the Phase is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Phase.Text == null ||
                this.Phase.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Phase.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPhaseGroup()
        {
            
                    
            // Set the PhaseGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.PhaseGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PhaseGroupSpecified) {
                								
                // If the PhaseGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.PhaseGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PhaseGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // PhaseGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PhaseGroup.Text = POITView.PhaseGroup.Format(POITView.PhaseGroup.DefaultValue);
            		
            }
            
            // If the PhaseGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PhaseGroup.Text == null ||
                this.PhaseGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PhaseGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPO()
        {
            
                    
            // Set the PO Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.PO is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POSpecified) {
                								
                // If the PO is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.PO);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PO.Text = formattedValue;
                   
            } 
            
            else {
            
                // PO is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PO.Text = POITView.PO.Format(POITView.PO.DefaultValue);
            		
            }
            
            // If the PO is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PO.Text == null ||
                this.PO.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PO.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOCo()
        {
            
                    
            // Set the POCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.POCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCoSpecified) {
                								
                // If the POCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.POCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // POCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POCo.Text = POITView.POCo.Format(POITView.POCo.DefaultValue);
            		
            }
            
            // If the POCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POCo.Text == null ||
                this.POCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPOItem()
        {
            
                    
            // Set the POItem Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.POItem is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POItemSpecified) {
                								
                // If the POItem is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.POItem);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.POItem.Text = formattedValue;
                   
            } 
            
            else {
            
                // POItem is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POItem.Text = POITView.POItem.Format(POITView.POItem.DefaultValue);
            		
            }
            
            // If the POItem is NULL or blank, then use the value specified  
            // on Properties.
            if (this.POItem.Text == null ||
                this.POItem.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.POItem.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPostedDate()
        {
            
                    
            // Set the PostedDate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.PostedDate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PostedDateSpecified) {
                								
                // If the PostedDate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.PostedDate, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PostedDate.Text = formattedValue;
                   
            } 
            
            else {
            
                // PostedDate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PostedDate.Text = POITView.PostedDate.Format(POITView.PostedDate.DefaultValue, @"g");
            		
            }
            
            // If the PostedDate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PostedDate.Text == null ||
                this.PostedDate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PostedDate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetPostToCo()
        {
            
                    
            // Set the PostToCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.PostToCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PostToCoSpecified) {
                								
                // If the PostToCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.PostToCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.PostToCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // PostToCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PostToCo.Text = POITView.PostToCo.Format(POITView.PostToCo.DefaultValue);
            		
            }
            
            // If the PostToCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.PostToCo.Text == null ||
                this.PostToCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.PostToCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetRecvdCost()
        {
            
                    
            // Set the RecvdCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.RecvdCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.RecvdCostSpecified) {
                								
                // If the RecvdCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.RecvdCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.RecvdCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // RecvdCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.RecvdCost.Text = POITView.RecvdCost.Format(POITView.RecvdCost.DefaultValue);
            		
            }
            
            // If the RecvdCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.RecvdCost.Text == null ||
                this.RecvdCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.RecvdCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetRecvdUnits()
        {
            
                    
            // Set the RecvdUnits Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.RecvdUnits is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.RecvdUnitsSpecified) {
                								
                // If the RecvdUnits is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.RecvdUnits);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.RecvdUnits.Text = formattedValue;
                   
            } 
            
            else {
            
                // RecvdUnits is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.RecvdUnits.Text = POITView.RecvdUnits.Format(POITView.RecvdUnits.DefaultValue);
            		
            }
            
            // If the RecvdUnits is NULL or blank, then use the value specified  
            // on Properties.
            if (this.RecvdUnits.Text == null ||
                this.RecvdUnits.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.RecvdUnits.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetRecvYN()
        {
            
                    
            // Set the RecvYN Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.RecvYN is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.RecvYNSpecified) {
                								
                // If the RecvYN is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.RecvYN);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.RecvYN.Text = formattedValue;
                   
            } 
            
            else {
            
                // RecvYN is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.RecvYN.Text = POITView.RecvYN.Format(POITView.RecvYN.DefaultValue);
            		
            }
            
            // If the RecvYN is NULL or blank, then use the value specified  
            // on Properties.
            if (this.RecvYN.Text == null ||
                this.RecvYN.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.RecvYN.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetRemCost()
        {
            
                    
            // Set the RemCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.RemCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.RemCostSpecified) {
                								
                // If the RemCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.RemCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.RemCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // RemCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.RemCost.Text = POITView.RemCost.Format(POITView.RemCost.DefaultValue);
            		
            }
            
            // If the RemCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.RemCost.Text == null ||
                this.RemCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.RemCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetRemTax()
        {
            
                    
            // Set the RemTax Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.RemTax is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.RemTaxSpecified) {
                								
                // If the RemTax is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.RemTax);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.RemTax.Text = formattedValue;
                   
            } 
            
            else {
            
                // RemTax is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.RemTax.Text = POITView.RemTax.Format(POITView.RemTax.DefaultValue);
            		
            }
            
            // If the RemTax is NULL or blank, then use the value specified  
            // on Properties.
            if (this.RemTax.Text == null ||
                this.RemTax.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.RemTax.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetRemUnits()
        {
            
                    
            // Set the RemUnits Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.RemUnits is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.RemUnitsSpecified) {
                								
                // If the RemUnits is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.RemUnits);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.RemUnits.Text = formattedValue;
                   
            } 
            
            else {
            
                // RemUnits is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.RemUnits.Text = POITView.RemUnits.Format(POITView.RemUnits.DefaultValue);
            		
            }
            
            // If the RemUnits is NULL or blank, then use the value specified  
            // on Properties.
            if (this.RemUnits.Text == null ||
                this.RemUnits.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.RemUnits.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetReqDate()
        {
            
                    
            // Set the ReqDate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.ReqDate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ReqDateSpecified) {
                								
                // If the ReqDate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.ReqDate, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.ReqDate.Text = formattedValue;
                   
            } 
            
            else {
            
                // ReqDate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.ReqDate.Text = POITView.ReqDate.Format(POITView.ReqDate.DefaultValue, @"g");
            		
            }
            
            // If the ReqDate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.ReqDate.Text == null ||
                this.ReqDate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.ReqDate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetRequisitionNum()
        {
            
                    
            // Set the RequisitionNum Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.RequisitionNum is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.RequisitionNumSpecified) {
                								
                // If the RequisitionNum is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.RequisitionNum);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.RequisitionNum.Text = formattedValue;
                   
            } 
            
            else {
            
                // RequisitionNum is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.RequisitionNum.Text = POITView.RequisitionNum.Format(POITView.RequisitionNum.DefaultValue);
            		
            }
            
            // If the RequisitionNum is NULL or blank, then use the value specified  
            // on Properties.
            if (this.RequisitionNum.Text == null ||
                this.RequisitionNum.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.RequisitionNum.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSMCo()
        {
            
                    
            // Set the SMCo Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.SMCo is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SMCoSpecified) {
                								
                // If the SMCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.SMCo);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SMCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // SMCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SMCo.Text = POITView.SMCo.Format(POITView.SMCo.DefaultValue);
            		
            }
            
            // If the SMCo is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SMCo.Text == null ||
                this.SMCo.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SMCo.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSMJCCostType()
        {
            
                    
            // Set the SMJCCostType Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.SMJCCostType is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SMJCCostTypeSpecified) {
                								
                // If the SMJCCostType is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.SMJCCostType);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SMJCCostType.Text = formattedValue;
                   
            } 
            
            else {
            
                // SMJCCostType is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SMJCCostType.Text = POITView.SMJCCostType.Format(POITView.SMJCCostType.DefaultValue);
            		
            }
            
            // If the SMJCCostType is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SMJCCostType.Text == null ||
                this.SMJCCostType.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SMJCCostType.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSMPhase()
        {
            
                    
            // Set the SMPhase Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.SMPhase is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SMPhaseSpecified) {
                								
                // If the SMPhase is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.SMPhase);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SMPhase.Text = formattedValue;
                   
            } 
            
            else {
            
                // SMPhase is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SMPhase.Text = POITView.SMPhase.Format(POITView.SMPhase.DefaultValue);
            		
            }
            
            // If the SMPhase is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SMPhase.Text == null ||
                this.SMPhase.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SMPhase.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSMPhaseGroup()
        {
            
                    
            // Set the SMPhaseGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.SMPhaseGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SMPhaseGroupSpecified) {
                								
                // If the SMPhaseGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.SMPhaseGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SMPhaseGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // SMPhaseGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SMPhaseGroup.Text = POITView.SMPhaseGroup.Format(POITView.SMPhaseGroup.DefaultValue);
            		
            }
            
            // If the SMPhaseGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SMPhaseGroup.Text == null ||
                this.SMPhaseGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SMPhaseGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSMScope()
        {
            
                    
            // Set the SMScope Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.SMScope is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SMScopeSpecified) {
                								
                // If the SMScope is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.SMScope);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SMScope.Text = formattedValue;
                   
            } 
            
            else {
            
                // SMScope is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SMScope.Text = POITView.SMScope.Format(POITView.SMScope.DefaultValue);
            		
            }
            
            // If the SMScope is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SMScope.Text == null ||
                this.SMScope.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SMScope.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSMWorkOrder()
        {
            
                    
            // Set the SMWorkOrder Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.SMWorkOrder is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SMWorkOrderSpecified) {
                								
                // If the SMWorkOrder is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.SMWorkOrder);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SMWorkOrder.Text = formattedValue;
                   
            } 
            
            else {
            
                // SMWorkOrder is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SMWorkOrder.Text = POITView.SMWorkOrder.Format(POITView.SMWorkOrder.DefaultValue);
            		
            }
            
            // If the SMWorkOrder is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SMWorkOrder.Text == null ||
                this.SMWorkOrder.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SMWorkOrder.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSupplier()
        {
            
                    
            // Set the Supplier Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.Supplier is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SupplierSpecified) {
                								
                // If the Supplier is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.Supplier);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Supplier.Text = formattedValue;
                   
            } 
            
            else {
            
                // Supplier is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Supplier.Text = POITView.Supplier.Format(POITView.Supplier.DefaultValue);
            		
            }
            
            // If the Supplier is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Supplier.Text == null ||
                this.Supplier.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Supplier.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetSupplierGroup()
        {
            
                    
            // Set the SupplierGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.SupplierGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SupplierGroupSpecified) {
                								
                // If the SupplierGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.SupplierGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.SupplierGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // SupplierGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SupplierGroup.Text = POITView.SupplierGroup.Format(POITView.SupplierGroup.DefaultValue);
            		
            }
            
            // If the SupplierGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.SupplierGroup.Text == null ||
                this.SupplierGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.SupplierGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetTaxCode()
        {
            
                    
            // Set the TaxCode Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.TaxCode is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.TaxCodeSpecified) {
                								
                // If the TaxCode is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.TaxCode);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.TaxCode.Text = formattedValue;
                   
            } 
            
            else {
            
                // TaxCode is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.TaxCode.Text = POITView.TaxCode.Format(POITView.TaxCode.DefaultValue);
            		
            }
            
            // If the TaxCode is NULL or blank, then use the value specified  
            // on Properties.
            if (this.TaxCode.Text == null ||
                this.TaxCode.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.TaxCode.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetTaxGroup()
        {
            
                    
            // Set the TaxGroup Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.TaxGroup is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.TaxGroupSpecified) {
                								
                // If the TaxGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.TaxGroup);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.TaxGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // TaxGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.TaxGroup.Text = POITView.TaxGroup.Format(POITView.TaxGroup.DefaultValue);
            		
            }
            
            // If the TaxGroup is NULL or blank, then use the value specified  
            // on Properties.
            if (this.TaxGroup.Text == null ||
                this.TaxGroup.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.TaxGroup.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetTaxRate()
        {
            
                    
            // Set the TaxRate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.TaxRate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.TaxRateSpecified) {
                								
                // If the TaxRate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.TaxRate);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.TaxRate.Text = formattedValue;
                   
            } 
            
            else {
            
                // TaxRate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.TaxRate.Text = POITView.TaxRate.Format(POITView.TaxRate.DefaultValue);
            		
            }
            
            // If the TaxRate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.TaxRate.Text == null ||
                this.TaxRate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.TaxRate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetTaxType()
        {
            
                    
            // Set the TaxType Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.TaxType is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.TaxTypeSpecified) {
                								
                // If the TaxType is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.TaxType);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.TaxType.Text = formattedValue;
                   
            } 
            
            else {
            
                // TaxType is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.TaxType.Text = POITView.TaxType.Format(POITView.TaxType.DefaultValue);
            		
            }
            
            // If the TaxType is NULL or blank, then use the value specified  
            // on Properties.
            if (this.TaxType.Text == null ||
                this.TaxType.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.TaxType.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetTotalCost()
        {
            
                    
            // Set the TotalCost Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.TotalCost is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.TotalCostSpecified) {
                								
                // If the TotalCost is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.TotalCost);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.TotalCost.Text = formattedValue;
                   
            } 
            
            else {
            
                // TotalCost is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.TotalCost.Text = POITView.TotalCost.Format(POITView.TotalCost.DefaultValue);
            		
            }
            
            // If the TotalCost is NULL or blank, then use the value specified  
            // on Properties.
            if (this.TotalCost.Text == null ||
                this.TotalCost.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.TotalCost.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetTotalTax()
        {
            
                    
            // Set the TotalTax Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.TotalTax is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.TotalTaxSpecified) {
                								
                // If the TotalTax is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.TotalTax);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.TotalTax.Text = formattedValue;
                   
            } 
            
            else {
            
                // TotalTax is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.TotalTax.Text = POITView.TotalTax.Format(POITView.TotalTax.DefaultValue);
            		
            }
            
            // If the TotalTax is NULL or blank, then use the value specified  
            // on Properties.
            if (this.TotalTax.Text == null ||
                this.TotalTax.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.TotalTax.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetTotalUnits()
        {
            
                    
            // Set the TotalUnits Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.TotalUnits is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.TotalUnitsSpecified) {
                								
                // If the TotalUnits is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.TotalUnits);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.TotalUnits.Text = formattedValue;
                   
            } 
            
            else {
            
                // TotalUnits is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.TotalUnits.Text = POITView.TotalUnits.Format(POITView.TotalUnits.DefaultValue);
            		
            }
            
            // If the TotalUnits is NULL or blank, then use the value specified  
            // on Properties.
            if (this.TotalUnits.Text == null ||
                this.TotalUnits.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.TotalUnits.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudActOffDate()
        {
            
                    
            // Set the udActOffDate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.udActOffDate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udActOffDateSpecified) {
                								
                // If the udActOffDate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.udActOffDate, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udActOffDate.Text = formattedValue;
                   
            } 
            
            else {
            
                // udActOffDate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udActOffDate.Text = POITView.udActOffDate.Format(POITView.udActOffDate.DefaultValue, @"g");
            		
            }
            
            // If the udActOffDate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udActOffDate.Text == null ||
                this.udActOffDate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udActOffDate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudCGCTable()
        {
            
                    
            // Set the udCGCTable Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.udCGCTable is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udCGCTableSpecified) {
                								
                // If the udCGCTable is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.udCGCTable);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udCGCTable.Text = formattedValue;
                   
            } 
            
            else {
            
                // udCGCTable is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udCGCTable.Text = POITView.udCGCTable.Format(POITView.udCGCTable.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.udCGCTableID is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udCGCTableIDSpecified) {
                								
                // If the udCGCTableID is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.udCGCTableID);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udCGCTableID.Text = formattedValue;
                   
            } 
            
            else {
            
                // udCGCTableID is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udCGCTableID.Text = POITView.udCGCTableID.Format(POITView.udCGCTableID.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.udConv is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udConvSpecified) {
                								
                // If the udConv is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.udConv);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udConv.Text = formattedValue;
                   
            } 
            
            else {
            
                // udConv is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udConv.Text = POITView.udConv.Format(POITView.udConv.DefaultValue);
            		
            }
            
            // If the udConv is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udConv.Text == null ||
                this.udConv.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udConv.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudOnDate()
        {
            
                    
            // Set the udOnDate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.udOnDate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udOnDateSpecified) {
                								
                // If the udOnDate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.udOnDate, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udOnDate.Text = formattedValue;
                   
            } 
            
            else {
            
                // udOnDate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udOnDate.Text = POITView.udOnDate.Format(POITView.udOnDate.DefaultValue, @"g");
            		
            }
            
            // If the udOnDate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udOnDate.Text == null ||
                this.udOnDate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udOnDate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudPlnOffDate()
        {
            
                    
            // Set the udPlnOffDate Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.udPlnOffDate is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udPlnOffDateSpecified) {
                								
                // If the udPlnOffDate is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.udPlnOffDate, @"g");
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udPlnOffDate.Text = formattedValue;
                   
            } 
            
            else {
            
                // udPlnOffDate is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udPlnOffDate.Text = POITView.udPlnOffDate.Format(POITView.udPlnOffDate.DefaultValue, @"g");
            		
            }
            
            // If the udPlnOffDate is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udPlnOffDate.Text == null ||
                this.udPlnOffDate.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udPlnOffDate.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudRentalNum()
        {
            
                    
            // Set the udRentalNum Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.udRentalNum is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udRentalNumSpecified) {
                								
                // If the udRentalNum is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.udRentalNum);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udRentalNum.Text = formattedValue;
                   
            } 
            
            else {
            
                // udRentalNum is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udRentalNum.Text = POITView.udRentalNum.Format(POITView.udRentalNum.DefaultValue);
            		
            }
            
            // If the udRentalNum is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udRentalNum.Text == null ||
                this.udRentalNum.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udRentalNum.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetudSource()
        {
            
                    
            // Set the udSource Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.udSource is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.udSourceSpecified) {
                								
                // If the udSource is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.udSource);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.udSource.Text = formattedValue;
                   
            } 
            
            else {
            
                // udSource is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.udSource.Text = POITView.udSource.Format(POITView.udSource.DefaultValue);
            		
            }
            
            // If the udSource is NULL or blank, then use the value specified  
            // on Properties.
            if (this.udSource.Text == null ||
                this.udSource.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.udSource.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetUM()
        {
            
                    
            // Set the UM Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.UM is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.UMSpecified) {
                								
                // If the UM is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.UM);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.UM.Text = formattedValue;
                   
            } 
            
            else {
            
                // UM is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.UM.Text = POITView.UM.Format(POITView.UM.DefaultValue);
            		
            }
            
            // If the UM is NULL or blank, then use the value specified  
            // on Properties.
            if (this.UM.Text == null ||
                this.UM.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.UM.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVendMatId()
        {
            
                    
            // Set the VendMatId Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.VendMatId is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VendMatIdSpecified) {
                								
                // If the VendMatId is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.VendMatId);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VendMatId.Text = formattedValue;
                   
            } 
            
            else {
            
                // VendMatId is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VendMatId.Text = POITView.VendMatId.Format(POITView.VendMatId.DefaultValue);
            		
            }
            
            // If the VendMatId is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VendMatId.Text == null ||
                this.VendMatId.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VendMatId.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetWO()
        {
            
                    
            // Set the WO Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.WO is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.WOSpecified) {
                								
                // If the WO is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.WO);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.WO.Text = formattedValue;
                   
            } 
            
            else {
            
                // WO is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.WO.Text = POITView.WO.Format(POITView.WO.DefaultValue);
            		
            }
            
            // If the WO is NULL or blank, then use the value specified  
            // on Properties.
            if (this.WO.Text == null ||
                this.WO.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.WO.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetWOItem()
        {
            
                    
            // Set the WOItem Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.POIT database record.

            // this.DataSource is the DatabaseViewpoint%dbo.POIT record retrieved from the database.
            // this.WOItem is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.WOItemSpecified) {
                								
                // If the WOItem is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(POITView.WOItem);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.WOItem.Text = formattedValue;
                   
            } 
            
            else {
            
                // WOItem is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.WOItem.Text = POITView.WOItem.Format(POITView.WOItem.DefaultValue);
            		
            }
            
            // If the WOItem is NULL or blank, then use the value specified  
            // on Properties.
            if (this.WOItem.Text == null ||
                this.WOItem.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.WOItem.Text = "&nbsp;";
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
                ((POITTableControl)MiscUtils.GetParentControlObject(this, "POITTableControl")).DataChanged = true;
                ((POITTableControl)MiscUtils.GetParentControlObject(this, "POITTableControl")).ResetData = true;
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
            GetBOCost();
            GetBOUnits();
            GetComponent();
            GetCompType();
            GetCostCode();
            GetCurCost();
            GetCurECM();
            GetCurTax();
            GetCurUnitCost();
            GetCurUnits();
            GetDescription();
            GetEMCo();
            GetEMCType();
            GetEMGroup();
            GetEquip();
            GetGLAcct();
            GetGLCo();
            GetGSTRate();
            GetINCo();
            GetInUseBatchId();
            GetInUseMth();
            GetInvCost();
            GetInvMiscAmt();
            GetInvTax();
            GetInvUnits();
            GetItemType();
            GetJCCmtdTax();
            GetJCCo();
            GetJCCType();
            GetJCRemCmtdTax();
            GetJob();
            GetLoc();
            GetMaterial();
            GetMatlGroup();
            GetNotes();
            GetOrigCost();
            GetOrigECM();
            GetOrigTax();
            GetOrigUnitCost();
            GetOrigUnits();
            GetPayCategory();
            GetPayType();
            GetPhase();
            GetPhaseGroup();
            GetPO();
            GetPOCo();
            GetPOItem();
            GetPostedDate();
            GetPostToCo();
            GetRecvdCost();
            GetRecvdUnits();
            GetRecvYN();
            GetRemCost();
            GetRemTax();
            GetRemUnits();
            GetReqDate();
            GetRequisitionNum();
            GetSMCo();
            GetSMJCCostType();
            GetSMPhase();
            GetSMPhaseGroup();
            GetSMScope();
            GetSMWorkOrder();
            GetSupplier();
            GetSupplierGroup();
            GetTaxCode();
            GetTaxGroup();
            GetTaxRate();
            GetTaxType();
            GetTotalCost();
            GetTotalTax();
            GetTotalUnits();
            GetudActOffDate();
            GetudCGCTable();
            GetudCGCTableID();
            GetudConv();
            GetudOnDate();
            GetudPlnOffDate();
            GetudRentalNum();
            GetudSource();
            GetUM();
            GetVendMatId();
            GetWO();
            GetWOItem();
        }
        
        
        public virtual void GetAddedBatchID()
        {
            
        }
                
        public virtual void GetAddedMth()
        {
            
        }
                
        public virtual void GetBOCost()
        {
            
        }
                
        public virtual void GetBOUnits()
        {
            
        }
                
        public virtual void GetComponent()
        {
            
        }
                
        public virtual void GetCompType()
        {
            
        }
                
        public virtual void GetCostCode()
        {
            
        }
                
        public virtual void GetCurCost()
        {
            
        }
                
        public virtual void GetCurECM()
        {
            
        }
                
        public virtual void GetCurTax()
        {
            
        }
                
        public virtual void GetCurUnitCost()
        {
            
        }
                
        public virtual void GetCurUnits()
        {
            
        }
                
        public virtual void GetDescription()
        {
            
        }
                
        public virtual void GetEMCo()
        {
            
        }
                
        public virtual void GetEMCType()
        {
            
        }
                
        public virtual void GetEMGroup()
        {
            
        }
                
        public virtual void GetEquip()
        {
            
        }
                
        public virtual void GetGLAcct()
        {
            
        }
                
        public virtual void GetGLCo()
        {
            
        }
                
        public virtual void GetGSTRate()
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
                
        public virtual void GetInvCost()
        {
            
        }
                
        public virtual void GetInvMiscAmt()
        {
            
        }
                
        public virtual void GetInvTax()
        {
            
        }
                
        public virtual void GetInvUnits()
        {
            
        }
                
        public virtual void GetItemType()
        {
            
        }
                
        public virtual void GetJCCmtdTax()
        {
            
        }
                
        public virtual void GetJCCo()
        {
            
        }
                
        public virtual void GetJCCType()
        {
            
        }
                
        public virtual void GetJCRemCmtdTax()
        {
            
        }
                
        public virtual void GetJob()
        {
            
        }
                
        public virtual void GetLoc()
        {
            
        }
                
        public virtual void GetMaterial()
        {
            
        }
                
        public virtual void GetMatlGroup()
        {
            
        }
                
        public virtual void GetNotes()
        {
            
        }
                
        public virtual void GetOrigCost()
        {
            
        }
                
        public virtual void GetOrigECM()
        {
            
        }
                
        public virtual void GetOrigTax()
        {
            
        }
                
        public virtual void GetOrigUnitCost()
        {
            
        }
                
        public virtual void GetOrigUnits()
        {
            
        }
                
        public virtual void GetPayCategory()
        {
            
        }
                
        public virtual void GetPayType()
        {
            
        }
                
        public virtual void GetPhase()
        {
            
        }
                
        public virtual void GetPhaseGroup()
        {
            
        }
                
        public virtual void GetPO()
        {
            
        }
                
        public virtual void GetPOCo()
        {
            
        }
                
        public virtual void GetPOItem()
        {
            
        }
                
        public virtual void GetPostedDate()
        {
            
        }
                
        public virtual void GetPostToCo()
        {
            
        }
                
        public virtual void GetRecvdCost()
        {
            
        }
                
        public virtual void GetRecvdUnits()
        {
            
        }
                
        public virtual void GetRecvYN()
        {
            
        }
                
        public virtual void GetRemCost()
        {
            
        }
                
        public virtual void GetRemTax()
        {
            
        }
                
        public virtual void GetRemUnits()
        {
            
        }
                
        public virtual void GetReqDate()
        {
            
        }
                
        public virtual void GetRequisitionNum()
        {
            
        }
                
        public virtual void GetSMCo()
        {
            
        }
                
        public virtual void GetSMJCCostType()
        {
            
        }
                
        public virtual void GetSMPhase()
        {
            
        }
                
        public virtual void GetSMPhaseGroup()
        {
            
        }
                
        public virtual void GetSMScope()
        {
            
        }
                
        public virtual void GetSMWorkOrder()
        {
            
        }
                
        public virtual void GetSupplier()
        {
            
        }
                
        public virtual void GetSupplierGroup()
        {
            
        }
                
        public virtual void GetTaxCode()
        {
            
        }
                
        public virtual void GetTaxGroup()
        {
            
        }
                
        public virtual void GetTaxRate()
        {
            
        }
                
        public virtual void GetTaxType()
        {
            
        }
                
        public virtual void GetTotalCost()
        {
            
        }
                
        public virtual void GetTotalTax()
        {
            
        }
                
        public virtual void GetTotalUnits()
        {
            
        }
                
        public virtual void GetudActOffDate()
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
                
        public virtual void GetudOnDate()
        {
            
        }
                
        public virtual void GetudPlnOffDate()
        {
            
        }
                
        public virtual void GetudRentalNum()
        {
            
        }
                
        public virtual void GetudSource()
        {
            
        }
                
        public virtual void GetUM()
        {
            
        }
                
        public virtual void GetVendMatId()
        {
            
        }
                
        public virtual void GetWO()
        {
            
        }
                
        public virtual void GetWOItem()
        {
            
        }
                

      // To customize, override this method in POITTableControlRow.
      
        public virtual WhereClause CreateWhereClause()
         
        {
//Bryan Check
    
            bool hasFiltersPOITTableControl = false;
            hasFiltersPOITTableControl = hasFiltersPOITTableControl && false; // suppress warning
      
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
  

        
        public POITRecord DataSource {
            get {
                return (POITRecord)(this._DataSource);
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
            
        public System.Web.UI.WebControls.Literal BOCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "BOCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal BOUnits {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "BOUnits");
            }
        }
            
        public System.Web.UI.WebControls.Literal Component {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Component");
            }
        }
            
        public System.Web.UI.WebControls.Literal CompType {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CompType");
            }
        }
            
        public System.Web.UI.WebControls.Literal CostCode {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostCode");
            }
        }
            
        public System.Web.UI.WebControls.Literal CurCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal CurECM {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurECM");
            }
        }
            
        public System.Web.UI.WebControls.Literal CurTax {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurTax");
            }
        }
            
        public System.Web.UI.WebControls.Literal CurUnitCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurUnitCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal CurUnits {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurUnits");
            }
        }
            
        public System.Web.UI.WebControls.Literal Description {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Description");
            }
        }
            
        public System.Web.UI.WebControls.Literal EMCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "EMCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal EMCType {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "EMCType");
            }
        }
            
        public System.Web.UI.WebControls.Literal EMGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "EMGroup");
            }
        }
            
        public System.Web.UI.WebControls.Literal Equip {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Equip");
            }
        }
            
        public System.Web.UI.WebControls.Literal GLAcct {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLAcct");
            }
        }
            
        public System.Web.UI.WebControls.Literal GLCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal GSTRate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GSTRate");
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
            
        public System.Web.UI.WebControls.Literal InvCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InvCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal InvMiscAmt {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InvMiscAmt");
            }
        }
            
        public System.Web.UI.WebControls.Literal InvTax {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InvTax");
            }
        }
            
        public System.Web.UI.WebControls.Literal InvUnits {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InvUnits");
            }
        }
            
        public System.Web.UI.WebControls.Literal ItemType {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ItemType");
            }
        }
            
        public System.Web.UI.WebControls.Literal JCCmtdTax {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCCmtdTax");
            }
        }
            
        public System.Web.UI.WebControls.Literal JCCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal JCCType {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCCType");
            }
        }
            
        public System.Web.UI.WebControls.Literal JCRemCmtdTax {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCRemCmtdTax");
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
            
        public System.Web.UI.WebControls.Literal Material {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Material");
            }
        }
            
        public System.Web.UI.WebControls.Literal MatlGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MatlGroup");
            }
        }
            
        public System.Web.UI.WebControls.Literal Notes {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Notes");
            }
        }
            
        public System.Web.UI.WebControls.Literal OrigCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal OrigECM {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigECM");
            }
        }
            
        public System.Web.UI.WebControls.Literal OrigTax {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigTax");
            }
        }
            
        public System.Web.UI.WebControls.Literal OrigUnitCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigUnitCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal OrigUnits {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigUnits");
            }
        }
            
        public System.Web.UI.WebControls.Literal PayCategory {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PayCategory");
            }
        }
            
        public System.Web.UI.WebControls.Literal PayType {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PayType");
            }
        }
            
        public System.Web.UI.WebControls.Literal Phase {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Phase");
            }
        }
            
        public System.Web.UI.WebControls.Literal PhaseGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PhaseGroup");
            }
        }
            
        public System.Web.UI.WebControls.Literal PO {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PO");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal POItem {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POItem");
            }
        }
            
        public System.Web.UI.WebControls.Literal PostedDate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PostedDate");
            }
        }
            
        public System.Web.UI.WebControls.Literal PostToCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PostToCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal RecvdCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RecvdCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal RecvdUnits {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RecvdUnits");
            }
        }
            
        public System.Web.UI.WebControls.Literal RecvYN {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RecvYN");
            }
        }
            
        public System.Web.UI.WebControls.Literal RemCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RemCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal RemTax {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RemTax");
            }
        }
            
        public System.Web.UI.WebControls.Literal RemUnits {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RemUnits");
            }
        }
            
        public System.Web.UI.WebControls.Literal ReqDate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ReqDate");
            }
        }
            
        public System.Web.UI.WebControls.Literal RequisitionNum {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RequisitionNum");
            }
        }
            
        public System.Web.UI.WebControls.Literal SMCo {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal SMJCCostType {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMJCCostType");
            }
        }
            
        public System.Web.UI.WebControls.Literal SMPhase {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMPhase");
            }
        }
            
        public System.Web.UI.WebControls.Literal SMPhaseGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMPhaseGroup");
            }
        }
            
        public System.Web.UI.WebControls.Literal SMScope {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMScope");
            }
        }
            
        public System.Web.UI.WebControls.Literal SMWorkOrder {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMWorkOrder");
            }
        }
            
        public System.Web.UI.WebControls.Literal Supplier {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Supplier");
            }
        }
            
        public System.Web.UI.WebControls.Literal SupplierGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SupplierGroup");
            }
        }
            
        public System.Web.UI.WebControls.Literal TaxCode {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TaxCode");
            }
        }
            
        public System.Web.UI.WebControls.Literal TaxGroup {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TaxGroup");
            }
        }
            
        public System.Web.UI.WebControls.Literal TaxRate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TaxRate");
            }
        }
            
        public System.Web.UI.WebControls.Literal TaxType {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TaxType");
            }
        }
            
        public System.Web.UI.WebControls.Literal TotalCost {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TotalCost");
            }
        }
            
        public System.Web.UI.WebControls.Literal TotalTax {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TotalTax");
            }
        }
            
        public System.Web.UI.WebControls.Literal TotalUnits {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TotalUnits");
            }
        }
            
        public System.Web.UI.WebControls.Literal udActOffDate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udActOffDate");
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
            
        public System.Web.UI.WebControls.Literal udOnDate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udOnDate");
            }
        }
            
        public System.Web.UI.WebControls.Literal udPlnOffDate {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPlnOffDate");
            }
        }
            
        public System.Web.UI.WebControls.Literal udRentalNum {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udRentalNum");
            }
        }
            
        public System.Web.UI.WebControls.Literal udSource {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udSource");
            }
        }
            
        public System.Web.UI.WebControls.Literal UM {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "UM");
            }
        }
            
        public System.Web.UI.WebControls.Literal VendMatId {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VendMatId");
            }
        }
            
        public System.Web.UI.WebControls.Literal WO {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "WO");
            }
        }
            
        public System.Web.UI.WebControls.Literal WOItem {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "WOItem");
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
    POITRecord rec = null;
             
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
    POITRecord rec = null;
    
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

    
        public virtual POITRecord GetRecord()
             
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

  
// Base class for the POITTableControl control on the Show_POIT_Table page.
// Do not modify this class. Instead override any method in POITTableControl.
public class BasePOITTableControl : POViewer.UI.BaseApplicationTableControl
{
         

       public BasePOITTableControl()
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
                if  (this.InSession(this.CompTypeFilter)) 				
                    initialVal = this.GetFromSession(this.CompTypeFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"CompType\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    string[] CompTypeFilteritemListFromSession = initialVal.Split(',');
                    int index = 0;
                    foreach (string item in CompTypeFilteritemListFromSession)
                    {
                        if (index == 0 && item.ToString().Equals(""))
                        {
                            // do nothing
                        }
                        else
                        {
                            this.CompTypeFilter.Items.Add(item);
                            this.CompTypeFilter.Items[index].Selected = true;
                            index += 1;
                        }
                    }
                    foreach (ListItem listItem in this.CompTypeFilter.Items)
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
          
              this.AddedBatchIDLabel.Click += AddedBatchIDLabel_Click;
            
              this.AddedMthLabel.Click += AddedMthLabel_Click;
            
              this.BOCostLabel.Click += BOCostLabel_Click;
            
              this.InUseMthLabel.Click += InUseMthLabel_Click;
            
              this.POLabel.Click += POLabel_Click;
            
              this.PostedDateLabel.Click += PostedDateLabel_Click;
            
              this.ReqDateLabel.Click += ReqDateLabel_Click;
            
              this.udActOffDateLabel.Click += udActOffDateLabel_Click;
            
              this.udOnDateLabel.Click += udOnDateLabel_Click;
            
              this.udPlnOffDateLabel.Click += udPlnOffDateLabel_Click;
            
            // Setup the button events.
          
                    this.ExcelButton.Click += ExcelButton_Click;
                        
                    this.PDFButton.Click += PDFButton_Click;
                        
                    this.ResetButton.Click += ResetButton_Click;
                        
                    this.SearchButton.Click += SearchButton_Click;
                        
                    this.WordButton.Click += WordButton_Click;
                        
                    this.ActionsButton.Button.Click += ActionsButton_Click;
                        
                    this.FilterButton.Button.Click += FilterButton_Click;
                        
                    this.FiltersButton.Button.Click += FiltersButton_Click;
                        
              this.CompTypeFilter.SelectedIndexChanged += CompTypeFilter_SelectedIndexChanged;                  
                        
        
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
                      Type myrec = typeof(POViewer.Business.POITRecord);
                      this.DataSource = (POITRecord[])(alist.ToArray(myrec));
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
                    foreach (POITTableControlRow rc in this.GetRecordControls()) {
                        if (!rc.IsNewRecord) {
                            rc.DataSource = rc.GetRecord();
                            rc.GetUIData();
                            postdata.Add(rc.DataSource);
                            UIData.Add(rc.PreservedUIData());
                        }
                    }
                    Type myrec = typeof(POViewer.Business.POITRecord);
                    this.DataSource = (POITRecord[])(postdata.ToArray(myrec));
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
        
        public virtual POITRecord[] GetRecords(BaseFilter join, WhereClause where, OrderBy orderBy, int pageIndex, int pageSize)
        {    
            // by default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               
    
            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecordCount as well
            // selCols.Add(POITView.Column1, true);          
            // selCols.Add(POITView.Column2, true);          
            // selCols.Add(POITView.Column3, true);          
            

            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                  
            {
              
                return POITView.GetRecords(join, where, orderBy, this.PageIndex, this.PageSize);
                 
            }
            else
            {
                POITView databaseTable = new POITView();
                databaseTable.SelectedColumns.Clear();
                databaseTable.SelectedColumns.AddRange(selCols);
                
                // Stored Procedures provided by Iron Speed Designer specifies to query all columns, in order to query a subset of columns, it is necessary to disable stored procedures
                databaseTable.DataAdapter.DisableStoredProcedures = true; 
                
            
                
                ArrayList recList; 
                orderBy.ExpandForeignKeyColums = false;
                recList = databaseTable.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
                return (recList.ToArray(typeof(POITRecord)) as POITRecord[]);
            }            
            
        }
        
        
        public virtual int GetRecordCount(BaseFilter join, WhereClause where)
        {

            // By default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               


            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecords as well
            // selCols.Add(POITView.Column1, true);          
            // selCols.Add(POITView.Column2, true);          
            // selCols.Add(POITView.Column3, true);          


            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                     
            
                return POITView.GetRecordCount(join, where);
            else
            {
                POITView databaseTable = new POITView();
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
        System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POITTableControlRepeater"));
        if (rep == null){return;}
        rep.DataSource = this.DataSource;
        rep.DataBind();
          
        int index = 0;
        foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
        {
            // Loop through all rows in the table, set its DataSource and call DataBind().
            POITTableControlRow recControl = (POITTableControlRow)(repItem.FindControl("POITTableControlRow"));
            recControl.DataSource = this.DataSource[index];            
            if (this.UIData.Count > index)
                recControl.PreviousUIData = this.UIData[index];
            recControl.DataBind();
            
           
            index++;
        }
           
    
            // Call the Set methods for each controls on the panel
        
                
                SetAddedBatchIDLabel();
                SetAddedMthLabel();
                SetBOCostLabel();
                SetBOUnitsLabel();
                SetComponentLabel();
                SetCompTypeFilter();
                SetCompTypeLabel();
                SetCompTypeLabel1();
                SetCostCodeLabel();
                SetCurCostLabel();
                SetCurECMLabel();
                SetCurTaxLabel();
                SetCurUnitCostLabel();
                SetCurUnitsLabel();
                SetDescriptionLabel();
                SetEMCoLabel();
                SetEMCTypeLabel();
                SetEMGroupLabel();
                SetEquipLabel();
                
                
                
                SetGLAcctLabel();
                SetGLCoLabel();
                SetGSTRateLabel();
                SetINCoLabel();
                SetInUseBatchIdLabel();
                SetInUseMthLabel();
                SetInvCostLabel();
                SetInvMiscAmtLabel();
                SetInvTaxLabel();
                SetInvUnitsLabel();
                SetItemTypeLabel();
                SetJCCmtdTaxLabel();
                SetJCCoLabel();
                SetJCCTypeLabel();
                SetJCRemCmtdTaxLabel();
                SetJobLabel();
                SetLocLabel();
                SetMaterialLabel();
                SetMatlGroupLabel();
                SetNotesLabel();
                SetOrigCostLabel();
                SetOrigECMLabel();
                SetOrigTaxLabel();
                SetOrigUnitCostLabel();
                SetOrigUnitsLabel();
                
                SetPayCategoryLabel();
                SetPayTypeLabel();
                
                SetPhaseGroupLabel();
                SetPhaseLabel();
                SetPOCoLabel();
                SetPOItemLabel();
                SetPOLabel();
                SetPostedDateLabel();
                SetPostToCoLabel();
                SetRecvdCostLabel();
                SetRecvdUnitsLabel();
                SetRecvYNLabel();
                SetRemCostLabel();
                SetRemTaxLabel();
                SetRemUnitsLabel();
                SetReqDateLabel();
                SetRequisitionNumLabel();
                
                
                SetSearchText();
                SetSMCoLabel();
                SetSMJCCostTypeLabel();
                SetSMPhaseGroupLabel();
                SetSMPhaseLabel();
                SetSMScopeLabel();
                SetSMWorkOrderLabel();
                SetSupplierGroupLabel();
                SetSupplierLabel();
                SetTaxCodeLabel();
                SetTaxGroupLabel();
                SetTaxRateLabel();
                SetTaxTypeLabel();
                
                SetTotalCostLabel();
                SetTotalTaxLabel();
                SetTotalUnitsLabel();
                SetudActOffDateLabel();
                SetudCGCTableIDLabel();
                SetudCGCTableLabel();
                SetudConvLabel();
                SetudOnDateLabel();
                SetudPlnOffDateLabel();
                SetudRentalNumLabel();
                SetudSourceLabel();
                SetUMLabel();
                SetVendMatIdLabel();
                SetWOItemLabel();
                SetWOLabel();
                
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


            
            this.CompTypeFilter.ClearSelection();
            
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
    
            // Bind the buttons for POITTableControl pagination.
        
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
              
            foreach (POITTableControlRow recCtl in this.GetRecordControls())
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
            foreach (POITTableControlRow recCtl in this.GetRecordControls()){
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
            POITView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
    
            // CreateWhereClause() Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
        

                          int totalSelectedItemCount = 0;
                          
            if (MiscUtils.IsValueSelected(this.CompTypeFilter)) {
                        
                int selectedItemCount = 0;
                foreach (ListItem item in this.CompTypeFilter.Items){
                    if (item.Selected) {
                        selectedItemCount += 1;
                        
                          totalSelectedItemCount += 1;
                        
                          
                    }
                }
                WhereClause filter = new WhereClause();
                foreach (ListItem item in this.CompTypeFilter.Items){
                    if ((item.Selected) && ((item.Value == "--ANY--") || (item.Value == "--PLEASE_SELECT--")) && (selectedItemCount > 1)){
                        item.Selected = false;
                    }
                    if (item.Selected){
                        filter.iOR(POITView.CompType, BaseFilter.ComparisonOperator.EqualsTo, item.Value, false, false);
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
        
      cols.Add(POITView.Description);
      
      foreach(BaseColumn col in cols)
      {
      
                    search.iOR(col, BaseFilter.ComparisonOperator.Contains, MiscUtils.GetSelectedValue(this.SearchText, this.GetFromSession(this.SearchText)), true, false);
        
      }
    
                    wc.iAND(search);
                  
                }
            }
                  
      if (totalSelectedItemCount > 50)
          throw new Exception(Page.GetResourceValue("Err:SelectedItemOverLimit", "POViewer").Replace("{Limit}", "50").Replace("{SelectedCount}", totalSelectedItemCount.ToString()));
    
            return wc;
        }
        
         
        public virtual WhereClause CreateWhereClause(String searchText, String fromSearchControl, String AutoTypeAheadSearch, String AutoTypeAheadWordSeparators)
        {
            // This CreateWhereClause is used for loading list of suggestions for Auto Type-Ahead feature.
            POITView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
        
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
            String appRelativeVirtualPath = (String)HttpContext.Current.Session["AppRelativeVirtualPath"];
            
            // Adds clauses if values are selected in Filter controls which are configured in the page.
          
      String CompTypeFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "CompTypeFilter_Ajax"];
            if (MiscUtils.IsValueSelected(CompTypeFilterSelectedValue)) {

              
        if (CompTypeFilterSelectedValue != null){
                        string[] CompTypeFilteritemListFromSession = CompTypeFilterSelectedValue.Split(',');
                        int index = 0;
                        WhereClause filter = new WhereClause();
                        foreach (string item in CompTypeFilteritemListFromSession)
                        {
                            if (index == 0 && item.ToString().Equals(""))
                            {
                            }
                            else
                            {
                                filter.iOR(POITView.CompType, BaseFilter.ComparisonOperator.EqualsTo, item, false, false);
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
        
      cols.Add(POITView.Description);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Starts_With, formatedSearchText, true, false);
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, AutoTypeAheadWordSeparators + formatedSearchText, true, false);
                
      }
    
                    } else {
                        
      ColumnList cols = new ColumnList();    
        
      cols.Add(POITView.Description);
      
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
            POViewer.Business.POITRecord[] recordList  = POITView.GetRecords(filterJoin, wc, null, 0, count, ref count);
            String resultItem = "";
            if (resultItem == "") resultItem = "";
            foreach (POITRecord rec in recordList ){
                // Exit the loop if recordList count has reached AutoTypeAheadListSize.
                if (resultList.Count >= count) {
                    break;
                }
                // If the field is configured to Display as Foreign key, Format() method returns the 
                // Display as Forien Key value instead of original field value.
                // Since search had to be done in multiple fields (selected in Control's page property, binding tab) in a record,
                // We need to find relevent field to display which matches the prefixText and is not already present in the result list.
        
                resultItem = rec.Format(POITView.Description);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(POITView.Description.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, POITView.Description.IsFullTextSearchable);
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
    System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POITTableControlRepeater"));
    if (rep == null){return;}

    foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
    {
    // Loop through all rows in the table, set its DataSource and call DataBind().
    POITTableControlRow recControl = (POITTableControlRow)(repItem.FindControl("POITTableControlRow"));

      if (recControl.Visible && recControl.IsNewRecord) {
      POITRecord rec = new POITRecord();
        
                        if (recControl.AddedBatchID.Text != "") {
                            rec.Parse(recControl.AddedBatchID.Text, POITView.AddedBatchID);
                  }
                
                        if (recControl.AddedMth.Text != "") {
                            rec.Parse(recControl.AddedMth.Text, POITView.AddedMth);
                  }
                
                        if (recControl.BOCost.Text != "") {
                            rec.Parse(recControl.BOCost.Text, POITView.BOCost);
                  }
                
                        if (recControl.BOUnits.Text != "") {
                            rec.Parse(recControl.BOUnits.Text, POITView.BOUnits);
                  }
                
                        if (recControl.Component.Text != "") {
                            rec.Parse(recControl.Component.Text, POITView.Component);
                  }
                
                        if (recControl.CompType.Text != "") {
                            rec.Parse(recControl.CompType.Text, POITView.CompType);
                  }
                
                        if (recControl.CostCode.Text != "") {
                            rec.Parse(recControl.CostCode.Text, POITView.CostCode);
                  }
                
                        if (recControl.CurCost.Text != "") {
                            rec.Parse(recControl.CurCost.Text, POITView.CurCost);
                  }
                
                        if (recControl.CurECM.Text != "") {
                            rec.Parse(recControl.CurECM.Text, POITView.CurECM);
                  }
                
                        if (recControl.CurTax.Text != "") {
                            rec.Parse(recControl.CurTax.Text, POITView.CurTax);
                  }
                
                        if (recControl.CurUnitCost.Text != "") {
                            rec.Parse(recControl.CurUnitCost.Text, POITView.CurUnitCost);
                  }
                
                        if (recControl.CurUnits.Text != "") {
                            rec.Parse(recControl.CurUnits.Text, POITView.CurUnits);
                  }
                
                        if (recControl.Description.Text != "") {
                            rec.Parse(recControl.Description.Text, POITView.Description);
                  }
                
                        if (recControl.EMCo.Text != "") {
                            rec.Parse(recControl.EMCo.Text, POITView.EMCo);
                  }
                
                        if (recControl.EMCType.Text != "") {
                            rec.Parse(recControl.EMCType.Text, POITView.EMCType);
                  }
                
                        if (recControl.EMGroup.Text != "") {
                            rec.Parse(recControl.EMGroup.Text, POITView.EMGroup);
                  }
                
                        if (recControl.Equip.Text != "") {
                            rec.Parse(recControl.Equip.Text, POITView.Equip);
                  }
                
                        if (recControl.GLAcct.Text != "") {
                            rec.Parse(recControl.GLAcct.Text, POITView.GLAcct);
                  }
                
                        if (recControl.GLCo.Text != "") {
                            rec.Parse(recControl.GLCo.Text, POITView.GLCo);
                  }
                
                        if (recControl.GSTRate.Text != "") {
                            rec.Parse(recControl.GSTRate.Text, POITView.GSTRate);
                  }
                
                        if (recControl.INCo.Text != "") {
                            rec.Parse(recControl.INCo.Text, POITView.INCo);
                  }
                
                        if (recControl.InUseBatchId.Text != "") {
                            rec.Parse(recControl.InUseBatchId.Text, POITView.InUseBatchId);
                  }
                
                        if (recControl.InUseMth.Text != "") {
                            rec.Parse(recControl.InUseMth.Text, POITView.InUseMth);
                  }
                
                        if (recControl.InvCost.Text != "") {
                            rec.Parse(recControl.InvCost.Text, POITView.InvCost);
                  }
                
                        if (recControl.InvMiscAmt.Text != "") {
                            rec.Parse(recControl.InvMiscAmt.Text, POITView.InvMiscAmt);
                  }
                
                        if (recControl.InvTax.Text != "") {
                            rec.Parse(recControl.InvTax.Text, POITView.InvTax);
                  }
                
                        if (recControl.InvUnits.Text != "") {
                            rec.Parse(recControl.InvUnits.Text, POITView.InvUnits);
                  }
                
                        if (recControl.ItemType.Text != "") {
                            rec.Parse(recControl.ItemType.Text, POITView.ItemType);
                  }
                
                        if (recControl.JCCmtdTax.Text != "") {
                            rec.Parse(recControl.JCCmtdTax.Text, POITView.JCCmtdTax);
                  }
                
                        if (recControl.JCCo.Text != "") {
                            rec.Parse(recControl.JCCo.Text, POITView.JCCo);
                  }
                
                        if (recControl.JCCType.Text != "") {
                            rec.Parse(recControl.JCCType.Text, POITView.JCCType);
                  }
                
                        if (recControl.JCRemCmtdTax.Text != "") {
                            rec.Parse(recControl.JCRemCmtdTax.Text, POITView.JCRemCmtdTax);
                  }
                
                        if (recControl.Job.Text != "") {
                            rec.Parse(recControl.Job.Text, POITView.Job);
                  }
                
                        if (recControl.Loc.Text != "") {
                            rec.Parse(recControl.Loc.Text, POITView.Loc);
                  }
                
                        if (recControl.Material.Text != "") {
                            rec.Parse(recControl.Material.Text, POITView.Material);
                  }
                
                        if (recControl.MatlGroup.Text != "") {
                            rec.Parse(recControl.MatlGroup.Text, POITView.MatlGroup);
                  }
                
                        if (recControl.Notes.Text != "") {
                            rec.Parse(recControl.Notes.Text, POITView.Notes);
                  }
                
                        if (recControl.OrigCost.Text != "") {
                            rec.Parse(recControl.OrigCost.Text, POITView.OrigCost);
                  }
                
                        if (recControl.OrigECM.Text != "") {
                            rec.Parse(recControl.OrigECM.Text, POITView.OrigECM);
                  }
                
                        if (recControl.OrigTax.Text != "") {
                            rec.Parse(recControl.OrigTax.Text, POITView.OrigTax);
                  }
                
                        if (recControl.OrigUnitCost.Text != "") {
                            rec.Parse(recControl.OrigUnitCost.Text, POITView.OrigUnitCost);
                  }
                
                        if (recControl.OrigUnits.Text != "") {
                            rec.Parse(recControl.OrigUnits.Text, POITView.OrigUnits);
                  }
                
                        if (recControl.PayCategory.Text != "") {
                            rec.Parse(recControl.PayCategory.Text, POITView.PayCategory);
                  }
                
                        if (recControl.PayType.Text != "") {
                            rec.Parse(recControl.PayType.Text, POITView.PayType);
                  }
                
                        if (recControl.Phase.Text != "") {
                            rec.Parse(recControl.Phase.Text, POITView.Phase);
                  }
                
                        if (recControl.PhaseGroup.Text != "") {
                            rec.Parse(recControl.PhaseGroup.Text, POITView.PhaseGroup);
                  }
                
                        if (recControl.PO.Text != "") {
                            rec.Parse(recControl.PO.Text, POITView.PO);
                  }
                
                        if (recControl.POCo.Text != "") {
                            rec.Parse(recControl.POCo.Text, POITView.POCo);
                  }
                
                        if (recControl.POItem.Text != "") {
                            rec.Parse(recControl.POItem.Text, POITView.POItem);
                  }
                
                        if (recControl.PostedDate.Text != "") {
                            rec.Parse(recControl.PostedDate.Text, POITView.PostedDate);
                  }
                
                        if (recControl.PostToCo.Text != "") {
                            rec.Parse(recControl.PostToCo.Text, POITView.PostToCo);
                  }
                
                        if (recControl.RecvdCost.Text != "") {
                            rec.Parse(recControl.RecvdCost.Text, POITView.RecvdCost);
                  }
                
                        if (recControl.RecvdUnits.Text != "") {
                            rec.Parse(recControl.RecvdUnits.Text, POITView.RecvdUnits);
                  }
                
                        if (recControl.RecvYN.Text != "") {
                            rec.Parse(recControl.RecvYN.Text, POITView.RecvYN);
                  }
                
                        if (recControl.RemCost.Text != "") {
                            rec.Parse(recControl.RemCost.Text, POITView.RemCost);
                  }
                
                        if (recControl.RemTax.Text != "") {
                            rec.Parse(recControl.RemTax.Text, POITView.RemTax);
                  }
                
                        if (recControl.RemUnits.Text != "") {
                            rec.Parse(recControl.RemUnits.Text, POITView.RemUnits);
                  }
                
                        if (recControl.ReqDate.Text != "") {
                            rec.Parse(recControl.ReqDate.Text, POITView.ReqDate);
                  }
                
                        if (recControl.RequisitionNum.Text != "") {
                            rec.Parse(recControl.RequisitionNum.Text, POITView.RequisitionNum);
                  }
                
                        if (recControl.SMCo.Text != "") {
                            rec.Parse(recControl.SMCo.Text, POITView.SMCo);
                  }
                
                        if (recControl.SMJCCostType.Text != "") {
                            rec.Parse(recControl.SMJCCostType.Text, POITView.SMJCCostType);
                  }
                
                        if (recControl.SMPhase.Text != "") {
                            rec.Parse(recControl.SMPhase.Text, POITView.SMPhase);
                  }
                
                        if (recControl.SMPhaseGroup.Text != "") {
                            rec.Parse(recControl.SMPhaseGroup.Text, POITView.SMPhaseGroup);
                  }
                
                        if (recControl.SMScope.Text != "") {
                            rec.Parse(recControl.SMScope.Text, POITView.SMScope);
                  }
                
                        if (recControl.SMWorkOrder.Text != "") {
                            rec.Parse(recControl.SMWorkOrder.Text, POITView.SMWorkOrder);
                  }
                
                        if (recControl.Supplier.Text != "") {
                            rec.Parse(recControl.Supplier.Text, POITView.Supplier);
                  }
                
                        if (recControl.SupplierGroup.Text != "") {
                            rec.Parse(recControl.SupplierGroup.Text, POITView.SupplierGroup);
                  }
                
                        if (recControl.TaxCode.Text != "") {
                            rec.Parse(recControl.TaxCode.Text, POITView.TaxCode);
                  }
                
                        if (recControl.TaxGroup.Text != "") {
                            rec.Parse(recControl.TaxGroup.Text, POITView.TaxGroup);
                  }
                
                        if (recControl.TaxRate.Text != "") {
                            rec.Parse(recControl.TaxRate.Text, POITView.TaxRate);
                  }
                
                        if (recControl.TaxType.Text != "") {
                            rec.Parse(recControl.TaxType.Text, POITView.TaxType);
                  }
                
                        if (recControl.TotalCost.Text != "") {
                            rec.Parse(recControl.TotalCost.Text, POITView.TotalCost);
                  }
                
                        if (recControl.TotalTax.Text != "") {
                            rec.Parse(recControl.TotalTax.Text, POITView.TotalTax);
                  }
                
                        if (recControl.TotalUnits.Text != "") {
                            rec.Parse(recControl.TotalUnits.Text, POITView.TotalUnits);
                  }
                
                        if (recControl.udActOffDate.Text != "") {
                            rec.Parse(recControl.udActOffDate.Text, POITView.udActOffDate);
                  }
                
                        if (recControl.udCGCTable.Text != "") {
                            rec.Parse(recControl.udCGCTable.Text, POITView.udCGCTable);
                  }
                
                        if (recControl.udCGCTableID.Text != "") {
                            rec.Parse(recControl.udCGCTableID.Text, POITView.udCGCTableID);
                  }
                
                        if (recControl.udConv.Text != "") {
                            rec.Parse(recControl.udConv.Text, POITView.udConv);
                  }
                
                        if (recControl.udOnDate.Text != "") {
                            rec.Parse(recControl.udOnDate.Text, POITView.udOnDate);
                  }
                
                        if (recControl.udPlnOffDate.Text != "") {
                            rec.Parse(recControl.udPlnOffDate.Text, POITView.udPlnOffDate);
                  }
                
                        if (recControl.udRentalNum.Text != "") {
                            rec.Parse(recControl.udRentalNum.Text, POITView.udRentalNum);
                  }
                
                        if (recControl.udSource.Text != "") {
                            rec.Parse(recControl.udSource.Text, POITView.udSource);
                  }
                
                        if (recControl.UM.Text != "") {
                            rec.Parse(recControl.UM.Text, POITView.UM);
                  }
                
                        if (recControl.VendMatId.Text != "") {
                            rec.Parse(recControl.VendMatId.Text, POITView.VendMatId);
                  }
                
                        if (recControl.WO.Text != "") {
                            rec.Parse(recControl.WO.Text, POITView.WO);
                  }
                
                        if (recControl.WOItem.Text != "") {
                            rec.Parse(recControl.WOItem.Text, POITView.WOItem);
                  }
                
      newUIDataList.Add(recControl.PreservedUIData());
      newRecordList.Add(rec);
      }
      }
      }
    
            // Add any new record to the list.
            for (int count = 1; count <= this.AddNewRecord; count++) {
              
                newRecordList.Insert(0, new POITRecord());
                newUIDataList.Insert(0, new Hashtable());
              
            }
            this.AddNewRecord = 0;

            // Finally, add any new records to the DataSource.
            if (newRecordList.Count > 0) {
              
                ArrayList finalList = new ArrayList(this.DataSource);
                finalList.InsertRange(0, newRecordList);

                Type myrec = typeof(POViewer.Business.POITRecord);
                this.DataSource = (POITRecord[])(finalList.ToArray(myrec));
              
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
                
        public virtual void SetBOCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetBOUnitsLabel()
                  {
                  
                    
        }
                
        public virtual void SetComponentLabel()
                  {
                  
                    
        }
                
        public virtual void SetCompTypeLabel()
                  {
                  
                    
        }
                
        public virtual void SetCompTypeLabel1()
                  {
                  
                    
        }
                
        public virtual void SetCostCodeLabel()
                  {
                  
                    
        }
                
        public virtual void SetCurCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetCurECMLabel()
                  {
                  
                    
        }
                
        public virtual void SetCurTaxLabel()
                  {
                  
                    
        }
                
        public virtual void SetCurUnitCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetCurUnitsLabel()
                  {
                  
                    
        }
                
        public virtual void SetDescriptionLabel()
                  {
                  
                    
        }
                
        public virtual void SetEMCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetEMCTypeLabel()
                  {
                  
                    
        }
                
        public virtual void SetEMGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetEquipLabel()
                  {
                  
                    
        }
                
        public virtual void SetGLAcctLabel()
                  {
                  
                    
        }
                
        public virtual void SetGLCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetGSTRateLabel()
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
                
        public virtual void SetInvCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetInvMiscAmtLabel()
                  {
                  
                    
        }
                
        public virtual void SetInvTaxLabel()
                  {
                  
                    
        }
                
        public virtual void SetInvUnitsLabel()
                  {
                  
                    
        }
                
        public virtual void SetItemTypeLabel()
                  {
                  
                    
        }
                
        public virtual void SetJCCmtdTaxLabel()
                  {
                  
                    
        }
                
        public virtual void SetJCCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetJCCTypeLabel()
                  {
                  
                    
        }
                
        public virtual void SetJCRemCmtdTaxLabel()
                  {
                  
                    
        }
                
        public virtual void SetJobLabel()
                  {
                  
                    
        }
                
        public virtual void SetLocLabel()
                  {
                  
                    
        }
                
        public virtual void SetMaterialLabel()
                  {
                  
                    
        }
                
        public virtual void SetMatlGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetNotesLabel()
                  {
                  
                    
        }
                
        public virtual void SetOrigCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetOrigECMLabel()
                  {
                  
                    
        }
                
        public virtual void SetOrigTaxLabel()
                  {
                  
                    
        }
                
        public virtual void SetOrigUnitCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetOrigUnitsLabel()
                  {
                  
                    
        }
                
        public virtual void SetPayCategoryLabel()
                  {
                  
                    
        }
                
        public virtual void SetPayTypeLabel()
                  {
                  
                    
        }
                
        public virtual void SetPhaseGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetPhaseLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOItemLabel()
                  {
                  
                    
        }
                
        public virtual void SetPOLabel()
                  {
                  
                    
        }
                
        public virtual void SetPostedDateLabel()
                  {
                  
                    
        }
                
        public virtual void SetPostToCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetRecvdCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetRecvdUnitsLabel()
                  {
                  
                    
        }
                
        public virtual void SetRecvYNLabel()
                  {
                  
                    
        }
                
        public virtual void SetRemCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetRemTaxLabel()
                  {
                  
                    
        }
                
        public virtual void SetRemUnitsLabel()
                  {
                  
                    
        }
                
        public virtual void SetReqDateLabel()
                  {
                  
                    
        }
                
        public virtual void SetRequisitionNumLabel()
                  {
                  
                    
        }
                
        public virtual void SetSMCoLabel()
                  {
                  
                    
        }
                
        public virtual void SetSMJCCostTypeLabel()
                  {
                  
                    
        }
                
        public virtual void SetSMPhaseGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetSMPhaseLabel()
                  {
                  
                    
        }
                
        public virtual void SetSMScopeLabel()
                  {
                  
                    
        }
                
        public virtual void SetSMWorkOrderLabel()
                  {
                  
                    
        }
                
        public virtual void SetSupplierGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetSupplierLabel()
                  {
                  
                    
        }
                
        public virtual void SetTaxCodeLabel()
                  {
                  
                    
        }
                
        public virtual void SetTaxGroupLabel()
                  {
                  
                    
        }
                
        public virtual void SetTaxRateLabel()
                  {
                  
                    
        }
                
        public virtual void SetTaxTypeLabel()
                  {
                  
                    
        }
                
        public virtual void SetTotalCostLabel()
                  {
                  
                    
        }
                
        public virtual void SetTotalTaxLabel()
                  {
                  
                    
        }
                
        public virtual void SetTotalUnitsLabel()
                  {
                  
                    
        }
                
        public virtual void SetudActOffDateLabel()
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
                
        public virtual void SetudOnDateLabel()
                  {
                  
                    
        }
                
        public virtual void SetudPlnOffDateLabel()
                  {
                  
                    
        }
                
        public virtual void SetudRentalNumLabel()
                  {
                  
                    
        }
                
        public virtual void SetudSourceLabel()
                  {
                  
                    
        }
                
        public virtual void SetUMLabel()
                  {
                  
                    
        }
                
        public virtual void SetVendMatIdLabel()
                  {
                  
                    
        }
                
        public virtual void SetWOItemLabel()
                  {
                  
                    
        }
                
        public virtual void SetWOLabel()
                  {
                  
                    
        }
                
        public virtual void SetCompTypeFilter()
        {
            
            ArrayList CompTypeFilterselectedFilterItemList = new ArrayList();
            string CompTypeFilteritemsString = null;
            if (this.InSession(this.CompTypeFilter))
                CompTypeFilteritemsString = this.GetFromSession(this.CompTypeFilter);
            
            if (CompTypeFilteritemsString != null)
            {
                string[] CompTypeFilteritemListFromSession = CompTypeFilteritemsString.Split(',');
                foreach (string item in CompTypeFilteritemListFromSession)
                {
                    CompTypeFilterselectedFilterItemList.Add(item);
                }
            }
              
            			
            this.PopulateCompTypeFilter(MiscUtils.GetSelectedValueList(this.CompTypeFilter, CompTypeFilterselectedFilterItemList), 500);
                    
              string url = this.ModifyRedirectUrl("../POIT/POIT-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.CompTypeFilter.PostBackUrl = url + "?Target=" + this.CompTypeFilter.ClientID + "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("CompType")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--ANY--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:All")) + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.CompTypeFilter.Attributes["onClick"] = "initializePopupPage(this, '" + this.CompTypeFilter.PostBackUrl + "', false, event); return false;";                  
                                   
        }
            
        public virtual void SetSearchText()
        {
                                            
            this.SearchText.Attributes.Add("onfocus", "if(this.value=='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "') {this.value='';this.className='Search_Input';}");
            this.SearchText.Attributes.Add("onblur", "if(this.value=='') {this.value='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "';this.className='Search_InputHint';}");
                                   
        }
            
        // Get the filters' data for CompTypeFilter.
                
        protected virtual void PopulateCompTypeFilter(ArrayList selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            WhereClause wc = this.CreateWhereClause_CompTypeFilter();            
            this.CompTypeFilter.Items.Clear();
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_CompTypeFilter function.
            // It is better to customize the where clause there.
          
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(POITView.CompType, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = POITView.GetValues(POITView.CompType, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( POITView.CompType.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = POITView.CompType.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.CompTypeFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.CompTypeFilter.Items.Add(newItem);

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
            
            
            this.CompTypeFilter.SetFieldMaxLength(50);
                                 
                  
            // Add the selected value.
            if (this.CompTypeFilter.Items.Count == 0)
                this.CompTypeFilter.Items.Add(new ListItem(Page.GetResourceValue("Txt:All", "POViewer"), "--ANY--"));
            
            // Mark all items to be selected.
            foreach (ListItem item in this.CompTypeFilter.Items)
            {
                item.Selected = true;
            }
                               
        }
            
        public virtual WhereClause CreateWhereClause_CompTypeFilter()
        {
            // Create a where clause for the filter CompTypeFilter.
            // This function is called by the Populate method to load the items 
            // in the CompTypeFilterQuickSelector
        
            ArrayList CompTypeFilterselectedFilterItemList = new ArrayList();
            string CompTypeFilteritemsString = null;
            if (this.InSession(this.CompTypeFilter))
                CompTypeFilteritemsString = this.GetFromSession(this.CompTypeFilter);
            
            if (CompTypeFilteritemsString != null)
            {
                string[] CompTypeFilteritemListFromSession = CompTypeFilteritemsString.Split(',');
                foreach (string item in CompTypeFilteritemListFromSession)
                {
                    CompTypeFilterselectedFilterItemList.Add(item);
                }
            }
              
            CompTypeFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CompTypeFilter, CompTypeFilterselectedFilterItemList); 
            WhereClause wc = new WhereClause();
            if (CompTypeFilterselectedFilterItemList == null || CompTypeFilterselectedFilterItemList.Count == 0)
                wc.RunQuery = false;
            else            
            {
                foreach (string item in CompTypeFilterselectedFilterItemList)
                {
            
      
   
                    wc.iOR(POITView.CompType, BaseFilter.ComparisonOperator.EqualsTo, item);

                                
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
        
            ArrayList CompTypeFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CompTypeFilter, null);
            string CompTypeFilterSessionString = "";
            if (CompTypeFilterselectedFilterItemList != null){
                foreach (string item in CompTypeFilterselectedFilterItemList){
                    CompTypeFilterSessionString = String.Concat(CompTypeFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession(this.CompTypeFilter, CompTypeFilterSessionString);
                  
            this.SaveToSession(this.SearchText, this.SearchText.Text);
                  
            
                    
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
          
            ArrayList CompTypeFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CompTypeFilter, null);
            string CompTypeFilterSessionString = "";
            if (CompTypeFilterselectedFilterItemList != null){
                foreach (string item in CompTypeFilterselectedFilterItemList){
                    CompTypeFilterSessionString = String.Concat(CompTypeFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession("CompTypeFilter_Ajax", CompTypeFilterSessionString);
          
      this.SaveToSession("SearchText_Ajax", this.SearchText.Text);
              
           HttpContext.Current.Session["AppRelativeVirtualPath"] = this.Page.AppRelativeVirtualPath;
         
        }
        
        
        protected override void ClearControlsFromSession()
        {
            base.ClearControlsFromSession();
            // Clear filter controls values from the session.
        
            this.RemoveFromSession(this.CompTypeFilter);
            this.RemoveFromSession(this.SearchText);
            
            // Clear pagination state from session.
         

    // Clear table properties from the session.
    this.RemoveFromSession(this, "Order_By");
    this.RemoveFromSession(this, "Page_Index");
    this.RemoveFromSession(this, "Page_Size");
    
        }

        protected override void LoadViewState(object savedState)
        {
            base.LoadViewState(savedState);

            string orderByStr = (string)ViewState["POITTableControl_OrderBy"];
          
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
                this.ViewState["POITTableControl_OrderBy"] = this.CurrentSortOrder.ToXmlString();
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
    
      
            if (MiscUtils.IsValueSelected(CompTypeFilter))
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
        
        public virtual void AddedBatchIDLabel_Click(object sender, EventArgs args)
        {
            //Sorts by AddedBatchID when clicked.
              
            // Get previous sorting state for AddedBatchID.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.AddedBatchID);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for AddedBatchID.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.AddedBatchID, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by AddedBatchID, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void AddedMthLabel_Click(object sender, EventArgs args)
        {
            //Sorts by AddedMth when clicked.
              
            // Get previous sorting state for AddedMth.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.AddedMth);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for AddedMth.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.AddedMth, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by AddedMth, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void BOCostLabel_Click(object sender, EventArgs args)
        {
            //Sorts by BOCost when clicked.
              
            // Get previous sorting state for BOCost.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.BOCost);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for BOCost.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.BOCost, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by BOCost, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void InUseMthLabel_Click(object sender, EventArgs args)
        {
            //Sorts by InUseMth when clicked.
              
            // Get previous sorting state for InUseMth.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.InUseMth);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for InUseMth.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.InUseMth, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by InUseMth, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void POLabel_Click(object sender, EventArgs args)
        {
            //Sorts by PO when clicked.
              
            // Get previous sorting state for PO.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.PO);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for PO.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.PO, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by PO, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void PostedDateLabel_Click(object sender, EventArgs args)
        {
            //Sorts by PostedDate when clicked.
              
            // Get previous sorting state for PostedDate.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.PostedDate);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for PostedDate.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.PostedDate, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by PostedDate, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void ReqDateLabel_Click(object sender, EventArgs args)
        {
            //Sorts by ReqDate when clicked.
              
            // Get previous sorting state for ReqDate.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.ReqDate);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for ReqDate.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.ReqDate, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by ReqDate, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void udActOffDateLabel_Click(object sender, EventArgs args)
        {
            //Sorts by udActOffDate when clicked.
              
            // Get previous sorting state for udActOffDate.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.udActOffDate);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for udActOffDate.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.udActOffDate, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by udActOffDate, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void udOnDateLabel_Click(object sender, EventArgs args)
        {
            //Sorts by udOnDate when clicked.
              
            // Get previous sorting state for udOnDate.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.udOnDate);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for udOnDate.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.udOnDate, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by udOnDate, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void udPlnOffDateLabel_Click(object sender, EventArgs args)
        {
            //Sorts by udPlnOffDate when clicked.
              
            // Get previous sorting state for udPlnOffDate.
        
            OrderByItem sd = this.CurrentSortOrder.Find(POITView.udPlnOffDate);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for udPlnOffDate.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(POITView.udPlnOffDate, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by udPlnOffDate, so just reverse.
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


              this.TotalRecords = POITView.GetRecordCount(join, wc);
              if (this.TotalRecords > 10000)
              {
              
                // Add each of the columns in order of export.
                BaseColumn[] columns = new BaseColumn[] {
                             POITView.POCo,
             POITView.PO,
             POITView.POItem,
             POITView.ItemType,
             POITView.MatlGroup,
             POITView.Material,
             POITView.VendMatId,
             POITView.Description,
             POITView.UM,
             POITView.RecvYN,
             POITView.PostToCo,
             POITView.Loc,
             POITView.Job,
             POITView.PhaseGroup,
             POITView.Phase,
             POITView.JCCType,
             POITView.Equip,
             POITView.CompType,
             POITView.Component,
             POITView.EMGroup,
             POITView.CostCode,
             POITView.EMCType,
             POITView.WO,
             POITView.WOItem,
             POITView.GLCo,
             POITView.GLAcct,
             POITView.ReqDate,
             POITView.TaxGroup,
             POITView.TaxCode,
             POITView.TaxType,
             POITView.OrigUnits,
             POITView.OrigUnitCost,
             POITView.OrigECM,
             POITView.OrigCost,
             POITView.OrigTax,
             POITView.CurUnits,
             POITView.CurUnitCost,
             POITView.CurECM,
             POITView.CurCost,
             POITView.CurTax,
             POITView.RecvdUnits,
             POITView.RecvdCost,
             POITView.BOUnits,
             POITView.BOCost,
             POITView.TotalUnits,
             POITView.TotalCost,
             POITView.TotalTax,
             POITView.InvUnits,
             POITView.InvCost,
             POITView.InvTax,
             POITView.RemUnits,
             POITView.RemCost,
             POITView.RemTax,
             POITView.InUseMth,
             POITView.InUseBatchId,
             POITView.PostedDate,
             POITView.Notes,
             POITView.RequisitionNum,
             POITView.AddedMth,
             POITView.AddedBatchID,
             POITView.PayCategory,
             POITView.PayType,
             POITView.INCo,
             POITView.EMCo,
             POITView.JCCo,
             POITView.JCCmtdTax,
             POITView.Supplier,
             POITView.SupplierGroup,
             POITView.JCRemCmtdTax,
             POITView.TaxRate,
             POITView.GSTRate,
             POITView.SMCo,
             POITView.SMWorkOrder,
             POITView.InvMiscAmt,
             POITView.SMScope,
             POITView.SMPhaseGroup,
             POITView.SMPhase,
             POITView.SMJCCostType,
             POITView.udSource,
             POITView.udConv,
             POITView.udCGCTable,
             POITView.udCGCTableID,
             POITView.udOnDate,
             POITView.udPlnOffDate,
             POITView.udActOffDate,
             POITView.udRentalNum,
             null};
                ExportDataToCSV exportData = new ExportDataToCSV(POITView.Instance,wc,orderBy,columns);
                exportData.StartExport(this.Page.Response, true);

                DataForExport dataForCSV = new DataForExport(POITView.Instance, wc, orderBy, columns,join);

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
              ExportDataToExcel excelReport = new ExportDataToExcel(POITView.Instance, wc, orderBy);
              // Add each of the columns in order of export.
              // To customize the data type, change the second parameter of the new ExcelColumn to be
              // a format string from Excel's Format Cell menu. For example "dddd, mmmm dd, yyyy h:mm AM/PM;@", "#,##0.00"

              if (this.Page.Response == null)
              return;

              excelReport.CreateExcelBook();

              int width = 0;
              int columnCounter = 0;
              DataForExport data = new DataForExport(POITView.Instance, wc, orderBy, null,join);
                           data.ColumnList.Add(new ExcelColumn(POITView.POCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.PO, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.POItem, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.ItemType, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.MatlGroup, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.Material, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.VendMatId, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.Description, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.UM, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.RecvYN, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.PostToCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.Loc, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.Job, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.PhaseGroup, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.Phase, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.JCCType, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.Equip, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.CompType, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.Component, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.EMGroup, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.CostCode, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.EMCType, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.WO, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.WOItem, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.GLCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.GLAcct, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.ReqDate, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POITView.TaxGroup, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.TaxCode, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.TaxType, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.OrigUnits, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.OrigUnitCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.OrigECM, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.OrigCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.OrigTax, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.CurUnits, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.CurUnitCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.CurECM, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.CurCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.CurTax, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.RecvdUnits, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.RecvdCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.BOUnits, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.BOCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.TotalUnits, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.TotalCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.TotalTax, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.InvUnits, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.InvCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.InvTax, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.RemUnits, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.RemCost, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.RemTax, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.InUseMth, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POITView.InUseBatchId, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.PostedDate, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POITView.Notes, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.RequisitionNum, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.AddedMth, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POITView.AddedBatchID, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.PayCategory, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.PayType, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.INCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.EMCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.JCCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.JCCmtdTax, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.Supplier, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.SupplierGroup, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.JCRemCmtdTax, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.TaxRate, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.GSTRate, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.SMCo, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.SMWorkOrder, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.InvMiscAmt, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.SMScope, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.SMPhaseGroup, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.SMPhase, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.SMJCCostType, "0"));
             data.ColumnList.Add(new ExcelColumn(POITView.udSource, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.udConv, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.udCGCTable, "Default"));
             data.ColumnList.Add(new ExcelColumn(POITView.udCGCTableID, "Standard"));
             data.ColumnList.Add(new ExcelColumn(POITView.udOnDate, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POITView.udPlnOffDate, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POITView.udActOffDate, "Short Date"));
             data.ColumnList.Add(new ExcelColumn(POITView.udRentalNum, "Default"));


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
                val = POITView.GetDFKA(rec.GetValue(col.DisplayColumn).ToString(), col.DisplayColumn, null) as string;
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

                report.SpecificReportFileName = Page.Server.MapPath("Show-POIT-Table.PDFButton.report");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "POIT";
                // If Show-POIT-Table.PDFButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.   
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(POITView.POCo.Name, ReportEnum.Align.Right, "${POCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.PO.Name, ReportEnum.Align.Left, "${PO}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POITView.POItem.Name, ReportEnum.Align.Right, "${POItem}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.ItemType.Name, ReportEnum.Align.Right, "${ItemType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.MatlGroup.Name, ReportEnum.Align.Right, "${MatlGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.Material.Name, ReportEnum.Align.Left, "${Material}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.VendMatId.Name, ReportEnum.Align.Left, "${VendMatId}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POITView.Description.Name, ReportEnum.Align.Left, "${Description}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POITView.UM.Name, ReportEnum.Align.Left, "${UM}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.RecvYN.Name, ReportEnum.Align.Left, "${RecvYN}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.PostToCo.Name, ReportEnum.Align.Right, "${PostToCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.Loc.Name, ReportEnum.Align.Left, "${Loc}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.Job.Name, ReportEnum.Align.Left, "${Job}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.PhaseGroup.Name, ReportEnum.Align.Right, "${PhaseGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.Phase.Name, ReportEnum.Align.Left, "${Phase}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.JCCType.Name, ReportEnum.Align.Right, "${JCCType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.Equip.Name, ReportEnum.Align.Left, "${Equip}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.CompType.Name, ReportEnum.Align.Left, "${CompType}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.Component.Name, ReportEnum.Align.Left, "${Component}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.EMGroup.Name, ReportEnum.Align.Right, "${EMGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.CostCode.Name, ReportEnum.Align.Left, "${CostCode}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.EMCType.Name, ReportEnum.Align.Right, "${EMCType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.WO.Name, ReportEnum.Align.Left, "${WO}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.WOItem.Name, ReportEnum.Align.Right, "${WOItem}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.GLCo.Name, ReportEnum.Align.Right, "${GLCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.GLAcct.Name, ReportEnum.Align.Left, "${GLAcct}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.ReqDate.Name, ReportEnum.Align.Left, "${ReqDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.TaxGroup.Name, ReportEnum.Align.Right, "${TaxGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.TaxCode.Name, ReportEnum.Align.Left, "${TaxCode}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.TaxType.Name, ReportEnum.Align.Right, "${TaxType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.OrigUnits.Name, ReportEnum.Align.Right, "${OrigUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.OrigUnitCost.Name, ReportEnum.Align.Right, "${OrigUnitCost}", ReportEnum.Align.Right, 20);
                 report.AddColumn(POITView.OrigECM.Name, ReportEnum.Align.Left, "${OrigECM}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.OrigCost.Name, ReportEnum.Align.Right, "${OrigCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.OrigTax.Name, ReportEnum.Align.Right, "${OrigTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.CurUnits.Name, ReportEnum.Align.Right, "${CurUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.CurUnitCost.Name, ReportEnum.Align.Right, "${CurUnitCost}", ReportEnum.Align.Right, 20);
                 report.AddColumn(POITView.CurECM.Name, ReportEnum.Align.Left, "${CurECM}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.CurCost.Name, ReportEnum.Align.Right, "${CurCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.CurTax.Name, ReportEnum.Align.Right, "${CurTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RecvdUnits.Name, ReportEnum.Align.Right, "${RecvdUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RecvdCost.Name, ReportEnum.Align.Right, "${RecvdCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.BOUnits.Name, ReportEnum.Align.Right, "${BOUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.BOCost.Name, ReportEnum.Align.Right, "${BOCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.TotalUnits.Name, ReportEnum.Align.Right, "${TotalUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.TotalCost.Name, ReportEnum.Align.Right, "${TotalCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.TotalTax.Name, ReportEnum.Align.Right, "${TotalTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.InvUnits.Name, ReportEnum.Align.Right, "${InvUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.InvCost.Name, ReportEnum.Align.Right, "${InvCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.InvTax.Name, ReportEnum.Align.Right, "${InvTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RemUnits.Name, ReportEnum.Align.Right, "${RemUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RemCost.Name, ReportEnum.Align.Right, "${RemCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RemTax.Name, ReportEnum.Align.Right, "${RemTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.InUseMth.Name, ReportEnum.Align.Left, "${InUseMth}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.InUseBatchId.Name, ReportEnum.Align.Right, "${InUseBatchId}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.PostedDate.Name, ReportEnum.Align.Left, "${PostedDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.Notes.Name, ReportEnum.Align.Left, "${Notes}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POITView.RequisitionNum.Name, ReportEnum.Align.Left, "${RequisitionNum}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.AddedMth.Name, ReportEnum.Align.Left, "${AddedMth}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.AddedBatchID.Name, ReportEnum.Align.Right, "${AddedBatchID}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.PayCategory.Name, ReportEnum.Align.Right, "${PayCategory}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.PayType.Name, ReportEnum.Align.Right, "${PayType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.INCo.Name, ReportEnum.Align.Right, "${INCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.EMCo.Name, ReportEnum.Align.Right, "${EMCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.JCCo.Name, ReportEnum.Align.Right, "${JCCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.JCCmtdTax.Name, ReportEnum.Align.Right, "${JCCmtdTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.Supplier.Name, ReportEnum.Align.Right, "${Supplier}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SupplierGroup.Name, ReportEnum.Align.Right, "${SupplierGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.JCRemCmtdTax.Name, ReportEnum.Align.Right, "${JCRemCmtdTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.TaxRate.Name, ReportEnum.Align.Right, "${TaxRate}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.GSTRate.Name, ReportEnum.Align.Right, "${GSTRate}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SMCo.Name, ReportEnum.Align.Right, "${SMCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SMWorkOrder.Name, ReportEnum.Align.Right, "${SMWorkOrder}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.InvMiscAmt.Name, ReportEnum.Align.Right, "${InvMiscAmt}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.SMScope.Name, ReportEnum.Align.Right, "${SMScope}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SMPhaseGroup.Name, ReportEnum.Align.Right, "${SMPhaseGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SMPhase.Name, ReportEnum.Align.Left, "${SMPhase}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.SMJCCostType.Name, ReportEnum.Align.Right, "${SMJCCostType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.udSource.Name, ReportEnum.Align.Left, "${udSource}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POITView.udConv.Name, ReportEnum.Align.Left, "${udConv}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.udCGCTable.Name, ReportEnum.Align.Left, "${udCGCTable}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.udCGCTableID.Name, ReportEnum.Align.Right, "${udCGCTableID}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.udOnDate.Name, ReportEnum.Align.Left, "${udOnDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.udPlnOffDate.Name, ReportEnum.Align.Left, "${udPlnOffDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.udActOffDate.Name, ReportEnum.Align.Left, "${udActOffDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.udRentalNum.Name, ReportEnum.Align.Left, "${udRentalNum}", ReportEnum.Align.Left, 22);

  
                int rowsPerQuery = 5000;
                int recordCount = 0;
                                
                report.Page = Page.GetResourceValue("Txt:Page", "POViewer");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                
                ColumnList columns = POITView.GetColumnList();
                
                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                
                int pageNum = 0;
                int totalRows = POITView.GetRecordCount(joinFilter,whereClause);
                POITRecord[] records = null;
                
                do
                {
                    
                    records = POITView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                     if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( POITRecord record in records)
                    
                        {
                            // AddData method takes four parameters   
                            // The 1st parameter represent the data format
                            // The 2nd parameter represent the data value
                            // The 3rd parameter represent the default alignment of column using the data
                            // The 4th parameter represent the maximum length of the data value being shown
                                                 report.AddData("${POCo}", record.Format(POITView.POCo), ReportEnum.Align.Right, 300);
                             report.AddData("${PO}", record.Format(POITView.PO), ReportEnum.Align.Left, 300);
                             report.AddData("${POItem}", record.Format(POITView.POItem), ReportEnum.Align.Right, 300);
                             report.AddData("${ItemType}", record.Format(POITView.ItemType), ReportEnum.Align.Right, 300);
                             report.AddData("${MatlGroup}", record.Format(POITView.MatlGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${Material}", record.Format(POITView.Material), ReportEnum.Align.Left, 300);
                             report.AddData("${VendMatId}", record.Format(POITView.VendMatId), ReportEnum.Align.Left, 300);
                             report.AddData("${Description}", record.Format(POITView.Description), ReportEnum.Align.Left, 300);
                             report.AddData("${UM}", record.Format(POITView.UM), ReportEnum.Align.Left, 300);
                             report.AddData("${RecvYN}", record.Format(POITView.RecvYN), ReportEnum.Align.Left, 300);
                             report.AddData("${PostToCo}", record.Format(POITView.PostToCo), ReportEnum.Align.Right, 300);
                             report.AddData("${Loc}", record.Format(POITView.Loc), ReportEnum.Align.Left, 300);
                             report.AddData("${Job}", record.Format(POITView.Job), ReportEnum.Align.Left, 300);
                             report.AddData("${PhaseGroup}", record.Format(POITView.PhaseGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${Phase}", record.Format(POITView.Phase), ReportEnum.Align.Left, 300);
                             report.AddData("${JCCType}", record.Format(POITView.JCCType), ReportEnum.Align.Right, 300);
                             report.AddData("${Equip}", record.Format(POITView.Equip), ReportEnum.Align.Left, 300);
                             report.AddData("${CompType}", record.Format(POITView.CompType), ReportEnum.Align.Left, 300);
                             report.AddData("${Component}", record.Format(POITView.Component), ReportEnum.Align.Left, 300);
                             report.AddData("${EMGroup}", record.Format(POITView.EMGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${CostCode}", record.Format(POITView.CostCode), ReportEnum.Align.Left, 300);
                             report.AddData("${EMCType}", record.Format(POITView.EMCType), ReportEnum.Align.Right, 300);
                             report.AddData("${WO}", record.Format(POITView.WO), ReportEnum.Align.Left, 300);
                             report.AddData("${WOItem}", record.Format(POITView.WOItem), ReportEnum.Align.Right, 300);
                             report.AddData("${GLCo}", record.Format(POITView.GLCo), ReportEnum.Align.Right, 300);
                             report.AddData("${GLAcct}", record.Format(POITView.GLAcct), ReportEnum.Align.Left, 300);
                             report.AddData("${ReqDate}", record.Format(POITView.ReqDate), ReportEnum.Align.Left, 300);
                             report.AddData("${TaxGroup}", record.Format(POITView.TaxGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${TaxCode}", record.Format(POITView.TaxCode), ReportEnum.Align.Left, 300);
                             report.AddData("${TaxType}", record.Format(POITView.TaxType), ReportEnum.Align.Right, 300);
                             report.AddData("${OrigUnits}", record.Format(POITView.OrigUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${OrigUnitCost}", record.Format(POITView.OrigUnitCost), ReportEnum.Align.Right, 300);
                             report.AddData("${OrigECM}", record.Format(POITView.OrigECM), ReportEnum.Align.Left, 300);
                             report.AddData("${OrigCost}", record.Format(POITView.OrigCost), ReportEnum.Align.Right, 300);
                             report.AddData("${OrigTax}", record.Format(POITView.OrigTax), ReportEnum.Align.Right, 300);
                             report.AddData("${CurUnits}", record.Format(POITView.CurUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${CurUnitCost}", record.Format(POITView.CurUnitCost), ReportEnum.Align.Right, 300);
                             report.AddData("${CurECM}", record.Format(POITView.CurECM), ReportEnum.Align.Left, 300);
                             report.AddData("${CurCost}", record.Format(POITView.CurCost), ReportEnum.Align.Right, 300);
                             report.AddData("${CurTax}", record.Format(POITView.CurTax), ReportEnum.Align.Right, 300);
                             report.AddData("${RecvdUnits}", record.Format(POITView.RecvdUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${RecvdCost}", record.Format(POITView.RecvdCost), ReportEnum.Align.Right, 300);
                             report.AddData("${BOUnits}", record.Format(POITView.BOUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${BOCost}", record.Format(POITView.BOCost), ReportEnum.Align.Right, 300);
                             report.AddData("${TotalUnits}", record.Format(POITView.TotalUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${TotalCost}", record.Format(POITView.TotalCost), ReportEnum.Align.Right, 300);
                             report.AddData("${TotalTax}", record.Format(POITView.TotalTax), ReportEnum.Align.Right, 300);
                             report.AddData("${InvUnits}", record.Format(POITView.InvUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${InvCost}", record.Format(POITView.InvCost), ReportEnum.Align.Right, 300);
                             report.AddData("${InvTax}", record.Format(POITView.InvTax), ReportEnum.Align.Right, 300);
                             report.AddData("${RemUnits}", record.Format(POITView.RemUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${RemCost}", record.Format(POITView.RemCost), ReportEnum.Align.Right, 300);
                             report.AddData("${RemTax}", record.Format(POITView.RemTax), ReportEnum.Align.Right, 300);
                             report.AddData("${InUseMth}", record.Format(POITView.InUseMth), ReportEnum.Align.Left, 300);
                             report.AddData("${InUseBatchId}", record.Format(POITView.InUseBatchId), ReportEnum.Align.Right, 300);
                             report.AddData("${PostedDate}", record.Format(POITView.PostedDate), ReportEnum.Align.Left, 300);
                             report.AddData("${Notes}", record.Format(POITView.Notes), ReportEnum.Align.Left, 300);
                             report.AddData("${RequisitionNum}", record.Format(POITView.RequisitionNum), ReportEnum.Align.Left, 300);
                             report.AddData("${AddedMth}", record.Format(POITView.AddedMth), ReportEnum.Align.Left, 300);
                             report.AddData("${AddedBatchID}", record.Format(POITView.AddedBatchID), ReportEnum.Align.Right, 300);
                             report.AddData("${PayCategory}", record.Format(POITView.PayCategory), ReportEnum.Align.Right, 300);
                             report.AddData("${PayType}", record.Format(POITView.PayType), ReportEnum.Align.Right, 300);
                             report.AddData("${INCo}", record.Format(POITView.INCo), ReportEnum.Align.Right, 300);
                             report.AddData("${EMCo}", record.Format(POITView.EMCo), ReportEnum.Align.Right, 300);
                             report.AddData("${JCCo}", record.Format(POITView.JCCo), ReportEnum.Align.Right, 300);
                             report.AddData("${JCCmtdTax}", record.Format(POITView.JCCmtdTax), ReportEnum.Align.Right, 300);
                             report.AddData("${Supplier}", record.Format(POITView.Supplier), ReportEnum.Align.Right, 300);
                             report.AddData("${SupplierGroup}", record.Format(POITView.SupplierGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${JCRemCmtdTax}", record.Format(POITView.JCRemCmtdTax), ReportEnum.Align.Right, 300);
                             report.AddData("${TaxRate}", record.Format(POITView.TaxRate), ReportEnum.Align.Right, 300);
                             report.AddData("${GSTRate}", record.Format(POITView.GSTRate), ReportEnum.Align.Right, 300);
                             report.AddData("${SMCo}", record.Format(POITView.SMCo), ReportEnum.Align.Right, 300);
                             report.AddData("${SMWorkOrder}", record.Format(POITView.SMWorkOrder), ReportEnum.Align.Right, 300);
                             report.AddData("${InvMiscAmt}", record.Format(POITView.InvMiscAmt), ReportEnum.Align.Right, 300);
                             report.AddData("${SMScope}", record.Format(POITView.SMScope), ReportEnum.Align.Right, 300);
                             report.AddData("${SMPhaseGroup}", record.Format(POITView.SMPhaseGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${SMPhase}", record.Format(POITView.SMPhase), ReportEnum.Align.Left, 300);
                             report.AddData("${SMJCCostType}", record.Format(POITView.SMJCCostType), ReportEnum.Align.Right, 300);
                             report.AddData("${udSource}", record.Format(POITView.udSource), ReportEnum.Align.Left, 300);
                             report.AddData("${udConv}", record.Format(POITView.udConv), ReportEnum.Align.Left, 300);
                             report.AddData("${udCGCTable}", record.Format(POITView.udCGCTable), ReportEnum.Align.Left, 300);
                             report.AddData("${udCGCTableID}", record.Format(POITView.udCGCTableID), ReportEnum.Align.Right, 300);
                             report.AddData("${udOnDate}", record.Format(POITView.udOnDate), ReportEnum.Align.Left, 300);
                             report.AddData("${udPlnOffDate}", record.Format(POITView.udPlnOffDate), ReportEnum.Align.Left, 300);
                             report.AddData("${udActOffDate}", record.Format(POITView.udActOffDate), ReportEnum.Align.Left, 300);
                             report.AddData("${udRentalNum}", record.Format(POITView.udRentalNum), ReportEnum.Align.Left, 300);

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
                
              this.CompTypeFilter.ClearSelection();
            
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

                report.SpecificReportFileName = Page.Server.MapPath("Show-POIT-Table.WordButton.word");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "POIT";
                // If Show-POIT-Table.WordButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(POITView.POCo.Name, ReportEnum.Align.Right, "${POCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.PO.Name, ReportEnum.Align.Left, "${PO}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POITView.POItem.Name, ReportEnum.Align.Right, "${POItem}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.ItemType.Name, ReportEnum.Align.Right, "${ItemType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.MatlGroup.Name, ReportEnum.Align.Right, "${MatlGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.Material.Name, ReportEnum.Align.Left, "${Material}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.VendMatId.Name, ReportEnum.Align.Left, "${VendMatId}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POITView.Description.Name, ReportEnum.Align.Left, "${Description}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POITView.UM.Name, ReportEnum.Align.Left, "${UM}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.RecvYN.Name, ReportEnum.Align.Left, "${RecvYN}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.PostToCo.Name, ReportEnum.Align.Right, "${PostToCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.Loc.Name, ReportEnum.Align.Left, "${Loc}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.Job.Name, ReportEnum.Align.Left, "${Job}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.PhaseGroup.Name, ReportEnum.Align.Right, "${PhaseGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.Phase.Name, ReportEnum.Align.Left, "${Phase}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.JCCType.Name, ReportEnum.Align.Right, "${JCCType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.Equip.Name, ReportEnum.Align.Left, "${Equip}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.CompType.Name, ReportEnum.Align.Left, "${CompType}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.Component.Name, ReportEnum.Align.Left, "${Component}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.EMGroup.Name, ReportEnum.Align.Right, "${EMGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.CostCode.Name, ReportEnum.Align.Left, "${CostCode}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.EMCType.Name, ReportEnum.Align.Right, "${EMCType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.WO.Name, ReportEnum.Align.Left, "${WO}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.WOItem.Name, ReportEnum.Align.Right, "${WOItem}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.GLCo.Name, ReportEnum.Align.Right, "${GLCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.GLAcct.Name, ReportEnum.Align.Left, "${GLAcct}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.ReqDate.Name, ReportEnum.Align.Left, "${ReqDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.TaxGroup.Name, ReportEnum.Align.Right, "${TaxGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.TaxCode.Name, ReportEnum.Align.Left, "${TaxCode}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.TaxType.Name, ReportEnum.Align.Right, "${TaxType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.OrigUnits.Name, ReportEnum.Align.Right, "${OrigUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.OrigUnitCost.Name, ReportEnum.Align.Right, "${OrigUnitCost}", ReportEnum.Align.Right, 20);
                 report.AddColumn(POITView.OrigECM.Name, ReportEnum.Align.Left, "${OrigECM}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.OrigCost.Name, ReportEnum.Align.Right, "${OrigCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.OrigTax.Name, ReportEnum.Align.Right, "${OrigTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.CurUnits.Name, ReportEnum.Align.Right, "${CurUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.CurUnitCost.Name, ReportEnum.Align.Right, "${CurUnitCost}", ReportEnum.Align.Right, 20);
                 report.AddColumn(POITView.CurECM.Name, ReportEnum.Align.Left, "${CurECM}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.CurCost.Name, ReportEnum.Align.Right, "${CurCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.CurTax.Name, ReportEnum.Align.Right, "${CurTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RecvdUnits.Name, ReportEnum.Align.Right, "${RecvdUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RecvdCost.Name, ReportEnum.Align.Right, "${RecvdCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.BOUnits.Name, ReportEnum.Align.Right, "${BOUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.BOCost.Name, ReportEnum.Align.Right, "${BOCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.TotalUnits.Name, ReportEnum.Align.Right, "${TotalUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.TotalCost.Name, ReportEnum.Align.Right, "${TotalCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.TotalTax.Name, ReportEnum.Align.Right, "${TotalTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.InvUnits.Name, ReportEnum.Align.Right, "${InvUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.InvCost.Name, ReportEnum.Align.Right, "${InvCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.InvTax.Name, ReportEnum.Align.Right, "${InvTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RemUnits.Name, ReportEnum.Align.Right, "${RemUnits}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RemCost.Name, ReportEnum.Align.Right, "${RemCost}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.RemTax.Name, ReportEnum.Align.Right, "${RemTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.InUseMth.Name, ReportEnum.Align.Left, "${InUseMth}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.InUseBatchId.Name, ReportEnum.Align.Right, "${InUseBatchId}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.PostedDate.Name, ReportEnum.Align.Left, "${PostedDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.Notes.Name, ReportEnum.Align.Left, "${Notes}", ReportEnum.Align.Left, 28);
                 report.AddColumn(POITView.RequisitionNum.Name, ReportEnum.Align.Left, "${RequisitionNum}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.AddedMth.Name, ReportEnum.Align.Left, "${AddedMth}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.AddedBatchID.Name, ReportEnum.Align.Right, "${AddedBatchID}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.PayCategory.Name, ReportEnum.Align.Right, "${PayCategory}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.PayType.Name, ReportEnum.Align.Right, "${PayType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.INCo.Name, ReportEnum.Align.Right, "${INCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.EMCo.Name, ReportEnum.Align.Right, "${EMCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.JCCo.Name, ReportEnum.Align.Right, "${JCCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.JCCmtdTax.Name, ReportEnum.Align.Right, "${JCCmtdTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.Supplier.Name, ReportEnum.Align.Right, "${Supplier}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SupplierGroup.Name, ReportEnum.Align.Right, "${SupplierGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.JCRemCmtdTax.Name, ReportEnum.Align.Right, "${JCRemCmtdTax}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.TaxRate.Name, ReportEnum.Align.Right, "${TaxRate}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.GSTRate.Name, ReportEnum.Align.Right, "${GSTRate}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SMCo.Name, ReportEnum.Align.Right, "${SMCo}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SMWorkOrder.Name, ReportEnum.Align.Right, "${SMWorkOrder}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.InvMiscAmt.Name, ReportEnum.Align.Right, "${InvMiscAmt}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.SMScope.Name, ReportEnum.Align.Right, "${SMScope}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SMPhaseGroup.Name, ReportEnum.Align.Right, "${SMPhaseGroup}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.SMPhase.Name, ReportEnum.Align.Left, "${SMPhase}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.SMJCCostType.Name, ReportEnum.Align.Right, "${SMJCCostType}", ReportEnum.Align.Right, 15);
                 report.AddColumn(POITView.udSource.Name, ReportEnum.Align.Left, "${udSource}", ReportEnum.Align.Left, 24);
                 report.AddColumn(POITView.udConv.Name, ReportEnum.Align.Left, "${udConv}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.udCGCTable.Name, ReportEnum.Align.Left, "${udCGCTable}", ReportEnum.Align.Left, 15);
                 report.AddColumn(POITView.udCGCTableID.Name, ReportEnum.Align.Right, "${udCGCTableID}", ReportEnum.Align.Right, 19);
                 report.AddColumn(POITView.udOnDate.Name, ReportEnum.Align.Left, "${udOnDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.udPlnOffDate.Name, ReportEnum.Align.Left, "${udPlnOffDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.udActOffDate.Name, ReportEnum.Align.Left, "${udActOffDate}", ReportEnum.Align.Left, 20);
                 report.AddColumn(POITView.udRentalNum.Name, ReportEnum.Align.Left, "${udRentalNum}", ReportEnum.Align.Left, 22);

                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
            
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                

                int rowsPerQuery = 5000;
                int pageNum = 0;
                int recordCount = 0;
                int totalRows = POITView.GetRecordCount(joinFilter,whereClause);

                report.Page = Page.GetResourceValue("Txt:Page", "POViewer");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                ColumnList columns = POITView.GetColumnList();
                POITRecord[] records = null;
                do
                {
                    records = POITView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                    if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( POITRecord record in records)
                        {
                            // AddData method takes four parameters
                            // The 1st parameter represents the data format
                            // The 2nd parameter represents the data value
                            // The 3rd parameter represents the default alignment of column using the data
                            // The 4th parameter represents the maximum length of the data value being shown
                             report.AddData("${POCo}", record.Format(POITView.POCo), ReportEnum.Align.Right, 300);
                             report.AddData("${PO}", record.Format(POITView.PO), ReportEnum.Align.Left, 300);
                             report.AddData("${POItem}", record.Format(POITView.POItem), ReportEnum.Align.Right, 300);
                             report.AddData("${ItemType}", record.Format(POITView.ItemType), ReportEnum.Align.Right, 300);
                             report.AddData("${MatlGroup}", record.Format(POITView.MatlGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${Material}", record.Format(POITView.Material), ReportEnum.Align.Left, 300);
                             report.AddData("${VendMatId}", record.Format(POITView.VendMatId), ReportEnum.Align.Left, 300);
                             report.AddData("${Description}", record.Format(POITView.Description), ReportEnum.Align.Left, 300);
                             report.AddData("${UM}", record.Format(POITView.UM), ReportEnum.Align.Left, 300);
                             report.AddData("${RecvYN}", record.Format(POITView.RecvYN), ReportEnum.Align.Left, 300);
                             report.AddData("${PostToCo}", record.Format(POITView.PostToCo), ReportEnum.Align.Right, 300);
                             report.AddData("${Loc}", record.Format(POITView.Loc), ReportEnum.Align.Left, 300);
                             report.AddData("${Job}", record.Format(POITView.Job), ReportEnum.Align.Left, 300);
                             report.AddData("${PhaseGroup}", record.Format(POITView.PhaseGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${Phase}", record.Format(POITView.Phase), ReportEnum.Align.Left, 300);
                             report.AddData("${JCCType}", record.Format(POITView.JCCType), ReportEnum.Align.Right, 300);
                             report.AddData("${Equip}", record.Format(POITView.Equip), ReportEnum.Align.Left, 300);
                             report.AddData("${CompType}", record.Format(POITView.CompType), ReportEnum.Align.Left, 300);
                             report.AddData("${Component}", record.Format(POITView.Component), ReportEnum.Align.Left, 300);
                             report.AddData("${EMGroup}", record.Format(POITView.EMGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${CostCode}", record.Format(POITView.CostCode), ReportEnum.Align.Left, 300);
                             report.AddData("${EMCType}", record.Format(POITView.EMCType), ReportEnum.Align.Right, 300);
                             report.AddData("${WO}", record.Format(POITView.WO), ReportEnum.Align.Left, 300);
                             report.AddData("${WOItem}", record.Format(POITView.WOItem), ReportEnum.Align.Right, 300);
                             report.AddData("${GLCo}", record.Format(POITView.GLCo), ReportEnum.Align.Right, 300);
                             report.AddData("${GLAcct}", record.Format(POITView.GLAcct), ReportEnum.Align.Left, 300);
                             report.AddData("${ReqDate}", record.Format(POITView.ReqDate), ReportEnum.Align.Left, 300);
                             report.AddData("${TaxGroup}", record.Format(POITView.TaxGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${TaxCode}", record.Format(POITView.TaxCode), ReportEnum.Align.Left, 300);
                             report.AddData("${TaxType}", record.Format(POITView.TaxType), ReportEnum.Align.Right, 300);
                             report.AddData("${OrigUnits}", record.Format(POITView.OrigUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${OrigUnitCost}", record.Format(POITView.OrigUnitCost), ReportEnum.Align.Right, 300);
                             report.AddData("${OrigECM}", record.Format(POITView.OrigECM), ReportEnum.Align.Left, 300);
                             report.AddData("${OrigCost}", record.Format(POITView.OrigCost), ReportEnum.Align.Right, 300);
                             report.AddData("${OrigTax}", record.Format(POITView.OrigTax), ReportEnum.Align.Right, 300);
                             report.AddData("${CurUnits}", record.Format(POITView.CurUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${CurUnitCost}", record.Format(POITView.CurUnitCost), ReportEnum.Align.Right, 300);
                             report.AddData("${CurECM}", record.Format(POITView.CurECM), ReportEnum.Align.Left, 300);
                             report.AddData("${CurCost}", record.Format(POITView.CurCost), ReportEnum.Align.Right, 300);
                             report.AddData("${CurTax}", record.Format(POITView.CurTax), ReportEnum.Align.Right, 300);
                             report.AddData("${RecvdUnits}", record.Format(POITView.RecvdUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${RecvdCost}", record.Format(POITView.RecvdCost), ReportEnum.Align.Right, 300);
                             report.AddData("${BOUnits}", record.Format(POITView.BOUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${BOCost}", record.Format(POITView.BOCost), ReportEnum.Align.Right, 300);
                             report.AddData("${TotalUnits}", record.Format(POITView.TotalUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${TotalCost}", record.Format(POITView.TotalCost), ReportEnum.Align.Right, 300);
                             report.AddData("${TotalTax}", record.Format(POITView.TotalTax), ReportEnum.Align.Right, 300);
                             report.AddData("${InvUnits}", record.Format(POITView.InvUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${InvCost}", record.Format(POITView.InvCost), ReportEnum.Align.Right, 300);
                             report.AddData("${InvTax}", record.Format(POITView.InvTax), ReportEnum.Align.Right, 300);
                             report.AddData("${RemUnits}", record.Format(POITView.RemUnits), ReportEnum.Align.Right, 300);
                             report.AddData("${RemCost}", record.Format(POITView.RemCost), ReportEnum.Align.Right, 300);
                             report.AddData("${RemTax}", record.Format(POITView.RemTax), ReportEnum.Align.Right, 300);
                             report.AddData("${InUseMth}", record.Format(POITView.InUseMth), ReportEnum.Align.Left, 300);
                             report.AddData("${InUseBatchId}", record.Format(POITView.InUseBatchId), ReportEnum.Align.Right, 300);
                             report.AddData("${PostedDate}", record.Format(POITView.PostedDate), ReportEnum.Align.Left, 300);
                             report.AddData("${Notes}", record.Format(POITView.Notes), ReportEnum.Align.Left, 300);
                             report.AddData("${RequisitionNum}", record.Format(POITView.RequisitionNum), ReportEnum.Align.Left, 300);
                             report.AddData("${AddedMth}", record.Format(POITView.AddedMth), ReportEnum.Align.Left, 300);
                             report.AddData("${AddedBatchID}", record.Format(POITView.AddedBatchID), ReportEnum.Align.Right, 300);
                             report.AddData("${PayCategory}", record.Format(POITView.PayCategory), ReportEnum.Align.Right, 300);
                             report.AddData("${PayType}", record.Format(POITView.PayType), ReportEnum.Align.Right, 300);
                             report.AddData("${INCo}", record.Format(POITView.INCo), ReportEnum.Align.Right, 300);
                             report.AddData("${EMCo}", record.Format(POITView.EMCo), ReportEnum.Align.Right, 300);
                             report.AddData("${JCCo}", record.Format(POITView.JCCo), ReportEnum.Align.Right, 300);
                             report.AddData("${JCCmtdTax}", record.Format(POITView.JCCmtdTax), ReportEnum.Align.Right, 300);
                             report.AddData("${Supplier}", record.Format(POITView.Supplier), ReportEnum.Align.Right, 300);
                             report.AddData("${SupplierGroup}", record.Format(POITView.SupplierGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${JCRemCmtdTax}", record.Format(POITView.JCRemCmtdTax), ReportEnum.Align.Right, 300);
                             report.AddData("${TaxRate}", record.Format(POITView.TaxRate), ReportEnum.Align.Right, 300);
                             report.AddData("${GSTRate}", record.Format(POITView.GSTRate), ReportEnum.Align.Right, 300);
                             report.AddData("${SMCo}", record.Format(POITView.SMCo), ReportEnum.Align.Right, 300);
                             report.AddData("${SMWorkOrder}", record.Format(POITView.SMWorkOrder), ReportEnum.Align.Right, 300);
                             report.AddData("${InvMiscAmt}", record.Format(POITView.InvMiscAmt), ReportEnum.Align.Right, 300);
                             report.AddData("${SMScope}", record.Format(POITView.SMScope), ReportEnum.Align.Right, 300);
                             report.AddData("${SMPhaseGroup}", record.Format(POITView.SMPhaseGroup), ReportEnum.Align.Right, 300);
                             report.AddData("${SMPhase}", record.Format(POITView.SMPhase), ReportEnum.Align.Left, 300);
                             report.AddData("${SMJCCostType}", record.Format(POITView.SMJCCostType), ReportEnum.Align.Right, 300);
                             report.AddData("${udSource}", record.Format(POITView.udSource), ReportEnum.Align.Left, 300);
                             report.AddData("${udConv}", record.Format(POITView.udConv), ReportEnum.Align.Left, 300);
                             report.AddData("${udCGCTable}", record.Format(POITView.udCGCTable), ReportEnum.Align.Left, 300);
                             report.AddData("${udCGCTableID}", record.Format(POITView.udCGCTableID), ReportEnum.Align.Right, 300);
                             report.AddData("${udOnDate}", record.Format(POITView.udOnDate), ReportEnum.Align.Left, 300);
                             report.AddData("${udPlnOffDate}", record.Format(POITView.udPlnOffDate), ReportEnum.Align.Left, 300);
                             report.AddData("${udActOffDate}", record.Format(POITView.udActOffDate), ReportEnum.Align.Left, 300);
                             report.AddData("${udRentalNum}", record.Format(POITView.udRentalNum), ReportEnum.Align.Left, 300);

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
        protected virtual void CompTypeFilter_SelectedIndexChanged(object sender, EventArgs args)
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
                    _TotalRecords = POITView.GetRecordCount(CreateCompoundJoinFilter(), CreateWhereClause());
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
        
        public  POITRecord[] DataSource {
             
            get {
                return (POITRecord[])(base._DataSource);
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
        
        public System.Web.UI.WebControls.LinkButton AddedBatchIDLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AddedBatchIDLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton AddedMthLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "AddedMthLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton BOCostLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "BOCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal BOUnitsLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "BOUnitsLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal ComponentLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ComponentLabel");
            }
        }
        
        public BaseClasses.Web.UI.WebControls.QuickSelector CompTypeFilter {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CompTypeFilter");
            }
        }              
        
        public System.Web.UI.WebControls.Literal CompTypeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CompTypeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CompTypeLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CompTypeLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal CostCodeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostCodeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CurCostLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CurECMLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurECMLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CurTaxLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurTaxLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CurUnitCostLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurUnitCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CurUnitsLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CurUnitsLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal DescriptionLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "DescriptionLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal EMCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "EMCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal EMCTypeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "EMCTypeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal EMGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "EMGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal EquipLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "EquipLabel");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton ExcelButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ExcelButton");
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
        
        public System.Web.UI.WebControls.Literal GLAcctLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLAcctLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal GLCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GLCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal GSTRateLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "GSTRateLabel");
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
        
        public System.Web.UI.WebControls.LinkButton InUseMthLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InUseMthLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal InvCostLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InvCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal InvMiscAmtLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InvMiscAmtLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal InvTaxLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InvTaxLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal InvUnitsLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "InvUnitsLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal ItemTypeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ItemTypeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal JCCmtdTaxLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCCmtdTaxLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal JCCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal JCCTypeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCCTypeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal JCRemCmtdTaxLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JCRemCmtdTaxLabel");
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
        
        public System.Web.UI.WebControls.Literal MaterialLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MaterialLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal MatlGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MatlGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal NotesLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "NotesLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal OrigCostLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal OrigECMLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigECMLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal OrigTaxLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigTaxLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal OrigUnitCostLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigUnitCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal OrigUnitsLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "OrigUnitsLabel");
            }
        }
        
        public POViewer.UI.IPaginationModern Pagination {
            get {
                return (POViewer.UI.IPaginationModern)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Pagination");
            }
        }
        
        public System.Web.UI.WebControls.Literal PayCategoryLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PayCategoryLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal PayTypeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PayTypeLabel");
            }
        }
        
        public System.Web.UI.WebControls.ImageButton PDFButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PDFButton");
            }
        }
        
        public System.Web.UI.WebControls.Literal PhaseGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PhaseGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal PhaseLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PhaseLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal POItemLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POItemLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton POLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton PostedDateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PostedDateLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal PostToCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PostToCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal RecvdCostLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RecvdCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal RecvdUnitsLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RecvdUnitsLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal RecvYNLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RecvYNLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal RemCostLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RemCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal RemTaxLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RemTaxLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal RemUnitsLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RemUnitsLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton ReqDateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ReqDateLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal RequisitionNumLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "RequisitionNumLabel");
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
        
        public System.Web.UI.WebControls.Literal SMCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SMJCCostTypeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMJCCostTypeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SMPhaseGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMPhaseGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SMPhaseLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMPhaseLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SMScopeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMScopeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SMWorkOrderLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SMWorkOrderLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SupplierGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SupplierGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal SupplierLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SupplierLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal TaxCodeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TaxCodeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal TaxGroupLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TaxGroupLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal TaxRateLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TaxRateLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal TaxTypeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TaxTypeLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal Title {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Title");
            }
        }
        
        public System.Web.UI.WebControls.Literal TotalCostLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TotalCostLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal TotalTaxLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TotalTaxLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal TotalUnitsLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "TotalUnitsLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton udActOffDateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udActOffDateLabel");
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
        
        public System.Web.UI.WebControls.LinkButton udOnDateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udOnDateLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton udPlnOffDateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udPlnOffDateLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udRentalNumLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udRentalNumLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal udSourceLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "udSourceLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal UMLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "UMLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal VendMatIdLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VendMatIdLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal WOItemLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "WOItemLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal WOLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "WOLabel");
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
          
        public virtual POITTableControlRow GetSelectedRecordControl()
        {
        
            return null;
          
        }

        public virtual POITTableControlRow[] GetSelectedRecordControls()
        {
        
            return (POITTableControlRow[])((new ArrayList()).ToArray(Type.GetType("POViewer.UI.Controls.Show_POIT_Table.POITTableControlRow")));
          
        }

        public virtual void DeleteSelectedRecords(bool deferDeletion)
        {
            POITTableControlRow[] recordList = this.GetSelectedRecordControls();
            if (recordList.Length == 0) {
                // Localization.
                throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "POViewer"));
            }
            
            foreach (POITTableControlRow recCtl in recordList)
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

        public POITTableControlRow[] GetRecordControls()
        {
            ArrayList recordList = new ArrayList();
            System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)this.FindControl("POITTableControlRepeater");
            if (rep == null){return null;}
            foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
            {
              POITTableControlRow recControl = (POITTableControlRow)repItem.FindControl("POITTableControlRow");
                  recordList.Add(recControl);
                
            }

            return (POITTableControlRow[])recordList.ToArray(Type.GetType("POViewer.UI.Controls.Show_POIT_Table.POITTableControlRow"));
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

  