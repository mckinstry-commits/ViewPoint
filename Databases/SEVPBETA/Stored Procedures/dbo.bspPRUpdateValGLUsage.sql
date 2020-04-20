SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUpdateValGLUsage    Script Date: 8/28/99 9:36:50 AM ******/
CREATE procedure [dbo].[bspPRUpdateValGLUsage]
/***********************************************************
* Created: GG 08/16/99
* Modified: GG 09/13/99 Get Equip Category if passed as null, fixed return code value
*			GG 10/14/99 Remove Equip Category as passed parameter, always pull from bEMEM
*           GG 11/08/99 - Exit if Total and Calculated Revenue equal 0.00
*           EN 6/06/01 - issue #11553 - enhancement to interface hours to GL memo acccounts
*			GG 08/27/01 - #14454 - when processing revenue breakdown, exclude previously interfaced entries with no current amts 
*			GG 02/20/02 - #14175 - JC Department override by Phase
*			DANF 10/30/03 - 22786 Added Phase GL Account valid part over ride.
*			EN 12/09/03 - issue 23061  added isnull check, with (nolock), and dbo
*  			JE 11/15/04 - issue 26213 add flags to not re-read information
*			GG 10/16/07 - #125791 - fix for DDDTShared
*
* Called from bspPRUpdateValGLExp procedure to validate and load
* GL Equipment Usage related distributions into bPRGL prior to a Pay Period update.
*
* Revenue breakdown has already been loaded into bPRRB from bspPRUpdateValJC.  Use the
* GL Accounts and amounts from bPRRB to load the equipment revenue distributions
* into bPRGL.
*
* Errors are written to bPRUR unless fatal.
*
* Inputs:
*   @prco   		PR Company
*   @prgroup  		PR Group to validate
*   @prenddate		Pay Period Ending Date
*   @employee      Employee
*   @payseq        Payment Sequence
*   @postseq       Posting Sequence
*   @emco          EM Co#
*   @equipment     Equipment
*   @emgroup       EM Group
*   @revcode       Revenue Code
*   @jcco          JC Co#
*   @job           Job
*   @jobstatus     Job Status
*   @jcdept        Job Department
*   @phasegroup    Phase Group
*   @phase		  Phase
*   @emctype       JC Cost Type for Equipment usage
*   @usageunits    Posted units of usage
*   @glco          JC GL Co#
*   @mth           Expense month
*   @validphasechars	  Valid # of characters in Phase code
*
* Output:
*   @errmsg      error message if error occurs
*
* Return Value:
*   0         success
*   1         failure
*****************************************************/
    	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @employee bEmployee = null,
  	 @payseq tinyint = null, @postseq smallint = null, @emco bCompany = null, @equipment bEquip = null,
  	 @emgroup bGroup = null, @revcode bRevCode = null, @jcco bCompany = null, @job bJob = null,
       @jobstatus tinyint = null, @jcdept bDept = null, @phasegroup bGroup = null, @phase bPhase = null, 
  	 @emctype bJCCType = null, @usageunits bUnits = null, @glco bCompany = null, @mth bMonth = null,
  	 @validphasechars int = null, @errmsg varchar(255) output)
  
    as
  
    set nocount on
  
    declare @rcode int, @emrate bDollar, @errortext varchar(255), @revamt bDollar, @totalamt bDollar,
    @openRevenue tinyint, @emglco bCompany, @revglacct bGLAcct, @glamt bDollar, @glacct bGLAcct,
    @intercoARGLAcct bGLAcct, @intercoAPGLAcct bGLAcct, @creditamt bDollar, @timeum bUM, @workum bUM,
    @category varchar(10), @glhrs bHrs, @pphase bPhase, 
    @InputMask varchar(30), @InputType tinyint
  
    declare @flg1glco bCompany, @flg1glacct bGLAcct, @flg2glco bCompany, @flg2glacct bGLAcct,
  	@flg3glco bCompany, @flg3glacct bGLAcct, @flg4glco bCompany, @flg4glacct bGLAcct,
  	@flg5phase bPhase, @v5phase bPhase
  
    select @rcode = 0, @glhrs = 0
  
    -- get Phase Format 
    select @InputMask = InputMask, @InputType= InputType
    from dbo.DDDTShared (nolock) where Datatype ='bPhase'
   
    -- Equip Category not passed on usage entry, so get it from EMEM
    select @category = Category from dbo.bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
  
    -- get Equipment Revenue rate
    exec @rcode = bspEMRevRateUMDflt @emco, @emgroup, 'J', @equipment, @category, @revcode, @jcco, @job,
        @emrate output, @timeum output, @workum output, @errortext output
    if @rcode <> 0
        begin
        exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
        goto bspexit
        end
    -- calculate revenue
    select @revamt = isnull((@emrate * @usageunits),0)
  
  -- check sum of revenue by breakdown code
  select @totalamt = isnull(sum(Amt),0)
  from dbo.bPRRB with (nolock)
  where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
      and PaySeq = @payseq and PostSeq = @postseq
  if @revamt <> @totalamt
      begin
      select @errortext = 'EM Revenue total: ' + convert(varchar(12),@revamt) + ' does not match breakdown distribution: '
            + convert(varchar(12),@totalamt)
      exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
      goto bspexit
      end
  
  if @totalamt = 0 and @revamt = 0 goto bspexit
  
  -- create Revenue Breakdown cursor on bPRRB
  declare bcRevenue cursor LOCAL FAST_FORWARD for
  select GLCo, GLRevAcct, Amt
  from dbo.bPRRB with (nolock)
  where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
  	and PaySeq = @payseq and PostSeq = @postseq and Amt <> 0	-- exclude previous interfaced entries with no current value
  	order by GLCo, GLRevAcct 
  open bcRevenue
  select @openRevenue = 1
  
  next_Revenue:
      fetch next from bcRevenue into @emglco, @revglacct, @glamt
      if @@fetch_status = -1 goto end_Revenue
      if @@fetch_status <> 0 goto next_Revenue
  
      if @glamt <> 0
          begin
  		-- validate GL Revenue Account
  		if @flg1glco<>@emglco or @flg1glacct<>@revglacct or @flg1glacct is null --x
  			begin
  	        exec @rcode = bspGLACfPostable @emglco, @revglacct, 'E', @errmsg output
  	        if @rcode = 1
  	            begin
  				select @flg1glco=null
  	            select @errortext = 'Equipment Revenue GL Account: ' + isnull(@errmsg,'')
  	            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	            goto bspexit
  	            end
  			select @flg1glco=@emglco , @flg1glacct=@revglacct
  			end
          -- add GL distribution to Credit Equipment Revenue - EM GL Co#, Expense month
          select @creditamt = -(@glamt)
          exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @emglco, @revglacct, @employee, @payseq, @creditamt, @glhrs
          end
  
  	goto next_Revenue
  
  end_Revenue:
  	close bcRevenue
      deallocate bcRevenue
      select @openRevenue = 0
  
  -- check for GL Account override by Phase - #14175
  select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
  from dbo.bJCDO with (nolock)
  where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and Phase = @phase 
  if @@rowcount = 0 and @validphasechars > 0
  	begin
  	-- check using valid portion
  	--select @pphase = substring(@phase,1,@validphasechars) + '%'
  	if @flg5phase = @phase and @flg5phase<>null 
  		select @pphase = @v5phase
  	else
  		begin
  		select @pphase  = substring(@phase,1,@validphasechars)
      	exec @rcode = dbo.bspHQFormatMultiPart @pphase, @InputMask, @pphase output
  		select @flg5phase = @phase, @v5phase=@pphase
  		end
  	select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
  	from dbo.bJCDO with (nolock)
  	where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and Phase = @pphase 
  	end 
  if @glacct is null 
  	begin
    	-- get GL Expense Account based on posted Phase and EM Usage Cost Type
    	select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
    	from dbo.bJCDC with (nolock)
    	where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and CostType = @emctype
    	if @@rowcount = 0
        	begin
        	select @errortext = 'JC Dept: ' + @jcdept + ' and Cost Type: ' + convert(char(4),@emctype) + ' is invalid.'
        	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
        	goto bspexit
        	end
  	end
  -- validate GL Expense Account
  if @flg2glco<>@glco or @flg2glacct<>@glacct or @flg2glacct is null
  	begin
  	exec @rcode = bspGLACfPostable @glco, @glacct, 'J', @errmsg output
  	if @rcode = 1
  		
  		begin
  		select @flg2glco=null
  	    select @errortext = 'JC Equipment Expense GL Account: ' + isnull(@errmsg,'')
  	    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	    goto bspexit
  	    end
  	select @flg2glco=@glco , @flg2glacct=@glacct
  	end
  
  -- add GL distribution to Debit Equipment Expense - JC GL Co#, Expense month
  exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @revamt, @glhrs
  
    if @glco <> @emglco
        begin
        -- get Intercompany GL Accounts
        select @intercoARGLAcct = ARGLAcct, @intercoAPGLAcct = APGLAcct
        from dbo.bGLIA with (nolock) where ARGLCo = @emglco and APGLCo = @glco
        if @@rowcount = 0
            begin
            select @errortext = 'Missing Intercompany GL Accounts entry for GL Co#s ' + convert(varchar(4),@emglco) +
                ' and ' + convert(varchar(4),@glco)
  
            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
            goto bspexit
            end
        -- validate Interco AR GL Account
  	  if @flg3glco<>@emglco or @flg3glacct<>@intercoARGLAcct or @flg3glacct is null
  		  begin
  	      exec @rcode = bspGLACfPostable @emglco, @intercoARGLAcct, 'N', @errmsg output
  	      if @rcode = 1
  	          begin
  			  select @flg3glco=null
  	          select @errortext = 'Intercompany AR GL Account: ' + isnull(@errmsg,'')
  	          exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	           goto bspexit
  	          end
  		  select @flg3glco=@emglco , @flg3glacct=@intercoARGLAcct
  		  end
        -- validate Interco AP GL Account
  	  if @flg4glco<>@glco or @flg4glacct<>@intercoAPGLAcct or @flg4glacct is null
  		  begin
  	      exec @rcode = bspGLACfPostable @glco, @intercoAPGLAcct, 'N', @errmsg output
  	      if @rcode = 1
  	          begin
  			  select @flg4glco=null
  	          select @errortext = 'Intercompany AP GL Account: ' + isnull(@errmsg,'')
  	          exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	           goto bspexit
  	          end
  		  select @flg4glco=@glco , @flg4glacct=@intercoAPGLAcct
  		  end
  
        -- Credit Intercompany AP  - JC GL Co#, Expense month
        select @creditamt = -(@revamt)
        exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @creditamt, @glhrs
        -- Debit Intercompany AR - EM GL Co#, Expense month
        exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @emglco, @intercoARGLAcct, @employee, @payseq, @revamt, @glhrs
        end
  
    bspexit:
        if @openRevenue = 1
            begin
            close bcRevenue
            deallocate bcRevenue
            end
        --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdateValGLUsage]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdateValGLUsage] TO [public]
GO
