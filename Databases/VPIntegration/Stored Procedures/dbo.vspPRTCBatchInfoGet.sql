SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRTCBatchInfoGet]
/*************************************
* CREATED BY: EN 5/20/05
* MODIFIED BY: GG 02/02/07 - changed to use tables, added nolocks
*
* Returns pay period and group info for a PR timecard batch
*
* Pass:
*	PR Company
*	PR Batch Month
*	PR Batch Id
*
* Success returns:
*		PR Group for pay period
*		Pay Period Ending Date
*		Standard Hrs for pay period
*		Beginning Date for pay period
*		Pay Frequency for the PR Group
*
* Error returns:
*	1 and error message
**************************************/
(@prco bCompany, @mth bMonth, @batchid bBatchID, 
	@prgroup bGroup output, @prenddate bDate output, @stdhrs bHrs output,
	@prbegindate bDate output, @msg varchar(60) output)

as 

set nocount on
declare @rcode int
select @rcode = 0
  	
if @prco is null
  	begin
  	select @msg = 'Missing PR Company', @rcode = 1
  	goto vspexit
  	end
if @mth is null
  	begin
  	select @msg = 'Missing Batch Month', @rcode = 1
  	goto vspexit
  	end
if @batchid is null
  	begin
  	select @msg = 'Missing Batch ID#', @rcode = 1
  	goto vspexit
  	end

--get pay period control and group info for batch  
Select @prgroup=p.PRGroup, @prenddate=p.PREndDate, @stdhrs=p.Hrs, @prbegindate=p.BeginDate
from dbo.bHQBC b (nolock)
join dbo.bPRPC p (nolock) on p.PRCo=b.Co and p.PRGroup=b.PRGroup and p.PREndDate=b.PREndDate 
join dbo.bPRGR g (nolock) on g.PRCo=p.PRCo and g.PRGroup=p.PRGroup 
where b.Co=@prco and b.Mth=@mth and b.BatchId=@batchid


vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTCBatchInfoGet] TO [public]
GO
