// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDCustomerXrefRecord.cs

using System;
using System.Collections;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace VPLookup.Business
{

/// <summary>
/// The generated superclass for the <see cref="MvwISDCustomerXrefRecord"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="MvwISDCustomerXrefView"></see> class.
/// </remarks>
/// <seealso cref="MvwISDCustomerXrefView"></seealso>
/// <seealso cref="MvwISDCustomerXrefRecord"></seealso>
public class BaseMvwISDCustomerXrefRecord : PrimaryKeyRecord
{

	public readonly static MvwISDCustomerXrefView TableUtils = MvwISDCustomerXrefView.Instance;

	// Constructors
 
	protected BaseMvwISDCustomerXrefRecord() : base(TableUtils)
	{
		this.InsertingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.InsertingRecordEventHandler(this.MvwISDCustomerXrefRecord_InsertingRecord); 
		this.UpdatingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.UpdatingRecordEventHandler(this.MvwISDCustomerXrefRecord_UpdatingRecord); 
		this.ReadRecord +=
            new BaseClasses.IRecordWithTriggerEvents.ReadRecordEventHandler(this.MvwISDCustomerXrefRecord_ReadRecord); 
	}

	protected BaseMvwISDCustomerXrefRecord(PrimaryKeyRecord record) : base(record, TableUtils)
	{
	}
	
	
	//Audit Trail methods
	
	//Evaluates Initialize when->Reading record formulas specified at the data access layer
    protected virtual void MvwISDCustomerXrefRecord_ReadRecord(Object sender,System.EventArgs e)
    {
        //Apply Initialize->Reading record formula only if validation is successful.
                MvwISDCustomerXrefRecord MvwISDCustomerXrefRec = (MvwISDCustomerXrefRecord)sender;
        if(MvwISDCustomerXrefRec != null && !MvwISDCustomerXrefRec.IsReadOnly ){
                }
    
    }
        
	//Evaluates Initialize when->Inserting formulas specified at the data access layer
    protected virtual void MvwISDCustomerXrefRecord_InsertingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Inserting formula only if validation is successful.
                MvwISDCustomerXrefRecord MvwISDCustomerXrefRec = (MvwISDCustomerXrefRecord)sender;
        Validate_Inserting();
        if(MvwISDCustomerXrefRec != null && !MvwISDCustomerXrefRec.IsReadOnly ){
                }
    
    }
    
    //Evaluates Initialize when->Updating formulas specified at the data access layer
    protected virtual void MvwISDCustomerXrefRecord_UpdatingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Updating formula only if validation is successful.
                MvwISDCustomerXrefRecord MvwISDCustomerXrefRec = (MvwISDCustomerXrefRecord)sender;
        Validate_Updating();
        if(MvwISDCustomerXrefRec != null && !MvwISDCustomerXrefRec.IsReadOnly ){
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
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public ColumnValue GetCustGroupValue()
	{
		return this.GetValue(TableUtils.CustGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public Byte GetCustGroupFieldValue()
	{
		return this.GetValue(TableUtils.CustGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public void SetCustGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CustGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public void SetCustGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.CustGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public void SetCustGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CustGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public void SetCustGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CustGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public void SetCustGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CustGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.VPCustomer field.
	/// </summary>
	public ColumnValue GetVPCustomerValue()
	{
		return this.GetValue(TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.VPCustomer field.
	/// </summary>
	public Int32 GetVPCustomerFieldValue()
	{
		return this.GetValue(TableUtils.VPCustomerColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(string val)
	{
		this.SetString(val, TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.VPCustomer field.
	/// </summary>
	public void SetVPCustomerFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCustomerColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.CGCCustomer field.
	/// </summary>
	public ColumnValue GetCGCCustomerValue()
	{
		return this.GetValue(TableUtils.CGCCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.CGCCustomer field.
	/// </summary>
	public string GetCGCCustomerFieldValue()
	{
		return this.GetValue(TableUtils.CGCCustomerColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CGCCustomer field.
	/// </summary>
	public void SetCGCCustomerFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CGCCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CGCCustomer field.
	/// </summary>
	public void SetCGCCustomerFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CGCCustomerColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.AsteaCustomer field.
	/// </summary>
	public ColumnValue GetAsteaCustomerValue()
	{
		return this.GetValue(TableUtils.AsteaCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.AsteaCustomer field.
	/// </summary>
	public string GetAsteaCustomerFieldValue()
	{
		return this.GetValue(TableUtils.AsteaCustomerColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.AsteaCustomer field.
	/// </summary>
	public void SetAsteaCustomerFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AsteaCustomerColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.AsteaCustomer field.
	/// </summary>
	public void SetAsteaCustomerFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AsteaCustomerColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.CustomerName field.
	/// </summary>
	public ColumnValue GetCustomerNameValue()
	{
		return this.GetValue(TableUtils.CustomerNameColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.CustomerName field.
	/// </summary>
	public string GetCustomerNameFieldValue()
	{
		return this.GetValue(TableUtils.CustomerNameColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustomerName field.
	/// </summary>
	public void SetCustomerNameFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CustomerNameColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustomerName field.
	/// </summary>
	public void SetCustomerNameFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CustomerNameColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.Address field.
	/// </summary>
	public ColumnValue GetAddressValue()
	{
		return this.GetValue(TableUtils.AddressColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.Address field.
	/// </summary>
	public string GetAddressFieldValue()
	{
		return this.GetValue(TableUtils.AddressColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Address field.
	/// </summary>
	public void SetAddressFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AddressColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Address field.
	/// </summary>
	public void SetAddressFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddressColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.Address2 field.
	/// </summary>
	public ColumnValue GetAddress2Value()
	{
		return this.GetValue(TableUtils.Address2Column);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.Address2 field.
	/// </summary>
	public string GetAddress2FieldValue()
	{
		return this.GetValue(TableUtils.Address2Column).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Address2 field.
	/// </summary>
	public void SetAddress2FieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.Address2Column);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Address2 field.
	/// </summary>
	public void SetAddress2FieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.Address2Column);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.City field.
	/// </summary>
	public ColumnValue GetCityValue()
	{
		return this.GetValue(TableUtils.CityColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.City field.
	/// </summary>
	public string GetCityFieldValue()
	{
		return this.GetValue(TableUtils.CityColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.City field.
	/// </summary>
	public void SetCityFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CityColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.City field.
	/// </summary>
	public void SetCityFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CityColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.State field.
	/// </summary>
	public ColumnValue GetStateValue()
	{
		return this.GetValue(TableUtils.StateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.State field.
	/// </summary>
	public string GetStateFieldValue()
	{
		return this.GetValue(TableUtils.StateColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.State field.
	/// </summary>
	public void SetStateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.StateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.State field.
	/// </summary>
	public void SetStateFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.StateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.Zip field.
	/// </summary>
	public ColumnValue GetZipValue()
	{
		return this.GetValue(TableUtils.ZipColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.Zip field.
	/// </summary>
	public string GetZipFieldValue()
	{
		return this.GetValue(TableUtils.ZipColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Zip field.
	/// </summary>
	public void SetZipFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ZipColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Zip field.
	/// </summary>
	public void SetZipFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ZipColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.CustomerKey field.
	/// </summary>
	public ColumnValue GetCustomerKeyValue()
	{
		return this.GetValue(TableUtils.CustomerKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDCustomerXref_.CustomerKey field.
	/// </summary>
	public string GetCustomerKeyFieldValue()
	{
		return this.GetValue(TableUtils.CustomerKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustomerKey field.
	/// </summary>
	public void SetCustomerKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CustomerKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustomerKey field.
	/// </summary>
	public void SetCustomerKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CustomerKeyColumn);
	}


#endregion

#region "Convenience methods to get field names"

	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public Byte CustGroup
	{
		get
		{
			return this.GetValue(TableUtils.CustGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CustGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CustGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CustGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustGroup field.
	/// </summary>
	public string CustGroupDefault
	{
		get
		{
			return TableUtils.CustGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.VPCustomer field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.VPCustomer field.
	/// </summary>
	public string VPCustomerDefault
	{
		get
		{
			return TableUtils.VPCustomerColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.CGCCustomer field.
	/// </summary>
	public string CGCCustomer
	{
		get
		{
			return this.GetValue(TableUtils.CGCCustomerColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CGCCustomerColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CGCCustomerSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CGCCustomerColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CGCCustomer field.
	/// </summary>
	public string CGCCustomerDefault
	{
		get
		{
			return TableUtils.CGCCustomerColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.AsteaCustomer field.
	/// </summary>
	public string AsteaCustomer
	{
		get
		{
			return this.GetValue(TableUtils.AsteaCustomerColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.AsteaCustomerColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool AsteaCustomerSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.AsteaCustomerColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.AsteaCustomer field.
	/// </summary>
	public string AsteaCustomerDefault
	{
		get
		{
			return TableUtils.AsteaCustomerColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.CustomerName field.
	/// </summary>
	public string CustomerName
	{
		get
		{
			return this.GetValue(TableUtils.CustomerNameColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CustomerNameColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CustomerNameSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CustomerNameColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustomerName field.
	/// </summary>
	public string CustomerNameDefault
	{
		get
		{
			return TableUtils.CustomerNameColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.Address field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Address field.
	/// </summary>
	public string AddressDefault
	{
		get
		{
			return TableUtils.AddressColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.Address2 field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Address2 field.
	/// </summary>
	public string Address2Default
	{
		get
		{
			return TableUtils.Address2Column.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.City field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.City field.
	/// </summary>
	public string CityDefault
	{
		get
		{
			return TableUtils.CityColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.State field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.State field.
	/// </summary>
	public string StateDefault
	{
		get
		{
			return TableUtils.StateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.Zip field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.Zip field.
	/// </summary>
	public string ZipDefault
	{
		get
		{
			return TableUtils.ZipColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDCustomerXref_.CustomerKey field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDCustomerXref_.CustomerKey field.
	/// </summary>
	public string CustomerKeyDefault
	{
		get
		{
			return TableUtils.CustomerKeyColumn.DefaultValue;
		}
	}


#endregion
}

}
