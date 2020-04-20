// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDVendorXrefRecord.cs

using System;
using System.Collections;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace ViewpointXRef.Business
{

/// <summary>
/// The generated superclass for the <see cref="MvwISDVendorXrefRecord"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="MvwISDVendorXrefView"></see> class.
/// </remarks>
/// <seealso cref="MvwISDVendorXrefView"></seealso>
/// <seealso cref="MvwISDVendorXrefRecord"></seealso>
public class BaseMvwISDVendorXrefRecord : PrimaryKeyRecord
{

	public readonly static MvwISDVendorXrefView TableUtils = MvwISDVendorXrefView.Instance;

	// Constructors
 
	protected BaseMvwISDVendorXrefRecord() : base(TableUtils)
	{
		this.InsertingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.InsertingRecordEventHandler(this.MvwISDVendorXrefRecord_InsertingRecord); 
		this.UpdatingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.UpdatingRecordEventHandler(this.MvwISDVendorXrefRecord_UpdatingRecord); 
		this.ReadRecord +=
            new BaseClasses.IRecordWithTriggerEvents.ReadRecordEventHandler(this.MvwISDVendorXrefRecord_ReadRecord); 
	}

	protected BaseMvwISDVendorXrefRecord(PrimaryKeyRecord record) : base(record, TableUtils)
	{
	}
	
	
	//Audit Trail methods
	
	//Evaluates Initialize when->Reading record formulas specified at the data access layer
    protected virtual void MvwISDVendorXrefRecord_ReadRecord(Object sender,System.EventArgs e)
    {
        //Apply Initialize->Reading record formula only if validation is successful.
                MvwISDVendorXrefRecord MvwISDVendorXrefRec = (MvwISDVendorXrefRecord)sender;
        if(MvwISDVendorXrefRec != null && !MvwISDVendorXrefRec.IsReadOnly ){
                }
    
    }
        
	//Evaluates Initialize when->Inserting formulas specified at the data access layer
    protected virtual void MvwISDVendorXrefRecord_InsertingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Inserting formula only if validation is successful.
                MvwISDVendorXrefRecord MvwISDVendorXrefRec = (MvwISDVendorXrefRecord)sender;
        Validate_Inserting();
        if(MvwISDVendorXrefRec != null && !MvwISDVendorXrefRec.IsReadOnly ){
                }
    
    }
    
    //Evaluates Initialize when->Updating formulas specified at the data access layer
    protected virtual void MvwISDVendorXrefRecord_UpdatingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Updating formula only if validation is successful.
                MvwISDVendorXrefRecord MvwISDVendorXrefRec = (MvwISDVendorXrefRecord)sender;
        Validate_Updating();
        if(MvwISDVendorXrefRec != null && !MvwISDVendorXrefRec.IsReadOnly ){
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
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public ColumnValue GetVendorGroupValue()
	{
		return this.GetValue(TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public Byte GetVendorGroupFieldValue()
	{
		return this.GetValue(TableUtils.VendorGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public ColumnValue GetVPVendorValue()
	{
		return this.GetValue(TableUtils.VPVendorColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public Int32 GetVPVendorFieldValue()
	{
		return this.GetValue(TableUtils.VPVendorColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public void SetVPVendorFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPVendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public void SetVPVendorFieldValue(string val)
	{
		this.SetString(val, TableUtils.VPVendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public void SetVPVendorFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPVendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public void SetVPVendorFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPVendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public void SetVPVendorFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPVendorColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.CGCVendor field.
	/// </summary>
	public ColumnValue GetCGCVendorValue()
	{
		return this.GetValue(TableUtils.CGCVendorColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.CGCVendor field.
	/// </summary>
	public string GetCGCVendorFieldValue()
	{
		return this.GetValue(TableUtils.CGCVendorColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.CGCVendor field.
	/// </summary>
	public void SetCGCVendorFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CGCVendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.CGCVendor field.
	/// </summary>
	public void SetCGCVendorFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CGCVendorColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.VendorName field.
	/// </summary>
	public ColumnValue GetVendorNameValue()
	{
		return this.GetValue(TableUtils.VendorNameColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.VendorName field.
	/// </summary>
	public string GetVendorNameFieldValue()
	{
		return this.GetValue(TableUtils.VendorNameColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorName field.
	/// </summary>
	public void SetVendorNameFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VendorNameColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorName field.
	/// </summary>
	public void SetVendorNameFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorNameColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.IsSubcontractor field.
	/// </summary>
	public ColumnValue GetIsSubcontractorValue()
	{
		return this.GetValue(TableUtils.IsSubcontractorColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.IsSubcontractor field.
	/// </summary>
	public string GetIsSubcontractorFieldValue()
	{
		return this.GetValue(TableUtils.IsSubcontractorColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.IsSubcontractor field.
	/// </summary>
	public void SetIsSubcontractorFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.IsSubcontractorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.IsSubcontractor field.
	/// </summary>
	public void SetIsSubcontractorFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.IsSubcontractorColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.Address field.
	/// </summary>
	public ColumnValue GetAddressValue()
	{
		return this.GetValue(TableUtils.AddressColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.Address field.
	/// </summary>
	public string GetAddressFieldValue()
	{
		return this.GetValue(TableUtils.AddressColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Address field.
	/// </summary>
	public void SetAddressFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AddressColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Address field.
	/// </summary>
	public void SetAddressFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddressColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.Address2 field.
	/// </summary>
	public ColumnValue GetAddress2Value()
	{
		return this.GetValue(TableUtils.Address2Column);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.Address2 field.
	/// </summary>
	public string GetAddress2FieldValue()
	{
		return this.GetValue(TableUtils.Address2Column).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Address2 field.
	/// </summary>
	public void SetAddress2FieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.Address2Column);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Address2 field.
	/// </summary>
	public void SetAddress2FieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.Address2Column);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.City field.
	/// </summary>
	public ColumnValue GetCityValue()
	{
		return this.GetValue(TableUtils.CityColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.City field.
	/// </summary>
	public string GetCityFieldValue()
	{
		return this.GetValue(TableUtils.CityColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.City field.
	/// </summary>
	public void SetCityFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CityColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.City field.
	/// </summary>
	public void SetCityFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CityColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.State field.
	/// </summary>
	public ColumnValue GetStateValue()
	{
		return this.GetValue(TableUtils.StateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.State field.
	/// </summary>
	public string GetStateFieldValue()
	{
		return this.GetValue(TableUtils.StateColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.State field.
	/// </summary>
	public void SetStateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.StateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.State field.
	/// </summary>
	public void SetStateFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.StateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.Zip field.
	/// </summary>
	public ColumnValue GetZipValue()
	{
		return this.GetValue(TableUtils.ZipColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.Zip field.
	/// </summary>
	public string GetZipFieldValue()
	{
		return this.GetValue(TableUtils.ZipColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Zip field.
	/// </summary>
	public void SetZipFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ZipColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Zip field.
	/// </summary>
	public void SetZipFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ZipColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.VendorKey field.
	/// </summary>
	public ColumnValue GetVendorKeyValue()
	{
		return this.GetValue(TableUtils.VendorKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDVendorXref_.VendorKey field.
	/// </summary>
	public string GetVendorKeyFieldValue()
	{
		return this.GetValue(TableUtils.VendorKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorKey field.
	/// </summary>
	public void SetVendorKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VendorKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorKey field.
	/// </summary>
	public void SetVendorKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorKeyColumn);
	}


#endregion

#region "Convenience methods to get field names"

	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public Byte VendorGroup
	{
		get
		{
			return this.GetValue(TableUtils.VendorGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VendorGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VendorGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VendorGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorGroup field.
	/// </summary>
	public string VendorGroupDefault
	{
		get
		{
			return TableUtils.VendorGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public Int32 VPVendor
	{
		get
		{
			return this.GetValue(TableUtils.VPVendorColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPVendorColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPVendorSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPVendorColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VPVendor field.
	/// </summary>
	public string VPVendorDefault
	{
		get
		{
			return TableUtils.VPVendorColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.CGCVendor field.
	/// </summary>
	public string CGCVendor
	{
		get
		{
			return this.GetValue(TableUtils.CGCVendorColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CGCVendorColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CGCVendorSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CGCVendorColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.CGCVendor field.
	/// </summary>
	public string CGCVendorDefault
	{
		get
		{
			return TableUtils.CGCVendorColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.VendorName field.
	/// </summary>
	public string VendorName
	{
		get
		{
			return this.GetValue(TableUtils.VendorNameColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VendorNameColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VendorNameSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VendorNameColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorName field.
	/// </summary>
	public string VendorNameDefault
	{
		get
		{
			return TableUtils.VendorNameColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.IsSubcontractor field.
	/// </summary>
	public string IsSubcontractor
	{
		get
		{
			return this.GetValue(TableUtils.IsSubcontractorColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.IsSubcontractorColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool IsSubcontractorSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.IsSubcontractorColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.IsSubcontractor field.
	/// </summary>
	public string IsSubcontractorDefault
	{
		get
		{
			return TableUtils.IsSubcontractorColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.Address field.
	/// </summary>
	public string Address
	{
		get
		{
			return this.GetValue(TableUtils.AddressColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.AddressColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool AddressSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.AddressColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Address field.
	/// </summary>
	public string AddressDefault
	{
		get
		{
			return TableUtils.AddressColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.Address2 field.
	/// </summary>
	public string Address2
	{
		get
		{
			return this.GetValue(TableUtils.Address2Column).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.Address2Column);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool Address2Specified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.Address2Column);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Address2 field.
	/// </summary>
	public string Address2Default
	{
		get
		{
			return TableUtils.Address2Column.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.City field.
	/// </summary>
	public string City
	{
		get
		{
			return this.GetValue(TableUtils.CityColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CityColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CitySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CityColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.City field.
	/// </summary>
	public string CityDefault
	{
		get
		{
			return TableUtils.CityColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.State field.
	/// </summary>
	public string State
	{
		get
		{
			return this.GetValue(TableUtils.StateColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.StateColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool StateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.StateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.State field.
	/// </summary>
	public string StateDefault
	{
		get
		{
			return TableUtils.StateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.Zip field.
	/// </summary>
	public string Zip
	{
		get
		{
			return this.GetValue(TableUtils.ZipColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ZipColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ZipSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ZipColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.Zip field.
	/// </summary>
	public string ZipDefault
	{
		get
		{
			return TableUtils.ZipColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDVendorXref_.VendorKey field.
	/// </summary>
	public string VendorKey
	{
		get
		{
			return this.GetValue(TableUtils.VendorKeyColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VendorKeyColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VendorKeySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VendorKeyColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDVendorXref_.VendorKey field.
	/// </summary>
	public string VendorKeyDefault
	{
		get
		{
			return TableUtils.VendorKeyColumn.DefaultValue;
		}
	}


#endregion
}

}
