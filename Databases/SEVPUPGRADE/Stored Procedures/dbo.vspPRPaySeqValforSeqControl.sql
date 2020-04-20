SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRPaySeqValforSeqControl]
/************************************************************************
* CREATED:	mh 10/30/06    
* MODIFIED: mh 12/11/07 - Added initial values for @unpostedtimecards and @hoursposted.
			mh 01/31/08 - Added a check against PRSQ if no records in PRTH.   
*
* Purpose of Stored Procedure
*
*    Used by PRSeqControl.  Validates PaySeq and checks for unposted
*	 time cards.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, @prgroup bGroup, @prenddate bDate, @payseq tinyint, @employee bEmployee, 
	 @unpostedtimecards bYN output, @hoursposted bYN output, @msg varchar(60) output)

as
set nocount on

    declare @rcode int

    select @rcode = 0, @unpostedtimecards = 'N', @hoursposted = 'N'

	exec @rcode = bspPRPaySeqVal @prco, @prgroup, @prenddate, @payseq, @msg output

	if @rcode = 0
	begin
		if exists (Select 1 
		from dbo.PRTB b 
		join HQBC h on b.Co = h.Co and b.Mth = h.Mth and b.BatchId = h.BatchId 
		join dbo.PRPC p on p.PRCo = h.Co and p.PRGroup = h.PRGroup and p.PREndDate = h.PREndDate 
		where p.PRCo = @prco and p.PRGroup = @prgroup and p.PREndDate = @prenddate and 
		b.Employee = @employee and b.PaySeq = @payseq)
		begin
			select @unpostedtimecards = 'Y'
		end
		else
		begin
			select @unpostedtimecards = 'N'
		end
	end

	if exists(select 1 from dbo.PRTH 
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and 
	PaySeq = @payseq)
	begin
		select @hoursposted = 'Y'
	end
	else
	begin

		if exists(select 1 from dbo.PRSQ (nolock) 
		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and
		PaySeq = @payseq)
		begin
			select @hoursposted = 'Y'
		end
		else
		begin
			select @hoursposted = 'N'
		end
	end

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRPaySeqValforSeqControl] TO [public]
GO
