SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure dbo.vspPRDirectDepositEMailList
	/******************************************************
	* CREATED BY:  markh 01/15/09 
	* MODIFIED By: 
	*
	* Usage:  Creates a list of Employees from PRSP/PREH to
	*		  email
	*	
	*
	* Input params:
	*	
	*	@prco - Company
	*	@prgroup - Payroll Group
	*	@prenddate - Payroll End Date
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @prgroup bGroup, @prenddate bDate --, @msg varchar output
	
	as 
	set nocount on
--	declare @rcode int
   	
	select s.PRCo 'PRCo', s.PRGroup 'PRGroup', s.PREndDate 'PREndDate', 
	s.Employee 'Employee', s.PaySeq 'PaySeq', s.LastName 'LastName', s.FirstName 'FirstName', 
	h.Email 'Email', q.KeyID 'KeyID'
	from bPRSP s Join bPREH h on
	s.PRCo = h.PRCo and
	s.Employee = h.Employee
	join bPRSQ q on 
	s.PRCo = q.PRCo and
	s.PRGroup = q.PRGroup and
	s.PREndDate = q.PREndDate and
	s.Employee = q.Employee and
	s.PaySeq = q.PaySeq
	where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate

--	select @rcode = 0
	 
	vspexit:

--	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRDirectDepositEMailList] TO [public]
GO
