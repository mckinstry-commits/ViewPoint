SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARRetainageGridFill]
/****************************************************************************
* CREATED BY: 	TJL 05/24/05 - Issue #27715, 6x Rewrite.  Needed to return Column Names
* MODIFIED BY:	TJL 07/19/07 - Issue #124965, Correct bPct format when using FormatSecondaryGrid()
*		TJL 04/14/08 - Issue #127811, Total Open Retainage label value not correct when Customer Entered
*		TJL 06/18/08 - Issue #128371, ARRelease International Sales Tax
*
* USAGE:
*	Fills grid in ARRelease form
*
* INPUT PARAMETERS:
*
* OUTPUT PARAMETERS:
*
*	See Select statement below
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@ARCo bCompany = null, @Mth bMonth, @BatchId bBatchID, @CustGrp bGroup = null,
@Customer bCustomer=null, @releasedate bDate = null, @Contract bContract = null, @JCCo bCompany = null)
as
set nocount on
declare @rcode integer
select @rcode = 0
  
begin
  
/* Fill the grid with a calculated open retainage value along with the other columns */
select H.Mth, H.ARTrans, min(H.Invoice) as [Invoice #], min(H.Description) as [Description], min(H.Contract) as [Contract],
	sum(L.Amount) as [Invoice Amt], isnull(sum(L.Retainage),0) as [OpenRetainage],
	(select isnull(sum(b.Amount),0) from ARBL b where b.Co = @ARCo and b.BatchId = @BatchId
		and b.Mth = @Mth and b.ApplyMth = H.Mth and b.ApplyTrans = H.ARTrans) / sum(L.Retainage) /* * 100*/ as [Release PCT],
	(select isnull(sum(b.Amount),0) from ARBL b where b.Co = @ARCo and b.BatchId = @BatchId
		and b.Mth = @Mth and b.ApplyTrans = H.ARTrans and b.ApplyMth = H.Mth) as [Release Amt]
from ARTH H with (nolock)
join ARTL L with (nolock) on L.ARCo = H.ARCo and L.ApplyMth = H.Mth and L.ApplyTrans = H.ARTrans
where H.ARCo = @ARCo and H.CustGroup = @CustGrp and H.Customer = @Customer 
   	and (H.JCCo = @JCCo or @JCCo is null) 
   	and (H.Contract = @Contract or @Contract is null)   
	and H.ARTransType <> 'R' and H.Source like 'AR%' 
	--and ((@releasedate is null) or (@releasedate is not null and H.TransDate <= @releasedate))
group by H.Mth, H.ARTrans
having (select isnull(sum(L.Retainage),0)) <> 0
  
vspexit:
return @rcode
end

GO
GRANT EXECUTE ON  [dbo].[vspARRetainageGridFill] TO [public]
GO
