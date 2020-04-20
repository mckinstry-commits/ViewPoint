SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRCrewTSGetStatus]
	/******************************************************
	* CREATED BY:	MarkH 01/20/09 
	* MODIFIED By: 
	*
	* Usage:  Check and return bPRRH.Status value.  Used by Crew Timesheets to 
	*		  determine if a PRRH record can be saved.  
	*	
	*
	* Input params:
	*	
	*		@prco bCompany - Payroll Company
	*		@crew varchar(10) - Crew
	*		@postdate bDate - Timesheet Date
	*		@sheetnum smallint - Timesheet Number
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @crew varchar(10), @postdate bDate, @sheetnum int, @status tinyint output, @msg varchar(100) output

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0, @status = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company.', @rcode = 1
		goto vspexit
	end

	if @crew is null
	begin
		select @msg = 'Missing Crew.', @rcode = 1
		goto vspexit
	end

	if @postdate is null
	begin
		select @msg = 'Missing Sheet Number.', @rcode = 1
		goto vspexit
	end


	select @status = [Status] 
	from dbo.PRRH (nolock) 
	where PRCo = @prco and Crew = @crew	and PostDate = @postdate and SheetNum = @sheetnum
 
	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCrewTSGetStatus] TO [public]
GO
