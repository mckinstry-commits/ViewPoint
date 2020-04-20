using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.Models.Viewpoint
{
    // REQUIRES:
    // SQL table type:
    /*
        CREATE TYPE dbo.McKtyInvoicePreview AS TABLE
        ( 
            SMCo					tinyint
	        ,SMInvoiceID		bigint
	        ,InvoiceNumber		varchar(10)
	        ,WorkOrder	nvarchar(max)
        );
    */

    /// <summary>
    /// The data layer will pass this table-valued structure to SQL sp: dbo.McKspSMInvoiceDeliverySearch
    /// </summary>
    /// <remarks>structure matches user-defined type: dbo.McKtyInvoiceList</remarks>
    public class InvoicePreview : List<InvoicePreviewParam>, IEnumerable<SqlDataRecord>
    {
        IEnumerator<SqlDataRecord> IEnumerable<SqlDataRecord>.GetEnumerator()
        {
            var sqlRow = new SqlDataRecord( 
                                            new SqlMetaData("SMCo", SqlDbType.TinyInt)
                                            ,new SqlMetaData("SMInvoiceID", SqlDbType.BigInt)
                                            ,new SqlMetaData("InvoiceNumber", SqlDbType.VarChar, 10)
                                            ,new SqlMetaData("WorkOrder", SqlDbType.NVarChar, -1) // nvarchar(max)
                                          );

            foreach (InvoicePreviewParam inv in this)
            {
                sqlRow.SetByte(0, inv.SMCo);
                sqlRow.SetInt64(1, inv.SMInvoiceID);
                sqlRow.SetString(2, inv.InvoiceNumber);
                sqlRow.SetString(3, inv.WorkOrder);
                yield return sqlRow;
            }
        }
    }
}
