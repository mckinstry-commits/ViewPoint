SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRBatchDateVal]
/***********************************************************
* CREATED: kb 1/13/98
* MODIFIED: kb 1/13/98
*			EN 10/7/02 - issue 18877 change double quotes to single
*			EN 9/29/03 - issue 20054 allow batch month to be either beginning or ending month in pay period
			kb 1/30/5 - added pay seq to be returned, need for 6.x
*			EN 10/5/06 - mod for 6x recode issue
*			GG 06/28/07 - added pay seq# validation 
*
* USAGE:
* Called from Batch Selection form to validate PR Ending Date
*
* INPUT PARAMETERS
*   @prco          PR Company
*   @prgroup       PR Group
*   @enddate       Pay Period Ending Date
*   @mth           Batch Month
*
* OUTPUT PARAMETERS
*	@payseq			1st Pay Seq in Pay Period
*   @msg			error message
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
   	(@prco bCompany = null, @prgroup bGroup = null, @enddate bDate = null, @mth bMonth = null,
	 @payseq tinyint output, @msg varchar(60) output)
as

set nocount on

declare @rcode int, @status tinyint

select @rcode = 0

if @prco is null
	begin
	select @msg = 'Missing PR Company!', @rcode = 1
	goto bspexit
	end
if @prgroup is null
	begin
	select @msg = 'Missing PR Group!', @rcode = 1
	goto bspexit
	end
if @enddate is null
	begin
	select @msg = 'Missing PR Ending Date!', @rcode = 1
	goto bspexit
	end
if @mth is null
	begin
	select @msg = 'Missing Batch Month!', @rcode = 1
	goto bspexit
	end
   
--validate Pay Period
select @status = Status
from dbo.PRPC (nolock)
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @enddate
if @@rowcount = 0
	begin
   	select @msg = 'PR Ending Date not on file!', @rcode = 1
   	goto bspexit
   	end
if @status <> 0
   	begin
   	select @msg = 'Must be an ''open'' Pay Period!', @rcode = 1
   	goto bspexit
   	end

--get 1st Pay Seq for the Pay Period
select @payseq = min(PaySeq)
from dbo.PRPS (nolock)
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @enddate
if @@rowcount = 0
	begin
	select @msg = 'No Payment Sequences have been setup for this Pay Period.', @rcode = 1
	goto bspexit
	end

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRBatchDateVal] TO [public]
GO
