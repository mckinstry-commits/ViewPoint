SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*=============================================
-- Author:		Jacob Van Houten
-- Create date: 8/6/09
-- Modified By:	GF 09/06/2010 - issue #141031 changed to use function vfDateOnly
--				MV 09/20/10 - #140022 - set @Reviewer to null if it's an empty string. 
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
__				MH 3/3/11 - 142635 - Need to include PRCo as an input parameter.  Also, removed the @startdate (extra variable referenced in AMR's note)
				local variable.  Not needed since this is a parameter too.
				JayR 10/16/2012 TK-16099 Fix overlapping variable issue.
				
	modified: MarkH 03/02/10 - Issue 136720.  Essentially re-wrote procedure.  Only original code
	is the parameter list and the update statement.  Before approving all lines we need to check
	the phase/cost type combination is valid. Accomplish this by spinning through all the lines to be
	approved and calling bspPRJCCostTypeVal (Procedure used by Timecard Entry to accomplish this).  
	Upon the first found record that has an invalid phase/cost type combination the procedure will exit
	and return an error message informing the user which Employee/Job/Phase is in error.
	
	Modified: MarkH 05/03/10 - 136170/137212.  Backed off the phase/cost type validation.  We will still
	validate and return a message if there are any invalid combinations.  However, we will continue and approve
	all lines that can be approved.  Message is returned to user who will have to manually approve the lines.

-- Description:	Approves all PRMyTimesheetDetail records the a given reviewer is allowed to approve for a given date
-- =============================================*/

CREATE PROCEDURE [dbo].[vspPRMyTimesheetApproveAll]
	(@PRCo bCompany, @Reviewer VARCHAR(3), @StartDate bDate, @Approver bVPUserName, @returnmsg varchar(500) output )
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--#142350 - renaming @startdate
	declare @prco_lower bCompany, @employee bEmployee, @jcco bCompany, @job bJob, @phase bPhase, 
	@earncode bEDLCode, @rcode int, @opencurs tinyint, @dayone bHrs, @daytwo bHrs, 
	@daythree bHrs, @dayfour bHrs, @dayfive bHrs, @daysix bHrs, @dayseven bHrs,	@hoursposted bYN,
	@entryemployee bEmployee, @sheet smallint, @seq smallint
		
	select @opencurs = 0, @dayone = null, @daytwo = null, @daythree = null, @dayfour = null, 
	@dayfive = null, @daysix = null, @dayseven = null

	IF @Reviewer = '' SELECT @Reviewer = NULL 
		
	--Cycle through each line and validate the Phase/Cost Type. 
	
	declare cValPhaseCT cursor local fast_forward for
	select PRCo,	
	EntryEmployee, Sheet, Seq,	
	Employee, JCCo, Job, Phase, EarnCode, DayOne, DayTwo, DayThree,
	DayFour, DayFive, DaySix, DaySeven	
	from PRMyTimesheetDetailForApproval with (nolock) 
	where Approved = 'N' AND [Status] = 1 AND (Reviewer = @Reviewer OR (Reviewer IS NULL AND @Reviewer IS NULL)) 
	AND StartDate = @StartDate and PRCo = @PRCo
	
	open cValPhaseCT
	select @opencurs = 1
	
	fetch next from cValPhaseCT into @prco_lower, @entryemployee, @sheet, @seq, 
	@employee, @jcco, @job, @phase, @earncode, @dayone,
	@daytwo, @daythree, @dayfour, @dayfive, @daysix, @dayseven
	

	while @@fetch_status = 0
	begin
		
		if isnull(@dayone, 0) <> 0 select @hoursposted = 'Y'
		if isnull(@daytwo, 0) <> 0 select @hoursposted = 'Y'
		if isnull(@daythree, 0) <> 0 select @hoursposted = 'Y'
		if isnull(@dayfour, 0) <> 0 select @hoursposted = 'Y'
		if isnull(@dayfive, 0) <> 0 select @hoursposted = 'Y'
		if isnull(@daysix, 0) <> 0 select @hoursposted = 'Y'
		if isnull(@dayseven, 0) <> 0 select @hoursposted = 'Y'
		
		if @hoursposted = 'Y' 
		begin
			exec @rcode = bspPRJCCostTypeVal @prco_lower, @earncode, @jcco, @job, @phase, @returnmsg output
			
			if @rcode <> 0
			begin
				select @rcode = 7
				--select @returnmsg = 'Employee: ' + convert(varchar, @employee) + ' ' + @returnmsg
				select @returnmsg = 'One or more employees have invalid Job Phase/Cost Type combinations.  Those records must be manually approved.'
				
				--goto vspexit
			end
			else
			begin
				UPDATE PRMyTimesheetDetailForApproval
				SET Approved = 'Y'
				,ApprovedBy = @Approver
				,ApprovedOn = dbo.vfDateOnly()
				WHERE Approved = 'N' AND [Status] = 1 AND (Reviewer = @Reviewer OR 
					(Reviewer IS NULL AND @Reviewer IS NULL)) AND StartDate = @StartDate
					and EntryEmployee = @entryemployee and StartDate = @StartDate and 
					Sheet = @sheet and Seq = @seq and Employee = @employee and PRCo = @PRCo

			end
					
		end
		
		select @dayone = null, @daytwo = null, @daythree = null, @dayfour = null, @dayfive = null,
		@daysix = null, @dayseven = null
							
		fetch next from cValPhaseCT into @prco_lower, @entryemployee, @sheet, @seq, @employee, 
		@jcco, @job, @phase, @earncode, @dayone,
		@daytwo, @daythree, @dayfour, @dayfive, @daysix, @dayseven
		
	end
		
	
vspexit:

	if @opencurs = 1
	begin
		close cValPhaseCT
		deallocate cValPhaseCT
	end
	
	return @rcode 
	
END





GO
GRANT EXECUTE ON  [dbo].[vspPRMyTimesheetApproveAll] TO [public]
GO
