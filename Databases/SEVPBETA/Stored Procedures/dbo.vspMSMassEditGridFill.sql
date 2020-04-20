SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
CREATE procedure [dbo].[vspMSMassEditGridFill]
/************************************************************************
 * Created By:	GF 09/13/2007
 * Modified By:	
 *
 * Purpose of Stored Procedure to populate the MS Mass Edit Batch Detail grid.
 *    
 *           
 * 
 *
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 *************************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID)
as
set nocount on
   
declare @rcode int
   
select @rcode = 0
   
---- get MSTB Batch Detail information
select a.BatchSeq, a.BatchTransType, a.MSTrans, a.FromLoc, a.Ticket, a.SaleType,
		a.Material, a.UM, a.MatlUnits, a.UnitPrice, a.ECM,
		'TicketTotal' = isnull(a.MatlTotal,0) + isnull(a.HaulTotal,0) + isnull(a.TaxTotal,0) - isnull(a.DiscOff,0) - isnull(a.TaxDisc,0)
	
from MSTB a where a.Co=@co and a.Mth=@mth and a.BatchId=@batchid
order by a.BatchSeq


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSMassEditGridFill] TO [public]
GO
