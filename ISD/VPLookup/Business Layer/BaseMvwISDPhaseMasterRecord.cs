// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDPhaseMasterRecord.cs

using System;
using System.Collections;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace VPLookup.Business
{

/// <summary>
/// The generated superclass for the <see cref="MvwISDPhaseMasterRecord"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="MvwISDPhaseMasterView"></see> class.
/// </remarks>
/// <seealso cref="MvwISDPhaseMasterView"></seealso>
/// <seealso cref="MvwISDPhaseMasterRecord"></seealso>
public class BaseMvwISDPhaseMasterRecord : PrimaryKeyRecord
{

	public readonly static MvwISDPhaseMasterView TableUtils = MvwISDPhaseMasterView.Instance;

	// Constructors
 
	protected BaseMvwISDPhaseMasterRecord() : base(TableUtils)
	{
		this.InsertingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.InsertingRecordEventHandler(this.MvwISDPhaseMasterRecord_InsertingRecord); 
		this.UpdatingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.UpdatingRecordEventHandler(this.MvwISDPhaseMasterRecord_UpdatingRecord); 
		this.ReadRecord +=
            new BaseClasses.IRecordWithTriggerEvents.ReadRecordEventHandler(this.MvwISDPhaseMasterRecord_ReadRecord); 
	}

	protected BaseMvwISDPhaseMasterRecord(PrimaryKeyRecord record) : base(record, TableUtils)
	{
	}
	
	
	//Audit Trail methods
	
	//Evaluates Initialize when->Reading record formulas specified at the data access layer
    protected virtual void MvwISDPhaseMasterRecord_ReadRecord(Object sender,System.EventArgs e)
    {
        //Apply Initialize->Reading record formula only if validation is successful.
                MvwISDPhaseMasterRecord MvwISDPhaseMasterRec = (MvwISDPhaseMasterRecord)sender;
        if(MvwISDPhaseMasterRec != null && !MvwISDPhaseMasterRec.IsReadOnly ){
                }
    
    }
        
	//Evaluates Initialize when->Inserting formulas specified at the data access layer
    protected virtual void MvwISDPhaseMasterRecord_InsertingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Inserting formula only if validation is successful.
                MvwISDPhaseMasterRecord MvwISDPhaseMasterRec = (MvwISDPhaseMasterRecord)sender;
        Validate_Inserting();
        if(MvwISDPhaseMasterRec != null && !MvwISDPhaseMasterRec.IsReadOnly ){
                }
    
    }
    
    //Evaluates Initialize when->Updating formulas specified at the data access layer
    protected virtual void MvwISDPhaseMasterRecord_UpdatingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Updating formula only if validation is successful.
                MvwISDPhaseMasterRecord MvwISDPhaseMasterRec = (MvwISDPhaseMasterRecord)sender;
        Validate_Updating();
        if(MvwISDPhaseMasterRec != null && !MvwISDPhaseMasterRec.IsReadOnly ){
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
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
	/// </summary>
	public ColumnValue GetPhaseGroupValue()
	{
		return this.GetValue(TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
	/// </summary>
	public Byte GetPhaseGroupFieldValue()
	{
		return this.GetValue(TableUtils.PhaseGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
	/// </summary>
	public void SetPhaseGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.Phase field.
	/// </summary>
	public ColumnValue GetPhaseValue()
	{
		return this.GetValue(TableUtils.PhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.Phase field.
	/// </summary>
	public string GetPhaseFieldValue()
	{
		return this.GetValue(TableUtils.PhaseColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Phase field.
	/// </summary>
	public void SetPhaseFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Phase field.
	/// </summary>
	public void SetPhaseFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.Description field.
	/// </summary>
	public ColumnValue GetDescriptionValue()
	{
		return this.GetValue(TableUtils.DescriptionColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.Description field.
	/// </summary>
	public string GetDescriptionFieldValue()
	{
		return this.GetValue(TableUtils.DescriptionColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Description field.
	/// </summary>
	public void SetDescriptionFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.DescriptionColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Description field.
	/// </summary>
	public void SetDescriptionFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.DescriptionColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public ColumnValue GetProjMinPctValue()
	{
		return this.GetValue(TableUtils.ProjMinPctColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public Decimal GetProjMinPctFieldValue()
	{
		return this.GetValue(TableUtils.ProjMinPctColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public void SetProjMinPctFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ProjMinPctColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public void SetProjMinPctFieldValue(string val)
	{
		this.SetString(val, TableUtils.ProjMinPctColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public void SetProjMinPctFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ProjMinPctColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public void SetProjMinPctFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ProjMinPctColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public void SetProjMinPctFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ProjMinPctColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.Notes field.
	/// </summary>
	public ColumnValue GetNotesValue()
	{
		return this.GetValue(TableUtils.NotesColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.Notes field.
	/// </summary>
	public string GetNotesFieldValue()
	{
		return this.GetValue(TableUtils.NotesColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Notes field.
	/// </summary>
	public void SetNotesFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.NotesColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Notes field.
	/// </summary>
	public void SetNotesFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.NotesColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.UniqueAttchID field.
	/// </summary>
	public ColumnValue GetUniqueAttchIDValue()
	{
		return this.GetValue(TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.UniqueAttchID field.
	/// </summary>
	public System.Guid GetUniqueAttchIDFieldValue()
	{
		return this.GetValue(TableUtils.UniqueAttchIDColumn).ToGuid();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.UniqueAttchIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.UniqueAttchID field.
	/// </summary>
	public void SetUniqueAttchIDFieldValue(System.Guid val)
	{
		ColumnValue cv = new ColumnValue(val, System.TypeCode.Object);
		this.SetValue(cv, TableUtils.UniqueAttchIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.KeyID field.
	/// </summary>
	public ColumnValue GetKeyIDValue()
	{
		return this.GetValue(TableUtils.KeyIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.KeyID field.
	/// </summary>
	public Int64 GetKeyIDFieldValue()
	{
		return this.GetValue(TableUtils.KeyIDColumn).ToInt64();
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udSource field.
	/// </summary>
	public ColumnValue GetudSourceValue()
	{
		return this.GetValue(TableUtils.udSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udSource field.
	/// </summary>
	public string GetudSourceFieldValue()
	{
		return this.GetValue(TableUtils.udSourceColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udSource field.
	/// </summary>
	public void SetudSourceFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udSourceColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udSource field.
	/// </summary>
	public void SetudSourceFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udSourceColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udConv field.
	/// </summary>
	public ColumnValue GetudConvValue()
	{
		return this.GetValue(TableUtils.udConvColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udConv field.
	/// </summary>
	public string GetudConvFieldValue()
	{
		return this.GetValue(TableUtils.udConvColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udConv field.
	/// </summary>
	public void SetudConvFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udConvColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udConv field.
	/// </summary>
	public void SetudConvFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udConvColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udCGCTable field.
	/// </summary>
	public ColumnValue GetudCGCTableValue()
	{
		return this.GetValue(TableUtils.udCGCTableColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udCGCTable field.
	/// </summary>
	public string GetudCGCTableFieldValue()
	{
		return this.GetValue(TableUtils.udCGCTableColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTable field.
	/// </summary>
	public void SetudCGCTableFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCGCTableColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTable field.
	/// </summary>
	public void SetudCGCTableFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
	/// </summary>
	public ColumnValue GetudCGCTableIDValue()
	{
		return this.GetValue(TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
	/// </summary>
	public Decimal GetudCGCTableIDFieldValue()
	{
		return this.GetValue(TableUtils.udCGCTableIDColumn).ToDecimal();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(string val)
	{
		this.SetString(val, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
	/// </summary>
	public void SetudCGCTableIDFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCGCTableIDColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udParentPhase field.
	/// </summary>
	public ColumnValue GetudParentPhaseValue()
	{
		return this.GetValue(TableUtils.udParentPhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udParentPhase field.
	/// </summary>
	public string GetudParentPhaseFieldValue()
	{
		return this.GetValue(TableUtils.udParentPhaseColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udParentPhase field.
	/// </summary>
	public void SetudParentPhaseFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udParentPhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udParentPhase field.
	/// </summary>
	public void SetudParentPhaseFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udParentPhaseColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udCSIDiv field.
	/// </summary>
	public ColumnValue GetudCSIDivValue()
	{
		return this.GetValue(TableUtils.udCSIDivColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.udCSIDiv field.
	/// </summary>
	public string GetudCSIDivFieldValue()
	{
		return this.GetValue(TableUtils.udCSIDivColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCSIDiv field.
	/// </summary>
	public void SetudCSIDivFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.udCSIDivColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCSIDiv field.
	/// </summary>
	public void SetudCSIDivFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.udCSIDivColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.PhaseMasterKey field.
	/// </summary>
	public ColumnValue GetPhaseMasterKeyValue()
	{
		return this.GetValue(TableUtils.PhaseMasterKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDPhaseMaster_.PhaseMasterKey field.
	/// </summary>
	public string GetPhaseMasterKeyFieldValue()
	{
		return this.GetValue(TableUtils.PhaseMasterKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseMasterKey field.
	/// </summary>
	public void SetPhaseMasterKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseMasterKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseMasterKey field.
	/// </summary>
	public void SetPhaseMasterKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseMasterKeyColumn);
	}


#endregion

#region "Convenience methods to get field names"

	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseGroup field.
	/// </summary>
	public string PhaseGroupDefault
	{
		get
		{
			return TableUtils.PhaseGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.Phase field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Phase field.
	/// </summary>
	public string PhaseDefault
	{
		get
		{
			return TableUtils.PhaseColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.Description field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Description field.
	/// </summary>
	public string DescriptionDefault
	{
		get
		{
			return TableUtils.DescriptionColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public Decimal ProjMinPct
	{
		get
		{
			return this.GetValue(TableUtils.ProjMinPctColumn).ToDecimal();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ProjMinPctColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ProjMinPctSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ProjMinPctColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.ProjMinPct field.
	/// </summary>
	public string ProjMinPctDefault
	{
		get
		{
			return TableUtils.ProjMinPctColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.Notes field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.Notes field.
	/// </summary>
	public string NotesDefault
	{
		get
		{
			return TableUtils.NotesColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.UniqueAttchID field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.UniqueAttchID field.
	/// </summary>
	public string UniqueAttchIDDefault
	{
		get
		{
			return TableUtils.UniqueAttchIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.KeyID field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.KeyID field.
	/// </summary>
	public string KeyIDDefault
	{
		get
		{
			return TableUtils.KeyIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.udSource field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udSource field.
	/// </summary>
	public string udSourceDefault
	{
		get
		{
			return TableUtils.udSourceColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.udConv field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udConv field.
	/// </summary>
	public string udConvDefault
	{
		get
		{
			return TableUtils.udConvColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.udCGCTable field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTable field.
	/// </summary>
	public string udCGCTableDefault
	{
		get
		{
			return TableUtils.udCGCTableColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCGCTableID field.
	/// </summary>
	public string udCGCTableIDDefault
	{
		get
		{
			return TableUtils.udCGCTableIDColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.udParentPhase field.
	/// </summary>
	public string udParentPhase
	{
		get
		{
			return this.GetValue(TableUtils.udParentPhaseColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udParentPhaseColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udParentPhaseSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udParentPhaseColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udParentPhase field.
	/// </summary>
	public string udParentPhaseDefault
	{
		get
		{
			return TableUtils.udParentPhaseColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.udCSIDiv field.
	/// </summary>
	public string udCSIDiv
	{
		get
		{
			return this.GetValue(TableUtils.udCSIDivColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.udCSIDivColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool udCSIDivSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.udCSIDivColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.udCSIDiv field.
	/// </summary>
	public string udCSIDivDefault
	{
		get
		{
			return TableUtils.udCSIDivColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDPhaseMaster_.PhaseMasterKey field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDPhaseMaster_.PhaseMasterKey field.
	/// </summary>
	public string PhaseMasterKeyDefault
	{
		get
		{
			return TableUtils.PhaseMasterKeyColumn.DefaultValue;
		}
	}


#endregion
}

}
