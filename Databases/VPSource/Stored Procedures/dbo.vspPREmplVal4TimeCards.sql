SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPREmplVal4TimeCards    ******/
   CREATE        proc [dbo].[vspPREmplVal4TimeCards]
   --#135490:  Added @wotaxstate, @wolocalcode, @useunempstate, @useinsstate
   (@prco bCompany, @empl varchar(15), @activeopt varchar(1),
   	@prgroup bGroup, @prenddate bDate, 
	@emplout bEmployee=null output, @prdept bDept = null output, @crew varchar(10) output, 
    @usestate bYN = null output, @insstate varchar(4) = null output, @taxstate varchar(4) = null output, 
   	@uselocal bYN = null output, @local bLocalCode = null output, @unempstate varchar(4) = null output, 
    @craft bCraft = null output, @cert bYN = null output, @inscode bInsCode = null output, 
	@glco bCompany = null output, 
    @emprate bUnitCost = null output, @class bClass = null output, @jcco bCompany output, 
    @job bJob output, @salaryamt bDollar = null output, @earncode bEDLCode = null output, 
    @useins bYN = null output, @shift tinyint = null output, @periodhrs bHrs output, 
	@empEMCo bCompany output, @empEMGroup bGroup output, @empEMEquip bEquip output, 
	@useunempstate bYN = 'N' output, @useinsstate bYN = 'N' output, 
	@crafteffdate bDate = NULL OUTPUT,
	@msg varchar(60) = null output)
   /***********************************************************
    * CREATED BY: EN 2/22/06 - based on 5.x bspPREmplValwithGroup & bspPREmployeeInfoGet
    * MODIFIED By : 2/15/07 - return the pay period hours - used to compute salary employee hours default
	*		EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
    *		mh 2/07/09 - #123591 - Return EMCo, EMGroup and EMEquip assigned to Employee in bPREH.
    *		TJL 02/26/10 - Issue #135490, Add Work Office Tax State & Local Code.  Breakout UnempState & InsState
    *		EN 04/03/2012 D-04782 Return craft effective date for plus copy feature rate default correction
    *
    * Usage:
    *	Used by PRTimeCards to validate Employee and return data that used to be
	*	retrieved by bspPREmployeeInfoGet in 5.x.
    *
    * Input params:
    *	@prco		PR company
    *	@empl		Employee sort name or number
    *	@activeopt	Controls validation based on Active flag
    *			'Y' = must be an active
    *			'X' = can be any value
    *	@prgroup	PR Group
	*	@prenddate	Pay Period Ending Date
    *
    * Output params:
    *	@emplout		Employee number
    *	@prdept			Employee default PR Department
    *	@crew			Employee default Crew 
    *	@usestate		Y = Use Employee States, N = Use Job States
    *	@insstate		Employee default Insurance State
    *	@taxstate		Employee default Tax State
    *	@uselocal		Y = Use Employee Local, N = Use Job Local 
    *	@local			Employee default Local code
    *	@unempstate		Employee default Unemployment State
    *	@craft			Employee default Craft
    *	@cert			Employee default Certified flag (Y/N)
    *	@inscode		Employee default Insurance code
    *	@glco			Employee default GL Company #
    *	@emprate		Employee default pay rate
    *	@class			Employee default Class
    *	@jcco			Employee default JC Company # - last posted
    *	@job			Employee default Job - last posted
    *	@salaryamt		Employee default salary amount
    *	@earncode		Employee default earnings code
    *	@useins			Y = Use Employee default Insurance code, N = Use Job Insurance code
    *	@shift			Employee default shift
	*	@periodhrs		Hours posted to pay period (used to compute salary employee hours default)
	*	@empEMCo		EM Company assigned to Employee in bPREH
	*	@empEMGroup		EM Group assigned to Employee in bPREH (M.B.U.)
	*	@empEMEquip		EM Equipment assigned to Employee in bPREH
    *	@msg			Employee Name or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    **************************************************************************/ 
	as
	set nocount on
	declare @rcode int, @lastname varchar(30), @firstname varchar(30), @middlename varchar(15), 
	@active bYN, @empgroup bGroup, @suffix varchar(4)
	
	select @rcode = 0
   
   /* check required input params */	
   
	if @empl is null
   	begin
   		select @msg = 'Missing Employee.', @rcode = 1
   		goto bspexit
   	end

	if @activeopt is null
   	begin
   		select @msg = 'Missing Active option for Employee validation.', @rcode = 1
   		goto bspexit
   	end
   	
   /* If @empl is numeric then try to find Employee number */
   --if isnumeric(@empl) = 1
   --24734 Added call to function and check for len @empl
	if dbo.bfIsInteger(@empl) = 1
	begin
   		if len(@empl) < 7
   		begin
   			----#135490: Added UseUnempState, UseInsState
   			select @emplout = Employee, @lastname=LastName, @firstname=FirstName, @middlename=MidName, 
			@active=ActiveYN, @empgroup=PRGroup, @suffix = Suffix, @prdept = PRDept, @crew = Crew, 
			@usestate = UseState, @uselocal = UseLocal, @useins = UseIns, 
			@useunempstate = UseUnempState, @useinsstate = UseInsState,  
			@taxstate = isnull(WOTaxState,TaxState), @local = isnull(WOLocalCode,LocalCode),
			@insstate = InsState, @unempstate = UnempState, @craft = Craft, @cert = CertYN,
 			@inscode = InsCode, @glco = GLCo, @emprate = HrlyRate, @class = Class, @jcco = JCCo, 
			@job = Job, @salaryamt = SalaryAmt, @earncode = EarnCode, @shift = Shift, @empEMCo = EMCo,
			@empEMGroup = EMGroup, @empEMEquip = Equipment 
   			from dbo.PREH (nolock)
   			where PRCo=@prco and Employee= convert(int,convert(float, @empl))
   		end
   		else
   		begin
   			select @msg = 'Invalid Employee Number, length must be 6 digits or less.', @rcode = 1
   			goto bspexit
   		end
	end
   
   /* if not numeric or not found try to find as Sort Name */
   if @@rowcount = 0
   begin
		----#135490: Added UseUnempState, UseInsState
		select @emplout = Employee, @lastname=LastName, @firstname=FirstName, @middlename=MidName, 
		@active=ActiveYN, @empgroup=PRGroup, @suffix = Suffix, @prdept = PRDept, @crew = Crew, 
		@usestate = UseState, @uselocal = UseLocal, @useins = UseIns, 
		@useunempstate = UseUnempState, @useinsstate = UseInsState,  
		@taxstate = isnull(WOTaxState,TaxState), @local = isnull(WOLocalCode,LocalCode),
		@insstate = InsState, @unempstate = UnempState, @craft = Craft, @cert = CertYN,
		@inscode = InsCode, @glco = GLCo, @emprate = HrlyRate, @class = Class, @jcco = JCCo, 
		@job = Job, @salaryamt = SalaryAmt, @earncode = EarnCode, @shift = Shift, @empEMCo = EMCo,
		@empEMGroup = EMGroup, @empEMEquip = Equipment 
   		from dbo.PREH (nolock) where PRCo=@prco and SortName = @empl

      	 /* if not found,  try to find closest */
		if @@rowcount = 0
        begin
           	set rowcount 1
   			----#135490: Added UseUnempState, UseInsState
   			select @emplout = Employee, @lastname=LastName, @firstname=FirstName, @middlename=MidName, 
			@active=ActiveYN, @empgroup=PRGroup, @suffix = Suffix, @prdept = PRDept, @crew = Crew, 
			@usestate = UseState, @uselocal = UseLocal, @useins = UseIns, 
			@useunempstate = UseUnempState, @useinsstate = UseInsState,  
			@taxstate = isnull(WOTaxState,TaxState), @local = isnull(WOLocalCode,LocalCode),
			@insstate = InsState, @unempstate = UnempState, @craft = Craft, @cert = CertYN,
 			@inscode = InsCode, @glco = GLCo, @emprate = HrlyRate, @class = Class, @jcco = JCCo, 
			@job = Job, @salaryamt = SalaryAmt, @earncode = EarnCode, @shift = Shift, @empEMCo = EMCo,
			@empEMGroup = EMGroup, @empEMEquip = Equipment 
			from dbo.PREH (nolock)
   			where PRCo= @prco and SortName like @empl + '%'

	   		if @@rowcount = 0
      		begin
   	    		select @msg = 'Not a valid Employee', @rcode = 1
   				goto bspexit
   	   		end
   		end
   	end

	if @empgroup<>@prgroup
   	begin
    	select @msg = 'Employee must be assigned to PR Group ' + convert(char(3),@prgroup), @rcode=1
   	goto bspexit
   	end
   
	if @activeopt <> 'X' and @active <> @activeopt
   	begin
   		select @msg = 'Must be an active Employee.' , @rcode = 1
   		goto bspexit
   	end
   
	-- get hours already posted to pay period
    -- check existing timecards in bPRTH
    select @periodhrs = isnull(sum(t.Hours),0)
    from dbo.bPRTH t with (nolock)
    join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
    where t.PRCo = @prco and t.Employee = @emplout and t.PREndDate = @prenddate
     	and t.InUseBatchId is null	-- exlcude timecards in a batch
   -- check timecard batches - bPRTB
   select @periodhrs = @periodhrs + isnull(sum(b.Hours),0)
    from dbo.bPRTB b with (nolock)
    join dbo.bPREC e with (nolock) on e.PRCo = b.Co and e.EarnCode = b.EarnCode
    join dbo.HQBC h with (nolock) on h.Co = b.Co and h.Mth = b.Mth and h.BatchId = b.BatchId
    where b.Co = @prco and b.Employee = @emplout and h.PREndDate = @prenddate and b.BatchTransType <> 'D' --and
    	--(b.Mth <> @mth or b.BatchId <> @batchid or (b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq <> @tcseq))

   if @suffix is null select @msg=@lastname + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   if @suffix is not null select @msg=@lastname + ' ' + @suffix + ', ' + isnull(@firstname,'') + ' ' + isnull(@middlename,'')
   
   -- D-04782 get craft effective date
   SELECT @crafteffdate = EffectiveDate 
   FROM dbo.bPRCM 
   WHERE	PRCo = @prco AND
			Craft = @craft


   bspexit:

   	return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspPREmplVal4TimeCards] TO [public]
GO
