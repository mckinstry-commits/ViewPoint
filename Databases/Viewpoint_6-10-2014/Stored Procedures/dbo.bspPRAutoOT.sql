SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRAutoOT]
   /************************************************************************************
   * CREATED: kb 3/18/98
   * MODIFIED: GG 4/30/99
   *           EN 6/1/01 - issue 11870 (add 2 more levels to OT Schedule plus Schedule by Shift)
   *           EN 6/1/01 - issue 11871 (check for craft holidays)
   *           EN 7/31/01 - issue 14163 (error when calc non-shiftoverride daily ot)
   *           EN 8/1/01 - issue 14201 (error when calc ot by craft)
   *           EN 8/14/01 - issue 14327 (ignore postings with neg hours)
   *           EN 8/15/01 - issue 14334 (3rd level of otime schedule not working)
   *           EN 8/21/01 - issue 14413
   *           EN 8/23/01 - issue 14443
   *			EN 8/6/02 - issue 14692 option to calc ot for specified employee
   *			MV 08/19/02 - #18191 BatchUserMemoInsertExisting
   *			EN 8/21/02 - issue 18257 clarified warning msg for possible missing Job OT schedules
   *			EN 10/7/02 - issue 18877 change double quotes to single
   *			EN 10/29/02 - issue 19167  optimize fix for issue 14163 to remove use of isnull
   *			EN 10/30/02 issue 18561  on craft OT calc, ot on same day postings to separate jobs not being separated when jobs have different craft templates
   *			EN 11/13/02 issue 19188  Don't use craft holidays when posting Daily or Job overtime
   *			EN 1/3/02 - issue 19812  job ot trying to post ot twice to same timecard resulting in error
   *			GG 02/04/03 - #18703 - rewritten for weighted avg overtime, fix shift override logic,
   *									and aggregate daily hours by OT schedule
   *			EN 12/03/03 - issue 23061  added isnull check, with (nolock), and dbo
   *			EN 3/29/04 - issue 24137  fix to allow for 0 hours in level 1 and >0 hours in level 2 ... vice versa w/ level 2 and 3
   *			EN 2/22/05 - issue 21123  add option to restrict by pay seq
   *			EN 9/13/05 - issue 29635  added a Y/N flag (@PRTBAddedYN) as a return parameter to indicate whether or not any records were added to bPRTB
   *										and changed code to skip any employee/pay seq that is in a batch rather than triggering an error
   *			EN 10/20/2009 - #135963  ensure that job ot sched validation occurs after verifying that there are regular earnings set for Auto OT calculation\
   *            ECV 04/20/11 - TK-04385 Add SM Fields to PRTB records that are created.
   *			ECV 06/06/11 - TK-14637 Removed SM Fields from #PRAutoOT temp table
   *			EN 7/11/2012  B-09337/#144937 read in and pass additional rate options added to PRCO 
   *										  (AutoOTUseVariableRatesYN and AutoOTUseHighestRateYN) as params to 
   *										  bspPRAutoOTPostLevels and bspPRAutoOTWeekly
   *
   * USAGE:
   * Called by PR Automatic Overtime Posting program to evaluate existing timecards
   * and generate batch entries for overtime and updated regular time.
   *
   * INPUT PARAMETERS
   *   @co      	PR Company
   *   @mth        Batch Month
   *   @batchid    Batch ID#
   *	@specempl	Specific Employee for whom to calculate OT (null for all)
   *   @specpayseq	Pay Sequence to restrict on (null for all)
   *
   * OUTPUT PARAMETERS
   *	@PRTBAddedYN	='Y' if any timecards were added to bPRTB
   *   @msg      error message if error occurs
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   ************************************************************************************/
   (@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,  
	@specempl bEmployee = null , @specpayseq tinyint, @PRTBAddedYN bYN output, --#29635
   	@msg varchar(4000) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @openEmployeeSeq tinyint, @inuseby bVPUserName, @status tinyint,
   	@prgroup bGroup, @prenddate bDate, @payfreq bFreq,
   	@begindate bDate, @employee bEmployee, @otopt char(1), @otsched tinyint, @payseq tinyint,
   	@postdate bDate, @errmsg varchar(255), @openTimecard tinyint, @postseq smallint,
   	@postedhrs bHrs, @postedrate bUnitCost, @jcco bCompany, @job bJob, @craft bCraft, @class bClass,
   	@stdotsched tinyint, @jobotsched tinyint, @shift tinyint, @totreghrs bHrs, 
   	@lvl1hrs bHrs, @lvl2hrs bHrs, @lvl3hrs bHrs, @lvl1earncode bEDLCode,
   	@lvl2earncode bEDLCode, @lvl3earncode bEDLCode, @earncode bEDLCode, @ot1factor bRate,
   	@ot2factor bRate, @ot3factor bRate, @byshift char(1), @hrs bHrs, @earns bDollar,
   	@otrateadj bUnitCost, @otmsg varchar(4000), @openCraftEarns tinyint, @lastcraft bCraft,
   	@openDailyOT tinyint, @maxshift tinyint, @ot2dist bHrs, @postedlvl1hrs bHrs, @postedlvl2hrs bHrs,
   	@lvl1ot bHrs, @lvl2ot bHrs, @lvl3ot bHrs, @lastotsched tinyint
   
   -- bPRCO variables
   DECLARE @autoot bYN, 
		   @prco_otearncode bEDLCode, 
		   @autootusevariableratesyn bYN,
		   @autootusehighestrateyn bYN
   
   set @rcode = 0
   
   -- get PR Group and Ending Date from Batch
   select @inuseby = InUseBy, @status = Status, @prgroup = PRGroup, @prenddate = PREndDate
   from dbo.bHQBC with (nolock)
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
     	select @msg =  'Missing HQ Batch.', @rcode = 1
     	goto bspexit
     	end
   if @inuseby <> SUSER_SNAME()
     	begin
     	select @msg = 'This batch already in use by ' + isnull(@inuseby,''), @rcode = 1
     	goto bspexit
     	end
   if @status <> 0
       begin
       select @msg = 'Batch status must be ''open''.', @rcode = 1
       goto bspexit
       end
   
   -- check PR Company's Auto Overtime options
   SELECT @autoot = AutoOT, 
		  @prco_otearncode = OTEarnCode,
		  @autootusevariableratesyn = AutoOTUseVariableRatesYN,
		  @autootusehighestrateyn = AutoOTUseHighestRateYN
   FROM dbo.bPRCO
   WHERE PRCo = @co
   IF @@ROWCOUNT = 0
   BEGIN
       SELECT @msg = 'Missing PR Company.', @rcode = 1
       GOTO bspexit
   END
   IF @autoot='N'
   BEGIN
       SELECT @msg = 'The option for Auto Overtime is not used by this PR Company.', @rcode = 1
       GOTO bspexit
   END
       
   -- check PR Group's Payment Frequency 
   select @payfreq = PayFreq
   from dbo.bPRGR with (nolock)
   where PRCo = @co and PRGroup = @prgroup
   if @@rowcount = 0
   	begin
       select @msg = 'Missing PR Group.',@rcode = 1
       goto bspexit
       end
   if @payfreq <> 'W' and @payfreq <> 'B'
       begin
       select @msg = 'Auto Overtime can only be run for Weekly or BiWeekly Pay Periods.',@rcode = 1
       goto bspexit
       end
   
   -- check Pay Period's Status and get Beginning Date
   select @begindate = BeginDate, @status = Status
   from dbo.bPRPC with (nolock)
   where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
   if @@rowcount = 0
       begin
       select @msg = 'Missing Pay Period.', @rcode = 1
       goto bspexit
       end
   if @status <> 0
       begin
       select @msg = 'Pay Period must be Open.', @rcode = 1
       goto bspexit
       end
   
   -- make sure temp table doesn't already exist
   if object_id('#PRAutoOT') is not null drop table #PRAutoOT
   
   -- create temp table to hold timecards used in auto overtime processing
   create table #PRAutoOT
   	(OTSched tinyint null,	-- allow null to report jobs with missing OT schedules
   	PostDate smalldatetime not null ,
   	PostSeq smallint not null ,
   	EarnCode int not null,
   	Hours numeric(10,2) not null ,
   	Shift tinyint not null,
   	Rate numeric(16,5) not null,
   	Craft varchar(10) null,
   	Class varchar(10) null,
   	JCCo tinyint null,
   	Job varchar(20) null)
   
   -- add an index for ensure uniqueness and improve performance
   create unique clustered index biPRAutoOT
   	on #PRAutoOT(OTSched, PostDate, PostSeq)
   
   -- create a cursor on Employee/Pay Seq 
   declare bcEmployeeSeq cursor for
   select distinct s.Employee, e.OTOpt, e.OTSched, s.PaySeq
   from dbo.bPREH e with (nolock)
   join dbo.bPRSQ s with (nolock) on s.PRCo = e.PRCo and s.Employee = e.Employee
   join dbo.bPRTH h with (nolock) on h.PRCo = s.PRCo and h.PRGroup = s.PRGroup and h.PREndDate = s.PREndDate
   	and h.Employee = s.Employee and h.PaySeq = s.PaySeq	-- must have existing timecards
   where s.PRCo = @co and s.PRGroup = @prgroup and s.PREndDate = @prenddate
   	-- must be unpaid, subject to overtime, and can be limited to specific employee
       and s.CMRef is null and e.OTOpt <> 'N' and s.Employee = isnull(@specempl,s.Employee)
   	-- ... and can be limited to specific pay seq (issue 21123)
   	and s.PaySeq = isnull(@specpayseq,s.PaySeq)
   
   -- open cursor
   open bcEmployeeSeq
   set @openEmployeeSeq = 1
   
   -- loop through all Employee/Pay Seqs
   EmployeeSeq_loop:
   	fetch next from bcEmployeeSeq into @employee, @otopt, @otsched, @payseq
       if @@fetch_status <> 0 goto bspexit
   
       -- skip Employee/Pay Seq if entries exist in a timecard batch
       if exists(select 1 from dbo.bPRTB t with (nolock)
       			join dbo.HQBC b with (nolock) on b.Co = t.Co and b.Mth = t.Mth and b.BatchId = t.BatchId
       			where t.Co = @co and b.PRGroup = @prgroup and t.Employee = @employee
             			and b.PREndDate = @prenddate and t.PaySeq = @payseq)
   		begin
   		goto EmployeeSeq_loop
   --        select @msg = 'Auto Overtime posting may be incomplete.' + char(13) +
   --        	'One or more Employees have entries in a Timecard Batch.  Post all open Timecard Batches, ' +
   --            'then rerun this program.', @rcode = 1
   --        goto bspexit
           end
   
   	-- calculate employee's weighted average overtime rate - positive hours and earnings only
   	select @hrs = isnull(sum(case when h.Hours > 0 then h.Hours else 0 end),0),
   		@earns = isnull(sum(case when h.Amt > 0 then h.Amt else 0 end),0)
   	from dbo.bPRTH h with (nolock)
   	join dbo.bPREC e with (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode
   	where h.PRCo = @co and h.PRGroup = @prgroup and h.PREndDate = @prenddate
   		and h.Employee = @employee and h.PaySeq = @payseq
   		and e.OTCalcs = 'Y'	-- regular time subject to overtime only
   	------------------------------------------------------------------
   	-- Note that average is calculated over entire pay period, not by week.
   	-- If pay period is biweekly this may not be technically correct but
   	-- rules are not specific.  A true weekly calc would require additional
   	-- work not considered worth the effort at this time. GG 01/21/03
   	-------------------------------------------------------------------
   	
   	-- overtime rate adjustment is one half of average regular posted earnings rate, will be added to
   	-- posted rate when Job, Craft, and Class all indicate it should be used.
   	select @otrateadj = 0
   	if @hrs <> 0 select @otrateadj = (@earns / @hrs) * .5
   
   	-- clear auto overtime processing table
   	delete #PRAutoOT 
   
   	if @otopt = 'D'   -- Employee based daily overtime 
   		begin
   		if @otsched is null
   			begin
   			select @msg = 'Missing Overtime Schedule for Employee#:' + convert(varchar,@employee) +
   				'.  Assign schedule in PR Employee Header, then rerun this program.', @rcode = 1
   			goto bspexit
   			end
   		-- load processing table with all posted earnings - OT schedule from Employee Header
   		insert #PRAutoOT (OTSched, PostDate, PostSeq, EarnCode, Hours, Shift, Rate, Craft, Class, JCCo, Job)
   		select @otsched, PostDate, PostSeq, bPRTH.EarnCode, Hours, Shift, Rate, Craft, Class, JCCo, Job
   		from dbo.bPRTH with (nolock)
   		where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
   			and Employee = @employee and PaySeq = @payseq
   		end
   
   	if @otopt = 'J'		-- Job based daily overtime 
   		begin
   		-- load processing table with all job posted earnings - OT schedule from Job Master
--   		insert #PRAutoOT (OTSched, PostDate, PostSeq, EarnCode, Hours, Shift, Rate, Craft, Class, JCCo, Job)
--   		select j.OTSched, h.PostDate, h.PostSeq, h.EarnCode, h.Hours, h.Shift, h.Rate, h.Craft, h.Class, h.JCCo, h.Job
--   		from dbo.bPRTH h with (nolock)
--   		join dbo.bJCJM j with (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
--   		where h.PRCo = @co and h.PRGroup = @prgroup and h.PREndDate = @prenddate and h.Employee = @employee
--   			and h.PaySeq = @payseq 
   
   		insert #PRAutoOT (OTSched, PostDate, PostSeq, h.EarnCode, Hours, Shift, Rate, Craft, Class, JCCo, Job)
   		select j.OTSched, h.PostDate, h.PostSeq, h.EarnCode, h.Hours, h.Shift, h.Rate, h.Craft, h.Class, h.JCCo, h.Job
   		from dbo.bPRTH h with (nolock)
   		join dbo.bJCJM j with (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
		join dbo.bPREC e with (nolock) on h.PRCo = e.PRCo and h.EarnCode = e.EarnCode --#135963
   		where h.PRCo = @co and h.PRGroup = @prgroup and h.PREndDate = @prenddate and h.Employee = @employee
   			and h.PaySeq = @payseq and e.OTCalcs = 'Y' --#135963

   		-- check for Jobs with missing OT schedules
   		set @otmsg = ''
   		select distinct @otmsg = isnull(@otmsg,'') + ', ' + isnull(Job,'') 
   		from #PRAutoOT with (nolock) where OTSched is null
   		if datalength(@otmsg) > 2
   			begin
   			select @msg = 'Missing Overtime Schedule(s) for Job(s): ' +
   				isnull(substring(@otmsg,3,datalength(@otmsg)),'') + char(13) + 
   				'Assign schedule(s) in JC Job Master, then rerun this program.', @rcode = 1
   			goto bspexit
   			end
   		end
   
   	if @otopt = 'C'		-- Craft based daily overtime with override by Job
   		begin
   		-- use a cursor to cycle through Craft earnings and determine OT schedule
           declare bcCraftEarns cursor for
           select Craft, JCCo, Job, PostDate, PostSeq
           from dbo.bPRTH with (nolock)
           where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
           	and PaySeq = @payseq and Craft is not null
           order by Craft, JCCo, Job
   
   		open bcCraftEarns
           select @openCraftEarns = 1, @lastcraft = null
   
           CraftEarns_loop:   -- next Craft timecard
           	fetch next from bcCraftEarns into @craft, @jcco, @job, @postdate, @postseq
               
   			if @@fetch_status <> 0 goto CraftEarns_end
   
   			if @lastcraft is null or @craft <> @lastcraft
   				begin
   				-- get standard OT schedule for Craft
   				select @stdotsched = OTSched
                 	from dbo.bPRCM with (nolock)
                 	where PRCo = @co and Craft = @craft
                 	if @@rowcount = 0
                     	begin
                     	select @msg = 'Unable to process Craft based overtime on Employee#: ' + convert(varchar,@employee)
                         	+ '.  Missing Craft: ' + isnull(@craft,''), @rcode = 1
                     	goto bspexit
                     	end
   				select @lastcraft = @craft
   				end
   
   			-- check for Job override
               select @jobotsched = null
   			if @jcco is not null and @job is not null
               	select @jobotsched = t.OTSched
               	from dbo.bPRCT t with (nolock)
               	join dbo.bJCJM j with (nolock) on t.Template = j.CraftTemplate
                   where t.PRCo = @co and t.Craft = @craft and j.JCCo = @jcco and j.Job = @job
                   	and t.OverOT = 'Y'
   
               select @otsched = coalesce(@jobotsched,@stdotsched)
   
   			-- add entry to processing table 
   			insert #PRAutoOT (OTSched, PostDate, PostSeq, EarnCode, Hours, Shift, Rate, Craft, Class, JCCo, Job)
   			select @otsched, @postdate, @postseq, h.EarnCode, Hours, Shift, Rate, @craft, Class, @jcco, @job
   			from dbo.bPRTH h with (nolock)
   			where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   				and PaySeq = @payseq and PostSeq = @postseq
   			if @@rowcount <> 1
   				begin
   				select @msg = 'Unable to load Auto Overtime processing table.', @rcode = 1
   				goto bspexit
   				end
   
   			goto CraftEarns_loop	-- next Craft timecard
   
   		CraftEarns_end:		-- finished loading Craft earnings
   			close bcCraftEarns
   			deallocate bcCraftEarns
   			set @openCraftEarns = 0
   
   			-- check for Crafts with missing OT schedules
   			set @otmsg = ''
   			select distinct @otmsg = isnull(@otmsg,'') + ', ' + isnull(Craft,'')
   			from #PRAutoOT with (nolock) where OTSched is null
   			if datalength(@otmsg) > 2
   				begin
   				select @msg = 'Missing Overtime Schedule(s) for Craft(s): ' +
   					substring(@otmsg,3,datalength(@otmsg)) + char(13) + 
   					'Assign schedule(s) in PR Craft Master, then rerun this program.', @rcode = 1
   				goto bspexit
   				end
   
   		end
   
   	-- temp table is loaded with posted earnings, ready to process daily overtime based on OT schedule
   	if @otopt in ('D','J','C')
   		begin
   		-- use a cursor to process by OT schedule and date
   		declare bcDailyOT cursor for
           select distinct OTSched, PostDate
           from #PRAutoOT with (nolock)
           
   		open bcDailyOT
           select @openDailyOT = 1, @lastotsched = null
   
           DailyOT_loop:   -- next OT schdule and timecard posted date
           	fetch next from bcDailyOT into @otsched, @postdate
               
   			if @@fetch_status <> 0 goto DailyOT_end
   
   			if @otsched is null
   				begin
   				-- all null OT schedules should have caught above, but make a final check 
   				select @msg = 'Missing Overtime Schedule.', @rcode = 1
   				goto bspexit
   				end
   
   			-- get employee's max shift worked for the day under the OT schedule
   			select @maxshift = max(Shift)
   			from #PRAutoOT with (nolock)
   			where OTSched = @otsched and PostDate = @postdate
   
   			-- if daily OT is Craft based, get 1st Craft worked to determine Holidays
   			set @craft = null
   			if @otopt = 'C'
   				select @craft = Craft
   				from #PRAutoOT with (nolock)
   				where OTSched = @otsched and PostDate = @postdate 
   
   			 -- get daily overtime limits and earnings codes
       		exec @rcode = bspPROTInfoGet @co, @prgroup, @prenddate, @otsched, @maxshift, @craft, @postdate,
       			@lvl1hrs output, @lvl1earncode output, @lvl2hrs output, @lvl2earncode output,
           		@lvl3hrs output, @lvl3earncode output, @byshift output, @errmsg output
       		if @rcode <> 0
           		begin
           		select @msg = 'Unable to process daily overtime for Employee#: ' + convert(varchar,@employee)
   					+ char(13) + isnull(@errmsg,'')
           		goto bspexit
           		end
   
       		-- get overtime earnings code factors
       		if @lvl1earncode is not null
       			begin
   	    		select @ot1factor = Factor from dbo.bPREC with (nolock) where PRCo = @co and EarnCode = @lvl1earncode
           		if @@rowcount = 0
           			begin
               		select @msg = 'Level 1 Earnings Code ' + convert(varchar(6),@lvl1earncode) + ' is invalid', @rcode = 1
               		goto bspexit
               		end
   --        		if @lvl1hrs=0 select @lvl2earncode = null, @lvl3earncode = null
           		end
       		if @lvl2earncode is not null
           		begin
   	    		select @ot2factor = Factor from dbo.bPREC with (nolock) where PRCo = @co and EarnCode = @lvl2earncode
           		if @@rowcount = 0
           			begin
               		select @msg = 'Level 2 Earnings Code ' + convert(varchar(6),@lvl2earncode) + ' is invalid', @rcode = 1
               		goto bspexit
               		end
   --        		if @lvl2hrs=0 select @lvl3earncode = null
           		end
   			if @lvl3earncode is not null
           		begin
   	    		select @ot3factor = Factor from dbo.bPREC with (nolock) where PRCo = @co and EarnCode = @lvl3earncode
           		if @@rowcount = 0
           			begin
               		select @msg = 'Level 3 Earnings Code ' + convert(varchar(6),@lvl3earncode) + ' is invalid', @rcode = 1
               		goto bspexit
               		end
           		end
   
   			-- get total regular time hours for the day subject to overtime calculations
   		    select @totreghrs = isnull(sum(h.Hours),0)	
   		    from #PRAutoOT h with (nolock)
   		    join dbo.bPREC e with (nolock) on e.EarnCode = h.EarnCode
   		    where h.OTSched = @otsched and h.PostDate = @postdate
   				and e.PRCo = @co and e.OTCalcs = 'Y' and h.Hours > 0	-- positive hours only
   
   			set @ot2dist = @totreghrs - @lvl1hrs  		-- total auto overtime hrs to distribute for the day
   			if @ot2dist <= 0 goto DailyOT_loop	-- no auto overtime needed for the day
   
   			-- get total overtime hours for levels 1 and 2 already posted for the day
   		    select @postedlvl1hrs = isnull(sum(case when EarnCode = @lvl1earncode and Hours > 0 then Hours else 0 end),0),
   					@postedlvl2hrs = isnull(sum(case when EarnCode = @lvl2earncode and Hours > 0 then Hours else 0 end),0)
   			from #PRAutoOT with (nolock)
   			where OTSched = @otsched and PostDate = @postdate
       
   			-- calculate overtime to post by level
   			select @lvl1ot = 0, @lvl2ot = 0, @lvl3ot = 0	-- initialize 
   			if @lvl2hrs = 0 set @lvl2hrs = 99
   			if @lvl3hrs = 0 set @lvl3hrs = 99
   			set @lvl1ot = (@lvl2hrs - @lvl1hrs) - @postedlvl1hrs	-- max level 1 overtime including posted hrs
   			if @lvl1ot < 0 set @lvl1ot = 0		-- needed if posted hrs exceed level 1 max
   			if @lvl1ot >= @ot2dist
   				begin
   				set @lvl1ot = @ot2dist	-- all overtime will be added as level 1
   				goto check_ot_levels
   				end
   			set @ot2dist = @ot2dist - @lvl1ot	-- adjust total overtime to distribute
   			set @lvl2ot = (@lvl3hrs - @lvl2hrs) - @postedlvl2hrs	-- max level 2 overtime including posted hrs
   			if @lvl2ot < 0 set @lvl2ot = 0		-- needed if posted hrs exceed level 1 max
   			if @lvl2ot >= @ot2dist
   				begin
   				set @lvl2ot = @ot2dist	-- overtime will added as level 1 or 2
   				goto check_ot_levels
   				end
   			set @ot2dist = @ot2dist - @lvl2ot	-- adjust total overtime to distribute
   			set @lvl3ot = @ot2dist 			-- any remaing overtime will be posted as level 3
   
   			check_ot_levels: -- check sum of overtime levels, must equal total to distibute
   				if (@lvl1ot + @lvl2ot + @lvl3ot) <> (@totreghrs - @lvl1hrs)
   					begin
   		            select @msg = 'Unable to distribute overtime correctly for Employee #' + convert(varchar,@employee), @rcode = 1
   		            goto bspexit
   		            end
   				if @lvl1ot > 0 and @lvl1earncode is null
   					begin
   		            select @msg = 'Level 1 overtime indicated, but no Earnings Code assigned.', @rcode = 1
   		            goto bspexit
   		            end
   				if @lvl2ot > 0 and @lvl2earncode is null
   					begin
   		            select @msg = 'Level 2 overtime indicated, but no Earnings Code assigned.', @rcode = 1
   		            goto bspexit
   		            end
   				if @lvl3ot > 0 and @lvl3earncode is null
   					begin
   		            select @msg = 'Level 3 overtime indicated, but no Earnings Code assigned.', @rcode = 1
   		            goto bspexit
   		            end
   
   			-- create a cursor on daily timecards with regular time earnings subject to overtime
   			declare bcTimecard cursor for
       		select h.PostSeq, h.EarnCode, h.Hours, h.Rate, h.Craft, h.Class, h.JCCo, h.Job 
       		from #PRAutoOT h with (nolock)
       		join dbo.bPREC e with (nolock) on h.EarnCode = e.EarnCode
   			where h.OTSched = @otsched and h.PostDate = @postdate
   				and e.PRCo = @co and e.OTCalcs = 'Y' and h.Hours > 0
   			order by h.PostSeq desc		-- proccess in descending order
   
   			open bcTimecard
   			select @openTimecard = 1
   					
   			Timecard_day_loop:  -- get the next timecard for the day
   				fetch next from bcTimecard into @postseq, @earncode, @postedhrs, @postedrate,
   					@craft, @class, @jcco, @job
   
   	    		if @@fetch_status <> 0 goto Timecard_day_end
   
   		        -- post breakdowns to batch
   		        EXEC @rcode = bspPRAutoOTPostLevels @co,			@mth,		@batchid,		@prgroup, 
   													@prenddate,		@begindate, @employee,		@payseq, 
   													@postseq,		@postdate,	@craft,			@class, 
   													@jcco,			@job,		@maxshift,		@postedrate,
   													@postedhrs,		@otrateadj, @lvl1earncode,	@lvl2earncode, 
   													@lvl3earncode,	@ot1factor, @ot2factor,		@ot3factor, 
   													@autootusevariableratesyn,	@autootusehighestrateyn, 
   													@lvl1ot OUTPUT, 
   													@lvl2ot OUTPUT,		
   													@lvl3ot OUTPUT, 
   													@PRTBAddedYN OUTPUT, 
   													@msg OUTPUT --#29635
   		        IF @rcode <> 0 GOTO bspexit
   		
   				-- check for any remaining overtime to distribute
   				if @lvl1ot <> 0 or @lvl2ot <> 0 or @lvl3ot <> 0 goto Timecard_day_loop	
   
   			Timecard_day_end:
   	            close bcTimecard
   	            deallocate bcTimecard
   	            select @openTimecard = 0
   	
   				-- make sure all overtime was distributed for the day
   				if @lvl1ot <> 0 or @lvl2ot <> 0 or @lvl3ot <> 0 
   					begin
   	                select @msg = 'Unable to fully distribute daily overtime for Employee#:' + convert(varchar,@employee), @rcode = 1
   	                goto bspexit
   	                end
   	
   				goto DailyOT_loop	-- next OT schedule and date
   
   		DailyOT_end:
               close bcDailyOT
               deallocate bcDailyOT
               select @openDailyOT = 0
   
   		end		-- finished with daily overtime
    
   
   	IF @otopt IN ('C','D','J','W')    -- weekly overtime applies to all
   	BEGIN
		EXEC @rcode = bspPRAutoOTWeekly @co,				@mth,		@batchid,	@prgroup, 
										@prenddate,			@employee,	@payseq,	@payfreq, 
										@prco_otearncode,	@begindate, @otrateadj, 
										@autootusevariableratesyn,		@autootusehighestrateyn,		
										@PRTBAddedYN OUTPUT, 
										@msg OUTPUT --#29635
   		IF @rcode <> 0 GOTO bspexit
    END
   
   	goto EmployeeSeq_loop
   
   bspexit:
   	if @openEmployeeSeq = 1
   		begin
       	close bcEmployeeSeq
       	deallocate bcEmployeeSeq
       	end
   	if @openDailyOT = 1
   		begin
   		close bcDailyOT
           deallocate bcDailyOT
   		end
   	if @openTimecard = 1
   		begin
   		close bcTimecard
   		deallocate bcTimecard
   		end
   
   	-- drop auto overtime processing temp table 
   	if object_id('#PRAutoOT') is not null drop table #PRAutoOT
   
   	if @rcode <> 0 select @msg = isnull(@msg,'') --+ char(13) + char(10) + '[bspPRAutoOT]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAutoOT] TO [public]
GO
