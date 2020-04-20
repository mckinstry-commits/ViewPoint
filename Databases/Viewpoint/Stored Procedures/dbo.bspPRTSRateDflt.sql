SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSRateDflt    Script Date: 8/28/99 9:35:39 AM ******/
      CREATE            proc [dbo].[bspPRTSRateDflt]
      /****************************************************************************
       * CREATED BY: EN 9/25/03
       * MODIFIED By:	EN 11/22/04 - issue 22571  relabel "Posting Date" to "Timecard Date"
       *
       * USAGE:
       * Initializes employee entries in bPRRE based on employee entries for crew in bPRCW.
       * 
       *  INPUT PARAMETERS
       *   @prco			PR Company
   	*	@crew			Crew code
       *   @postdate		Posting Date
   	*	@sheetnum		Timesheet sheet # (only used if update rates for all employees)
       *   @employee		Employee code (only used if updating rates for one employee)
       *	@craft			Craft code (only used if updating rates for one employee)
       *	@class			Class code (only used if updating rates for one employee)
       *	@template		Timesheet job's Craft Template
       *	@shift			Shift code
       *
       * OUTPUT PARAMETERS
   	*	@regrate		straight time pay rate (only if updating rates for one employee)
   	*	@otrate			overtime pay rate (only if updating rates for one employee)
   	*	@dblrate		doubletime pay rate (only if updating rates for one employee)
       *   @msg      error message if error occurs 
       *
       * RETURN VALUE
       *   0         success
       *   1         Failure
       ****************************************************************************/ 
      (@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null, 
   	@sheetnum smallint = null, @employee bEmployee = null, @craft bCraft = null, 
   	@class bClass = null, @template smallint = null, @shift tinyint = 0, 
   	@regrate bUnitCost output, @otrate bUnitCost output, @dblrate bUnitCost output,
   	@msg varchar(60) output)
      as
      
      set nocount on
      
      declare @rcode int, @opencursorPRRE int,	@regearncode bEDLCode, @otearncode bEDLCode, 
   	@dblearncode bEDLCode, @crewregec bEDLCode, @crewotec bEDLCode, @crewdblec bEDLCode, 
   	@lineseq smallint, @errmsg varchar(200)
      
      select @rcode = 0, @opencursorPRRE = 0
   
     
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
      -- validate Posting Date
      if @postdate is null
      	begin
      	select @msg = 'Missing Timecard Date!', @rcode = 1
      	goto bspexit
      	end
      -- validate Sheet Number
      if @employee is null and @sheetnum is null
      	begin
      	select @msg = 'Missing Sheet #!', @rcode = 1
      	goto bspexit
      	end
   --   -- validate Craft
   --   if @employee is not null and @craft is null
   --   	begin
   --  	select @msg = 'Missing Craft!', @rcode = 1
   --   	goto bspexit
   --   	end
   --   -- validate Class
   --   if @employee is not null and @class is null
   --   	begin
   --   	select @msg = 'Missing Class!', @rcode = 1
   --   	goto bspexit
   --   	end
   --   -- validate Template
   --   if @template is null
   --   	begin
   --   	select @msg = 'Missing Template!', @rcode = 1
   --   	goto bspexit
   --   	end
      -- validate Shift
      if @shift is null
      	begin
      	select @msg = 'Missing Shift!', @rcode = 1
      	goto bspexit
      	end
      
   	-- return rates for one employee
   	if @employee is not null
   		begin  
   	  	-- get earnings codes
   	  	select @regearncode=CrewRegEC, @otearncode=CrewOTEC, @dblearncode=CrewDblEC from PRCO where PRCo=@prco --read company earn codes
   	  
   	  	select @crewregec=RegECOvride, @crewotec=OTECOvride, @crewdblec=DblECOvride --check for crew earn code overrides
   	  	from PRCR where PRCo=@prco and Crew=@crew
   	  
   	  	if @crewregec is not null select @regearncode=@crewregec --apply overrides if found
   	  	if @crewotec is not null select @otearncode=@crewotec
   	  	if @crewdblec is not null select @dblearncode=@crewdblec	
   	  
   		-- get pay rates
   	  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get regular pay rate
   	  		@regearncode, @rate=@regrate output, @msg=@msg output
   	  	if @rcode<>0 goto bspexit
   	  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get overtime pay rate
   	  		@otearncode, @rate=@otrate output, @msg=@msg output
   	  	if @rcode<>0 goto bspexit
   	  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get doubletime pay rate
   	  		@dblearncode, @rate=@dblrate output, @msg=@msg output
   	  	if @rcode<>0 goto bspexit
   		end
   	  
   	-- refresh rates for entire timesheet
   	if @employee is null
   		begin
   	  	-- get earnings codes
   	  	select @regearncode=CrewRegEC, @otearncode=CrewOTEC, @dblearncode=CrewDblEC from PRCO where PRCo=@prco --read company earn codes
   	  
   	  	select @crewregec=RegECOvride, @crewotec=OTECOvride, @crewdblec=DblECOvride --check for crew earn code overrides
   	  	from PRCR where PRCo=@prco and Crew=@crew
   	  
   	  	if @crewregec is not null select @regearncode=@crewregec --apply overrides if found
   	  	if @crewotec is not null select @otearncode=@crewotec
   	  	if @crewdblec is not null select @dblearncode=@crewdblec	
   
   		--declare cursor to spin thru PRRE
   		declare bcPRRE cursor for 
   		select Employee, LineSeq, Craft, Class from PRRE (nolock)
   		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheetnum
   	
   		open bcPRRE
   		select @opencursorPRRE = 1
   
   		fetch next from bcPRRE into @employee, @lineseq, @craft, @class
   		while @@fetch_status = 0
   			begin
   			-- get pay rates

   		  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get regular pay rate
   		  		@regearncode, @rate=@regrate output, @msg=@msg output
   		  	if @rcode<>0 goto bspexit
   		  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get overtime pay rate
   		  		@otearncode, @rate=@otrate output, @msg=@msg output
   		  	if @rcode<>0 goto bspexit
   		  	exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, @shift, --get doubletime pay rate
   		  		@dblearncode, @rate=@dblrate output, @msg=@msg output
   		  	if @rcode<>0 goto bspexit
   
   			-- update PRRE record
   			update bPRRE set RegRate=@regrate, OTRate=@otrate, DblRate=@dblrate
   			where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheetnum and
   				Employee=@employee and LineSeq=@lineseq
   
   			fetch next from bcPRRE into @employee, @lineseq, @craft, @class
   			end
   		end
   
      
      bspexit:
   	if @opencursorPRRE = 1
   		begin
       	close bcPRRE
       	deallocate bcPRRE
       	end
   
      	--if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspPRTSRateDflt]'
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSRateDflt] TO [public]
GO
