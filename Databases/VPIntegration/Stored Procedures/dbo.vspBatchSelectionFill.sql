SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspBatchSelectionFill]
/********************************
* Created: kb 07/16/03 
* Modified: GG 02/16/07 - cleanup, handle EM source batches, limit to open months
*			GG 02/25/08 - #120107 - separate sub ledger close
*			GG 08/13/98 - #129420 - fix for GL source batches
*
* Called from Batch Selection form to list unposted batches
*
* Input:
*	@co					Company
*	@source				Batch Source
*	@restrictuser		Y = batches created by the current user
*						N = batches created by anyone
*	@incldcanceled		Y = include open (0) and canceled (6) batches
*						N = open (0) batches only
*	@glco				GL Company # to limit batches within an open month
*							(canceled batches may exist in closed month)
*
* Output:
*	@msg 		error message if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@co tinyint = null, @source varchar(30) = null, @restrictuser bYN = null,
 @incldcanceled bYN = null, @glco bCompany = null)
as

set nocount on


select  Mth as [Month], BatchId, InUseBy, CreatedBy, DateCreated, Status, Rstrict,
	Adjust, PRGroup, PREndDate, Source
from dbo.bHQBC (nolock)
where Co = @co and (Status = 0 or (Status = 6 and @incldcanceled = 'Y'))
	and (Source = @source or (@source = 'EMAdj' and Source in ('EMAlloc', 'EMDepr')))	
	and ((@restrictuser = 'Y' and CreatedBy = suser_sname()) or @restrictuser = 'N')
	-- #120107 - last month depends on batch source
	and Mth > (select case when (@source like 'AP%' or @source in ('MS MatlPay', 'MS HaulPay')) then LastMthAPClsd
					when (@source like 'AR%' or @source like 'JB%' or @source = 'MS Invoice') then LastMthARClsd
					when (@source like 'GL%') then LastMthGLClsd	-- needed for GL batches
					else LastMthSubClsd end
					from dbo.bGLCO with (nolock) where GLCo = @glco)
	-- (select LastMthSubClsd from dbo.bGLCO with (nolock) where GLCo = @glco) 
order by  Mth, BatchId 

vspexit:
	return

GO
GRANT EXECUTE ON  [dbo].[vspBatchSelectionFill] TO [public]
GO
