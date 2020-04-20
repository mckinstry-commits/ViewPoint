// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDCustomerXrefView.cs


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
/// The generated superclass for the <see cref="MvwISDCustomerXrefView"></see> class.
/// Provides access to the schema information and record data of a database table or view named DatabaseViewpoint%dbo.mvwISDCustomerXref.
/// </summary>
/// <remarks>
/// The connection details (name, location, etc.) of the database and table (or view) accessed by this class 
/// are resolved at runtime based on the connection string in the application's Web.Config file.
/// <para>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, use 
/// <see cref="MvwISDCustomerXrefView.Instance">MvwISDCustomerXrefView.Instance</see>.
/// </para>
/// </remarks>
/// <seealso cref="MvwISDCustomerXrefView"></seealso>
[SerializableAttribute()]
public class BaseMvwISDCustomerXrefView : PrimaryKeyTable
{

    private readonly string TableDefinitionString = MvwISDCustomerXrefDefinition.GetXMLString();







    protected BaseMvwISDCustomerXrefView()
    {
        this.Initialize();
    }

    protected virtual void Initialize()
    {
        XmlTableDefinition def = new XmlTableDefinition(TableDefinitionString);
        this.TableDefinition = new TableDefinition();
        this.TableDefinition.TableClassName = System.Reflection.Assembly.CreateQualifiedName("VPLookup.Business", "VPLookup.Business.MvwISDCustomerXrefView");
        def.InitializeTableDefinition(this.TableDefinition);
        this.ConnectionName = def.GetConnectionName();
        this.RecordClassName = System.Reflection.Assembly.CreateQualifiedName("VPLookup.Business", "VPLookup.Business.MvwISDCustomerXrefRecord");
        this.ApplicationName = "VPLookup";
        this.DataAdapter = new MvwISDCustomerXrefSqlView();
        ((MvwISDCustomerXrefSqlView)this.DataAdapter).ConnectionName = this.ConnectionName;
		
        this.TableDefinition.AdapterMetaData = this.DataAdapter.AdapterMetaData;
        CustGroupColumn.CodeName = "CustGroup";
        VPCustomerColumn.CodeName = "VPCustomer";
        CGCCustomerColumn.CodeName = "CGCCustomer";
        AsteaCustomerColumn.CodeName = "AsteaCustomer";
        CustomerNameColumn.CodeName = "CustomerName";
        AddressColumn.CodeName = "Address";
        Address2Column.CodeName = "Address2";
        CityColumn.CodeName = "City";
        StateColumn.CodeName = "State";
        ZipColumn.CodeName = "Zip";
        CustomerKeyColumn.CodeName = "CustomerKey";

        
    }
    
#region "Overriden methods"
	
#endregion    

#region "Properties for columns"

    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.CustGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn CustGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[0];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.CustGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn CustGroup
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.CustGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.VPCustomer column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VPCustomerColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[1];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.VPCustomer column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn VPCustomer
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.VPCustomerColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.CGCCustomer column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CGCCustomerColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[2];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.CGCCustomer column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CGCCustomer
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.CGCCustomerColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.AsteaCustomer column object.
    /// </summary>
    public BaseClasses.Data.StringColumn AsteaCustomerColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[3];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.AsteaCustomer column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn AsteaCustomer
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.AsteaCustomerColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.CustomerName column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CustomerNameColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[4];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.CustomerName column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CustomerName
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.CustomerNameColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.Address column object.
    /// </summary>
    public BaseClasses.Data.StringColumn AddressColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[5];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.Address column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Address
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.AddressColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.Address2 column object.
    /// </summary>
    public BaseClasses.Data.StringColumn Address2Column
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[6];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.Address2 column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Address2
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.Address2Column;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.City column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CityColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[7];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.City column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn City
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.CityColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.State column object.
    /// </summary>
    public BaseClasses.Data.UsaStateColumn StateColumn
    {
        get
        {
            return (BaseClasses.Data.UsaStateColumn)this.TableDefinition.ColumnList[8];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.State column object.
    /// </summary>
    public static BaseClasses.Data.UsaStateColumn State
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.StateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.Zip column object.
    /// </summary>
    public BaseClasses.Data.UsaZipCodeColumn ZipColumn
    {
        get
        {
            return (BaseClasses.Data.UsaZipCodeColumn)this.TableDefinition.ColumnList[9];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.Zip column object.
    /// </summary>
    public static BaseClasses.Data.UsaZipCodeColumn Zip
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.ZipColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.CustomerKey column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CustomerKeyColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[10];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDCustomerXref_.CustomerKey column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CustomerKey
    {
        get
        {
            return MvwISDCustomerXrefView.Instance.CustomerKeyColumn;
        }
    }
    
    


#endregion

    
#region "Shared helper methods"

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDCustomerXrefRecord records using a where clause.
    /// </summary>
    public static MvwISDCustomerXrefRecord[] GetRecords(string where)
    {
        return GetRecords(where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDCustomerXrefRecord records using a where clause.
    /// </summary>
    public static MvwISDCustomerXrefRecord[] GetRecords(BaseFilter join, string where)
    {
        return GetRecords(join, where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDCustomerXrefRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDCustomerXrefRecord[] GetRecords(string where, OrderBy orderBy)
    {
        return GetRecords(where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
     /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDCustomerXrefRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDCustomerXrefRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy)
    {
        return GetRecords(join, where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }    
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDCustomerXrefRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDCustomerXrefRecord[] GetRecords(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDCustomerXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDCustomerXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDCustomerXrefRecord"));
    }   
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDCustomerXrefRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDCustomerXrefRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        ArrayList recList = MvwISDCustomerXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDCustomerXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDCustomerXrefRecord"));
    }   


    public static MvwISDCustomerXrefRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDCustomerXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDCustomerXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDCustomerXrefRecord"));
    }

    public static MvwISDCustomerXrefRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{

        ArrayList recList = MvwISDCustomerXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDCustomerXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDCustomerXrefRecord"));
    }


    public static MvwISDCustomerXrefRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDCustomerXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDCustomerXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDCustomerXrefRecord"));
    }

    public static MvwISDCustomerXrefRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{

        ArrayList recList = MvwISDCustomerXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDCustomerXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDCustomerXrefRecord"));
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

        return (int)MvwISDCustomerXrefView.Instance.GetRecordListCount(null, whereFilter, null, null);
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

        return (int)MvwISDCustomerXrefView.Instance.GetRecordListCount(join, whereFilter, null, null);
    }

    
    public static int GetRecordCount(WhereClause where)
    {
        return (int)MvwISDCustomerXrefView.Instance.GetRecordListCount(null, where.GetFilter(), null, null);
    }
    
    public static int GetRecordCount(BaseFilter join, WhereClause where)
    {
        return (int)MvwISDCustomerXrefView.Instance.GetRecordListCount(join, where.GetFilter(), null, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDCustomerXrefRecord record using a where clause.
    /// </summary>
    public static MvwISDCustomerXrefRecord GetRecord(string where)
    {
        OrderBy orderBy = null;
        return GetRecord(where, orderBy);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDCustomerXrefRecord record using a where clause.
    /// </summary>
    public static MvwISDCustomerXrefRecord GetRecord(BaseFilter join, string where)
    {
        OrderBy orderBy = null;
        return GetRecord(join, where, orderBy);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDCustomerXrefRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDCustomerXrefRecord GetRecord(string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;  
        ArrayList recList = MvwISDCustomerXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDCustomerXrefRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDCustomerXrefRecord)recList[0];
        }

        return rec;
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDCustomerXrefRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDCustomerXrefRecord GetRecord(BaseFilter join, string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        
        ArrayList recList = MvwISDCustomerXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDCustomerXrefRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDCustomerXrefRecord)recList[0];
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

        return MvwISDCustomerXrefView.Instance.GetColumnValues(retCol, null, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

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

        return MvwISDCustomerXrefView.Instance.GetColumnValues(retCol, join, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

    }
      
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where)
    {
        MvwISDCustomerXrefRecord[] recs = GetRecords(where);
        return  MvwISDCustomerXrefView.Instance.CreateDataTable(recs, null);
    }

    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where)
    {
        MvwISDCustomerXrefRecord[] recs = GetRecords(join, where);
        return  MvwISDCustomerXrefView.Instance.CreateDataTable(recs, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy)
    {
        MvwISDCustomerXrefRecord[] recs = GetRecords(where, orderBy);
        return  MvwISDCustomerXrefView.Instance.CreateDataTable(recs, null);
    }
   
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy)
    {
        MvwISDCustomerXrefRecord[] recs = GetRecords(join, where, orderBy);
        return  MvwISDCustomerXrefView.Instance.CreateDataTable(recs, null);
    }
   
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDCustomerXrefRecord[] recs = GetRecords(where, orderBy, pageIndex, pageSize);
        return  MvwISDCustomerXrefView.Instance.CreateDataTable(recs, null);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDCustomerXrefRecord[] recs = GetRecords(join, where, orderBy, pageIndex, pageSize);
        return  MvwISDCustomerXrefView.Instance.CreateDataTable(recs, null);
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
        MvwISDCustomerXrefView.Instance.DeleteRecordList(whereFilter);
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
        
        return  MvwISDCustomerXrefView.Instance.ExportRecordData(whereFilter);
    }
   
    public static string Export(WhereClause where)
    {
        BaseFilter whereFilter = null;
        if (where != null)
        {
            whereFilter = where.GetFilter();
        }

        return MvwISDCustomerXrefView.Instance.ExportRecordData(whereFilter);
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

        return MvwISDCustomerXrefView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDCustomerXrefView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDCustomerXrefView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDCustomerXrefView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }

    /// <summary>
    ///  This method returns the columns in the table.
    /// </summary>
    public static BaseColumn[] GetColumns() 
    {
        return MvwISDCustomerXrefView.Instance.TableDefinition.Columns;
    }

    /// <summary>
    ///  This method returns the columnlist in the table.
    /// </summary>   
    public static ColumnList GetColumnList() 
    {
        return MvwISDCustomerXrefView.Instance.TableDefinition.ColumnList;
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    public static IRecord CreateNewRecord() 
    {
        return MvwISDCustomerXrefView.Instance.CreateRecord();
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    /// <param name="tempId">ID of the new record.</param>   
    public static IRecord CreateNewRecord(string tempId) 
    {
        return MvwISDCustomerXrefView.Instance.CreateRecord(tempId);
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
        BaseColumn column = MvwISDCustomerXrefView.Instance.TableDefinition.ColumnList.GetByUniqueName(uniqueColumnName);
        return column;
    }
    
    /// <summary>
    /// This method gets the specified column.
    /// </summary>
    /// <param name="name">name of the column to fetch.</param>
    public static BaseColumn GetColumnByName(string name)
    {
        BaseColumn column = MvwISDCustomerXrefView.Instance.TableDefinition.ColumnList.GetByInternalName(name);
        return column;
    } 

        //Convenience method for getting a record using a string-based record identifier
        public static MvwISDCustomerXrefRecord GetRecord(string id, bool bMutable)
        {
            return (MvwISDCustomerXrefRecord)MvwISDCustomerXrefView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for getting a record using a KeyValue record identifier
        public static MvwISDCustomerXrefRecord GetRecord(KeyValue id, bool bMutable)
        {
            return (MvwISDCustomerXrefRecord)MvwISDCustomerXrefView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for creating a record
        public KeyValue NewRecord(
        string CustGroupValue, 
        string VPCustomerValue, 
        string CGCCustomerValue, 
        string AsteaCustomerValue, 
        string CustomerNameValue, 
        string AddressValue, 
        string Address2Value, 
        string CityValue, 
        string StateValue, 
        string ZipValue, 
        string CustomerKeyValue
    )
        {
            IPrimaryKeyRecord rec = (IPrimaryKeyRecord)this.CreateRecord();
                    rec.SetString(CustGroupValue, CustGroupColumn);
        rec.SetString(VPCustomerValue, VPCustomerColumn);
        rec.SetString(CGCCustomerValue, CGCCustomerColumn);
        rec.SetString(AsteaCustomerValue, AsteaCustomerColumn);
        rec.SetString(CustomerNameValue, CustomerNameColumn);
        rec.SetString(AddressValue, AddressColumn);
        rec.SetString(Address2Value, Address2Column);
        rec.SetString(CityValue, CityColumn);
        rec.SetString(StateValue, StateColumn);
        rec.SetString(ZipValue, ZipColumn);
        rec.SetString(CustomerKeyValue, CustomerKeyColumn);


            rec.Create(); //update the DB so any DB-initialized fields (like autoincrement IDs) can be initialized

            return rec.GetID();
        }
        
        /// <summary>
		///  This method deletes a specified record
		/// </summary>
		/// <param name="kv">Keyvalue of the record to be deleted.</param>
		public static void DeleteRecord(KeyValue kv)
		{
			MvwISDCustomerXrefView.Instance.DeleteOneRecord(kv);
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
				MvwISDCustomerXrefView.GetRecord(kv, false);
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
            if (!(MvwISDCustomerXrefView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                return MvwISDCustomerXrefView.Instance.TableDefinition.PrimaryKey.Columns;
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
            if (!(MvwISDCustomerXrefView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                bool isCompositePrimaryKey = false;
                isCompositePrimaryKey = MvwISDCustomerXrefView.Instance.TableDefinition.PrimaryKey.IsCompositeKey;
                if ((isCompositePrimaryKey && key.GetType().IsArray)) 
                {
                    //  If the key is composite, then construct a key value.
                    kv = new KeyValue();
                    Array keyArray = ((Array)(key));
                    if (!(keyArray == null)) 
                    {
                        int length = keyArray.Length;
                        ColumnList pkColumns = MvwISDCustomerXrefView.Instance.TableDefinition.PrimaryKey.Columns;
                        int index = 0;
                        foreach (BaseColumn pkColumn in pkColumns) 
                        {
                            string keyString = ((keyArray.GetValue(index)).ToString());
                            if (MvwISDCustomerXrefView.Instance.TableDefinition.TableType == BaseClasses.Data.TableDefinition.TableTypes.Virtual)
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
                    kv = MvwISDCustomerXrefView.Instance.TableDefinition.PrimaryKey.ParseValue(((key).ToString()));
                }
            }
            return kv;
        }
        
        /// <summary>
        /// This method takes a record and a Column and returns an evaluated value of DFKA formula.
        /// </summary>
        public static string GetDFKA(BaseRecord rec, BaseColumn col)
		{
			ForeignKey fkColumn = MvwISDCustomerXrefView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
			ForeignKey fkColumn = MvwISDCustomerXrefView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
