SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRTSApproveGridFill]
/************************************************************************
* CREATED:	mh 5/14/07    
* MODIFIED: mh 01/12/09 - 131479 Remove InUseBy from select.   
*
* Purpose of Stored Procedure
*
*    Retrieve a set of TimeSheets based on PRCo and PRGroup.  Set will be filtered in UI based 
*	 on User criteria.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, @prgroup bGroup)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	select p.PostDate, p.SheetNum, p.JCCo, p.Job, j.Description as 'JobDesc', 
	p.Crew, r.Description as 'CrewDesc', 
	p.CreatedBy, p.Status as 'SheetStatus', case p.Status when 2 then 'Y' else 'N' end as 'Approved', p.ApprovedBy
	from PRRH p 
	join JCJM j on p.JCCo = j.JCCo and p.Job = j.Job
	Join PRCR r on p.PRCo = r.PRCo and p.Crew = r.Crew
	where p.PRCo = @prco and p.PRGroup = @prgroup and p.Status in (1,2)
	
vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTSApproveGridFill] TO [public]
GO
