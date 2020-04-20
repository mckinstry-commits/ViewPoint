SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCrewUpdate    Script Date: 8/28/99 9:35:39 AM ******/
     CREATE            proc [dbo].[bspPRCrewUpdate]
     /****************************************************************************
      * CREATED BY: EN 2/28/03
      * MODIFIED By : EN 12/04/03 - issue 23061  added isnull check, with (nolock), and dbo
      *				EN 2/24/04 - issue 23514  update PRGroup as well
      *				EN 11/22/04 - issue 22571  relabel "Posting Date" to "Timecard Date"
	  *				mh 3/14/08 - issue 126709 - StdHours should be sent to PRCW as "Y".
	  *				mh 5/8/09 - issue 133584 - Do not look at PRCW equipment records that do
	  *					not have an employee assigned.
	  *				mh 03/09/10 - issue 135217 - include PhaseGroup for Job Company.
      *
      * USAGE:
      * Updates Crew setup (bPRCR and bPRCW) from timesheet values.  Some values are
      * passed in, others (the employees and equipment) are read from bPRRE, and bPRRQ.
      * 
      *  INPUT PARAMETERS
      *   @prco			PR Company
      *   @crew			PR Crew
      *   @postdate		Posting Date
      *	 @sheet			Timesheet Sheet #
      *	 @jcco			JC company value to update
      *	 @job			Job value to update
      *  @phasegroup	PhaseGroup to update
      *	 @phase1		Phase1 value to update
      *	 @phase2		Phase2 value to update
      *	 @phase3		Phase3 value to update
      *	 @phase4		Phase4 value to update
      *	 @phase5		Phase5 value to update
      *	 @phase6		Phase6 value to update
      *	 @phase7		Phase7 value to update
      *	 @phase8		Phase8 value to update
      *	 @prgroup		PR Group used in timesheet
      *
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs 
      *
      * RETURN VALUE
      *   0         success
      *   1         Failure
      ****************************************************************************/ 
     (@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null,
      @sheet smallint = null, @jcco bCompany = null, @job bJob = null, @phasegroup bGroup = null,
      @phase1 bPhase = null, @phase2 bPhase = null, @phase3 bPhase = null,
      @phase4 bPhase = null, @phase5 bPhase = null, @phase6 bPhase = null,
      @phase7 bPhase = null, @phase8 bPhase = null, @prgroup bGroup = null, @msg varchar(60) output)
     as
     
     set nocount on
     
     declare @rcode int, @numrows int
     
     declare @employee bEmployee, @seq smallint, @emco bCompany, @emgroup bGroup, @equipment bEquip,
   	@usagepct bPct, @prcwseq smallint, @lineseq smallint
     
     select @rcode = 0
	     
     -- validate PRCo
     if @prco is null
     	begin
     	select @msg = 'Missing PR Co#!', @rcode = 1
     	goto bspexit
     	end
     -- validate Crew
     if @crew is null
     	begin
     	select @msg = 'Missing Crew!', @rcode = 1
     	goto bspexit
     	end
     -- validate PostDate
     if @postdate is null
     	begin
     	select @msg = 'Missing Timecard Date!', @rcode = 1
     	goto bspexit
     	end
     
     --135217 - If @phasegroup is null then pull it from HQCO.  If not in HQCO then
     --raise an error.
     if @phasegroup is null
     begin
		select @phasegroup = PhaseGroup from HQCO with (nolock) where HQCo = @jcco
		if @phasegroup is null 
		begin
			select @msg = 'Missing Phase Group for Job Cost Company!', @rcode = 1
			goto bspexit
		end
	 end		
		
     -- update bPRCR
     --Issue 135217 - Include PhaseGroup.
     update dbo.bPRCR	--PRCrews
     set JCCo=@jcco, Job=@job, Phase1=@phase1, Phase2=@phase2, Phase3=@phase3, Phase4=@phase4,
     	Phase5=@phase5, Phase6=@phase6, Phase7=@phase7, Phase8=@phase8, PRGroup=@prgroup, PhaseGroup = @phasegroup
     where PRCo=@prco and Crew=@crew
     
     -- check PRRQ for equipment or needing to be added to PRCW (PR Crew Members) or employee needing to be added to equipment entry
     select @emco = min(EMCo) from dbo.PRRQ with (nolock)
     where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet
     WHILE @emco is not null
     	BEGIN
     	select @emgroup = min(EMGroup) from dbo.PRRQ with (nolock)
     	where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco
     	WHILE @emgroup is not null
     		BEGIN
     		select @equipment = min(Equipment) from dbo.PRRQ with (nolock)
     		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and
     			EMCo=@emco and EMGroup=@emgroup
     		WHILE @equipment is not null
     			BEGIN
   	  		select @lineseq = min(LineSeq) from dbo.PRRQ with (nolock)
   	  		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and
   	  			EMCo=@emco and EMGroup=@emgroup and Equipment=@equipment
   	  		WHILE @lineseq is not null
   	  			BEGIN
   				select @employee = null
   	  			select @employee = Employee from dbo.PRRQ with (nolock) where PRCo=@prco and Crew=@crew and PostDate=@postdate and 
   	  				SheetNum=@sheet and EMCo=@emco and EMGroup=@emgroup and Equipment=@equipment
   	
   				if not exists (select * from dbo.PRCW with (nolock) where PRCo=@prco and Crew=@crew and EMCo=@emco and
   	  					Equipment=@equipment and EMGroup=@emgroup)
   					begin
   					-- get available sequence #
   	  				select @seq = 1
   	  				while (select count(*) from dbo.PRCW with (nolock) where PRCo=@prco and Crew=@crew and Seq=@seq) <> 0
   	  					begin
   	  					select @seq = @seq + 1
   	  					end
   					-- add equipment entry
   					insert dbo.bPRCW (PRCo, Crew, Seq, Employee, UseStdHrs, AddOnHrs, EMCo, Equipment, 
   						EMGroup, RevCode, UsagePct)
   					values(@prco, @crew, @seq, @employee, 'Y', 0, @emco, @equipment, 
   						@emgroup, null, 1)
   					end
   				else
   					if @employee is not null and exists (select * from dbo.PRCW with (nolock) where PRCo=@prco and 
   							Crew=@crew and EMCo=@emco and Equipment=@equipment and EMGroup=@emgroup and
   							Employee is null)
   						update dbo.bPRCW
   	  					set Employee=@employee, UseStdHrs='Y', AddOnHrs=0
   	  					where PRCo=@prco and Crew=@crew and EMCo=@emco and Equipment=@equipment and EMGroup=@emgroup
   
   	  			-- get next bPRRQ entry
   		  		select @lineseq = min(LineSeq) from dbo.PRRQ with (nolock)
   		  		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and
   		  			EMCo=@emco and EMGroup=@emgroup and Equipment=@equipment and LineSeq>@lineseq
   				END
     			select @equipment = min(Equipment) from dbo.PRRQ with (nolock)
     			where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and
     				EMCo=@emco and EMGroup=@emgroup and Equipment>@equipment
     			END
     		select @emgroup = min(EMGroup) from dbo.PRRQ with (nolock)
     		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco and
     			EMGroup>@emgroup
     		END
     	select @emco = min(EMCo) from dbo.PRRQ with (nolock)
     	where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo>@emco
     	END
   
     -- check PRRE for employees needing to be added to PRCW
     select @employee = min(distinct e.Employee) from dbo.PRRE e with (nolock)
     where e.PRCo=@prco and e.Crew=@crew and e.PostDate=@postdate and e.SheetNum=@sheet and
--Issue 133584
--     	e.Employee not in (select w.Employee from dbo.PRCW w with (nolock) where w.PRCo=@prco and w.Crew=@crew)
     	e.Employee not in (select w.Employee from dbo.PRCW w with (nolock) where w.PRCo=@prco and w.Crew=@crew and w.Employee is not null) 
     WHILE @employee is not null
     	BEGIN
       -- get available sequence #
     	select @seq = 1
     	while (select count(*) from dbo.PRCW with (nolock) where PRCo=@prco and Crew=@crew and Seq=@seq) <> 0
     		begin
     		select @seq = @seq + 1
     		end
     	-- insert new bPRCW entry
     	insert dbo.bPRCW (PRCo, Crew, Seq, Employee, UseStdHrs, AddOnHrs, EMCo, Equipment, EMGroup, RevCode, UsagePct)
     		values(@prco, @crew, @seq, @employee, 'Y', 0, null, null, null, null, null)
     	-- find next employee
     	select @employee = min(distinct e.Employee) from dbo.PRRE e with (nolock)
     	where e.PRCo=@prco and e.Crew=@crew and e.PostDate=@postdate and e.SheetNum=@sheet and
--     		e.Employee not in (select w.Employee from dbo.PRCW w with (nolock) where w.PRCo=@prco and w.Crew=@crew) and
     		e.Employee not in (select w.Employee from dbo.PRCW w with (nolock) where w.PRCo=@prco and w.Crew=@crew and w.Employee is not null) and 
     		e.Employee > @employee
     	END
     
     -- delete employee-only entries no longer in PRRE
     delete from dbo.bPRCW
     where PRCo=@prco and Crew=@crew and Employee is not null and Equipment is null and
     	Employee not in (select e.Employee from dbo.PRRE e with (nolock) where e.PRCo=@prco and e.Crew=@crew and
     						e.PostDate=@postdate and e.SheetNum=@sheet)
   
     -- remove employee from entries with equipment where employee is no longer in PRRE and no longer assigned in PRRQ
     update dbo.bPRCW
     set Employee=null, UseStdHrs='Y', AddOnHrs=0
 
     where PRCo=@prco and Crew=@crew and Employee is not null and Equipment is not null and
     	Employee not in (select e.Employee from dbo.PRRE e with (nolock) where e.PRCo=@prco and e.Crew=@crew and
     						e.PostDate=@postdate and e.SheetNum=@sheet) and
   	Equipment not in (select q.Equipment from dbo.PRRQ q with (nolock) where q.PRCo=@prco and q.Crew=@crew and
   						q.PostDate=@postdate and q.SheetNum=@sheet and q.EMCo=bPRCW.EMCo and
   						q.EMGroup=bPRCW.EMGroup and q.Employee=bPRCW.Employee)
   
     -- move employee to employee-only entry where employee is still in PRRE but no longer in PRRQ
     select @prcwseq = min(Seq) from dbo.PRCW with (nolock)
     where PRCo=@prco and Crew=@crew and Employee is not null and Equipment is not null and
     	Employee in (select e.Employee from dbo.PRRE e with (nolock) where e.PRCo=@prco and e.Crew=@crew and
     						e.PostDate=@postdate and e.SheetNum=@sheet) and
   	Equipment not in (select q.Equipment from dbo.PRRQ q with (nolock) where q.PRCo=@prco and q.Crew=@crew and
   						q.PostDate=@postdate and q.SheetNum=@sheet and q.EMCo=PRCW.EMCo and
   						q.EMGroup=PRCW.EMGroup and q.Employee=PRCW.Employee)
     WHILE @prcwseq is not null
     	BEGIN
   	-- read employee #
   	select @employee=Employee from dbo.PRCW with (nolock) where PRCo=@prco and Crew=@crew and Seq=@prcwseq
       -- get available sequence #
     	select @seq = 1
     	while (select count(*) from dbo.PRCW with (nolock) where PRCo=@prco and Crew=@crew and Seq=@seq) <> 0
     		begin
     		select @seq = @seq + 1
     		end
     	-- insert new bPRCW entry
     	insert dbo.bPRCW (PRCo, Crew, Seq, Employee, UseStdHrs, AddOnHrs, EMCo, Equipment, EMGroup, RevCode, UsagePct)
     		values(@prco, @crew, @seq, @employee, 'Y', 0, null, null, null, null, null)
   	-- remove employee from equipment entry
   	update dbo.bPRCW
   	set Employee=null, UseStdHrs='Y', AddOnHrs=0
     	where PRCo=@prco and Crew=@crew and Seq=@prcwseq
     	-- find next entry
     	select @prcwseq = min(Seq) from dbo.PRCW with (nolock)
     	where PRCo=@prco and Crew=@crew and Employee is not null and Equipment is not null and
     	  Employee in (select e.Employee from dbo.PRRE e with (nolock) where e.PRCo=@prco and e.Crew=@crew and
     						e.PostDate=@postdate and e.SheetNum=@sheet) and
   	  Equipment not in (select q.Equipment from dbo.PRRQ q with (nolock) where q.PRCo=@prco and q.Crew=@crew and
   						q.PostDate=@postdate and q.SheetNum=@sheet and q.EMCo=PRCW.EMCo and
   						q.EMGroup=PRCW.EMGroup and q.Employee=PRCW.Employee) and Seq>@prcwseq
     	END
   
   
     -- delete equip-only entries where equip is no longer assigned in PRRQ
     delete from dbo.bPRCW
     where PRCo=@prco and Crew=@crew and Equipment is not null and Employee is null and
   	Equipment not in (select q.Equipment from dbo.PRRQ q with (nolock) where q.PRCo=@prco and q.Crew=@crew and
   						q.PostDate=@postdate and q.SheetNum=@sheet and q.EMCo=bPRCW.EMCo and
   						q.EMGroup=bPRCW.EMGroup and q.Employee is null)
    
     -- remove equip from employees where equip is no longer assigned to crew
     update dbo.bPRCW
     set EMCo=null, Equipment=null, EMGroup=null, RevCode=null
     where PRCo=@prco and Crew=@crew and Equipment is not null and Employee is not null and
   	Equipment not in (select q.Equipment from dbo.PRRQ q with (nolock) where q.PRCo=@prco and q.Crew=@crew and
   						q.PostDate=@postdate and q.SheetNum=@sheet and q.EMCo=bPRCW.EMCo and
   						q.EMGroup=bPRCW.EMGroup)
     
     
     bspexit:
     	if @rcode <> 0 select @msg = isnull(@msg,'') --+ char(13) + char(10) + '[bspPRCrewUpdate]'
     	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPRCrewUpdate] TO [public]
GO
