// This class is "generated" and will be overwritten.
// Your customizations should be made in POHDView.cs

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
/// The generated superclass for the <see cref="POHDView"></see> class.
/// Provides access to the schema information and record data of a database table or view named DatabaseViewpoint%dbo.POHD.
/// </summary>
/// <remarks>
/// The connection details (name, location, etc.) of the database and table (or view) accessed by this class 
/// are resolved at runtime based on the connection string in the application's Web.Config file.
/// <para>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, use 
/// <see cref="POHDView.Instance">POHDView.Instance</see>.
/// </para>
/// </remarks>
/// <seealso cref="POHDView"></seealso>
[SerializableAttribute()]
public class BasePOHDView : KeylessTable
{

	private readonly string TableDefinitionString = POHDDefinition.GetXMLString();







	protected BasePOHDView()
	{
		this.Initialize();
	}

	protected virtual void Initialize()
	{
		XmlTableDefinition def = new XmlTableDefinition(TableDefinitionString);
		this.TableDefinition = new TableDefinition();
		this.TableDefinition.TableClassName = System.Reflection.Assembly.CreateQualifiedName("POViewer.Business", "POViewer.Business.POHDView");
		def.InitializeTableDefinition(this.TableDefinition);
		this.ConnectionName = def.GetConnectionName();
		this.RecordClassName = System.Reflection.Assembly.CreateQualifiedName("POViewer.Business", "POViewer.Business.POHDRecord");
		this.ApplicationName = "POViewer";
		this.DataAdapter = new POHDSqlView();
		((POHDSqlView)this.DataAdapter).ConnectionName = this.ConnectionName;
		((POHDSqlView)this.DataAdapter).ApplicationName = this.ApplicationName;
		this.TableDefinition.AdapterMetaData = this.DataAdapter.AdapterMetaData;
        POCoColumn.CodeName = "POCo";
        POColumn.CodeName = "PO";
        VendorGroupColumn.CodeName = "VendorGroup";
        VendorColumn.CodeName = "Vendor";
        DescriptionColumn.CodeName = "Description";
        OrderDateColumn.CodeName = "OrderDate";
        OrderedByColumn.CodeName = "OrderedBy";
        ExpDateColumn.CodeName = "ExpDate";
        StatusColumn.CodeName = "Status";
        JCCoColumn.CodeName = "JCCo";
        JobColumn.CodeName = "Job";
        INCoColumn.CodeName = "INCo";
        LocColumn.CodeName = "Loc";
        ShipLocColumn.CodeName = "ShipLoc";
        AddressColumn.CodeName = "Address";
        CityColumn.CodeName = "City";
        StateColumn.CodeName = "State";
        ZipColumn.CodeName = "Zip";
        ShipInsColumn.CodeName = "ShipIns";
        HoldCodeColumn.CodeName = "HoldCode";
        PayTermsColumn.CodeName = "PayTerms";
        CompGroupColumn.CodeName = "CompGroup";
        MthClosedColumn.CodeName = "MthClosed";
        InUseMthColumn.CodeName = "InUseMth";
        InUseBatchIdColumn.CodeName = "InUseBatchId";
        ApprovedColumn.CodeName = "Approved";
        ApprovedByColumn.CodeName = "ApprovedBy";
        PurgeColumn.CodeName = "Purge";
        NotesColumn.CodeName = "Notes";
        AddedMthColumn.CodeName = "AddedMth";
        AddedBatchIDColumn.CodeName = "AddedBatchID";
        UniqueAttchIDColumn.CodeName = "UniqueAttchID";
        AttentionColumn.CodeName = "Attention";
        PayAddressSeqColumn.CodeName = "PayAddressSeq";
        POAddressSeqColumn.CodeName = "POAddressSeq";
        Address2Column.CodeName = "Address2";
        KeyIDColumn.CodeName = "KeyID";
        CountryColumn.CodeName = "Country";
        POCloseBatchIDColumn.CodeName = "POCloseBatchID";
        udSourceColumn.CodeName = "udSource";
        udConvColumn.CodeName = "udConv";
        udCGCTableColumn.CodeName = "udCGCTable";
        udCGCTableIDColumn.CodeName = "udCGCTableID";
        udOrderedByColumn.CodeName = "udOrderedBy";
        DocTypeColumn.CodeName = "DocType";
        udMCKPONumberColumn.CodeName = "udMCKPONumber";
        udShipToJobYNColumn.CodeName = "udShipToJobYN";
        udPRCoColumn.CodeName = "udPRCo";
        udAddressNameColumn.CodeName = "udAddressName";
        udPOFOBColumn.CodeName = "udPOFOB";
        udShipMethodColumn.CodeName = "udShipMethod";
        udPurchaseContactColumn.CodeName = "udPurchaseContact";
        udPMSourceColumn.CodeName = "udPMSource";
		
	}

#region "Overriden methods"
    
#endregion

#region "Properties for columns"

    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.POCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn POCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[0];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.POCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn POCo
    {
        get
        {
            return POHDView.Instance.POCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.PO column object.
    /// </summary>
    public BaseClasses.Data.StringColumn POColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[1];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.PO column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn PO
    {
        get
        {
            return POHDView.Instance.POColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.VendorGroup column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VendorGroupColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[2];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.VendorGroup column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn VendorGroup
    {
        get
        {
            return POHDView.Instance.VendorGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Vendor column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn VendorColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[3];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Vendor column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn Vendor
    {
        get
        {
            return POHDView.Instance.VendorColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Description column object.
    /// </summary>
    public BaseClasses.Data.StringColumn DescriptionColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[4];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Description column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Description
    {
        get
        {
            return POHDView.Instance.DescriptionColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.OrderDate column object.
    /// </summary>
    public BaseClasses.Data.DateColumn OrderDateColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[5];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.OrderDate column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn OrderDate
    {
        get
        {
            return POHDView.Instance.OrderDateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.OrderedBy column object.
    /// </summary>
    public BaseClasses.Data.StringColumn OrderedByColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[6];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.OrderedBy column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn OrderedBy
    {
        get
        {
            return POHDView.Instance.OrderedByColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.ExpDate column object.
    /// </summary>
    public BaseClasses.Data.DateColumn ExpDateColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[7];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.ExpDate column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn ExpDate
    {
        get
        {
            return POHDView.Instance.ExpDateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Status column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn StatusColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[8];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Status column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn Status
    {
        get
        {
            return POHDView.Instance.StatusColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.JCCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn JCCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[9];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.JCCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn JCCo
    {
        get
        {
            return POHDView.Instance.JCCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Job column object.
    /// </summary>
    public BaseClasses.Data.StringColumn JobColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[10];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Job column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Job
    {
        get
        {
            return POHDView.Instance.JobColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.INCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn INCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[11];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.INCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn INCo
    {
        get
        {
            return POHDView.Instance.INCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Loc column object.
    /// </summary>
    public BaseClasses.Data.StringColumn LocColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[12];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Loc column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Loc
    {
        get
        {
            return POHDView.Instance.LocColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.ShipLoc column object.
    /// </summary>
    public BaseClasses.Data.StringColumn ShipLocColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[13];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.ShipLoc column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn ShipLoc
    {
        get
        {
            return POHDView.Instance.ShipLocColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Address column object.
    /// </summary>
    public BaseClasses.Data.StringColumn AddressColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[14];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Address column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Address
    {
        get
        {
            return POHDView.Instance.AddressColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.City column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CityColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[15];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.City column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn City
    {
        get
        {
            return POHDView.Instance.CityColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.State column object.
    /// </summary>
    public BaseClasses.Data.UsaStateColumn StateColumn
    {
        get
        {
            return (BaseClasses.Data.UsaStateColumn)this.TableDefinition.ColumnList[16];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.State column object.
    /// </summary>
    public static BaseClasses.Data.UsaStateColumn State
    {
        get
        {
            return POHDView.Instance.StateColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Zip column object.
    /// </summary>
    public BaseClasses.Data.UsaZipCodeColumn ZipColumn
    {
        get
        {
            return (BaseClasses.Data.UsaZipCodeColumn)this.TableDefinition.ColumnList[17];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Zip column object.
    /// </summary>
    public static BaseClasses.Data.UsaZipCodeColumn Zip
    {
        get
        {
            return POHDView.Instance.ZipColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.ShipIns column object.
    /// </summary>
    public BaseClasses.Data.StringColumn ShipInsColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[18];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.ShipIns column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn ShipIns
    {
        get
        {
            return POHDView.Instance.ShipInsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.HoldCode column object.
    /// </summary>
    public BaseClasses.Data.StringColumn HoldCodeColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[19];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.HoldCode column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn HoldCode
    {
        get
        {
            return POHDView.Instance.HoldCodeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.PayTerms column object.
    /// </summary>
    public BaseClasses.Data.StringColumn PayTermsColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[20];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.PayTerms column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn PayTerms
    {
        get
        {
            return POHDView.Instance.PayTermsColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.CompGroup column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CompGroupColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[21];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.CompGroup column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn CompGroup
    {
        get
        {
            return POHDView.Instance.CompGroupColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.MthClosed column object.
    /// </summary>
    public BaseClasses.Data.DateColumn MthClosedColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[22];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.MthClosed column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn MthClosed
    {
        get
        {
            return POHDView.Instance.MthClosedColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.InUseMth column object.
    /// </summary>
    public BaseClasses.Data.DateColumn InUseMthColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[23];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.InUseMth column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn InUseMth
    {
        get
        {
            return POHDView.Instance.InUseMthColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.InUseBatchId column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn InUseBatchIdColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[24];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.InUseBatchId column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn InUseBatchId
    {
        get
        {
            return POHDView.Instance.InUseBatchIdColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Approved column object.
    /// </summary>
    public BaseClasses.Data.StringColumn ApprovedColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[25];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Approved column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Approved
    {
        get
        {
            return POHDView.Instance.ApprovedColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.ApprovedBy column object.
    /// </summary>
    public BaseClasses.Data.StringColumn ApprovedByColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[26];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.ApprovedBy column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn ApprovedBy
    {
        get
        {
            return POHDView.Instance.ApprovedByColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Purge column object.
    /// </summary>
    public BaseClasses.Data.StringColumn PurgeColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[27];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Purge column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Purge
    {
        get
        {
            return POHDView.Instance.PurgeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Notes column object.
    /// </summary>
    public BaseClasses.Data.ClobColumn NotesColumn
    {
        get
        {
            return (BaseClasses.Data.ClobColumn)this.TableDefinition.ColumnList[28];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Notes column object.
    /// </summary>
    public static BaseClasses.Data.ClobColumn Notes
    {
        get
        {
            return POHDView.Instance.NotesColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.AddedMth column object.
    /// </summary>
    public BaseClasses.Data.DateColumn AddedMthColumn
    {
        get
        {
            return (BaseClasses.Data.DateColumn)this.TableDefinition.ColumnList[29];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.AddedMth column object.
    /// </summary>
    public static BaseClasses.Data.DateColumn AddedMth
    {
        get
        {
            return POHDView.Instance.AddedMthColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.AddedBatchID column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn AddedBatchIDColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[30];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.AddedBatchID column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn AddedBatchID
    {
        get
        {
            return POHDView.Instance.AddedBatchIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.UniqueAttchID column object.
    /// </summary>
    public BaseClasses.Data.UniqueIdentifierColumn UniqueAttchIDColumn
    {
        get
        {
            return (BaseClasses.Data.UniqueIdentifierColumn)this.TableDefinition.ColumnList[31];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.UniqueAttchID column object.
    /// </summary>
    public static BaseClasses.Data.UniqueIdentifierColumn UniqueAttchID
    {
        get
        {
            return POHDView.Instance.UniqueAttchIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Attention column object.
    /// </summary>
    public BaseClasses.Data.StringColumn AttentionColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[32];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Attention column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Attention
    {
        get
        {
            return POHDView.Instance.AttentionColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.PayAddressSeq column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn PayAddressSeqColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[33];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.PayAddressSeq column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn PayAddressSeq
    {
        get
        {
            return POHDView.Instance.PayAddressSeqColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.POAddressSeq column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn POAddressSeqColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[34];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.POAddressSeq column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn POAddressSeq
    {
        get
        {
            return POHDView.Instance.POAddressSeqColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Address2 column object.
    /// </summary>
    public BaseClasses.Data.StringColumn Address2Column
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[35];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Address2 column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Address2
    {
        get
        {
            return POHDView.Instance.Address2Column;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.KeyID column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn KeyIDColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[36];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.KeyID column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn KeyID
    {
        get
        {
            return POHDView.Instance.KeyIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Country column object.
    /// </summary>
    public BaseClasses.Data.StringColumn CountryColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[37];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.Country column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn Country
    {
        get
        {
            return POHDView.Instance.CountryColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.POCloseBatchID column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn POCloseBatchIDColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[38];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.POCloseBatchID column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn POCloseBatchID
    {
        get
        {
            return POHDView.Instance.POCloseBatchIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udSource column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udSourceColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[39];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udSource column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udSource
    {
        get
        {
            return POHDView.Instance.udSourceColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udConv column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udConvColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[40];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udConv column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udConv
    {
        get
        {
            return POHDView.Instance.udConvColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udCGCTable column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udCGCTableColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[41];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udCGCTable column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udCGCTable
    {
        get
        {
            return POHDView.Instance.udCGCTableColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udCGCTableID column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn udCGCTableIDColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[42];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udCGCTableID column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn udCGCTableID
    {
        get
        {
            return POHDView.Instance.udCGCTableIDColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udOrderedBy column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn udOrderedByColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[43];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udOrderedBy column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn udOrderedBy
    {
        get
        {
            return POHDView.Instance.udOrderedByColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.DocType column object.
    /// </summary>
    public BaseClasses.Data.StringColumn DocTypeColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[44];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.DocType column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn DocType
    {
        get
        {
            return POHDView.Instance.DocTypeColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udMCKPONumber column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udMCKPONumberColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[45];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udMCKPONumber column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udMCKPONumber
    {
        get
        {
            return POHDView.Instance.udMCKPONumberColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udShipToJobYN column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udShipToJobYNColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[46];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udShipToJobYN column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udShipToJobYN
    {
        get
        {
            return POHDView.Instance.udShipToJobYNColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udPRCo column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn udPRCoColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[47];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udPRCo column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn udPRCo
    {
        get
        {
            return POHDView.Instance.udPRCoColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udAddressName column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udAddressNameColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[48];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udAddressName column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udAddressName
    {
        get
        {
            return POHDView.Instance.udAddressNameColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udPOFOB column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udPOFOBColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[49];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udPOFOB column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udPOFOB
    {
        get
        {
            return POHDView.Instance.udPOFOBColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udShipMethod column object.
    /// </summary>
    public BaseClasses.Data.StringColumn udShipMethodColumn
    {
        get
        {
            return (BaseClasses.Data.StringColumn)this.TableDefinition.ColumnList[50];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udShipMethod column object.
    /// </summary>
    public static BaseClasses.Data.StringColumn udShipMethod
    {
        get
        {
            return POHDView.Instance.udShipMethodColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udPurchaseContact column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn udPurchaseContactColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[51];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udPurchaseContact column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn udPurchaseContact
    {
        get
        {
            return POHDView.Instance.udPurchaseContactColumn;
        }
    }
    
    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udPMSource column object.
    /// </summary>
    public BaseClasses.Data.NumberColumn udPMSourceColumn
    {
        get
        {
            return (BaseClasses.Data.NumberColumn)this.TableDefinition.ColumnList[52];
        }
    }
    

    
    /// <summary>
    /// This is a convenience property that provides direct access to the table's POHD_.udPMSource column object.
    /// </summary>
    public static BaseClasses.Data.NumberColumn udPMSource
    {
        get
        {
            return POHDView.Instance.udPMSourceColumn;
        }
    }
    
    


#endregion

#region "Shared helper methods"

    /// <summary>
    /// This is a shared function that can be used to get an array of POHDRecord records using a where clause.
    /// </summary>
    public static POHDRecord[] GetRecords(string where)
    {
        return GetRecords(where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get an array of POHDRecord records using a where clause.
    /// </summary>
    public static POHDRecord[] GetRecords(BaseFilter join, string where)
    {
        return GetRecords(join, where, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    

    /// <summary>
    /// This is a shared function that can be used to get an array of POHDRecord records using a where and order by clause.
    /// </summary>
    public static POHDRecord[] GetRecords(string where, OrderBy orderBy)
    {
        return GetRecords(where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }
    
     /// <summary>
    /// This is a shared function that can be used to get an array of POHDRecord records using a where and order by clause.
    /// </summary>
    public static POHDRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy)
    {
        return GetRecords(join, where, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
    }    
    
    /// <summary>
    /// This is a shared function that can be used to get an array of POHDRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static POHDRecord[] GetRecords(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = POHDView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (POHDRecord[])recList.ToArray(Type.GetType("POViewer.Business.POHDRecord"));
    }   
    
    /// <summary>
    /// This is a shared function that can be used to get an array of POHDRecord records using a where and order by clause clause with pagination.
    /// </summary>
    public static POHDRecord[] GetRecords(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }

        ArrayList recList = POHDView.Instance.GetRecordList(join, whereFilter, null, orderBy, pageIndex, pageSize);

        return (POHDRecord[])recList.ToArray(Type.GetType("POViewer.Business.POHDRecord"));
    }   


    public static POHDRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = POHDView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (POHDRecord[])recList.ToArray(Type.GetType("POViewer.Business.POHDRecord"));
    }

    public static POHDRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize)
	{

        ArrayList recList = POHDView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize);

        return (POHDRecord[])recList.ToArray(Type.GetType("POViewer.Business.POHDRecord"));
    }


    public static POHDRecord[] GetRecords(
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{
        BaseClasses.Data.BaseFilter join = null;
        ArrayList recList = POHDView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (POHDRecord[])recList.ToArray(Type.GetType("POViewer.Business.POHDRecord"));
    }

    public static POHDRecord[] GetRecords(
        BaseFilter join,
		WhereClause where,
		OrderBy orderBy,
		int pageIndex,
		int pageSize,
		ref int totalRecords)
	{

        ArrayList recList = POHDView.Instance.GetRecordList(join, where.GetFilter(), null, orderBy, pageIndex, pageSize, ref totalRecords);

        return (POHDRecord[])recList.ToArray(Type.GetType("POViewer.Business.POHDRecord"));
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

        return (int)POHDView.Instance.GetRecordListCount(null, whereFilter, null, null);
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

        return (int)POHDView.Instance.GetRecordListCount(join, whereFilter, null, null);
    }

    
    public static int GetRecordCount(WhereClause where)
    {
        return (int)POHDView.Instance.GetRecordListCount(null, where.GetFilter(), null, null);
    }
    
    public static int GetRecordCount(BaseFilter join, WhereClause where)
    {
        return (int)POHDView.Instance.GetRecordListCount(join, where.GetFilter(), null, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a POHDRecord record using a where clause.
    /// </summary>
    public static POHDRecord GetRecord(string where)
    {
        OrderBy orderBy = null;
        return GetRecord(where, orderBy);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a POHDRecord record using a where clause.
    /// </summary>
    public static POHDRecord GetRecord(BaseFilter join, string where)
    {
        OrderBy orderBy = null;
        return GetRecord(join, where, orderBy);
    }


    /// <summary>
    /// This is a shared function that can be used to get a POHDRecord record using a where and order by clause.
    /// </summary>
    public static POHDRecord GetRecord(string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        BaseClasses.Data.BaseFilter join = null;  
        ArrayList recList = POHDView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        POHDRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (POHDRecord)recList[0];
        }

        return rec;
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a POHDRecord record using a where and order by clause.
    /// </summary>
    public static POHDRecord GetRecord(BaseFilter join, string where, OrderBy orderBy)
    {
        SqlFilter whereFilter = null;
        if (where != null && where.Trim() != "")
        {
           whereFilter = new SqlFilter(where);
        }
        
        ArrayList recList = POHDView.Instance.GetRecordList(join, whereFilter, null, orderBy, BaseTable.MIN_PAGE_NUMBER, BaseTable.MIN_BATCH_SIZE);

        POHDRecord rec = null;
        if (recList.Count > 0)
        {
            rec = (POHDRecord)recList[0];
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

        return POHDView.Instance.GetColumnValues(retCol, null, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

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

        return POHDView.Instance.GetColumnValues(retCol, join, where.GetFilter(), null, orderBy, BaseTable.MIN_PAGE_NUMBER, maxItems);

    }
      
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where)
    {
        POHDRecord[] recs = GetRecords(where);
        return  POHDView.Instance.CreateDataTable(recs, null);
    }

    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where)
    {
        POHDRecord[] recs = GetRecords(join, where);
        return  POHDView.Instance.CreateDataTable(recs, null);
    }


    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy)
    {
        POHDRecord[] recs = GetRecords(where, orderBy);
        return  POHDView.Instance.CreateDataTable(recs, null);
    }
   
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy)
    {
        POHDRecord[] recs = GetRecords(join, where, orderBy);
        return  POHDView.Instance.CreateDataTable(recs, null);
    }
   
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        POHDRecord[] recs = GetRecords(where, orderBy, pageIndex, pageSize);
        return  POHDView.Instance.CreateDataTable(recs, null);
    }
    
    /// <summary>
    /// This is a shared function that can be used to get a DataTable to bound with a data bound control using a where and order by clause with pagination.
    /// </summary>
    public static System.Data.DataTable GetDataTable(BaseFilter join, string where, OrderBy orderBy, int pageIndex, int pageSize)
    {
        POHDRecord[] recs = GetRecords(join, where, orderBy, pageIndex, pageSize);
        return  POHDView.Instance.CreateDataTable(recs, null);
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
        POHDView.Instance.DeleteRecordList(whereFilter);
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
        
        return  POHDView.Instance.ExportRecordData(whereFilter);
    }
   
    public static string Export(WhereClause where)
    {
        BaseFilter whereFilter = null;
        if (where != null)
        {
            whereFilter = where.GetFilter();
        }

        return POHDView.Instance.ExportRecordData(whereFilter);
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

        return POHDView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return POHDView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return POHDView.Instance.GetColumnStatistics(colSel, null, where.GetFilter(), null, orderBy, pageIndex, pageSize);
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

        return POHDView.Instance.GetColumnStatistics(colSel, join, where.GetFilter(), null, orderBy, pageIndex, pageSize);
    }

    /// <summary>
    ///  This method returns the columns in the table.
    /// </summary>
    public static BaseColumn[] GetColumns() 
    {
        return POHDView.Instance.TableDefinition.Columns;
    }

    /// <summary>
    ///  This method returns the columnlist in the table.
    /// </summary>   
    public static ColumnList GetColumnList() 
    {
        return POHDView.Instance.TableDefinition.ColumnList;
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    public static IRecord CreateNewRecord() 
    {
        return POHDView.Instance.CreateRecord();
    }

    /// <summary>
    /// This method creates a new record and returns it to be edited.
    /// </summary>
    /// <param name="tempId">ID of the new record.</param>   
    public static IRecord CreateNewRecord(string tempId) 
    {
        return POHDView.Instance.CreateRecord(tempId);
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
        BaseColumn column = POHDView.Instance.TableDefinition.ColumnList.GetByUniqueName(uniqueColumnName);
        return column;
    }
    
    /// <summary>
    /// This method gets the specified column.
    /// </summary>
    /// <param name="name">name of the column to fetch.</param>
    public static BaseColumn GetColumnByName(string name)
    {
        BaseColumn column = POHDView.Instance.TableDefinition.ColumnList.GetByInternalName(name);
        return column;
    } 

        /// <summary>
        /// This method takes a record and a Column and returns an evaluated value of DFKA formula.
        /// </summary>
        public static string GetDFKA(BaseRecord rec, BaseColumn col)
		{
			ForeignKey fkColumn = POHDView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
			ForeignKey fkColumn = POHDView.Instance.TableDefinition.GetExpandableNonCompositeForeignKey(col);
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
