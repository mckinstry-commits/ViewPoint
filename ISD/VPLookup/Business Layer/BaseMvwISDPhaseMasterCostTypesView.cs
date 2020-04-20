﻿// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDPhaseMasterCostTypesView.cs


using System;
using System.Data;
using System.Collections;
using System.Runtime;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;
using VPLookup.Data;

namespace VPLookup.Business
{

/// <summary>
/// The generated superclass for the <see cref="MvwISDPhaseMasterCostTypesView"></see> class.
/// Provides access to the schema information and record data of a database table or view named DatabaseViewpoint%dbo.mvwISDPhaseMasterCostTypes.
/// </summary>
/// <remarks>
/// The connection details (name, location, etc.) of the database and table (or view) accessed by this class 
/// are resolved at runtime based on the connection string in the application's Web.Config file.
/// <para>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, use 
/// <see cref="MvwISDPhaseMasterCostTypesView.Instance">MvwISDPhaseMasterCostTypesView.Instance</see>.
/// </para>
/// </remarks>
/// <seealso cref="MvwISDPhaseMasterCostTypesView"></seealso>
[SerializableAttribute()]
public class BaseMvwISDPhaseMasterCostTypesView : PrimaryKeyTable
{

    private readonly string TableDefinitionString = MvwISDPhaseMasterCostTypesDefinition.GetXMLString();







    protected BaseMvwISDPhaseMasterCostTypesView()
    {
        this.Initialize();
    }

    protected virtual void Initialize()
    {
        XmlTableDefinition def = new XmlTableDefinition(TableDefinitionString);
        this.TableDefinition = new TableDefinition();
        this.TableDefinition.TableClassName = System.Reflection.Assembly.CreateQualifiedName("VPLookup.Business", "VPLookup.Business.MvwISDPhaseMasterCostTypesView");
        def.InitializeTableDefinition(this.TableDefinition);
        this.ConnectionName = def.GetConnectionName();
        this.RecordClassName = System.Reflection.Assembly.CreateQualifiedName("VPLookup.Business", "VPLookup.Business.MvwISDPhaseMasterCostTypesRecord");
        this.ApplicationName = "VPLookup";
        this.DataAdapter = new MvwISDPhaseMasterCostTypesSqlView();
        ((MvwISDPhaseMasterCostTypesSqlView)this.DataAdapter).ConnectionName = this.ConnectionName;
		
        this.TableDefinition.AdapterMetaData = this.DataAdapter.AdapterMetaData;
        PhaseGroupColumn.CodeName = "PhaseGroup";
        PhaseColumn.CodeName = "Phase";
        CostTypeColumn.CodeName = "CostType";
        BillFlagColumn.CodeName = "BillFlag";
        UMColumn.CodeName = "UM";
        ItemUnitFlagColumn.CodeName = "ItemUnitFlag";
        PhaseUnitFlagColumn.CodeName = "PhaseUnitFlag";
        udSourceColumn.CodeName = "udSource";
        udConvColumn.CodeName = "udConv";
        udCGCTableColumn.CodeName = "udCGCTable";
        udCGCTableIDColumn.CodeName = "udCGCTableID";
        CostTypeCodeColumn.CodeName = "CostTypeCode";
        CostTypeDescColumn.CodeName = "CostTypeDesc";
        PhaseMasterKeyColumn.CodeName = "PhaseMasterKey";
        PhaseMasterCostTypeKeyColumn.CodeName = "PhaseMasterCostTypeKey";

        
    }
    
#region "Overriden methods"
	
#endregion    

#region "Properties for columns"

    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.PhaseGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn PhaseGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[0];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.PhaseGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn PhaseGroup
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.PhaseGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.Phase column object.
    /// </summary>
    public BaseClasses.Data.StringColumn PhaseColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[1];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.Phase column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Phase
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.PhaseColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.CostType column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn CostTypeColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[2];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.CostType column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn CostType
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.CostTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.BillFlag column object.
    /// </summary>
    public BaseClasses.Data.StringColumn BillFlagColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[3];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.BillFlag column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn BillFlag
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.BillFlagColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.UM column object.
    /// </summary>
    public BaseClasses.Data.StringColumn UMColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[4];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.UM column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn UM
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.UMColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.ItemUnitFlag column object.
    /// </summary>
    public BaseClasses.Data.StringColumn ItemUnitFlagColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[5];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.ItemUnitFlag column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn ItemUnitFlag
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.ItemUnitFlagColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.PhaseUnitFlag column object.
    /// </summary>
    public BaseClasses.Data.StringColumn PhaseUnitFlagColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[6];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.PhaseUnitFlag column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn PhaseUnitFlag
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.PhaseUnitFlagColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.udSource column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udSourceColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[7];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.udSource column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udSource
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.udSourceColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.udConv column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udConvColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[8];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.udConv column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udConv
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.udConvColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.udCGCTable column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udCGCTableColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[9];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.udCGCTable column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udCGCTable
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.udCGCTableColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.udCGCTableID column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn udCGCTableIDColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[10];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.udCGCTableID column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn udCGCTableID
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.udCGCTableIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.CostTypeCode column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CostTypeCodeColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[11];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.CostTypeCode column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CostTypeCode
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.CostTypeCodeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.CostTypeDesc column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CostTypeDescColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[12];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.CostTypeDesc column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CostTypeDesc
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.CostTypeDescColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.PhaseMasterKey column object.
    /// </summary>
    public BaseClasses.Data.StringColumn PhaseMasterKeyColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[13];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.PhaseMasterKey column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn PhaseMasterKey
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.PhaseMasterKeyColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.PhaseMasterCostTypeKey column object.
    /// </summary>
    public BaseClasses.Data.StringColumn PhaseMasterCostTypeKeyColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[14];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDPhaseMasterCostTypes_.PhaseMasterCostTypeKey column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn PhaseMasterCostTypeKey
    {
        get
        {
            return MvwISDPhaseMasterCostTypesView.Instance.PhaseMasterCostTypeKeyColumn;
        }
    }
    
    


#endregion

    
#region "Shared helper methods"

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDPhaseMasterCostTypesRecord records using a where clause.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(string where)
    {
        return GetRecords(where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDPhaseMasterCostTypesRecord records using a where clause.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(BaseFilter join, string where)
    {
        return GetRecords(join, where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDPhaseMasterCostTypesRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(string where, OrderBy orderBy)
    {
        return GetRecords(where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
     /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDPhaseMasterCostTypesRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy)
    {
        return GetRecords(join, where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }    
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDPhaseMasterCostTypesRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDPhaseMasterCostTypesView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDPhaseMasterCostTypesRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDPhaseMasterCostTypesRecord"));
    }   
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDPhaseMasterCostTypesRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        ArrayList recList = MvwISDPhaseMasterCostTypesView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDPhaseMasterCostTypesRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDPhaseMasterCostTypesRecord"));
    }   


    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDPhaseMasterCostTypesView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDPhaseMasterCostTypesRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDPhaseMasterCostTypesRecord"));
    }

    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{

        ArrayList recList = MvwISDPhaseMasterCostTypesView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDPhaseMasterCostTypesRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDPhaseMasterCostTypesRecord"));
    }


    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDPhaseMasterCostTypesView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDPhaseMasterCostTypesRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDPhaseMasterCostTypesRecord"));
    }

    public static MvwISDPhaseMasterCostTypesRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{

        ArrayList recList = MvwISDPhaseMasterCostTypesView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDPhaseMasterCostTypesRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDPhaseMasterCostTypesRecord"));
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

        return (int)MvwISDPhaseMasterCostTypesView.Instance.GetRecordListCount(null, whereFilter, null, null);
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

        return (int)MvwISDPhaseMasterCostTypesView.Instance.GetRecordListCount(join, whereFilter, null, null);
    }

    
    public static int GetRecordCount(WhereClause where)
    {
        return (int)MvwISDPhaseMasterCostTypesView.Instance.GetRecordListCount(null, where.GetFilter(), null, null);
    }
    
    public static int GetRecordCount(BaseFilter join, WhereClause where)
    {
        return (int)MvwISDPhaseMasterCostTypesView.Instance.GetRecordListCount(join, where.GetFilter(), null, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDPhaseMasterCostTypesRecord record using a where clause.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord GetRecord(string where)
    {
        OrderBy orderBy = null;
        return GetRecord(where, orderBy);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDPhaseMasterCostTypesRecord record using a where clause.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord GetRecord(BaseFilter join, string where)
    {
        OrderBy orderBy = null;
        return GetRecord(join, where, orderBy);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDPhaseMasterCostTypesRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord GetRecord(string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;  
        ArrayList recList = MvwISDPhaseMasterCostTypesView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDPhaseMasterCostTypesRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDPhaseMasterCostTypesRecord)recList[0];
        }

        return rec;
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDPhaseMasterCostTypesRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDPhaseMasterCostTypesRecord GetRecord(BaseFilter join, string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        
        ArrayList recList = MvwISDPhaseMasterCostTypesView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDPhaseMasterCostTypesRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDPhaseMasterCostTypesRecord)recList[0];
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

        return MvwISDPhaseMasterCostTypesView.Instance.GetColumnValues(retCol, null, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

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

        return MvwISDPhaseMasterCostTypesView.Instance.GetColumnValues(retCol, join, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

    }
      
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where)
    {
        MvwISDPhaseMasterCostTypesRecord[] recs = GetRecords(where);
        return  MvwISDPhaseMasterCostTypesView.Instance.CreateDataTable(recs, null);
    }

    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where)
    {
        MvwISDPhaseMasterCostTypesRecord[] recs = GetRecords(join, where);
        return  MvwISDPhaseMasterCostTypesView.Instance.CreateDataTable(recs, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy)
    {
        MvwISDPhaseMasterCostTypesRecord[] recs = GetRecords(where, orderBy);
        return  MvwISDPhaseMasterCostTypesView.Instance.CreateDataTable(recs, null);
    }
   
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy)
    {
        MvwISDPhaseMasterCostTypesRecord[] recs = GetRecords(join, where, orderBy);
        return  MvwISDPhaseMasterCostTypesView.Instance.CreateDataTable(recs, null);
    }
   
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDPhaseMasterCostTypesRecord[] recs = GetRecords(where, orderBy, pageIndex, pageSize);
        return  MvwISDPhaseMasterCostTypesView.Instance.CreateDataTable(recs, null);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDPhaseMasterCostTypesRecord[] recs = GetRecords(join, where, orderBy, pageIndex, pageSize);
        return  MvwISDPhaseMasterCostTypesView.Instance.CreateDataTable(recs, null);
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
        MvwISDPhaseMasterCostTypesView.Instance.DeleteRecordList(whereFilter);
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
        
        return  MvwISDPhaseMasterCostTypesView.Instance.ExportRecordData(whereFilter);
    }
   
    public static string Export(WhereClause where)
    {
        BaseFilter whereFilter = null;
        if (where != null)
        {
            whereFilter = where.GetFilter();
        }

        return MvwISDPhaseMasterCostTypesView.Instance.ExportRecordData(whereFilter);
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

        return MvwISDPhaseMasterCostTypesView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDPhaseMasterCostTypesView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDPhaseMasterCostTypesView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDPhaseMasterCostTypesView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }

    /// <summary>
    ///  This method returns the columns in the table.
    /// </summary>
    public static BaseColumn[] GetColumns() 
    {
        return MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.Columns;
    }

    /// <summary>
    ///  This method returns the columnlist in the table.
    /// </summary>   
    public static ColumnList GetColumnList() 
    {
        return MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.ColumnList;
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    public static IRecord CreateNewRecord() 
    {
        return MvwISDPhaseMasterCostTypesView.Instance.CreateRecord();
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    /// <param name="tempId">ID of the new record.</param>   
    public static IRecord CreateNewRecord(string tempId) 
    {
        return MvwISDPhaseMasterCostTypesView.Instance.CreateRecord(tempId);
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
        BaseColumn column = MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.ColumnList.GetByUniqueName(uniqueColumnName);
        return column;
    }
    
    /// <summary>
    /// This method gets the specified column.
    /// </summary>
    /// <param name="name">name of the column to fetch.</param>
    public static BaseColumn GetColumnByName(string name)
    {
        BaseColumn column = MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.ColumnList.GetByInternalName(name);
        return column;
    } 

        //Convenience method for getting a record using a string-based record identifier
        public static MvwISDPhaseMasterCostTypesRecord GetRecord(string id, bool bMutable)
        {
            return (MvwISDPhaseMasterCostTypesRecord)MvwISDPhaseMasterCostTypesView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for getting a record using a KeyValue record identifier
        public static MvwISDPhaseMasterCostTypesRecord GetRecord(KeyValue id, bool bMutable)
        {
            return (MvwISDPhaseMasterCostTypesRecord)MvwISDPhaseMasterCostTypesView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for creating a record
        public KeyValue NewRecord(
        string PhaseGroupValue, 
        string PhaseValue, 
        string CostTypeValue, 
        string BillFlagValue, 
        string UMValue, 
        string ItemUnitFlagValue, 
        string PhaseUnitFlagValue, 
        string udSourceValue, 
        string udConvValue, 
        string udCGCTableValue, 
        string udCGCTableIDValue, 
        string CostTypeCodeValue, 
        string CostTypeDescValue, 
        string PhaseMasterKeyValue, 
        string PhaseMasterCostTypeKeyValue
    )
        {
            IPrimaryKeyRecord rec = (IPrimaryKeyRecord)this.CreateRecord();
                    rec.SetString(PhaseGroupValue, PhaseGroupColumn);
        rec.SetString(PhaseValue, PhaseColumn);
        rec.SetString(CostTypeValue, CostTypeColumn);
        rec.SetString(BillFlagValue, BillFlagColumn);
        rec.SetString(UMValue, UMColumn);
        rec.SetString(ItemUnitFlagValue, ItemUnitFlagColumn);
        rec.SetString(PhaseUnitFlagValue, PhaseUnitFlagColumn);
        rec.SetString(udSourceValue, udSourceColumn);
        rec.SetString(udConvValue, udConvColumn);
        rec.SetString(udCGCTableValue, udCGCTableColumn);
        rec.SetString(udCGCTableIDValue, udCGCTableIDColumn);
        rec.SetString(CostTypeCodeValue, CostTypeCodeColumn);
        rec.SetString(CostTypeDescValue, CostTypeDescColumn);
        rec.SetString(PhaseMasterKeyValue, PhaseMasterKeyColumn);
        rec.SetString(PhaseMasterCostTypeKeyValue, PhaseMasterCostTypeKeyColumn);


            rec.Create(); //update the DB so any DB-initialized fields (like autoincrement IDs) can be initialized

            return rec.GetID();
        }
        
        /// <summary>
		///  This method deletes a specified record
		/// </summary>
		/// <param name="kv">Keyvalue of the record to be deleted.</param>
		public static void DeleteRecord(KeyValue kv)
		{
			MvwISDPhaseMasterCostTypesView.Instance.DeleteOneRecord(kv);
		}

		/// <summary>
		/// This method checks if record exist in the database using the keyvalue provided.
		/// </summary>
		/// <param name="kv">Key value of the record.</param>
		public static bool DoesRecordExist(KeyValue kv)
		{
			bool recordExist = true;
			try
			{
				MvwISDPhaseMasterCostTypesView.GetRecord(kv, false);
			}
			catch (Exception)
			{
				recordExist = false;
			}
			return recordExist;
		}

        /// <summary>
        ///  This method returns all the primary columns in the table.
        /// </summary>
        public static ColumnList GetPrimaryKeyColumns() 
        {
            if (!(MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                return MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.PrimaryKey.Columns;
            }
            else 
            {
                return null;
            }
        }

        /// <summary>
        /// This method takes a key and returns a keyvalue.
        /// </summary>
        /// <param name="key">key could be array of primary key values in case of composite primary key or a string containing single primary key value in case of non-composite primary key.</param>
        public static KeyValue GetKeyValue(object key) 
        {
            KeyValue kv = null;
            if (!(MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                bool isCompositePrimaryKey = false;
                isCompositePrimaryKey = MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.PrimaryKey.IsCompositeKey;
                if ((isCompositePrimaryKey && key.GetType().IsArray)) 
                {
                    //  If the key is composite, then construct a key value.
                    kv = new KeyValue();
                    Array keyArray = ((Array)(key));
                    if (!(keyArray == null)) 
                    {
                        int length = keyArray.Length;
                        ColumnList pkColumns = MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.PrimaryKey.Columns;
                        int index = 0;
                        foreach (BaseColumn pkColumn in pkColumns) 
                        {
                            string keyString = ((keyArray.GetValue(index)).ToString());
                            if (MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.TableType == BaseClasses.Data.TableDefinition.TableTypes.Virtual)
                            {
                                kv.AddElement(pkColumn.UniqueName, keyString);
                            }
                            else 
                            {
                                kv.AddElement(pkColumn.InternalName, keyString);
                            }

                            index = (index + 1);
                        }
                    }
                }
                else 
                {
                    //  If the key is not composite, then get the key value.
                    kv = MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.PrimaryKey.ParseValue(((key).ToString()));
                }
            }
            return kv;
        }
        
        /// <summary>
        /// This method takes a record and a Column and returns an evaluated value of DFKA formula.
        /// </summary>
        public static string GetDFKA(BaseRecord rec, BaseColumn col)
		{
			ForeignKey fkColumn = MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
			ForeignKey fkColumn = MvwISDPhaseMasterCostTypesView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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