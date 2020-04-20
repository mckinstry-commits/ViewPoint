SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRPayStubAttachmentList]
	/******************************************************
	* CREATED BY:  MarkH 02/18/2009
	* MODIFIED By: MarkH 04/18/2009	Restricting by pay seq is an option.
	*			   MarkH 03/15/2010 Include Pay Seq in returned dataset.
	*
	* Usage:	Return set from PRSP of Employees that will have
	*			Checks/Direct Deposit Stubs attached to PRSQ records.
	*	
	*
	* Input params:
	*
	*		@prco - Payroll Company
	*		@prgroup - Payroll Group
	*		@prenddate - Payroll Ending Date
	*		@payseq - Payment Seq	
	*	
	*
	* Output params:	
	*
	*		@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @prgroup bGroup, @prenddate bDate, @payseq int

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	if @payseq is null
	begin
		select p.PRCo, p.PRGroup, p.PREndDate, p.Employee, h.LastName, h.FirstName, p.PaySeq, s.KeyID
		from dbo.PRSP p (nolock)
		left join dbo.PRSQ s on 
		p.PRCo = s.PRCo and 
		p.PRGroup = s.PRGroup and 
		p.PREndDate = s.PREndDate and
		p.Employee = s.Employee and
		p.PaySeq = s.PaySeq
		left join dbo.PREH h on 
		p.PRCo = h.PRCo and p.Employee = h.Employee
		where p.PRCo = @prco and p.PRGroup = @prgroup and 
		p.PREndDate = @prenddate 
	end
	else
	begin	--Restrict by pay sequence.
		select p.PRCo, p.PRGroup, p.PREndDate, p.Employee, h.LastName, h.FirstName, p.PaySeq, s.KeyID
		from dbo.PRSP p (nolock)
		left join dbo.PRSQ s on 
		p.PRCo = s.PRCo and 
		p.PRGroup = s.PRGroup and 
		p.PREndDate = s.PREndDate and
		p.Employee = s.Employee and
		p.PaySeq = s.PaySeq
		left join dbo.PREH h on 
		p.PRCo = h.PRCo and p.Employee = h.Employee
		where p.PRCo = @prco and p.PRGroup = @prgroup and 
		p.PREndDate = @prenddate and p.PaySeq = @payseq
	end
	 
	vspexit:

		return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRPayStubAttachmentList] TO [public]
GO
