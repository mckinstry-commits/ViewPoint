SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRPayStubNotifyList]
/******************************************************
* CREATED BY:	markh 2/17/09 
* MODIFIED By:	markh 05/13/09	- Excluding employees that do not have a CM Ref in PRSQ. 
*				markh 01/12/10	- 136454 added KeyID and UniqueAttchID to record set returned.
*				MCP 11/5/2010	- Issue #141821 Removed References to HQAT
*				CHS	02/23/2011	- #143273
* 
* Usage:
*	
*		Retrieve a list of Attachments to send to employees based on 
*		Company/Group/EndDate/PaySeq
*
* Input params:
*	
*		@co - Company
*		@prgroup - PRGroup
*		@prenddate - Payroll end date
*		@payseq - Pay Sequence
*	
*
* Output params:
*		none
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
@co bCompany, @prgroup bGroup, @prenddate bDate, @payseq int, @empl bEmployee, @attachtypeid int

	as 
	set nocount on
	
	if @empl is null
		begin
			select p1.Employee, e1.Email, e1.PayMethodDelivery, p1.KeyID, p1.UniqueAttchID
			from dbo.PRSQ (nolock) p1
			join dbo.PREH (nolock) e1 on p1.PRCo = e1.PRCo and p1.PRGroup = e1.PRGroup and p1.Employee = e1.Employee
			and e1.PayMethodDelivery <> 'N'
			where p1.PRCo = @co 
				and p1.PREndDate = @prenddate
				and p1.PRGroup = @prgroup
				and p1.PaySeq = @payseq 
				and p1.CMRef is not null
		end
	else
		begin
			select p1.Employee, e1.Email, e1.PayMethodDelivery, p1.KeyID, p1.UniqueAttchID
			from dbo.PRSQ (nolock) p1 
			join dbo.PREH (nolock) e1 on p1.PRCo = e1.PRCo and p1.PRGroup = e1.PRGroup and p1.Employee = e1.Employee
			and e1.PayMethodDelivery <> 'N'
			where p1.PRCo = @co 
				and p1.PREndDate = @prenddate
				and p1.PRGroup = @prgroup 
				and p1.PaySeq = @payseq 
				and p1.Employee = @empl
				and p1.CMRef is not null 
		end

GO
GRANT EXECUTE ON  [dbo].[vspPRPayStubNotifyList] TO [public]
GO
