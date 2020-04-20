// This class is "generated" and will be overwritten.
// Your customizations should be made in MvwISDJobXrefView.cs


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
/// The generated superclass for the <see cref="MvwISDJobXrefView"></see> class.
/// Provides access to the schema information and record data of a database table or view named DatabaseViewpoint%dbo.mvwISDJobXref.
/// </summary>
/// <remarks>
/// The connection details (name, location, etc.) of the database and table (or view) accessed by this class 
/// are resolved at runtime based on the connection string in the application's Web.Config file.
/// <para>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, use 
/// <see cref="MvwISDJobXrefView.Instance">MvwISDJobXrefView.Instance</see>.
/// </para>
/// </remarks>
/// <seealso cref="MvwISDJobXrefView"></seealso>
[SerializableAttribute()]
public class BaseMvwISDJobXrefView : PrimaryKeyTable
{

    private readonly string TableDefinitionString = MvwISDJobXrefDefinition.GetXMLString();







    protected BaseMvwISDJobXrefView()
    {
        this.Initialize();
    }

    protected virtual void Initialize()
    {
        XmlTableDefinition def = new XmlTableDefinition(TableDefinitionString);
        this.TableDefinition = new TableDefinition();
        this.TableDefinition.TableClassName = System.Reflection.Assembly.CreateQualifiedName("VPLookup.Business", "VPLookup.Business.MvwISDJobXrefView");
        def.InitializeTableDefinition(this.TableDefinition);
        this.ConnectionName = def.GetConnectionName();
        this.RecordClassName = System.Reflection.Assembly.CreateQualifiedName("VPLookup.Business", "VPLookup.Business.MvwISDJobXrefRecord");
        this.ApplicationName = "VPLookup";
        this.DataAdapter = new MvwISDJobXrefSqlView();
        ((MvwISDJobXrefSqlView)this.DataAdapter).ConnectionName = this.ConnectionName;
		
        this.TableDefinition.AdapterMetaData = this.DataAdapter.AdapterMetaData;
        VPCoColumn.CodeName = "VPCo";
        VPJobColumn.CodeName = "VPJob";
        CGCCoColumn.CodeName = "CGCCo";
        CGCJobColumn.CodeName = "CGCJob";
        VPJobDescColumn.CodeName = "VPJobDesc";
        VPCustomerColumn.CodeName = "VPCustomer";
        VPCustomerNameColumn.CodeName = "VPCustomerName";
        MailAddressColumn.CodeName = "MailAddress";
        MailAddress2Column.CodeName = "MailAddress2";
        MailCityColumn.CodeName = "MailCity";
        MailStateColumn.CodeName = "MailState";
        MailZipColumn.CodeName = "MailZip";
        POCColumn.CodeName = "POC";
        POCNameColumn.CodeName = "POCName";
        POCEmailColumn.CodeName = "POCEmail";
        SalesPersonColumn.CodeName = "SalesPerson";
        SalesPersonNameColumn.CodeName = "SalesPersonName";
        SalesPersonEmailColumn.CodeName = "SalesPersonEmail";
        JobKeyColumn.CodeName = "JobKey";
        CustomerKeyColumn.CodeName = "CustomerKey";
        PhaseGroupColumn.CodeName = "PhaseGroup";
        JobStatusColumn.CodeName = "JobStatus";
        GLDepartmentNumberColumn.CodeName = "GLDepartmentNumber";
        GLDepartmentNameColumn.CodeName = "GLDepartmentName";

        
    }
    
#region "Overriden methods"
	
#endregion    

#region "Properties for columns"

    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VPCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[0];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn VPCo
    {
        get
        {
            return MvwISDJobXrefView.Instance.VPCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPJob column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VPJobColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[1];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPJob column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VPJob
    {
        get
        {
            return MvwISDJobXrefView.Instance.VPJobColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.CGCCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn CGCCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[2];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.CGCCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn CGCCo
    {
        get
        {
            return MvwISDJobXrefView.Instance.CGCCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.CGCJob column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CGCJobColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[3];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.CGCJob column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CGCJob
    {
        get
        {
            return MvwISDJobXrefView.Instance.CGCJobColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPJobDesc column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VPJobDescColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[4];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPJobDesc column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VPJobDesc
    {
        get
        {
            return MvwISDJobXrefView.Instance.VPJobDescColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPCustomer column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VPCustomerColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[5];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPCustomer column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn VPCustomer
    {
        get
        {
            return MvwISDJobXrefView.Instance.VPCustomerColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPCustomerName column object.
    /// </summary>
    public BaseClasses.Data.StringColumn VPCustomerNameColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[6];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.VPCustomerName column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn VPCustomerName
    {
        get
        {
            return MvwISDJobXrefView.Instance.VPCustomerNameColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailAddress column object.
    /// </summary>
    public BaseClasses.Data.StringColumn MailAddressColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[7];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailAddress column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn MailAddress
    {
        get
        {
            return MvwISDJobXrefView.Instance.MailAddressColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailAddress2 column object.
    /// </summary>
    public BaseClasses.Data.StringColumn MailAddress2Column
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[8];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailAddress2 column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn MailAddress2
    {
        get
        {
            return MvwISDJobXrefView.Instance.MailAddress2Column;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailCity column object.
    /// </summary>
    public BaseClasses.Data.StringColumn MailCityColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[9];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailCity column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn MailCity
    {
        get
        {
            return MvwISDJobXrefView.Instance.MailCityColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailState column object.
    /// </summary>
    public BaseClasses.Data.StringColumn MailStateColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[10];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailState column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn MailState
    {
        get
        {
            return MvwISDJobXrefView.Instance.MailStateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailZip column object.
    /// </summary>
    public BaseClasses.Data.UsaZipCodeColumn MailZipColumn
    {
        get
        {
            return (BaseClasses.Data.UsaZipCodeColumn)this.TableDefinition.ColumnList[11];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.MailZip column object.
    /// </summary>
    public static BaseClasses.Data.UsaZipCodeColumn MailZip
    {
        get
        {
            return MvwISDJobXrefView.Instance.MailZipColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.POC column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn POCColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[12];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.POC column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn POC
    {
        get
        {
            return MvwISDJobXrefView.Instance.POCColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.POCName column object.
    /// </summary>
    public BaseClasses.Data.StringColumn POCNameColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[13];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.POCName column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn POCName
    {
        get
        {
            return MvwISDJobXrefView.Instance.POCNameColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.POCEmail column object.
    /// </summary>
    public BaseClasses.Data.EmailColumn POCEmailColumn
    {
        get
        {
            return (BaseClasses.Data.EmailColumn)this.TableDefinition.ColumnList[14];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.POCEmail column object.
    /// </summary>
    public static BaseClasses.Data.EmailColumn POCEmail
    {
        get
        {
            return MvwISDJobXrefView.Instance.POCEmailColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.SalesPerson column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn SalesPersonColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[15];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.SalesPerson column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn SalesPerson
    {
        get
        {
            return MvwISDJobXrefView.Instance.SalesPersonColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.SalesPersonName column object.
    /// </summary>
    public BaseClasses.Data.StringColumn SalesPersonNameColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[16];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.SalesPersonName column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn SalesPersonName
    {
        get
        {
            return MvwISDJobXrefView.Instance.SalesPersonNameColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.SalesPersonEmail column object.
    /// </summary>
    public BaseClasses.Data.EmailColumn SalesPersonEmailColumn
    {
        get
        {
            return (BaseClasses.Data.EmailColumn)this.TableDefinition.ColumnList[17];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.SalesPersonEmail column object.
    /// </summary>
    public static BaseClasses.Data.EmailColumn SalesPersonEmail
    {
        get
        {
            return MvwISDJobXrefView.Instance.SalesPersonEmailColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.JobKey column object.
    /// </summary>
    public BaseClasses.Data.StringColumn JobKeyColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[18];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.JobKey column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn JobKey
    {
        get
        {
            return MvwISDJobXrefView.Instance.JobKeyColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.CustomerKey column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CustomerKeyColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[19];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.CustomerKey column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CustomerKey
    {
        get
        {
            return MvwISDJobXrefView.Instance.CustomerKeyColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.PhaseGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn PhaseGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[20];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.PhaseGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn PhaseGroup
    {
        get
        {
            return MvwISDJobXrefView.Instance.PhaseGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.JobStatus column object.
    /// </summary>
    public BaseClasses.Data.StringColumn JobStatusColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[21];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.JobStatus column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn JobStatus
    {
        get
        {
            return MvwISDJobXrefView.Instance.JobStatusColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.GLDepartmentNumber column object.
    /// </summary>
    public BaseClasses.Data.StringColumn GLDepartmentNumberColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[22];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.GLDepartmentNumber column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn GLDepartmentNumber
    {
        get
        {
            return MvwISDJobXrefView.Instance.GLDepartmentNumberColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.GLDepartmentName column object.
    /// </summary>
    public BaseClasses.Data.StringColumn GLDepartmentNameColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[23];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's mvwISDJobXref_.GLDepartmentName column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn GLDepartmentName
    {
        get
        {
            return MvwISDJobXrefView.Instance.GLDepartmentNameColumn;
        }
    }
    
    


#endregion

    
#region "Shared helper methods"

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobXrefRecord records using a where clause.
    /// </summary>
    public static MvwISDJobXrefRecord[] GetRecords(string where)
    {
        return GetRecords(where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobXrefRecord records using a where clause.
    /// </summary>
    public static MvwISDJobXrefRecord[] GetRecords(BaseFilter join, string where)
    {
        return GetRecords(join, where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    

    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobXrefRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDJobXrefRecord[] GetRecords(string where, OrderBy orderBy)
    {
        return GetRecords(where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
     /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobXrefRecord records using a where and order by clause.
    /// </summary>
    public static MvwISDJobXrefRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy)
    {
        return GetRecords(join, where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }    
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobXrefRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDJobXrefRecord[] GetRecords(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDJobXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDJobXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDJobXrefRecord"));
    }   
    
    /// <summary>
    /// This is a shared function that can be used to get an array of MvwISDJobXrefRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static MvwISDJobXrefRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        ArrayList recList = MvwISDJobXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (MvwISDJobXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDJobXrefRecord"));
    }   


    public static MvwISDJobXrefRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDJobXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDJobXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDJobXrefRecord"));
    }

    public static MvwISDJobXrefRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{

        ArrayList recList = MvwISDJobXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (MvwISDJobXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDJobXrefRecord"));
    }


    public static MvwISDJobXrefRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = MvwISDJobXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDJobXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDJobXrefRecord"));
    }

    public static MvwISDJobXrefRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{

        ArrayList recList = MvwISDJobXrefView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (MvwISDJobXrefRecord[])recList.ToArray(Type.GetType("VPLookup.Business.MvwISDJobXrefRecord"));
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

        return (int)MvwISDJobXrefView.Instance.GetRecordListCount(null, whereFilter, null, null);
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

        return (int)MvwISDJobXrefView.Instance.GetRecordListCount(join, whereFilter, null, null);
    }

    
    public static int GetRecordCount(WhereClause where)
    {
        return (int)MvwISDJobXrefView.Instance.GetRecordListCount(null, where.GetFilter(), null, null);
    }
    
    public static int GetRecordCount(BaseFilter join, WhereClause where)
    {
        return (int)MvwISDJobXrefView.Instance.GetRecordListCount(join, where.GetFilter(), null, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDJobXrefRecord record using a where clause.
    /// </summary>
    public static MvwISDJobXrefRecord GetRecord(string where)
    {
        OrderBy orderBy = null;
        return GetRecord(where, orderBy);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDJobXrefRecord record using a where clause.
    /// </summary>
    public static MvwISDJobXrefRecord GetRecord(BaseFilter join, string where)
    {
        OrderBy orderBy = null;
        return GetRecord(join, where, orderBy);
    }


    /// <summary>
    /// This is a shared function that can be used to get a MvwISDJobXrefRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDJobXrefRecord GetRecord(string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;  
        ArrayList recList = MvwISDJobXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDJobXrefRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDJobXrefRecord)recList[0];
        }

        return rec;
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a MvwISDJobXrefRecord record using a where and order by clause.
    /// </summary>
    public static MvwISDJobXrefRecord GetRecord(BaseFilter join, string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        
        ArrayList recList = MvwISDJobXrefView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        MvwISDJobXrefRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (MvwISDJobXrefRecord)recList[0];
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

        return MvwISDJobXrefView.Instance.GetColumnValues(retCol, null, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

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

        return MvwISDJobXrefView.Instance.GetColumnValues(retCol, join, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

    }
      
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where)
    {
        MvwISDJobXrefRecord[] recs = GetRecords(where);
        return  MvwISDJobXrefView.Instance.CreateDataTable(recs, null);
    }

    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where)
    {
        MvwISDJobXrefRecord[] recs = GetRecords(join, where);
        return  MvwISDJobXrefView.Instance.CreateDataTable(recs, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy)
    {
        MvwISDJobXrefRecord[] recs = GetRecords(where, orderBy);
        return  MvwISDJobXrefView.Instance.CreateDataTable(recs, null);
    }
   
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy)
    {
        MvwISDJobXrefRecord[] recs = GetRecords(join, where, orderBy);
        return  MvwISDJobXrefView.Instance.CreateDataTable(recs, null);
    }
   
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDJobXrefRecord[] recs = GetRecords(where, orderBy, pageIndex, pageSize);
        return  MvwISDJobXrefView.Instance.CreateDataTable(recs, null);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        MvwISDJobXrefRecord[] recs = GetRecords(join, where, orderBy, pageIndex, pageSize);
        return  MvwISDJobXrefView.Instance.CreateDataTable(recs, null);
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
        MvwISDJobXrefView.Instance.DeleteRecordList(whereFilter);
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
        
        return  MvwISDJobXrefView.Instance.ExportRecordData(whereFilter);
    }
   
    public static string Export(WhereClause where)
    {
        BaseFilter whereFilter = null;
        if (where != null)
        {
            whereFilter = where.GetFilter();
        }

        return MvwISDJobXrefView.Instance.ExportRecordData(whereFilter);
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

        return MvwISDJobXrefView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDJobXrefView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDJobXrefView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return MvwISDJobXrefView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }

    /// <summary>
    ///  This method returns the columns in the table.
    /// </summary>
    public static BaseColumn[] GetColumns() 
    {
        return MvwISDJobXrefView.Instance.TableDefinition.Columns;
    }

    /// <summary>
    ///  This method returns the columnlist in the table.
    /// </summary>   
    public static ColumnList GetColumnList() 
    {
        return MvwISDJobXrefView.Instance.TableDefinition.ColumnList;
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    public static IRecord CreateNewRecord() 
    {
        return MvwISDJobXrefView.Instance.CreateRecord();
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    /// <param name="tempId">ID of the new record.</param>   
    public static IRecord CreateNewRecord(string tempId) 
    {
        return MvwISDJobXrefView.Instance.CreateRecord(tempId);
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
        BaseColumn column = MvwISDJobXrefView.Instance.TableDefinition.ColumnList.GetByUniqueName(uniqueColumnName);
        return column;
    }
    
    /// <summary>
    /// This method gets the specified column.
    /// </summary>
    /// <param name="name">name of the column to fetch.</param>
    public static BaseColumn GetColumnByName(string name)
    {
        BaseColumn column = MvwISDJobXrefView.Instance.TableDefinition.ColumnList.GetByInternalName(name);
        return column;
    } 

        //Convenience method for getting a record using a string-based record identifier
        public static MvwISDJobXrefRecord GetRecord(string id, bool bMutable)
        {
            return (MvwISDJobXrefRecord)MvwISDJobXrefView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for getting a record using a KeyValue record identifier
        public static MvwISDJobXrefRecord GetRecord(KeyValue id, bool bMutable)
        {
            return (MvwISDJobXrefRecord)MvwISDJobXrefView.Instance.GetRecordData(id, bMutable);
        }

        //Convenience method for creating a record
        public KeyValue NewRecord(
        string VPCoValue, 
        string VPJobValue, 
        string CGCCoValue, 
        string CGCJobValue, 
        string VPJobDescValue, 
        string VPCustomerValue, 
        string VPCustomerNameValue, 
        string MailAddressValue, 
        string MailAddress2Value, 
        string MailCityValue, 
        string MailStateValue, 
        string MailZipValue, 
        string POCValue, 
        string POCNameValue, 
        string POCEmailValue, 
        string SalesPersonValue, 
        string SalesPersonNameValue, 
        string SalesPersonEmailValue, 
        string JobKeyValue, 
        string CustomerKeyValue, 
        string PhaseGroupValue, 
        string JobStatusValue, 
        string GLDepartmentNumberValue, 
        string GLDepartmentNameValue
    )
        {
            IPrimaryKeyRecord rec = (IPrimaryKeyRecord)this.CreateRecord();
                    rec.SetString(VPCoValue, VPCoColumn);
        rec.SetString(VPJobValue, VPJobColumn);
        rec.SetString(CGCCoValue, CGCCoColumn);
        rec.SetString(CGCJobValue, CGCJobColumn);
        rec.SetString(VPJobDescValue, VPJobDescColumn);
        rec.SetString(VPCustomerValue, VPCustomerColumn);
        rec.SetString(VPCustomerNameValue, VPCustomerNameColumn);
        rec.SetString(MailAddressValue, MailAddressColumn);
        rec.SetString(MailAddress2Value, MailAddress2Column);
        rec.SetString(MailCityValue, MailCityColumn);
        rec.SetString(MailStateValue, MailStateColumn);
        rec.SetString(MailZipValue, MailZipColumn);
        rec.SetString(POCValue, POCColumn);
        rec.SetString(POCNameValue, POCNameColumn);
        rec.SetString(POCEmailValue, POCEmailColumn);
        rec.SetString(SalesPersonValue, SalesPersonColumn);
        rec.SetString(SalesPersonNameValue, SalesPersonNameColumn);
        rec.SetString(SalesPersonEmailValue, SalesPersonEmailColumn);
        rec.SetString(JobKeyValue, JobKeyColumn);
        rec.SetString(CustomerKeyValue, CustomerKeyColumn);
        rec.SetString(PhaseGroupValue, PhaseGroupColumn);
        rec.SetString(JobStatusValue, JobStatusColumn);
        rec.SetString(GLDepartmentNumberValue, GLDepartmentNumberColumn);
        rec.SetString(GLDepartmentNameValue, GLDepartmentNameColumn);


            rec.Create(); //update the DB so any DB-initialized fields (like autoincrement IDs) can be initialized

            return rec.GetID();
        }
        
        /// <summary>
		///  This method deletes a specified record
		/// </summary>
		/// <param name="kv">Keyvalue of the record to be deleted.</param>
		public static void DeleteRecord(KeyValue kv)
		{
			MvwISDJobXrefView.Instance.DeleteOneRecord(kv);
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
				MvwISDJobXrefView.GetRecord(kv, false);
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
            if (!(MvwISDJobXrefView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                return MvwISDJobXrefView.Instance.TableDefinition.PrimaryKey.Columns;
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
            if (!(MvwISDJobXrefView.Instance.TableDefinition.PrimaryKey == null)) 
            {
                bool isCompositePrimaryKey = false;
                isCompositePrimaryKey = MvwISDJobXrefView.Instance.TableDefinition.PrimaryKey.IsCompositeKey;
                if ((isCompositePrimaryKey && key.GetType().IsArray)) 
                {
                    //  If the key is composite, then construct a key value.
                    kv = new KeyValue();
                    Array keyArray = ((Array)(key));
                    if (!(keyArray == null)) 
                    {
                        int length = keyArray.Length;
                        ColumnList pkColumns = MvwISDJobXrefView.Instance.TableDefinition.PrimaryKey.Columns;
                        int index = 0;
                        foreach (BaseColumn pkColumn in pkColumns) 
                        {
                            string keyString = ((keyArray.GetValue(index)).ToString());
                            if (MvwISDJobXrefView.Instance.TableDefinition.TableType == BaseClasses.Data.TableDefinition.TableTypes.Virtual)
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
                    kv = MvwISDJobXrefView.Instance.TableDefinition.PrimaryKey.ParseValue(((key).ToString()));
                }
            }
            return kv;
        }
        
        /// <summary>
        /// This method takes a record and a Column and returns an evaluated value of DFKA formula.
        /// </summary>
        public static string GetDFKA(BaseRecord rec, BaseColumn col)
		{
			ForeignKey fkColumn = MvwISDJobXrefView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
			ForeignKey fkColumn = MvwISDJobXrefView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
