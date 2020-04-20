SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPCheckList]
/************************************************************************
* Created:	MV 01/20/09 Woohoo Obama is prez!  
* Modified:  
*
* Usage:
*   Returns a list of check information to display in the AP Check Print form.
*
* Inputs:
*	@apco		AP Company #
*	@mth		Batch Month
*	@batchid	Batch ID
*	@cmco		CM Company #
*	@cmacct		CM Account #
*	@beginchk	Beginning Check #
*	@endchk		Ending Check #
*
* Outputs:
*	resultset of check info 
*
*************************************************************************/
    
    (@apco bCompany = null, @mth bMonth = null, @batchid int = null,@cmco bCompany = null,
	 @cmacct int = null, @beginchk bCMRef = null, @endchk bCMRef = null)

as
set nocount on

select v.SortName, v.Name,b.BatchSeq,b.CMRef
from dbo.bAPPB b (nolock)
join dbo.bAPVM v (nolock) on b.VendorGroup=v.VendorGroup and b.Vendor=v.Vendor
left join dbo.bCMDT c (nolock) on b.CMCo=c.CMCo and b.CMAcct=c.CMAcct and c.CMTransType = 1 and c.CMRef = b.CMRef and c.CMRefSeq = b.CMRefSeq
where b.Co=@apco and b.Mth=@mth and b.BatchId=@batchid 
	and b.PayMethod = 'C' and b.ChkType = 'C' and c.StmtDate is null and b.VoidYN = 'N' 
	and b.CMRef >= isnull(@beginchk,'') and b.CMRef <= isnull(@endchk,'~~~~~~~~~~')
order by b.CMRef

return

GO
GRANT EXECUTE ON  [dbo].[vspAPCheckList] TO [public]
GO
