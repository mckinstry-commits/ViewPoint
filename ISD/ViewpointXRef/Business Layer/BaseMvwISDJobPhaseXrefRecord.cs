// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDJobPhaseXrefRecord.cs

using System;
using System.Collections;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;

namespace ViewpointXRef.Business
{

/// <summary>
/// The generated superclass for the <see cref="MvwISDJobPhaseXrefRecord"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="MvwISDJobPhaseXrefView"></see> class.
/// </remarks>
/// <seealso cref="MvwISDJobPhaseXrefView"></seealso>
/// <seealso cref="MvwISDJobPhaseXrefRecord"></seealso>
public class BaseMvwISDJobPhaseXrefRecord : PrimaryKeyRecord
{

	public readonly static MvwISDJobPhaseXrefView TableUtils = MvwISDJobPhaseXrefView.Instance;

	// Constructors
 
	protected BaseMvwISDJobPhaseXrefRecord() : base(TableUtils)
	{
		this.InsertingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.InsertingRecordEventHandler(this.MvwISDJobPhaseXrefRecord_InsertingRecord); 
		this.UpdatingRecord += 
			new BaseClasses.IRecordWithTriggerEvents.UpdatingRecordEventHandler(this.MvwISDJobPhaseXrefRecord_UpdatingRecord); 
		this.ReadRecord +=
            new BaseClasses.IRecordWithTriggerEvents.ReadRecordEventHandler(this.MvwISDJobPhaseXrefRecord_ReadRecord); 
	}

	protected BaseMvwISDJobPhaseXrefRecord(PrimaryKeyRecord record) : base(record, TableUtils)
	{
	}
	
	
	//Audit Trail methods
	
	//Evaluates Initialize when->Reading record formulas specified at the data access layer
    protected virtual void MvwISDJobPhaseXrefRecord_ReadRecord(Object sender,System.EventArgs e)
    {
        //Apply Initialize->Reading record formula only if validation is successful.
                MvwISDJobPhaseXrefRecord MvwISDJobPhaseXrefRec = (MvwISDJobPhaseXrefRecord)sender;
        if(MvwISDJobPhaseXrefRec != null && !MvwISDJobPhaseXrefRec.IsReadOnly ){
                }
    
    }
        
	//Evaluates Initialize when->Inserting formulas specified at the data access layer
    protected virtual void MvwISDJobPhaseXrefRecord_InsertingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Inserting formula only if validation is successful.
                MvwISDJobPhaseXrefRecord MvwISDJobPhaseXrefRec = (MvwISDJobPhaseXrefRecord)sender;
        Validate_Inserting();
        if(MvwISDJobPhaseXrefRec != null && !MvwISDJobPhaseXrefRec.IsReadOnly ){
                }
    
    }
    
    //Evaluates Initialize when->Updating formulas specified at the data access layer
    protected virtual void MvwISDJobPhaseXrefRecord_UpdatingRecord(Object sender,System.ComponentModel.CancelEventArgs e)
    {
        //Apply Initialize->Updating formula only if validation is successful.
                MvwISDJobPhaseXrefRecord MvwISDJobPhaseXrefRec = (MvwISDJobPhaseXrefRecord)sender;
        Validate_Updating();
        if(MvwISDJobPhaseXrefRec != null && !MvwISDJobPhaseXrefRec.IsReadOnly ){
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
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPCo field.
	/// </summary>
	public ColumnValue GetVPCoValue()
	{
		return this.GetValue(TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPCo field.
	/// </summary>
	public Byte GetVPCoFieldValue()
	{
		return this.GetValue(TableUtils.VPCoColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(string val)
	{
		this.SetString(val, TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPCo field.
	/// </summary>
	public void SetVPCoFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPJob field.
	/// </summary>
	public ColumnValue GetVPJobValue()
	{
		return this.GetValue(TableUtils.VPJobColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPJob field.
	/// </summary>
	public string GetVPJobFieldValue()
	{
		return this.GetValue(TableUtils.VPJobColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPJob field.
	/// </summary>
	public void SetVPJobFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPJobColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPJob field.
	/// </summary>
	public void SetVPJobFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPJobColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.CGCCo field.
	/// </summary>
	public ColumnValue GetCGCCoValue()
	{
		return this.GetValue(TableUtils.CGCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.CGCCo field.
	/// </summary>
	public string GetCGCCoFieldValue()
	{
		return this.GetValue(TableUtils.CGCCoColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CGCCo field.
	/// </summary>
	public void SetCGCCoFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CGCCoColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CGCCo field.
	/// </summary>
	public void SetCGCCoFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CGCCoColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.CGCJob field.
	/// </summary>
	public ColumnValue GetCGCJobValue()
	{
		return this.GetValue(TableUtils.CGCJobColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.CGCJob field.
	/// </summary>
	public string GetCGCJobFieldValue()
	{
		return this.GetValue(TableUtils.CGCJobColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CGCJob field.
	/// </summary>
	public void SetCGCJobFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CGCJobColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CGCJob field.
	/// </summary>
	public void SetCGCJobFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CGCJobColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPJobDesc field.
	/// </summary>
	public ColumnValue GetVPJobDescValue()
	{
		return this.GetValue(TableUtils.VPJobDescColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPJobDesc field.
	/// </summary>
	public string GetVPJobDescFieldValue()
	{
		return this.GetValue(TableUtils.VPJobDescColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPJobDesc field.
	/// </summary>
	public void SetVPJobDescFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPJobDescColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPJobDesc field.
	/// </summary>
	public void SetVPJobDescFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPJobDescColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.POC field.
	/// </summary>
	public ColumnValue GetPOCValue()
	{
		return this.GetValue(TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.POC field.
	/// </summary>
	public Int32 GetPOCFieldValue()
	{
		return this.GetValue(TableUtils.POCColumn).ToInt32();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(string val)
	{
		this.SetString(val, TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POC field.
	/// </summary>
	public void SetPOCFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.POCName field.
	/// </summary>
	public ColumnValue GetPOCNameValue()
	{
		return this.GetValue(TableUtils.POCNameColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.POCName field.
	/// </summary>
	public string GetPOCNameFieldValue()
	{
		return this.GetValue(TableUtils.POCNameColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POCName field.
	/// </summary>
	public void SetPOCNameFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.POCNameColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POCName field.
	/// </summary>
	public void SetPOCNameFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.POCNameColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public ColumnValue GetVPPhaseGroupValue()
	{
		return this.GetValue(TableUtils.VPPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public Byte GetVPPhaseGroupFieldValue()
	{
		return this.GetValue(TableUtils.VPPhaseGroupColumn).ToByte();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public void SetVPPhaseGroupFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public void SetVPPhaseGroupFieldValue(string val)
	{
		this.SetString(val, TableUtils.VPPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public void SetVPPhaseGroupFieldValue(double val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public void SetVPPhaseGroupFieldValue(decimal val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPPhaseGroupColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public void SetVPPhaseGroupFieldValue(long val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPPhaseGroupColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhase field.
	/// </summary>
	public ColumnValue GetVPPhaseValue()
	{
		return this.GetValue(TableUtils.VPPhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhase field.
	/// </summary>
	public string GetVPPhaseFieldValue()
	{
		return this.GetValue(TableUtils.VPPhaseColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhase field.
	/// </summary>
	public void SetVPPhaseFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPPhaseColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhase field.
	/// </summary>
	public void SetVPPhaseFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPPhaseColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.CostTypeCode field.
	/// </summary>
	public ColumnValue GetCostTypeCodeValue()
	{
		return this.GetValue(TableUtils.CostTypeCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.CostTypeCode field.
	/// </summary>
	public string GetCostTypeCodeFieldValue()
	{
		return this.GetValue(TableUtils.CostTypeCodeColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CostTypeCode field.
	/// </summary>
	public void SetCostTypeCodeFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CostTypeCodeColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CostTypeCode field.
	/// </summary>
	public void SetCostTypeCodeFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CostTypeCodeColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.CostTypeDesc field.
	/// </summary>
	public ColumnValue GetCostTypeDescValue()
	{
		return this.GetValue(TableUtils.CostTypeDescColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.CostTypeDesc field.
	/// </summary>
	public string GetCostTypeDescFieldValue()
	{
		return this.GetValue(TableUtils.CostTypeDescColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CostTypeDesc field.
	/// </summary>
	public void SetCostTypeDescFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.CostTypeDescColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CostTypeDesc field.
	/// </summary>
	public void SetCostTypeDescFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.CostTypeDescColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhaseDescription field.
	/// </summary>
	public ColumnValue GetVPPhaseDescriptionValue()
	{
		return this.GetValue(TableUtils.VPPhaseDescriptionColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhaseDescription field.
	/// </summary>
	public string GetVPPhaseDescriptionFieldValue()
	{
		return this.GetValue(TableUtils.VPPhaseDescriptionColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseDescription field.
	/// </summary>
	public void SetVPPhaseDescriptionFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.VPPhaseDescriptionColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseDescription field.
	/// </summary>
	public void SetVPPhaseDescriptionFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.VPPhaseDescriptionColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.ConversionNotes field.
	/// </summary>
	public ColumnValue GetConversionNotesValue()
	{
		return this.GetValue(TableUtils.ConversionNotesColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.ConversionNotes field.
	/// </summary>
	public string GetConversionNotesFieldValue()
	{
		return this.GetValue(TableUtils.ConversionNotesColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.ConversionNotes field.
	/// </summary>
	public void SetConversionNotesFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.ConversionNotesColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.ConversionNotes field.
	/// </summary>
	public void SetConversionNotesFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.ConversionNotesColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.PhaseKey field.
	/// </summary>
	public ColumnValue GetPhaseKeyValue()
	{
		return this.GetValue(TableUtils.PhaseKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.PhaseKey field.
	/// </summary>
	public string GetPhaseKeyFieldValue()
	{
		return this.GetValue(TableUtils.PhaseKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.PhaseKey field.
	/// </summary>
	public void SetPhaseKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.PhaseKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.PhaseKey field.
	/// </summary>
	public void SetPhaseKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.PhaseKeyColumn);
	}
	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.JobKey field.
	/// </summary>
	public ColumnValue GetJobKeyValue()
	{
		return this.GetValue(TableUtils.JobKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that provides direct access to the value of the record's mvwISDJobPhaseXref_.JobKey field.
	/// </summary>
	public string GetJobKeyFieldValue()
	{
		return this.GetValue(TableUtils.JobKeyColumn).ToString();
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.JobKey field.
	/// </summary>
	public void SetJobKeyFieldValue(ColumnValue val)
	{
		this.SetValue(val, TableUtils.JobKeyColumn);
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.JobKey field.
	/// </summary>
	public void SetJobKeyFieldValue(string val)
	{
		ColumnValue cv = new ColumnValue(val);
		this.SetValue(cv, TableUtils.JobKeyColumn);
	}


#endregion

#region "Convenience methods to get field names"

	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPCo field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPCo field.
	/// </summary>
	public string VPCoDefault
	{
		get
		{
			return TableUtils.VPCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPJob field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPJob field.
	/// </summary>
	public string VPJobDefault
	{
		get
		{
			return TableUtils.VPJobColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.CGCCo field.
	/// </summary>
	public string CGCCo
	{
		get
		{
			return this.GetValue(TableUtils.CGCCoColumn).ToString();
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CGCCo field.
	/// </summary>
	public string CGCCoDefault
	{
		get
		{
			return TableUtils.CGCCoColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.CGCJob field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CGCJob field.
	/// </summary>
	public string CGCJobDefault
	{
		get
		{
			return TableUtils.CGCJobColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPJobDesc field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPJobDesc field.
	/// </summary>
	public string VPJobDescDefault
	{
		get
		{
			return TableUtils.VPJobDescColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.POC field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POC field.
	/// </summary>
	public string POCDefault
	{
		get
		{
			return TableUtils.POCColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.POCName field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.POCName field.
	/// </summary>
	public string POCNameDefault
	{
		get
		{
			return TableUtils.POCNameColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public Byte VPPhaseGroup
	{
		get
		{
			return this.GetValue(TableUtils.VPPhaseGroupColumn).ToByte();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPPhaseGroupColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPPhaseGroupSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPPhaseGroupColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseGroup field.
	/// </summary>
	public string VPPhaseGroupDefault
	{
		get
		{
			return TableUtils.VPPhaseGroupColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhase field.
	/// </summary>
	public string VPPhase
	{
		get
		{
			return this.GetValue(TableUtils.VPPhaseColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPPhaseColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPPhaseSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPPhaseColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhase field.
	/// </summary>
	public string VPPhaseDefault
	{
		get
		{
			return TableUtils.VPPhaseColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.CostTypeCode field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CostTypeCode field.
	/// </summary>
	public string CostTypeCodeDefault
	{
		get
		{
			return TableUtils.CostTypeCodeColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.CostTypeDesc field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.CostTypeDesc field.
	/// </summary>
	public string CostTypeDescDefault
	{
		get
		{
			return TableUtils.CostTypeDescColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.VPPhaseDescription field.
	/// </summary>
	public string VPPhaseDescription
	{
		get
		{
			return this.GetValue(TableUtils.VPPhaseDescriptionColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.VPPhaseDescriptionColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool VPPhaseDescriptionSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.VPPhaseDescriptionColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.VPPhaseDescription field.
	/// </summary>
	public string VPPhaseDescriptionDefault
	{
		get
		{
			return TableUtils.VPPhaseDescriptionColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.ConversionNotes field.
	/// </summary>
	public string ConversionNotes
	{
		get
		{
			return this.GetValue(TableUtils.ConversionNotesColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.ConversionNotesColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool ConversionNotesSpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.ConversionNotesColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.ConversionNotes field.
	/// </summary>
	public string ConversionNotesDefault
	{
		get
		{
			return TableUtils.ConversionNotesColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.PhaseKey field.
	/// </summary>
	public string PhaseKey
	{
		get
		{
			return this.GetValue(TableUtils.PhaseKeyColumn).ToString();
		}
		set
		{
			ColumnValue cv = new ColumnValue(value);
			this.SetValue(cv, TableUtils.PhaseKeyColumn);
		}
	}


	/// <summary>
	/// This is a convenience method that can be used to determine that the column is set.
	/// </summary>
	public bool PhaseKeySpecified
	{
		get
		{
			ColumnValue val = this.GetValue(TableUtils.PhaseKeyColumn);
            if (val == null || val.IsNull)
            {
                return false;
            }
            return true;
		}
	}

	/// <summary>
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.PhaseKey field.
	/// </summary>
	public string PhaseKeyDefault
	{
		get
		{
			return TableUtils.PhaseKeyColumn.DefaultValue;
		}
	}
	/// <summary>
	/// This is a property that provides direct access to the value of the record's mvwISDJobPhaseXref_.JobKey field.
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
	/// This is a convenience method that allows direct modification of the value of the record's mvwISDJobPhaseXref_.JobKey field.
	/// </summary>
	public string JobKeyDefault
	{
		get
		{
			return TableUtils.JobKeyColumn.DefaultValue;
		}
	}


#endregion
}

}
