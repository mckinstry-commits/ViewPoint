// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDJobXrefRecord.cs

using System;
using System.Collections;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace VPLookup.Business
{

/// <summary>
/// The generated superclass for the <see cref="MvwISDJobXrefRecord"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="MvwISDJobXrefView"></see> class.
/// </remarks>
/// <seealso cref="MvwISDJobXrefView"></seealso>
/// <seealso cref="MvwISDJobXrefRecord"></seealso>
public class BaseMvwISDJobXrefRecord : PrimaryKeyRecord
{

	public readonly static MvwISDJobXrefView TableUtils = MvwISDJobXrefView.Instance;

	// Constructors
 
	protected BaseMvwISDJobXrefRecord() : base(TableUtils)
	{
		this.InsertingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.InsertingRecordEventHandler(this.MvwISDJobXrefRecord_InsertingRecord); 
		this.UpdatingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.UpdatingRecordEventHandler(this.MvwISDJobXrefRecord_UpdatingRecord); 
		this.ReadRecord +=
            new BaseClasses.IRecordWithTriggerEvents.ReadRecordEventHandler(this.MvwISDJobXrefRecord_ReadRecord); 
	}

	protected BaseMvwISDJobXrefRecord(PrimaryKeyRecord record) : base(record, TableUtils)
	{
	}
	
	
	//Audit Trail methods
	
	//Evaluates Initialize when->Reading record formulas specified at the data access layer
    protected virtual void MvwISDJobXrefRecord_ReadRecord(Object sender,System.EventArgs e)
    {
        //Apply Initialize->Reading record formula only if validation is successful.
                MvwISDJobXrefRecord MvwISDJobXrefRec = (MvwISDJobXrefRecord)sender;
        if(MvwISDJobXrefRec != null && !MvwISDJobXrefRec.IsReadOnly ){
                }
    
    }
        
	//Evaluates Initialize when->Inserting formulas specified at the data access layer
    protected virtual void MvwISDJobXrefRecord_InsertingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Inserting formula only if validation is successful.
                MvwISDJobXrefRecord MvwISDJobXrefRec = (MvwISDJobXrefRecord)sender;
        Validate_Inserting();
        if(MvwISDJobXrefRec != null && !MvwISDJobXrefRec.IsReadOnly ){
                }
    
    }
    
    //Evaluates Initialize when->Updating formulas specified at the data access layer
    protected virtual void MvwISDJobXrefRecord_UpdatingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Updating formula only if validation is successful.
                MvwISDJobXrefRecord MvwISDJobXrefRec = (MvwISDJobXrefRecord)sender;
        Validate_Updating();
        if(MvwISDJobXrefRec != null && !MvwISDJobXrefRec.IsReadOnly ){
                }
    
    }

   //Evaluates Validate when->Inserting formulas specified at the data access layer
	protected virtual void Validate_Inserting()
	{
		string fullValidationMessage = "";
		string validationMessage = "";
		
		string formula = "";if (formula == "") formula = "";


		if(validationMessage != "" && validationMessage.ToLower() != "true")
            fullValidationMessage = fullValidationMessage + validationMessage + "\r\n"; 
		
        if(fullValidationMessage != "")
			throw new Exception(fullValidationMessage);
	}
 
	//Evaluates Validate when->Updating formulas specified at the data access layer
	protected virtual void Validate_Updating()
	{
		string fullValidationMessage = "";
		string validationMessage = "";
		
		string formula = "";if (formula == "") formula = "";


		if(validationMessage != "" && validationMessage.ToLower() != "true")
            fullValidationMessage = fullValidationMessage + validationMessage + "\r\n"; 
		
        if(fullValidationMessage != "")
			throw new Exception(fullValidationMessage);
	}
	public virtual string EvaluateFormula(string formula, BaseRecord  dataSourceForEvaluate, string format)
    {
        Data.BaseFormulaEvaluator e = new Data.BaseFormulaEvaluator();
        
        // All variables referred to in the formula are expected to be
        // properties of the DataSource.  For example, referring to
        // UnitPrice as a variable will refer to DataSource.UnitPrice
        e.DataSource = dataSourceForEvaluate;

        Object resultObj = e.Evaluate(formula);
        if(resultObj == null) 
			return "";
        return resultObj.ToString();
	}







#region "Convenience methods to get/set values of fields"

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public ColumnValue GetVPCoValue()
	{
		return this.GetValue(TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public Byte GetVPCoFieldValue()
	{
		return this.GetValue(TableUtils.VPCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPJob field.
	/// </summary>
	public ColumnValue GetVPJobValue()
	{
		return this.GetValue(TableUtils.VPJobColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPJob field.
	/// </summary>
	public string GetVPJobFieldValue()
	{
		return this.GetValue(TableUtils.VPJobColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPJob field.
	/// </summary>
	public void SetVPJobFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPJobColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPJob field.
	/// </summary>
	public void SetVPJobFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPJobColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public ColumnValue GetCGCCoValue()
	{
		return this.GetValue(TableUtils.CGCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public Int32 GetCGCCoFieldValue()
	{
		return this.GetValue(TableUtils.CGCCoColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public void SetCGCCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CGCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public void SetCGCCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.CGCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public void SetCGCCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CGCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public void SetCGCCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CGCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public void SetCGCCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CGCCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.CGCJob field.
	/// </summary>
	public ColumnValue GetCGCJobValue()
	{
		return this.GetValue(TableUtils.CGCJobColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.CGCJob field.
	/// </summary>
	public string GetCGCJobFieldValue()
	{
		return this.GetValue(TableUtils.CGCJobColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCJob field.
	/// </summary>
	public void SetCGCJobFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CGCJobColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCJob field.
	/// </summary>
	public void SetCGCJobFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CGCJobColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPJobDesc field.
	/// </summary>
	public ColumnValue GetVPJobDescValue()
	{
		return this.GetValue(TableUtils.VPJobDescColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPJobDesc field.
	/// </summary>
	public string GetVPJobDescFieldValue()
	{
		return this.GetValue(TableUtils.VPJobDescColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPJobDesc field.
	/// </summary>
	public void SetVPJobDescFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPJobDescColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPJobDesc field.
	/// </summary>
	public void SetVPJobDescFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPJobDescColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public ColumnValue GetVPCustomerValue()
	{
		return this.GetValue(TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public Int32 GetVPCustomerFieldValue()
	{
		return this.GetValue(TableUtils.VPCustomerColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(string val)
	{
		this.SetString(val, TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCustomerColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPCustomerName field.
	/// </summary>
	public ColumnValue GetVPCustomerNameValue()
	{
		return this.GetValue(TableUtils.VPCustomerNameColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.VPCustomerName field.
	/// </summary>
	public string GetVPCustomerNameFieldValue()
	{
		return this.GetValue(TableUtils.VPCustomerNameColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomerName field.
	/// </summary>
	public void SetVPCustomerNameFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPCustomerNameColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomerName field.
	/// </summary>
	public void SetVPCustomerNameFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCustomerNameColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailAddress field.
	/// </summary>
	public ColumnValue GetMailAddressValue()
	{
		return this.GetValue(TableUtils.MailAddressColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailAddress field.
	/// </summary>
	public string GetMailAddressFieldValue()
	{
		return this.GetValue(TableUtils.MailAddressColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailAddress field.
	/// </summary>
	public void SetMailAddressFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.MailAddressColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailAddress field.
	/// </summary>
	public void SetMailAddressFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MailAddressColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailAddress2 field.
	/// </summary>
	public ColumnValue GetMailAddress2Value()
	{
		return this.GetValue(TableUtils.MailAddress2Column);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailAddress2 field.
	/// </summary>
	public string GetMailAddress2FieldValue()
	{
		return this.GetValue(TableUtils.MailAddress2Column).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailAddress2 field.
	/// </summary>
	public void SetMailAddress2FieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.MailAddress2Column);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailAddress2 field.
	/// </summary>
	public void SetMailAddress2FieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MailAddress2Column);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailCity field.
	/// </summary>
	public ColumnValue GetMailCityValue()
	{
		return this.GetValue(TableUtils.MailCityColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailCity field.
	/// </summary>
	public string GetMailCityFieldValue()
	{
		return this.GetValue(TableUtils.MailCityColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailCity field.
	/// </summary>
	public void SetMailCityFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.MailCityColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailCity field.
	/// </summary>
	public void SetMailCityFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MailCityColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailState field.
	/// </summary>
	public ColumnValue GetMailStateValue()
	{
		return this.GetValue(TableUtils.MailStateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailState field.
	/// </summary>
	public string GetMailStateFieldValue()
	{
		return this.GetValue(TableUtils.MailStateColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailState field.
	/// </summary>
	public void SetMailStateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.MailStateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailState field.
	/// </summary>
	public void SetMailStateFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MailStateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailZip field.
	/// </summary>
	public ColumnValue GetMailZipValue()
	{
		return this.GetValue(TableUtils.MailZipColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.MailZip field.
	/// </summary>
	public string GetMailZipFieldValue()
	{
		return this.GetValue(TableUtils.MailZipColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailZip field.
	/// </summary>
	public void SetMailZipFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.MailZipColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailZip field.
	/// </summary>
	public void SetMailZipFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MailZipColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public ColumnValue GetPOCValue()
	{
		return this.GetValue(TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public Int32 GetPOCFieldValue()
	{
		return this.GetValue(TableUtils.POCColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(string val)
	{
		this.SetString(val, TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.POCName field.
	/// </summary>
	public ColumnValue GetPOCNameValue()
	{
		return this.GetValue(TableUtils.POCNameColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.POCName field.
	/// </summary>
	public string GetPOCNameFieldValue()
	{
		return this.GetValue(TableUtils.POCNameColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POCName field.
	/// </summary>
	public void SetPOCNameFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POCNameColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POCName field.
	/// </summary>
	public void SetPOCNameFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCNameColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.POCEmail field.
	/// </summary>
	public ColumnValue GetPOCEmailValue()
	{
		return this.GetValue(TableUtils.POCEmailColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.POCEmail field.
	/// </summary>
	public string GetPOCEmailFieldValue()
	{
		return this.GetValue(TableUtils.POCEmailColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POCEmail field.
	/// </summary>
	public void SetPOCEmailFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POCEmailColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POCEmail field.
	/// </summary>
	public void SetPOCEmailFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCEmailColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public ColumnValue GetSalesPersonValue()
	{
		return this.GetValue(TableUtils.SalesPersonColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public Int32 GetSalesPersonFieldValue()
	{
		return this.GetValue(TableUtils.SalesPersonColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public void SetSalesPersonFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SalesPersonColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public void SetSalesPersonFieldValue(string val)
	{
		this.SetString(val, TableUtils.SalesPersonColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public void SetSalesPersonFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SalesPersonColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public void SetSalesPersonFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SalesPersonColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public void SetSalesPersonFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SalesPersonColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.SalesPersonName field.
	/// </summary>
	public ColumnValue GetSalesPersonNameValue()
	{
		return this.GetValue(TableUtils.SalesPersonNameColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.SalesPersonName field.
	/// </summary>
	public string GetSalesPersonNameFieldValue()
	{
		return this.GetValue(TableUtils.SalesPersonNameColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPersonName field.
	/// </summary>
	public void SetSalesPersonNameFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SalesPersonNameColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPersonName field.
	/// </summary>
	public void SetSalesPersonNameFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SalesPersonNameColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.SalesPersonEmail field.
	/// </summary>
	public ColumnValue GetSalesPersonEmailValue()
	{
		return this.GetValue(TableUtils.SalesPersonEmailColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.SalesPersonEmail field.
	/// </summary>
	public string GetSalesPersonEmailFieldValue()
	{
		return this.GetValue(TableUtils.SalesPersonEmailColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPersonEmail field.
	/// </summary>
	public void SetSalesPersonEmailFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SalesPersonEmailColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPersonEmail field.
	/// </summary>
	public void SetSalesPersonEmailFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SalesPersonEmailColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.JobKey field.
	/// </summary>
	public ColumnValue GetJobKeyValue()
	{
		return this.GetValue(TableUtils.JobKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.JobKey field.
	/// </summary>
	public string GetJobKeyFieldValue()
	{
		return this.GetValue(TableUtils.JobKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.JobKey field.
	/// </summary>
	public void SetJobKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JobKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.JobKey field.
	/// </summary>
	public void SetJobKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JobKeyColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.CustomerKey field.
	/// </summary>
	public ColumnValue GetCustomerKeyValue()
	{
		return this.GetValue(TableUtils.CustomerKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.CustomerKey field.
	/// </summary>
	public string GetCustomerKeyFieldValue()
	{
		return this.GetValue(TableUtils.CustomerKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CustomerKey field.
	/// </summary>
	public void SetCustomerKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CustomerKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CustomerKey field.
	/// </summary>
	public void SetCustomerKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CustomerKeyColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public ColumnValue GetPhaseGroupValue()
	{
		return this.GetValue(TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public Byte GetPhaseGroupFieldValue()
	{
		return this.GetValue(TableUtils.PhaseGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.JobStatus field.
	/// </summary>
	public ColumnValue GetJobStatusValue()
	{
		return this.GetValue(TableUtils.JobStatusColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.JobStatus field.
	/// </summary>
	public string GetJobStatusFieldValue()
	{
		return this.GetValue(TableUtils.JobStatusColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.JobStatus field.
	/// </summary>
	public void SetJobStatusFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JobStatusColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.JobStatus field.
	/// </summary>
	public void SetJobStatusFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JobStatusColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.GLDepartmentNumber field.
	/// </summary>
	public ColumnValue GetGLDepartmentNumberValue()
	{
		return this.GetValue(TableUtils.GLDepartmentNumberColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.GLDepartmentNumber field.
	/// </summary>
	public string GetGLDepartmentNumberFieldValue()
	{
		return this.GetValue(TableUtils.GLDepartmentNumberColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.GLDepartmentNumber field.
	/// </summary>
	public void SetGLDepartmentNumberFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.GLDepartmentNumberColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.GLDepartmentNumber field.
	/// </summary>
	public void SetGLDepartmentNumberFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GLDepartmentNumberColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.GLDepartmentName field.
	/// </summary>
	public ColumnValue GetGLDepartmentNameValue()
	{
		return this.GetValue(TableUtils.GLDepartmentNameColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobXref_.GLDepartmentName field.
	/// </summary>
	public string GetGLDepartmentNameFieldValue()
	{
		return this.GetValue(TableUtils.GLDepartmentNameColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.GLDepartmentName field.
	/// </summary>
	public void SetGLDepartmentNameFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.GLDepartmentNameColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.GLDepartmentName field.
	/// </summary>
	public void SetGLDepartmentNameFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GLDepartmentNameColumn);
	}


#endregion

#region "Convenience methods to get field names"

	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public Byte VPCo
	{
		get
		{
			return this.GetValue(TableUtils.VPCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCo field.
	/// </summary>
	public string VPCoDefault
	{
		get
		{
			return TableUtils.VPCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.VPJob field.
	/// </summary>
	public string VPJob
	{
		get
		{
			return this.GetValue(TableUtils.VPJobColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPJobColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPJobSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPJobColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPJob field.
	/// </summary>
	public string VPJobDefault
	{
		get
		{
			return TableUtils.VPJobColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public Int32 CGCCo
	{
		get
		{
			return this.GetValue(TableUtils.CGCCoColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CGCCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CGCCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CGCCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCCo field.
	/// </summary>
	public string CGCCoDefault
	{
		get
		{
			return TableUtils.CGCCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.CGCJob field.
	/// </summary>
	public string CGCJob
	{
		get
		{
			return this.GetValue(TableUtils.CGCJobColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CGCJobColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CGCJobSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CGCJobColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CGCJob field.
	/// </summary>
	public string CGCJobDefault
	{
		get
		{
			return TableUtils.CGCJobColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.VPJobDesc field.
	/// </summary>
	public string VPJobDesc
	{
		get
		{
			return this.GetValue(TableUtils.VPJobDescColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPJobDescColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPJobDescSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPJobDescColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPJobDesc field.
	/// </summary>
	public string VPJobDescDefault
	{
		get
		{
			return TableUtils.VPJobDescColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public Int32 VPCustomer
	{
		get
		{
			return this.GetValue(TableUtils.VPCustomerColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPCustomerColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPCustomerSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPCustomerColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomer field.
	/// </summary>
	public string VPCustomerDefault
	{
		get
		{
			return TableUtils.VPCustomerColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.VPCustomerName field.
	/// </summary>
	public string VPCustomerName
	{
		get
		{
			return this.GetValue(TableUtils.VPCustomerNameColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPCustomerNameColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPCustomerNameSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPCustomerNameColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.VPCustomerName field.
	/// </summary>
	public string VPCustomerNameDefault
	{
		get
		{
			return TableUtils.VPCustomerNameColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.MailAddress field.
	/// </summary>
	public string MailAddress
	{
		get
		{
			return this.GetValue(TableUtils.MailAddressColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.MailAddressColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool MailAddressSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.MailAddressColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailAddress field.
	/// </summary>
	public string MailAddressDefault
	{
		get
		{
			return TableUtils.MailAddressColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.MailAddress2 field.
	/// </summary>
	public string MailAddress2
	{
		get
		{
			return this.GetValue(TableUtils.MailAddress2Column).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.MailAddress2Column);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool MailAddress2Specified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.MailAddress2Column);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailAddress2 field.
	/// </summary>
	public string MailAddress2Default
	{
		get
		{
			return TableUtils.MailAddress2Column.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.MailCity field.
	/// </summary>
	public string MailCity
	{
		get
		{
			return this.GetValue(TableUtils.MailCityColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.MailCityColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool MailCitySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.MailCityColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailCity field.
	/// </summary>
	public string MailCityDefault
	{
		get
		{
			return TableUtils.MailCityColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.MailState field.
	/// </summary>
	public string MailState
	{
		get
		{
			return this.GetValue(TableUtils.MailStateColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.MailStateColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool MailStateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.MailStateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailState field.
	/// </summary>
	public string MailStateDefault
	{
		get
		{
			return TableUtils.MailStateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.MailZip field.
	/// </summary>
	public string MailZip
	{
		get
		{
			return this.GetValue(TableUtils.MailZipColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.MailZipColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool MailZipSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.MailZipColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.MailZip field.
	/// </summary>
	public string MailZipDefault
	{
		get
		{
			return TableUtils.MailZipColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public Int32 POC
	{
		get
		{
			return this.GetValue(TableUtils.POCColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.POCColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool POCSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.POCColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POC field.
	/// </summary>
	public string POCDefault
	{
		get
		{
			return TableUtils.POCColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.POCName field.
	/// </summary>
	public string POCName
	{
		get
		{
			return this.GetValue(TableUtils.POCNameColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.POCNameColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool POCNameSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.POCNameColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POCName field.
	/// </summary>
	public string POCNameDefault
	{
		get
		{
			return TableUtils.POCNameColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.POCEmail field.
	/// </summary>
	public string POCEmail
	{
		get
		{
			return this.GetValue(TableUtils.POCEmailColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.POCEmailColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool POCEmailSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.POCEmailColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.POCEmail field.
	/// </summary>
	public string POCEmailDefault
	{
		get
		{
			return TableUtils.POCEmailColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public Int32 SalesPerson
	{
		get
		{
			return this.GetValue(TableUtils.SalesPersonColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SalesPersonColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SalesPersonSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SalesPersonColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPerson field.
	/// </summary>
	public string SalesPersonDefault
	{
		get
		{
			return TableUtils.SalesPersonColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.SalesPersonName field.
	/// </summary>
	public string SalesPersonName
	{
		get
		{
			return this.GetValue(TableUtils.SalesPersonNameColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SalesPersonNameColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SalesPersonNameSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SalesPersonNameColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPersonName field.
	/// </summary>
	public string SalesPersonNameDefault
	{
		get
		{
			return TableUtils.SalesPersonNameColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.SalesPersonEmail field.
	/// </summary>
	public string SalesPersonEmail
	{
		get
		{
			return this.GetValue(TableUtils.SalesPersonEmailColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SalesPersonEmailColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SalesPersonEmailSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SalesPersonEmailColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.SalesPersonEmail field.
	/// </summary>
	public string SalesPersonEmailDefault
	{
		get
		{
			return TableUtils.SalesPersonEmailColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.JobKey field.
	/// </summary>
	public string JobKey
	{
		get
		{
			return this.GetValue(TableUtils.JobKeyColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.JobKeyColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool JobKeySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.JobKeyColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.JobKey field.
	/// </summary>
	public string JobKeyDefault
	{
		get
		{
			return TableUtils.JobKeyColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.CustomerKey field.
	/// </summary>
	public string CustomerKey
	{
		get
		{
			return this.GetValue(TableUtils.CustomerKeyColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CustomerKeyColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CustomerKeySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CustomerKeyColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.CustomerKey field.
	/// </summary>
	public string CustomerKeyDefault
	{
		get
		{
			return TableUtils.CustomerKeyColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public Byte PhaseGroup
	{
		get
		{
			return this.GetValue(TableUtils.PhaseGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PhaseGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PhaseGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PhaseGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.PhaseGroup field.
	/// </summary>
	public string PhaseGroupDefault
	{
		get
		{
			return TableUtils.PhaseGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.JobStatus field.
	/// </summary>
	public string JobStatus
	{
		get
		{
			return this.GetValue(TableUtils.JobStatusColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.JobStatusColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool JobStatusSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.JobStatusColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.JobStatus field.
	/// </summary>
	public string JobStatusDefault
	{
		get
		{
			return TableUtils.JobStatusColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.GLDepartmentNumber field.
	/// </summary>
	public string GLDepartmentNumber
	{
		get
		{
			return this.GetValue(TableUtils.GLDepartmentNumberColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.GLDepartmentNumberColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool GLDepartmentNumberSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.GLDepartmentNumberColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.GLDepartmentNumber field.
	/// </summary>
	public string GLDepartmentNumberDefault
	{
		get
		{
			return TableUtils.GLDepartmentNumberColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobXref_.GLDepartmentName field.
	/// </summary>
	public string GLDepartmentName
	{
		get
		{
			return this.GetValue(TableUtils.GLDepartmentNameColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.GLDepartmentNameColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool GLDepartmentNameSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.GLDepartmentNameColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobXref_.GLDepartmentName field.
	/// </summary>
	public string GLDepartmentNameDefault
	{
		get
		{
			return TableUtils.GLDepartmentNameColumn.DefaultValue;
		}
	}


#endregion
}

}
