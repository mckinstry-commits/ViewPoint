// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDPhaseMasterCostTypesRecord.cs

using System;
using System.Collections;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace VPLookup.Business
{

/// <summary>
/// The generated superclass for the <see cref="MvwISDPhaseMasterCostTypesRecord"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="MvwISDPhaseMasterCostTypesView"></see> class.
/// </remarks>
/// <seealso cref="MvwISDPhaseMasterCostTypesView"></seealso>
/// <seealso cref="MvwISDPhaseMasterCostTypesRecord"></seealso>
public class BaseMvwISDPhaseMasterCostTypesRecord : PrimaryKeyRecord
{

	public readonly static MvwISDPhaseMasterCostTypesView TableUtils = MvwISDPhaseMasterCostTypesView.Instance;

	// Constructors
 
	protected BaseMvwISDPhaseMasterCostTypesRecord() : base(TableUtils)
	{
		this.InsertingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.InsertingRecordEventHandler(this.MvwISDPhaseMasterCostTypesRecord_InsertingRecord); 
		this.UpdatingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.UpdatingRecordEventHandler(this.MvwISDPhaseMasterCostTypesRecord_UpdatingRecord); 
		this.ReadRecord +=
            new BaseClasses.IRecordWithTriggerEvents.ReadRecordEventHandler(this.MvwISDPhaseMasterCostTypesRecord_ReadRecord); 
	}

	protected BaseMvwISDPhaseMasterCostTypesRecord(PrimaryKeyRecord record) : base(record, TableUtils)
	{
	}
	
	
	//Audit Trail methods
	
	//Evaluates Initialize when->Reading record formulas specified at the data access layer
    protected virtual void MvwISDPhaseMasterCostTypesRecord_ReadRecord(Object sender,System.EventArgs e)
    {
        //Apply Initialize->Reading record formula only if validation is successful.
                MvwISDPhaseMasterCostTypesRecord MvwISDPhaseMasterCostTypesRec = (MvwISDPhaseMasterCostTypesRecord)sender;
        if(MvwISDPhaseMasterCostTypesRec != null && !MvwISDPhaseMasterCostTypesRec.IsReadOnly ){
                }
    
    }
        
	//Evaluates Initialize when->Inserting formulas specified at the data access layer
    protected virtual void MvwISDPhaseMasterCostTypesRecord_InsertingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Inserting formula only if validation is successful.
                MvwISDPhaseMasterCostTypesRecord MvwISDPhaseMasterCostTypesRec = (MvwISDPhaseMasterCostTypesRecord)sender;
        Validate_Inserting();
        if(MvwISDPhaseMasterCostTypesRec != null && !MvwISDPhaseMasterCostTypesRec.IsReadOnly ){
                }
    
    }
    
    //Evaluates Initialize when->Updating formulas specified at the data access layer
    protected virtual void MvwISDPhaseMasterCostTypesRecord_UpdatingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Updating formula only if validation is successful.
                MvwISDPhaseMasterCostTypesRecord MvwISDPhaseMasterCostTypesRec = (MvwISDPhaseMasterCostTypesRecord)sender;
        Validate_Updating();
        if(MvwISDPhaseMasterCostTypesRec != null && !MvwISDPhaseMasterCostTypesRec.IsReadOnly ){
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
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
	/// </summary>
	public ColumnValue GetPhaseGroupValue()
	{
		return this.GetValue(TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
	/// </summary>
	public Byte GetPhaseGroupFieldValue()
	{
		return this.GetValue(TableUtils.PhaseGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.Phase field.
	/// </summary>
	public ColumnValue GetPhaseValue()
	{
		return this.GetValue(TableUtils.PhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.Phase field.
	/// </summary>
	public string GetPhaseFieldValue()
	{
		return this.GetValue(TableUtils.PhaseColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.Phase field.
	/// </summary>
	public void SetPhaseFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.Phase field.
	/// </summary>
	public void SetPhaseFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public ColumnValue GetCostTypeValue()
	{
		return this.GetValue(TableUtils.CostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public Byte GetCostTypeFieldValue()
	{
		return this.GetValue(TableUtils.CostTypeColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public void SetCostTypeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public void SetCostTypeFieldValue(string val)
	{
		this.SetString(val, TableUtils.CostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public void SetCostTypeFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public void SetCostTypeFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CostTypeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public void SetCostTypeFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CostTypeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.BillFlag field.
	/// </summary>
	public ColumnValue GetBillFlagValue()
	{
		return this.GetValue(TableUtils.BillFlagColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.BillFlag field.
	/// </summary>
	public string GetBillFlagFieldValue()
	{
		return this.GetValue(TableUtils.BillFlagColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.BillFlag field.
	/// </summary>
	public void SetBillFlagFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.BillFlagColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.BillFlag field.
	/// </summary>
	public void SetBillFlagFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.BillFlagColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.UM field.
	/// </summary>
	public ColumnValue GetUMValue()
	{
		return this.GetValue(TableUtils.UMColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.UM field.
	/// </summary>
	public string GetUMFieldValue()
	{
		return this.GetValue(TableUtils.UMColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.UM field.
	/// </summary>
	public void SetUMFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.UMColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.UM field.
	/// </summary>
	public void SetUMFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.UMColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.ItemUnitFlag field.
	/// </summary>
	public ColumnValue GetItemUnitFlagValue()
	{
		return this.GetValue(TableUtils.ItemUnitFlagColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.ItemUnitFlag field.
	/// </summary>
	public string GetItemUnitFlagFieldValue()
	{
		return this.GetValue(TableUtils.ItemUnitFlagColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.ItemUnitFlag field.
	/// </summary>
	public void SetItemUnitFlagFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ItemUnitFlagColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.ItemUnitFlag field.
	/// </summary>
	public void SetItemUnitFlagFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ItemUnitFlagColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseUnitFlag field.
	/// </summary>
	public ColumnValue GetPhaseUnitFlagValue()
	{
		return this.GetValue(TableUtils.PhaseUnitFlagColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseUnitFlag field.
	/// </summary>
	public string GetPhaseUnitFlagFieldValue()
	{
		return this.GetValue(TableUtils.PhaseUnitFlagColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseUnitFlag field.
	/// </summary>
	public void SetPhaseUnitFlagFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseUnitFlagColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseUnitFlag field.
	/// </summary>
	public void SetPhaseUnitFlagFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseUnitFlagColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udSource field.
	/// </summary>
	public ColumnValue GetudSourceValue()
	{
		return this.GetValue(TableUtils.udSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udSource field.
	/// </summary>
	public string GetudSourceFieldValue()
	{
		return this.GetValue(TableUtils.udSourceColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udSource field.
	/// </summary>
	public void SetudSourceFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udSource field.
	/// </summary>
	public void SetudSourceFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udSourceColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udConv field.
	/// </summary>
	public ColumnValue GetudConvValue()
	{
		return this.GetValue(TableUtils.udConvColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udConv field.
	/// </summary>
	public string GetudConvFieldValue()
	{
		return this.GetValue(TableUtils.udConvColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udConv field.
	/// </summary>
	public void SetudConvFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udConvColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udConv field.
	/// </summary>
	public void SetudConvFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udConvColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTable field.
	/// </summary>
	public ColumnValue GetudCGCTableValue()
	{
		return this.GetValue(TableUtils.udCGCTableColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTable field.
	/// </summary>
	public string GetudCGCTableFieldValue()
	{
		return this.GetValue(TableUtils.udCGCTableColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTable field.
	/// </summary>
	public void SetudCGCTableFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCGCTableColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTable field.
	/// </summary>
	public void SetudCGCTableFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
	/// </summary>
	public ColumnValue GetudCGCTableIDValue()
	{
		return this.GetValue(TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
	/// </summary>
	public Decimal GetudCGCTableIDFieldValue()
	{
		return this.GetValue(TableUtils.udCGCTableIDColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeCode field.
	/// </summary>
	public ColumnValue GetCostTypeCodeValue()
	{
		return this.GetValue(TableUtils.CostTypeCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeCode field.
	/// </summary>
	public string GetCostTypeCodeFieldValue()
	{
		return this.GetValue(TableUtils.CostTypeCodeColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeCode field.
	/// </summary>
	public void SetCostTypeCodeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CostTypeCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeCode field.
	/// </summary>
	public void SetCostTypeCodeFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CostTypeCodeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeDesc field.
	/// </summary>
	public ColumnValue GetCostTypeDescValue()
	{
		return this.GetValue(TableUtils.CostTypeDescColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeDesc field.
	/// </summary>
	public string GetCostTypeDescFieldValue()
	{
		return this.GetValue(TableUtils.CostTypeDescColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeDesc field.
	/// </summary>
	public void SetCostTypeDescFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CostTypeDescColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeDesc field.
	/// </summary>
	public void SetCostTypeDescFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CostTypeDescColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterKey field.
	/// </summary>
	public ColumnValue GetPhaseMasterKeyValue()
	{
		return this.GetValue(TableUtils.PhaseMasterKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterKey field.
	/// </summary>
	public string GetPhaseMasterKeyFieldValue()
	{
		return this.GetValue(TableUtils.PhaseMasterKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterKey field.
	/// </summary>
	public void SetPhaseMasterKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseMasterKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterKey field.
	/// </summary>
	public void SetPhaseMasterKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseMasterKeyColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterCostTypeKey field.
	/// </summary>
	public ColumnValue GetPhaseMasterCostTypeKeyValue()
	{
		return this.GetValue(TableUtils.PhaseMasterCostTypeKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterCostTypeKey field.
	/// </summary>
	public string GetPhaseMasterCostTypeKeyFieldValue()
	{
		return this.GetValue(TableUtils.PhaseMasterCostTypeKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterCostTypeKey field.
	/// </summary>
	public void SetPhaseMasterCostTypeKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseMasterCostTypeKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterCostTypeKey field.
	/// </summary>
	public void SetPhaseMasterCostTypeKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseMasterCostTypeKeyColumn);
	}


#endregion

#region "Convenience methods to get field names"

	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseGroup field.
	/// </summary>
	public string PhaseGroupDefault
	{
		get
		{
			return TableUtils.PhaseGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.Phase field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.Phase field.
	/// </summary>
	public string PhaseDefault
	{
		get
		{
			return TableUtils.PhaseColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public Byte CostType
	{
		get
		{
			return this.GetValue(TableUtils.CostTypeColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CostTypeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CostTypeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CostTypeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostType field.
	/// </summary>
	public string CostTypeDefault
	{
		get
		{
			return TableUtils.CostTypeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.BillFlag field.
	/// </summary>
	public string BillFlag
	{
		get
		{
			return this.GetValue(TableUtils.BillFlagColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.BillFlagColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool BillFlagSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.BillFlagColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.BillFlag field.
	/// </summary>
	public string BillFlagDefault
	{
		get
		{
			return TableUtils.BillFlagColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.UM field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.UM field.
	/// </summary>
	public string UMDefault
	{
		get
		{
			return TableUtils.UMColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.ItemUnitFlag field.
	/// </summary>
	public string ItemUnitFlag
	{
		get
		{
			return this.GetValue(TableUtils.ItemUnitFlagColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ItemUnitFlagColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ItemUnitFlagSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ItemUnitFlagColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.ItemUnitFlag field.
	/// </summary>
	public string ItemUnitFlagDefault
	{
		get
		{
			return TableUtils.ItemUnitFlagColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseUnitFlag field.
	/// </summary>
	public string PhaseUnitFlag
	{
		get
		{
			return this.GetValue(TableUtils.PhaseUnitFlagColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PhaseUnitFlagColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PhaseUnitFlagSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PhaseUnitFlagColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseUnitFlag field.
	/// </summary>
	public string PhaseUnitFlagDefault
	{
		get
		{
			return TableUtils.PhaseUnitFlagColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udSource field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udSource field.
	/// </summary>
	public string udSourceDefault
	{
		get
		{
			return TableUtils.udSourceColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udConv field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udConv field.
	/// </summary>
	public string udConvDefault
	{
		get
		{
			return TableUtils.udConvColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTable field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTable field.
	/// </summary>
	public string udCGCTableDefault
	{
		get
		{
			return TableUtils.udCGCTableColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.udCGCTableID field.
	/// </summary>
	public string udCGCTableIDDefault
	{
		get
		{
			return TableUtils.udCGCTableIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeCode field.
	/// </summary>
	public string CostTypeCode
	{
		get
		{
			return this.GetValue(TableUtils.CostTypeCodeColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CostTypeCodeColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CostTypeCodeSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CostTypeCodeColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeCode field.
	/// </summary>
	public string CostTypeCodeDefault
	{
		get
		{
			return TableUtils.CostTypeCodeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeDesc field.
	/// </summary>
	public string CostTypeDesc
	{
		get
		{
			return this.GetValue(TableUtils.CostTypeDescColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.CostTypeDescColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool CostTypeDescSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.CostTypeDescColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.CostTypeDesc field.
	/// </summary>
	public string CostTypeDescDefault
	{
		get
		{
			return TableUtils.CostTypeDescColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterKey field.
	/// </summary>
	public string PhaseMasterKey
	{
		get
		{
			return this.GetValue(TableUtils.PhaseMasterKeyColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PhaseMasterKeyColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PhaseMasterKeySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PhaseMasterKeyColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterKey field.
	/// </summary>
	public string PhaseMasterKeyDefault
	{
		get
		{
			return TableUtils.PhaseMasterKeyColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterCostTypeKey field.
	/// </summary>
	public string PhaseMasterCostTypeKey
	{
		get
		{
			return this.GetValue(TableUtils.PhaseMasterCostTypeKeyColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PhaseMasterCostTypeKeyColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PhaseMasterCostTypeKeySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PhaseMasterCostTypeKeyColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMasterCostTypes_.PhaseMasterCostTypeKey field.
	/// </summary>
	public string PhaseMasterCostTypeKeyDefault
	{
		get
		{
			return TableUtils.PhaseMasterCostTypeKeyColumn.DefaultValue;
		}
	}


#endregion
}

}
