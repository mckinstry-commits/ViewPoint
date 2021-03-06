﻿
// This file implements the TableControl, TableControlRow, and RecordControl classes for the 
// Show_MvwISDVendorXref_Table.aspx page.  The Row or RecordControl classes are the 
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

  
namespace VPLookup.UI.Controls.Show_MvwISDVendorXref_Table
{
  

#region "Section 1: Place your customizations here."

    
public class MvwISDVendorXrefTableControlRow : BaseMvwISDVendorXrefTableControlRow
{
      
        // The BaseMvwISDVendorXrefTableControlRow implements code for a ROW within the
        // the MvwISDVendorXrefTableControl table.  The BaseMvwISDVendorXrefTableControlRow implements the DataBind and SaveData methods.
        // The loading of data is actually performed by the LoadData method in the base class of MvwISDVendorXrefTableControl.

        // This is the ideal place to add your code customizations. For example, you can override the DataBind, 
        // SaveData, GetUIData, and Validate methods.
        
}

  

public class MvwISDVendorXrefTableControl : BaseMvwISDVendorXrefTableControl
{
    // The BaseMvwISDVendorXrefTableControl class implements the LoadData, DataBind, CreateWhereClause
    // and other methods to load and display the data in a table control.

    // This is the ideal place to add your code customizations. You can override the LoadData and CreateWhereClause,
    // The MvwISDVendorXrefTableControlRow class offers another place where you can customize
    // the DataBind, GetUIData, SaveData and Validate methods specific to each row displayed on the table.

}

  

#endregion

  

#region "Section 2: Do not modify this section."
    
    
// Base class for the MvwISDVendorXrefTableControlRow control on the Show_MvwISDVendorXref_Table page.
// Do not modify this class. Instead override any method in MvwISDVendorXrefTableControlRow.
public class BaseMvwISDVendorXrefTableControlRow : VPLookup.UI.BaseApplicationRecordControl
{
        public BaseMvwISDVendorXrefTableControlRow()
        {
            this.Init += Control_Init;
            this.Load += Control_Load;
            this.PreRender += Control_PreRender;
            this.EvaluateFormulaDelegate = new DataSource.EvaluateFormulaDelegate(this.EvaluateFormula);
        }

        // To customize, override this method in MvwISDVendorXrefTableControlRow.
        protected virtual void Control_Init(object sender, System.EventArgs e)
        {
                
            this.ClearControlsFromSession();
        }

        // To customize, override this method in MvwISDVendorXrefTableControlRow.
        protected virtual void Control_Load(object sender, System.EventArgs e)
        {      
                    
        
              // Register the event handlers.

          
                    this.ViewRowButton.Click += ViewRowButton_Click;
                        
        }

        public virtual void LoadData()  
        {
            // Load the data from the database into the DataSource DatabaseViewpoint%dbo.mvwISDVendorXref record.
            // It is better to make changes to functions called by LoadData such as
            // CreateWhereClause, rather than making changes here.
            
        
            // The RecordUniqueId is set the first time a record is loaded, and is
            // used during a PostBack to load the record.
            if (this.RecordUniqueId != null && this.RecordUniqueId.Length > 0) {
              
                this.DataSource = MvwISDVendorXrefView.GetRecord(this.RecordUniqueId, true);
              
                return;
            }
      
            // Since this is a row in the table, the data for this row is loaded by the 
            // LoadData method of the BaseMvwISDVendorXrefTableControl when the data for the entire
            // table is loaded.
            
            this.DataSource = new MvwISDVendorXrefRecord();
            
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
                SetCGCVendor();
                SetCity();
                SetIsSubcontractor();
                SetState();
                SetVendorName();
                
                SetVPVendor();
                SetZip();
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
            
        }
        
        
        public virtual void SetAddress()
        {
            
                    
            // Set the Address Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.Address is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.AddressSpecified) {
                								
                // If the Address is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.Address);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Address.Text = formattedValue;
                   
            } 
            
            else {
            
                // Address is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Address.Text = MvwISDVendorXrefView.Address.Format(MvwISDVendorXrefView.Address.DefaultValue);
            		
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
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.Address2 is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.Address2Specified) {
                								
                // If the Address2 is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.Address2);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Address2.Text = formattedValue;
                   
            } 
            
            else {
            
                // Address2 is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Address2.Text = MvwISDVendorXrefView.Address2.Format(MvwISDVendorXrefView.Address2.DefaultValue);
            		
            }
            
            // If the Address2 is NULL or blank, then use the value specified  
            // on Properties.
            if (this.Address2.Text == null ||
                this.Address2.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.Address2.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCGCVendor()
        {
            
                    
            // Set the CGCVendor Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.CGCVendor is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CGCVendorSpecified) {
                								
                // If the CGCVendor is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.CGCVendor);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.CGCVendor.Text = formattedValue;
                   
            } 
            
            else {
            
                // CGCVendor is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.CGCVendor.Text = MvwISDVendorXrefView.CGCVendor.Format(MvwISDVendorXrefView.CGCVendor.DefaultValue);
            		
            }
            
            // If the CGCVendor is NULL or blank, then use the value specified  
            // on Properties.
            if (this.CGCVendor.Text == null ||
                this.CGCVendor.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.CGCVendor.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetCity()
        {
            
                    
            // Set the City Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.City is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.CitySpecified) {
                								
                // If the City is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.City);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.City.Text = formattedValue;
                   
            } 
            
            else {
            
                // City is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.City.Text = MvwISDVendorXrefView.City.Format(MvwISDVendorXrefView.City.DefaultValue);
            		
            }
            
            // If the City is NULL or blank, then use the value specified  
            // on Properties.
            if (this.City.Text == null ||
                this.City.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.City.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetIsSubcontractor()
        {
            
                    
            // Set the IsSubcontractor Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.IsSubcontractor is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.IsSubcontractorSpecified) {
                								
                // If the IsSubcontractor is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.IsSubcontractor);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.IsSubcontractor.Text = formattedValue;
                   
            } 
            
            else {
            
                // IsSubcontractor is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.IsSubcontractor.Text = MvwISDVendorXrefView.IsSubcontractor.Format(MvwISDVendorXrefView.IsSubcontractor.DefaultValue);
            		
            }
            
            // If the IsSubcontractor is NULL or blank, then use the value specified  
            // on Properties.
            if (this.IsSubcontractor.Text == null ||
                this.IsSubcontractor.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.IsSubcontractor.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetState()
        {
            
                    
            // Set the State Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.State is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.StateSpecified) {
                								
                // If the State is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.State);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.State.Text = formattedValue;
                   
            } 
            
            else {
            
                // State is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.State.Text = MvwISDVendorXrefView.State.Format(MvwISDVendorXrefView.State.DefaultValue);
            		
            }
            
            // If the State is NULL or blank, then use the value specified  
            // on Properties.
            if (this.State.Text == null ||
                this.State.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.State.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVendorName()
        {
            
                    
            // Set the VendorName Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.VendorName is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VendorNameSpecified) {
                								
                // If the VendorName is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.VendorName);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VendorName.Text = formattedValue;
                   
            } 
            
            else {
            
                // VendorName is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VendorName.Text = MvwISDVendorXrefView.VendorName.Format(MvwISDVendorXrefView.VendorName.DefaultValue);
            		
            }
            
            // If the VendorName is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VendorName.Text == null ||
                this.VendorName.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VendorName.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetVPVendor()
        {
            
                    
            // Set the VPVendor Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.VPVendor is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.VPVendorSpecified) {
                								
                // If the VPVendor is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.VPVendor);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.VPVendor.Text = formattedValue;
                   
            } 
            
            else {
            
                // VPVendor is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.VPVendor.Text = MvwISDVendorXrefView.VPVendor.Format(MvwISDVendorXrefView.VPVendor.DefaultValue);
            		
            }
            
            // If the VPVendor is NULL or blank, then use the value specified  
            // on Properties.
            if (this.VPVendor.Text == null ||
                this.VPVendor.Text.Trim().Length == 0) {
                // Set the value specified on the Properties.
                this.VPVendor.Text = "&nbsp;";
            }
                                     
        }
                
        public virtual void SetZip()
        {
            
                    
            // Set the Zip Literal on the webpage with value from the
            // DatabaseViewpoint%dbo.mvwISDVendorXref database record.

            // this.DataSource is the DatabaseViewpoint%dbo.mvwISDVendorXref record retrieved from the database.
            // this.Zip is the ASP:Literal on the webpage.
                  
            if (this.DataSource != null && this.DataSource.ZipSpecified) {
                								
                // If the Zip is non-NULL, then format the value.
                // The Format method will use the Display Format
               string formattedValue = this.DataSource.Format(MvwISDVendorXrefView.Zip);
                                
                formattedValue = HttpUtility.HtmlEncode(formattedValue);
                this.Zip.Text = formattedValue;
                   
            } 
            
            else {
            
                // Zip is NULL in the database, so use the Default Value.  
                // Default Value could also be NULL.
        
              this.Zip.Text = MvwISDVendorXrefView.Zip.Format(MvwISDVendorXrefView.Zip.DefaultValue);
            		
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
                ((MvwISDVendorXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDVendorXrefTableControl")).DataChanged = true;
                ((MvwISDVendorXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDVendorXrefTableControl")).ResetData = true;
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
            GetCGCVendor();
            GetCity();
            GetIsSubcontractor();
            GetState();
            GetVendorName();
            GetVPVendor();
            GetZip();
        }
        
        
        public virtual void GetAddress()
        {
            
        }
                
        public virtual void GetAddress2()
        {
            
        }
                
        public virtual void GetCGCVendor()
        {
            
        }
                
        public virtual void GetCity()
        {
            
        }
                
        public virtual void GetIsSubcontractor()
        {
            
        }
                
        public virtual void GetState()
        {
            
        }
                
        public virtual void GetVendorName()
        {
            
        }
                
        public virtual void GetVPVendor()
        {
            
        }
                
        public virtual void GetZip()
        {
            
        }
                

      // To customize, override this method in MvwISDVendorXrefTableControlRow.
      
        public virtual WhereClause CreateWhereClause()
         
        {
//Bryan Check
    
            bool hasFiltersMvwISDVendorXrefTableControl = false;
            hasFiltersMvwISDVendorXrefTableControl = hasFiltersMvwISDVendorXrefTableControl && false; // suppress warning
      
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
          MvwISDVendorXrefView.DeleteRecord(pkValue);
          
              
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            ((MvwISDVendorXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDVendorXrefTableControl")).DataChanged = true;
            ((MvwISDVendorXrefTableControl)MiscUtils.GetParentControlObject(this, "MvwISDVendorXrefTableControl")).ResetData = true;
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
        
        public virtual void SetViewRowButton()                
              
        {
        
   
        }
            
        // event handler for ImageButton
        public virtual void ViewRowButton_Click(object sender, ImageClickEventArgs args)
        {
              
            // The redirect URL is set on the Properties, Custom Properties or Actions.
            // The ModifyRedirectURL call resolves the parameters before the
            // Response.Redirect redirects the page to the URL.  
            // Any code after the Response.Redirect call will not be executed, since the page is
            // redirected to the URL.
            
            string url = @"../mvwISDVendorXref/Show-MvwISDVendorXref.aspx?MvwISDVendorXref={PK}";
            
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
                return (string)this.ViewState["BaseMvwISDVendorXrefTableControlRow_Rec"];
            }
            set {
                this.ViewState["BaseMvwISDVendorXrefTableControlRow_Rec"] = value;
            }
        }
        
        public MvwISDVendorXrefRecord DataSource {
            get {
                return (MvwISDVendorXrefRecord)(this._DataSource);
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
            
        public System.Web.UI.WebControls.Literal CGCVendor {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCVendor");
            }
        }
            
        public System.Web.UI.WebControls.Literal City {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "City");
            }
        }
            
        public System.Web.UI.WebControls.Literal IsSubcontractor {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "IsSubcontractor");
            }
        }
            
        public System.Web.UI.WebControls.Literal State {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "State");
            }
        }
            
        public System.Web.UI.WebControls.Literal VendorName {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VendorName");
            }
        }
            
        public System.Web.UI.WebControls.ImageButton ViewRowButton {
            get {
                return (System.Web.UI.WebControls.ImageButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ViewRowButton");
            }
        }
        
        public System.Web.UI.WebControls.Literal VPVendor {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPVendor");
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
    MvwISDVendorXrefRecord rec = null;
             
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
    MvwISDVendorXrefRecord rec = null;
    
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

    
        public virtual MvwISDVendorXrefRecord GetRecord()
             
        {
        
            if (this.DataSource != null) {
                return this.DataSource;
            }
            
            if (this.RecordUniqueId != null) {
              
                return MvwISDVendorXrefView.GetRecord(this.RecordUniqueId, true);
              
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

  
// Base class for the MvwISDVendorXrefTableControl control on the Show_MvwISDVendorXref_Table page.
// Do not modify this class. Instead override any method in MvwISDVendorXrefTableControl.
public class BaseMvwISDVendorXrefTableControl : VPLookup.UI.BaseApplicationTableControl
{
         

       public BaseMvwISDVendorXrefTableControl()
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
                if  (this.InSession(this.CityFilter)) 				
                    initialVal = this.GetFromSession(this.CityFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"City\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    string[] CityFilteritemListFromSession = initialVal.Split(',');
                    int index = 0;
                    foreach (string item in CityFilteritemListFromSession)
                    {
                        if (index == 0 && item.ToString().Equals(""))
                        {
                            // do nothing
                        }
                        else
                        {
                            this.CityFilter.Items.Add(item);
                            this.CityFilter.Items[index].Selected = true;
                            index += 1;
                        }
                    }
                    foreach (ListItem listItem in this.CityFilter.Items)
                    {
                        listItem.Selected = true;
                    }
                        
                    }
            }
            if (!this.Page.IsPostBack)
            {
                string initialVal = "";
                if  (this.InSession(this.IsSubcontractorFilter)) 				
                    initialVal = this.GetFromSession(this.IsSubcontractorFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"IsSubcontractor\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    string[] IsSubcontractorFilteritemListFromSession = initialVal.Split(',');
                    int index = 0;
                    foreach (string item in IsSubcontractorFilteritemListFromSession)
                    {
                        if (index == 0 && item.ToString().Equals(""))
                        {
                            // do nothing
                        }
                        else
                        {
                            this.IsSubcontractorFilter.Items.Add(item);
                            this.IsSubcontractorFilter.Items[index].Selected = true;
                            index += 1;
                        }
                    }
                    foreach (ListItem listItem in this.IsSubcontractorFilter.Items)
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
                if  (this.InSession(this.StateFilter)) 				
                    initialVal = this.GetFromSession(this.StateFilter);
                
                else
                    
                    initialVal = EvaluateFormula("URL(\"State\")");
                
                if(StringUtils.InvariantEquals(initialVal, "Search for", true) || StringUtils.InvariantEquals(initialVal, BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null), true))
                {
                initialVal = "";
                }
              
                if (initialVal != null && initialVal != "")		
                {
                        
                    this.StateFilter.Items.Add(new ListItem(initialVal, initialVal));
                        
                    this.StateFilter.SelectedValue = initialVal;
                            
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
          
              this.Address2Label.Click += Address2Label_Click;
            
              this.AddressLabel.Click += AddressLabel_Click;
            
              this.CGCVendorLabel.Click += CGCVendorLabel_Click;
            
              this.CityLabel.Click += CityLabel_Click;
            
              this.IsSubcontractorLabel.Click += IsSubcontractorLabel_Click;
            
              this.StateLabel.Click += StateLabel_Click;
            
              this.VendorNameLabel.Click += VendorNameLabel_Click;
            
              this.VPVendorLabel.Click += VPVendorLabel_Click;
            
              this.ZipLabel.Click += ZipLabel_Click;
            
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
                        
            this.OrderSort.SelectedIndexChanged += new EventHandler(OrderSort_SelectedIndexChanged);
            
              this.CityFilter.SelectedIndexChanged += CityFilter_SelectedIndexChanged;                  
                
              this.IsSubcontractorFilter.SelectedIndexChanged += IsSubcontractorFilter_SelectedIndexChanged;                  
                
            this.StateFilter.SelectedIndexChanged += new EventHandler(StateFilter_SelectedIndexChanged);
                    
        
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
                      Type myrec = typeof(VPLookup.Business.MvwISDVendorXrefRecord);
                      this.DataSource = (MvwISDVendorXrefRecord[])(alist.ToArray(myrec));
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
                    foreach (MvwISDVendorXrefTableControlRow rc in this.GetRecordControls()) {
                        if (!rc.IsNewRecord) {
                            rc.DataSource = rc.GetRecord();
                            rc.GetUIData();
                            postdata.Add(rc.DataSource);
                            UIData.Add(rc.PreservedUIData());
                        }
                    }
                    Type myrec = typeof(VPLookup.Business.MvwISDVendorXrefRecord);
                    this.DataSource = (MvwISDVendorXrefRecord[])(postdata.ToArray(myrec));
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
        
        public virtual MvwISDVendorXrefRecord[] GetRecords(BaseFilter join, WhereClause where, OrderBy orderBy, int pageIndex, int pageSize)
        {    
            // by default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               
    
            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecordCount as well
            // selCols.Add(MvwISDVendorXrefView.Column1, true);          
            // selCols.Add(MvwISDVendorXrefView.Column2, true);          
            // selCols.Add(MvwISDVendorXrefView.Column3, true);          
            

            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                  
            {
              
                return MvwISDVendorXrefView.GetRecords(join, where, orderBy, this.PageIndex, this.PageSize);
                 
            }
            else
            {
                MvwISDVendorXrefView databaseTable = new MvwISDVendorXrefView();
                databaseTable.SelectedColumns.Clear();
                databaseTable.SelectedColumns.AddRange(selCols);
                
            
                
                ArrayList recList; 
                orderBy.ExpandForeignKeyColums = false;
                recList = databaseTable.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
                return (recList.ToArray(typeof(MvwISDVendorXrefRecord)) as MvwISDVendorXrefRecord[]);
            }            
            
        }
        
        
        public virtual int GetRecordCount(BaseFilter join, WhereClause where)
        {

            // By default, Select * will be executed to get a list of records.  If you want to run Select Distinct with certain column only, add the column to selCols
            ColumnList selCols = new ColumnList();                 
               


            // If you want to specify certain columns to be in the select statement, you can write code similar to the following:
            // However, if you don't specify PK, row button click might show an error message.
            // And make sure you write similar code in GetRecords as well
            // selCols.Add(MvwISDVendorXrefView.Column1, true);          
            // selCols.Add(MvwISDVendorXrefView.Column2, true);          
            // selCols.Add(MvwISDVendorXrefView.Column3, true);          


            // If the parameters doesn't specify specific columns in the Select statement, then run Select *
            // Alternatively, if the parameters specifies to include PK, also run Select *
            
            if (selCols.Count == 0)                 
                     
            
                return MvwISDVendorXrefView.GetRecordCount(join, where);
            else
            {
                MvwISDVendorXrefView databaseTable = new MvwISDVendorXrefView();
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
        System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDVendorXrefTableControlRepeater"));
        if (rep == null){return;}
        rep.DataSource = this.DataSource;
        rep.DataBind();
          
        int index = 0;
        foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
        {
            // Loop through all rows in the table, set its DataSource and call DataBind().
            MvwISDVendorXrefTableControlRow recControl = (MvwISDVendorXrefTableControlRow)(repItem.FindControl("MvwISDVendorXrefTableControlRow"));
            recControl.DataSource = this.DataSource[index];            
            if (this.UIData.Count > index)
                recControl.PreviousUIData = this.UIData[index];
            recControl.DataBind();
            
           
            recControl.Visible = !this.InDeletedRecordIds(recControl);
        
            index++;
        }
           
    
            // Call the Set methods for each controls on the panel
        
                
                SetAddress2Label();
                SetAddressLabel();
                SetCGCVendorLabel();
                SetCityFilter();
                SetCityLabel();
                SetCityLabel1();
                
                
                
                
                SetIsSubcontractorFilter();
                SetIsSubcontractorLabel();
                SetIsSubcontractorLabel1();
                SetOrderSort();
                
                
                
                
                SetSearchText();
                SetSortByLabel();
                SetStateFilter();
                SetStateLabel();
                SetStateLabel1();
                
                SetVendorNameLabel();
                SetVPVendorLabel();
                
                SetZipLabel();
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


            
            this.CityFilter.ClearSelection();
            
            this.IsSubcontractorFilter.ClearSelection();
            
            this.StateFilter.ClearSelection();
            
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
    
            // Bind the buttons for MvwISDVendorXrefTableControl pagination.
        
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
              
            foreach (MvwISDVendorXrefTableControlRow recCtl in this.GetRecordControls())
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
            foreach (MvwISDVendorXrefTableControlRow recCtl in this.GetRecordControls()){
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
            MvwISDVendorXrefView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
    
            // CreateWhereClause() Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
        
            if (MiscUtils.IsValueSelected(this.CityFilter)) {
                        
                int selectedItemCount = 0;
                foreach (ListItem item in this.CityFilter.Items){
                    if (item.Selected) {
                        selectedItemCount += 1;
                        
                          
                    }
                }
                WhereClause filter = new WhereClause();
                foreach (ListItem item in this.CityFilter.Items){
                    if ((item.Selected) && ((item.Value == "--ANY--") || (item.Value == "--PLEASE_SELECT--")) && (selectedItemCount > 1)){
                        item.Selected = false;
                    }
                    if (item.Selected){
                        filter.iOR(MvwISDVendorXrefView.City, BaseFilter.ComparisonOperator.EqualsTo, item.Value, false, false);
                    }
                }
                wc.iAND(filter);
                    
            }
                      
            if (MiscUtils.IsValueSelected(this.IsSubcontractorFilter)) {
                        
                int selectedItemCount = 0;
                foreach (ListItem item in this.IsSubcontractorFilter.Items){
                    if (item.Selected) {
                        selectedItemCount += 1;
                        
                          
                    }
                }
                WhereClause filter = new WhereClause();
                foreach (ListItem item in this.IsSubcontractorFilter.Items){
                    if ((item.Selected) && ((item.Value == "--ANY--") || (item.Value == "--PLEASE_SELECT--")) && (selectedItemCount > 1)){
                        item.Selected = false;
                    }
                    if (item.Selected){
                        filter.iOR(MvwISDVendorXrefView.IsSubcontractor, BaseFilter.ComparisonOperator.EqualsTo, item.Value, false, false);
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
        
      cols.Add(MvwISDVendorXrefView.VendorName);
      
      cols.Add(MvwISDVendorXrefView.VPVendor);
      
      cols.Add(MvwISDVendorXrefView.CGCVendor);
      
      cols.Add(MvwISDVendorXrefView.City);
      
      cols.Add(MvwISDVendorXrefView.State);
      
      foreach(BaseColumn col in cols)
      {
      
                    search.iOR(col, BaseFilter.ComparisonOperator.Contains, MiscUtils.GetSelectedValue(this.SearchText, this.GetFromSession(this.SearchText)), true, false);
        
      }
    
                    wc.iAND(search);
                  
                }
            }
                  
            if (MiscUtils.IsValueSelected(this.StateFilter)) {
                        
                wc.iAND(MvwISDVendorXrefView.State, BaseFilter.ComparisonOperator.EqualsTo, MiscUtils.GetSelectedValue(this.StateFilter, this.GetFromSession(this.StateFilter)), false, false);
                    
            }
                      
            bool bAnyFiltersChanged = false;
            
            if (MiscUtils.IsValueSelected(this.CityFilter) || this.InSession(this.CityFilter)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.IsSubcontractorFilter) || this.InSession(this.IsSubcontractorFilter)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.SearchText) || this.InSession(this.SearchText)){
                bAnyFiltersChanged = true;
                }
            
            if (MiscUtils.IsValueSelected(this.StateFilter) || this.InSession(this.StateFilter)){
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
            MvwISDVendorXrefView.Instance.InnerFilter = null;
            WhereClause wc = new WhereClause();
        
            // Compose the WHERE clause consist of:
            // 1. Static clause defined at design time.
            // 2. User selected search criteria.
            // 3. User selected filter criteria.
            
            String appRelativeVirtualPath = (String)HttpContext.Current.Session["AppRelativeVirtualPath"];
            
            // Adds clauses if values are selected in Filter controls which are configured in the page.
          
      String CityFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "CityFilter_Ajax"];
            if (MiscUtils.IsValueSelected(CityFilterSelectedValue)) {

              
        if (CityFilterSelectedValue != null){
                        string[] CityFilteritemListFromSession = CityFilterSelectedValue.Split(',');
                        int index = 0;
                        WhereClause filter = new WhereClause();
                        foreach (string item in CityFilteritemListFromSession)
                        {
                            if (index == 0 && item.ToString().Equals(""))
                            {
                            }
                            else
                            {
                                filter.iOR(MvwISDVendorXrefView.City, BaseFilter.ComparisonOperator.EqualsTo, item, false, false);
                                index += 1;
                            }
                        }
                        wc.iAND(filter);
        }
                
      }
                      
      String IsSubcontractorFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "IsSubcontractorFilter_Ajax"];
            if (MiscUtils.IsValueSelected(IsSubcontractorFilterSelectedValue)) {

              
        if (IsSubcontractorFilterSelectedValue != null){
                        string[] IsSubcontractorFilteritemListFromSession = IsSubcontractorFilterSelectedValue.Split(',');
                        int index = 0;
                        WhereClause filter = new WhereClause();
                        foreach (string item in IsSubcontractorFilteritemListFromSession)
                        {
                            if (index == 0 && item.ToString().Equals(""))
                            {
                            }
                            else
                            {
                                filter.iOR(MvwISDVendorXrefView.IsSubcontractor, BaseFilter.ComparisonOperator.EqualsTo, item, false, false);
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
        
      cols.Add(MvwISDVendorXrefView.VendorName);
      
      cols.Add(MvwISDVendorXrefView.VPVendor);
      
      cols.Add(MvwISDVendorXrefView.CGCVendor);
      
      cols.Add(MvwISDVendorXrefView.City);
      
      cols.Add(MvwISDVendorXrefView.State);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Starts_With, formatedSearchText, true, false);
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, AutoTypeAheadWordSeparators + formatedSearchText, true, false);
                
      }
    
                    } else {
                        
      ColumnList cols = new ColumnList();    
        
      cols.Add(MvwISDVendorXrefView.VendorName);
      
      cols.Add(MvwISDVendorXrefView.VPVendor);
      
      cols.Add(MvwISDVendorXrefView.CGCVendor);
      
      cols.Add(MvwISDVendorXrefView.City);
      
      cols.Add(MvwISDVendorXrefView.State);
      
      foreach(BaseColumn col in cols)
      {
      
                        search.iOR(col, BaseFilter.ComparisonOperator.Contains, formatedSearchText, true, false);
      }
    
                    } 
                    wc.iAND(search);
                  
                }
            }
                  
      String StateFilterSelectedValue = (String)HttpContext.Current.Session[HttpContext.Current.Session.SessionID + appRelativeVirtualPath + "StateFilter_Ajax"];
            if (MiscUtils.IsValueSelected(StateFilterSelectedValue)) {

              
                wc.iAND(MvwISDVendorXrefView.State, BaseFilter.ComparisonOperator.EqualsTo, StateFilterSelectedValue, false, false);
                      
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
            VPLookup.Business.MvwISDVendorXrefRecord[] recordList  = MvwISDVendorXrefView.GetRecords(filterJoin, wc, null, 0, count, ref count);
            String resultItem = "";
            if (resultItem == "") resultItem = "";
            foreach (MvwISDVendorXrefRecord rec in recordList ){
                // Exit the loop if recordList count has reached AutoTypeAheadListSize.
                if (resultList.Count >= count) {
                    break;
                }
                // If the field is configured to Display as Foreign key, Format() method returns the 
                // Display as Forien Key value instead of original field value.
                // Since search had to be done in multiple fields (selected in Control's page property, binding tab) in a record,
                // We need to find relevent field to display which matches the prefixText and is not already present in the result list.
        
                resultItem = rec.Format(MvwISDVendorXrefView.VendorName);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDVendorXrefView.VendorName.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDVendorXrefView.VendorName.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDVendorXrefView.VPVendor);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDVendorXrefView.VPVendor.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDVendorXrefView.VPVendor.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDVendorXrefView.CGCVendor);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDVendorXrefView.CGCVendor.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDVendorXrefView.CGCVendor.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDVendorXrefView.City);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDVendorXrefView.City.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDVendorXrefView.City.IsFullTextSearchable);
                        if (isAdded) {
                            continue;
                        }
                    }
                }
      
                resultItem = rec.Format(MvwISDVendorXrefView.State);
  
                if (resultItem != null) {
                    string prText = prefixText;
                    if(MvwISDVendorXrefView.State.IsFullTextSearchable) {
                        FullTextExpression ft = new FullTextExpression();
                        prText = ft.GetFirstNonExcludedTerm(prText);
                    }
                    if (!string.IsNullOrEmpty(prText) && resultItem.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture).Contains(prText.ToUpper(System.Threading.Thread.CurrentThread.CurrentCulture))) {
                        bool isAdded = FormatSuggestions(prText, resultItem, 50, "InMiddleOfMatchedString", "WordsStartingWithSearchString", "[^a-zA-Z0-9]", resultList, MvwISDVendorXrefView.State.IsFullTextSearchable);
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
    System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "MvwISDVendorXrefTableControlRepeater"));
    if (rep == null){return;}

    foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
    {
    // Loop through all rows in the table, set its DataSource and call DataBind().
    MvwISDVendorXrefTableControlRow recControl = (MvwISDVendorXrefTableControlRow)(repItem.FindControl("MvwISDVendorXrefTableControlRow"));

      if (recControl.Visible && recControl.IsNewRecord) {
      MvwISDVendorXrefRecord rec = new MvwISDVendorXrefRecord();
        
                        if (recControl.Address.Text != "") {
                            rec.Parse(recControl.Address.Text, MvwISDVendorXrefView.Address);
                  }
                
                        if (recControl.Address2.Text != "") {
                            rec.Parse(recControl.Address2.Text, MvwISDVendorXrefView.Address2);
                  }
                
                        if (recControl.CGCVendor.Text != "") {
                            rec.Parse(recControl.CGCVendor.Text, MvwISDVendorXrefView.CGCVendor);
                  }
                
                        if (recControl.City.Text != "") {
                            rec.Parse(recControl.City.Text, MvwISDVendorXrefView.City);
                  }
                
                        if (recControl.IsSubcontractor.Text != "") {
                            rec.Parse(recControl.IsSubcontractor.Text, MvwISDVendorXrefView.IsSubcontractor);
                  }
                
                        if (recControl.State.Text != "") {
                            rec.Parse(recControl.State.Text, MvwISDVendorXrefView.State);
                  }
                
                        if (recControl.VendorName.Text != "") {
                            rec.Parse(recControl.VendorName.Text, MvwISDVendorXrefView.VendorName);
                  }
                
                        if (recControl.VPVendor.Text != "") {
                            rec.Parse(recControl.VPVendor.Text, MvwISDVendorXrefView.VPVendor);
                  }
                
                        if (recControl.Zip.Text != "") {
                            rec.Parse(recControl.Zip.Text, MvwISDVendorXrefView.Zip);
                  }
                
      newUIDataList.Add(recControl.PreservedUIData());
      newRecordList.Add(rec);
      }
      }
      }
    
            // Add any new record to the list.
            for (int count = 1; count <= this.AddNewRecord; count++) {
              
                newRecordList.Insert(0, new MvwISDVendorXrefRecord());
                newUIDataList.Insert(0, new Hashtable());
              
            }
            this.AddNewRecord = 0;

            // Finally, add any new records to the DataSource.
            if (newRecordList.Count > 0) {
              
                ArrayList finalList = new ArrayList(this.DataSource);
                finalList.InsertRange(0, newRecordList);

                Type myrec = typeof(VPLookup.Business.MvwISDVendorXrefRecord);
                this.DataSource = (MvwISDVendorXrefRecord[])(finalList.ToArray(myrec));
              
            }
            
            // Add the existing UI data to this hash table
            if (newUIDataList.Count > 0)
                this.UIData.InsertRange(0, newUIDataList);
        }

        
        public void AddToDeletedRecordIds(MvwISDVendorXrefTableControlRow rec)
        {
            if (rec.IsNewRecord) {
                return;
            }

            if (this.DeletedRecordIds != null && this.DeletedRecordIds.Length > 0) {
                this.DeletedRecordIds += ",";
            }

            this.DeletedRecordIds += "[" + rec.RecordUniqueId + "]";
        }

        protected virtual bool InDeletedRecordIds(MvwISDVendorXrefTableControlRow rec)            
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
        
        public virtual void SetAddress2Label()
                  {
                  
                    
        }
                
        public virtual void SetAddressLabel()
                  {
                  
                    
        }
                
        public virtual void SetCGCVendorLabel()
                  {
                  
                    
        }
                
        public virtual void SetCityLabel()
                  {
                  
                    
        }
                
        public virtual void SetCityLabel1()
                  {
                  
                    
        }
                
        public virtual void SetIsSubcontractorLabel()
                  {
                  
                    
        }
                
        public virtual void SetIsSubcontractorLabel1()
                  {
                  
                    
        }
                
        public virtual void SetSortByLabel()
                  {
                  
                      //Code for the text property is generated inside the .aspx file. 
                      //To override this property you can uncomment the following property and add you own value.
                      //this.SortByLabel.Text = "Some value";
                    
                    
        }
                
        public virtual void SetStateLabel()
                  {
                  
                    
        }
                
        public virtual void SetStateLabel1()
                  {
                  
                    
        }
                
        public virtual void SetVendorNameLabel()
                  {
                  
                    
        }
                
        public virtual void SetVPVendorLabel()
                  {
                  
                    
        }
                
        public virtual void SetZipLabel()
                  {
                  
                    
        }
                
        public virtual void SetOrderSort()
        {
            
                this.PopulateOrderSort(MiscUtils.GetSelectedValue(this.OrderSort,  GetFromSession(this.OrderSort)), 500);					
                    

        }
            
        public virtual void SetCityFilter()
        {
            
            ArrayList CityFilterselectedFilterItemList = new ArrayList();
            string CityFilteritemsString = null;
            if (this.InSession(this.CityFilter))
                CityFilteritemsString = this.GetFromSession(this.CityFilter);
            
            if (CityFilteritemsString != null)
            {
                string[] CityFilteritemListFromSession = CityFilteritemsString.Split(',');
                foreach (string item in CityFilteritemListFromSession)
                {
                    CityFilterselectedFilterItemList.Add(item);
                }
            }
              
            			
            this.PopulateCityFilter(MiscUtils.GetSelectedValueList(this.CityFilter, CityFilterselectedFilterItemList), 500);
                    
              string url = this.ModifyRedirectUrl("../mvwISDVendorXref/MvwISDVendorXref-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.CityFilter.PostBackUrl = url + "?Target=" + this.CityFilter.ClientID + "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("City")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--PLEASE_SELECT--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:PleaseSelect")) + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.CityFilter.Attributes["onClick"] = "initializePopupPage(this, '" + this.CityFilter.PostBackUrl + "', false, event); return false;";                  
                                   
        }
            
        public virtual void SetIsSubcontractorFilter()
        {
            
            ArrayList IsSubcontractorFilterselectedFilterItemList = new ArrayList();
            string IsSubcontractorFilteritemsString = null;
            if (this.InSession(this.IsSubcontractorFilter))
                IsSubcontractorFilteritemsString = this.GetFromSession(this.IsSubcontractorFilter);
            
            if (IsSubcontractorFilteritemsString != null)
            {
                string[] IsSubcontractorFilteritemListFromSession = IsSubcontractorFilteritemsString.Split(',');
                foreach (string item in IsSubcontractorFilteritemListFromSession)
                {
                    IsSubcontractorFilterselectedFilterItemList.Add(item);
                }
            }
              
            			
            this.PopulateIsSubcontractorFilter(MiscUtils.GetSelectedValueList(this.IsSubcontractorFilter, IsSubcontractorFilterselectedFilterItemList), 500);
                    
              string url = this.ModifyRedirectUrl("../mvwISDVendorXref/MvwISDVendorXref-QuickSelector.aspx", "", true);
              
              url = this.Page.ModifyRedirectUrl(url, "", true);                                  
              
              this.IsSubcontractorFilter.PostBackUrl = url + "?Target=" + this.IsSubcontractorFilter.ClientID + "&IndexField=" + (this.Page as BaseApplicationPage).Encrypt("IsSubcontractor")+ "&EmptyValue=" + (this.Page as BaseApplicationPage).Encrypt("--PLEASE_SELECT--") + "&EmptyDisplayText=" + (this.Page as BaseApplicationPage).Encrypt(this.Page.GetResourceValue("Txt:PleaseSelect")) + "&RedirectStyle=" + (this.Page as BaseApplicationPage).Encrypt("Popup");
              
              this.IsSubcontractorFilter.Attributes["onClick"] = "initializePopupPage(this, '" + this.IsSubcontractorFilter.PostBackUrl + "', false, event); return false;";                  
                                   
        }
            
        public virtual void SetSearchText()
        {
                                            
            this.SearchText.Attributes.Add("onfocus", "if(this.value=='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "') {this.value='';this.className='Search_Input';}");
            this.SearchText.Attributes.Add("onblur", "if(this.value=='') {this.value='" + BaseClasses.Resources.AppResources.GetResourceValue("Txt:SearchForEllipsis", null) + "';this.className='Search_InputHint';}");
                                   
        }
            
        public virtual void SetStateFilter()
        {
            
            this.PopulateStateFilter(MiscUtils.GetSelectedValue(this.StateFilter,  GetFromSession(this.StateFilter)), 500);					
                                     
        }
            
        // Get the filters' data for OrderSort.
                
        protected virtual void PopulateOrderSort(string selectedValue, int maxItems)
                    
        {
            
              
                this.OrderSort.Items.Clear();
                
              // 1. Setup the static list items
              							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("{Txt:PleaseSelect}"), "--PLEASE_SELECT--"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Address {Txt:Ascending}"), "Address Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Address {Txt:Descending}"), "Address Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Address 2 {Txt:Ascending}"), "Address2 Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Address 2 {Txt:Descending}"), "Address2 Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("CGC Vendor {Txt:Ascending}"), "CGCVendor Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("CGC Vendor {Txt:Descending}"), "CGCVendor Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("City {Txt:Ascending}"), "City Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("City {Txt:Descending}"), "City Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Is Subcontractor {Txt:Ascending}"), "IsSubcontractor Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Is Subcontractor {Txt:Descending}"), "IsSubcontractor Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Vendor Group {Txt:Ascending}"), "VendorGroup Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Vendor Group {Txt:Descending}"), "VendorGroup Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Vendor Key {Txt:Ascending}"), "VendorKey Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Vendor Key {Txt:Descending}"), "VendorKey Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Vendor Name {Txt:Ascending}"), "VendorName Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("Vendor Name {Txt:Descending}"), "VendorName Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("VP Vendor {Txt:Ascending}"), "VPVendor Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("VP Vendor {Txt:Descending}"), "VPVendor Desc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("ZIP {Txt:Ascending}"), "Zip Asc"));
                            							
            this.OrderSort.Items.Add(new ListItem(this.Page.ExpandResourceValue("ZIP {Txt:Descending}"), "Zip Desc"));
                            
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
            
        // Get the filters' data for CityFilter.
                
        protected virtual void PopulateCityFilter(ArrayList selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            WhereClause wc = this.CreateWhereClause_CityFilter();            
            this.CityFilter.Items.Clear();
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_CityFilter function.
            // It is better to customize the where clause there.
          
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDVendorXrefView.City, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDVendorXrefView.GetValues(MvwISDVendorXrefView.City, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDVendorXrefView.City.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDVendorXrefView.City.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.CityFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.CityFilter.Items.Add(newItem);

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
            
            
            this.CityFilter.SetFieldMaxLength(50);
                                 
                  
            // Add the selected value.
            if (this.CityFilter.Items.Count == 0)
                this.CityFilter.Items.Add(new ListItem(Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
            
            // Mark all items to be selected.
            foreach (ListItem item in this.CityFilter.Items)
            {
                item.Selected = true;
            }
                               
        }
            
        // Get the filters' data for IsSubcontractorFilter.
                
        protected virtual void PopulateIsSubcontractorFilter(ArrayList selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            WhereClause wc = this.CreateWhereClause_IsSubcontractorFilter();            
            this.IsSubcontractorFilter.Items.Clear();
            			  			
            // Set up the WHERE and the ORDER BY clause by calling the CreateWhereClause_IsSubcontractorFilter function.
            // It is better to customize the where clause there.
          
            
            
            OrderBy orderBy = new OrderBy(false, false);
            orderBy.Add(MvwISDVendorXrefView.IsSubcontractor, OrderByItem.OrderDir.Asc);                
            
            
            string[] values = new string[0];
            if (wc.RunQuery)
            {
            
                values = MvwISDVendorXrefView.GetValues(MvwISDVendorXrefView.IsSubcontractor, wc, orderBy, maxItems);
            
            }
            
            ArrayList listDuplicates = new ArrayList();
            foreach (string cvalue in values)
            {
            // Create the item and add to the list.
            string fvalue;
            if ( MvwISDVendorXrefView.IsSubcontractor.IsColumnValueTypeBoolean()) {
                    fvalue = cvalue;
                }else {
                    fvalue = MvwISDVendorXrefView.IsSubcontractor.Format(cvalue);
                }
                if (fvalue == null) {
                    fvalue = "";
                }

                fvalue = fvalue.Trim();

                if ( fvalue.Length > 50 ) {
                    fvalue = fvalue.Substring(0, 50) + "...";
                }

                ListItem dupItem = this.IsSubcontractorFilter.Items.FindByText(fvalue);
								
                if (dupItem != null) {
                    listDuplicates.Add(fvalue);
                    if (!string.IsNullOrEmpty(dupItem.Value))
                    {
                        dupItem.Text = fvalue + " (ID " + dupItem.Value.Substring(0, Math.Min(dupItem.Value.Length,38)) + ")";
                    }
                }

                ListItem newItem = new ListItem(fvalue, cvalue);
                this.IsSubcontractorFilter.Items.Add(newItem);

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
            
            
            this.IsSubcontractorFilter.SetFieldMaxLength(50);
                                 
                  
            // Add the selected value.
            if (this.IsSubcontractorFilter.Items.Count == 0)
                this.IsSubcontractorFilter.Items.Add(new ListItem(Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
            
            // Mark all items to be selected.
            foreach (ListItem item in this.IsSubcontractorFilter.Items)
            {
                item.Selected = true;
            }
                               
        }
            
        // Get the filters' data for StateFilter.
                
        protected virtual void PopulateStateFilter(string selectedValue, int maxItems)
                    
        {
        
            
            //Setup the WHERE clause.
                        
            this.StateFilter.Items.Clear();
            WhereClause wc = this.CreateWhereClause_StateFilter();            
            		  
            // Skip load data from database and insert data
            // Setup the static list items        
            
            // Add the Please Select item.
            this.StateFilter.Items.Insert(0, new ListItem(this.Page.GetResourceValue("Txt:PleaseSelect", "VPLookup"), "--PLEASE_SELECT--"));
                            
            MiscUtils.PopulateStates(this.StateFilter);
                          
            try
            {
      
                
                // Set the selected value.
                MiscUtils.SetSelectedValue(this.StateFilter, selectedValue);
                
            }
            catch
            {
            }
            
            
            if (this.StateFilter.SelectedValue != null && this.StateFilter.Items.FindByValue(this.StateFilter.SelectedValue) == null)
                this.StateFilter.SelectedValue = null;
                           
        }
            
        public virtual WhereClause CreateWhereClause_CityFilter()
        {
            // Create a where clause for the filter CityFilter.
            // This function is called by the Populate method to load the items 
            // in the CityFilterQuickSelector
        
            ArrayList CityFilterselectedFilterItemList = new ArrayList();
            string CityFilteritemsString = null;
            if (this.InSession(this.CityFilter))
                CityFilteritemsString = this.GetFromSession(this.CityFilter);
            
            if (CityFilteritemsString != null)
            {
                string[] CityFilteritemListFromSession = CityFilteritemsString.Split(',');
                foreach (string item in CityFilteritemListFromSession)
                {
                    CityFilterselectedFilterItemList.Add(item);
                }
            }
              
            CityFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CityFilter, CityFilterselectedFilterItemList); 
            WhereClause wc = new WhereClause();
            if (CityFilterselectedFilterItemList == null || CityFilterselectedFilterItemList.Count == 0)
                wc.RunQuery = false;
            else            
            {
                foreach (string item in CityFilterselectedFilterItemList)
                {
            
      
   
                    wc.iOR(MvwISDVendorXrefView.City, BaseFilter.ComparisonOperator.EqualsTo, item);

                                
                }
            }
            return wc;
        
        }
      
        public virtual WhereClause CreateWhereClause_IsSubcontractorFilter()
        {
            // Create a where clause for the filter IsSubcontractorFilter.
            // This function is called by the Populate method to load the items 
            // in the IsSubcontractorFilterQuickSelector
        
            ArrayList IsSubcontractorFilterselectedFilterItemList = new ArrayList();
            string IsSubcontractorFilteritemsString = null;
            if (this.InSession(this.IsSubcontractorFilter))
                IsSubcontractorFilteritemsString = this.GetFromSession(this.IsSubcontractorFilter);
            
            if (IsSubcontractorFilteritemsString != null)
            {
                string[] IsSubcontractorFilteritemListFromSession = IsSubcontractorFilteritemsString.Split(',');
                foreach (string item in IsSubcontractorFilteritemListFromSession)
                {
                    IsSubcontractorFilterselectedFilterItemList.Add(item);
                }
            }
              
            IsSubcontractorFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.IsSubcontractorFilter, IsSubcontractorFilterselectedFilterItemList); 
            WhereClause wc = new WhereClause();
            if (IsSubcontractorFilterselectedFilterItemList == null || IsSubcontractorFilterselectedFilterItemList.Count == 0)
                wc.RunQuery = false;
            else            
            {
                foreach (string item in IsSubcontractorFilterselectedFilterItemList)
                {
            
      
   
                    wc.iOR(MvwISDVendorXrefView.IsSubcontractor, BaseFilter.ComparisonOperator.EqualsTo, item);

                                
                }
            }
            return wc;
        
        }
      
        public virtual WhereClause CreateWhereClause_StateFilter()
        {
            // Create a where clause for the filter StateFilter.
            // This function is called by the Populate method to load the items 
            // in the StateFilterDropDownList
        
            WhereClause wc = new WhereClause();
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
                  
            ArrayList CityFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CityFilter, null);
            string CityFilterSessionString = "";
            if (CityFilterselectedFilterItemList != null){
                foreach (string item in CityFilterselectedFilterItemList){
                    CityFilterSessionString = String.Concat(CityFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession(this.CityFilter, CityFilterSessionString);
                  
            ArrayList IsSubcontractorFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.IsSubcontractorFilter, null);
            string IsSubcontractorFilterSessionString = "";
            if (IsSubcontractorFilterselectedFilterItemList != null){
                foreach (string item in IsSubcontractorFilterselectedFilterItemList){
                    IsSubcontractorFilterSessionString = String.Concat(IsSubcontractorFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession(this.IsSubcontractorFilter, IsSubcontractorFilterSessionString);
                  
            this.SaveToSession(this.SearchText, this.SearchText.Text);
                  
            this.SaveToSession(this.StateFilter, this.StateFilter.SelectedValue);
                  
            
                    
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
                  
            ArrayList CityFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.CityFilter, null);
            string CityFilterSessionString = "";
            if (CityFilterselectedFilterItemList != null){
                foreach (string item in CityFilterselectedFilterItemList){
                    CityFilterSessionString = String.Concat(CityFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession("CityFilter_Ajax", CityFilterSessionString);
          
            ArrayList IsSubcontractorFilterselectedFilterItemList = MiscUtils.GetSelectedValueList(this.IsSubcontractorFilter, null);
            string IsSubcontractorFilterSessionString = "";
            if (IsSubcontractorFilterselectedFilterItemList != null){
                foreach (string item in IsSubcontractorFilterselectedFilterItemList){
                    IsSubcontractorFilterSessionString = String.Concat(IsSubcontractorFilterSessionString ,"," , item);
                }
            }
            this.SaveToSession("IsSubcontractorFilter_Ajax", IsSubcontractorFilterSessionString);
          
      this.SaveToSession("SearchText_Ajax", this.SearchText.Text);
              
      this.SaveToSession("StateFilter_Ajax", this.StateFilter.SelectedValue);
              
           HttpContext.Current.Session["AppRelativeVirtualPath"] = this.Page.AppRelativeVirtualPath;
         
        }
        
        
        protected override void ClearControlsFromSession()
        {
            base.ClearControlsFromSession();
            // Clear filter controls values from the session.
        
            this.RemoveFromSession(this.OrderSort);
            this.RemoveFromSession(this.CityFilter);
            this.RemoveFromSession(this.IsSubcontractorFilter);
            this.RemoveFromSession(this.SearchText);
            this.RemoveFromSession(this.StateFilter);
            
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

            string orderByStr = (string)ViewState["MvwISDVendorXrefTableControl_OrderBy"];
          
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
                this.ViewState["MvwISDVendorXrefTableControl_OrderBy"] = this.CurrentSortOrder.ToXmlString();
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
        							
                    this.ImportButton.PostBackUrl = "../Shared/SelectFileToImport.aspx?TableName=MvwISDVendorXref" ;
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
    
      
            if (MiscUtils.IsValueSelected(CityFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
            if (MiscUtils.IsValueSelected(IsSubcontractorFilter))
                themeButtonFiltersButton.ArrowImage.ImageUrl = "../Images/ButtonCheckmark.png";
        
            if (MiscUtils.IsValueSelected(StateFilter))
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
        
        public virtual void Address2Label_Click(object sender, EventArgs args)
        {
            //Sorts by Address2 when clicked.
              
            // Get previous sorting state for Address2.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.Address2);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for Address2.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.Address2, OrderByItem.OrderDir.Asc);
            
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
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.Address);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for Address.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.Address, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by Address, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void CGCVendorLabel_Click(object sender, EventArgs args)
        {
            //Sorts by CGCVendor when clicked.
              
            // Get previous sorting state for CGCVendor.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.CGCVendor);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for CGCVendor.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.CGCVendor, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by CGCVendor, so just reverse.
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
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.City);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for City.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.City, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by City, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void IsSubcontractorLabel_Click(object sender, EventArgs args)
        {
            //Sorts by IsSubcontractor when clicked.
              
            // Get previous sorting state for IsSubcontractor.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.IsSubcontractor);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for IsSubcontractor.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.IsSubcontractor, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by IsSubcontractor, so just reverse.
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
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.State);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for State.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.State, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by State, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void VendorNameLabel_Click(object sender, EventArgs args)
        {
            //Sorts by VendorName when clicked.
              
            // Get previous sorting state for VendorName.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.VendorName);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for VendorName.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.VendorName, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by VendorName, so just reverse.
                sd.Reverse();
            }
        

            // Setting the DataChanged to true results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
              
        }
            
        public virtual void VPVendorLabel_Click(object sender, EventArgs args)
        {
            //Sorts by VPVendor when clicked.
              
            // Get previous sorting state for VPVendor.
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.VPVendor);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for VPVendor.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.VPVendor, OrderByItem.OrderDir.Asc);
            
            } else {
                // Previously sorted by VPVendor, so just reverse.
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
        
            OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.Zip);
            if (sd == null || (this.CurrentSortOrder.Items != null && this.CurrentSortOrder.Items.Length > 1)) {
                // First time sort, so add sort order for Zip.
                this.CurrentSortOrder.Reset();

    
              //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
              if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

              this.CurrentSortOrder.Add(MvwISDVendorXrefView.Zip, OrderByItem.OrderDir.Asc);
            
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


              this.TotalRecords = MvwISDVendorXrefView.GetRecordCount(join, wc);
              if (this.TotalRecords > 10000)
              {
              
                // Add each of the columns in order of export.
                BaseColumn[] columns = new BaseColumn[] {
                             MvwISDVendorXrefView.VPVendor,
             MvwISDVendorXrefView.CGCVendor,
             MvwISDVendorXrefView.VendorName,
             MvwISDVendorXrefView.IsSubcontractor,
             MvwISDVendorXrefView.Address,
             MvwISDVendorXrefView.Address2,
             MvwISDVendorXrefView.City,
             MvwISDVendorXrefView.State,
             MvwISDVendorXrefView.Zip,
             null};
                ExportDataToCSV exportData = new ExportDataToCSV(MvwISDVendorXrefView.Instance,wc,orderBy,columns);
                exportData.StartExport(this.Page.Response, true);

                DataForExport dataForCSV = new DataForExport(MvwISDVendorXrefView.Instance, wc, orderBy, columns,join);

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
              ExportDataToExcel excelReport = new ExportDataToExcel(MvwISDVendorXrefView.Instance, wc, orderBy);
              // Add each of the columns in order of export.
              // To customize the data type, change the second parameter of the new ExcelColumn to be
              // a format string from Excel's Format Cell menu. For example "dddd, mmmm dd, yyyy h:mm AM/PM;@", "#,##0.00"

              if (this.Page.Response == null)
              return;

              excelReport.CreateExcelBook();

              int width = 0;
              int columnCounter = 0;
              DataForExport data = new DataForExport(MvwISDVendorXrefView.Instance, wc, orderBy, null,join);
                           data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.VPVendor, "0"));
             data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.CGCVendor, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.VendorName, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.IsSubcontractor, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.Address, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.Address2, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.City, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.State, "Default"));
             data.ColumnList.Add(new ExcelColumn(MvwISDVendorXrefView.Zip, "Default"));


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
                val = MvwISDVendorXrefView.GetDFKA(rec.GetValue(col.DisplayColumn).ToString(), col.DisplayColumn, null) as string;
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

                report.SpecificReportFileName = Page.Server.MapPath("Show-MvwISDVendorXref-Table.PDFButton.report");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "mvwISDVendorXref";
                // If Show-MvwISDVendorXref-Table.PDFButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.   
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(MvwISDVendorXrefView.VPVendor.Name, ReportEnum.Align.Right, "${VPVendor}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDVendorXrefView.CGCVendor.Name, ReportEnum.Align.Left, "${CGCVendor}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDVendorXrefView.VendorName.Name, ReportEnum.Align.Left, "${VendorName}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDVendorXrefView.IsSubcontractor.Name, ReportEnum.Align.Left, "${IsSubcontractor}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDVendorXrefView.Address.Name, ReportEnum.Align.Left, "${Address}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDVendorXrefView.Address2.Name, ReportEnum.Align.Left, "${Address2}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDVendorXrefView.City.Name, ReportEnum.Align.Left, "${City}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDVendorXrefView.State.Name, ReportEnum.Align.Left, "${State}", ReportEnum.Align.Left, 20);
                 report.AddColumn(MvwISDVendorXrefView.Zip.Name, ReportEnum.Align.Left, "${Zip}", ReportEnum.Align.Left, 15);

  
                int rowsPerQuery = 5000;
                int recordCount = 0;
                                
                report.Page = Page.GetResourceValue("Txt:Page", "VPLookup");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                
                ColumnList columns = MvwISDVendorXrefView.GetColumnList();
                
                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                
                int pageNum = 0;
                int totalRows = MvwISDVendorXrefView.GetRecordCount(joinFilter,whereClause);
                MvwISDVendorXrefRecord[] records = null;
                
                do
                {
                    
                    records = MvwISDVendorXrefView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                     if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( MvwISDVendorXrefRecord record in records)
                    
                        {
                            // AddData method takes four parameters   
                            // The 1st parameter represent the data format
                            // The 2nd parameter represent the data value
                            // The 3rd parameter represent the default alignment of column using the data
                            // The 4th parameter represent the maximum length of the data value being shown
                                                 report.AddData("${VPVendor}", record.Format(MvwISDVendorXrefView.VPVendor), ReportEnum.Align.Right, 300);
                             report.AddData("${CGCVendor}", record.Format(MvwISDVendorXrefView.CGCVendor), ReportEnum.Align.Left, 300);
                             report.AddData("${VendorName}", record.Format(MvwISDVendorXrefView.VendorName), ReportEnum.Align.Left, 300);
                             report.AddData("${IsSubcontractor}", record.Format(MvwISDVendorXrefView.IsSubcontractor), ReportEnum.Align.Left, 300);
                             report.AddData("${Address}", record.Format(MvwISDVendorXrefView.Address), ReportEnum.Align.Left, 300);
                             report.AddData("${Address2}", record.Format(MvwISDVendorXrefView.Address2), ReportEnum.Align.Left, 300);
                             report.AddData("${City}", record.Format(MvwISDVendorXrefView.City), ReportEnum.Align.Left, 300);
                             report.AddData("${State}", record.Format(MvwISDVendorXrefView.State), ReportEnum.Align.Left, 300);
                             report.AddData("${Zip}", record.Format(MvwISDVendorXrefView.Zip), ReportEnum.Align.Left, 300);

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
                
              this.CityFilter.ClearSelection();
            
              this.IsSubcontractorFilter.ClearSelection();
            
              this.StateFilter.ClearSelection();
            
           
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

                report.SpecificReportFileName = Page.Server.MapPath("Show-MvwISDVendorXref-Table.WordButton.word");
                // report.Title replaces the value tag of page header and footer containing ${ReportTitle}
                report.Title = "mvwISDVendorXref";
                // If Show-MvwISDVendorXref-Table.WordButton.report specifies a valid report template,
                // AddColumn methods will generate a report template.
                // Each AddColumn method-call specifies a column
                // The 1st parameter represents the text of the column header
                // The 2nd parameter represents the horizontal alignment of the column header
                // The 3rd parameter represents the text format of the column detail
                // The 4th parameter represents the horizontal alignment of the column detail
                // The 5th parameter represents the relative width of the column
                 report.AddColumn(MvwISDVendorXrefView.VPVendor.Name, ReportEnum.Align.Right, "${VPVendor}", ReportEnum.Align.Right, 15);
                 report.AddColumn(MvwISDVendorXrefView.CGCVendor.Name, ReportEnum.Align.Left, "${CGCVendor}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDVendorXrefView.VendorName.Name, ReportEnum.Align.Left, "${VendorName}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDVendorXrefView.IsSubcontractor.Name, ReportEnum.Align.Left, "${IsSubcontractor}", ReportEnum.Align.Left, 15);
                 report.AddColumn(MvwISDVendorXrefView.Address.Name, ReportEnum.Align.Left, "${Address}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDVendorXrefView.Address2.Name, ReportEnum.Align.Left, "${Address2}", ReportEnum.Align.Left, 28);
                 report.AddColumn(MvwISDVendorXrefView.City.Name, ReportEnum.Align.Left, "${City}", ReportEnum.Align.Left, 24);
                 report.AddColumn(MvwISDVendorXrefView.State.Name, ReportEnum.Align.Left, "${State}", ReportEnum.Align.Left, 20);
                 report.AddColumn(MvwISDVendorXrefView.Zip.Name, ReportEnum.Align.Left, "${Zip}", ReportEnum.Align.Left, 15);

                WhereClause whereClause = null;
                whereClause = CreateWhereClause();
            
                OrderBy orderBy = CreateOrderBy();
                BaseFilter joinFilter = CreateCompoundJoinFilter();
                

                int rowsPerQuery = 5000;
                int pageNum = 0;
                int recordCount = 0;
                int totalRows = MvwISDVendorXrefView.GetRecordCount(joinFilter,whereClause);

                report.Page = Page.GetResourceValue("Txt:Page", "VPLookup");
                report.ApplicationPath = this.Page.MapPath(Page.Request.ApplicationPath);

                ColumnList columns = MvwISDVendorXrefView.GetColumnList();
                MvwISDVendorXrefRecord[] records = null;
                do
                {
                    records = MvwISDVendorXrefView.GetRecords(joinFilter,whereClause, orderBy, pageNum, rowsPerQuery);
                    if (records != null && records.Length > 0 && whereClause.RunQuery)
                    {
                        foreach ( MvwISDVendorXrefRecord record in records)
                        {
                            // AddData method takes four parameters
                            // The 1st parameter represents the data format
                            // The 2nd parameter represents the data value
                            // The 3rd parameter represents the default alignment of column using the data
                            // The 4th parameter represents the maximum length of the data value being shown
                             report.AddData("${VPVendor}", record.Format(MvwISDVendorXrefView.VPVendor), ReportEnum.Align.Right, 300);
                             report.AddData("${CGCVendor}", record.Format(MvwISDVendorXrefView.CGCVendor), ReportEnum.Align.Left, 300);
                             report.AddData("${VendorName}", record.Format(MvwISDVendorXrefView.VendorName), ReportEnum.Align.Left, 300);
                             report.AddData("${IsSubcontractor}", record.Format(MvwISDVendorXrefView.IsSubcontractor), ReportEnum.Align.Left, 300);
                             report.AddData("${Address}", record.Format(MvwISDVendorXrefView.Address), ReportEnum.Align.Left, 300);
                             report.AddData("${Address2}", record.Format(MvwISDVendorXrefView.Address2), ReportEnum.Align.Left, 300);
                             report.AddData("${City}", record.Format(MvwISDVendorXrefView.City), ReportEnum.Align.Left, 300);
                             report.AddData("${State}", record.Format(MvwISDVendorXrefView.State), ReportEnum.Align.Left, 300);
                             report.AddData("${Zip}", record.Format(MvwISDVendorXrefView.Zip), ReportEnum.Align.Left, 300);

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
                  foreach (BaseClasses.Data.BaseColumn ColumnNam in MvwISDVendorXrefView.GetColumns())
                  {
                  if (ColumnNam.Name.ToUpper().Equals(SelVal1))
                  {
                  SelVal1 = ColumnNam.InternalName;
                  }
                  }
                  }

                
                OrderByItem sd = this.CurrentSortOrder.Find(MvwISDVendorXrefView.GetColumnByName(SelVal1));
                if (sd == null || this.CurrentSortOrder.Items != null)
                {
                // First time sort, so add sort order for Discontinued.
                if (MvwISDVendorXrefView.GetColumnByName(SelVal1) != null)
                {
                  this.CurrentSortOrder.Reset();
                }

                //If default sort order was GeoProximity, create new CurrentSortOrder of OrderBy type
                if ((this.CurrentSortOrder).GetType() == typeof(GeoOrderBy)) this.CurrentSortOrder = new OrderBy(true, false);

                
                  if (SelVal1 != "--PLEASE_SELECT--" && MvwISDVendorXrefView.GetColumnByName(SelVal1) != null)
                  {
                    if (words1[words1.Length - 1].Contains("ASC"))
                  {
                  this.CurrentSortOrder.Add(MvwISDVendorXrefView.GetColumnByName(SelVal1),OrderByItem.OrderDir.Asc);
                    }
                    else
                    {
                      if (words1[words1.Length - 1].Contains("DESC"))
                  {
                  this.CurrentSortOrder.Add(MvwISDVendorXrefView.GetColumnByName(SelVal1),OrderByItem.OrderDir.Desc );
                      }
                    }
                  }
                
                }
                this.DataChanged = true;
              				
        }
            
        // event handler for FieldFilter
        protected virtual void CityFilter_SelectedIndexChanged(object sender, EventArgs args)
        {
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            
           				
        }
            
        // event handler for FieldFilter
        protected virtual void IsSubcontractorFilter_SelectedIndexChanged(object sender, EventArgs args)
        {
            // Setting the DataChanged to True results in the page being refreshed with
            // the most recent data from the database.  This happens in PreRender event
            // based on the current sort, search and filter criteria.
            this.DataChanged = true;
            
           				
        }
            
        // event handler for FieldFilter
        protected virtual void StateFilter_SelectedIndexChanged(object sender, EventArgs args)
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
                    _TotalRecords = MvwISDVendorXrefView.GetRecordCount(CreateCompoundJoinFilter(), CreateWhereClause());
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
        
        public  MvwISDVendorXrefRecord[] DataSource {
             
            get {
                return (MvwISDVendorXrefRecord[])(base._DataSource);
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
        
        public System.Web.UI.WebControls.LinkButton CGCVendorLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CGCVendorLabel");
            }
        }
        
        public BaseClasses.Web.UI.WebControls.QuickSelector CityFilter {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CityFilter");
            }
        }              
        
        public System.Web.UI.WebControls.LinkButton CityLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CityLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal CityLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "CityLabel1");
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
        
        public BaseClasses.Web.UI.WebControls.QuickSelector IsSubcontractorFilter {
            get {
                return (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "IsSubcontractorFilter");
            }
        }              
        
        public System.Web.UI.WebControls.LinkButton IsSubcontractorLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "IsSubcontractorLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal IsSubcontractorLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "IsSubcontractorLabel1");
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
        
        public System.Web.UI.WebControls.DropDownList StateFilter {
            get {
                return (System.Web.UI.WebControls.DropDownList)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "StateFilter");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton StateLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "StateLabel");
            }
        }
        
        public System.Web.UI.WebControls.Literal StateLabel1 {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "StateLabel1");
            }
        }
        
        public System.Web.UI.WebControls.Literal Title {
            get {
                return (System.Web.UI.WebControls.Literal)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "Title");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton VendorNameLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VendorNameLabel");
            }
        }
        
        public System.Web.UI.WebControls.LinkButton VPVendorLabel {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "VPVendorLabel");
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
                MvwISDVendorXrefTableControlRow recCtl = this.GetSelectedRecordControl();
                if (recCtl == null && url.IndexOf("{") >= 0) {
                    // Localization.
                    throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
                }

        MvwISDVendorXrefRecord rec = null;
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
                MvwISDVendorXrefTableControlRow recCtl = this.GetSelectedRecordControl();
                if (recCtl == null && url.IndexOf("{") >= 0) {
                    // Localization.
                    throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
                }

        MvwISDVendorXrefRecord rec = null;
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
          
        public virtual MvwISDVendorXrefTableControlRow GetSelectedRecordControl()
        {
        
            return null;
          
        }

        public virtual MvwISDVendorXrefTableControlRow[] GetSelectedRecordControls()
        {
        
            return (MvwISDVendorXrefTableControlRow[])((new ArrayList()).ToArray(Type.GetType("VPLookup.UI.Controls.Show_MvwISDVendorXref_Table.MvwISDVendorXrefTableControlRow")));
          
        }

        public virtual void DeleteSelectedRecords(bool deferDeletion)
        {
            MvwISDVendorXrefTableControlRow[] recordList = this.GetSelectedRecordControls();
            if (recordList.Length == 0) {
                // Localization.
                throw new Exception(Page.GetResourceValue("Err:NoRecSelected", "VPLookup"));
            }
            
            foreach (MvwISDVendorXrefTableControlRow recCtl in recordList)
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

        public MvwISDVendorXrefTableControlRow[] GetRecordControls()
        {
            ArrayList recordList = new ArrayList();
            System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)this.FindControl("MvwISDVendorXrefTableControlRepeater");
            if (rep == null){return null;}
            foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
            {
              MvwISDVendorXrefTableControlRow recControl = (MvwISDVendorXrefTableControlRow)repItem.FindControl("MvwISDVendorXrefTableControlRow");
                  recordList.Add(recControl);
                
            }

            return (MvwISDVendorXrefTableControlRow[])recordList.ToArray(Type.GetType("VPLookup.UI.Controls.Show_MvwISDVendorXref_Table.MvwISDVendorXrefTableControlRow"));
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

  