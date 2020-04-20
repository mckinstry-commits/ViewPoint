SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCrewInit    Script Date: 8/28/99 9:35:30 AM ******/
   /****** Object:  Stored Procedure dbo.bspPRCrewInit    Script Date: 2/12/97 3:25:02 PM ******/
CREATE       procedure [dbo].[bspPRCrewInit]
/****************************************************************
* CREATED BY:	kb	02/17/98
* MODIFIED By : kb	02/17/98
*				EN	09/12/00	- Fix to use variable earnings rates if any have been set up
*				MV	09/14/01	- Issue 13576 equipctype should have a value inserted if PRCW equip not null
*				EN	06/24/02	- issue 17696 use phaseinscode if applicable
*				EN	03/17/03	- issue 16532 only find crew entries with non-null employee value
*				EN	05/22/03	- issue 21284  include EquipPhase in bPRTB insert using @phase value
*				EN	05/28/03	- issue 21290  allow for possible 0 hours ... in such a case set rate to 0
*				EN	03/15/05	- issue 27283  correct field defaults to match timecard entry standards
*				EN	03/22/05	- issue 27459  check for ins. by phase using valid portion of phase
*				EN	03/07/08	- #127081  in declare statements change State declarations to varchar(4)
*				CHS 06/18/10	- issue #140255
* 
* USAGE:
* This procedure is used by the PR Crew Initialize form to initialize timecard entries
* into bPRTB.
*
* INPUT PARAMETERS
*   Co         PR Co to pull from
*   Mth
*   BatchId
*   Crew
*   PaySeq
*   Posting Date
*   JCCo
*   Job
*   Phase
*   Hours
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
****************************************************************/
   
@co bCompany, @mth bMonth, @batchid bBatchID, @crew varchar(10), @payseq tinyint, @postdate bDate,
@jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @stdhrs bHrs,@glco bCompany,
@errmsg varchar(200) output
   
   as
   set nocount on
   declare @rcode int, @type char(1), @emco bCompany, @wo bWO, @woitem bItem, @template smallint,
   	@equip bEquip, @emgroup bGroup, @costcode bCostCode, @comptype varchar(10), @component bEquip,
   	@revcode bRevCode, @emctype bJCCType, @usageunits bHrs, @taxstate varchar(4), @localcode bLocalCode,
   	@unempstate varchar(4), @insstate varchar(4), @inscode bInsCode, @prdept bDept, @method char(1),
   	@cert bYN, @craft bCraft, @class bClass, @earncode bEDLCode, @shift tinyint, @hours bHrs, @rate bUnitCost,
   	@amt bDollar, @seq smallint, @employee bEmployee, @postseq smallint, @opencursor tinyint,@equipjcct bJCCType,
   	@usestdhrs bYN, @addonhrs bHrs, @usagepct bPct, @activeYN bYN, @salaryamt bDollar, @daynum smallint,
   	@begindate bDate, @useins char(1) /*issue 17696*/, @phaseinscode bInsCode /*issue 17696*/
   
   --issue 27283 declarations
   declare @jobcraft bCraft, @equipclass bClass, @category varchar(10), @jobstate varchar(4), @joblocal bLocalCode,
   	@jobtaxstate varchar(4), @emptaxstate varchar(4), @empunempstate varchar(4), @empinsstate varchar(4), @emplocalcode bLocalCode,
   	@useempstate bYN, @useemplocal bYN, @taxstateopt bYN, @unempstateopt bYN, @insstateopt bYN, @localopt bYN, 
   	@officestate varchar(4), @officelocal bLocalCode, @insbyphase bYN
   
   --27459 declarations
   declare @validphasechars int, @pphase bPhase
   
   select @rcode = 0
   
   --27283 read PRCO flags
   select @taxstateopt=TaxStateOpt, @unempstateopt=UnempStateOpt, @insstateopt=InsStateOpt, @localopt=LocalOpt, 
   		@officestate=OfficeState, @officelocal=OfficeLocal, @insbyphase=InsByPhase
   from dbo.PRCO where PRCo=@co
   
   select @begindate=PRPC.BeginDate from dbo.HQBC with (nolock)
   	join dbo.PRPC with (nolock) on PRPC.PRCo=HQBC.Co and PRPC.PRGroup=HQBC.PRGroup and PRPC.PREndDate=HQBC.PREndDate
   	where HQBC.Co=@co and HQBC.Mth=@mth and HQBC.BatchId=@batchid
   
   select @daynum=Datediff(day,@begindate,@postdate)+1
   
   /* set open cursor flags to false */
   select @opencursor = 0
   
   
   /* declare cursor on PR Batch for validation */
   declare bcPRCW cursor for select Employee, UseStdHrs, AddOnHrs, EMCo, Equipment, EMGroup, RevCode, UsagePct
   	from dbo.bPRCW with (nolock) where PRCo = @co and Crew=@crew and Employee is not null --issue 16532 look for crew entries with employee
   
   
   /* open cursor */
   
   open bcPRCW
   
   /* set open cursor flag to true */
   select @opencursor = 1
   
   /* loop through all employees in PRCW and update their info.*/
   pr_posting_loop:
   /* get row from PRCW */
   fetch next from bcPRCW into @employee, @usestdhrs, @addonhrs, @emco, @equip, @emgroup, @revcode, @usagepct
   
   if @@fetch_status <> 0
      goto pr_posting_end
   /* add PR transaction to batch */
   
   /* check if employee valid and active */
   select @activeYN=ActiveYN, @emptaxstate=TaxState, @emplocalcode=LocalCode, @empunempstate=UnempState, @empinsstate=InsState,
   	@inscode=InsCode, @prdept=PRDept, @cert=CertYN, @craft=Craft, @class=Class, @earncode=EarnCode, @salaryamt=SalaryAmt,
   	@useempstate=UseState, @useemplocal=UseLocal, @useins=UseIns /*issue 17696*/
   	from dbo.PREH with (nolock) where PRCo=@co and Employee=@employee
   
   if @@rowcount=0 or @activeYN='N' goto pr_posting_loop
   
   --27283 default shift to crew shift, if any ... otherwise set it to 1
   select @shift=isnull(Shift,0) from dbo.bPRCR with (nolock) where PRCo=@co and Crew=@crew
   if @shift<1 or @shift>255 select @shift=1
   
   select @hours=0
   
   if @usestdhrs='Y' select @hours=@stdhrs+@addonhrs
   
   if @usestdhrs='N' select @hours=0+@addonhrs
   
   select @template=CraftTemplate, @jobstate=PRStateCode, @joblocal=PRLocalCode from dbo.JCJM with (nolock) where JCCo=@jcco and Job=@job
   
   select @rate=0, @amt=0, @method=Method from dbo.PREC with (nolock) where PRCo=@co and EarnCode=@earncode
   
   --27283 check craft template for possible job craft override ... otherwise use employee craft
   exec @rcode = bspPRJobCraftDflt @co, @craft, @template, @jobcraft output, @msg=@errmsg output
   if @rcode<>0 goto bspexit
   if @jobcraft is not null select @craft=@jobcraft
   
   -- issue #140255
   --if @method<>'A'
   --	begin
   --	exec @rcode = bspPRRateDefault @co, @employee, @postdate, @craft, @class, @template, @shift, @earncode, @rate output, @errmsg output
   --	if @rcode<>0 goto bspexit
   --	select @amt=@rate*@hours
   --	end
   --else
   --	begin
   --	select @amt=@salaryamt
   --	if @hours<>0 --issue 21290 allow for possible 0 hours ... in such a case set rate to 0
   --		select @rate=@amt/@hours
   --	else
   --		select @rate=0
   --	end
   
   -- 27283 determine job tax state with possible reciprocal agreement to use if job state override
   select @jobtaxstate = @jobstate
   if @jobstate is not null and @emptaxstate is not null and
   		(select count(*) from dbo.HQRS with (nolock) where JobState=@jobstate and 
   		 ResidentState=@emptaxstate)=1
   	select @jobtaxstate = @emptaxstate
   
   -- 27283 determine tax state
   if @useempstate='Y'
   	select @taxstate = @emptaxstate
   else
   	begin
   	if @taxstateopt='Y'
   		select @taxstate = @jobtaxstate
   	else
   		select @taxstate = @emptaxstate
   	end
   
   -- 27283 determine insurance state
   if @useempstate='Y' or (@useempstate='N' and @insstateopt='N')
   	select @insstate = @empinsstate
   else
   	begin
   	if @jobstate is not null
   		select @insstate = @jobstate
   	else
   		select @insstate = @officestate
   	end
   
   -- 27283 determine unemployment state
   if @useempstate='Y' or (@useempstate='N' and @unempstateopt='N')
   	select @unempstate = @empunempstate
   else
   	begin
   	if @jobstate is not null
   		select @unempstate = @jobstate
   	else
   		select @unempstate = @officestate
   	end
   
   -- 27283 determine local code
   select @localcode = @emplocalcode
   if @useemplocal='N' and @localopt='Y'
   	select @localcode = @joblocal
   
   select @usageunits=0
   select @equipjcct = null
   if @equip is not null
	    begin
	    select @usageunits=@usagepct*@hours
	    select @equipjcct = UsageCostType, @category=Category from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @equip --27283 retrieve Category
   		if @@rowcount = 0 --27283 added precaution in case of invalid equipement
   			begin
   			select @errmsg = 'Equipment ' + convert(varchar,@equip) + ' is invalid.', @rcode = 1
   			goto bspexit
   			end
   		--27283 check for class setup by EM category
		--Ellen's note 2/4/2010 - double check but perhaps the following 2 lines of code to override
		--				class should only happen if using equip class override but looks like it's not messing
		--				up the rate in any case
   		select @equipclass=PRClass from dbo.EMCM with (nolock) where EMCo=@emco and Category=@category
   		if @equipclass is not null select @class=@equipclass
		end
		
		
    -- issue #140255
	if @method<>'A'
		begin
		exec @rcode = bspPRRateDefault @co, @employee, @postdate, @craft, @class, @template, @shift, @earncode, @rate output, @errmsg output
			if @rcode<>0 goto bspexit
			
			select @amt=@rate*@hours
		end
	else
		begin
		select @amt=@salaryamt
		
		if @hours<>0 --issue 21290 allow for possible 0 hours ... in such a case set rate to 0
		select @rate=@amt/@hours
		
		else		
		select @rate=0
		
		end		
		
		
   
   --issue 17696 - use phaseinscode if phase is not null, employee ins override is not enforced, and InsByPhase is set in PRCO
   select @phaseinscode = null
   if @phase is not null and @useins = 'N'
   	begin
   	if @insbyphase = 'Y'
   	    begin
   	    select @phaseinscode = t.InsCode
   	    from dbo.JCTI t with (nolock)
   	    join dbo.JCJM j with (nolock) on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
   	    where t.JCCo = @jcco and PhaseGroup = @phasegroup and Phase = @phase
   	        and j.Job = @job
   	    if @@rowcount = 0
   	    	begin
   	    	-- 27459 check Phase Master using valid portion
   	    	-- validate JC Company -  get valid portion of phase code
   	    	select @validphasechars = ValidPhaseChars
   	    	from dbo.JCCO where JCCo = @jcco
   	    	if @@rowcount <> 0
   	    		begin
   	         	if @validphasechars > 0
   	          		begin
   	          		select @pphase = substring(@phase,1,@validphasechars) + '%'
   	
   	          		select Top 1 @phaseinscode = t.InsCode
   	          		from dbo.JCTI t with (nolock)
   	          		join dbo.JCJM j with (nolock) on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
   	          		where t.JCCo = @jcco and t.PhaseGroup = @phasegroup and t.Phase like @pphase and j.Job = @job
   	          		Group By t.PhaseGroup, t.Phase, t.InsCode
   	          		end -- end valid part
   	        	end-- end select of jc company
   	     	end -- end of full phase not found
   		end
   	end
   if @phaseinscode is not null
   	select @inscode = @phaseinscode
   
   select @seq=isnull(max(BatchSeq),0)+1 from dbo.PRTB with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid
   if @@rowcount=0
   	begin
   	select @errmsg='Error getting next batch sequence #.', @rcode=1
   	goto bspexit
   	end
   
   insert into bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, PostSeq, Type, PostDate,
   	JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, Equipment, EMGroup, RevCode, EquipCType, UsageUnits, TaxState, LocalCode,
   	UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, DayNum,
   	EquipPhase) --issue 21284 (include EquipPhase in insert)
   values (@co, @mth, @batchid, @seq, 'A', @employee, @payseq, @postseq, 'J',@postdate,
   	@jcco, @job, @phasegroup, @phase, @glco, @emco, @equip, @emgroup, @revcode, @equipjcct, @usageunits, @taxstate, @localcode,
   	@unempstate, @insstate, @inscode, @prdept, @crew, @cert, @craft, @class, @earncode, @shift, @hours, @rate, @amt,
   	@daynum, @phase) --issue 21284 (include EquipPhase in insert)
   
   if @@rowcount <> 1
   	begin
   	select @errmsg = 'Unable to entry for emp#' + convert(varchar(6),@employee) + ' to PR Timecard Batch!', @rcode = 1
   	goto bspexit
   	end
   
   goto pr_posting_loop
   
   pr_posting_end:
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcPRCW
   		deallocate bcPRCW
   		end
   
   	if (select count(*) from dbo.bPRCW with (nolock) where PRCo = @co and Crew=@crew and Employee is null)>0
   		select @errmsg = 'Crew contained equipment-only entries which were NOT included in timecard initialization as that information is for crew timesheet use only!', @rcode = 5
   		
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCrewInit] TO [public]
GO
