// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDJobPhaseXrefView.cs


using System;
using System.Data;
using System.Collections;
using System.Runtime;
using System.Data.SqlTypes;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;
using ViewpointXRef.Data;

namespace ViewpointXRef.Business
{

/// <summary>
/// The generated superclass for the <see cref="MvwISDJobPhaseXrefView"></see> class.
/// Provides access to the schema information and record data of a database table or view named DatabaseViewpoint%dbo.mvwISDJobPhaseXref.
/// </summary>
/// <remarks>
/// The connection details (name, location, etc.) of the database and table (or view) accessed by this class 
/// are resolved at runtime based on the connection string in the application's Web.Config file.
/// <para>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, use 
/// <see cref="MvwISDJobPhaseXrefView.Instance">MvwISDJobPhaseXrefView.Instance</see>.
/// </para>
/// </remarks>
/// <seealso cref="MvwISDJobPhaseXrefView"></seealso>
[SerializableAttribute()]
public class BaseMvwISDJobPhaseXrefView : PrimaryKeyTable
{

    private readonly string TableDefinitionString = MvwISDJobPhaseXrefDefinition.GetXMLString();







    protected BaseMvwISDJobPhaseXrefView()
    {
        this.Initialize();
    }

    protected virtual void Initialize()
    {
        XmlTableDefinition def = new XmlTableDefinition(TableDefinitionString);
        this.TableDefinition = new TableDefinition();
        this.TableDefinition.TableClassName = System.Reflection.Assembly.CreateQualifiedName("ViewpointXRef.Business", "ViewpointXRef.Business.MvwISDJobPhaseXrefView");
        def.InitializeTableDefinition(this.TableDefinition);
        this.ConnectionName = def.GetConnectionName();
        this.RecordClassName = System.Reflection.Assembly.CreateQualifiedName("ViewpointXRef.Business", "ViewpointXRef.Business.MvwISDJobPhaseXrefRecord");
        this.ApplicationName = "ViewpointXRef";
        this.DataAdapter = new MvwISDJobPhaseXrefSqlView();
        ((MvwISDJobPhaseXrefSqlView)this.DataAdapter).ConnectionName = this.ConnectionName;
		
        this.TableDefinition.AdapterMetaData = this.DataAdapter.AdapterMetaData;
        VPCoColumn.CodeName = "VPCo";
        VPJobColumn.CodeName = "VPJob";
        CGCCoColumn.CodeName = "CGCCo";
        CGCJobColumn.CodeName = "CGCJob";
        VPJobDescColumn.CodeName = "VPJobDesc";
        POCColumn.CodeName = "POC";
        POCNameColumn.CodeName = "POCName";
        VPPhaseGroupColumn.CodeName = "VPPhaseGroup";
        VPPhaseColumn.CodeName = "VPPhase";
        CostTypeCodeColumn.CodeName = "CostTypeCode";
        CostTypeDescColumn.CodeName = "CostTypeDesc";
        VPPhaseDescriptionColumn.CodeName = "VPPhaseDescription";
        ConversionNotesColumn.CodeName = "ConversionNotes";
        PhaseKeyColumn.CodeName = "PhaseKey";
        JobKeyColumn.CodeName = "JobKey";

        
    }
    
#region "Overriden methods"
	
#endregion    

#region "Properties for columns"

    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VPCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[0];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn VPCo
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.VPCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPJob column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VPJobColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[1];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPJob column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VPJob
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.VPJobColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.CGCCo column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CGCCoColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[2];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.CGCCo column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CGCCo
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.CGCCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.CGCJob column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CGCJobColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[3];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.CGCJob column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CGCJob
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.CGCJobColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPJobDesc column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VPJobDescColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[4];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPJobDesc column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VPJobDesc
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.VPJobDescColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.POC column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn POCColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[5];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.POC column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn POC
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.POCColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.POCName column object.
    /// </summary>
    public BaseClasses.Data.StringColumn POCNameColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[6];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.POCName column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn POCName
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.POCNameColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPPhaseGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VPPhaseGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[7];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPPhaseGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn VPPhaseGroup
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.VPPhaseGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPPhase column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VPPhaseColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[8];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPPhase column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VPPhase
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.VPPhaseColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.CostTypeCode column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CostTypeCodeColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[9];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.CostTypeCode column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CostTypeCode
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.CostTypeCodeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.CostTypeDesc column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CostTypeDescColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[10];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.CostTypeDesc column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CostTypeDesc
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.CostTypeDescColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPPhaseDescription column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VPPhaseDescriptionColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[11];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.VPPhaseDescription column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VPPhaseDescription
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.VPPhaseDescriptionColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.ConversionNotes column object.
    /// </summary>
    public BaseClasses.Data.ClobColumn ConversionNotesColumn
    {
        get
        {
            return (BaseClasses.Data.ClobColumn)this.TableDefinition.ColumnList[12];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.ConversionNotes column object.
    /// </summary>
    public static BaseClasses.Data.ClobColumn ConversionNotes
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.ConversionNotesColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.PhaseKey column object.
    /// </summary>
    public BaseClasses.Data.StringColumn PhaseKeyColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[13];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.PhaseKey column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn PhaseKey
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.PhaseKeyColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.JobKey column object.
    /// </summary>
    public BaseClasses.Data.StringColumn JobKeyColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[14];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobPhaseXref_.JobKey column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn JobKey
    {
        get
        {
            return MvwISDJobPhaseXrefView.Instance.JobKeyColumn;
        }
    }
    
    


#endregion

    
#region "Shared helper methods"

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobPhaseXrefRecord records using a where clause.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord[] GetRecords(string where)
    {
        return GetRecords(where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobPhaseXrefRecord records using a where clause.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord[] GetRecords(BaseFilter join, string where)
    {
        return GetRecords(join, where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobPhaseXrefRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord[] GetRecords(string where, OrderBy orderBy)
    {
        return GetRecords(where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
     /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobPhaseXrefRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy)
    {
        return GetRecords(join, where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }    
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobPhaseXrefRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord[] GetRecords(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDJobPhaseXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDJobPhaseXrefRecord[])recList.ToArray(Type.GetType("ViewpointXRef.Business.MvwISDJobPhaseXrefRecord"));
    }   
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobPhaseXrefRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        ArrayList recList = MvwISDJobPhaseXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDJobPhaseXrefRecord[])recList.ToArray(Type.GetType("ViewpointXRef.Business.MvwISDJobPhaseXrefRecord"));
    }   


    public static MvwISDJobPhaseXrefRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDJobPhaseXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDJobPhaseXrefRecord[])recList.ToArray(Type.GetType("ViewpointXRef.Business.MvwISDJobPhaseXrefRecord"));
    }

    public static MvwISDJobPhaseXrefRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{

        ArrayList recList = MvwISDJobPhaseXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDJobPhaseXrefRecord[])recList.ToArray(Type.GetType("ViewpointXRef.Business.MvwISDJobPhaseXrefRecord"));
    }


    public static MvwISDJobPhaseXrefRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDJobPhaseXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDJobPhaseXrefRecord[])recList.ToArray(Type.GetType("ViewpointXRef.Business.MvwISDJobPhaseXrefRecord"));
    }

    public static MvwISDJobPhaseXrefRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{

        ArrayList recList = MvwISDJobPhaseXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDJobPhaseXrefRecord[])recList.ToArray(Type.GetType("ViewpointXRef.Business.MvwISDJobPhaseXrefRecord"));
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

        return (int)MvwISDJobPhaseXrefView.Instance.GetRecordListCount(null, whereFilter, null, null);
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

        return (int)MvwISDJobPhaseXrefView.Instance.GetRecordListCount(join, whereFilter, null, null);
    }

    
    public static int GetRecordCount(WhereClause where)
    {
        return (int)MvwISDJobPhaseXrefView.Instance.GetRecordListCount(null, where.GetFilter(), null, null);
    }
    
    public static int GetRecordCount(BaseFilter join, WhereClause where)
    {
        return (int)MvwISDJobPhaseXrefView.Instance.GetRecordListCount(join, where.GetFilter(), null, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDJobPhaseXrefRecord record using a where clause.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord GetRecord(string where)
    {
        OrderBy orderBy = null;
        return GetRecord(where, orderBy);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDJobPhaseXrefRecord record using a where clause.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord GetRecord(BaseFilter join, string where)
    {
        OrderBy orderBy = null;
        return GetRecord(join, where, orderBy);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDJobPhaseXrefRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord GetRecord(string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDJobPhaseXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDJobPhaseXrefRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDJobPhaseXrefRecord)recList[0];
        }

        return rec;
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDJobPhaseXrefRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDJobPhaseXrefRecord GetRecord(BaseFilter join, string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        
        ArrayList recList = MvwISDJobPhaseXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDJobPhaseXrefRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDJobPhaseXrefRecord)recList[0];
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

        return MvwISDJobPhaseXrefView.Instance.GetColumnValues(retCol, null, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

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

        return MvwISDJobPhaseXrefView.Instance.GetColumnValues(retCol, join, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

    }
      
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where)
    {
        MvwISDJobPhaseXrefRecord[] recs = GetRecords(where);
        return  MvwISDJobPhaseXrefView.Instance.CreateDataTable(recs, null);
    }

    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where)
    {
        MvwISDJobPhaseXrefRecord[] recs = GetRecords(join, where);
        return  MvwISDJobPhaseXrefView.Instance.CreateDataTable(recs, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy)
    {
        MvwISDJobPhaseXrefRecord[] recs = GetRecords(where, orderBy);
        return  MvwISDJobPhaseXrefView.Instance.CreateDataTable(recs, null);
    }
   
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy)
    {
        MvwISDJobPhaseXrefRecord[] recs = GetRecords(join, where, orderBy);
        return  MvwISDJobPhaseXrefView.Instance.CreateDataTable(recs, null);
    }
   
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDJobPhaseXrefRecord[] recs = GetRecords(where, orderBy, pageIndex, pageSize);
        return  MvwISDJobPhaseXrefView.Instance.CreateDataTable(recs, null);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDJobPhaseXrefRecord[] recs = GetRecords(join, where, orderBy, pageIndex, pageSize);
        return  MvwISDJobPhaseXrefView.Instance.CreateDataTable(recs, null);
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
        MvwISDJobPhaseXrefView.Instance.DeleteRecordList(whereFilter);
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
        
        return  MvwISDJobPhaseXrefView.Instance.ExportRecordData(whereFilter);
    }
   
    public static string Export(WhereClause where)
    {
        BaseFilter whereFilter = null;
        if (where != null)
        {
            whereFilter = where.GetFilter();
        }

        return MvwISDJobPhaseXrefView.Instance.ExportRecordData(whereFilter);
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

        return MvwISDJobPhaseXrefView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDJobPhaseXrefView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDJobPhaseXrefView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDJobPhaseXrefView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }

    /// <summary>
    ///  This method returns the columns in the table.
    /// </summary>
    public static BaseColumn[] GetColumns() 
    {
        return MvwISDJobPhaseXrefView.Instance.TableDefinition.Columns;
    }

    /// <summary>
    ///  This method returns the columnlist in the table.
    /// </summary>   
    public static ColumnList GetColumnList() 
    {
        return MvwISDJobPhaseXrefView.Instance.TableDefinition.ColumnList;
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    public static IRecord CreateNewRecord() 
    {
        return MvwISDJobPhaseXrefView.Instance.CreateRecord();
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    /// <param name="tempId">ID of the new record.</param>   
    public static IRecord CreateNewRecord(string tempId) 
    {
        return MvwISDJobPhaseXrefView.Instance.CreateRecord(tempId);
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
        BaseColumn column = MvwISDJobPhaseXrefView.Instance.TableDefinition.ColumnList.GetByUniqueName(uniqueColumnName);
        return column;
    }
    
    /// <summary>
    /// This method gets the specified column.
    /// </summary>
    /// <param name="name">name of the column to fetch.</param>
    public static BaseColumn GetColumnByName(string name)
    {
        BaseColumn column = MvwISDJobPhaseXrefView.Instance.TableDefinition.ColumnList.GetByInternalName(name);
        return column;
    }           

        //Convenience method for getting a record using a string-based record identifier
        public static MvwISDJobPhaseXrefRecord GetRecord(string id, bool bMutable)
        {
            return (MvwISDJobPhaseXrefRecord)MvwISDJobPhaseXrefView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for getting a record using a KeyValue record identifier
        public static MvwISDJobPhaseXrefRecord GetRecord(KeyValue id, bool bMutable)
        {
            return (MvwISDJobPhaseXrefRecord)MvwISDJobPhaseXrefView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for creating a record
        public KeyValue NewRecord(
        string VPCoValue, 
        string VPJobValue, 
        string CGCCoValue, 
        string CGCJobValue, 
        string VPJobDescValue, 
        string POCValue, 
        string POCNameValue, 
        string VPPhaseGroupValue, 
        string VPPhaseValue, 
        string CostTypeCodeValue, 
        string CostTypeDescValue, 
        string VPPhaseDescriptionValue, 
        string ConversionNotesValue, 
        string PhaseKeyValue, 
        string JobKeyValue
    )
        {
            IPrimaryKeyRecord rec = (IPrimaryKeyRecord)this.CreateRecord();
                    rec.SetString(VPCoValue, VPCoColumn);
        rec.SetString(VPJobValue, VPJobColumn);
        rec.SetString(CGCCoValue, CGCCoColumn);
        rec.SetString(CGCJobValue, CGCJobColumn);
        rec.SetString(VPJobDescValue, VPJobDescColumn);
        rec.SetString(POCValue, POCColumn);
        rec.SetString(POCNameValue, POCNameColumn);
        rec.SetString(VPPhaseGroupValue, VPPhaseGroupColumn);
        rec.SetString(VPPhaseValue, VPPhaseColumn);
        rec.SetString(CostTypeCodeValue, CostTypeCodeColumn);
        rec.SetString(CostTypeDescValue, CostTypeDescColumn);
        rec.SetString(VPPhaseDescriptionValue, VPPhaseDescriptionColumn);
        rec.SetString(ConversionNotesValue, ConversionNotesColumn);
        rec.SetString(PhaseKeyValue, PhaseKeyColumn);
        rec.SetString(JobKeyValue, JobKeyColumn);


            rec.Create(); //update the DB so any DB-initialized fields (like autoincrement IDs) can be initialized

            return rec.GetID();
        }
        
        /// <summary>
		///  This method deletes a specified record
		/// </summary>
		/// <param name="kv">Keyvalue of the record to be deleted.</param>
		public static void DeleteRecord(KeyValue kv)
		{
			MvwISDJobPhaseXrefView.Instance.DeleteOneRecord(kv);
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
				MvwISDJobPhaseXrefView.GetRecord(kv, false);
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
            if (!(MvwISDJobPhaseXrefView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                return MvwISDJobPhaseXrefView.Instance.TableDefinition.PrimaryKey.Columns;
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
            if (!(MvwISDJobPhaseXrefView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                bool isCompositePrimaryKey = false;
                isCompositePrimaryKey = MvwISDJobPhaseXrefView.Instance.TableDefinition.PrimaryKey.IsCompositeKey;
                if ((isCompositePrimaryKey && key.GetType().IsArray)) 
                {
                    //  If the key is composite, then construct a key value.
                    kv = new KeyValue();
                    Array keyArray = ((Array)(key));
                    if (!(keyArray == null)) 
                    {
                        int length = keyArray.Length;
                        ColumnList pkColumns = MvwISDJobPhaseXrefView.Instance.TableDefinition.PrimaryKey.Columns;
                        int index = 0;
                        foreach (BaseColumn pkColumn in pkColumns) 
                        {
                            string keyString = ((keyArray.GetValue(index)).ToString());
                            if (MvwISDJobPhaseXrefView.Instance.TableDefinition.TableType == BaseClasses.Data.TableDefinition.TableTypes.Virtual)
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
                    kv = MvwISDJobPhaseXrefView.Instance.TableDefinition.PrimaryKey.ParseValue(((key).ToString()));
                }
            }
            return kv;
        }
        
        /// <summary>
        /// This method takes a record and a Column and returns an evaluated value of DFKA formula.
        /// </summary>
        public static string GetDFKA(BaseRecord rec, BaseColumn col)
		{
			ForeignKey fkColumn = MvwISDJobPhaseXrefView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
			ForeignKey fkColumn = MvwISDJobPhaseXrefView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
