SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSEmplInit    Script Date: 8/28/99 9:35:39 AM ******/
      CREATE          proc [dbo].[bspPRTSEmplInit]
      /****************************************************************************
       * CREATED BY: EN 3/3/03
       * MODIFIED By :	EN 8/13/03 - issue 21955  do not add employee more than once if entered multiple times in crew
       *					EN 11/22/04 - issue 22571  relabel "Posting Date" to "Timecard Date"
       *
       * USAGE:
       * Initializes employee entries in bPRRE based on employee entries for crew in bPRCW.
       * 
       *  INPUT PARAMETERS
       *   @prco			PR Company
       *   @crew			PR Crew
       *   @postdate		Posting Date
       *	 @sheet			Timesheet Sheet #
       *	 @jcco			Timesheet JC company
       *	 @job			Timesheet Job
       *	 @phase1		Phase1 value to update
       *	 @phase2		Phase2 value to update
       *	 @phase3		Phase3 value to update
       *	 @phase4		Phase4 value to update
       *	 @phase5		Phase5 value to update
       *	 @phase6		Phase6 value to update
       *	 @phase7		Phase7 value to update
       *	 @phase8		Phase8 value to update
       *	 @shift			Shift code
       *
       * OUTPUT PARAMETERS
       *   @msg      error message if error occurs 
       *
       * RETURN VALUE
       *   0         success
       *   1         Failure
       ****************************************************************************/ 
      (@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null,
       @sheet smallint = null, @jcco bCompany = null, @job bJob = null, @phase1 bPhase = null,
       @phase2 bPhase = null, @phase3 bPhase = null, @phase4 bPhase = null, @phase5 bPhase = null, 
       @phase6 bPhase = null, @phase7 bPhase = null, @phase8 bPhase = null, @shift tinyint = 1,
       @msg varchar(60) output)
      as
      
      set nocount on
      
      declare @rcode int, @numrows int
      
      declare @employee bEmployee, @seq smallint, @template smallint, @craft bCraft, @jobcraft bCraft, 
      	@class bClass, @reghrs1 bHrs, @othrs1 bHrs, @dblhrs1 bHrs, @reghrs2 bHrs, @othrs2 bHrs, 
      	@dblhrs2 bHrs, @reghrs3 bHrs, @othrs3 bHrs, @dblhrs3 bHrs, @reghrs4 bHrs, @othrs4 bHrs, 
      	@dblhrs4 bHrs, @reghrs5 bHrs, @othrs5 bHrs, @dblhrs5 bHrs, @reghrs6 bHrs, @othrs6 bHrs, 
      	@dblhrs6 bHrs, @reghrs7 bHrs, @othrs7 bHrs, @dblhrs7 bHrs, @reghrs8 bHrs, @othrs8 bHrs, 
      	@dblhrs8 bHrs, @regearncode bEDLCode, @otearncode bEDLCode, @dblearncode bEDLCode,
     	@crewregec bEDLCode, @crewotec bEDLCode, @crewdblec bEDLCode, @regrate bUnitCost,
     	@otrate bUnitCost, @dblrate bUnitCost, @totalhrs bHrs, @errmsg varchar(200)
      
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
      -- validate Sheet number
      if @sheet is null
      	begin
      	select @msg = 'Missing Sheet #!', @rcode = 1
      	goto bspexit
      	end
      -- validate JC company
      if @jcco is null
      	begin
      	select @msg = 'Missing JC Company!', @rcode = 1
      	goto bspexit
      	end
      -- validate Job
      if @job is null
      	begin
      	select @msg = 'Missing Job!', @rcode = 1
      	goto bspexit
      	end
      
      -- spin through employees in PRCW
      select @seq = min(Seq) from PRCW 
      where PRCo=@prco and Crew=@crew and Employee is not null
      WHILE @seq is not null
      	BEGIN
      	--read employee
      	select @employee=Employee from PRCW where PRCo=@prco and Crew=@crew and Seq=@seq
   	--issue 21955  check for duplicate employee
   	if @employee not in (select Employee from bPRRE where PRCo=@prco and Crew=@crew and 
   						PostDate=@postdate and SheetNum=@sheet)
   		begin
   	   	-- get job craft template
   	   	select @template=CraftTemplate from JCJM where JCCo=@jcco and Job=@job --read job template
   	   	-- get craft / class
   	   	select @craft=Craft, @class=Class from PREH where PRCo=@prco and Employee=@employee --read employee craft
   	  	-- check for job craft override
   	   	exec @rcode = bspPRJobCraftDflt @prco, @craft, @template, @jobcraft=@jobcraft output, @msg=@errmsg output
   	  	if @rcode<>0 goto bspexit
   	   	if @jobcraft is not null select @craft=@jobcraft --craft is from PREH unless overridden
   	  
   	  	if @craft is null select @class = null
   	  
   	  	-- get pay rates
   	  	select @regearncode=CrewRegEC, @otearncode=CrewOTEC, @dblearncode=CrewDblEC from PRCO where PRCo=@prco --read company earn codes
   	  
   	  	select @crewregec=RegECOvride, @crewotec=OTECOvride, @crewdblec=DblECOvride --check for crew earn code overrides
   	  	from PRCR where PRCo=@prco and Crew=@crew
   	  
   	  	if @crewregec is not null select @regearncode=@crewregec --apply overrides if found
   	  	if @crewotec is not null select @otearncode=@crewotec
   	  	if @crewdblec is not null select @dblearncode=@crewdblec	
   	  
   	  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get regular pay rate
   	  		@regearncode, @rate=@regrate output, @msg=@msg output
   	  	if @rcode<>0 goto bspexit
   	  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get overtime pay rate
   	  		@otearncode, @rate=@otrate output, @msg=@msg output
   	  	if @rcode<>0 goto bspexit
   	  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get doubletime pay rate
   	  		@dblearncode, @rate=@dblrate output, @msg=@msg output
   	  	if @rcode<>0 goto bspexit
   	  
   	   	-- init hours values
   	   	if @phase1 is not null 
   	   		select @reghrs1=0, @othrs1=0, @dblhrs1=0
   	   	else
   	   		select @reghrs1=null, @othrs1=null, @dblhrs1=null
   	   	if @phase2 is not null 
   	   		select @reghrs2=0, @othrs2=0, @dblhrs2=0	
   	   	else
   	   		select @reghrs2=null, @othrs2=null, @dblhrs2=null
   	   	if @phase3 is not null 
   	   		select @reghrs3=0, @othrs3=0, @dblhrs3=0	
   	   	else
   	   		select @reghrs3=null, @othrs3=null, @dblhrs3=null
   	   	if @phase4 is not null 
   	   		select @reghrs4=0, @othrs4=0, @dblhrs4=0	
   	   	else
   	   		select @reghrs4=null, @othrs4=null, @dblhrs4=null
   	   	if @phase5 is not null 
   	   		select @reghrs5=0, @othrs5=0, @dblhrs5=0	
   	   	else
   	   		select @reghrs5=null, @othrs5=null, @dblhrs5=null
   	   	if @phase6 is not null 
   	   		select @reghrs6=0, @othrs6=0, @dblhrs6=0	
   	   	else
   	   		select @reghrs6=null, @othrs6=null, @dblhrs6=null
   	   	if @phase7 is not null 
   	   		select @reghrs7=0, @othrs7=0, @dblhrs7=0	
   	   	else
   	   		select @reghrs7=null, @othrs7=null, @dblhrs7=null
   	   	if @phase8 is not null 
   	   		select @reghrs8=0, @othrs8=0, @dblhrs8=0	
   	   	else
   	   		select @reghrs8=null, @othrs8=null, @dblhrs8=null
   		
   		-- compute total hours
   		select @totalhrs=@reghrs1+@othrs1+@dblhrs1+@reghrs2+@othrs2+@dblhrs2+@reghrs3+@othrs3+
   			@dblhrs3+@reghrs4+@othrs4+@dblhrs4+@reghrs5+@othrs5+@dblhrs5+@reghrs6+@othrs6+ 
      			@dblhrs6+@reghrs7+@othrs7+@dblhrs7+@reghrs8+@othrs8+@dblhrs8
   
   	   	-- insert employee entry into bPRRE
   	   	insert bPRRE (PRCo, Crew, PostDate, SheetNum, Employee, LineSeq, Craft, Class, Phase1RegHrs,
   	   		Phase1OTHrs, Phase1DblHrs, Phase2RegHrs, Phase2OTHrs, Phase2DblHrs, Phase3RegHrs, Phase3OTHrs,                   
   	   		Phase3DblHrs, Phase4RegHrs, Phase4OTHrs, Phase4DblHrs, Phase5RegHrs, Phase5OTHrs, Phase5DblHrs,                  
   	   		Phase6RegHrs, Phase6OTHrs, Phase6DblHrs, Phase7RegHrs, Phase7OTHrs, Phase7DblHrs, Phase8RegHrs,
   	   		Phase8OTHrs, Phase8DblHrs, RegRate, OTRate, DblRate, TotalHrs)
   	   	values (@prco, @crew, @postdate, @sheet, @employee, 1, @craft, @class, @reghrs1,
   	   		@othrs1, @dblhrs1, @reghrs2, @othrs2, @dblhrs2, @reghrs3, @othrs3, 
   	   		@dblhrs3, @reghrs4, @othrs4, @dblhrs4, @reghrs5, @othrs5, @dblhrs5,
   	   		@reghrs6, @othrs6, @dblhrs6, @reghrs7, @othrs7, @dblhrs7, @reghrs8, 
   	   		@othrs8, @dblhrs8, @regrate, @otrate, @dblrate, @totalhrs)
   	    end
   
      	-- get next bPRCW entry
      	select @seq = min(Seq) from PRCW
      	where PRCo=@prco and Crew=@crew and Employee is not null and Seq>@seq
      	END
      
      
      bspexit:
      	--if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspPRTSEmplInit]'
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSEmplInit] TO [public]
GO
