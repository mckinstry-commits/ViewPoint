// This class is "generated" and will be overwritten.
// Your customizations should be made in POHDRecord.vb

using System;
using System.Collections;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace POViewer.Business
{

/// <summary>
/// The generated superclass for the <see cref="POHDRecord"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="POHDView"></see> class.
/// </remarks>
/// <seealso cref="POHDView"></seealso>
/// <seealso cref="POHDRecord"></seealso>
public class BasePOHDRecord : KeylessRecord
{

	public readonly static POHDView TableUtils = POHDView.Instance;

	// Constructors
 
	protected BasePOHDRecord() : base(TableUtils)
	{
		this.ReadRecord +=
            new BaseClasses.IRecordWithTriggerEvents.ReadRecordEventHandler(this.POHDRecord_ReadRecord); 
        this.InsertingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.InsertingRecordEventHandler(this.POHDRecord_InsertingRecord);     
	}

	protected BasePOHDRecord(KeylessRecord record) : base(record, TableUtils)
	{
	}
	
	//Audit Trail methods
	
	//Evaluates Initialize when->Reading record formulas specified at the data access layer
    protected virtual void POHDRecord_ReadRecord(Object sender,System.EventArgs e)
    {
        //Apply Initialize->Reading record formula only if validation is successful.
                POHDRecord POHDRec = (POHDRecord)sender;
        if(POHDRec != null && !POHDRec.IsReadOnly ){
                }
    
    }
    
    	//Evaluates Initialize when->Inserting formulas specified at the data access layer
    protected virtual void POHDRecord_InsertingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Inserting formula only if validation is successful.
                POHDRecord POHDRec = (POHDRecord)sender;
        Validate_Inserting();
        if(POHDRec != null && !POHDRec.IsReadOnly ){
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
	/// This is a convenience method that provides direct access to the value of the record's POHD_.POCo field.
	/// </summary>
	public ColumnValue GetPOCoValue()
	{
		return this.GetValue(TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.POCo field.
	/// </summary>
	public Byte GetPOCoFieldValue()
	{
		return this.GetValue(TableUtils.POCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.PO field.
	/// </summary>
	public ColumnValue GetPOValue()
	{
		return this.GetValue(TableUtils.POColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.PO field.
	/// </summary>
	public string GetPOFieldValue()
	{
		return this.GetValue(TableUtils.POColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PO field.
	/// </summary>
	public void SetPOFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PO field.
	/// </summary>
	public void SetPOFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.VendorGroup field.
	/// </summary>
	public ColumnValue GetVendorGroupValue()
	{
		return this.GetValue(TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.VendorGroup field.
	/// </summary>
	public Byte GetVendorGroupFieldValue()
	{
		return this.GetValue(TableUtils.VendorGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.VendorGroup field.
	/// </summary>
	public void SetVendorGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Vendor field.
	/// </summary>
	public ColumnValue GetVendorValue()
	{
		return this.GetValue(TableUtils.VendorColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Vendor field.
	/// </summary>
	public Int32 GetVendorFieldValue()
	{
		return this.GetValue(TableUtils.VendorColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Vendor field.
	/// </summary>
	public void SetVendorFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Vendor field.
	/// </summary>
	public void SetVendorFieldValue(string val)
	{
		this.SetString(val, TableUtils.VendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Vendor field.
	/// </summary>
	public void SetVendorFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Vendor field.
	/// </summary>
	public void SetVendorFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Vendor field.
	/// </summary>
	public void SetVendorFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendorColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Description field.
	/// </summary>
	public ColumnValue GetDescriptionValue()
	{
		return this.GetValue(TableUtils.DescriptionColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Description field.
	/// </summary>
	public string GetDescriptionFieldValue()
	{
		return this.GetValue(TableUtils.DescriptionColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Description field.
	/// </summary>
	public void SetDescriptionFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.DescriptionColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Description field.
	/// </summary>
	public void SetDescriptionFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.DescriptionColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.OrderDate field.
	/// </summary>
	public ColumnValue GetOrderDateValue()
	{
		return this.GetValue(TableUtils.OrderDateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.OrderDate field.
	/// </summary>
	public DateTime GetOrderDateFieldValue()
	{
		return this.GetValue(TableUtils.OrderDateColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.OrderDate field.
	/// </summary>
	public void SetOrderDateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.OrderDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.OrderDate field.
	/// </summary>
	public void SetOrderDateFieldValue(string val)
	{
		this.SetString(val, TableUtils.OrderDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.OrderDate field.
	/// </summary>
	public void SetOrderDateFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrderDateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.OrderedBy field.
	/// </summary>
	public ColumnValue GetOrderedByValue()
	{
		return this.GetValue(TableUtils.OrderedByColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.OrderedBy field.
	/// </summary>
	public string GetOrderedByFieldValue()
	{
		return this.GetValue(TableUtils.OrderedByColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.OrderedBy field.
	/// </summary>
	public void SetOrderedByFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.OrderedByColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.OrderedBy field.
	/// </summary>
	public void SetOrderedByFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrderedByColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.ExpDate field.
	/// </summary>
	public ColumnValue GetExpDateValue()
	{
		return this.GetValue(TableUtils.ExpDateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.ExpDate field.
	/// </summary>
	public DateTime GetExpDateFieldValue()
	{
		return this.GetValue(TableUtils.ExpDateColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ExpDate field.
	/// </summary>
	public void SetExpDateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ExpDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ExpDate field.
	/// </summary>
	public void SetExpDateFieldValue(string val)
	{
		this.SetString(val, TableUtils.ExpDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ExpDate field.
	/// </summary>
	public void SetExpDateFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ExpDateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Status field.
	/// </summary>
	public ColumnValue GetStatusValue()
	{
		return this.GetValue(TableUtils.StatusColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Status field.
	/// </summary>
	public Byte GetStatusFieldValue()
	{
		return this.GetValue(TableUtils.StatusColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Status field.
	/// </summary>
	public void SetStatusFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.StatusColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Status field.
	/// </summary>
	public void SetStatusFieldValue(string val)
	{
		this.SetString(val, TableUtils.StatusColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Status field.
	/// </summary>
	public void SetStatusFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.StatusColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Status field.
	/// </summary>
	public void SetStatusFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.StatusColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Status field.
	/// </summary>
	public void SetStatusFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.StatusColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.JCCo field.
	/// </summary>
	public ColumnValue GetJCCoValue()
	{
		return this.GetValue(TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.JCCo field.
	/// </summary>
	public Byte GetJCCoFieldValue()
	{
		return this.GetValue(TableUtils.JCCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Job field.
	/// </summary>
	public ColumnValue GetJobValue()
	{
		return this.GetValue(TableUtils.JobColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Job field.
	/// </summary>
	public string GetJobFieldValue()
	{
		return this.GetValue(TableUtils.JobColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Job field.
	/// </summary>
	public void SetJobFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JobColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Job field.
	/// </summary>
	public void SetJobFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JobColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.INCo field.
	/// </summary>
	public ColumnValue GetINCoValue()
	{
		return this.GetValue(TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.INCo field.
	/// </summary>
	public Byte GetINCoFieldValue()
	{
		return this.GetValue(TableUtils.INCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.INCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Loc field.
	/// </summary>
	public ColumnValue GetLocValue()
	{
		return this.GetValue(TableUtils.LocColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Loc field.
	/// </summary>
	public string GetLocFieldValue()
	{
		return this.GetValue(TableUtils.LocColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Loc field.
	/// </summary>
	public void SetLocFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.LocColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Loc field.
	/// </summary>
	public void SetLocFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.LocColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.ShipLoc field.
	/// </summary>
	public ColumnValue GetShipLocValue()
	{
		return this.GetValue(TableUtils.ShipLocColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.ShipLoc field.
	/// </summary>
	public string GetShipLocFieldValue()
	{
		return this.GetValue(TableUtils.ShipLocColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ShipLoc field.
	/// </summary>
	public void SetShipLocFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ShipLocColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ShipLoc field.
	/// </summary>
	public void SetShipLocFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ShipLocColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Address field.
	/// </summary>
	public ColumnValue GetAddressValue()
	{
		return this.GetValue(TableUtils.AddressColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Address field.
	/// </summary>
	public string GetAddressFieldValue()
	{
		return this.GetValue(TableUtils.AddressColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Address field.
	/// </summary>
	public void SetAddressFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AddressColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Address field.
	/// </summary>
	public void SetAddressFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddressColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.City field.
	/// </summary>
	public ColumnValue GetCityValue()
	{
		return this.GetValue(TableUtils.CityColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.City field.
	/// </summary>
	public string GetCityFieldValue()
	{
		return this.GetValue(TableUtils.CityColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.City field.
	/// </summary>
	public void SetCityFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CityColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.City field.
	/// </summary>
	public void SetCityFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CityColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.State field.
	/// </summary>
	public ColumnValue GetStateValue()
	{
		return this.GetValue(TableUtils.StateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.State field.
	/// </summary>
	public string GetStateFieldValue()
	{
		return this.GetValue(TableUtils.StateColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.State field.
	/// </summary>
	public void SetStateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.StateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.State field.
	/// </summary>
	public void SetStateFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.StateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Zip field.
	/// </summary>
	public ColumnValue GetZipValue()
	{
		return this.GetValue(TableUtils.ZipColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Zip field.
	/// </summary>
	public string GetZipFieldValue()
	{
		return this.GetValue(TableUtils.ZipColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Zip field.
	/// </summary>
	public void SetZipFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ZipColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Zip field.
	/// </summary>
	public void SetZipFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ZipColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.ShipIns field.
	/// </summary>
	public ColumnValue GetShipInsValue()
	{
		return this.GetValue(TableUtils.ShipInsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.ShipIns field.
	/// </summary>
	public string GetShipInsFieldValue()
	{
		return this.GetValue(TableUtils.ShipInsColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ShipIns field.
	/// </summary>
	public void SetShipInsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ShipInsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ShipIns field.
	/// </summary>
	public void SetShipInsFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ShipInsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.HoldCode field.
	/// </summary>
	public ColumnValue GetHoldCodeValue()
	{
		return this.GetValue(TableUtils.HoldCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.HoldCode field.
	/// </summary>
	public string GetHoldCodeFieldValue()
	{
		return this.GetValue(TableUtils.HoldCodeColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.HoldCode field.
	/// </summary>
	public void SetHoldCodeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.HoldCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.HoldCode field.
	/// </summary>
	public void SetHoldCodeFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.HoldCodeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.PayTerms field.
	/// </summary>
	public ColumnValue GetPayTermsValue()
	{
		return this.GetValue(TableUtils.PayTermsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.PayTerms field.
	/// </summary>
	public string GetPayTermsFieldValue()
	{
		return this.GetValue(TableUtils.PayTermsColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayTerms field.
	/// </summary>
	public void SetPayTermsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PayTermsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayTerms field.
	/// </summary>
	public void SetPayTermsFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayTermsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.CompGroup field.
	/// </summary>
	public ColumnValue GetCompGroupValue()
	{
		return this.GetValue(TableUtils.CompGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.CompGroup field.
	/// </summary>
	public string GetCompGroupFieldValue()
	{
		return this.GetValue(TableUtils.CompGroupColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.CompGroup field.
	/// </summary>
	public void SetCompGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CompGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.CompGroup field.
	/// </summary>
	public void SetCompGroupFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CompGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.MthClosed field.
	/// </summary>
	public ColumnValue GetMthClosedValue()
	{
		return this.GetValue(TableUtils.MthClosedColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.MthClosed field.
	/// </summary>
	public DateTime GetMthClosedFieldValue()
	{
		return this.GetValue(TableUtils.MthClosedColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.MthClosed field.
	/// </summary>
	public void SetMthClosedFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.MthClosedColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.MthClosed field.
	/// </summary>
	public void SetMthClosedFieldValue(string val)
	{
		this.SetString(val, TableUtils.MthClosedColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.MthClosed field.
	/// </summary>
	public void SetMthClosedFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MthClosedColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.InUseMth field.
	/// </summary>
	public ColumnValue GetInUseMthValue()
	{
		return this.GetValue(TableUtils.InUseMthColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.InUseMth field.
	/// </summary>
	public DateTime GetInUseMthFieldValue()
	{
		return this.GetValue(TableUtils.InUseMthColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseMth field.
	/// </summary>
	public void SetInUseMthFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.InUseMthColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseMth field.
	/// </summary>
	public void SetInUseMthFieldValue(string val)
	{
		this.SetString(val, TableUtils.InUseMthColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseMth field.
	/// </summary>
	public void SetInUseMthFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InUseMthColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public ColumnValue GetInUseBatchIdValue()
	{
		return this.GetValue(TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public Int32 GetInUseBatchIdFieldValue()
	{
		return this.GetValue(TableUtils.InUseBatchIdColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(string val)
	{
		this.SetString(val, TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InUseBatchIdColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Approved field.
	/// </summary>
	public ColumnValue GetApprovedValue()
	{
		return this.GetValue(TableUtils.ApprovedColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Approved field.
	/// </summary>
	public string GetApprovedFieldValue()
	{
		return this.GetValue(TableUtils.ApprovedColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Approved field.
	/// </summary>
	public void SetApprovedFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ApprovedColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Approved field.
	/// </summary>
	public void SetApprovedFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ApprovedColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.ApprovedBy field.
	/// </summary>
	public ColumnValue GetApprovedByValue()
	{
		return this.GetValue(TableUtils.ApprovedByColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.ApprovedBy field.
	/// </summary>
	public string GetApprovedByFieldValue()
	{
		return this.GetValue(TableUtils.ApprovedByColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ApprovedBy field.
	/// </summary>
	public void SetApprovedByFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ApprovedByColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ApprovedBy field.
	/// </summary>
	public void SetApprovedByFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ApprovedByColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Purge field.
	/// </summary>
	public ColumnValue GetPurgeValue()
	{
		return this.GetValue(TableUtils.PurgeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Purge field.
	/// </summary>
	public string GetPurgeFieldValue()
	{
		return this.GetValue(TableUtils.PurgeColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Purge field.
	/// </summary>
	public void SetPurgeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PurgeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Purge field.
	/// </summary>
	public void SetPurgeFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PurgeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Notes field.
	/// </summary>
	public ColumnValue GetNotesValue()
	{
		return this.GetValue(TableUtils.NotesColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Notes field.
	/// </summary>
	public string GetNotesFieldValue()
	{
		return this.GetValue(TableUtils.NotesColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Notes field.
	/// </summary>
	public void SetNotesFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.NotesColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Notes field.
	/// </summary>
	public void SetNotesFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.NotesColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.AddedMth field.
	/// </summary>
	public ColumnValue GetAddedMthValue()
	{
		return this.GetValue(TableUtils.AddedMthColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.AddedMth field.
	/// </summary>
	public DateTime GetAddedMthFieldValue()
	{
		return this.GetValue(TableUtils.AddedMthColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedMth field.
	/// </summary>
	public void SetAddedMthFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AddedMthColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedMth field.
	/// </summary>
	public void SetAddedMthFieldValue(string val)
	{
		this.SetString(val, TableUtils.AddedMthColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedMth field.
	/// </summary>
	public void SetAddedMthFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddedMthColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public ColumnValue GetAddedBatchIDValue()
	{
		return this.GetValue(TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public Int32 GetAddedBatchIDFieldValue()
	{
		return this.GetValue(TableUtils.AddedBatchIDColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddedBatchIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.UniqueAttchID field.
	/// </summary>
	public ColumnValue GetUniqueAttchIDValue()
	{
		return this.GetValue(TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.UniqueAttchID field.
	/// </summary>
	public System.Guid GetUniqueAttchIDFieldValue()
	{
		return this.GetValue(TableUtils.UniqueAttchIDColumn).ToGuid();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(System.Guid val)
	{
		ColumnValue cv = new ColumnValue(val, System.TypeCode.Object);
		this.SetValue(cv, TableUtils.UniqueAttchIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Attention field.
	/// </summary>
	public ColumnValue GetAttentionValue()
	{
		return this.GetValue(TableUtils.AttentionColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Attention field.
	/// </summary>
	public string GetAttentionFieldValue()
	{
		return this.GetValue(TableUtils.AttentionColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Attention field.
	/// </summary>
	public void SetAttentionFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AttentionColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Attention field.
	/// </summary>
	public void SetAttentionFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AttentionColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public ColumnValue GetPayAddressSeqValue()
	{
		return this.GetValue(TableUtils.PayAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public Byte GetPayAddressSeqFieldValue()
	{
		return this.GetValue(TableUtils.PayAddressSeqColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public void SetPayAddressSeqFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PayAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public void SetPayAddressSeqFieldValue(string val)
	{
		this.SetString(val, TableUtils.PayAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public void SetPayAddressSeqFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public void SetPayAddressSeqFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public void SetPayAddressSeqFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayAddressSeqColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public ColumnValue GetPOAddressSeqValue()
	{
		return this.GetValue(TableUtils.POAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public Byte GetPOAddressSeqFieldValue()
	{
		return this.GetValue(TableUtils.POAddressSeqColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public void SetPOAddressSeqFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public void SetPOAddressSeqFieldValue(string val)
	{
		this.SetString(val, TableUtils.POAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public void SetPOAddressSeqFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public void SetPOAddressSeqFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POAddressSeqColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public void SetPOAddressSeqFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POAddressSeqColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Address2 field.
	/// </summary>
	public ColumnValue GetAddress2Value()
	{
		return this.GetValue(TableUtils.Address2Column);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Address2 field.
	/// </summary>
	public string GetAddress2FieldValue()
	{
		return this.GetValue(TableUtils.Address2Column).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Address2 field.
	/// </summary>
	public void SetAddress2FieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.Address2Column);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Address2 field.
	/// </summary>
	public void SetAddress2FieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.Address2Column);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.KeyID field.
	/// </summary>
	public ColumnValue GetKeyIDValue()
	{
		return this.GetValue(TableUtils.KeyIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.KeyID field.
	/// </summary>
	public Int64 GetKeyIDFieldValue()
	{
		return this.GetValue(TableUtils.KeyIDColumn).ToInt64();
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Country field.
	/// </summary>
	public ColumnValue GetCountryValue()
	{
		return this.GetValue(TableUtils.CountryColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.Country field.
	/// </summary>
	public string GetCountryFieldValue()
	{
		return this.GetValue(TableUtils.CountryColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Country field.
	/// </summary>
	public void SetCountryFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CountryColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Country field.
	/// </summary>
	public void SetCountryFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CountryColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public ColumnValue GetPOCloseBatchIDValue()
	{
		return this.GetValue(TableUtils.POCloseBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public Int32 GetPOCloseBatchIDFieldValue()
	{
		return this.GetValue(TableUtils.POCloseBatchIDColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public void SetPOCloseBatchIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POCloseBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public void SetPOCloseBatchIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.POCloseBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public void SetPOCloseBatchIDFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCloseBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public void SetPOCloseBatchIDFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCloseBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public void SetPOCloseBatchIDFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCloseBatchIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udSource field.
	/// </summary>
	public ColumnValue GetudSourceValue()
	{
		return this.GetValue(TableUtils.udSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udSource field.
	/// </summary>
	public string GetudSourceFieldValue()
	{
		return this.GetValue(TableUtils.udSourceColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udSource field.
	/// </summary>
	public void SetudSourceFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udSource field.
	/// </summary>
	public void SetudSourceFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udSourceColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udConv field.
	/// </summary>
	public ColumnValue GetudConvValue()
	{
		return this.GetValue(TableUtils.udConvColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udConv field.
	/// </summary>
	public string GetudConvFieldValue()
	{
		return this.GetValue(TableUtils.udConvColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udConv field.
	/// </summary>
	public void SetudConvFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udConvColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udConv field.
	/// </summary>
	public void SetudConvFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udConvColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udCGCTable field.
	/// </summary>
	public ColumnValue GetudCGCTableValue()
	{
		return this.GetValue(TableUtils.udCGCTableColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udCGCTable field.
	/// </summary>
	public string GetudCGCTableFieldValue()
	{
		return this.GetValue(TableUtils.udCGCTableColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTable field.
	/// </summary>
	public void SetudCGCTableFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCGCTableColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTable field.
	/// </summary>
	public void SetudCGCTableFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public ColumnValue GetudCGCTableIDValue()
	{
		return this.GetValue(TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public Decimal GetudCGCTableIDFieldValue()
	{
		return this.GetValue(TableUtils.udCGCTableIDColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public ColumnValue GetudOrderedByValue()
	{
		return this.GetValue(TableUtils.udOrderedByColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public Int32 GetudOrderedByFieldValue()
	{
		return this.GetValue(TableUtils.udOrderedByColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public void SetudOrderedByFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udOrderedByColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public void SetudOrderedByFieldValue(string val)
	{
		this.SetString(val, TableUtils.udOrderedByColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public void SetudOrderedByFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udOrderedByColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public void SetudOrderedByFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udOrderedByColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public void SetudOrderedByFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udOrderedByColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.DocType field.
	/// </summary>
	public ColumnValue GetDocTypeValue()
	{
		return this.GetValue(TableUtils.DocTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.DocType field.
	/// </summary>
	public string GetDocTypeFieldValue()
	{
		return this.GetValue(TableUtils.DocTypeColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.DocType field.
	/// </summary>
	public void SetDocTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.DocTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.DocType field.
	/// </summary>
	public void SetDocTypeFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.DocTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udMCKPONumber field.
	/// </summary>
	public ColumnValue GetudMCKPONumberValue()
	{
		return this.GetValue(TableUtils.udMCKPONumberColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udMCKPONumber field.
	/// </summary>
	public string GetudMCKPONumberFieldValue()
	{
		return this.GetValue(TableUtils.udMCKPONumberColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udMCKPONumber field.
	/// </summary>
	public void SetudMCKPONumberFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udMCKPONumberColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udMCKPONumber field.
	/// </summary>
	public void SetudMCKPONumberFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udMCKPONumberColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udShipToJobYN field.
	/// </summary>
	public ColumnValue GetudShipToJobYNValue()
	{
		return this.GetValue(TableUtils.udShipToJobYNColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udShipToJobYN field.
	/// </summary>
	public string GetudShipToJobYNFieldValue()
	{
		return this.GetValue(TableUtils.udShipToJobYNColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udShipToJobYN field.
	/// </summary>
	public void SetudShipToJobYNFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udShipToJobYNColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udShipToJobYN field.
	/// </summary>
	public void SetudShipToJobYNFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udShipToJobYNColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udPRCo field.
	/// </summary>
	public ColumnValue GetudPRCoValue()
	{
		return this.GetValue(TableUtils.udPRCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udPRCo field.
	/// </summary>
	public Byte GetudPRCoFieldValue()
	{
		return this.GetValue(TableUtils.udPRCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPRCo field.
	/// </summary>
	public void SetudPRCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udPRCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPRCo field.
	/// </summary>
	public void SetudPRCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.udPRCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPRCo field.
	/// </summary>
	public void SetudPRCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPRCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPRCo field.
	/// </summary>
	public void SetudPRCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPRCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPRCo field.
	/// </summary>
	public void SetudPRCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPRCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udAddressName field.
	/// </summary>
	public ColumnValue GetudAddressNameValue()
	{
		return this.GetValue(TableUtils.udAddressNameColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udAddressName field.
	/// </summary>
	public string GetudAddressNameFieldValue()
	{
		return this.GetValue(TableUtils.udAddressNameColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udAddressName field.
	/// </summary>
	public void SetudAddressNameFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udAddressNameColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udAddressName field.
	/// </summary>
	public void SetudAddressNameFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udAddressNameColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udPOFOB field.
	/// </summary>
	public ColumnValue GetudPOFOBValue()
	{
		return this.GetValue(TableUtils.udPOFOBColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udPOFOB field.
	/// </summary>
	public string GetudPOFOBFieldValue()
	{
		return this.GetValue(TableUtils.udPOFOBColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPOFOB field.
	/// </summary>
	public void SetudPOFOBFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udPOFOBColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPOFOB field.
	/// </summary>
	public void SetudPOFOBFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPOFOBColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udShipMethod field.
	/// </summary>
	public ColumnValue GetudShipMethodValue()
	{
		return this.GetValue(TableUtils.udShipMethodColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udShipMethod field.
	/// </summary>
	public string GetudShipMethodFieldValue()
	{
		return this.GetValue(TableUtils.udShipMethodColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udShipMethod field.
	/// </summary>
	public void SetudShipMethodFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udShipMethodColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udShipMethod field.
	/// </summary>
	public void SetudShipMethodFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udShipMethodColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public ColumnValue GetudPurchaseContactValue()
	{
		return this.GetValue(TableUtils.udPurchaseContactColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public Int32 GetudPurchaseContactFieldValue()
	{
		return this.GetValue(TableUtils.udPurchaseContactColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public void SetudPurchaseContactFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udPurchaseContactColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public void SetudPurchaseContactFieldValue(string val)
	{
		this.SetString(val, TableUtils.udPurchaseContactColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public void SetudPurchaseContactFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPurchaseContactColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public void SetudPurchaseContactFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPurchaseContactColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public void SetudPurchaseContactFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPurchaseContactColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udPMSource field.
	/// </summary>
	public ColumnValue GetudPMSourceValue()
	{
		return this.GetValue(TableUtils.udPMSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POHD_.udPMSource field.
	/// </summary>
	public Byte GetudPMSourceFieldValue()
	{
		return this.GetValue(TableUtils.udPMSourceColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPMSource field.
	/// </summary>
	public void SetudPMSourceFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udPMSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPMSource field.
	/// </summary>
	public void SetudPMSourceFieldValue(string val)
	{
		this.SetString(val, TableUtils.udPMSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPMSource field.
	/// </summary>
	public void SetudPMSourceFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPMSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPMSource field.
	/// </summary>
	public void SetudPMSourceFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPMSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPMSource field.
	/// </summary>
	public void SetudPMSourceFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPMSourceColumn);
	}


#endregion

#region "Convenience methods to get field names"

	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.POCo field.
	/// </summary>
	public Byte POCo
	{
		get
		{
			return this.GetValue(TableUtils.POCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.POCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool POCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.POCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCo field.
	/// </summary>
	public string POCoDefault
	{
		get
		{
			return TableUtils.POCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.PO field.
	/// </summary>
	public string PO
	{
		get
		{
			return this.GetValue(TableUtils.POColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.POColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool POSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.POColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PO field.
	/// </summary>
	public string PODefault
	{
		get
		{
			return TableUtils.POColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.VendorGroup field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.VendorGroup field.
	/// </summary>
	public string VendorGroupDefault
	{
		get
		{
			return TableUtils.VendorGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Vendor field.
	/// </summary>
	public Int32 Vendor
	{
		get
		{
			return this.GetValue(TableUtils.VendorColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VendorColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VendorSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VendorColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Vendor field.
	/// </summary>
	public string VendorDefault
	{
		get
		{
			return TableUtils.VendorColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Description field.
	/// </summary>
	public string Description
	{
		get
		{
			return this.GetValue(TableUtils.DescriptionColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.DescriptionColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool DescriptionSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.DescriptionColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Description field.
	/// </summary>
	public string DescriptionDefault
	{
		get
		{
			return TableUtils.DescriptionColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.OrderDate field.
	/// </summary>
	public DateTime OrderDate
	{
		get
		{
			return this.GetValue(TableUtils.OrderDateColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.OrderDateColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool OrderDateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.OrderDateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.OrderDate field.
	/// </summary>
	public string OrderDateDefault
	{
		get
		{
			return TableUtils.OrderDateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.OrderedBy field.
	/// </summary>
	public string OrderedBy
	{
		get
		{
			return this.GetValue(TableUtils.OrderedByColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.OrderedByColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool OrderedBySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.OrderedByColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.OrderedBy field.
	/// </summary>
	public string OrderedByDefault
	{
		get
		{
			return TableUtils.OrderedByColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.ExpDate field.
	/// </summary>
	public DateTime ExpDate
	{
		get
		{
			return this.GetValue(TableUtils.ExpDateColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ExpDateColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ExpDateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ExpDateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ExpDate field.
	/// </summary>
	public string ExpDateDefault
	{
		get
		{
			return TableUtils.ExpDateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Status field.
	/// </summary>
	public Byte Status
	{
		get
		{
			return this.GetValue(TableUtils.StatusColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.StatusColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool StatusSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.StatusColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Status field.
	/// </summary>
	public string StatusDefault
	{
		get
		{
			return TableUtils.StatusColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.JCCo field.
	/// </summary>
	public Byte JCCo
	{
		get
		{
			return this.GetValue(TableUtils.JCCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.JCCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool JCCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.JCCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.JCCo field.
	/// </summary>
	public string JCCoDefault
	{
		get
		{
			return TableUtils.JCCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Job field.
	/// </summary>
	public string Job
	{
		get
		{
			return this.GetValue(TableUtils.JobColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.JobColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool JobSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.JobColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Job field.
	/// </summary>
	public string JobDefault
	{
		get
		{
			return TableUtils.JobColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.INCo field.
	/// </summary>
	public Byte INCo
	{
		get
		{
			return this.GetValue(TableUtils.INCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.INCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool INCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.INCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.INCo field.
	/// </summary>
	public string INCoDefault
	{
		get
		{
			return TableUtils.INCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Loc field.
	/// </summary>
	public string Loc
	{
		get
		{
			return this.GetValue(TableUtils.LocColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.LocColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool LocSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.LocColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Loc field.
	/// </summary>
	public string LocDefault
	{
		get
		{
			return TableUtils.LocColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.ShipLoc field.
	/// </summary>
	public string ShipLoc
	{
		get
		{
			return this.GetValue(TableUtils.ShipLocColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ShipLocColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ShipLocSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ShipLocColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ShipLoc field.
	/// </summary>
	public string ShipLocDefault
	{
		get
		{
			return TableUtils.ShipLocColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Address field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Address field.
	/// </summary>
	public string AddressDefault
	{
		get
		{
			return TableUtils.AddressColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.City field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.City field.
	/// </summary>
	public string CityDefault
	{
		get
		{
			return TableUtils.CityColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.State field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.State field.
	/// </summary>
	public string StateDefault
	{
		get
		{
			return TableUtils.StateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Zip field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Zip field.
	/// </summary>
	public string ZipDefault
	{
		get
		{
			return TableUtils.ZipColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.ShipIns field.
	/// </summary>
	public string ShipIns
	{
		get
		{
			return this.GetValue(TableUtils.ShipInsColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ShipInsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ShipInsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ShipInsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ShipIns field.
	/// </summary>
	public string ShipInsDefault
	{
		get
		{
			return TableUtils.ShipInsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.HoldCode field.
	/// </summary>
	public string HoldCode
	{
		get
		{
			return this.GetValue(TableUtils.HoldCodeColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.HoldCodeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool HoldCodeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.HoldCodeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.HoldCode field.
	/// </summary>
	public string HoldCodeDefault
	{
		get
		{
			return TableUtils.HoldCodeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.PayTerms field.
	/// </summary>
	public string PayTerms
	{
		get
		{
			return this.GetValue(TableUtils.PayTermsColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PayTermsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PayTermsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PayTermsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayTerms field.
	/// </summary>
	public string PayTermsDefault
	{
		get
		{
			return TableUtils.PayTermsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.CompGroup field.
	/// </summary>
	public string CompGroup
	{
		get
		{
			return this.GetValue(TableUtils.CompGroupColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CompGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CompGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CompGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.CompGroup field.
	/// </summary>
	public string CompGroupDefault
	{
		get
		{
			return TableUtils.CompGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.MthClosed field.
	/// </summary>
	public DateTime MthClosed
	{
		get
		{
			return this.GetValue(TableUtils.MthClosedColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.MthClosedColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool MthClosedSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.MthClosedColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.MthClosed field.
	/// </summary>
	public string MthClosedDefault
	{
		get
		{
			return TableUtils.MthClosedColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.InUseMth field.
	/// </summary>
	public DateTime InUseMth
	{
		get
		{
			return this.GetValue(TableUtils.InUseMthColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.InUseMthColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool InUseMthSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.InUseMthColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseMth field.
	/// </summary>
	public string InUseMthDefault
	{
		get
		{
			return TableUtils.InUseMthColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public Int32 InUseBatchId
	{
		get
		{
			return this.GetValue(TableUtils.InUseBatchIdColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.InUseBatchIdColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool InUseBatchIdSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.InUseBatchIdColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.InUseBatchId field.
	/// </summary>
	public string InUseBatchIdDefault
	{
		get
		{
			return TableUtils.InUseBatchIdColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Approved field.
	/// </summary>
	public string Approved
	{
		get
		{
			return this.GetValue(TableUtils.ApprovedColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ApprovedColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ApprovedSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ApprovedColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Approved field.
	/// </summary>
	public string ApprovedDefault
	{
		get
		{
			return TableUtils.ApprovedColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.ApprovedBy field.
	/// </summary>
	public string ApprovedBy
	{
		get
		{
			return this.GetValue(TableUtils.ApprovedByColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ApprovedByColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ApprovedBySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ApprovedByColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.ApprovedBy field.
	/// </summary>
	public string ApprovedByDefault
	{
		get
		{
			return TableUtils.ApprovedByColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Purge field.
	/// </summary>
	public string Purge
	{
		get
		{
			return this.GetValue(TableUtils.PurgeColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PurgeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PurgeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PurgeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Purge field.
	/// </summary>
	public string PurgeDefault
	{
		get
		{
			return TableUtils.PurgeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Notes field.
	/// </summary>
	public string Notes
	{
		get
		{
			return this.GetValue(TableUtils.NotesColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.NotesColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool NotesSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.NotesColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Notes field.
	/// </summary>
	public string NotesDefault
	{
		get
		{
			return TableUtils.NotesColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.AddedMth field.
	/// </summary>
	public DateTime AddedMth
	{
		get
		{
			return this.GetValue(TableUtils.AddedMthColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.AddedMthColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool AddedMthSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.AddedMthColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedMth field.
	/// </summary>
	public string AddedMthDefault
	{
		get
		{
			return TableUtils.AddedMthColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public Int32 AddedBatchID
	{
		get
		{
			return this.GetValue(TableUtils.AddedBatchIDColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.AddedBatchIDColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool AddedBatchIDSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.AddedBatchIDColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.AddedBatchID field.
	/// </summary>
	public string AddedBatchIDDefault
	{
		get
		{
			return TableUtils.AddedBatchIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.UniqueAttchID field.
	/// </summary>
	public System.Guid UniqueAttchID
	{
		get
		{
			return this.GetValue(TableUtils.UniqueAttchIDColumn).ToGuid();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value, System.TypeCode.Object);
			this.SetValue(cv, TableUtils.UniqueAttchIDColumn);
		}
	}
		

	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool UniqueAttchIDSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.UniqueAttchIDColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.UniqueAttchID field.
	/// </summary>
	public string UniqueAttchIDDefault
	{
		get
		{
			return TableUtils.UniqueAttchIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Attention field.
	/// </summary>
	public string Attention
	{
		get
		{
			return this.GetValue(TableUtils.AttentionColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.AttentionColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool AttentionSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.AttentionColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Attention field.
	/// </summary>
	public string AttentionDefault
	{
		get
		{
			return TableUtils.AttentionColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public Byte PayAddressSeq
	{
		get
		{
			return this.GetValue(TableUtils.PayAddressSeqColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PayAddressSeqColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PayAddressSeqSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PayAddressSeqColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.PayAddressSeq field.
	/// </summary>
	public string PayAddressSeqDefault
	{
		get
		{
			return TableUtils.PayAddressSeqColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public Byte POAddressSeq
	{
		get
		{
			return this.GetValue(TableUtils.POAddressSeqColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.POAddressSeqColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool POAddressSeqSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.POAddressSeqColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POAddressSeq field.
	/// </summary>
	public string POAddressSeqDefault
	{
		get
		{
			return TableUtils.POAddressSeqColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Address2 field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Address2 field.
	/// </summary>
	public string Address2Default
	{
		get
		{
			return TableUtils.Address2Column.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.KeyID field.
	/// </summary>
	public Int64 KeyID
	{
		get
		{
			return this.GetValue(TableUtils.KeyIDColumn).ToInt64();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.KeyIDColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool KeyIDSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.KeyIDColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.KeyID field.
	/// </summary>
	public string KeyIDDefault
	{
		get
		{
			return TableUtils.KeyIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.Country field.
	/// </summary>
	public string Country
	{
		get
		{
			return this.GetValue(TableUtils.CountryColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CountryColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CountrySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CountryColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.Country field.
	/// </summary>
	public string CountryDefault
	{
		get
		{
			return TableUtils.CountryColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public Int32 POCloseBatchID
	{
		get
		{
			return this.GetValue(TableUtils.POCloseBatchIDColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.POCloseBatchIDColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool POCloseBatchIDSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.POCloseBatchIDColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.POCloseBatchID field.
	/// </summary>
	public string POCloseBatchIDDefault
	{
		get
		{
			return TableUtils.POCloseBatchIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udSource field.
	/// </summary>
	public string udSource
	{
		get
		{
			return this.GetValue(TableUtils.udSourceColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udSourceColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udSourceSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udSourceColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udSource field.
	/// </summary>
	public string udSourceDefault
	{
		get
		{
			return TableUtils.udSourceColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udConv field.
	/// </summary>
	public string udConv
	{
		get
		{
			return this.GetValue(TableUtils.udConvColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udConvColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udConvSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udConvColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udConv field.
	/// </summary>
	public string udConvDefault
	{
		get
		{
			return TableUtils.udConvColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udCGCTable field.
	/// </summary>
	public string udCGCTable
	{
		get
		{
			return this.GetValue(TableUtils.udCGCTableColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udCGCTableColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udCGCTableSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udCGCTableColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTable field.
	/// </summary>
	public string udCGCTableDefault
	{
		get
		{
			return TableUtils.udCGCTableColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public Decimal udCGCTableID
	{
		get
		{
			return this.GetValue(TableUtils.udCGCTableIDColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udCGCTableIDColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udCGCTableIDSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udCGCTableIDColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udCGCTableID field.
	/// </summary>
	public string udCGCTableIDDefault
	{
		get
		{
			return TableUtils.udCGCTableIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public Int32 udOrderedBy
	{
		get
		{
			return this.GetValue(TableUtils.udOrderedByColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udOrderedByColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udOrderedBySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udOrderedByColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udOrderedBy field.
	/// </summary>
	public string udOrderedByDefault
	{
		get
		{
			return TableUtils.udOrderedByColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.DocType field.
	/// </summary>
	public string DocType
	{
		get
		{
			return this.GetValue(TableUtils.DocTypeColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.DocTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool DocTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.DocTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.DocType field.
	/// </summary>
	public string DocTypeDefault
	{
		get
		{
			return TableUtils.DocTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udMCKPONumber field.
	/// </summary>
	public string udMCKPONumber
	{
		get
		{
			return this.GetValue(TableUtils.udMCKPONumberColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udMCKPONumberColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udMCKPONumberSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udMCKPONumberColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udMCKPONumber field.
	/// </summary>
	public string udMCKPONumberDefault
	{
		get
		{
			return TableUtils.udMCKPONumberColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udShipToJobYN field.
	/// </summary>
	public string udShipToJobYN
	{
		get
		{
			return this.GetValue(TableUtils.udShipToJobYNColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udShipToJobYNColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udShipToJobYNSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udShipToJobYNColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udShipToJobYN field.
	/// </summary>
	public string udShipToJobYNDefault
	{
		get
		{
			return TableUtils.udShipToJobYNColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udPRCo field.
	/// </summary>
	public Byte udPRCo
	{
		get
		{
			return this.GetValue(TableUtils.udPRCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udPRCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udPRCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udPRCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPRCo field.
	/// </summary>
	public string udPRCoDefault
	{
		get
		{
			return TableUtils.udPRCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udAddressName field.
	/// </summary>
	public string udAddressName
	{
		get
		{
			return this.GetValue(TableUtils.udAddressNameColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udAddressNameColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udAddressNameSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udAddressNameColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udAddressName field.
	/// </summary>
	public string udAddressNameDefault
	{
		get
		{
			return TableUtils.udAddressNameColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udPOFOB field.
	/// </summary>
	public string udPOFOB
	{
		get
		{
			return this.GetValue(TableUtils.udPOFOBColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udPOFOBColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udPOFOBSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udPOFOBColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPOFOB field.
	/// </summary>
	public string udPOFOBDefault
	{
		get
		{
			return TableUtils.udPOFOBColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udShipMethod field.
	/// </summary>
	public string udShipMethod
	{
		get
		{
			return this.GetValue(TableUtils.udShipMethodColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udShipMethodColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udShipMethodSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udShipMethodColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udShipMethod field.
	/// </summary>
	public string udShipMethodDefault
	{
		get
		{
			return TableUtils.udShipMethodColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public Int32 udPurchaseContact
	{
		get
		{
			return this.GetValue(TableUtils.udPurchaseContactColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udPurchaseContactColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udPurchaseContactSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udPurchaseContactColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPurchaseContact field.
	/// </summary>
	public string udPurchaseContactDefault
	{
		get
		{
			return TableUtils.udPurchaseContactColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POHD_.udPMSource field.
	/// </summary>
	public Byte udPMSource
	{
		get
		{
			return this.GetValue(TableUtils.udPMSourceColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udPMSourceColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udPMSourceSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udPMSourceColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POHD_.udPMSource field.
	/// </summary>
	public string udPMSourceDefault
	{
		get
		{
			return TableUtils.udPMSourceColumn.DefaultValue;
		}
	}


#endregion

}

}
