SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRTSSendGridFill]
/************************************************************************
* CREATED:	mh 5/17/2007    
* MODIFIED:	mh 06/04/2008 - Issue 128542 - do not include post date in where
*							clause.  Set will be filtered in calling form.   
*			mh 01/12/2009 - Issue 131479 - Remove InUseBy references. 
*
* Purpose of Stored Procedure
*
*	Fill PRCrew Timesheet Send grid.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, @prgroup bGroup /*, @postdate bDate*/, @restrictjob bYN, @jcco bCompany, @job bJob)

as
set nocount on

	if @restrictjob = 'Y'
	begin
		Select PRRH.PostDate, PRRH.SheetNum, PRRH.JCCo, PRRH.Job, 
		JCJM.Description as 'JobDesc', PRRH.Crew, PRCR.Description as 'CrewDesc', PRRH.CreatedBy, 
		PRRH.Status as 'SheetStatus', /*PRRH.InUseBy,*/ PRRH.ApprovedBy, PRRH.SendSeq 
		from PRRH
		join JCJM on PRRH.JCCo = JCJM.JCCo and PRRH.Job = JCJM.Job 
		join PRCR on PRRH.PRCo = PRCR.PRCo and PRRH.Crew = PRCR.Crew
		where PRRH.PRCo = @prco and PRRH.PRGroup = @prgroup /*and PRRH.PostDate <=@postdate*/ and
		PRRH.Status in (1,2) and PRRH.JCCo = @jcco and PRRH.Job = @job
	end
	else
	begin
		Select PRRH.PostDate, PRRH.SheetNum, PRRH.JCCo, PRRH.Job, 
		JCJM.Description as 'JobDesc', PRRH.Crew, PRCR.Description as 'CrewDesc', PRRH.CreatedBy, 
		PRRH.Status as 'SheetStatus', /*PRRH.InUseBy,*/ PRRH.ApprovedBy, PRRH.SendSeq 
		from PRRH
		join JCJM on PRRH.JCCo = JCJM.JCCo and PRRH.Job = JCJM.Job 
		join PRCR on PRRH.PRCo = PRCR.PRCo and PRRH.Crew = PRCR.Crew
		where PRRH.PRCo = @prco and PRRH.PRGroup = @prgroup /*and PRRH.PostDate <=@postdate*/ and
		PRRH.Status in (1,2) 
	end

GO
GRANT EXECUTE ON  [dbo].[vspPRTSSendGridFill] TO [public]
GO
