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
        CREATE TYPE dbo.McKtyInvoiceList AS TABLE
        (
            InvoiceNumber VARCHAR(10)
        ); 
    */

    /// <summary>
    /// The data layer will pass this table-valued structure to SQL sp: dbo.McKspSMInvoiceDeliverySearch
    /// </summary>
    /// <remarks>structure matches user-defined type: dbo.McKtyInvoiceList</remarks>
    public class InvoiceList : List<InvoiceParam>, IEnumerable<SqlDataRecord>
    {
        IEnumerator<SqlDataRecord> IEnumerable<SqlDataRecord>.GetEnumerator()
        {
            var sqlRow = new SqlDataRecord( new SqlMetaData("InvoiceNumber", SqlDbType.VarChar, 10));

            foreach (InvoiceParam inv in this)
            {
                sqlRow.SetString(0, inv.InvoiceNumber);
                yield return sqlRow;
            }
        }
    }
}
