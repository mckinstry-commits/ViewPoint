
// This file implements the TableControl, TableControlRow, and RecordControl classes for the 
// Edit_MvwISDJobPhaseXref.aspx page.  The Row or RecordControl classes are the 
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

  
namespace VPLookup.UI.Controls.Edit_MvwISDJobPhaseXref
{
  

#region "Section 1: Place your customizations here."

    
public class MvwISDJobPhaseXrefRecordControl : BaseMvwISDJobPhaseXrefRecordControl
{
      
        // The BaseMvwISDJobPhaseXrefRecordControl implements the LoadData, DataBind and other
        // methods to load and display the data in a table control.

        // This is the ideal place to add your code customizations. For example, you can override the LoadData, 
        // CreateWhereClause, DataBind, SaveData, GetUIData, and Validate methods.
        
}

  

#endregion

  

#region "Section 2: Do not modify this section."
    
    
// Base class for the MvwISDJobPhaseXrefRecordControl control on the Edit_MvwISDJobPhaseXref page.
// Do not modify this class. Instead override any method in MvwISDJobPhaseXrefRecordControl.
public class BaseMvwISDJobPhaseXrefRecordControl : VPLookup.UI.BaseApplicationRecordControl
{
        public BaseMvwISDJobPhaseXrefRecordControl()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        // To customize, override this method in MvwISDJobPhaseXrefRecordControl.
        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
        
            
            string url = "";
            if (url == null) url = ""; //avoid warning on VS
            // Setup the filter and search events.
                
            this.ClearControlsFromSession();
        }

        // To customize, override this method in MvwISDJobPhaseXrefRecordControl.
        protected virtual void Control_Load(object sender, System.EventArgs e)
        {      
        
              // Setup the pagination events.	  
                     
        
              // Register the event handlers.

          
              this.JobKey.SelectedIndexChanged += JobKey_SelectedIndexChanged;                  
                
              this.CGCCo.TextChanged += CGCCo_TextChanged;
            
              this.CGCJob.TextChanged += CGCJob_TextChanged;
            
              this.CostTypeCode.TextChanged += CostTypeCode_TextChanged;
            
              this.CostTypeDesc.TextChanged += CostTypeDesc_TextChanged;
            
              this.CustomerKey.TextChanged += CustomerKey_TextChanged;
            
              this.PhaseKey.TextChanged += PhaseKey_TextChanged;
            
              this.POC.TextChanged += POC_TextChanged;
            
              this.POCName.TextChanged += POCName_TextChanged;
            
              this.SalesPerson.TextChanged += SalesPerson_TextChanged;
            
              this.SalesPersonName.TextChanged += SalesPersonName_TextChanged;
            
              this.VPCo.TextChanged += VPCo_TextChanged;
            
              this.VPCustomer.TextChanged += VPCustomer_TextChanged;
            
              this.VPCustomerName.TextChanged += VPCustomerName_TextChanged;
            
              this.VPJob.TextChanged += VPJob_TextChanged;
            
              this.VPJobDesc.TextChanged += VPJobDesc_TextChanged;
            
              this.VPPhase.TextChanged += VPPhase_TextChanged;
            
              this.VPPhaseDescription.TextChanged += VPPhaseDescription_TextChanged;
            
              this.VPPhaseGroup.TextChanged += VPPhaseGroup_TextChanged;
            
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
      
            // This is the first time a record is being retrieved from the database.
            // So create a Where Clause based on the staic Where clause specified
            // on the Query wizard and the dynamic part specified by the end user
            // on the search and filter controls (if any).
            
            WhereClause wc = this.CreateWhereClause();
            
            System.Web.UI.WebControls.Panel Panel = (System.Web.UI.WebControls.Panel)MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefRecordControlPanel");
            if (Panel != null){
                Panel.Visible = true;
            }
            
            // If there is no Where clause, then simply create a new, blank record.
            
            if (wc == null || !(wc.RunQuery)) {
                this.DataSource = new MvwISDJobPhaseXrefRecord();
            
                if (Panel != null){
                    Panel.Visible = false;
                }
              
                return;
            }
          
            // Retrieve the record from the database.  It is possible
            MvwISDJobPhaseXrefRecord[] recList = MvwISDJobPhaseXrefView.GetRecords(wc, null, 0, 2);
            if (recList.Length == 0) {
                // There is no data for this Where clause.
                wc.RunQuery = false;
                
                if (Panel != null){
                    Panel.Visible = false;
                }
                
                return;
            }
            
            // Set DataSource based on record retrieved from the database.
            this.DataSource = MvwISDJobPhaseXrefView.GetRecord(recList[0].GetID().ToXmlString(), true);
                  
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
                SetJobKey();
                SetJobKeyLabel();
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
        
        
        public virtual void SetCGCCo()
        {
            
                    
            // Set the CGCCo TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CGCCo is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCCoSpecified) {
                								
                // If the CGCCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CGCCo);
                                
                this.CGCCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCCo.Text = MvwISDJobPhaseXrefView.CGCCo.Format(MvwISDJobPhaseXrefView.CGCCo.DefaultValue);
            		
            }
            
              this.CGCCo.TextChanged += CGCCo_TextChanged;
                               
        }
                
        public virtual void SetCGCJob()
        {
            
                    
            // Set the CGCJob TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CGCJob is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCJobSpecified) {
                								
                // If the CGCJob is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CGCJob);
                                
                this.CGCJob.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCJob is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCJob.Text = MvwISDJobPhaseXrefView.CGCJob.Format(MvwISDJobPhaseXrefView.CGCJob.DefaultValue);
            		
            }
            
              this.CGCJob.TextChanged += CGCJob_TextChanged;
                               
        }
                
        public virtual void SetConversionNotes()
        {
            
                    
            // Set the ConversionNotes TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.ConversionNotes is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ConversionNotesSpecified) {
                								
                // If the ConversionNotes is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.ConversionNotes);
                                                
                this.ConversionNotes.Content = formattedValue;
                 
            } 
            
            else {
            
                // ConversionNotes is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
                    
            this.ConversionNotes.Content = MvwISDJobPhaseXrefView.ConversionNotes.Format(MvwISDJobPhaseXrefView.ConversionNotes.DefaultValue);
          		
            }
                               
        }
                
        public virtual void SetCostTypeCode()
        {
            
                    
            // Set the CostTypeCode TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CostTypeCode is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CostTypeCodeSpecified) {
                								
                // If the CostTypeCode is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CostTypeCode);
                                
                this.CostTypeCode.Text = formattedValue;
                   
            } 
            
            else {
            
                // CostTypeCode is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CostTypeCode.Text = MvwISDJobPhaseXrefView.CostTypeCode.Format(MvwISDJobPhaseXrefView.CostTypeCode.DefaultValue);
            		
            }
            
              this.CostTypeCode.TextChanged += CostTypeCode_TextChanged;
                               
        }
                
        public virtual void SetCostTypeDesc()
        {
            
                    
            // Set the CostTypeDesc TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CostTypeDesc is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CostTypeDescSpecified) {
                								
                // If the CostTypeDesc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CostTypeDesc);
                                
                this.CostTypeDesc.Text = formattedValue;
                   
            } 
            
            else {
            
                // CostTypeDesc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CostTypeDesc.Text = MvwISDJobPhaseXrefView.CostTypeDesc.Format(MvwISDJobPhaseXrefView.CostTypeDesc.DefaultValue);
            		
            }
            
              this.CostTypeDesc.TextChanged += CostTypeDesc_TextChanged;
                               
        }
                
        public virtual void SetCustomerKey()
        {
            
                    
            // Set the CustomerKey TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.CustomerKey is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CustomerKeySpecified) {
                								
                // If the CustomerKey is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.CustomerKey);
                                
                this.CustomerKey.Text = formattedValue;
                   
            } 
            
            else {
            
                // CustomerKey is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CustomerKey.Text = MvwISDJobPhaseXrefView.CustomerKey.Format(MvwISDJobPhaseXrefView.CustomerKey.DefaultValue);
            		
            }
            
              this.CustomerKey.TextChanged += CustomerKey_TextChanged;
                               
        }
                
        public virtual void SetJobKey()
        {
            				
        
        
            string selectedValue = null;
            
            // figure out the selectedValue
                  
            
            
            // Set the JobKey QuickSelector on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.
            
            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.JobKey is the ASP:QuickSelector on the webpage.
            
            // You can modify this method directly, or replace it with a call to
            //     base.SetJobKey();
            // and add your own custom code before or after the call to the base function.

            
            if (this.DataSource != null && this.DataSource.JobKeySpecified)
            {
                            
                // If the JobKey is non-NULL, then format the value.
                // The Format method will return the Display Foreign Key As (DFKA) value
                selectedValue = this.DataSource.JobKey;
                
            }
            else
            {
                
                // JobKey is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
                if (this.DataSource != null && this.DataSource.IsCreated)
                    selectedValue = null;
                else
                    selectedValue = MvwISDJobPhaseXrefView.JobKey.DefaultValue;
                				
            }			
                
            // Add the Please Select item.
            if (selectedValue == null || selectedValue == "")
                  MiscUtils.ResetSelectedItem(this.JobKey, new ListItem(this.Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
                        
                  
            // Populate the item(s) to the control
            
            this.JobKey.SetFieldMaxLength(50);
            
            System.Collections.Generic.IDictionary<string, object> variables = new System.Collections.Generic.Dictionary<string, object>();              
            FormulaEvaluator evaluator = new FormulaEvaluator();
              
            if (selectedValue != null &&
                selectedValue.Trim() != "" &&
                !MiscUtils.SetSelectedValue(this.JobKey, selectedValue) &&
                !MiscUtils.SetSelectedDisplayText(this.JobKey, selectedValue))
            {

                // construct a whereclause to query a record with DatabaseViewpoint%dbo.mvwISDJobXref.JobKey = selectedValue
                    
                CompoundFilter filter2 = new CompoundFilter(CompoundFilter.CompoundingOperators.And_Operator, null);
                WhereClause whereClause2 = new WhereClause();
                filter2.AddFilter(new BaseClasses.Data.ColumnValueFilter(MvwISDJobXrefView.JobKey, selectedValue, BaseClasses.Data.BaseFilter.ComparisonOperator.EqualsTo, false));
                whereClause2.AddFilter(filter2, CompoundFilter.CompoundingOperators.And_Operator);

                // Execute the query
                try
                {
                    MvwISDJobXrefRecord[] rc = MvwISDJobXrefView.GetRecords(whereClause2, new OrderBy(false, false), 0, 1);
                    System.Collections.Generic.IDictionary<string, object> vars = new System.Collections.Generic.Dictionary<string, object> ();
                    // if find a record, add it to the dropdown and set it as selected item
                    if (rc != null && rc.Length == 1)
                    {
                        MvwISDJobXrefRecord itemValue = rc[0];
                        string cvalue = null;
                        string fvalue = null;                        
                        if (itemValue.JobKeySpecified)
                            cvalue = itemValue.JobKey.ToString(); 
                        Boolean _isExpandableNonCompositeForeignKey = MvwISDJobPhaseXrefView.Instance.TableDefinition.IsExpandableNonCompositeForeignKey(MvwISDJobPhaseXrefView.JobKey);
                        if(_isExpandableNonCompositeForeignKey && MvwISDJobPhaseXrefView.JobKey.IsApplyDisplayAs)
                            fvalue = MvwISDJobPhaseXrefView.GetDFKA(itemValue, MvwISDJobPhaseXrefView.JobKey);
                        if ((!_isExpandableNonCompositeForeignKey) || (String.IsNullOrEmpty(fvalue)))
                            fvalue = itemValue.Format(MvwISDJobXrefView.VPCustomerName);
                            					
                        if (fvalue == null || fvalue.Trim() == "") fvalue = cvalue;
                        MiscUtils.ResetSelectedItem(this.JobKey, new ListItem(fvalue, cvalue));                      
                    }
                }
                catch
                {
                }

                    					
            }					
                        
              string url = this.ModifyRedirectUrl("../mvwISDJobXref/MvwISDJobXref-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.JobKey.PostBackUrl = url + "?Target=" + this.JobKey.ClientID + "&DFKA=" + (this.Page as BaseApplicationPage).Encrypt("VPCustomerName")+ "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("JobKey")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--PLEASE_SELECT--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:PleaseSelect"))+ "&Mode=" + (this.Page as BaseApplicationPage).Encrypt("FieldValueSingleSelection") + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.JobKey.Attributes["onClick"] = "initializePopupPage(this, '" + this.JobKey.PostBackUrl + "', false, event); return false;";                  
                      
                  
        }
                
        public virtual void SetPhaseKey()
        {
            
                    
            // Set the PhaseKey TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.PhaseKey is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.PhaseKeySpecified) {
                								
                // If the PhaseKey is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.PhaseKey);
                                
                this.PhaseKey.Text = formattedValue;
                   
            } 
            
            else {
            
                // PhaseKey is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.PhaseKey.Text = MvwISDJobPhaseXrefView.PhaseKey.Format(MvwISDJobPhaseXrefView.PhaseKey.DefaultValue);
            		
            }
            
              this.PhaseKey.TextChanged += PhaseKey_TextChanged;
                               
        }
                
        public virtual void SetPOC()
        {
            
                    
            // Set the POC TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.POC is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCSpecified) {
                								
                // If the POC is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.POC);
                                
                this.POC.Text = formattedValue;
                   
            } 
            
            else {
            
                // POC is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POC.Text = MvwISDJobPhaseXrefView.POC.Format(MvwISDJobPhaseXrefView.POC.DefaultValue);
            		
            }
            
              this.POC.TextChanged += POC_TextChanged;
                               
        }
                
        public virtual void SetPOCName()
        {
            
                    
            // Set the POCName TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.POCName is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.POCNameSpecified) {
                								
                // If the POCName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.POCName);
                                
                this.POCName.Text = formattedValue;
                   
            } 
            
            else {
            
                // POCName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.POCName.Text = MvwISDJobPhaseXrefView.POCName.Format(MvwISDJobPhaseXrefView.POCName.DefaultValue);
            		
            }
            
              this.POCName.TextChanged += POCName_TextChanged;
                               
        }
                
        public virtual void SetSalesPerson()
        {
            
                    
            // Set the SalesPerson TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.SalesPerson is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SalesPersonSpecified) {
                								
                // If the SalesPerson is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.SalesPerson);
                                
                this.SalesPerson.Text = formattedValue;
                   
            } 
            
            else {
            
                // SalesPerson is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SalesPerson.Text = MvwISDJobPhaseXrefView.SalesPerson.Format(MvwISDJobPhaseXrefView.SalesPerson.DefaultValue);
            		
            }
            
              this.SalesPerson.TextChanged += SalesPerson_TextChanged;
                               
        }
                
        public virtual void SetSalesPersonName()
        {
            
                    
            // Set the SalesPersonName TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.SalesPersonName is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.SalesPersonNameSpecified) {
                								
                // If the SalesPersonName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.SalesPersonName);
                                
                this.SalesPersonName.Text = formattedValue;
                   
            } 
            
            else {
            
                // SalesPersonName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.SalesPersonName.Text = MvwISDJobPhaseXrefView.SalesPersonName.Format(MvwISDJobPhaseXrefView.SalesPersonName.DefaultValue);
            		
            }
            
              this.SalesPersonName.TextChanged += SalesPersonName_TextChanged;
                               
        }
                
        public virtual void SetVPCo()
        {
            
                    
            // Set the VPCo TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPCo is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCoSpecified) {
                								
                // If the VPCo is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPCo);
                                
                this.VPCo.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCo is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCo.Text = MvwISDJobPhaseXrefView.VPCo.Format(MvwISDJobPhaseXrefView.VPCo.DefaultValue);
            		
            }
            
              this.VPCo.TextChanged += VPCo_TextChanged;
                               
        }
                
        public virtual void SetVPCustomer()
        {
            
                    
            // Set the VPCustomer TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPCustomer is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerSpecified) {
                								
                // If the VPCustomer is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPCustomer);
                                
                this.VPCustomer.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomer is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomer.Text = MvwISDJobPhaseXrefView.VPCustomer.Format(MvwISDJobPhaseXrefView.VPCustomer.DefaultValue);
            		
            }
            
              this.VPCustomer.TextChanged += VPCustomer_TextChanged;
                               
        }
                
        public virtual void SetVPCustomerName()
        {
            
                    
            // Set the VPCustomerName TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPCustomerName is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPCustomerNameSpecified) {
                								
                // If the VPCustomerName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPCustomerName);
                                
                this.VPCustomerName.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPCustomerName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPCustomerName.Text = MvwISDJobPhaseXrefView.VPCustomerName.Format(MvwISDJobPhaseXrefView.VPCustomerName.DefaultValue);
            		
            }
            
              this.VPCustomerName.TextChanged += VPCustomerName_TextChanged;
                               
        }
                
        public virtual void SetVPJob()
        {
            
                    
            // Set the VPJob TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPJob is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPJobSpecified) {
                								
                // If the VPJob is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPJob);
                                
                this.VPJob.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPJob is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPJob.Text = MvwISDJobPhaseXrefView.VPJob.Format(MvwISDJobPhaseXrefView.VPJob.DefaultValue);
            		
            }
            
              this.VPJob.TextChanged += VPJob_TextChanged;
                               
        }
                
        public virtual void SetVPJobDesc()
        {
            
                    
            // Set the VPJobDesc TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPJobDesc is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPJobDescSpecified) {
                								
                // If the VPJobDesc is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPJobDesc);
                                
                this.VPJobDesc.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPJobDesc is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPJobDesc.Text = MvwISDJobPhaseXrefView.VPJobDesc.Format(MvwISDJobPhaseXrefView.VPJobDesc.DefaultValue);
            		
            }
            
              this.VPJobDesc.TextChanged += VPJobDesc_TextChanged;
                               
        }
                
        public virtual void SetVPPhase()
        {
            
                    
            // Set the VPPhase TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPPhase is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPPhaseSpecified) {
                								
                // If the VPPhase is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPPhase);
                                
                this.VPPhase.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPPhase is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPPhase.Text = MvwISDJobPhaseXrefView.VPPhase.Format(MvwISDJobPhaseXrefView.VPPhase.DefaultValue);
            		
            }
            
              this.VPPhase.TextChanged += VPPhase_TextChanged;
                               
        }
                
        public virtual void SetVPPhaseDescription()
        {
            
                    
            // Set the VPPhaseDescription TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPPhaseDescription is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPPhaseDescriptionSpecified) {
                								
                // If the VPPhaseDescription is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPPhaseDescription);
                                
                this.VPPhaseDescription.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPPhaseDescription is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPPhaseDescription.Text = MvwISDJobPhaseXrefView.VPPhaseDescription.Format(MvwISDJobPhaseXrefView.VPPhaseDescription.DefaultValue);
            		
            }
            
              this.VPPhaseDescription.TextChanged += VPPhaseDescription_TextChanged;
                               
        }
                
        public virtual void SetVPPhaseGroup()
        {
            
                    
            // Set the VPPhaseGroup TextBox on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDJobPhaseXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDJobPhaseXref record retrieved from the database.
            // this.VPPhaseGroup is the ASP:TextBox on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPPhaseGroupSpecified) {
                								
                // If the VPPhaseGroup is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDJobPhaseXrefView.VPPhaseGroup);
                                
                this.VPPhaseGroup.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPPhaseGroup is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPPhaseGroup.Text = MvwISDJobPhaseXrefView.VPPhaseGroup.Format(MvwISDJobPhaseXrefView.VPPhaseGroup.DefaultValue);
            		
            }
            
              this.VPPhaseGroup.TextChanged += VPPhaseGroup_TextChanged;
                               
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
                
        public virtual void SetJobKeyLabel()
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
        
            System.Web.UI.WebControls.Panel Panel = (System.Web.UI.WebControls.Panel)MiscUtils.FindControlRecursively(this, "MvwISDJobPhaseXrefRecordControlPanel");
            if ( (Panel != null && !Panel.Visible) || this.DataSource == null){
                return;
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
        
            GetCGCCo();
            GetCGCJob();
            GetConversionNotes();
            GetCostTypeCode();
            GetCostTypeDesc();
            GetCustomerKey();
            GetJobKey();
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
            
            // Retrieve the value entered by the user on the CGCCo ASP:TextBox, and
            // save it into the CGCCo field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.CGCCo.Text, MvwISDJobPhaseXrefView.CGCCo);							
                          
                      
        }
                
        public virtual void GetCGCJob()
        {
            
            // Retrieve the value entered by the user on the CGCJob ASP:TextBox, and
            // save it into the CGCJob field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.CGCJob.Text, MvwISDJobPhaseXrefView.CGCJob);							
                          
                      
        }
                
        public virtual void GetConversionNotes()
        {
            
            // Retrieve the value entered by the user on the ConversionNotes ASP:TextBox, and
            // save it into the ConversionNotes field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.ConversionNotes.Content, MvwISDJobPhaseXrefView.ConversionNotes);							
                          
                      
        }
                
        public virtual void GetCostTypeCode()
        {
            
            // Retrieve the value entered by the user on the CostTypeCode ASP:TextBox, and
            // save it into the CostTypeCode field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.CostTypeCode.Text, MvwISDJobPhaseXrefView.CostTypeCode);							
                          
                      
        }
                
        public virtual void GetCostTypeDesc()
        {
            
            // Retrieve the value entered by the user on the CostTypeDesc ASP:TextBox, and
            // save it into the CostTypeDesc field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.CostTypeDesc.Text, MvwISDJobPhaseXrefView.CostTypeDesc);							
                          
                      
        }
                
        public virtual void GetCustomerKey()
        {
            
            // Retrieve the value entered by the user on the CustomerKey ASP:TextBox, and
            // save it into the CustomerKey field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.CustomerKey.Text, MvwISDJobPhaseXrefView.CustomerKey);							
                          
                      
        }
                
        public virtual void GetJobKey()
        {
         // Retrieve the value entered by the user on the JobKey ASP:QuickSelector, and
            // save it into the JobKey field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
            
            this.DataSource.Parse(MiscUtils.GetValueSelectedPageRequest(this.JobKey), MvwISDJobPhaseXrefView.JobKey);			
                			 
        }
                
        public virtual void GetPhaseKey()
        {
            
            // Retrieve the value entered by the user on the PhaseKey ASP:TextBox, and
            // save it into the PhaseKey field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.PhaseKey.Text, MvwISDJobPhaseXrefView.PhaseKey);							
                          
                      
        }
                
        public virtual void GetPOC()
        {
            
            // Retrieve the value entered by the user on the POC ASP:TextBox, and
            // save it into the POC field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.POC.Text, MvwISDJobPhaseXrefView.POC);							
                          
                      
        }
                
        public virtual void GetPOCName()
        {
            
            // Retrieve the value entered by the user on the POCName ASP:TextBox, and
            // save it into the POCName field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.POCName.Text, MvwISDJobPhaseXrefView.POCName);							
                          
                      
        }
                
        public virtual void GetSalesPerson()
        {
            
            // Retrieve the value entered by the user on the SalesPerson ASP:TextBox, and
            // save it into the SalesPerson field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.SalesPerson.Text, MvwISDJobPhaseXrefView.SalesPerson);							
                          
                      
        }
                
        public virtual void GetSalesPersonName()
        {
            
            // Retrieve the value entered by the user on the SalesPersonName ASP:TextBox, and
            // save it into the SalesPersonName field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.SalesPersonName.Text, MvwISDJobPhaseXrefView.SalesPersonName);							
                          
                      
        }
                
        public virtual void GetVPCo()
        {
            
            // Retrieve the value entered by the user on the VPCo ASP:TextBox, and
            // save it into the VPCo field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.VPCo.Text, MvwISDJobPhaseXrefView.VPCo);							
                          
                      
        }
                
        public virtual void GetVPCustomer()
        {
            
            // Retrieve the value entered by the user on the VPCustomer ASP:TextBox, and
            // save it into the VPCustomer field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.VPCustomer.Text, MvwISDJobPhaseXrefView.VPCustomer);							
                          
                      
        }
                
        public virtual void GetVPCustomerName()
        {
            
            // Retrieve the value entered by the user on the VPCustomerName ASP:TextBox, and
            // save it into the VPCustomerName field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.VPCustomerName.Text, MvwISDJobPhaseXrefView.VPCustomerName);							
                          
                      
        }
                
        public virtual void GetVPJob()
        {
            
            // Retrieve the value entered by the user on the VPJob ASP:TextBox, and
            // save it into the VPJob field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.VPJob.Text, MvwISDJobPhaseXrefView.VPJob);							
                          
                      
        }
                
        public virtual void GetVPJobDesc()
        {
            
            // Retrieve the value entered by the user on the VPJobDesc ASP:TextBox, and
            // save it into the VPJobDesc field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.VPJobDesc.Text, MvwISDJobPhaseXrefView.VPJobDesc);							
                          
                      
        }
                
        public virtual void GetVPPhase()
        {
            
            // Retrieve the value entered by the user on the VPPhase ASP:TextBox, and
            // save it into the VPPhase field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.VPPhase.Text, MvwISDJobPhaseXrefView.VPPhase);							
                          
                      
        }
                
        public virtual void GetVPPhaseDescription()
        {
            
            // Retrieve the value entered by the user on the VPPhaseDescription ASP:TextBox, and
            // save it into the VPPhaseDescription field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.VPPhaseDescription.Text, MvwISDJobPhaseXrefView.VPPhaseDescription);							
                          
                      
        }
                
        public virtual void GetVPPhaseGroup()
        {
            
            // Retrieve the value entered by the user on the VPPhaseGroup ASP:TextBox, and
            // save it into the VPPhaseGroup field in DataSource DatabaseViewpoint%dbo.mvwISDJobPhaseXref record.
            
            // Custom validation should be performed in Validate, not here.
                    
            // Save the value to data source
            this.DataSource.Parse(this.VPPhaseGroup.Text, MvwISDJobPhaseXrefView.VPPhaseGroup);							
                          
                      
        }
                

      // To customize, override this method in MvwISDJobPhaseXrefRecordControl.
      
        public virtual WhereClause CreateWhereClause()
         
        {
//Bryan Check
    
            bool hasFiltersMvwISDJobPhaseXrefRecordControl = false;
            hasFiltersMvwISDJobPhaseXrefRecordControl = hasFiltersMvwISDJobPhaseXrefRecordControl && false; // suppress warning
      
//
        
            WhereClause wc;
            MvwISDJobPhaseXrefView.Instance.InnerFilter = null;
            wc = new WhereClause();
            
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.

              
            // Retrieve the record id from the URL parameter.
              
            string recId = ((BaseApplicationPage)(this.Page)).Decrypt(this.Page.Request.QueryString["MvwISDJobPhaseXref"]);
                
            if (recId == null || recId.Length == 0) {
                // Get the error message from the application resource file.
                throw new Exception(Page.GetResourceValue("Err:UrlParamMissing", "VPLookup").Replace("{URL}", "MvwISDJobPhaseXref"));
            }
            HttpContext.Current.Session["QueryString in Edit-MvwISDJobPhaseXref"] = recId;
                  
            if (KeyValue.IsXmlKey(recId)) {
                // Keys are typically passed as XML structures to handle composite keys.
                // If XML, then add a Where clause based on the Primary Key in the XML.
                KeyValue pkValue = KeyValue.XmlToKey(recId);
            
                wc.iAND(MvwISDJobPhaseXrefView.PhaseKey, BaseFilter.ComparisonOperator.EqualsTo, pkValue.GetColumnValueString(MvwISDJobPhaseXrefView.PhaseKey));
          
            }
            else {
                // The URL parameter contains the actual value, not an XML structure.
            
                wc.iAND(MvwISDJobPhaseXrefView.PhaseKey, BaseFilter.ComparisonOperator.EqualsTo, recId);
             
            }
              
            return wc;
          
        }
        
        
        public virtual WhereClause CreateWhereClause(String searchText, String fromSearchControl, String AutoTypeAheadSearch, String AutoTypeAheadWordSeparators)
        {
            // This CreateWhereClause is used for loading list of suggestions for Auto Type-Ahead feature.
            MvwISDJobPhaseXrefView.Instance.InnerFilter = null;
            WhereClause wc= new WhereClause();
        
//Bryan Check
    
            bool hasFiltersMvwISDJobPhaseXrefRecordControl = false;
            hasFiltersMvwISDJobPhaseXrefRecordControl = hasFiltersMvwISDJobPhaseXrefRecordControl && false; // suppress warning
      
//
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            String appRelativeVirtualPath = (String)HttpContext.Current.Session["AppRelativeVirtualPath"];
            
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
          MvwISDJobPhaseXrefView.DeleteRecord(pkValue);
          
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
        
        protected virtual void JobKey_SelectedIndexChanged(object sender, EventArgs args)
        {
          									

        }
                      
                    
        protected virtual void CGCCo_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void CGCJob_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void ConversionNotes_TextChanged(object sender, EventArgs args)
        {
                    
                // this event handler is not supported since ConversionNotes is an Ajax HTML Editor.
              
              }
            
        protected virtual void CostTypeCode_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void CostTypeDesc_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void CustomerKey_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void PhaseKey_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void POC_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void POCName_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void SalesPerson_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void SalesPersonName_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void VPCo_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void VPCustomer_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void VPCustomerName_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void VPJob_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void VPJobDesc_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void VPPhase_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void VPPhaseDescription_TextChanged(object sender, EventArgs args)
        {
                    
              }
            
        protected virtual void VPPhaseGroup_TextChanged(object sender, EventArgs args)
        {
                    
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
                return (string)this.ViewState["BaseMvwISDJobPhaseXrefRecordControl_Rec"];
            }
            set {
                this.ViewState["BaseMvwISDJobPhaseXrefRecordControl_Rec"] = value;
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
        
        public System.Web.UI.WebControls.TextBox CGCCo {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal CGCCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox CGCJob {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCJob");
            }
        }
            
        public System.Web.UI.WebControls.Literal CGCJobLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCJobLabel");
            }
        }
        
              public AjaxControlToolkit.HTMLEditor.Editor ConversionNotes {
              get {
                  return (AjaxControlToolkit.HTMLEditor.Editor)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ConversionNotes");
                  }
              }
          
        public System.Web.UI.WebControls.Literal ConversionNotesLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ConversionNotesLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox CostTypeCode {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeCode");
            }
        }
            
        public System.Web.UI.WebControls.Literal CostTypeCodeLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeCodeLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox CostTypeDesc {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeDesc");
            }
        }
            
        public System.Web.UI.WebControls.Literal CostTypeDescLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CostTypeDescLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox CustomerKey {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CustomerKey");
            }
        }
            
        public System.Web.UI.WebControls.Literal CustomerKeyLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CustomerKeyLabel");
            }
        }
        
        public BaseClasses.Web.UI.WebControls.QuickSelector JobKey {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobKey");
            }
        }              
            
        public System.Web.UI.WebControls.Literal JobKeyLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "JobKeyLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox PhaseKey {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PhaseKey");
            }
        }
            
        public System.Web.UI.WebControls.Literal PhaseKeyLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "PhaseKeyLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox POC {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POC");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox POCName {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCName");
            }
        }
            
        public System.Web.UI.WebControls.Literal POCNameLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "POCNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox SalesPerson {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPerson");
            }
        }
            
        public System.Web.UI.WebControls.Literal SalesPersonLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox SalesPersonName {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonName");
            }
        }
            
        public System.Web.UI.WebControls.Literal SalesPersonNameLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SalesPersonNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal Title {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Title");
            }
        }
        
        public System.Web.UI.WebControls.TextBox VPCo {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCo");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCoLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCoLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox VPCustomer {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomer");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomerLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox VPCustomerName {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerName");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPCustomerNameLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPCustomerNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox VPJob {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJob");
            }
        }
            
        public System.Web.UI.WebControls.TextBox VPJobDesc {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPJobDesc");
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
        
        public System.Web.UI.WebControls.TextBox VPPhase {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhase");
            }
        }
            
        public System.Web.UI.WebControls.TextBox VPPhaseDescription {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhaseDescription");
            }
        }
            
        public System.Web.UI.WebControls.Literal VPPhaseDescriptionLabel {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhaseDescriptionLabel");
            }
        }
        
        public System.Web.UI.WebControls.TextBox VPPhaseGroup {
            get {
                return (System.Web.UI.WebControls.TextBox)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPPhaseGroup");
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

  

#endregion
    
  
}

  