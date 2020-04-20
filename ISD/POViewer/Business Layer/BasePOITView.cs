// This class is "generated" and will be overwritten.
// Your customizations should be made in POITView.cs

using System;
using System.Data;
using System.Collections;
using System.Runtime;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;
using POViewer.Data;

namespace POViewer.Business
{

/// <summary>
/// The generated superclass for the <see cref="POITView"></see> class.
/// Provides access to the schema information and record data of a database table or view named DatabaseViewpoint%dbo.POIT.
/// </summary>
/// <remarks>
/// The connection details (name, location, etc.) of the database and table (or view) accessed by this class 
/// are resolved at runtime based on the connection string in the application's Web.Config file.
/// <para>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, use 
/// <see cref="POITView.Instance">POITView.Instance</see>.
/// </para>
/// </remarks>
/// <seealso cref="POITView"></seealso>
[SerializableAttribute()]
public class BasePOITView : KeylessTable
{

	private readonly string TableDefinitionString = POITDefinition.GetXMLString();







	protected BasePOITView()
	{
		this.Initialize();
	}

	protected virtual void Initialize()
	{
		XmlTableDefinition def = new XmlTableDefinition(TableDefinitionString);
		this.TableDefinition = new TableDefinition();
		this.TableDefinition.TableClassName = System.Reflection.Assembly.CreateQualifiedName("POViewer.Business", "POViewer.Business.POITView");
		def.InitializeTableDefinition(this.TableDefinition);
		this.ConnectionName = def.GetConnectionName();
		this.RecordClassName = System.Reflection.Assembly.CreateQualifiedName("POViewer.Business", "POViewer.Business.POITRecord");
		this.ApplicationName = "POViewer";
		this.DataAdapter = new POITSqlView();
		((POITSqlView)this.DataAdapter).ConnectionName = this.ConnectionName;
		((POITSqlView)this.DataAdapter).ApplicationName = this.ApplicationName;
		this.TableDefinition.AdapterMetaData = this.DataAdapter.AdapterMetaData;
        POCoColumn.CodeName = "POCo";
        POColumn.CodeName = "PO";
        POItemColumn.CodeName = "POItem";
        ItemTypeColumn.CodeName = "ItemType";
        MatlGroupColumn.CodeName = "MatlGroup";
        MaterialColumn.CodeName = "Material";
        VendMatIdColumn.CodeName = "VendMatId";
        DescriptionColumn.CodeName = "Description";
        UMColumn.CodeName = "UM";
        RecvYNColumn.CodeName = "RecvYN";
        PostToCoColumn.CodeName = "PostToCo";
        LocColumn.CodeName = "Loc";
        JobColumn.CodeName = "Job";
        PhaseGroupColumn.CodeName = "PhaseGroup";
        PhaseColumn.CodeName = "Phase";
        JCCTypeColumn.CodeName = "JCCType";
        EquipColumn.CodeName = "Equip";
        CompTypeColumn.CodeName = "CompType";
        ComponentColumn.CodeName = "Component";
        EMGroupColumn.CodeName = "EMGroup";
        CostCodeColumn.CodeName = "CostCode";
        EMCTypeColumn.CodeName = "EMCType";
        WOColumn.CodeName = "WO";
        WOItemColumn.CodeName = "WOItem";
        GLCoColumn.CodeName = "GLCo";
        GLAcctColumn.CodeName = "GLAcct";
        ReqDateColumn.CodeName = "ReqDate";
        TaxGroupColumn.CodeName = "TaxGroup";
        TaxCodeColumn.CodeName = "TaxCode";
        TaxTypeColumn.CodeName = "TaxType";
        OrigUnitsColumn.CodeName = "OrigUnits";
        OrigUnitCostColumn.CodeName = "OrigUnitCost";
        OrigECMColumn.CodeName = "OrigECM";
        OrigCostColumn.CodeName = "OrigCost";
        OrigTaxColumn.CodeName = "OrigTax";
        CurUnitsColumn.CodeName = "CurUnits";
        CurUnitCostColumn.CodeName = "CurUnitCost";
        CurECMColumn.CodeName = "CurECM";
        CurCostColumn.CodeName = "CurCost";
        CurTaxColumn.CodeName = "CurTax";
        RecvdUnitsColumn.CodeName = "RecvdUnits";
        RecvdCostColumn.CodeName = "RecvdCost";
        BOUnitsColumn.CodeName = "BOUnits";
        BOCostColumn.CodeName = "BOCost";
        TotalUnitsColumn.CodeName = "TotalUnits";
        TotalCostColumn.CodeName = "TotalCost";
        TotalTaxColumn.CodeName = "TotalTax";
        InvUnitsColumn.CodeName = "InvUnits";
        InvCostColumn.CodeName = "InvCost";
        InvTaxColumn.CodeName = "InvTax";
        RemUnitsColumn.CodeName = "RemUnits";
        RemCostColumn.CodeName = "RemCost";
        RemTaxColumn.CodeName = "RemTax";
        InUseMthColumn.CodeName = "InUseMth";
        InUseBatchIdColumn.CodeName = "InUseBatchId";
        PostedDateColumn.CodeName = "PostedDate";
        NotesColumn.CodeName = "Notes";
        RequisitionNumColumn.CodeName = "RequisitionNum";
        AddedMthColumn.CodeName = "AddedMth";
        AddedBatchIDColumn.CodeName = "AddedBatchID";
        UniqueAttchIDColumn.CodeName = "UniqueAttchID";
        PayCategoryColumn.CodeName = "PayCategory";
        PayTypeColumn.CodeName = "PayType";
        KeyIDColumn.CodeName = "KeyID";
        INCoColumn.CodeName = "INCo";
        EMCoColumn.CodeName = "EMCo";
        JCCoColumn.CodeName = "JCCo";
        JCCmtdTaxColumn.CodeName = "JCCmtdTax";
        SupplierColumn.CodeName = "Supplier";
        SupplierGroupColumn.CodeName = "SupplierGroup";
        JCRemCmtdTaxColumn.CodeName = "JCRemCmtdTax";
        TaxRateColumn.CodeName = "TaxRate";
        GSTRateColumn.CodeName = "GSTRate";
        SMCoColumn.CodeName = "SMCo";
        SMWorkOrderColumn.CodeName = "SMWorkOrder";
        InvMiscAmtColumn.CodeName = "InvMiscAmt";
        SMScopeColumn.CodeName = "SMScope";
        SMPhaseGroupColumn.CodeName = "SMPhaseGroup";
        SMPhaseColumn.CodeName = "SMPhase";
        SMJCCostTypeColumn.CodeName = "SMJCCostType";
        udSourceColumn.CodeName = "udSource";
        udConvColumn.CodeName = "udConv";
        udCGCTableColumn.CodeName = "udCGCTable";
        udCGCTableIDColumn.CodeName = "udCGCTableID";
        udOnDateColumn.CodeName = "udOnDate";
        udPlnOffDateColumn.CodeName = "udPlnOffDate";
        udActOffDateColumn.CodeName = "udActOffDate";
        udRentalNumColumn.CodeName = "udRentalNum";
		
	}

#region "Overriden methods"
    
#endregion

#region "Properties for columns"

    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.POCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn POCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[0];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.POCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn POCo
    {
        get
        {
            return POITView.Instance.POCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PO column object.
    /// </summary>
    public BaseClasses.Data.StringColumn POColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[1];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PO column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn PO
    {
        get
        {
            return POITView.Instance.POColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.POItem column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn POItemColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[2];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.POItem column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn POItem
    {
        get
        {
            return POITView.Instance.POItemColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.ItemType column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn ItemTypeColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[3];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.ItemType column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn ItemType
    {
        get
        {
            return POITView.Instance.ItemTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.MatlGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn MatlGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[4];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.MatlGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn MatlGroup
    {
        get
        {
            return POITView.Instance.MatlGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Material column object.
    /// </summary>
    public BaseClasses.Data.StringColumn MaterialColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[5];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Material column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Material
    {
        get
        {
            return POITView.Instance.MaterialColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.VendMatId column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VendMatIdColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[6];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.VendMatId column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VendMatId
    {
        get
        {
            return POITView.Instance.VendMatIdColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Description column object.
    /// </summary>
    public BaseClasses.Data.StringColumn DescriptionColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[7];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Description column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Description
    {
        get
        {
            return POITView.Instance.DescriptionColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.UM column object.
    /// </summary>
    public BaseClasses.Data.StringColumn UMColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[8];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.UM column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn UM
    {
        get
        {
            return POITView.Instance.UMColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RecvYN column object.
    /// </summary>
    public BaseClasses.Data.StringColumn RecvYNColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[9];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RecvYN column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn RecvYN
    {
        get
        {
            return POITView.Instance.RecvYNColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PostToCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn PostToCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[10];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PostToCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn PostToCo
    {
        get
        {
            return POITView.Instance.PostToCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Loc column object.
    /// </summary>
    public BaseClasses.Data.StringColumn LocColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[11];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Loc column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Loc
    {
        get
        {
            return POITView.Instance.LocColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Job column object.
    /// </summary>
    public BaseClasses.Data.StringColumn JobColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[12];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Job column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Job
    {
        get
        {
            return POITView.Instance.JobColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PhaseGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn PhaseGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[13];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PhaseGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn PhaseGroup
    {
        get
        {
            return POITView.Instance.PhaseGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Phase column object.
    /// </summary>
    public BaseClasses.Data.StringColumn PhaseColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[14];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Phase column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Phase
    {
        get
        {
            return POITView.Instance.PhaseColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.JCCType column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn JCCTypeColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[15];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.JCCType column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn JCCType
    {
        get
        {
            return POITView.Instance.JCCTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Equip column object.
    /// </summary>
    public BaseClasses.Data.StringColumn EquipColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[16];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Equip column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Equip
    {
        get
        {
            return POITView.Instance.EquipColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CompType column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CompTypeColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[17];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CompType column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CompType
    {
        get
        {
            return POITView.Instance.CompTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Component column object.
    /// </summary>
    public BaseClasses.Data.StringColumn ComponentColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[18];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Component column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Component
    {
        get
        {
            return POITView.Instance.ComponentColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.EMGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn EMGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[19];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.EMGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn EMGroup
    {
        get
        {
            return POITView.Instance.EMGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CostCode column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CostCodeColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[20];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CostCode column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CostCode
    {
        get
        {
            return POITView.Instance.CostCodeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.EMCType column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn EMCTypeColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[21];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.EMCType column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn EMCType
    {
        get
        {
            return POITView.Instance.EMCTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.WO column object.
    /// </summary>
    public BaseClasses.Data.StringColumn WOColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[22];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.WO column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn WO
    {
        get
        {
            return POITView.Instance.WOColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.WOItem column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn WOItemColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[23];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.WOItem column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn WOItem
    {
        get
        {
            return POITView.Instance.WOItemColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.GLCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn GLCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[24];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.GLCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn GLCo
    {
        get
        {
            return POITView.Instance.GLCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.GLAcct column object.
    /// </summary>
    public BaseClasses.Data.StringColumn GLAcctColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[25];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.GLAcct column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn GLAcct
    {
        get
        {
            return POITView.Instance.GLAcctColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.ReqDate column object.
    /// </summary>
    public BaseClasses.Data.DateColumn ReqDateColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[26];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.ReqDate column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn ReqDate
    {
        get
        {
            return POITView.Instance.ReqDateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TaxGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn TaxGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[27];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TaxGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn TaxGroup
    {
        get
        {
            return POITView.Instance.TaxGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TaxCode column object.
    /// </summary>
    public BaseClasses.Data.StringColumn TaxCodeColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[28];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TaxCode column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn TaxCode
    {
        get
        {
            return POITView.Instance.TaxCodeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TaxType column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn TaxTypeColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[29];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TaxType column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn TaxType
    {
        get
        {
            return POITView.Instance.TaxTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigUnits column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn OrigUnitsColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[30];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigUnits column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn OrigUnits
    {
        get
        {
            return POITView.Instance.OrigUnitsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigUnitCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn OrigUnitCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[31];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigUnitCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn OrigUnitCost
    {
        get
        {
            return POITView.Instance.OrigUnitCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigECM column object.
    /// </summary>
    public BaseClasses.Data.StringColumn OrigECMColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[32];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigECM column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn OrigECM
    {
        get
        {
            return POITView.Instance.OrigECMColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn OrigCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[33];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn OrigCost
    {
        get
        {
            return POITView.Instance.OrigCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigTax column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn OrigTaxColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[34];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.OrigTax column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn OrigTax
    {
        get
        {
            return POITView.Instance.OrigTaxColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurUnits column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn CurUnitsColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[35];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurUnits column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn CurUnits
    {
        get
        {
            return POITView.Instance.CurUnitsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurUnitCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn CurUnitCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[36];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurUnitCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn CurUnitCost
    {
        get
        {
            return POITView.Instance.CurUnitCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurECM column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CurECMColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[37];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurECM column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CurECM
    {
        get
        {
            return POITView.Instance.CurECMColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn CurCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[38];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn CurCost
    {
        get
        {
            return POITView.Instance.CurCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurTax column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn CurTaxColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[39];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.CurTax column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn CurTax
    {
        get
        {
            return POITView.Instance.CurTaxColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RecvdUnits column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn RecvdUnitsColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[40];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RecvdUnits column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn RecvdUnits
    {
        get
        {
            return POITView.Instance.RecvdUnitsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RecvdCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn RecvdCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[41];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RecvdCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn RecvdCost
    {
        get
        {
            return POITView.Instance.RecvdCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.BOUnits column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn BOUnitsColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[42];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.BOUnits column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn BOUnits
    {
        get
        {
            return POITView.Instance.BOUnitsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.BOCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn BOCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[43];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.BOCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn BOCost
    {
        get
        {
            return POITView.Instance.BOCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TotalUnits column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn TotalUnitsColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[44];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TotalUnits column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn TotalUnits
    {
        get
        {
            return POITView.Instance.TotalUnitsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TotalCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn TotalCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[45];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TotalCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn TotalCost
    {
        get
        {
            return POITView.Instance.TotalCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TotalTax column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn TotalTaxColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[46];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TotalTax column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn TotalTax
    {
        get
        {
            return POITView.Instance.TotalTaxColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InvUnits column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn InvUnitsColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[47];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InvUnits column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn InvUnits
    {
        get
        {
            return POITView.Instance.InvUnitsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InvCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn InvCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[48];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InvCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn InvCost
    {
        get
        {
            return POITView.Instance.InvCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InvTax column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn InvTaxColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[49];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InvTax column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn InvTax
    {
        get
        {
            return POITView.Instance.InvTaxColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RemUnits column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn RemUnitsColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[50];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RemUnits column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn RemUnits
    {
        get
        {
            return POITView.Instance.RemUnitsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RemCost column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn RemCostColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[51];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RemCost column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn RemCost
    {
        get
        {
            return POITView.Instance.RemCostColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RemTax column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn RemTaxColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[52];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RemTax column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn RemTax
    {
        get
        {
            return POITView.Instance.RemTaxColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InUseMth column object.
    /// </summary>
    public BaseClasses.Data.DateColumn InUseMthColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[53];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InUseMth column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn InUseMth
    {
        get
        {
            return POITView.Instance.InUseMthColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InUseBatchId column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn InUseBatchIdColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[54];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InUseBatchId column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn InUseBatchId
    {
        get
        {
            return POITView.Instance.InUseBatchIdColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PostedDate column object.
    /// </summary>
    public BaseClasses.Data.DateColumn PostedDateColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[55];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PostedDate column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn PostedDate
    {
        get
        {
            return POITView.Instance.PostedDateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Notes column object.
    /// </summary>
    public BaseClasses.Data.ClobColumn NotesColumn
    {
        get
        {
            return (BaseClasses.Data.ClobColumn)this.TableDefinition.ColumnList[56];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Notes column object.
    /// </summary>
    public static BaseClasses.Data.ClobColumn Notes
    {
        get
        {
            return POITView.Instance.NotesColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RequisitionNum column object.
    /// </summary>
    public BaseClasses.Data.StringColumn RequisitionNumColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[57];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.RequisitionNum column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn RequisitionNum
    {
        get
        {
            return POITView.Instance.RequisitionNumColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.AddedMth column object.
    /// </summary>
    public BaseClasses.Data.DateColumn AddedMthColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[58];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.AddedMth column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn AddedMth
    {
        get
        {
            return POITView.Instance.AddedMthColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.AddedBatchID column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn AddedBatchIDColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[59];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.AddedBatchID column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn AddedBatchID
    {
        get
        {
            return POITView.Instance.AddedBatchIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.UniqueAttchID column object.
    /// </summary>
    public BaseClasses.Data.UniqueIdentifierColumn UniqueAttchIDColumn
    {
        get
        {
            return (BaseClasses.Data.UniqueIdentifierColumn)this.TableDefinition.ColumnList[60];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.UniqueAttchID column object.
    /// </summary>
    public static BaseClasses.Data.UniqueIdentifierColumn UniqueAttchID
    {
        get
        {
            return POITView.Instance.UniqueAttchIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PayCategory column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn PayCategoryColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[61];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PayCategory column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn PayCategory
    {
        get
        {
            return POITView.Instance.PayCategoryColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PayType column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn PayTypeColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[62];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.PayType column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn PayType
    {
        get
        {
            return POITView.Instance.PayTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.KeyID column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn KeyIDColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[63];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.KeyID column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn KeyID
    {
        get
        {
            return POITView.Instance.KeyIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.INCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn INCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[64];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.INCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn INCo
    {
        get
        {
            return POITView.Instance.INCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.EMCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn EMCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[65];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.EMCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn EMCo
    {
        get
        {
            return POITView.Instance.EMCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.JCCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn JCCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[66];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.JCCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn JCCo
    {
        get
        {
            return POITView.Instance.JCCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.JCCmtdTax column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn JCCmtdTaxColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[67];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.JCCmtdTax column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn JCCmtdTax
    {
        get
        {
            return POITView.Instance.JCCmtdTaxColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Supplier column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn SupplierColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[68];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.Supplier column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn Supplier
    {
        get
        {
            return POITView.Instance.SupplierColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SupplierGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn SupplierGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[69];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SupplierGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn SupplierGroup
    {
        get
        {
            return POITView.Instance.SupplierGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.JCRemCmtdTax column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn JCRemCmtdTaxColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[70];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.JCRemCmtdTax column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn JCRemCmtdTax
    {
        get
        {
            return POITView.Instance.JCRemCmtdTaxColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TaxRate column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn TaxRateColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[71];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.TaxRate column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn TaxRate
    {
        get
        {
            return POITView.Instance.TaxRateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.GSTRate column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn GSTRateColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[72];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.GSTRate column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn GSTRate
    {
        get
        {
            return POITView.Instance.GSTRateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn SMCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[73];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn SMCo
    {
        get
        {
            return POITView.Instance.SMCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMWorkOrder column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn SMWorkOrderColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[74];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMWorkOrder column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn SMWorkOrder
    {
        get
        {
            return POITView.Instance.SMWorkOrderColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InvMiscAmt column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn InvMiscAmtColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[75];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.InvMiscAmt column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn InvMiscAmt
    {
        get
        {
            return POITView.Instance.InvMiscAmtColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMScope column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn SMScopeColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[76];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMScope column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn SMScope
    {
        get
        {
            return POITView.Instance.SMScopeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMPhaseGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn SMPhaseGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[77];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMPhaseGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn SMPhaseGroup
    {
        get
        {
            return POITView.Instance.SMPhaseGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMPhase column object.
    /// </summary>
    public BaseClasses.Data.StringColumn SMPhaseColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[78];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMPhase column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn SMPhase
    {
        get
        {
            return POITView.Instance.SMPhaseColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMJCCostType column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn SMJCCostTypeColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[79];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.SMJCCostType column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn SMJCCostType
    {
        get
        {
            return POITView.Instance.SMJCCostTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udSource column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udSourceColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[80];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udSource column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udSource
    {
        get
        {
            return POITView.Instance.udSourceColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udConv column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udConvColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[81];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udConv column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udConv
    {
        get
        {
            return POITView.Instance.udConvColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udCGCTable column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udCGCTableColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[82];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udCGCTable column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udCGCTable
    {
        get
        {
            return POITView.Instance.udCGCTableColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udCGCTableID column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn udCGCTableIDColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[83];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udCGCTableID column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn udCGCTableID
    {
        get
        {
            return POITView.Instance.udCGCTableIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udOnDate column object.
    /// </summary>
    public BaseClasses.Data.DateColumn udOnDateColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[84];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udOnDate column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn udOnDate
    {
        get
        {
            return POITView.Instance.udOnDateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udPlnOffDate column object.
    /// </summary>
    public BaseClasses.Data.DateColumn udPlnOffDateColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[85];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udPlnOffDate column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn udPlnOffDate
    {
        get
        {
            return POITView.Instance.udPlnOffDateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udActOffDate column object.
    /// </summary>
    public BaseClasses.Data.DateColumn udActOffDateColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[86];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udActOffDate column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn udActOffDate
    {
        get
        {
            return POITView.Instance.udActOffDateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udRentalNum column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udRentalNumColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[87];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POIT_.udRentalNum column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udRentalNum
    {
        get
        {
            return POITView.Instance.udRentalNumColumn;
        }
    }
    
    


#endregion

#region "Shared helper methods"

    /// <summary>
    /// This is a shared function that can be used to get an array of POITRecord records using a where clause.
    /// </summary>
    public static POITRecord[] GetRecords(string where)
    {
        return GetRecords(where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get an array of POITRecord records using a where clause.
    /// </summary>
    public static POITRecord[] GetRecords(BaseFilter join, string where)
    {
        return GetRecords(join, where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    

    /// <summary>
    /// This is a shared function that can be used to get an array of POITRecord records using a where and order by clause.
    /// </summary>
    public static POITRecord[] GetRecords(string where, OrderBy orderBy)
    {
        return GetRecords(where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
     /// <summary>
    /// This is a shared function that can be used to get an array of POITRecord records using a where and order by clause.
    /// </summary>
    public static POITRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy)
    {
        return GetRecords(join, where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }    
    
    /// <summary>
    /// This is a shared function that can be used to get an array of POITRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static POITRecord[] GetRecords(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = POITView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (POITRecord[])recList.ToArray(Type.GetType("POViewer.Business.POITRecord"));
    }   
    
    /// <summary>
    /// This is a shared function that can be used to get an array of POITRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static POITRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        ArrayList recList = POITView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (POITRecord[])recList.ToArray(Type.GetType("POViewer.Business.POITRecord"));
    }   


    public static POITRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = POITView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (POITRecord[])recList.ToArray(Type.GetType("POViewer.Business.POITRecord"));
    }

    public static POITRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{

        ArrayList recList = POITView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (POITRecord[])recList.ToArray(Type.GetType("POViewer.Business.POITRecord"));
    }


    public static POITRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = POITView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (POITRecord[])recList.ToArray(Type.GetType("POViewer.Business.POITRecord"));
    }

    public static POITRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{

        ArrayList recList = POITView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (POITRecord[])recList.ToArray(Type.GetType("POViewer.Business.POITRecord"));
    }


    /// <summary>
    /// This is a shared function that can be used to get total number of records that will be returned using the where clause.
    /// </summary>
    public static int GetRecordCount(string where)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        return (int)POITView.Instance.GetRecordListCount(null, whereFilter, null, null);
    }

    /// <summary>
    /// This is a shared function that can be used to get total number of records that will be returned using the where clause.
    /// </summary>
    public static int GetRecordCount(BaseFilter join, string where)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        return (int)POITView.Instance.GetRecordListCount(join, whereFilter, null, null);
    }

    
    public static int GetRecordCount(WhereClause where)
    {
        return (int)POITView.Instance.GetRecordListCount(null, where.GetFilter(), null, null);
    }
    
    public static int GetRecordCount(BaseFilter join, WhereClause where)
    {
        return (int)POITView.Instance.GetRecordListCount(join, where.GetFilter(), null, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a POITRecord record using a where clause.
    /// </summary>
    public static POITRecord GetRecord(string where)
    {
        OrderBy orderBy = null;
        return GetRecord(where, orderBy);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a POITRecord record using a where clause.
    /// </summary>
    public static POITRecord GetRecord(BaseFilter join, string where)
    {
        OrderBy orderBy = null;
        return GetRecord(join, where, orderBy);
    }


    /// <summary>
    /// This is a shared function that can be used to get a POITRecord record using a where and order by clause.
    /// </summary>
    public static POITRecord GetRecord(string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;  
        ArrayList recList = POITView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        POITRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (POITRecord)recList[0];
        }

        return rec;
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a POITRecord record using a where and order by clause.
    /// </summary>
    public static POITRecord GetRecord(BaseFilter join, string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        
        ArrayList recList = POITView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        POITRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (POITRecord)recList[0];
        }

        return rec;
    }


    public static String[] GetValues(
		BaseColumn col,
		WhereClause where,
		OrderBy orderBy,
		int maxItems)
	{

        // Create the filter list.
        SqlBuilderColumnSelection retCol = new SqlBuilderColumnSelection(false, true);
        retCol.AddColumn(col);

        return POITView.Instance.GetColumnValues(retCol, null, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

    }

    public static String[] GetValues(
		BaseColumn col,
		BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int maxItems)
	{

        // Create the filter list.
        SqlBuilderColumnSelection retCol = new SqlBuilderColumnSelection(false, true);
        retCol.AddColumn(col);

        return POITView.Instance.GetColumnValues(retCol, join, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

    }
      
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where)
    {
        POITRecord[] recs = GetRecords(where);
        return  POITView.Instance.CreateDataTable(recs, null);
    }

    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where)
    {
        POITRecord[] recs = GetRecords(join, where);
        return  POITView.Instance.CreateDataTable(recs, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy)
    {
        POITRecord[] recs = GetRecords(where, orderBy);
        return  POITView.Instance.CreateDataTable(recs, null);
    }
   
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy)
    {
        POITRecord[] recs = GetRecords(join, where, orderBy);
        return  POITView.Instance.CreateDataTable(recs, null);
    }
   
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        POITRecord[] recs = GetRecords(where, orderBy, pageIndex, pageSize);
        return  POITView.Instance.CreateDataTable(recs, null);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        POITRecord[] recs = GetRecords(join, where, orderBy, pageIndex, pageSize);
        return  POITView.Instance.CreateDataTable(recs, null);
    }    
    
    /// <summary>
    /// This is a shared function that can be used to delete records using a where clause.
    /// </summary>
    public static void DeleteRecords(string where)
    {
        if (where == null || where.Trim() == "")
        {
           return;
        }
        
        SqlFilter whereFilter = new SqlFilter(where);
        POITView.Instance.DeleteRecordList(whereFilter);
    }
    
    /// <summary>
    /// This is a shared function that can be used to export records using a where clause.
    /// </summary>
    public static string Export(string where)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        
        return  POITView.Instance.ExportRecordData(whereFilter);
    }
   
    public static string Export(WhereClause where)
    {
        BaseFilter whereFilter = null;
        if (where != null)
        {
            whereFilter = where.GetFilter();
        }

        return POITView.Instance.ExportRecordData(whereFilter);
    }
    
	public static string GetSum(
		BaseColumn col,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        SqlBuilderColumnSelection colSel = new SqlBuilderColumnSelection(false, false);
        colSel.AddColumn(col, SqlBuilderColumnOperation.OperationType.Sum);

        return POITView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }
    
	public static string GetSum(
		BaseColumn col,
		BaseFilter join, 
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        SqlBuilderColumnSelection colSel = new SqlBuilderColumnSelection(false, false);
        colSel.AddColumn(col, SqlBuilderColumnOperation.OperationType.Sum);

        return POITView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }    
    
    public static string GetCount(
		BaseColumn col,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        SqlBuilderColumnSelection colSel = new SqlBuilderColumnSelection(false, false);
        colSel.AddColumn(col, SqlBuilderColumnOperation.OperationType.Count);

        return POITView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }
    
    public static string GetCount(
		BaseColumn col,
		BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        SqlBuilderColumnSelection colSel = new SqlBuilderColumnSelection(false, false);
        colSel.AddColumn(col, SqlBuilderColumnOperation.OperationType.Count);

        return POITView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }

    /// <summary>
    ///  This method returns the columns in the table.
    /// </summary>
    public static BaseColumn[] GetColumns() 
    {
        return POITView.Instance.TableDefinition.Columns;
    }

    /// <summary>
    ///  This method returns the columnlist in the table.
    /// </summary>   
    public static ColumnList GetColumnList() 
    {
        return POITView.Instance.TableDefinition.ColumnList;
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    public static IRecord CreateNewRecord() 
    {
        return POITView.Instance.CreateRecord();
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    /// <param name="tempId">ID of the new record.</param>   
    public static IRecord CreateNewRecord(string tempId) 
    {
        return POITView.Instance.CreateRecord(tempId);
    }

    /// <summary>
    /// This method checks if column is editable.
    /// </summary>
    /// <param name="columnName">Name of the column to check.</param>
    public static bool isReadOnlyColumn(string columnName) 
    {
        BaseColumn column = GetColumn(columnName);
        if (!(column == null)) 
        {
            return column.IsValuesReadOnly;
        }
        else 
        {
            return true;
        }
    }

    /// <summary>
    /// This method gets the specified column.
    /// </summary>
    /// <param name="uniqueColumnName">Unique name of the column to fetch.</param>
    public static BaseColumn GetColumn(string uniqueColumnName) 
    {
        BaseColumn column = POITView.Instance.TableDefinition.ColumnList.GetByUniqueName(uniqueColumnName);
        return column;
    }
    
    /// <summary>
    /// This method gets the specified column.
    /// </summary>
    /// <param name="name">name of the column to fetch.</param>
    public static BaseColumn GetColumnByName(string name)
    {
        BaseColumn column = POITView.Instance.TableDefinition.ColumnList.GetByInternalName(name);
        return column;
    } 

        /// <summary>
        /// This method takes a record and a Column and returns an evaluated value of DFKA formula.
        /// </summary>
        public static string GetDFKA(BaseRecord rec, BaseColumn col)
		{
			ForeignKey fkColumn = POITView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
			if (fkColumn == null)
				return null;
			String _DFKA = fkColumn.PrimaryKeyDisplayColumns;
			if (_DFKA.Trim().StartsWith("="))
            {
                // if the formula is in the format of "= <Primary table>.<Field name>, then pull out the data from the rec object instead of doing formula evaluation 
                string tableCodeName = fkColumn.PrimaryKeyTableDefinition.TableCodeName;
                string column = _DFKA.Trim('=').Trim();
                if (column.StartsWith(tableCodeName + ".", StringComparison.InvariantCultureIgnoreCase))
                {
                    column = column.Substring(tableCodeName.Length + 1);
                }

                foreach (BaseColumn c in fkColumn.PrimaryKeyTableDefinition.Columns)
                {
                    if (column == c.CodeName)
                    {
                        return rec.Format(c);
                    }
                }
                            
				String tableName = fkColumn.PrimaryKeyTableDefinition.TableCodeName;
				return EvaluateFormula(_DFKA, rec, null, tableName);
			}
			else
				return null;
		}

		/// <summary>
        /// This method takes a keyValue and a Column and returns an evaluated value of DFKA formula.
        /// </summary>
		public static string GetDFKA(String keyValue, BaseColumn col, String formatPattern)
		{
		    if (keyValue == null)
				return null;
			ForeignKey fkColumn = POITView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
			if (fkColumn == null)
				return null;
			String _DFKA = fkColumn.PrimaryKeyDisplayColumns;
			if (_DFKA.Trim().StartsWith("="))
            {
				String tableName = fkColumn.PrimaryKeyTableDefinition.TableCodeName;
				PrimaryKeyTable t = (PrimaryKeyTable)DatabaseObjects.GetTableObject(tableName);
				BaseRecord rec = null;
				
				if (t != null)
				{
					try
					{
						rec = (BaseRecord)t.GetRecordData(keyValue, false);
					}
					catch
					{
						rec = null;
					}
				}
				if( rec == null)
					return "";

                // if the formula is in the format of "= <Primary table>.<Field name>, then pull out the data from the rec object instead of doing formula evaluation 
                string tableCodeName = fkColumn.PrimaryKeyTableDefinition.TableCodeName;
                string column = _DFKA.Trim('=').Trim();
                if (column.StartsWith(tableCodeName + ".", StringComparison.InvariantCultureIgnoreCase))
                {
                    column = column.Substring(tableCodeName.Length + 1);
                }

                foreach (BaseColumn c in fkColumn.PrimaryKeyTableDefinition.Columns)
                {
                    if (column == c.CodeName)
                    {
                        return rec.Format(c);
                    }
                }	            
				return EvaluateFormula(_DFKA, rec, null, tableName);
			}
			else
				return null;
		}

		/// <summary>
        /// Evaluates the formula
        /// </summary>
		public static string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, string name)
		{
			BaseFormulaEvaluator e = new BaseFormulaEvaluator();
			if(dataSourceForEvaluate != null)
				e.Evaluator.Variables.Add(name, dataSourceForEvaluate);
			e.DataSource = dataSourceForEvaluate;
	        object resultObj = e.Evaluate(formula);
	
		    if (resultObj == null)
			    return "";
	        if (!string.IsNullOrEmpty(format))
	            return BaseFormulaUtils.Format(resultObj, format);
		    else
            return resultObj.ToString();
		}
		
		/// <summary>
        /// Evaluates the formula
        /// </summary>
		public static string EvaluateFormula(string formula)
		{
			return EvaluateFormula(formula,null,null,null);
		}
#endregion
}

}
