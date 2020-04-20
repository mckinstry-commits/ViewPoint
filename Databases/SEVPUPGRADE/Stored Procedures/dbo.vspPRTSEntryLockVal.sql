SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRTSEntryLockVal]
/************************************************************************
* CREATED:	MH 5/8/07    
* MODIFIED: MH 05/14/09 - Issue 132377
*			MH 11/24/09 - Issue 136502  
*			MH 02/02/10 - Issue 135876    
*
* Purpose of Stored Procedure
*
*    Validate Employee and Equipment and related tables prior to locking 
*	 crew timesheet.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, @crew varchar(10), @postdate bDate, @sheet smallint, @prgroup bGroup, @msg varchar(255) = '' output)

as
set nocount on

    declare @rcode int, @jcco bCompany, @job bJob, @lockphases bYN, @phasegroup bGroup, @phase bPhase,
	@costtype varchar(10), @progunits bUnits, @costtypeout bJCCType, @umout bUM


    select @rcode = 0

	if (select count(1) from PRRE where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheet) < 1
	begin
		select @msg = 'No employees have been entered for this crew timesheet.  Please resolve before proceeding.', @rcode = 1
		goto vspexit
	end
	
	exec @rcode = bspPRTSEmplPRGroupVal @prco, @crew, @postdate, @sheet, @prgroup, @msg output
	
	if @rcode = 0
	begin
		--Issue 135876 Validate Usage Cost Type and Revenue Code.
		exec @rcode = bspPRTSCostTypesVal @prco, @crew, @postdate, @sheet, @msg output
		if @rcode = 1
		begin
			select @msg = 'Error in Equipment Usage - ' + @msg 
		end
		else
		begin
		
			select @jcco = p.JCCo, @job = p.Job, @lockphases = j.LockPhases, @phasegroup = p.PhaseGroup
			from PRRH p
			join JCJM j on p.JCCo = j.JCCo and p.Job = j.Job
			where p.PRCo = @prco and p.Crew = @crew and p.PostDate = @postdate and p.SheetNum = @sheet

			--Phase 1
			if exists(select 1 from PRRH where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase1 is not null)
			begin
				select @phase = Phase1, @phasegroup = PhaseGroup, @costtype = Phase1CostType, @progunits = Phase1Units
				from dbo.PRRH (nolock) where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase1 is not null

				if isnull(@progunits,0) > 0
				begin
					exec @rcode = vspPRCrewTSCostTypeVal @prco, @jcco, @job, @lockphases, @phasegroup, @phase,
						@costtype, @progunits, @costtypeout output, @umout output, @msg output

					if @rcode = 1
					begin
						goto vspexit
					end
				end	
			end

			
			--Phase 2	
			if exists(select 1 from PRRH where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase2 is not null)
			begin
				select @phase = Phase2, @phasegroup = PhaseGroup, @costtype = Phase2CostType, @progunits = Phase2Units
				from dbo.PRRH (nolock) where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase1 is not null

				if isnull(@progunits,0) > 0
				begin
					exec @rcode = vspPRCrewTSCostTypeVal @prco, @jcco, @job, @lockphases, @phasegroup, @phase,
						@costtype, @progunits, @costtypeout output, @umout output, @msg output

					if @rcode = 1
					begin
						goto vspexit
					end
				end			
			end


			--Phase 3
			if exists(select 1 from PRRH where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase3 is not null)
			begin
				select @phase = Phase3, @phasegroup = PhaseGroup, @costtype = Phase3CostType, @progunits = Phase3Units
				from dbo.PRRH (nolock) where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase3 is not null


				if isnull(@progunits,0) > 0
				begin
					exec @rcode = vspPRCrewTSCostTypeVal @prco, @jcco, @job, @lockphases, @phasegroup, @phase,
						@costtype, @progunits, @costtypeout output, @umout output, @msg output

					if @rcode = 1
					begin
						goto vspexit
					end
				end
			end

			--Phase 4
			if exists(select 1 from PRRH where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase4 is not null)
			begin
				select @phase = Phase4, @phasegroup = PhaseGroup, @costtype = Phase4CostType, @progunits = Phase4Units
				from dbo.PRRH (nolock) where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase4 is not null

				if isnull(@progunits,0) > 0
				begin
					exec @rcode = vspPRCrewTSCostTypeVal @prco, @jcco, @job, @lockphases, @phasegroup, @phase,
						@costtype, @progunits, @costtypeout output, @umout output, @msg output

					if @rcode = 1
					begin
						goto vspexit
					end
				end
			end

			--Phase 5
			if exists(select 1 from PRRH where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase5 is not null)
			begin
				select @phase = Phase5, @phasegroup = PhaseGroup, @costtype = Phase5CostType, @progunits = Phase5Units
				from dbo.PRRH (nolock) where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase5 is not null

				if isnull(@progunits,0) > 0
				begin
					exec @rcode = vspPRCrewTSCostTypeVal @prco, @jcco, @job, @lockphases, @phasegroup, @phase,
						@costtype, @progunits, @costtypeout output, @umout output, @msg output

					if @rcode = 1
					begin
						goto vspexit
					end
				end
			end

			--Phase 6
			if exists(select 1 from PRRH where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase6 is not null)
			begin
				select @phase = Phase6, @phasegroup = PhaseGroup, @costtype = Phase6CostType, @progunits = Phase6Units
				from dbo.PRRH (nolock) where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase6 is not null

				if isnull(@progunits,0) > 0
				begin
					exec @rcode = vspPRCrewTSCostTypeVal @prco, @jcco, @job, @lockphases, @phasegroup, @phase,
						@costtype, @progunits, @costtypeout output, @umout output, @msg output

					if @rcode = 1
					begin
						goto vspexit
					end
				end
			end

			--Phase 7
			if exists(select 1 from PRRH where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase7 is not null)
			begin
				select @phase = Phase7, @phasegroup = PhaseGroup, @costtype = Phase7CostType, @progunits = Phase7Units
				from dbo.PRRH (nolock) where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase7 is not null

				if isnull(@progunits,0) > 0
				begin
					exec @rcode = vspPRCrewTSCostTypeVal @prco, @jcco, @job, @lockphases, @phasegroup, @phase,
						@costtype, @progunits, @costtypeout output, @umout output, @msg output

					if @rcode = 1
					begin
						goto vspexit
					end
				end
			end

			--Phase 8
			if exists(select 1 from PRRH where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase8 is not null)
			begin
				select @phase = Phase8, @phasegroup = PhaseGroup, @costtype = Phase8CostType, @progunits = Phase8Units
				from dbo.PRRH (nolock) where PRCo = @prco and Crew = @crew and PostDate = @postdate and 
				SheetNum = @sheet and Phase8 is not null

				if isnull(@progunits,0) > 0
				begin
					exec @rcode = vspPRCrewTSCostTypeVal @prco, @jcco, @job, @lockphases, @phasegroup, @phase,
						@costtype, @progunits, @costtypeout output, @umout output, @msg output

					if @rcode = 1
					begin
						goto vspexit
					end
				end
			end

		end
	end

vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTSEntryLockVal] TO [public]
GO
