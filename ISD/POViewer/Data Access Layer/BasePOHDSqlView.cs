// This class is "generated" and will be overwritten.
// Your customizations should be made in POHDSqlView.cs 

using BaseClasses.Data.SqlProvider;

namespace POViewer.Data
{

/// <summary>
/// The generated superclass for the <see cref="POHDSqlView"></see> class.
/// </summary>
/// <remarks>
/// This class is not intended to be instantiated directly.  To obtain an instance of this class, 
/// use the methods of the <see cref="POHDView"></see> class.
/// </remarks>
/// <seealso cref="POHDView"></seealso>
/// <seealso cref="POHDSqlView"></seealso>
public class BasePOHDSqlView : StoredProceduresSQLServerAdapter
{
	
	public BasePOHDSqlView()
	{
	}

	public BasePOHDSqlView(string connectionName, string applicationName) : base(connectionName, applicationName)
	{
	}

}

}
