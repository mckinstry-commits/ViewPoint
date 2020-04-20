// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDVendorXrefView.cs


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
/// The generated superclass for the <see cref="MvwISDVendorXrefView"></see> class.
/// Provides access to the schema information and record data of a database table or view named DatabaseViewpoint%dbo.mvwISDVendorXref.
/// </summary>
/// <remarks>
/// The connection details (name, location, etc.) of the database and table (or view) accessed by this class 
/// are resolved at runtime based on the connection string in the application's Web.Config file.
/// <para>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, use 
/// <see cref="MvwISDVendorXrefView.Instance">MvwISDVendorXrefView.Instance</see>.
/// </para>
/// </remarks>
/// <seealso cref="MvwISDVendorXrefView"></seealso>
[SerializableAttribute()]
public class BaseMvwISDVendorXrefView : PrimaryKeyTable
{

    private readonly string TableDefinitionString = MvwISDVendorXrefDefinition.GetXMLString();







    protected BaseMvwISDVendorXrefView()
    {
        this.Initialize();
    }

    protected virtual void Initialize()
    {
        XmlTableDefinition def = new XmlTableDefinition(TableDefinitionString);
        this.TableDefinition = new TableDefinition();
        this.TableDefinition.TableClassName = System.Reflection.Assembly.CreateQualifiedName("VPLookup.Business", "VPLookup.Business.MvwISDVendorXrefView");
        def.InitializeTableDefinition(this.TableDefinition);
        this.ConnectionName = def.GetConnectionName();
        this.RecordClassName = System.Reflection.Assembly.CreateQualifiedName("VPLookup.Business", "VPLookup.Business.MvwISDVendorXrefRecord");
        this.ApplicationName = "VPLookup";
        this.DataAdapter = new MvwISDVendorXrefSqlView();
        ((MvwISDVendorXrefSqlView)this.DataAdapter).ConnectionName = this.ConnectionName;
		
        this.TableDefinition.AdapterMetaData = this.DataAdapter.AdapterMetaData;
        VendorGroupColumn.CodeName = "VendorGroup";
        VPVendorColumn.CodeName = "VPVendor";
        CGCVendorColumn.CodeName = "CGCVendor";
        VendorNameColumn.CodeName = "VendorName";
        IsSubcontractorColumn.CodeName = "IsSubcontractor";
        AddressColumn.CodeName = "Address";
        Address2Column.CodeName = "Address2";
        CityColumn.CodeName = "City";
        StateColumn.CodeName = "State";
        ZipColumn.CodeName = "Zip";
        VendorKeyColumn.CodeName = "VendorKey";

        
    }
    
#region "Overriden methods"
	
#endregion    

#region "Properties for columns"

    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.VendorGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VendorGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[0];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.VendorGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn VendorGroup
    {
        get
        {
            return MvwISDVendorXrefView.Instance.VendorGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.VPVendor column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VPVendorColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[1];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.VPVendor column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn VPVendor
    {
        get
        {
            return MvwISDVendorXrefView.Instance.VPVendorColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.CGCVendor column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CGCVendorColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[2];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.CGCVendor column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CGCVendor
    {
        get
        {
            return MvwISDVendorXrefView.Instance.CGCVendorColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.VendorName column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VendorNameColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[3];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.VendorName column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VendorName
    {
        get
        {
            return MvwISDVendorXrefView.Instance.VendorNameColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.IsSubcontractor column object.
    /// </summary>
    public BaseClasses.Data.StringColumn IsSubcontractorColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[4];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.IsSubcontractor column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn IsSubcontractor
    {
        get
        {
            return MvwISDVendorXrefView.Instance.IsSubcontractorColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.Address column object.
    /// </summary>
    public BaseClasses.Data.StringColumn AddressColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[5];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.Address column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Address
    {
        get
        {
            return MvwISDVendorXrefView.Instance.AddressColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.Address2 column object.
    /// </summary>
    public BaseClasses.Data.StringColumn Address2Column
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[6];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.Address2 column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Address2
    {
        get
        {
            return MvwISDVendorXrefView.Instance.Address2Column;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.City column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CityColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[7];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.City column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn City
    {
        get
        {
            return MvwISDVendorXrefView.Instance.CityColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.State column object.
    /// </summary>
    public BaseClasses.Data.UsaStateColumn StateColumn
    {
        get
        {
            return (BaseClasses.Data.UsaStateColumn)this.TableDefinition.ColumnList[8];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.State column object.
    /// </summary>
    public static BaseClasses.Data.UsaStateColumn State
    {
        get
        {
            return MvwISDVendorXrefView.Instance.StateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.Zip column object.
    /// </summary>
    public BaseClasses.Data.UsaZipCodeColumn ZipColumn
    {
        get
        {
            return (BaseClasses.Data.UsaZipCodeColumn)this.TableDefinition.ColumnList[9];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.Zip column object.
    /// </summary>
    public static BaseClasses.Data.UsaZipCodeColumn Zip
    {
        get
        {
            return MvwISDVendorXrefView.Instance.ZipColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.VendorKey column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VendorKeyColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[10];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDVendorXref_.VendorKey column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VendorKey
    {
        get
        {
            return MvwISDVendorXrefView.Instance.VendorKeyColumn;
        }
    }
    
    


#endregion

    
#region "Shared helper methods"

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDVendorXrefRecord records using a where clause.
    /// </summary>
    public static MvwISDVendorXrefRecord[] GetRecords(string where)
    {
        return GetRecords(where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDVendorXrefRecord records using a where clause.
    /// </summary>
    public static MvwISDVendorXrefRecord[] GetRecords(BaseFilter join, string where)
    {
        return GetRecords(join, where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDVendorXrefRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDVendorXrefRecord[] GetRecords(string where, OrderBy orderBy)
    {
        return GetRecords(where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
     /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDVendorXrefRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDVendorXrefRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy)
    {
        return GetRecords(join, where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }    
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDVendorXrefRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDVendorXrefRecord[] GetRecords(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDVendorXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDVendorXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDVendorXrefRecord"));
    }   
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDVendorXrefRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDVendorXrefRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        ArrayList recList = MvwISDVendorXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDVendorXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDVendorXrefRecord"));
    }   


    public static MvwISDVendorXrefRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDVendorXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDVendorXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDVendorXrefRecord"));
    }

    public static MvwISDVendorXrefRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{

        ArrayList recList = MvwISDVendorXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDVendorXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDVendorXrefRecord"));
    }


    public static MvwISDVendorXrefRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDVendorXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDVendorXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDVendorXrefRecord"));
    }

    public static MvwISDVendorXrefRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{

        ArrayList recList = MvwISDVendorXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDVendorXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDVendorXrefRecord"));
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

        return (int)MvwISDVendorXrefView.Instance.GetRecordListCount(null, whereFilter, null, null);
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

        return (int)MvwISDVendorXrefView.Instance.GetRecordListCount(join, whereFilter, null, null);
    }

    
    public static int GetRecordCount(WhereClause where)
    {
        return (int)MvwISDVendorXrefView.Instance.GetRecordListCount(null, where.GetFilter(), null, null);
    }
    
    public static int GetRecordCount(BaseFilter join, WhereClause where)
    {
        return (int)MvwISDVendorXrefView.Instance.GetRecordListCount(join, where.GetFilter(), null, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDVendorXrefRecord record using a where clause.
    /// </summary>
    public static MvwISDVendorXrefRecord GetRecord(string where)
    {
        OrderBy orderBy = null;
        return GetRecord(where, orderBy);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDVendorXrefRecord record using a where clause.
    /// </summary>
    public static MvwISDVendorXrefRecord GetRecord(BaseFilter join, string where)
    {
        OrderBy orderBy = null;
        return GetRecord(join, where, orderBy);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDVendorXrefRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDVendorXrefRecord GetRecord(string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;  
        ArrayList recList = MvwISDVendorXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDVendorXrefRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDVendorXrefRecord)recList[0];
        }

        return rec;
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDVendorXrefRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDVendorXrefRecord GetRecord(BaseFilter join, string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        
        ArrayList recList = MvwISDVendorXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDVendorXrefRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDVendorXrefRecord)recList[0];
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

        return MvwISDVendorXrefView.Instance.GetColumnValues(retCol, null, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

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

        return MvwISDVendorXrefView.Instance.GetColumnValues(retCol, join, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

    }
      
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where)
    {
        MvwISDVendorXrefRecord[] recs = GetRecords(where);
        return  MvwISDVendorXrefView.Instance.CreateDataTable(recs, null);
    }

    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where)
    {
        MvwISDVendorXrefRecord[] recs = GetRecords(join, where);
        return  MvwISDVendorXrefView.Instance.CreateDataTable(recs, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy)
    {
        MvwISDVendorXrefRecord[] recs = GetRecords(where, orderBy);
        return  MvwISDVendorXrefView.Instance.CreateDataTable(recs, null);
    }
   
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy)
    {
        MvwISDVendorXrefRecord[] recs = GetRecords(join, where, orderBy);
        return  MvwISDVendorXrefView.Instance.CreateDataTable(recs, null);
    }
   
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDVendorXrefRecord[] recs = GetRecords(where, orderBy, pageIndex, pageSize);
        return  MvwISDVendorXrefView.Instance.CreateDataTable(recs, null);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDVendorXrefRecord[] recs = GetRecords(join, where, orderBy, pageIndex, pageSize);
        return  MvwISDVendorXrefView.Instance.CreateDataTable(recs, null);
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
        MvwISDVendorXrefView.Instance.DeleteRecordList(whereFilter);
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
        
        return  MvwISDVendorXrefView.Instance.ExportRecordData(whereFilter);
    }
   
    public static string Export(WhereClause where)
    {
        BaseFilter whereFilter = null;
        if (where != null)
        {
            whereFilter = where.GetFilter();
        }

        return MvwISDVendorXrefView.Instance.ExportRecordData(whereFilter);
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

        return MvwISDVendorXrefView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDVendorXrefView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDVendorXrefView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDVendorXrefView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }

    /// <summary>
    ///  This method returns the columns in the table.
    /// </summary>
    public static BaseColumn[] GetColumns() 
    {
        return MvwISDVendorXrefView.Instance.TableDefinition.Columns;
    }

    /// <summary>
    ///  This method returns the columnlist in the table.
    /// </summary>   
    public static ColumnList GetColumnList() 
    {
        return MvwISDVendorXrefView.Instance.TableDefinition.ColumnList;
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    public static IRecord CreateNewRecord() 
    {
        return MvwISDVendorXrefView.Instance.CreateRecord();
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    /// <param name="tempId">ID of the new record.</param>   
    public static IRecord CreateNewRecord(string tempId) 
    {
        return MvwISDVendorXrefView.Instance.CreateRecord(tempId);
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
        BaseColumn column = MvwISDVendorXrefView.Instance.TableDefinition.ColumnList.GetByUniqueName(uniqueColumnName);
        return column;
    }
    
    /// <summary>
    /// This method gets the specified column.
    /// </summary>
    /// <param name="name">name of the column to fetch.</param>
    public static BaseColumn GetColumnByName(string name)
    {
        BaseColumn column = MvwISDVendorXrefView.Instance.TableDefinition.ColumnList.GetByInternalName(name);
        return column;
    } 

        //Convenience method for getting a record using a string-based record identifier
        public static MvwISDVendorXrefRecord GetRecord(string id, bool bMutable)
        {
            return (MvwISDVendorXrefRecord)MvwISDVendorXrefView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for getting a record using a KeyValue record identifier
        public static MvwISDVendorXrefRecord GetRecord(KeyValue id, bool bMutable)
        {
            return (MvwISDVendorXrefRecord)MvwISDVendorXrefView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for creating a record
        public KeyValue NewRecord(
        string VendorGroupValue, 
        string VPVendorValue, 
        string CGCVendorValue, 
        string VendorNameValue, 
        string IsSubcontractorValue, 
        string AddressValue, 
        string Address2Value, 
        string CityValue, 
        string StateValue, 
        string ZipValue, 
        string VendorKeyValue
    )
        {
            IPrimaryKeyRecord rec = (IPrimaryKeyRecord)this.CreateRecord();
                    rec.SetString(VendorGroupValue, VendorGroupColumn);
        rec.SetString(VPVendorValue, VPVendorColumn);
        rec.SetString(CGCVendorValue, CGCVendorColumn);
        rec.SetString(VendorNameValue, VendorNameColumn);
        rec.SetString(IsSubcontractorValue, IsSubcontractorColumn);
        rec.SetString(AddressValue, AddressColumn);
        rec.SetString(Address2Value, Address2Column);
        rec.SetString(CityValue, CityColumn);
        rec.SetString(StateValue, StateColumn);
        rec.SetString(ZipValue, ZipColumn);
        rec.SetString(VendorKeyValue, VendorKeyColumn);


            rec.Create(); //update the DB so any DB-initialized fields (like autoincrement IDs) can be initialized

            return rec.GetID();
        }
        
        /// <summary>
		///  This method deletes a specified record
		/// </summary>
		/// <param name="kv">Keyvalue of the record to be deleted.</param>
		public static void DeleteRecord(KeyValue kv)
		{
			MvwISDVendorXrefView.Instance.DeleteOneRecord(kv);
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
				MvwISDVendorXrefView.GetRecord(kv, false);
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
            if (!(MvwISDVendorXrefView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                return MvwISDVendorXrefView.Instance.TableDefinition.PrimaryKey.Columns;
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
            if (!(MvwISDVendorXrefView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                bool isCompositePrimaryKey = false;
                isCompositePrimaryKey = MvwISDVendorXrefView.Instance.TableDefinition.PrimaryKey.IsCompositeKey;
                if ((isCompositePrimaryKey && key.GetType().IsArray)) 
                {
                    //  If the key is composite, then construct a key value.
                    kv = new KeyValue();
                    Array keyArray = ((Array)(key));
                    if (!(keyArray == null)) 
                    {
                        int length = keyArray.Length;
                        ColumnList pkColumns = MvwISDVendorXrefView.Instance.TableDefinition.PrimaryKey.Columns;
                        int index = 0;
                        foreach (BaseColumn pkColumn in pkColumns) 
                        {
                            string keyString = ((keyArray.GetValue(index)).ToString());
                            if (MvwISDVendorXrefView.Instance.TableDefinition.TableType == BaseClasses.Data.TableDefinition.TableTypes.Virtual)
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
                    kv = MvwISDVendorXrefView.Instance.TableDefinition.PrimaryKey.ParseValue(((key).ToString()));
                }
            }
            return kv;
        }
        
        /// <summary>
        /// This method takes a record and a Column and returns an evaluated value of DFKA formula.
        /// </summary>
        public static string GetDFKA(BaseRecord rec, BaseColumn col)
		{
			ForeignKey fkColumn = MvwISDVendorXrefView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
			ForeignKey fkColumn = MvwISDVendorXrefView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
