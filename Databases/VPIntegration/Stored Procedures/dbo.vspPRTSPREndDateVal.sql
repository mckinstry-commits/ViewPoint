SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRTSPREndDateVal]
/************************************************************************
* CREATED:	mh 5/21/07    
* MODIFIED: mh 4/4/08 - Issue 127717 - Need to grab min PaySeq.   
*
* Purpose of Stored Procedure
*
*    Validate PR End Date entered in PR Crew TS Send and retrieve the Pay Seq.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

      (@prco bCompany, @prgroup bGroup, @prenddate bDate, @payseq int output, @status tinyint output,
		@beginmth bMonth output, @endmth bMonth output, @prbegindate bDate output, @msg varchar(60) output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if exists(select 1 from PRPC c (nolock)
		where c.PRCo = @prco and c.PRGroup = @prgroup and c.PREndDate = @prenddate)
	begin
		select @payseq = min(PaySeq) from PRPS s (nolock) 
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		if @payseq is null
		begin
			select @msg = 'No Pay Sequences have been entered for this pay period', @rcode = 1
			goto vspexit
		end

		select @beginmth = BeginMth, @endmth = EndMth, @prbegindate = BeginDate, @status = [Status]
		from PRPC (nolock)
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate

	end
	else
	begin
		select @msg = 'Invalid Pay Period', @rcode = 1
		goto vspexit
	end

    if @status <> 0
    begin
    	select @msg = 'Must be an ''open'' Pay Period!', @rcode = 1
    	goto vspexit
    end

	
vspexit:

    return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTSPREndDateVal] TO [public]
GO
