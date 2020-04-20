SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRTSEmpInitAddedPhase]
	/******************************************************
	* CREATED BY:	mh 07/02/08 
	* MODIFIED By: 
	*
	* Usage:	Called by trigger btPRRHu to Initialize Hours
	*			for PRRE when a Phase is added to PRRH.
	*
	* Input params:
	*	
	*			@prco - Payroll Company
	*			@crew - Crew
	*			@postdate - Timesheet Post Date
	*			@sheet - Timesheet number
	*			@jcco - Job Company
	*			@job - Job
	*			@phase - Phase being added
	*			@whichphase - Which Phase slot was added (Phase 1 - 8)
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null,
    @sheet smallint = null, @jcco bCompany, @job bJob, @phase bPhase, @whichphase varchar(6), @msg varchar(60) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	declare @employee bEmployee, @lineseq int, @tsql varchar(8000),	@openCurs tinyint

	declare cursPRRE cursor local fast_forward for

	select Employee, LineSeq 
	from PRRE 
	where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheet

	open cursPRRE
	select @openCurs = 1

	fetch next from cursPRRE into  @employee, @lineseq
	
	while @@fetch_status = 0
	begin

		select @tsql = 'Update PRRE set ' + @whichphase + 'RegHrs = 0, ' + @whichphase + 'OTHrs = 0, ' + @whichphase + 'DblHrs = 0 ' +
		' Where PRCo = ' + convert(varchar(3),@prco) + ' and Crew = ' + '''' + @crew + '''' + ' and PostDate = ' + '''' + convert(varchar(25),@postdate) + 
		'''' + ' and SheetNum = ' + convert(varchar(3),@sheet) +  ' and LineSeq = ' + convert(varchar(6), @lineseq)

		exec(@tsql)

		fetch next from cursPRRE into  @employee, @lineseq

	end

	vspexit:

	if @openCurs = 1
	begin
		close cursPRRE
		deallocate cursPRRE
	end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTSEmpInitAddedPhase] TO [public]
GO
