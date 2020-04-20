// This class is "generated" and will be overwritten.
// Your customizations should be made in POITRecord.vb

using System;
using System.Collections;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace POViewer.Business
{

/// <summary>
/// The generated superclass for the <see cref="POITRecord"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="POITView"></see> class.
/// </remarks>
/// <seealso cref="POITView"></seealso>
/// <seealso cref="POITRecord"></seealso>
public class BasePOITRecord : KeylessRecord
{

	public readonly static POITView TableUtils = POITView.Instance;

	// Constructors
 
	protected BasePOITRecord() : base(TableUtils)
	{
		this.ReadRecord +=
            new BaseClasses.IRecordWithTriggerEvents.ReadRecordEventHandler(this.POITRecord_ReadRecord); 
        this.InsertingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.InsertingRecordEventHandler(this.POITRecord_InsertingRecord);     
	}

	protected BasePOITRecord(KeylessRecord record) : base(record, TableUtils)
	{
	}
	
	//Audit Trail methods
	
	//Evaluates Initialize when->Reading record formulas specified at the data access layer
    protected virtual void POITRecord_ReadRecord(Object sender,System.EventArgs e)
    {
        //Apply Initialize->Reading record formula only if validation is successful.
                POITRecord POITRec = (POITRecord)sender;
        if(POITRec != null && !POITRec.IsReadOnly ){
                }
    
    }
    
    	//Evaluates Initialize when->Inserting formulas specified at the data access layer
    protected virtual void POITRecord_InsertingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Inserting formula only if validation is successful.
                POITRecord POITRec = (POITRecord)sender;
        Validate_Inserting();
        if(POITRec != null && !POITRec.IsReadOnly ){
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
	/// This is a convenience method that provides direct access to the value of the record's POIT_.POCo field.
	/// </summary>
	public ColumnValue GetPOCoValue()
	{
		return this.GetValue(TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.POCo field.
	/// </summary>
	public Byte GetPOCoFieldValue()
	{
		return this.GetValue(TableUtils.POCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POCo field.
	/// </summary>
	public void SetPOCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PO field.
	/// </summary>
	public ColumnValue GetPOValue()
	{
		return this.GetValue(TableUtils.POColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PO field.
	/// </summary>
	public string GetPOFieldValue()
	{
		return this.GetValue(TableUtils.POColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PO field.
	/// </summary>
	public void SetPOFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PO field.
	/// </summary>
	public void SetPOFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.POItem field.
	/// </summary>
	public ColumnValue GetPOItemValue()
	{
		return this.GetValue(TableUtils.POItemColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.POItem field.
	/// </summary>
	public Int16 GetPOItemFieldValue()
	{
		return this.GetValue(TableUtils.POItemColumn).ToInt16();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POItem field.
	/// </summary>
	public void SetPOItemFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POItemColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POItem field.
	/// </summary>
	public void SetPOItemFieldValue(string val)
	{
		this.SetString(val, TableUtils.POItemColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POItem field.
	/// </summary>
	public void SetPOItemFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POItemColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POItem field.
	/// </summary>
	public void SetPOItemFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POItemColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POItem field.
	/// </summary>
	public void SetPOItemFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POItemColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.ItemType field.
	/// </summary>
	public ColumnValue GetItemTypeValue()
	{
		return this.GetValue(TableUtils.ItemTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.ItemType field.
	/// </summary>
	public Byte GetItemTypeFieldValue()
	{
		return this.GetValue(TableUtils.ItemTypeColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ItemType field.
	/// </summary>
	public void SetItemTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ItemTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ItemType field.
	/// </summary>
	public void SetItemTypeFieldValue(string val)
	{
		this.SetString(val, TableUtils.ItemTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ItemType field.
	/// </summary>
	public void SetItemTypeFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ItemTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ItemType field.
	/// </summary>
	public void SetItemTypeFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ItemTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ItemType field.
	/// </summary>
	public void SetItemTypeFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ItemTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public ColumnValue GetMatlGroupValue()
	{
		return this.GetValue(TableUtils.MatlGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public Byte GetMatlGroupFieldValue()
	{
		return this.GetValue(TableUtils.MatlGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public void SetMatlGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.MatlGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public void SetMatlGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.MatlGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public void SetMatlGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MatlGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public void SetMatlGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MatlGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public void SetMatlGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MatlGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Material field.
	/// </summary>
	public ColumnValue GetMaterialValue()
	{
		return this.GetValue(TableUtils.MaterialColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Material field.
	/// </summary>
	public string GetMaterialFieldValue()
	{
		return this.GetValue(TableUtils.MaterialColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Material field.
	/// </summary>
	public void SetMaterialFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.MaterialColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Material field.
	/// </summary>
	public void SetMaterialFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.MaterialColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.VendMatId field.
	/// </summary>
	public ColumnValue GetVendMatIdValue()
	{
		return this.GetValue(TableUtils.VendMatIdColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.VendMatId field.
	/// </summary>
	public string GetVendMatIdFieldValue()
	{
		return this.GetValue(TableUtils.VendMatIdColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.VendMatId field.
	/// </summary>
	public void SetVendMatIdFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VendMatIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.VendMatId field.
	/// </summary>
	public void SetVendMatIdFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VendMatIdColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Description field.
	/// </summary>
	public ColumnValue GetDescriptionValue()
	{
		return this.GetValue(TableUtils.DescriptionColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Description field.
	/// </summary>
	public string GetDescriptionFieldValue()
	{
		return this.GetValue(TableUtils.DescriptionColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Description field.
	/// </summary>
	public void SetDescriptionFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.DescriptionColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Description field.
	/// </summary>
	public void SetDescriptionFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.DescriptionColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.UM field.
	/// </summary>
	public ColumnValue GetUMValue()
	{
		return this.GetValue(TableUtils.UMColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.UM field.
	/// </summary>
	public string GetUMFieldValue()
	{
		return this.GetValue(TableUtils.UMColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.UM field.
	/// </summary>
	public void SetUMFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.UMColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.UM field.
	/// </summary>
	public void SetUMFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.UMColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RecvYN field.
	/// </summary>
	public ColumnValue GetRecvYNValue()
	{
		return this.GetValue(TableUtils.RecvYNColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RecvYN field.
	/// </summary>
	public string GetRecvYNFieldValue()
	{
		return this.GetValue(TableUtils.RecvYNColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvYN field.
	/// </summary>
	public void SetRecvYNFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.RecvYNColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvYN field.
	/// </summary>
	public void SetRecvYNFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RecvYNColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PostToCo field.
	/// </summary>
	public ColumnValue GetPostToCoValue()
	{
		return this.GetValue(TableUtils.PostToCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PostToCo field.
	/// </summary>
	public Byte GetPostToCoFieldValue()
	{
		return this.GetValue(TableUtils.PostToCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostToCo field.
	/// </summary>
	public void SetPostToCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PostToCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostToCo field.
	/// </summary>
	public void SetPostToCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.PostToCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostToCo field.
	/// </summary>
	public void SetPostToCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PostToCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostToCo field.
	/// </summary>
	public void SetPostToCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PostToCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostToCo field.
	/// </summary>
	public void SetPostToCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PostToCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Loc field.
	/// </summary>
	public ColumnValue GetLocValue()
	{
		return this.GetValue(TableUtils.LocColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Loc field.
	/// </summary>
	public string GetLocFieldValue()
	{
		return this.GetValue(TableUtils.LocColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Loc field.
	/// </summary>
	public void SetLocFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.LocColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Loc field.
	/// </summary>
	public void SetLocFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.LocColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Job field.
	/// </summary>
	public ColumnValue GetJobValue()
	{
		return this.GetValue(TableUtils.JobColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Job field.
	/// </summary>
	public string GetJobFieldValue()
	{
		return this.GetValue(TableUtils.JobColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Job field.
	/// </summary>
	public void SetJobFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JobColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Job field.
	/// </summary>
	public void SetJobFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JobColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PhaseGroup field.
	/// </summary>
	public ColumnValue GetPhaseGroupValue()
	{
		return this.GetValue(TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PhaseGroup field.
	/// </summary>
	public Byte GetPhaseGroupFieldValue()
	{
		return this.GetValue(TableUtils.PhaseGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Phase field.
	/// </summary>
	public ColumnValue GetPhaseValue()
	{
		return this.GetValue(TableUtils.PhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Phase field.
	/// </summary>
	public string GetPhaseFieldValue()
	{
		return this.GetValue(TableUtils.PhaseColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Phase field.
	/// </summary>
	public void SetPhaseFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Phase field.
	/// </summary>
	public void SetPhaseFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.JCCType field.
	/// </summary>
	public ColumnValue GetJCCTypeValue()
	{
		return this.GetValue(TableUtils.JCCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.JCCType field.
	/// </summary>
	public Byte GetJCCTypeFieldValue()
	{
		return this.GetValue(TableUtils.JCCTypeColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCType field.
	/// </summary>
	public void SetJCCTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JCCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCType field.
	/// </summary>
	public void SetJCCTypeFieldValue(string val)
	{
		this.SetString(val, TableUtils.JCCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCType field.
	/// </summary>
	public void SetJCCTypeFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCType field.
	/// </summary>
	public void SetJCCTypeFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCType field.
	/// </summary>
	public void SetJCCTypeFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Equip field.
	/// </summary>
	public ColumnValue GetEquipValue()
	{
		return this.GetValue(TableUtils.EquipColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Equip field.
	/// </summary>
	public string GetEquipFieldValue()
	{
		return this.GetValue(TableUtils.EquipColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Equip field.
	/// </summary>
	public void SetEquipFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.EquipColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Equip field.
	/// </summary>
	public void SetEquipFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EquipColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CompType field.
	/// </summary>
	public ColumnValue GetCompTypeValue()
	{
		return this.GetValue(TableUtils.CompTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CompType field.
	/// </summary>
	public string GetCompTypeFieldValue()
	{
		return this.GetValue(TableUtils.CompTypeColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CompType field.
	/// </summary>
	public void SetCompTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CompTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CompType field.
	/// </summary>
	public void SetCompTypeFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CompTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Component field.
	/// </summary>
	public ColumnValue GetComponentValue()
	{
		return this.GetValue(TableUtils.ComponentColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Component field.
	/// </summary>
	public string GetComponentFieldValue()
	{
		return this.GetValue(TableUtils.ComponentColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Component field.
	/// </summary>
	public void SetComponentFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ComponentColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Component field.
	/// </summary>
	public void SetComponentFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ComponentColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.EMGroup field.
	/// </summary>
	public ColumnValue GetEMGroupValue()
	{
		return this.GetValue(TableUtils.EMGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.EMGroup field.
	/// </summary>
	public Byte GetEMGroupFieldValue()
	{
		return this.GetValue(TableUtils.EMGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMGroup field.
	/// </summary>
	public void SetEMGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.EMGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMGroup field.
	/// </summary>
	public void SetEMGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.EMGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMGroup field.
	/// </summary>
	public void SetEMGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMGroup field.
	/// </summary>
	public void SetEMGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMGroup field.
	/// </summary>
	public void SetEMGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CostCode field.
	/// </summary>
	public ColumnValue GetCostCodeValue()
	{
		return this.GetValue(TableUtils.CostCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CostCode field.
	/// </summary>
	public string GetCostCodeFieldValue()
	{
		return this.GetValue(TableUtils.CostCodeColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CostCode field.
	/// </summary>
	public void SetCostCodeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CostCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CostCode field.
	/// </summary>
	public void SetCostCodeFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CostCodeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.EMCType field.
	/// </summary>
	public ColumnValue GetEMCTypeValue()
	{
		return this.GetValue(TableUtils.EMCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.EMCType field.
	/// </summary>
	public Byte GetEMCTypeFieldValue()
	{
		return this.GetValue(TableUtils.EMCTypeColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCType field.
	/// </summary>
	public void SetEMCTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.EMCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCType field.
	/// </summary>
	public void SetEMCTypeFieldValue(string val)
	{
		this.SetString(val, TableUtils.EMCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCType field.
	/// </summary>
	public void SetEMCTypeFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCType field.
	/// </summary>
	public void SetEMCTypeFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMCTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCType field.
	/// </summary>
	public void SetEMCTypeFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMCTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.WO field.
	/// </summary>
	public ColumnValue GetWOValue()
	{
		return this.GetValue(TableUtils.WOColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.WO field.
	/// </summary>
	public string GetWOFieldValue()
	{
		return this.GetValue(TableUtils.WOColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WO field.
	/// </summary>
	public void SetWOFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.WOColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WO field.
	/// </summary>
	public void SetWOFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.WOColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.WOItem field.
	/// </summary>
	public ColumnValue GetWOItemValue()
	{
		return this.GetValue(TableUtils.WOItemColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.WOItem field.
	/// </summary>
	public Int16 GetWOItemFieldValue()
	{
		return this.GetValue(TableUtils.WOItemColumn).ToInt16();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WOItem field.
	/// </summary>
	public void SetWOItemFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.WOItemColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WOItem field.
	/// </summary>
	public void SetWOItemFieldValue(string val)
	{
		this.SetString(val, TableUtils.WOItemColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WOItem field.
	/// </summary>
	public void SetWOItemFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.WOItemColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WOItem field.
	/// </summary>
	public void SetWOItemFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.WOItemColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WOItem field.
	/// </summary>
	public void SetWOItemFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.WOItemColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.GLCo field.
	/// </summary>
	public ColumnValue GetGLCoValue()
	{
		return this.GetValue(TableUtils.GLCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.GLCo field.
	/// </summary>
	public Byte GetGLCoFieldValue()
	{
		return this.GetValue(TableUtils.GLCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLCo field.
	/// </summary>
	public void SetGLCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.GLCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLCo field.
	/// </summary>
	public void SetGLCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.GLCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLCo field.
	/// </summary>
	public void SetGLCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GLCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLCo field.
	/// </summary>
	public void SetGLCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GLCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLCo field.
	/// </summary>
	public void SetGLCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GLCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.GLAcct field.
	/// </summary>
	public ColumnValue GetGLAcctValue()
	{
		return this.GetValue(TableUtils.GLAcctColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.GLAcct field.
	/// </summary>
	public string GetGLAcctFieldValue()
	{
		return this.GetValue(TableUtils.GLAcctColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLAcct field.
	/// </summary>
	public void SetGLAcctFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.GLAcctColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLAcct field.
	/// </summary>
	public void SetGLAcctFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GLAcctColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.ReqDate field.
	/// </summary>
	public ColumnValue GetReqDateValue()
	{
		return this.GetValue(TableUtils.ReqDateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.ReqDate field.
	/// </summary>
	public DateTime GetReqDateFieldValue()
	{
		return this.GetValue(TableUtils.ReqDateColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ReqDate field.
	/// </summary>
	public void SetReqDateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ReqDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ReqDate field.
	/// </summary>
	public void SetReqDateFieldValue(string val)
	{
		this.SetString(val, TableUtils.ReqDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ReqDate field.
	/// </summary>
	public void SetReqDateFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ReqDateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public ColumnValue GetTaxGroupValue()
	{
		return this.GetValue(TableUtils.TaxGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public Byte GetTaxGroupFieldValue()
	{
		return this.GetValue(TableUtils.TaxGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public void SetTaxGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.TaxGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public void SetTaxGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.TaxGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public void SetTaxGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public void SetTaxGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public void SetTaxGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TaxCode field.
	/// </summary>
	public ColumnValue GetTaxCodeValue()
	{
		return this.GetValue(TableUtils.TaxCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TaxCode field.
	/// </summary>
	public string GetTaxCodeFieldValue()
	{
		return this.GetValue(TableUtils.TaxCodeColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxCode field.
	/// </summary>
	public void SetTaxCodeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.TaxCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxCode field.
	/// </summary>
	public void SetTaxCodeFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxCodeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TaxType field.
	/// </summary>
	public ColumnValue GetTaxTypeValue()
	{
		return this.GetValue(TableUtils.TaxTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TaxType field.
	/// </summary>
	public Byte GetTaxTypeFieldValue()
	{
		return this.GetValue(TableUtils.TaxTypeColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxType field.
	/// </summary>
	public void SetTaxTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.TaxTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxType field.
	/// </summary>
	public void SetTaxTypeFieldValue(string val)
	{
		this.SetString(val, TableUtils.TaxTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxType field.
	/// </summary>
	public void SetTaxTypeFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxType field.
	/// </summary>
	public void SetTaxTypeFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxType field.
	/// </summary>
	public void SetTaxTypeFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public ColumnValue GetOrigUnitsValue()
	{
		return this.GetValue(TableUtils.OrigUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public Decimal GetOrigUnitsFieldValue()
	{
		return this.GetValue(TableUtils.OrigUnitsColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public void SetOrigUnitsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.OrigUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public void SetOrigUnitsFieldValue(string val)
	{
		this.SetString(val, TableUtils.OrigUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public void SetOrigUnitsFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public void SetOrigUnitsFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public void SetOrigUnitsFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigUnitsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public ColumnValue GetOrigUnitCostValue()
	{
		return this.GetValue(TableUtils.OrigUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public Decimal GetOrigUnitCostFieldValue()
	{
		return this.GetValue(TableUtils.OrigUnitCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public void SetOrigUnitCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.OrigUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public void SetOrigUnitCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.OrigUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public void SetOrigUnitCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public void SetOrigUnitCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public void SetOrigUnitCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigUnitCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigECM field.
	/// </summary>
	public ColumnValue GetOrigECMValue()
	{
		return this.GetValue(TableUtils.OrigECMColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigECM field.
	/// </summary>
	public string GetOrigECMFieldValue()
	{
		return this.GetValue(TableUtils.OrigECMColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigECM field.
	/// </summary>
	public void SetOrigECMFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.OrigECMColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigECM field.
	/// </summary>
	public void SetOrigECMFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigECMColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigCost field.
	/// </summary>
	public ColumnValue GetOrigCostValue()
	{
		return this.GetValue(TableUtils.OrigCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigCost field.
	/// </summary>
	public Decimal GetOrigCostFieldValue()
	{
		return this.GetValue(TableUtils.OrigCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigCost field.
	/// </summary>
	public void SetOrigCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.OrigCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigCost field.
	/// </summary>
	public void SetOrigCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.OrigCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigCost field.
	/// </summary>
	public void SetOrigCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigCost field.
	/// </summary>
	public void SetOrigCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigCost field.
	/// </summary>
	public void SetOrigCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigTax field.
	/// </summary>
	public ColumnValue GetOrigTaxValue()
	{
		return this.GetValue(TableUtils.OrigTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.OrigTax field.
	/// </summary>
	public Decimal GetOrigTaxFieldValue()
	{
		return this.GetValue(TableUtils.OrigTaxColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigTax field.
	/// </summary>
	public void SetOrigTaxFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.OrigTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigTax field.
	/// </summary>
	public void SetOrigTaxFieldValue(string val)
	{
		this.SetString(val, TableUtils.OrigTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigTax field.
	/// </summary>
	public void SetOrigTaxFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigTax field.
	/// </summary>
	public void SetOrigTaxFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigTax field.
	/// </summary>
	public void SetOrigTaxFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.OrigTaxColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurUnits field.
	/// </summary>
	public ColumnValue GetCurUnitsValue()
	{
		return this.GetValue(TableUtils.CurUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurUnits field.
	/// </summary>
	public Decimal GetCurUnitsFieldValue()
	{
		return this.GetValue(TableUtils.CurUnitsColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnits field.
	/// </summary>
	public void SetCurUnitsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CurUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnits field.
	/// </summary>
	public void SetCurUnitsFieldValue(string val)
	{
		this.SetString(val, TableUtils.CurUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnits field.
	/// </summary>
	public void SetCurUnitsFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnits field.
	/// </summary>
	public void SetCurUnitsFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnits field.
	/// </summary>
	public void SetCurUnitsFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurUnitsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public ColumnValue GetCurUnitCostValue()
	{
		return this.GetValue(TableUtils.CurUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public Decimal GetCurUnitCostFieldValue()
	{
		return this.GetValue(TableUtils.CurUnitCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public void SetCurUnitCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CurUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public void SetCurUnitCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.CurUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public void SetCurUnitCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public void SetCurUnitCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurUnitCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public void SetCurUnitCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurUnitCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurECM field.
	/// </summary>
	public ColumnValue GetCurECMValue()
	{
		return this.GetValue(TableUtils.CurECMColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurECM field.
	/// </summary>
	public string GetCurECMFieldValue()
	{
		return this.GetValue(TableUtils.CurECMColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurECM field.
	/// </summary>
	public void SetCurECMFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CurECMColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurECM field.
	/// </summary>
	public void SetCurECMFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurECMColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurCost field.
	/// </summary>
	public ColumnValue GetCurCostValue()
	{
		return this.GetValue(TableUtils.CurCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurCost field.
	/// </summary>
	public Decimal GetCurCostFieldValue()
	{
		return this.GetValue(TableUtils.CurCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurCost field.
	/// </summary>
	public void SetCurCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CurCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurCost field.
	/// </summary>
	public void SetCurCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.CurCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurCost field.
	/// </summary>
	public void SetCurCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurCost field.
	/// </summary>
	public void SetCurCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurCost field.
	/// </summary>
	public void SetCurCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurTax field.
	/// </summary>
	public ColumnValue GetCurTaxValue()
	{
		return this.GetValue(TableUtils.CurTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.CurTax field.
	/// </summary>
	public Decimal GetCurTaxFieldValue()
	{
		return this.GetValue(TableUtils.CurTaxColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurTax field.
	/// </summary>
	public void SetCurTaxFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CurTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurTax field.
	/// </summary>
	public void SetCurTaxFieldValue(string val)
	{
		this.SetString(val, TableUtils.CurTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurTax field.
	/// </summary>
	public void SetCurTaxFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurTax field.
	/// </summary>
	public void SetCurTaxFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurTax field.
	/// </summary>
	public void SetCurTaxFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CurTaxColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public ColumnValue GetRecvdUnitsValue()
	{
		return this.GetValue(TableUtils.RecvdUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public Decimal GetRecvdUnitsFieldValue()
	{
		return this.GetValue(TableUtils.RecvdUnitsColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public void SetRecvdUnitsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.RecvdUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public void SetRecvdUnitsFieldValue(string val)
	{
		this.SetString(val, TableUtils.RecvdUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public void SetRecvdUnitsFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RecvdUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public void SetRecvdUnitsFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RecvdUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public void SetRecvdUnitsFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RecvdUnitsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public ColumnValue GetRecvdCostValue()
	{
		return this.GetValue(TableUtils.RecvdCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public Decimal GetRecvdCostFieldValue()
	{
		return this.GetValue(TableUtils.RecvdCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public void SetRecvdCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.RecvdCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public void SetRecvdCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.RecvdCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public void SetRecvdCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RecvdCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public void SetRecvdCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RecvdCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public void SetRecvdCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RecvdCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.BOUnits field.
	/// </summary>
	public ColumnValue GetBOUnitsValue()
	{
		return this.GetValue(TableUtils.BOUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.BOUnits field.
	/// </summary>
	public Decimal GetBOUnitsFieldValue()
	{
		return this.GetValue(TableUtils.BOUnitsColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOUnits field.
	/// </summary>
	public void SetBOUnitsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.BOUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOUnits field.
	/// </summary>
	public void SetBOUnitsFieldValue(string val)
	{
		this.SetString(val, TableUtils.BOUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOUnits field.
	/// </summary>
	public void SetBOUnitsFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.BOUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOUnits field.
	/// </summary>
	public void SetBOUnitsFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.BOUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOUnits field.
	/// </summary>
	public void SetBOUnitsFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.BOUnitsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.BOCost field.
	/// </summary>
	public ColumnValue GetBOCostValue()
	{
		return this.GetValue(TableUtils.BOCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.BOCost field.
	/// </summary>
	public Decimal GetBOCostFieldValue()
	{
		return this.GetValue(TableUtils.BOCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOCost field.
	/// </summary>
	public void SetBOCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.BOCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOCost field.
	/// </summary>
	public void SetBOCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.BOCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOCost field.
	/// </summary>
	public void SetBOCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.BOCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOCost field.
	/// </summary>
	public void SetBOCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.BOCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOCost field.
	/// </summary>
	public void SetBOCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.BOCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public ColumnValue GetTotalUnitsValue()
	{
		return this.GetValue(TableUtils.TotalUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public Decimal GetTotalUnitsFieldValue()
	{
		return this.GetValue(TableUtils.TotalUnitsColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public void SetTotalUnitsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.TotalUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public void SetTotalUnitsFieldValue(string val)
	{
		this.SetString(val, TableUtils.TotalUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public void SetTotalUnitsFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public void SetTotalUnitsFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public void SetTotalUnitsFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalUnitsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TotalCost field.
	/// </summary>
	public ColumnValue GetTotalCostValue()
	{
		return this.GetValue(TableUtils.TotalCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TotalCost field.
	/// </summary>
	public Decimal GetTotalCostFieldValue()
	{
		return this.GetValue(TableUtils.TotalCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalCost field.
	/// </summary>
	public void SetTotalCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.TotalCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalCost field.
	/// </summary>
	public void SetTotalCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.TotalCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalCost field.
	/// </summary>
	public void SetTotalCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalCost field.
	/// </summary>
	public void SetTotalCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalCost field.
	/// </summary>
	public void SetTotalCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TotalTax field.
	/// </summary>
	public ColumnValue GetTotalTaxValue()
	{
		return this.GetValue(TableUtils.TotalTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TotalTax field.
	/// </summary>
	public Decimal GetTotalTaxFieldValue()
	{
		return this.GetValue(TableUtils.TotalTaxColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalTax field.
	/// </summary>
	public void SetTotalTaxFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.TotalTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalTax field.
	/// </summary>
	public void SetTotalTaxFieldValue(string val)
	{
		this.SetString(val, TableUtils.TotalTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalTax field.
	/// </summary>
	public void SetTotalTaxFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalTax field.
	/// </summary>
	public void SetTotalTaxFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalTax field.
	/// </summary>
	public void SetTotalTaxFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TotalTaxColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InvUnits field.
	/// </summary>
	public ColumnValue GetInvUnitsValue()
	{
		return this.GetValue(TableUtils.InvUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InvUnits field.
	/// </summary>
	public Decimal GetInvUnitsFieldValue()
	{
		return this.GetValue(TableUtils.InvUnitsColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvUnits field.
	/// </summary>
	public void SetInvUnitsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.InvUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvUnits field.
	/// </summary>
	public void SetInvUnitsFieldValue(string val)
	{
		this.SetString(val, TableUtils.InvUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvUnits field.
	/// </summary>
	public void SetInvUnitsFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvUnits field.
	/// </summary>
	public void SetInvUnitsFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvUnits field.
	/// </summary>
	public void SetInvUnitsFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvUnitsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InvCost field.
	/// </summary>
	public ColumnValue GetInvCostValue()
	{
		return this.GetValue(TableUtils.InvCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InvCost field.
	/// </summary>
	public Decimal GetInvCostFieldValue()
	{
		return this.GetValue(TableUtils.InvCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvCost field.
	/// </summary>
	public void SetInvCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.InvCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvCost field.
	/// </summary>
	public void SetInvCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.InvCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvCost field.
	/// </summary>
	public void SetInvCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvCost field.
	/// </summary>
	public void SetInvCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvCost field.
	/// </summary>
	public void SetInvCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InvTax field.
	/// </summary>
	public ColumnValue GetInvTaxValue()
	{
		return this.GetValue(TableUtils.InvTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InvTax field.
	/// </summary>
	public Decimal GetInvTaxFieldValue()
	{
		return this.GetValue(TableUtils.InvTaxColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvTax field.
	/// </summary>
	public void SetInvTaxFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.InvTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvTax field.
	/// </summary>
	public void SetInvTaxFieldValue(string val)
	{
		this.SetString(val, TableUtils.InvTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvTax field.
	/// </summary>
	public void SetInvTaxFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvTax field.
	/// </summary>
	public void SetInvTaxFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvTax field.
	/// </summary>
	public void SetInvTaxFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvTaxColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RemUnits field.
	/// </summary>
	public ColumnValue GetRemUnitsValue()
	{
		return this.GetValue(TableUtils.RemUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RemUnits field.
	/// </summary>
	public Decimal GetRemUnitsFieldValue()
	{
		return this.GetValue(TableUtils.RemUnitsColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemUnits field.
	/// </summary>
	public void SetRemUnitsFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.RemUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemUnits field.
	/// </summary>
	public void SetRemUnitsFieldValue(string val)
	{
		this.SetString(val, TableUtils.RemUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemUnits field.
	/// </summary>
	public void SetRemUnitsFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemUnits field.
	/// </summary>
	public void SetRemUnitsFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemUnitsColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemUnits field.
	/// </summary>
	public void SetRemUnitsFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemUnitsColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RemCost field.
	/// </summary>
	public ColumnValue GetRemCostValue()
	{
		return this.GetValue(TableUtils.RemCostColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RemCost field.
	/// </summary>
	public Decimal GetRemCostFieldValue()
	{
		return this.GetValue(TableUtils.RemCostColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemCost field.
	/// </summary>
	public void SetRemCostFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.RemCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemCost field.
	/// </summary>
	public void SetRemCostFieldValue(string val)
	{
		this.SetString(val, TableUtils.RemCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemCost field.
	/// </summary>
	public void SetRemCostFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemCost field.
	/// </summary>
	public void SetRemCostFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemCostColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemCost field.
	/// </summary>
	public void SetRemCostFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemCostColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RemTax field.
	/// </summary>
	public ColumnValue GetRemTaxValue()
	{
		return this.GetValue(TableUtils.RemTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RemTax field.
	/// </summary>
	public Decimal GetRemTaxFieldValue()
	{
		return this.GetValue(TableUtils.RemTaxColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemTax field.
	/// </summary>
	public void SetRemTaxFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.RemTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemTax field.
	/// </summary>
	public void SetRemTaxFieldValue(string val)
	{
		this.SetString(val, TableUtils.RemTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemTax field.
	/// </summary>
	public void SetRemTaxFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemTax field.
	/// </summary>
	public void SetRemTaxFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemTax field.
	/// </summary>
	public void SetRemTaxFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RemTaxColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InUseMth field.
	/// </summary>
	public ColumnValue GetInUseMthValue()
	{
		return this.GetValue(TableUtils.InUseMthColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InUseMth field.
	/// </summary>
	public DateTime GetInUseMthFieldValue()
	{
		return this.GetValue(TableUtils.InUseMthColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseMth field.
	/// </summary>
	public void SetInUseMthFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.InUseMthColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseMth field.
	/// </summary>
	public void SetInUseMthFieldValue(string val)
	{
		this.SetString(val, TableUtils.InUseMthColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseMth field.
	/// </summary>
	public void SetInUseMthFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InUseMthColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InUseBatchId field.
	/// </summary>
	public ColumnValue GetInUseBatchIdValue()
	{
		return this.GetValue(TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InUseBatchId field.
	/// </summary>
	public Int32 GetInUseBatchIdFieldValue()
	{
		return this.GetValue(TableUtils.InUseBatchIdColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(string val)
	{
		this.SetString(val, TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InUseBatchIdColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseBatchId field.
	/// </summary>
	public void SetInUseBatchIdFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InUseBatchIdColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PostedDate field.
	/// </summary>
	public ColumnValue GetPostedDateValue()
	{
		return this.GetValue(TableUtils.PostedDateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PostedDate field.
	/// </summary>
	public DateTime GetPostedDateFieldValue()
	{
		return this.GetValue(TableUtils.PostedDateColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostedDate field.
	/// </summary>
	public void SetPostedDateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PostedDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostedDate field.
	/// </summary>
	public void SetPostedDateFieldValue(string val)
	{
		this.SetString(val, TableUtils.PostedDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostedDate field.
	/// </summary>
	public void SetPostedDateFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PostedDateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Notes field.
	/// </summary>
	public ColumnValue GetNotesValue()
	{
		return this.GetValue(TableUtils.NotesColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Notes field.
	/// </summary>
	public string GetNotesFieldValue()
	{
		return this.GetValue(TableUtils.NotesColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Notes field.
	/// </summary>
	public void SetNotesFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.NotesColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Notes field.
	/// </summary>
	public void SetNotesFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.NotesColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RequisitionNum field.
	/// </summary>
	public ColumnValue GetRequisitionNumValue()
	{
		return this.GetValue(TableUtils.RequisitionNumColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.RequisitionNum field.
	/// </summary>
	public string GetRequisitionNumFieldValue()
	{
		return this.GetValue(TableUtils.RequisitionNumColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RequisitionNum field.
	/// </summary>
	public void SetRequisitionNumFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.RequisitionNumColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RequisitionNum field.
	/// </summary>
	public void SetRequisitionNumFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.RequisitionNumColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.AddedMth field.
	/// </summary>
	public ColumnValue GetAddedMthValue()
	{
		return this.GetValue(TableUtils.AddedMthColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.AddedMth field.
	/// </summary>
	public DateTime GetAddedMthFieldValue()
	{
		return this.GetValue(TableUtils.AddedMthColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedMth field.
	/// </summary>
	public void SetAddedMthFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AddedMthColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedMth field.
	/// </summary>
	public void SetAddedMthFieldValue(string val)
	{
		this.SetString(val, TableUtils.AddedMthColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedMth field.
	/// </summary>
	public void SetAddedMthFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddedMthColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.AddedBatchID field.
	/// </summary>
	public ColumnValue GetAddedBatchIDValue()
	{
		return this.GetValue(TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.AddedBatchID field.
	/// </summary>
	public Int32 GetAddedBatchIDFieldValue()
	{
		return this.GetValue(TableUtils.AddedBatchIDColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddedBatchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedBatchID field.
	/// </summary>
	public void SetAddedBatchIDFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.AddedBatchIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.UniqueAttchID field.
	/// </summary>
	public ColumnValue GetUniqueAttchIDValue()
	{
		return this.GetValue(TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.UniqueAttchID field.
	/// </summary>
	public System.Guid GetUniqueAttchIDFieldValue()
	{
		return this.GetValue(TableUtils.UniqueAttchIDColumn).ToGuid();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(System.Guid val)
	{
		ColumnValue cv = new ColumnValue(val, System.TypeCode.Object);
		this.SetValue(cv, TableUtils.UniqueAttchIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PayCategory field.
	/// </summary>
	public ColumnValue GetPayCategoryValue()
	{
		return this.GetValue(TableUtils.PayCategoryColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PayCategory field.
	/// </summary>
	public Int32 GetPayCategoryFieldValue()
	{
		return this.GetValue(TableUtils.PayCategoryColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayCategory field.
	/// </summary>
	public void SetPayCategoryFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PayCategoryColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayCategory field.
	/// </summary>
	public void SetPayCategoryFieldValue(string val)
	{
		this.SetString(val, TableUtils.PayCategoryColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayCategory field.
	/// </summary>
	public void SetPayCategoryFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayCategoryColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayCategory field.
	/// </summary>
	public void SetPayCategoryFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayCategoryColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayCategory field.
	/// </summary>
	public void SetPayCategoryFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayCategoryColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PayType field.
	/// </summary>
	public ColumnValue GetPayTypeValue()
	{
		return this.GetValue(TableUtils.PayTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.PayType field.
	/// </summary>
	public Byte GetPayTypeFieldValue()
	{
		return this.GetValue(TableUtils.PayTypeColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayType field.
	/// </summary>
	public void SetPayTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PayTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayType field.
	/// </summary>
	public void SetPayTypeFieldValue(string val)
	{
		this.SetString(val, TableUtils.PayTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayType field.
	/// </summary>
	public void SetPayTypeFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayType field.
	/// </summary>
	public void SetPayTypeFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayType field.
	/// </summary>
	public void SetPayTypeFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PayTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.KeyID field.
	/// </summary>
	public ColumnValue GetKeyIDValue()
	{
		return this.GetValue(TableUtils.KeyIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.KeyID field.
	/// </summary>
	public Int64 GetKeyIDFieldValue()
	{
		return this.GetValue(TableUtils.KeyIDColumn).ToInt64();
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.INCo field.
	/// </summary>
	public ColumnValue GetINCoValue()
	{
		return this.GetValue(TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.INCo field.
	/// </summary>
	public Byte GetINCoFieldValue()
	{
		return this.GetValue(TableUtils.INCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.INCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.INCo field.
	/// </summary>
	public void SetINCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.INCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.EMCo field.
	/// </summary>
	public ColumnValue GetEMCoValue()
	{
		return this.GetValue(TableUtils.EMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.EMCo field.
	/// </summary>
	public Byte GetEMCoFieldValue()
	{
		return this.GetValue(TableUtils.EMCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCo field.
	/// </summary>
	public void SetEMCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.EMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCo field.
	/// </summary>
	public void SetEMCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.EMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCo field.
	/// </summary>
	public void SetEMCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCo field.
	/// </summary>
	public void SetEMCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCo field.
	/// </summary>
	public void SetEMCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.EMCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.JCCo field.
	/// </summary>
	public ColumnValue GetJCCoValue()
	{
		return this.GetValue(TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.JCCo field.
	/// </summary>
	public Byte GetJCCoFieldValue()
	{
		return this.GetValue(TableUtils.JCCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCo field.
	/// </summary>
	public void SetJCCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public ColumnValue GetJCCmtdTaxValue()
	{
		return this.GetValue(TableUtils.JCCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public Decimal GetJCCmtdTaxFieldValue()
	{
		return this.GetValue(TableUtils.JCCmtdTaxColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public void SetJCCmtdTaxFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JCCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public void SetJCCmtdTaxFieldValue(string val)
	{
		this.SetString(val, TableUtils.JCCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public void SetJCCmtdTaxFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public void SetJCCmtdTaxFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public void SetJCCmtdTaxFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCCmtdTaxColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Supplier field.
	/// </summary>
	public ColumnValue GetSupplierValue()
	{
		return this.GetValue(TableUtils.SupplierColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.Supplier field.
	/// </summary>
	public Int32 GetSupplierFieldValue()
	{
		return this.GetValue(TableUtils.SupplierColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Supplier field.
	/// </summary>
	public void SetSupplierFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SupplierColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Supplier field.
	/// </summary>
	public void SetSupplierFieldValue(string val)
	{
		this.SetString(val, TableUtils.SupplierColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Supplier field.
	/// </summary>
	public void SetSupplierFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SupplierColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Supplier field.
	/// </summary>
	public void SetSupplierFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SupplierColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Supplier field.
	/// </summary>
	public void SetSupplierFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SupplierColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public ColumnValue GetSupplierGroupValue()
	{
		return this.GetValue(TableUtils.SupplierGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public Byte GetSupplierGroupFieldValue()
	{
		return this.GetValue(TableUtils.SupplierGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public void SetSupplierGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SupplierGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public void SetSupplierGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.SupplierGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public void SetSupplierGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SupplierGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public void SetSupplierGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SupplierGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public void SetSupplierGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SupplierGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public ColumnValue GetJCRemCmtdTaxValue()
	{
		return this.GetValue(TableUtils.JCRemCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public Decimal GetJCRemCmtdTaxFieldValue()
	{
		return this.GetValue(TableUtils.JCRemCmtdTaxColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public void SetJCRemCmtdTaxFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JCRemCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public void SetJCRemCmtdTaxFieldValue(string val)
	{
		this.SetString(val, TableUtils.JCRemCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public void SetJCRemCmtdTaxFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCRemCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public void SetJCRemCmtdTaxFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCRemCmtdTaxColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public void SetJCRemCmtdTaxFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JCRemCmtdTaxColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TaxRate field.
	/// </summary>
	public ColumnValue GetTaxRateValue()
	{
		return this.GetValue(TableUtils.TaxRateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.TaxRate field.
	/// </summary>
	public Decimal GetTaxRateFieldValue()
	{
		return this.GetValue(TableUtils.TaxRateColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxRate field.
	/// </summary>
	public void SetTaxRateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.TaxRateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxRate field.
	/// </summary>
	public void SetTaxRateFieldValue(string val)
	{
		this.SetString(val, TableUtils.TaxRateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxRate field.
	/// </summary>
	public void SetTaxRateFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxRateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxRate field.
	/// </summary>
	public void SetTaxRateFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxRateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxRate field.
	/// </summary>
	public void SetTaxRateFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.TaxRateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.GSTRate field.
	/// </summary>
	public ColumnValue GetGSTRateValue()
	{
		return this.GetValue(TableUtils.GSTRateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.GSTRate field.
	/// </summary>
	public Decimal GetGSTRateFieldValue()
	{
		return this.GetValue(TableUtils.GSTRateColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GSTRate field.
	/// </summary>
	public void SetGSTRateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.GSTRateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GSTRate field.
	/// </summary>
	public void SetGSTRateFieldValue(string val)
	{
		this.SetString(val, TableUtils.GSTRateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GSTRate field.
	/// </summary>
	public void SetGSTRateFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GSTRateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GSTRate field.
	/// </summary>
	public void SetGSTRateFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GSTRateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GSTRate field.
	/// </summary>
	public void SetGSTRateFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.GSTRateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMCo field.
	/// </summary>
	public ColumnValue GetSMCoValue()
	{
		return this.GetValue(TableUtils.SMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMCo field.
	/// </summary>
	public Byte GetSMCoFieldValue()
	{
		return this.GetValue(TableUtils.SMCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMCo field.
	/// </summary>
	public void SetSMCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMCo field.
	/// </summary>
	public void SetSMCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.SMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMCo field.
	/// </summary>
	public void SetSMCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMCo field.
	/// </summary>
	public void SetSMCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMCo field.
	/// </summary>
	public void SetSMCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public ColumnValue GetSMWorkOrderValue()
	{
		return this.GetValue(TableUtils.SMWorkOrderColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public Int32 GetSMWorkOrderFieldValue()
	{
		return this.GetValue(TableUtils.SMWorkOrderColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public void SetSMWorkOrderFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SMWorkOrderColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public void SetSMWorkOrderFieldValue(string val)
	{
		this.SetString(val, TableUtils.SMWorkOrderColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public void SetSMWorkOrderFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMWorkOrderColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public void SetSMWorkOrderFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMWorkOrderColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public void SetSMWorkOrderFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMWorkOrderColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public ColumnValue GetInvMiscAmtValue()
	{
		return this.GetValue(TableUtils.InvMiscAmtColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public Decimal GetInvMiscAmtFieldValue()
	{
		return this.GetValue(TableUtils.InvMiscAmtColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public void SetInvMiscAmtFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.InvMiscAmtColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public void SetInvMiscAmtFieldValue(string val)
	{
		this.SetString(val, TableUtils.InvMiscAmtColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public void SetInvMiscAmtFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvMiscAmtColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public void SetInvMiscAmtFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvMiscAmtColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public void SetInvMiscAmtFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.InvMiscAmtColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMScope field.
	/// </summary>
	public ColumnValue GetSMScopeValue()
	{
		return this.GetValue(TableUtils.SMScopeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMScope field.
	/// </summary>
	public Int32 GetSMScopeFieldValue()
	{
		return this.GetValue(TableUtils.SMScopeColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMScope field.
	/// </summary>
	public void SetSMScopeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SMScopeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMScope field.
	/// </summary>
	public void SetSMScopeFieldValue(string val)
	{
		this.SetString(val, TableUtils.SMScopeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMScope field.
	/// </summary>
	public void SetSMScopeFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMScopeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMScope field.
	/// </summary>
	public void SetSMScopeFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMScopeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMScope field.
	/// </summary>
	public void SetSMScopeFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMScopeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public ColumnValue GetSMPhaseGroupValue()
	{
		return this.GetValue(TableUtils.SMPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public Byte GetSMPhaseGroupFieldValue()
	{
		return this.GetValue(TableUtils.SMPhaseGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public void SetSMPhaseGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SMPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public void SetSMPhaseGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.SMPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public void SetSMPhaseGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public void SetSMPhaseGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public void SetSMPhaseGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMPhaseGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMPhase field.
	/// </summary>
	public ColumnValue GetSMPhaseValue()
	{
		return this.GetValue(TableUtils.SMPhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMPhase field.
	/// </summary>
	public string GetSMPhaseFieldValue()
	{
		return this.GetValue(TableUtils.SMPhaseColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhase field.
	/// </summary>
	public void SetSMPhaseFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SMPhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhase field.
	/// </summary>
	public void SetSMPhaseFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMPhaseColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public ColumnValue GetSMJCCostTypeValue()
	{
		return this.GetValue(TableUtils.SMJCCostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public Byte GetSMJCCostTypeFieldValue()
	{
		return this.GetValue(TableUtils.SMJCCostTypeColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public void SetSMJCCostTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.SMJCCostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public void SetSMJCCostTypeFieldValue(string val)
	{
		this.SetString(val, TableUtils.SMJCCostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public void SetSMJCCostTypeFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMJCCostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public void SetSMJCCostTypeFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMJCCostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public void SetSMJCCostTypeFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.SMJCCostTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udSource field.
	/// </summary>
	public ColumnValue GetudSourceValue()
	{
		return this.GetValue(TableUtils.udSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udSource field.
	/// </summary>
	public string GetudSourceFieldValue()
	{
		return this.GetValue(TableUtils.udSourceColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udSource field.
	/// </summary>
	public void SetudSourceFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udSource field.
	/// </summary>
	public void SetudSourceFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udSourceColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udConv field.
	/// </summary>
	public ColumnValue GetudConvValue()
	{
		return this.GetValue(TableUtils.udConvColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udConv field.
	/// </summary>
	public string GetudConvFieldValue()
	{
		return this.GetValue(TableUtils.udConvColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udConv field.
	/// </summary>
	public void SetudConvFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udConvColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udConv field.
	/// </summary>
	public void SetudConvFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udConvColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udCGCTable field.
	/// </summary>
	public ColumnValue GetudCGCTableValue()
	{
		return this.GetValue(TableUtils.udCGCTableColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udCGCTable field.
	/// </summary>
	public string GetudCGCTableFieldValue()
	{
		return this.GetValue(TableUtils.udCGCTableColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTable field.
	/// </summary>
	public void SetudCGCTableFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCGCTableColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTable field.
	/// </summary>
	public void SetudCGCTableFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udCGCTableID field.
	/// </summary>
	public ColumnValue GetudCGCTableIDValue()
	{
		return this.GetValue(TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udCGCTableID field.
	/// </summary>
	public Decimal GetudCGCTableIDFieldValue()
	{
		return this.GetValue(TableUtils.udCGCTableIDColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udOnDate field.
	/// </summary>
	public ColumnValue GetudOnDateValue()
	{
		return this.GetValue(TableUtils.udOnDateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udOnDate field.
	/// </summary>
	public DateTime GetudOnDateFieldValue()
	{
		return this.GetValue(TableUtils.udOnDateColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udOnDate field.
	/// </summary>
	public void SetudOnDateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udOnDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udOnDate field.
	/// </summary>
	public void SetudOnDateFieldValue(string val)
	{
		this.SetString(val, TableUtils.udOnDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udOnDate field.
	/// </summary>
	public void SetudOnDateFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udOnDateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udPlnOffDate field.
	/// </summary>
	public ColumnValue GetudPlnOffDateValue()
	{
		return this.GetValue(TableUtils.udPlnOffDateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udPlnOffDate field.
	/// </summary>
	public DateTime GetudPlnOffDateFieldValue()
	{
		return this.GetValue(TableUtils.udPlnOffDateColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udPlnOffDate field.
	/// </summary>
	public void SetudPlnOffDateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udPlnOffDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udPlnOffDate field.
	/// </summary>
	public void SetudPlnOffDateFieldValue(string val)
	{
		this.SetString(val, TableUtils.udPlnOffDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udPlnOffDate field.
	/// </summary>
	public void SetudPlnOffDateFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udPlnOffDateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udActOffDate field.
	/// </summary>
	public ColumnValue GetudActOffDateValue()
	{
		return this.GetValue(TableUtils.udActOffDateColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udActOffDate field.
	/// </summary>
	public DateTime GetudActOffDateFieldValue()
	{
		return this.GetValue(TableUtils.udActOffDateColumn).ToDateTime();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udActOffDate field.
	/// </summary>
	public void SetudActOffDateFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udActOffDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udActOffDate field.
	/// </summary>
	public void SetudActOffDateFieldValue(string val)
	{
		this.SetString(val, TableUtils.udActOffDateColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udActOffDate field.
	/// </summary>
	public void SetudActOffDateFieldValue(DateTime val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udActOffDateColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udRentalNum field.
	/// </summary>
	public ColumnValue GetudRentalNumValue()
	{
		return this.GetValue(TableUtils.udRentalNumColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's POIT_.udRentalNum field.
	/// </summary>
	public string GetudRentalNumFieldValue()
	{
		return this.GetValue(TableUtils.udRentalNumColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udRentalNum field.
	/// </summary>
	public void SetudRentalNumFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udRentalNumColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udRentalNum field.
	/// </summary>
	public void SetudRentalNumFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udRentalNumColumn);
	}


#endregion

#region "Convenience methods to get field names"

	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.POCo field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POCo field.
	/// </summary>
	public string POCoDefault
	{
		get
		{
			return TableUtils.POCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.PO field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PO field.
	/// </summary>
	public string PODefault
	{
		get
		{
			return TableUtils.POColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.POItem field.
	/// </summary>
	public Int16 POItem
	{
		get
		{
			return this.GetValue(TableUtils.POItemColumn).ToInt16();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.POItemColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool POItemSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.POItemColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.POItem field.
	/// </summary>
	public string POItemDefault
	{
		get
		{
			return TableUtils.POItemColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.ItemType field.
	/// </summary>
	public Byte ItemType
	{
		get
		{
			return this.GetValue(TableUtils.ItemTypeColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ItemTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ItemTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ItemTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ItemType field.
	/// </summary>
	public string ItemTypeDefault
	{
		get
		{
			return TableUtils.ItemTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public Byte MatlGroup
	{
		get
		{
			return this.GetValue(TableUtils.MatlGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.MatlGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool MatlGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.MatlGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.MatlGroup field.
	/// </summary>
	public string MatlGroupDefault
	{
		get
		{
			return TableUtils.MatlGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Material field.
	/// </summary>
	public string Material
	{
		get
		{
			return this.GetValue(TableUtils.MaterialColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.MaterialColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool MaterialSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.MaterialColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Material field.
	/// </summary>
	public string MaterialDefault
	{
		get
		{
			return TableUtils.MaterialColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.VendMatId field.
	/// </summary>
	public string VendMatId
	{
		get
		{
			return this.GetValue(TableUtils.VendMatIdColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VendMatIdColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VendMatIdSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VendMatIdColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.VendMatId field.
	/// </summary>
	public string VendMatIdDefault
	{
		get
		{
			return TableUtils.VendMatIdColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Description field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Description field.
	/// </summary>
	public string DescriptionDefault
	{
		get
		{
			return TableUtils.DescriptionColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.UM field.
	/// </summary>
	public string UM
	{
		get
		{
			return this.GetValue(TableUtils.UMColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.UMColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool UMSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.UMColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.UM field.
	/// </summary>
	public string UMDefault
	{
		get
		{
			return TableUtils.UMColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.RecvYN field.
	/// </summary>
	public string RecvYN
	{
		get
		{
			return this.GetValue(TableUtils.RecvYNColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.RecvYNColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool RecvYNSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.RecvYNColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvYN field.
	/// </summary>
	public string RecvYNDefault
	{
		get
		{
			return TableUtils.RecvYNColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.PostToCo field.
	/// </summary>
	public Byte PostToCo
	{
		get
		{
			return this.GetValue(TableUtils.PostToCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PostToCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PostToCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PostToCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostToCo field.
	/// </summary>
	public string PostToCoDefault
	{
		get
		{
			return TableUtils.PostToCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Loc field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Loc field.
	/// </summary>
	public string LocDefault
	{
		get
		{
			return TableUtils.LocColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Job field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Job field.
	/// </summary>
	public string JobDefault
	{
		get
		{
			return TableUtils.JobColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.PhaseGroup field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PhaseGroup field.
	/// </summary>
	public string PhaseGroupDefault
	{
		get
		{
			return TableUtils.PhaseGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Phase field.
	/// </summary>
	public string Phase
	{
		get
		{
			return this.GetValue(TableUtils.PhaseColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PhaseColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PhaseSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PhaseColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Phase field.
	/// </summary>
	public string PhaseDefault
	{
		get
		{
			return TableUtils.PhaseColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.JCCType field.
	/// </summary>
	public Byte JCCType
	{
		get
		{
			return this.GetValue(TableUtils.JCCTypeColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.JCCTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool JCCTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.JCCTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCType field.
	/// </summary>
	public string JCCTypeDefault
	{
		get
		{
			return TableUtils.JCCTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Equip field.
	/// </summary>
	public string Equip
	{
		get
		{
			return this.GetValue(TableUtils.EquipColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.EquipColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool EquipSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.EquipColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Equip field.
	/// </summary>
	public string EquipDefault
	{
		get
		{
			return TableUtils.EquipColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.CompType field.
	/// </summary>
	public string CompType
	{
		get
		{
			return this.GetValue(TableUtils.CompTypeColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CompTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CompTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CompTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CompType field.
	/// </summary>
	public string CompTypeDefault
	{
		get
		{
			return TableUtils.CompTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Component field.
	/// </summary>
	public string Component
	{
		get
		{
			return this.GetValue(TableUtils.ComponentColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ComponentColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ComponentSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ComponentColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Component field.
	/// </summary>
	public string ComponentDefault
	{
		get
		{
			return TableUtils.ComponentColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.EMGroup field.
	/// </summary>
	public Byte EMGroup
	{
		get
		{
			return this.GetValue(TableUtils.EMGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.EMGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool EMGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.EMGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMGroup field.
	/// </summary>
	public string EMGroupDefault
	{
		get
		{
			return TableUtils.EMGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.CostCode field.
	/// </summary>
	public string CostCode
	{
		get
		{
			return this.GetValue(TableUtils.CostCodeColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CostCodeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CostCodeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CostCodeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CostCode field.
	/// </summary>
	public string CostCodeDefault
	{
		get
		{
			return TableUtils.CostCodeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.EMCType field.
	/// </summary>
	public Byte EMCType
	{
		get
		{
			return this.GetValue(TableUtils.EMCTypeColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.EMCTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool EMCTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.EMCTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCType field.
	/// </summary>
	public string EMCTypeDefault
	{
		get
		{
			return TableUtils.EMCTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.WO field.
	/// </summary>
	public string WO
	{
		get
		{
			return this.GetValue(TableUtils.WOColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.WOColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool WOSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.WOColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WO field.
	/// </summary>
	public string WODefault
	{
		get
		{
			return TableUtils.WOColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.WOItem field.
	/// </summary>
	public Int16 WOItem
	{
		get
		{
			return this.GetValue(TableUtils.WOItemColumn).ToInt16();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.WOItemColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool WOItemSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.WOItemColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.WOItem field.
	/// </summary>
	public string WOItemDefault
	{
		get
		{
			return TableUtils.WOItemColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.GLCo field.
	/// </summary>
	public Byte GLCo
	{
		get
		{
			return this.GetValue(TableUtils.GLCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.GLCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool GLCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.GLCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLCo field.
	/// </summary>
	public string GLCoDefault
	{
		get
		{
			return TableUtils.GLCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.GLAcct field.
	/// </summary>
	public string GLAcct
	{
		get
		{
			return this.GetValue(TableUtils.GLAcctColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.GLAcctColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool GLAcctSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.GLAcctColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GLAcct field.
	/// </summary>
	public string GLAcctDefault
	{
		get
		{
			return TableUtils.GLAcctColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.ReqDate field.
	/// </summary>
	public DateTime ReqDate
	{
		get
		{
			return this.GetValue(TableUtils.ReqDateColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ReqDateColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ReqDateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ReqDateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.ReqDate field.
	/// </summary>
	public string ReqDateDefault
	{
		get
		{
			return TableUtils.ReqDateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public Byte TaxGroup
	{
		get
		{
			return this.GetValue(TableUtils.TaxGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.TaxGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool TaxGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.TaxGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxGroup field.
	/// </summary>
	public string TaxGroupDefault
	{
		get
		{
			return TableUtils.TaxGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.TaxCode field.
	/// </summary>
	public string TaxCode
	{
		get
		{
			return this.GetValue(TableUtils.TaxCodeColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.TaxCodeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool TaxCodeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.TaxCodeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxCode field.
	/// </summary>
	public string TaxCodeDefault
	{
		get
		{
			return TableUtils.TaxCodeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.TaxType field.
	/// </summary>
	public Byte TaxType
	{
		get
		{
			return this.GetValue(TableUtils.TaxTypeColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.TaxTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool TaxTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.TaxTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxType field.
	/// </summary>
	public string TaxTypeDefault
	{
		get
		{
			return TableUtils.TaxTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public Decimal OrigUnits
	{
		get
		{
			return this.GetValue(TableUtils.OrigUnitsColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.OrigUnitsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool OrigUnitsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.OrigUnitsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnits field.
	/// </summary>
	public string OrigUnitsDefault
	{
		get
		{
			return TableUtils.OrigUnitsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public Decimal OrigUnitCost
	{
		get
		{
			return this.GetValue(TableUtils.OrigUnitCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.OrigUnitCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool OrigUnitCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.OrigUnitCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigUnitCost field.
	/// </summary>
	public string OrigUnitCostDefault
	{
		get
		{
			return TableUtils.OrigUnitCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.OrigECM field.
	/// </summary>
	public string OrigECM
	{
		get
		{
			return this.GetValue(TableUtils.OrigECMColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.OrigECMColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool OrigECMSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.OrigECMColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigECM field.
	/// </summary>
	public string OrigECMDefault
	{
		get
		{
			return TableUtils.OrigECMColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.OrigCost field.
	/// </summary>
	public Decimal OrigCost
	{
		get
		{
			return this.GetValue(TableUtils.OrigCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.OrigCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool OrigCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.OrigCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigCost field.
	/// </summary>
	public string OrigCostDefault
	{
		get
		{
			return TableUtils.OrigCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.OrigTax field.
	/// </summary>
	public Decimal OrigTax
	{
		get
		{
			return this.GetValue(TableUtils.OrigTaxColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.OrigTaxColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool OrigTaxSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.OrigTaxColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.OrigTax field.
	/// </summary>
	public string OrigTaxDefault
	{
		get
		{
			return TableUtils.OrigTaxColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.CurUnits field.
	/// </summary>
	public Decimal CurUnits
	{
		get
		{
			return this.GetValue(TableUtils.CurUnitsColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CurUnitsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CurUnitsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CurUnitsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnits field.
	/// </summary>
	public string CurUnitsDefault
	{
		get
		{
			return TableUtils.CurUnitsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public Decimal CurUnitCost
	{
		get
		{
			return this.GetValue(TableUtils.CurUnitCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CurUnitCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CurUnitCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CurUnitCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurUnitCost field.
	/// </summary>
	public string CurUnitCostDefault
	{
		get
		{
			return TableUtils.CurUnitCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.CurECM field.
	/// </summary>
	public string CurECM
	{
		get
		{
			return this.GetValue(TableUtils.CurECMColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CurECMColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CurECMSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CurECMColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurECM field.
	/// </summary>
	public string CurECMDefault
	{
		get
		{
			return TableUtils.CurECMColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.CurCost field.
	/// </summary>
	public Decimal CurCost
	{
		get
		{
			return this.GetValue(TableUtils.CurCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CurCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CurCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CurCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurCost field.
	/// </summary>
	public string CurCostDefault
	{
		get
		{
			return TableUtils.CurCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.CurTax field.
	/// </summary>
	public Decimal CurTax
	{
		get
		{
			return this.GetValue(TableUtils.CurTaxColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CurTaxColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CurTaxSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CurTaxColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.CurTax field.
	/// </summary>
	public string CurTaxDefault
	{
		get
		{
			return TableUtils.CurTaxColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public Decimal RecvdUnits
	{
		get
		{
			return this.GetValue(TableUtils.RecvdUnitsColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.RecvdUnitsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool RecvdUnitsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.RecvdUnitsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdUnits field.
	/// </summary>
	public string RecvdUnitsDefault
	{
		get
		{
			return TableUtils.RecvdUnitsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public Decimal RecvdCost
	{
		get
		{
			return this.GetValue(TableUtils.RecvdCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.RecvdCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool RecvdCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.RecvdCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RecvdCost field.
	/// </summary>
	public string RecvdCostDefault
	{
		get
		{
			return TableUtils.RecvdCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.BOUnits field.
	/// </summary>
	public Decimal BOUnits
	{
		get
		{
			return this.GetValue(TableUtils.BOUnitsColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.BOUnitsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool BOUnitsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.BOUnitsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOUnits field.
	/// </summary>
	public string BOUnitsDefault
	{
		get
		{
			return TableUtils.BOUnitsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.BOCost field.
	/// </summary>
	public Decimal BOCost
	{
		get
		{
			return this.GetValue(TableUtils.BOCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.BOCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool BOCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.BOCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.BOCost field.
	/// </summary>
	public string BOCostDefault
	{
		get
		{
			return TableUtils.BOCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public Decimal TotalUnits
	{
		get
		{
			return this.GetValue(TableUtils.TotalUnitsColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.TotalUnitsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool TotalUnitsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.TotalUnitsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalUnits field.
	/// </summary>
	public string TotalUnitsDefault
	{
		get
		{
			return TableUtils.TotalUnitsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.TotalCost field.
	/// </summary>
	public Decimal TotalCost
	{
		get
		{
			return this.GetValue(TableUtils.TotalCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.TotalCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool TotalCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.TotalCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalCost field.
	/// </summary>
	public string TotalCostDefault
	{
		get
		{
			return TableUtils.TotalCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.TotalTax field.
	/// </summary>
	public Decimal TotalTax
	{
		get
		{
			return this.GetValue(TableUtils.TotalTaxColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.TotalTaxColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool TotalTaxSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.TotalTaxColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TotalTax field.
	/// </summary>
	public string TotalTaxDefault
	{
		get
		{
			return TableUtils.TotalTaxColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.InvUnits field.
	/// </summary>
	public Decimal InvUnits
	{
		get
		{
			return this.GetValue(TableUtils.InvUnitsColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.InvUnitsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool InvUnitsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.InvUnitsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvUnits field.
	/// </summary>
	public string InvUnitsDefault
	{
		get
		{
			return TableUtils.InvUnitsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.InvCost field.
	/// </summary>
	public Decimal InvCost
	{
		get
		{
			return this.GetValue(TableUtils.InvCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.InvCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool InvCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.InvCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvCost field.
	/// </summary>
	public string InvCostDefault
	{
		get
		{
			return TableUtils.InvCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.InvTax field.
	/// </summary>
	public Decimal InvTax
	{
		get
		{
			return this.GetValue(TableUtils.InvTaxColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.InvTaxColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool InvTaxSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.InvTaxColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvTax field.
	/// </summary>
	public string InvTaxDefault
	{
		get
		{
			return TableUtils.InvTaxColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.RemUnits field.
	/// </summary>
	public Decimal RemUnits
	{
		get
		{
			return this.GetValue(TableUtils.RemUnitsColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.RemUnitsColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool RemUnitsSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.RemUnitsColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemUnits field.
	/// </summary>
	public string RemUnitsDefault
	{
		get
		{
			return TableUtils.RemUnitsColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.RemCost field.
	/// </summary>
	public Decimal RemCost
	{
		get
		{
			return this.GetValue(TableUtils.RemCostColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.RemCostColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool RemCostSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.RemCostColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemCost field.
	/// </summary>
	public string RemCostDefault
	{
		get
		{
			return TableUtils.RemCostColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.RemTax field.
	/// </summary>
	public Decimal RemTax
	{
		get
		{
			return this.GetValue(TableUtils.RemTaxColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.RemTaxColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool RemTaxSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.RemTaxColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RemTax field.
	/// </summary>
	public string RemTaxDefault
	{
		get
		{
			return TableUtils.RemTaxColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.InUseMth field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseMth field.
	/// </summary>
	public string InUseMthDefault
	{
		get
		{
			return TableUtils.InUseMthColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.InUseBatchId field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InUseBatchId field.
	/// </summary>
	public string InUseBatchIdDefault
	{
		get
		{
			return TableUtils.InUseBatchIdColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.PostedDate field.
	/// </summary>
	public DateTime PostedDate
	{
		get
		{
			return this.GetValue(TableUtils.PostedDateColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PostedDateColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PostedDateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PostedDateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PostedDate field.
	/// </summary>
	public string PostedDateDefault
	{
		get
		{
			return TableUtils.PostedDateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Notes field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Notes field.
	/// </summary>
	public string NotesDefault
	{
		get
		{
			return TableUtils.NotesColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.RequisitionNum field.
	/// </summary>
	public string RequisitionNum
	{
		get
		{
			return this.GetValue(TableUtils.RequisitionNumColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.RequisitionNumColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool RequisitionNumSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.RequisitionNumColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.RequisitionNum field.
	/// </summary>
	public string RequisitionNumDefault
	{
		get
		{
			return TableUtils.RequisitionNumColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.AddedMth field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedMth field.
	/// </summary>
	public string AddedMthDefault
	{
		get
		{
			return TableUtils.AddedMthColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.AddedBatchID field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.AddedBatchID field.
	/// </summary>
	public string AddedBatchIDDefault
	{
		get
		{
			return TableUtils.AddedBatchIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.UniqueAttchID field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.UniqueAttchID field.
	/// </summary>
	public string UniqueAttchIDDefault
	{
		get
		{
			return TableUtils.UniqueAttchIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.PayCategory field.
	/// </summary>
	public Int32 PayCategory
	{
		get
		{
			return this.GetValue(TableUtils.PayCategoryColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PayCategoryColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PayCategorySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PayCategoryColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayCategory field.
	/// </summary>
	public string PayCategoryDefault
	{
		get
		{
			return TableUtils.PayCategoryColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.PayType field.
	/// </summary>
	public Byte PayType
	{
		get
		{
			return this.GetValue(TableUtils.PayTypeColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PayTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PayTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PayTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.PayType field.
	/// </summary>
	public string PayTypeDefault
	{
		get
		{
			return TableUtils.PayTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.KeyID field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.KeyID field.
	/// </summary>
	public string KeyIDDefault
	{
		get
		{
			return TableUtils.KeyIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.INCo field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.INCo field.
	/// </summary>
	public string INCoDefault
	{
		get
		{
			return TableUtils.INCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.EMCo field.
	/// </summary>
	public Byte EMCo
	{
		get
		{
			return this.GetValue(TableUtils.EMCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.EMCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool EMCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.EMCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.EMCo field.
	/// </summary>
	public string EMCoDefault
	{
		get
		{
			return TableUtils.EMCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.JCCo field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCo field.
	/// </summary>
	public string JCCoDefault
	{
		get
		{
			return TableUtils.JCCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public Decimal JCCmtdTax
	{
		get
		{
			return this.GetValue(TableUtils.JCCmtdTaxColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.JCCmtdTaxColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool JCCmtdTaxSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.JCCmtdTaxColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCCmtdTax field.
	/// </summary>
	public string JCCmtdTaxDefault
	{
		get
		{
			return TableUtils.JCCmtdTaxColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.Supplier field.
	/// </summary>
	public Int32 Supplier
	{
		get
		{
			return this.GetValue(TableUtils.SupplierColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SupplierColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SupplierSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SupplierColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.Supplier field.
	/// </summary>
	public string SupplierDefault
	{
		get
		{
			return TableUtils.SupplierColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public Byte SupplierGroup
	{
		get
		{
			return this.GetValue(TableUtils.SupplierGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SupplierGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SupplierGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SupplierGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SupplierGroup field.
	/// </summary>
	public string SupplierGroupDefault
	{
		get
		{
			return TableUtils.SupplierGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public Decimal JCRemCmtdTax
	{
		get
		{
			return this.GetValue(TableUtils.JCRemCmtdTaxColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.JCRemCmtdTaxColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool JCRemCmtdTaxSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.JCRemCmtdTaxColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.JCRemCmtdTax field.
	/// </summary>
	public string JCRemCmtdTaxDefault
	{
		get
		{
			return TableUtils.JCRemCmtdTaxColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.TaxRate field.
	/// </summary>
	public Decimal TaxRate
	{
		get
		{
			return this.GetValue(TableUtils.TaxRateColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.TaxRateColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool TaxRateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.TaxRateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.TaxRate field.
	/// </summary>
	public string TaxRateDefault
	{
		get
		{
			return TableUtils.TaxRateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.GSTRate field.
	/// </summary>
	public Decimal GSTRate
	{
		get
		{
			return this.GetValue(TableUtils.GSTRateColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.GSTRateColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool GSTRateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.GSTRateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.GSTRate field.
	/// </summary>
	public string GSTRateDefault
	{
		get
		{
			return TableUtils.GSTRateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.SMCo field.
	/// </summary>
	public Byte SMCo
	{
		get
		{
			return this.GetValue(TableUtils.SMCoColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SMCoColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SMCoSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SMCoColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMCo field.
	/// </summary>
	public string SMCoDefault
	{
		get
		{
			return TableUtils.SMCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public Int32 SMWorkOrder
	{
		get
		{
			return this.GetValue(TableUtils.SMWorkOrderColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SMWorkOrderColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SMWorkOrderSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SMWorkOrderColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMWorkOrder field.
	/// </summary>
	public string SMWorkOrderDefault
	{
		get
		{
			return TableUtils.SMWorkOrderColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public Decimal InvMiscAmt
	{
		get
		{
			return this.GetValue(TableUtils.InvMiscAmtColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.InvMiscAmtColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool InvMiscAmtSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.InvMiscAmtColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.InvMiscAmt field.
	/// </summary>
	public string InvMiscAmtDefault
	{
		get
		{
			return TableUtils.InvMiscAmtColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.SMScope field.
	/// </summary>
	public Int32 SMScope
	{
		get
		{
			return this.GetValue(TableUtils.SMScopeColumn).ToInt32();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SMScopeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SMScopeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SMScopeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMScope field.
	/// </summary>
	public string SMScopeDefault
	{
		get
		{
			return TableUtils.SMScopeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public Byte SMPhaseGroup
	{
		get
		{
			return this.GetValue(TableUtils.SMPhaseGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SMPhaseGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SMPhaseGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SMPhaseGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhaseGroup field.
	/// </summary>
	public string SMPhaseGroupDefault
	{
		get
		{
			return TableUtils.SMPhaseGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.SMPhase field.
	/// </summary>
	public string SMPhase
	{
		get
		{
			return this.GetValue(TableUtils.SMPhaseColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SMPhaseColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SMPhaseSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SMPhaseColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMPhase field.
	/// </summary>
	public string SMPhaseDefault
	{
		get
		{
			return TableUtils.SMPhaseColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public Byte SMJCCostType
	{
		get
		{
			return this.GetValue(TableUtils.SMJCCostTypeColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.SMJCCostTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool SMJCCostTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.SMJCCostTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.SMJCCostType field.
	/// </summary>
	public string SMJCCostTypeDefault
	{
		get
		{
			return TableUtils.SMJCCostTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.udSource field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udSource field.
	/// </summary>
	public string udSourceDefault
	{
		get
		{
			return TableUtils.udSourceColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.udConv field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udConv field.
	/// </summary>
	public string udConvDefault
	{
		get
		{
			return TableUtils.udConvColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.udCGCTable field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTable field.
	/// </summary>
	public string udCGCTableDefault
	{
		get
		{
			return TableUtils.udCGCTableColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.udCGCTableID field.
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
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udCGCTableID field.
	/// </summary>
	public string udCGCTableIDDefault
	{
		get
		{
			return TableUtils.udCGCTableIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.udOnDate field.
	/// </summary>
	public DateTime udOnDate
	{
		get
		{
			return this.GetValue(TableUtils.udOnDateColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udOnDateColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udOnDateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udOnDateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udOnDate field.
	/// </summary>
	public string udOnDateDefault
	{
		get
		{
			return TableUtils.udOnDateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.udPlnOffDate field.
	/// </summary>
	public DateTime udPlnOffDate
	{
		get
		{
			return this.GetValue(TableUtils.udPlnOffDateColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udPlnOffDateColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udPlnOffDateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udPlnOffDateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udPlnOffDate field.
	/// </summary>
	public string udPlnOffDateDefault
	{
		get
		{
			return TableUtils.udPlnOffDateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.udActOffDate field.
	/// </summary>
	public DateTime udActOffDate
	{
		get
		{
			return this.GetValue(TableUtils.udActOffDateColumn).ToDateTime();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udActOffDateColumn);
			
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udActOffDateSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udActOffDateColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udActOffDate field.
	/// </summary>
	public string udActOffDateDefault
	{
		get
		{
			return TableUtils.udActOffDateColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's POIT_.udRentalNum field.
	/// </summary>
	public string udRentalNum
	{
		get
		{
			return this.GetValue(TableUtils.udRentalNumColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udRentalNumColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udRentalNumSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udRentalNumColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's POIT_.udRentalNum field.
	/// </summary>
	public string udRentalNumDefault
	{
		get
		{
			return TableUtils.udRentalNumColumn.DefaultValue;
		}
	}


#endregion

}

}
