SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSSend    Script Date: 8/28/99 9:35:39 AM ******/
CREATE proc [dbo].[bspPRTSSend]
/****************************************************************************
* CREATED BY:		EN	04/01/2003
* MODIFIED By:		EN	11/20/2003	- issue 23062 correct handling of linked progress units variable
*					EN	12/08/2003	- issue 23061  added isnull check, with (nolock), and dbo
*					EN	03/15/2004	- issue 24066 fix for error caused when trying to update null um to bJCPP
*					EN	09/20/2004	- issue 25544  PR batch is getting entries for the wrong PR Group(s)
*					EN	10/19/2004	- issue 25815 resolved divide by zero error by providing for null project/estimated when computing progress/linked phase units
*					EN	11/17/2004	- issue 24034 write PRCrew to bEMBF so that it gets included in EM JC Distributions
*					EN	11/22/2004	- issue 22571  relabel "Posting Date" to "Timecard Date"
*					EN	12/29/2004	- issue 26670  check for ins. by phase using valid portion of phase
*					EN	03/17/2005	- issue 27417  correct the variable used to get valid portion of phase code ... changed @jcco to @postjcco
*											... caused problem with pulling correct ins code by phase
*										Also, corrected the variable used for error about getting GL offset account for EM batch post
*											... changed @job to @postjob
*					EN	06/21/2005	- issue 29065  fine-tune the error recovery process and reduce possible causes for error
*					EN	07/06/2005	- issue 29196  @sendseq was inadvertantly clearing out causing improper clearing of bPRTS/bPRTT and release of batch from inuseby
*											Also fixed code to clear out bPRTS send seqs > 1 year old but only if not (PRTS_UserId=@userid and PRTS_SendSeq=@sendseq)
*					EN	10/04/2005	- issue 29993  if null rate is returned by bspPRRateDefault, treat it like a zero when computing amount to resolve error when null Amt is written to bPRTB
*					EN	12/04/2006	- issue 27864 changed HQBC TableName reference from 'PRTZGrid' to 'PRTB'
*					MH	06/28/2007	- issue 124951
*					EN	03/7/2008	- #127081  in declare statements change State declarations to varchar(4)
*					MH	05/19/2008	- #127072 - Uncommented code at bsperror_no_rollback to clear the InUseBy flag.
*					MH	06/11/2008	- #128126 - See comment tag below.  Resolved duplicate CT entries for linked CTs.
*					MH	01/12/2009	- #131479 - Remove "InUseBy" references.  InUseBy has been removed from bPRRH.
*					mh	06/16/2009	- Issue 133863.  See comments below and in bspPRTSSendCancel.
*					mh	10/06/2009	- Issue 135248.  When posting progress if phase is not on a job and locked 
*										locked phases = 'N' then we need to add the phase before posting progress.
*					mh	02/12/2010 - 135248 - Turns out we also need to add Cost Type on the fly too.
*					TJL 03/01/2010	- Issue #135490, Add Office TaxState & Office LocalCode to PR Employee Master
*					CHS 04/21/2011	- #140924 Insurance Code not defaulting from Job Phase.
*					EN 01/23/2013 D-06543/#140311/TK-20910 removed code to update linked cost types because it is handled in JCPP triggers
*
* USAGE:
* Creates PR Entry, EM Rev and JC Progress batches and fills them based on date
* in the selected timesheets.
* 
*  INPUT PARAMETERS
*	 @userid		User ID of user performing the send
*   @prco			PR Company
*	 @prgroup		PR Group
*	 @enddate		PR Period Ending Date
*	 @prrestrict	="Y" to restrict batch access to CreatedBy user
*	 @jcrestrict	="Y" to restrict batch access to CreatedBy user
*	 @emrestrict	="Y" to restrict batch access to CreatedBy user
*   @payseq		Payment Sequence
*	 @jcco			JC Company
*   @job			Job
*	 @throughdate	Send timesheets with Post Date before or on this date
*	 @restart		="Y" if restarting an incomplete send
*
* OUTPUT PARAMETERS
*   @msg      		error message if error occurs 
*
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************/ 
(@userid bVPUserName, @prco bCompany = null, @prgroup bGroup = null, 
@enddate bDate = null, @prrestrict bYN, @jcrestrict bYN, @emrestrict bYN,
@payseq tinyint = null, @jcco bCompany = null, @job bJob = null, 
@throughdate bDate = null, @restart bYN, @sendseq int = null, @msg varchar(1000) output)
as

set nocount on
      --Issue #135490, remove PRCo, Job, Employ variables related to State & LocalCodes & flags
      declare @rcode int, @month bMonth, @source bSource, @tablename varchar(20), @adjust bYN,
      	@prbatchid bBatchID, @embatchid bBatchID, @jcbatchid bBatchID, @headercursor tinyint, 
      	@seq smallint, @crew varchar(10), @nullgroup bGroup, @nullenddate bDate,
      	@postdate bDate, @sheetnum smallint, @employee bEmployee, @lineseq smallint, @craft bCraft,
      	@class bClass, @phase1reghrs bHrs, @phase1othrs bHrs, @phase1dblhrs bHrs, 
      	@phase2reghrs bHrs, @phase2othrs bHrs, @phase2dblhrs bHrs, @phase3reghrs bHrs, 
      	@phase3othrs bHrs, @phase3dblhrs bHrs, @phase4reghrs bHrs, @phase4othrs bHrs, 
      	@phase4dblhrs bHrs, @phase5reghrs bHrs, @phase5othrs bHrs,@phase5dblhrs bHrs, 
      	@phase6reghrs bHrs, @phase6othrs bHrs, @phase6dblhrs bHrs, @phase7reghrs bHrs, 
      	@phase7othrs bHrs, @phase7dblhrs bHrs, @phase8reghrs bHrs, @phase8othrs bHrs, 
      	@phase8dblhrs bHrs, @postjcco bCompany, @postjob bJob, @shift tinyint, @phasegroup bGroup,
      	@phase1 bPhase, @phase2 bPhase, @phase3 bPhase, @phase4 bPhase, @phase5 bPhase, @phase6 bPhase, 
      	@phase7 bPhase, @phase8 bPhase, @phasenum tinyint, @phase bPhase, @reghrs bHrs,
      	@othrs bHrs, @dblhrs bHrs, @emco bCompany, @equip bEquip, @emgroup bGroup,
      	@revcode bRevCode, @equipjcct bJCCType, @usageunits bHrs, @inscode bInsCode, @prdept bDept, @cert bYN, 
      	@earncode bEDLCode, @useempins char(1), @phaseinscode bInsCode, @hournum tinyint, @hours bHrs,
      	@regearncode bEDLCode, @otearncode bEDLCode, @dblearncode bEDLCode, @coregec bEDLCode, 
      	@cootec bEDLCode, @codblec bEDLCode, @crewregec bEDLCode, @crewotec bEDLCode, @crewdblec bEDLCode,
      	@template smallint, @rate bUnitCost, @begindate bDate, @daynum smallint, @phase1value bHrs,
      	@phase2value bHrs, @phase3value bHrs, @phase4value bHrs, @phase5value bHrs, @phase6value bHrs, 
      	@phase7value bHrs, @phase8value bHrs, @stdhrs bHrs, @factor bRate,
      	@stdpayrate bYN, @hourlyrate bRate, @phase1units bUnits, @phase2units bUnits, @phase3units bUnits, 
      	@phase4units bUnits, @phase5units bUnits, @phase6units bUnits, @phase7units bUnits, @phase8units bUnits,
      	@phaseunits bUnits, @numrows int, @phase1ct bJCCType, @phase2ct bJCCType, 
      	@phase3ct bJCCType, @phase4ct bJCCType, @phase5ct bJCCType, @phase6ct bJCCType, @phase7ct bJCCType,
      	@phase8ct bJCCType, @phase1eqct bJCCType, @phase2eqct bJCCType, @phase3eqct bJCCType, 
      	@phase4eqct bJCCType, @phase5eqct bJCCType, @phase6eqct bJCCType, @phase7eqct bJCCType,
      	@phase8eqct bJCCType, @jccosttype bJCCType, @linkcosttype bJCCType,
      	@um bUM, @projected bUnits, @actual bUnits, @totalactual bUnits,
      	@progresscmplt bPct, @linkum bUM, @linkestunits bUnits, @linkprojunits bUnits,
      	@equipment bEquip, @phase1usage bHrs, @phase1rev bRevCode, @phase2usage bHrs, @phase2rev bRevCode,
      	@phase3usage bHrs, @phase3rev bRevCode, @phase4usage bHrs, @phase4rev bRevCode, @phase5usage bHrs,
      	@phase5rev bRevCode, @phase6usage bHrs, @phase6rev bRevCode, @phase7usage bHrs, @phase7rev bRevCode,
      	@phase8usage bHrs, @phase8rev bRevCode, @phaseusage bHrs, @phaserev bRevCode, @glco bCompany,
      	@offsetacct bGLAcct, @ememployee bEmployee, @revrate bDollar, @category bCat, @time_um bUM, @work_um bUM,
      	@attachment bEquip, @posttoattach bYN, @attachrevrate bDollar, @attachtime_um bUM, @offsetglco bCompany, 
     	@amt bDollar, @acategory bCat, @linkphaseunits bUnits, @validphasechars int, @pphase bPhase, @progressseq int,
      	@method char(1), @prre_cursor tinyint, @prro_cursor tinyint, @prrn_cursor tinyint, @prrq_cursor tinyint, 
     	@batchmodule char(2), @co bCompany, @batchid bBatchID, @jccoglco bCompany, @module char(2),
     	@multimth bYN, @beginmth bMonth, @endmth bMonth, @cutoffdate bDate, @batchmonth bMonth, @tsql varchar(255),
     	@prevhourmeter bHrs, @currhourmeter bHrs, @prevodometer bHrs, @updatehourmeter bYN, @hrspertimeum bHrs, 
    	@status char(1), @type char(1), @lockphases bYN, @activeyn bYN, @jobstatus tinyint, @emlineseq smallint, 
    	@plugged bYN, @estimated bUnits, @linkactive bYN, 
   		@posttaxstate varchar(4), @postunempstate varchar(4), @postinsstate varchar(4), @postlocalcode bLocalCode, 
   		@errmsg varchar(255)
   	
      
	select @rcode = 0

	-- validate UserID
	if @userid is null
	begin
		select @msg = 'Missing User ID', @rcode = 1
		goto bspexit
	end
	-- validate Restart flag
	if @restart is null or @restart not in ('Y','N')
	begin
		select @msg = 'Restart flag should be either ''Y'' or ''N''', @rcode = 1
		goto bspexit
	end
	-- validate SendSeq if Restart='Y'
	if @restart = 'Y'
	begin
		if @sendseq is null
		begin
			select @msg = 'Missing Send Sequence needed for Restart', @rcode = 1
			goto bspexit
		end
	end
	   
      --Step 1: Create bPRTS entry unless this is a restart
      
      --if restarting, read Send parameters from bPRTS and PR BatchId from bPRTT and see if any batches have
      --detail.  If not, cancel batches, clear them from bPRTT and recreate.
	if @restart='Y'
  	begin --{if @restart='Y'}
		select @prco=PRCo, @month=BatchMth, @prgroup=PRGroup, @enddate=EndDate, @payseq=PaySeq, 
		@jcco=JCCo, @job=Job, @throughdate=ThroughDate, @prrestrict=PRRestrict, 
		@jcrestrict=JCRestrict, @emrestrict=EMRestrict
		from dbo.PRTS with (nolock) where UserId=@userid and SendSeq=@sendseq

      	if @@rowcount = 0 goto bspexit
     
     	-- get PR Pay Period data
     	select @begindate=BeginDate, @multimth=MultiMth, @beginmth=BeginMth, @endmth=EndMth, 
     		@cutoffdate=CutoffDate, @stdhrs=Hrs 
     	from dbo.PRPC with (nolock)
     	where PRCo=@prco and PRGroup=@prgroup and PREndDate=@enddate
     
      	-- read company regular/overtime/doubletime earnings codes and tax state info
		--Issue #135490, remove PRCo values related to State & LocalCodes & flags
     	select @coregec=CrewRegEC, @cootec=CrewOTEC, @codblec=CrewDblEC 
   		from dbo.PRCO with (nolock) where PRCo=@prco

     	if @coregec is null
     	begin
     	    select @msg = 'Please set up Crew Timesheet Earnings Code for this PR Company', @rcode = 1
     	    goto bspexit
     	end
    
        -- get PR Batch ID
    	select @prbatchid=BatchId from dbo.PRTT with (nolock) where UserId=@userid and SendSeq=@sendseq and Module='PR'
    
    	-- check for batches containing transaction detail
    	declare bcTCBatches cursor for 
    	select case b.Module when 'PR' then 'dbo.PRTB' when 'EM' then 'dbo.EMBF' when 'JC' then 'dbo.JCPP' else '' end,
    		a.Co, a.Mth, a.BatchId, a.Source, b.Module
    	from dbo.HQBC a with (nolock)
    	join dbo.PRTT b with (nolock) on a.Co=b.Co and a.Mth=b.BatchMth and a.BatchId=b.BatchId
    	where b.UserId=@userid and b.SendSeq=@sendseq

    	open bcTCBatches
    
    	-- if transactions found, go directly to transfer_timesheets
    	fetch next from bcTCBatches into @tablename, @co, @batchmonth, @batchid, @source, @module
    	while @@fetch_status = 0
    	begin
    		if @tablename <> ''
    		begin 
    			select @tsql = 'select Co from ' + @tablename + ' with (nolock) where Co = ' + convert(varchar(3),@co)
    		 	select @tsql = @tsql  + ' and Mth = ''' + convert(varchar(8),@batchmonth,1) + ''' and BatchId = ' + convert(varchar(10),@batchid)
    		 	execute (@tsql)
    		 	if @@rowcount <> 0
    			begin
    				close bcTCBatches
    			  	deallocate bcTCBatches
    				goto transfer_timesheets
    			end
    		end
    
    		fetch next from bcTCBatches into @tablename, @co, @batchmonth, @batchid, @source, @module
    	end
    
    	close bcTCBatches
      	deallocate bcTCBatches
    
    	-- no transactions found, cancel the batches and re-create them in case interrupt occurred while creating batches
    	declare bcTCBatches cursor for 
    	select case b.Module when 'PR' then 'dbo.PRTB' when 'EM' then 'dbo.EMBF' when 'JC' then 'dbo.JCPP' else '' end,
    		a.Co, a.Mth, a.BatchId, a.Source, b.Module
    	from HQBC a
    	join dbo.PRTT b with (nolock) on a.Co=b.Co and a.Mth=b.BatchMth and a.BatchId=b.BatchId
    	where b.UserId=@userid and b.SendSeq=@sendseq
    
    	open bcTCBatches
    
    	fetch next from bcTCBatches into @tablename, @co, @batchmonth, @batchid, @source, @module
    	while @@fetch_status = 0
    	begin
    		if @tablename <> ''
    		begin 
    	  		exec @rcode = bspHQBCExitCheck @co, @batchmonth, @batchid, @source, @tablename, @msg output
    	
    	 		delete from dbo.bPRTT 
    			where UserId=@userid and SendSeq=@sendseq and Module=@module and Co=@co and 
    				BatchMth=@batchmonth and BatchId=@batchid
    	
    		    fetch next from bcTCBatches into @tablename, @co, @batchmonth, @batchid, @source, @module
    		end
    	end
    
    	close bcTCBatches
      	deallocate bcTCBatches
    
    --	--if no PR batch entry is found, just act as if this is not a restart - this should never happen but just in case ...
    --  	select @prbatchid=BatchId from PRTT where UserId=@userid and SendSeq=@sendseq and Module='PR'
    --  	if @@rowcount = 0 select @restart='N' 
	end --{if @restart='Y'}
    
	if @restart='N'
	begin  
    	  -- add Send parameters to bPRTS and create batches
    	  -- validate that there are timesheets to send
	 	if (select count(*) from dbo.PRRH with (nolock) where PRCo=@prco and PRGroup = @prgroup and JCCo=isnull(@jcco,JCCo) and Job=isnull(@job,Job) and 
			PostDate<=isnull(@throughdate,PostDate) and Status=2 /*and (InUseBy is null or InUseBy=@userid)*/ and 
			PRBatchMth is null and PRBatchId is null) = 0
		begin
			select @msg = 'Found no timesheets ready to send', @rcode = 1
			goto bspexit
		end
    	  -- validate PRCo
		if @prco is null
		begin
			select @msg = 'Missing PR Co#', @rcode = 1
			goto bspexit
		end
		-- validate PR Group
		if @prgroup is null
		begin
			select @msg = 'Missing PR Group', @rcode = 1
			goto bspexit
		end

		-- validate PR Pay Period Ending Date
		if @enddate is null
		begin
			select @msg = 'Missing Period Ending Date', @rcode = 1
			goto bspexit
		end
		-- validate PR Batch Restrict flag
		if @prrestrict is null or @prrestrict not in ('Y','N')
		begin
			select @msg = 'PR Batch Restrict flag should be either ''Y'' or ''N''', @rcode = 1
			goto bspexit
		end
		-- validate JC Batch Restrict flag
		if @jcrestrict is null or @jcrestrict not in ('Y','N')
		begin
			select @msg = 'JC Batch Restrict flag should be either ''Y'' or ''N''', @rcode = 1
			goto bspexit
		end
		-- validate EM Batch Restrict flag
		if @emrestrict is null or @emrestrict not in ('Y','N')
		begin
			select @msg = 'EM Batch Restrict flag should be either ''Y'' or ''N''', @rcode = 1
			goto bspexit
		end
		-- validate Payment Sequence
		if @payseq is null
		begin
			select @msg = 'Missing Payment Sequence', @rcode = 1
			goto bspexit
		end
    	
		-- get PR Pay Period data
		select @begindate=BeginDate, @multimth=MultiMth, @beginmth=BeginMth, @endmth=EndMth, 
		@cutoffdate=CutoffDate, @stdhrs=Hrs 
		from dbo.PRPC with (nolock)
		where PRCo=@prco and PRGroup=@prgroup and PREndDate=@enddate

		-- set batch month equal to beginning month for pay period
		select @month = @beginmth
    
		-- read company regular/overtime/doubletime earnings codes
      	--Issue #135490, remove PRCo values related to State & LocalCodes & flags
		select @coregec=CrewRegEC, @cootec=CrewOTEC, @codblec=CrewDblEC
  		from dbo.PRCO with (nolock) where PRCo=@prco

		if @coregec is null
		begin
			select @msg = 'Please set up Crew Timesheet Earnings Code for this PR Company', @rcode = 1
			goto bspexit
		end
    	
		--BEGIN TRANSACTION --Send initiation (ie. bPRTS/bPRTT inserts and batch creation) is performed within this transaction
    	
		--get unique Send Sequence #
		select @sendseq = 0, @numrows = 0
		while (select count(*) from dbo.PRTT with (nolock) where UserId=@userid and SendSeq=@sendseq)>0
		begin
			if @sendseq = 2147483647
			begin
				select @msg = 'Out of send sequence #''s - please contact ViewpointCS', @rcode=1
				goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
			end
			select @sendseq=@sendseq+1
		end
    	
  
		--insert bPRTS entry
		insert into dbo.bPRTS (UserId, SendSeq, PRCo, BatchMth, PRGroup, EndDate, PaySeq, JCCo, Job, ThroughDate,
		PRRestrict, JCRestrict, EMRestrict)
		values (@userid, @sendseq, @prco, @month, @prgroup, @enddate, @payseq, @jcco, @job, @throughdate,
		@prrestrict, @jcrestrict, @emrestrict)

		if @@rowcount = 0
		begin
			select @msg = 'Unable to initiate send', @rcode = 1
			goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
		end
--InUseBy is set here
		-- Step 2: Mark applicable timesheets as Send In Progress (status 3), set InUseBy and SendSeq
		update dbo.bPRRH
		set Status=3, /*InUseBy=@userid,*/ SendSeq=@sendseq
		where PRCo=@prco and PRGroup=@prgroup and JCCo=isnull(@jcco,JCCo) and Job=isnull(@job,Job) and
		PostDate<=isnull(@throughdate,PostDate) and Status=2 and /*InUseBy is null and*/ --issue 29065 removed check for InUseBy=@userid - that should never happen and only makes the code confusing
		PRBatchMth is null and PRBatchId is null

	end --{if @restart='N'}
    
   
	-- Step 3: Create PR/EM/JC batches
	select @adjust = 'N'

	-- create PR batch
	select @source = 'PR Entry', @tablename = 'PRTB'
    
	exec @prbatchid = bspHQBCInsert @prco, @month, @source, @tablename, @prrestrict, @adjust, @prgroup, @enddate, @errmsg
	
	if @prbatchid = 0  
	begin
		select @msg = 'Unable to create PR batch for PR Company' + convert(varchar(3),@prco) + ': ' + isnull(@errmsg,''), @rcode = 1
		goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
	end

	--store batchid in bPRTT Send Batches table
	insert into dbo.bPRTT (UserId, SendSeq, Module, Co, BatchMth, BatchId)
	values(@userid, @sendseq, 'PR', @prco, @month, @prbatchid)

	if @@rowcount = 0  
	begin
		select @msg = 'Unable to add batch to bPRTT', @rcode = 1
		goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
	end
    
	-- create EM batch(s)
	select @source = 'EMRev', @tablename = 'EMBF'
	if @multimth='N'
	begin
		-- create a batch for each different emco in the group of timesheets being sent
		select @emco=min(rq.EMCo) from dbo.PRRQ rq with (nolock)
		join dbo.PRRH rh with (nolock) on rh.PRCo=rq.PRCo and rh.Crew=rq.Crew and rh.PostDate=rq.PostDate and rh.SheetNum=rq.SheetNum
		where rh.PRCo=@prco and rh.SendSeq=@sendseq and /*rh.InUseBy=@userid and*/ --issue 29065 use sendseq as criteria rather than checking JCCo/Job/etc. again and again which searching for batches to create
		(isnull(rq.Phase1Usage,0)<>0 or isnull(rq.Phase2Usage,0)<>0 or isnull(rq.Phase3Usage,0)<>0 or -- issue 29065 use isnull in case phase usage is null
		isnull(rq.Phase4Usage,0)<>0 or isnull(rq.Phase5Usage,0)<>0 or isnull(rq.Phase6Usage,0)<>0 or
		isnull(rq.Phase7Usage,0)<>0 or isnull(rq.Phase8Usage,0)<>0)

		WHILE @emco is not null
		begin
			exec @embatchid = bspHQBCInsert @emco, @month, @source, @tablename, @emrestrict, @adjust, @nullgroup, @nullenddate, @errmsg
			if @embatchid = 0
			begin
				select @msg = 'Unable to create EM batch for EM Company' + convert(varchar(3),@emco) + ': ' + isnull(@errmsg,''), @rcode = 1
				goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
			end
			--store batchid in bPRTT Send Batches table

			insert into dbo.bPRTT (UserId, SendSeq, Module, Co, BatchMth, BatchId)
			values(@userid, @sendseq, 'EM', @emco, @month, @embatchid)
			if @@rowcount = 0
			begin
				select @msg = 'Unable to add batch to bPRTT', @rcode = 1
				goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
			end

			select @emco=min(rq.EMCo) from dbo.PRRQ rq with (nolock)
			join dbo.PRRH rh with (nolock) on rh.PRCo=rq.PRCo and rh.Crew=rq.Crew and rh.PostDate=rq.PostDate and rh.SheetNum=rq.SheetNum
			where rh.PRCo=@prco and rh.SendSeq=@sendseq and /*rh.InUseBy=@userid and*/ --issue 29065 use sendseq as criteria rather than checking JCCo/Job/etc. again and again which searching for batches to create
			(isnull(rq.Phase1Usage,0)<>0 or isnull(rq.Phase2Usage,0)<>0 or isnull(rq.Phase3Usage,0)<>0 or  -- issue 29065 use isnull in case phase usage is null
			isnull(rq.Phase4Usage,0)<>0 or isnull(rq.Phase5Usage,0)<>0 or isnull(rq.Phase6Usage,0)<>0 or
			isnull(rq.Phase7Usage,0)<>0 or isnull(rq.Phase8Usage,0)<>0) 
			and @emco<rq.EMCo

		end
	end
	else
    
	begin
     	-- create a batch for each different emco/month in the group of timesheets being sent
		select @emco=min(rq.EMCo) from dbo.PRRQ rq with (nolock)
		join dbo.PRRH rh with (nolock) on rh.PRCo=rq.PRCo and rh.Crew=rq.Crew and rh.PostDate=rq.PostDate and rh.SheetNum=rq.SheetNum
		where rh.PRCo=@prco and rh.SendSeq=@sendseq and /*rh.InUseBy=@userid and */--issue 29065 use sendseq as criteria rather than checking JCCo/Job/etc. again and again which searching for batches to create
		(isnull(rq.Phase1Usage,0)<>0 or isnull(rq.Phase2Usage,0)<>0 or isnull(rq.Phase3Usage,0)<>0 or -- issue 29065 use isnull in case phase usage is null
		isnull(rq.Phase4Usage,0)<>0 or isnull(rq.Phase5Usage,0)<>0 or isnull(rq.Phase6Usage,0)<>0 or 
		isnull(rq.Phase7Usage,0)<>0 or isnull(rq.Phase8Usage,0)<>0)

		WHILE @emco is not null
		begin
			select @postdate=min(rq.PostDate) from dbo.PRRQ rq with (nolock)
			join dbo.PRRH rh with (nolock) on rh.PRCo=rq.PRCo and rh.Crew=rq.Crew and rh.PostDate=rq.PostDate and rh.SheetNum=rq.SheetNum
			where rh.PRCo=@prco and rh.SendSeq=@sendseq and /*rh.InUseBy=@userid and*/ --issue 29065 use sendseq as criteria rather than checking JCCo/Job/etc. again and again which searching for batches to create
			(isnull(rq.Phase1Usage,0)<>0 or isnull(rq.Phase2Usage,0)<>0 or isnull(rq.Phase3Usage,0)<>0 or  -- issue 29065 use isnull in case phase usage is null
			isnull(rq.Phase4Usage,0)<>0 or isnull(rq.Phase5Usage,0)<>0 or isnull(rq.Phase6Usage,0)<>0 or
			isnull(rq.Phase7Usage,0)<>0 or isnull(rq.Phase8Usage,0)<>0)
			and rq.EMCo=@emco

    		WHILE @postdate is not null
			begin
				-- use begin month unless timesheet posting date is past the cutoffdate ... then use end month
				select @batchmonth=@beginmth
				if @postdate > @cutoffdate select @batchmonth=@endmth

    			if (select count(*) from dbo.PRTT with (nolock) where UserId=@userid and SendSeq=@sendseq and Module='EM' and
    					Co=@emco and BatchMth=@batchmonth)=0
				begin
					exec @embatchid = bspHQBCInsert @emco, @batchmonth, @source, @tablename, @emrestrict, @adjust, @nullgroup, @nullenddate, @errmsg
					if @embatchid = 0
					begin
						select @msg = 'Unable to create EM batch for EM Company' + convert(varchar(3),@emco) + ': ' + isnull(@errmsg,''), @rcode = 1
						goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
					end
					--store batchid in bPRTT Send Batches table
					insert into dbo.bPRTT (UserId, SendSeq, Module, Co, BatchMth, BatchId)
					values(@userid, @sendseq, 'EM', @emco, @batchmonth, @embatchid)
					if @@rowcount = 0
					begin
						select @msg = 'Unable to add batch to bPRTT', @rcode = 1
						goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
					end
				end
    			
				select @postdate=min(rq.PostDate) from dbo.PRRQ rq with (nolock)
				join dbo.PRRH rh with (nolock) on rh.PRCo=rq.PRCo and rh.Crew=rq.Crew and rh.PostDate=rq.PostDate and rh.SheetNum=rq.SheetNum
				where rh.PRCo=@prco and rh.SendSeq=@sendseq and /*rh.InUseBy=@userid and */--issue 29065 use sendseq as criteria rather than checking JCCo/Job/etc. again and again which searching for batches to create
				(isnull(rq.Phase1Usage,0)<>0 or isnull(rq.Phase2Usage,0)<>0 or isnull(rq.Phase3Usage,0)<>0 or -- issue 29065 use isnull in case phase usage is null
				isnull(rq.Phase4Usage,0)<>0 or isnull(rq.Phase5Usage,0)<>0 or isnull(rq.Phase6Usage,0)<>0 or 
				isnull(rq.Phase7Usage,0)<>0 or isnull(rq.Phase8Usage,0)<>0)
				and rq.EMCo=@emco and @postdate<rq.PostDate
			end

     		select @emco=min(rq.EMCo) from dbo.PRRQ rq  with (nolock)
     		join dbo.PRRH rh with (nolock) on rh.PRCo=rq.PRCo and rh.Crew=rq.Crew and rh.PostDate=rq.PostDate and rh.SheetNum=rq.SheetNum
     		where rh.PRCo=@prco and rh.SendSeq=@sendseq and /*rh.InUseBy=@userid and */ --issue 29065 use sendseq as criteria rather than checking JCCo/Job/etc. again and again which searching for batches to create
   			(isnull(rq.Phase1Usage,0)<>0 or isnull(rq.Phase2Usage,0)<>0 or isnull(rq.Phase3Usage,0)<>0 or -- issue 29065 use isnull in case phase usage is null
   			 isnull(rq.Phase4Usage,0)<>0 or isnull(rq.Phase5Usage,0)<>0 or isnull(rq.Phase6Usage,0)<>0 or 
   			 isnull(rq.Phase7Usage,0)<>0 or isnull(rq.Phase8Usage,0)<>0)
   			and @emco<rq.EMCo
		end
	end

	-- create JC batch(s)
	select @source = 'JC Progres', @tablename = 'JCPP'

	-- create cursor to find all JCCo/PostDate combinations ... a batch will be created for each
	declare bcTC cursor for
	select distinct JCCo, PostDate
	from dbo.PRRH with (nolock) where PRCo=@prco and SendSeq=@sendseq and /*InUseBy=@userid and*/ --issue 29065 use sendseq as criteria rather than checking JCCo/Job/etc. again and again which searching for batches to create
	(isnull(Phase1Units,0)<>0 or isnull(Phase2Units,0)<>0 or isnull(Phase3Units,0)<>0 or isnull(Phase4Units,0)<>0 or -- issue 29065 use isnull in case phase units is null
	isnull(Phase5Units,0)<>0 or isnull(Phase6Units,0)<>0 or isnull(Phase7Units,0)<>0 or isnull(Phase8Units,0)<>0)

      
	open bcTC
      
	-- spin thru cursor
	fetch next from bcTC into @postjcco, @postdate
	while @@fetch_status=0
	begin
		if @postjcco is null
		begin
			select @msg = 'JC Company is missing from a timesheet (timecard date:' + convert(varchar(8),@postdate), @rcode=1
			close bcTC
			deallocate bcTC
			goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
		end

    	-- for batchmonth, use begin month unless timesheet posting date is past the cutoffdate ... then use end month
    	select @batchmonth=@beginmth
    	if @postdate > @cutoffdate select @batchmonth=@endmth
    
    	-- create batch
    	exec @jcbatchid = bspHQBCInsert @postjcco, @batchmonth, @source, @tablename, @jcrestrict, @adjust, @nullgroup, @nullenddate, @errmsg
    	if @jcbatchid = 0
	    begin
			select @msg = 'Unable to create JC batch for JC Company' + convert(varchar(3),@postjcco) + ': ' + isnull(@errmsg,''), @rcode = 1
			goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
	    end
    
    	-- store batchid in bPRTT Send Batches table
    	insert into dbo.bPRTT (UserId, SendSeq, Module, Co, BatchMth, BatchId, PostDate)
    		values(@userid, @sendseq, 'JC', @postjcco, @batchmonth, @jcbatchid, @postdate)
    	if @@rowcount = 0
		begin
			select @msg = 'Unable to add batch to bPRTT', @rcode = 1
			goto bsperror_no_rollback --issue 29065 use bsperror with no rollback
		end
    
      	fetch next from bcTC into @postjcco, @postdate
	end
    
	close bcTC
	deallocate bcTC

	goto transfer_timesheets
   
    
   --   init_error: --if error occurs during init, just back out <- issue 29065 no special code needed when error occurs during batch creation - just use bsperror with no rollback
   -- 
   --   -- set timesheets Status back to 2, remove InUseBy and clear SendSeq
   --   update dbo.bPRRH
   --   set Status=2, InUseBy=null, SendSeq=null
   --   where InUseBy=@userid and SendSeq=@sendseq
   -- 
   --   --remove bPRTS entry and bPRTT entries
   --   delete from dbo.bPRTT where UserId=@userid and SendSeq=@sendseq
   --   delete from dbo.bPRTS where UserId=@userid and SendSeq=@sendseq
   -- 
   --   goto bsperror
    
      --COMMIT TRANSACTION --Send initiation (ie. bPRTS/bPRTT inserts and batch creation) is performed within this transaction
      
transfer_timesheets:
      -- Step 4: transfer timesheet data to batches
     
      -- loop through timesheets through specified date which are ready to send and which match the PRCo and optional JCCo/Job specifications
	declare bcPRRH cursor for
	select Crew, PostDate, SheetNum, JCCo, Job, Shift, PhaseGroup, Phase1, isnull(Phase1Units,0), Phase1CostType, --issue 29065 convert Phase Units values to 0 if null
	Phase2, isnull(Phase2Units,0), Phase2CostType, Phase3, isnull(Phase3Units,0), Phase3CostType, Phase4, isnull(Phase4Units,0), 
	Phase4CostType, Phase5, isnull(Phase5Units,0), Phase5CostType, Phase6, isnull(Phase6Units,0), Phase6CostType,
	Phase7, isnull(Phase7Units,0), Phase7CostType, Phase8, isnull(Phase8Units,0), Phase8CostType
	from dbo.PRRH with (nolock) where PRCo=@prco and /*InUseBy=@userid and*/ SendSeq=@sendseq

	open bcPRRH
	select @headercursor = 1
   
      
timesheet_header_loop:
	fetch next from bcPRRH into @crew, @postdate, @sheetnum, @postjcco, @postjob, @shift, @phasegroup,
	@phase1, @phase1units, @phase1ct, @phase2, @phase2units, @phase2ct, @phase3, @phase3units, 
	@phase3ct, @phase4, @phase4units, @phase4ct, @phase5, @phase5units, @phase5ct, @phase6, 
	@phase6units, @phase6ct, @phase7, @phase7units, @phase7ct, @phase8, @phase8units, @phase8ct

  	if @@fetch_status<>0
		goto timesheet_header_end
    
	--read job's craft template & LockPhases flag & validate job status
	--read job's craft template for rate lookup plus job state and local
	--Issue #135490, remove Job values related to State & LocalCodes
	select @template=CraftTemplate		--, @lockphases=LockPhases, @jobstatus=JobStatus
	from dbo.JCJM with (nolock) where JCCo=@postjcco and Job=@postjob
    /*  --validate phases
    	select @activeyn=ActiveYN from JCJP with (nolock) where JCCo=@postjcco and Job=@postjob and Phase=@phase1
    	if @@rowcount = 0 and @lockphases = 'Y'
    		begin
    		select @msg = 'Phase ' + @phase1 + ' is not on job ' + @postjob + ' - Job Phases Locked'
    		goto PRRE_detail_error
    		end
    	if @@rowcount <> 0 and @activeyn = 'N'
    		begin
    		select @msg = 'Phase ' + @phase1 + ' is inactive', @rcode = 1
    	    goto PRRE_detail_error
    		end
    
    	select @activeyn=ActiveYN from JCJP with (nolock) where JCCo=@postjcco and Job=@postjob and Phase=@phase2
    	if @@rowcount = 0 and @lockphases = 'Y'
    		begin
    		select @msg = 'Phase ' + @phase2 + ' is not on job ' + @postjob + ' - Job Phases Locked'
    		goto PRRE_detail_error
    		end
    	if @@rowcount <> 0 and @activeyn = 'N'
    		begin
    		select @msg = 'Phase ' + @phase2 + ' is inactive', @rcode = 1
    	    goto PRRE_detail_error
    		end
    
    	select @activeyn=ActiveYN from JCJP with (nolock) where JCCo=@postjcco and Job=@postjob and Phase=@phase3
    	if @@rowcount = 0 and @lockphases = 'Y'
    		begin
    		select @msg = 'Phase ' + @phase3 + ' is not on job ' + @postjob + ' - Job Phases Locked'
    		goto PRRE_detail_error
    		end
    	if @@rowcount <> 0 and @activeyn = 'N'
    		begin
    		select @msg = 'Phase ' + @phase3 + ' is inactive', @rcode = 1
    	    goto PRRE_detail_error
    		end
    
    	select @activeyn=ActiveYN from JCJP with (nolock) where JCCo=@postjcco and Job=@postjob and Phase=@phase4
    	if @@rowcount = 0 and @lockphases = 'Y'
   
    		begin
    		select @msg = 'Phase ' + @phase4 + ' is not on job ' + @postjob + ' - Job Phases Locked'
    		goto PRRE_detail_error
    		end
    	if @@rowcount <> 0 and @activeyn = 'N'
    		begin
    		select @msg = 'Phase ' + @phase4 + ' is inactive', @rcode = 1
    	    goto PRRE_detail_error
    		end
    
    	select @activeyn=ActiveYN from JCJP with (nolock) where JCCo=@postjcco and Job=@postjob and Phase=@phase5
    	if @@rowcount = 0 and @lockphases = 'Y'
    		begin
    		select @msg = 'Phase ' + @phase5 + ' is not on job ' + @postjob + ' - Job Phases Locked'
    		goto PRRE_detail_error
    		end
    	if @@rowcount <> 0 and @activeyn = 'N'
    		begin
    		select @msg = 'Phase ' + @phase5 + ' is inactive', @rcode = 1
    	    goto PRRE_detail_error
    		end
    
    	select @activeyn=ActiveYN from JCJP with (nolock) where JCCo=@postjcco and Job=@postjob and Phase=@phase6
    	if @@rowcount = 0 and @lockphases = 'Y'
    		begin
    		select @msg = 'Phase ' + @phase6 + ' is not on job ' + @postjob + ' - Job Phases Locked'
    		goto PRRE_detail_error
    		end
    	if @@rowcount <> 0 and @activeyn = 'N'
    		begin
    		select @msg = 'Phase ' + @phase6 + ' is inactive', @rcode = 1
    	    goto PRRE_detail_error
    		end
    
    	select @activeyn=ActiveYN from JCJP with (nolock) where JCCo=@postjcco and Job=@postjob and Phase=@phase7
    	if @@rowcount = 0 and @lockphases = 'Y'
    		begin
    		select @msg = 'Phase ' + @phase7 + ' is not on job ' + @postjob + ' - Job Phases Locked'
    		goto PRRE_detail_error
    		end
    	if @@rowcount <> 0 and @activeyn = 'N'
    		begin
    		select @msg = 'Phase ' + @phase7 + ' is inactive', @rcode = 1
    	    goto PRRE_detail_error
    		end
    
    	select @activeyn=ActiveYN from JCJP with (nolock) where JCCo=@postjcco and Job=@postjob and Phase=@phase8
    	if @@rowcount = 0 and @lockphases = 'Y'
    		begin
    		select @msg = 'Phase ' + @phase8 + ' is not on job ' + @postjob + ' - Job Phases Locked'
    		goto PRRE_detail_error
    		end
    	if @@rowcount <> 0 and @activeyn = 'N'
    		begin
    		select @msg = 'Phase ' + @phase8 + ' is inactive', @rcode = 1
    	    goto PRRE_detail_error
    		end*/
    
      	
	-- read crew regular/overtime/doubletime earnings codes overrides
	select @crewregec=RegECOvride, @crewotec=OTECOvride, @crewdblec=DblECOvride
	from dbo.PRCR with (nolock) where PRCo=@prco and Crew=@crew

	--for posting Employee Hours details, default earnings codes from PRCO and apply crew overrides
	select @regearncode=@coregec, @otearncode=@cootec, @dblearncode=@codblec
	if @crewregec is not null select @regearncode=@crewregec
	if @crewotec is not null select @otearncode=@crewotec
	if @crewdblec is not null select @dblearncode=@crewdblec
      	
  	--compute day number
  	select @daynum=Datediff(day,@begindate,@postdate)+1
  	
  	--for posting to EM batch get offset glco
  	select @offsetglco=GLCo from dbo.JCCO with (nolock) where JCCo=@postjcco
  
  	--get GLCo for jc company for posting job PR timecards
  	select @jccoglco=GLCo from dbo.JCCO with (nolock) where JCCo=@postjcco
  	
    
  	BEGIN TRANSACTION
      
	-- PRRE: loop through Employee Hours details
	declare bcPRRE cursor for 
	select Employee, LineSeq, Craft, Class, Phase1RegHrs, Phase1OTHrs, Phase1DblHrs,
	Phase2RegHrs, Phase2OTHrs, Phase2DblHrs, Phase3RegHrs, Phase3OTHrs, Phase3DblHrs, 
	Phase4RegHrs, Phase4OTHrs, Phase4DblHrs, Phase5RegHrs, Phase5OTHrs, Phase5DblHrs, 
	Phase6RegHrs, Phase6OTHrs, Phase6DblHrs, Phase7RegHrs, Phase7OTHrs, Phase7DblHrs, 
	Phase8RegHrs, Phase8OTHrs, Phase8DblHrs
	from dbo.PRRE with (nolock) where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheetnum

  	open bcPRRE
  	select @prre_cursor = 1
      	
PRRE_detail_loop:
	fetch next from bcPRRE into @employee, @lineseq, @craft, @class, @phase1reghrs, @phase1othrs,
	@phase1dblhrs, @phase2reghrs, @phase2othrs, @phase2dblhrs, @phase3reghrs, @phase3othrs,
	@phase3dblhrs, @phase4reghrs, @phase4othrs, @phase4dblhrs, @phase5reghrs, @phase5othrs,
	@phase5dblhrs, @phase6reghrs, @phase6othrs, @phase6dblhrs, @phase7reghrs, @phase7othrs,
	@phase7dblhrs, @phase8reghrs, @phase8othrs, @phase8dblhrs

	if @@fetch_status <> 0
		goto PRRE_detail_end
      		
	--read employee info
	--Issue #135490, remove Employee values related to State & LocalCodes & flags
	select @inscode=InsCode, @prdept=PRDept, @cert=CertYN, @useempins=UseIns
	from dbo.PREH with (nolock) where PRCo=@prco and Employee=@employee
	if @@rowcount=0 goto PRRE_detail_loop --if employee not found, skip
	

      		
	--add entries to PR batch for each phase selected
	--spin through phases
	select @phasenum=1
	while @phasenum<=8
	begin
		if @phasenum=1 select @phase=@phase1, @reghrs=@phase1reghrs, @othrs=@phase1othrs, @dblhrs=@phase1dblhrs
		if @phasenum=2 select @phase=@phase2, @reghrs=@phase2reghrs, @othrs=@phase2othrs, @dblhrs=@phase2dblhrs
		if @phasenum=3 select @phase=@phase3, @reghrs=@phase3reghrs, @othrs=@phase3othrs, @dblhrs=@phase3dblhrs
		if @phasenum=4 select @phase=@phase4, @reghrs=@phase4reghrs, @othrs=@phase4othrs, @dblhrs=@phase4dblhrs
		if @phasenum=5 select @phase=@phase5, @reghrs=@phase5reghrs, @othrs=@phase5othrs, @dblhrs=@phase5dblhrs
		if @phasenum=6 select @phase=@phase6, @reghrs=@phase6reghrs, @othrs=@phase6othrs, @dblhrs=@phase6dblhrs
		if @phasenum=7 select @phase=@phase7, @reghrs=@phase7reghrs, @othrs=@phase7othrs, @dblhrs=@phase7dblhrs
		if @phasenum=8 select @phase=@phase8, @reghrs=@phase8reghrs, @othrs=@phase8othrs, @dblhrs=@phase8dblhrs
		if @phase is not null
		begin
		
			--spin through hours
			select @hournum=1
			while @hournum<=3
			begin
				if @hournum=1 select @hours=@reghrs, @earncode=@regearncode
				if @hournum=2 select @hours=@othrs, @earncode=@otearncode
				if @hournum=3 select @hours=@dblhrs, @earncode=@dblearncode
				if isnull(@hours,0)<>0
				begin
					--get rate/amt
					exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, 
						@shift, @earncode, @rate output, @msg output
					if @rcode<>0 goto PRRE_detail_error
					select @amt=isnull(@rate,0)*@hours --#29993
					     		
					--use phaseinscode if phase is not null, employee ins override is not enforced, and InsByPhase is set in PRCO
					select @phaseinscode = null
					if @phase is not null and @useempins = 'N'
						begin
						
							if exists(select * from dbo.PRCO with (nolock) where PRCo = @prco and InsByPhase = 'Y')
							begin
															
								select @phaseinscode = t.InsCode
								from dbo.JCTI t with (nolock)
								join dbo.JCJM j with (nolock) on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
								where t.JCCo = @postjcco and PhaseGroup = @phasegroup and Phase = @phase and j.Job = @postjob
								if @@rowcount = 0
					    		begin
					    			-- check Phase Master using valid portion
					    			-- validate JC Company -  get valid portion of phase code
					    			select @validphasechars = ValidPhaseChars
					    			from JCCO where JCCo = @postjcco --#27417
					    			if @@rowcount <> 0
				    				begin
				         				if @validphasechars > 0
			          					begin
			          						select @pphase = substring(@phase,1,@validphasechars) + '%'
							
			          						select Top 1 @phaseinscode = t.InsCode
			          						from bJCTI t
			          						join JCJM j on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
			          						where t.JCCo = @postjcco and t.PhaseGroup = @phasegroup and t.Phase like @pphase and j.Job = @postjob
			          						Group By t.PhaseGroup, t.Phase, t.InsCode
		          						end -- end valid part
			        				end-- end select of jc company
				     			end -- end of full phase not found
							end
							
							-- #140924 get insurance code from phase (JCJP)
							SELECT @phaseinscode = ISNULL(p.InsCode, @phaseinscode)
							FROM dbo.JCJP p WITH (NOLOCK)
							WHERE p.JCCo = @postjcco and p.PhaseGroup = @phasegroup and p.Phase = @phase and p.Job = @postjob
													
						end						


  						if @phaseinscode is not null
  							select @inscode = @phaseinscode
 
						--Get State and Local defaults
						--Issue #135490, moved code to common procedure below which could be accessed by other procedures			
						exec @rcode = vspPRGetStateLocalDflts @prco, @employee, @postjcco, @postjob, @postlocalcode output, @posttaxstate output,
							@postunempstate output, @postinsstate output, @errmsg output
						if @rcode <> 0 goto PRRE_detail_error
			     						
  						-- get next batch sequence #
  						select @seq=isnull(max(BatchSeq),0)+1 from dbo.PRTB with (nolock) where Co=@prco and Mth=@month and BatchId=@prbatchid
  						if @@rowcount=0
						begin
							select @msg='Error getting next batch sequence #', @rcode=1
							goto PRRE_detail_error
						end
  						-- insert PR batch entry
  						insert into dbo.bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, PostSeq, Type,
  							PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, Equipment, EMGroup, RevCode,
  							EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode, PRDept, 
  							Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, DayNum)
  						values (@prco, @month, @prbatchid, @seq, 'A', @employee, @payseq, null, 'J',
  							@postdate, @postjcco, @postjob, @phasegroup, @phase, @jccoglco, null, null, null, null, 
  							null, null, @posttaxstate, @postlocalcode, @postunempstate, @postinsstate, @inscode, @prdept, 
  							@crew, @cert, @craft, @class, @earncode, @shift, @hours, @rate, @amt, @daynum)
  						
  						if @@rowcount = 0
						begin
							select @msg = 'Unable to add PR batch entry for emp#' + convert(varchar(6),@employee), @rcode = 1
							goto PRRE_detail_error
						end
					end
  					select @hournum=@hournum+1
				end
			end
  			select @phasenum=@phasenum+1
		end
		
		goto PRRE_detail_loop
      
PRRE_detail_end:
      	close bcPRRE
      	deallocate bcPRRE
      	select @prre_cursor = 0
      	goto PostPRRO
      
PRRE_detail_error:
      	close bcPRRE
      	deallocate bcPRRE
      	select @prre_cursor = 0
      	goto bsperror
      
PostPRRO:
      	-- PRRO: loop through Other Job Earnings details
      	declare bcPRRO cursor for 
      		select Employee, LineSeq, Craft, Class, EarnCode, Phase1Value, Phase2Value, Phase3Value, 
      			Phase4Value, Phase5Value, Phase6Value, Phase7Value, Phase8Value
      		from dbo.PRRO with (nolock) where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheetnum
      	
      	open bcPRRO
      	select @prro_cursor = 1
      	
PRRO_detail_loop:
		fetch next from bcPRRO into @employee, @lineseq, @craft, @class, @earncode, @phase1value,
		@phase2value, @phase3value, @phase4value, @phase5value, @phase6value, @phase7value, 
		@phase8value
		if @@fetch_status <> 0
			goto PRRO_detail_end
      
		--read employee info
		--Issue #135490, remove Employee values related to State & LocalCodes & flags
		select @inscode=InsCode, @prdept=PRDept, @cert=CertYN, @useempins=UseIns
		from dbo.PREH with (nolock) where PRCo=@prco and Employee=@employee
		if @@rowcount=0 goto PRRE_detail_loop --if employee not found, skip

		--get earnings method
		select @method=Method from dbo.PREC with (nolock) where PRCo=@prco and EarnCode=@earncode

		--add entries to PR batch for each phase selected
		--spin through phases
		select @phasenum=1
		while @phasenum<=8
		begin
			if @method = 'A'
			begin
				if @phasenum=1 select @phase=@phase1, @amt=@phase1value
				if @phasenum=2 select @phase=@phase2, @amt=@phase2value
				if @phasenum=3 select @phase=@phase3, @amt=@phase3value
				if @phasenum=4 select @phase=@phase4, @amt=@phase4value
				if @phasenum=5 select @phase=@phase5, @amt=@phase5value
				if @phasenum=6 select @phase=@phase6, @amt=@phase6value
				if @phasenum=7 select @phase=@phase7, @amt=@phase7value
				if @phasenum=8 select @phase=@phase8, @amt=@phase8value
				select @hours=0, @rate=0 --zero out hours and rate
			end
  			else
			begin
				if @phasenum=1 select @phase=@phase1, @hours=@phase1value
				if @phasenum=2 select @phase=@phase2, @hours=@phase2value
				if @phasenum=3 select @phase=@phase3, @hours=@phase3value
				if @phasenum=4 select @phase=@phase4, @hours=@phase4value
				if @phasenum=5 select @phase=@phase5, @hours=@phase5value
				if @phasenum=6 select @phase=@phase6, @hours=@phase6value
				if @phasenum=7 select @phase=@phase7, @hours=@phase7value
				if @phasenum=8 select @phase=@phase8, @hours=@phase8value
				select @amt=0
			end

  			if @phase is not null and (isnull(@amt,0)<>0 or isnull(@hours,0)<>0)
			begin
      				/*--if method is amount, get hrs & rate
      				if @method = 'A'
      					begin
      					select @hours = @stdhrs
      					if @hours<>0
      						select @rate=@amt/@hours
      					else
      						select @rate=0
      					end*/
      
				--otherwise, calculate amount using default rate
				if @method <> 'A'
				begin
					exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @template, 
					@shift, @earncode, @rate output, @msg output
					
					--135248 - If @rcode = 0 then reset the @msg parameter.
					if @rcode = 0 
					begin
						select @msg = ''
					end
					else
					begin
						goto PRRO_detail_error
					end
					
					--if @rcode<>0 goto PRRO_detail_error
					--end 135248
					
					select @amt=isnull(@rate,0)*@hours --#29993
				end
      
					  --Get State and Local defaults
				--Issue #135490, moved code to common procedure below which could be accessed by other procedures			
				exec @rcode = vspPRGetStateLocalDflts @prco, @employee, @postjcco, @postjob, @postlocalcode output, @posttaxstate output,
					@postunempstate output, @postinsstate output, @errmsg output
				if @rcode <> 0 goto PRRO_detail_error

      				--use phaseinscode if phase is not null, employee ins override is not enforced, and InsByPhase is set in PRCO
      				select @phaseinscode = null
      				if @phase is not null and @useempins = 'N'
  					begin
  						if exists(select * from dbo.PRCO with (nolock) where PRCo = @prco and InsByPhase = 'Y')
						begin
							select @phaseinscode = t.InsCode
							from dbo.JCTI t with (nolock)
							join dbo.JCJM j with (nolock) on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
							where t.JCCo = @postjcco and PhaseGroup = @phasegroup and Phase = @phase
								and j.Job = @postjob
						end
  					end
  					
      				if @phaseinscode is not null
      					select @inscode = @phaseinscode
      		
      				-- get next batch sequence #
      				select @seq=isnull(max(BatchSeq),0)+1 from dbo.PRTB with (nolock) where Co=@prco and Mth=@month and BatchId=@prbatchid
      				if @@rowcount=0
      				begin
      					select @msg='Error getting next batch sequence #', @rcode=1
      					goto PRRO_detail_error
      				end
      				-- insert PR batch entry
      				insert into dbo.bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, PostSeq, Type,
      					PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, Equipment, EMGroup, RevCode,
      					EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode, PRDept, 
      					Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, DayNum)
      				values (@prco, @month, @prbatchid, @seq, 'A', @employee, @payseq, null, 'J',
      					@postdate, @postjcco, @postjob, @phasegroup, @phase, @jccoglco, @emco, @equip, @emgroup, @revcode, 
      					@equipjcct, @usageunits, @posttaxstate, @postlocalcode, @postunempstate, @postinsstate, @inscode, @prdept, 
      					@crew, @cert, @craft, @class, @earncode, @shift, @hours, @rate, @amt, @daynum)
      				
      				if @@rowcount = 0
      				begin
      					select @msg = 'Unable to add PR batch entry for emp#' + convert(varchar(6),@employee), @rcode = 1
      					goto PRRO_detail_error
      				end
      			end
      			select @phasenum=@phasenum+1
      		end
      		goto PRRO_detail_loop
      
PRRO_detail_end:
      	close bcPRRO
      	deallocate bcPRRO
      	select @prro_cursor = 0
      	goto PostPRRN
      
PRRO_detail_error:
      	close bcPRRO
      	deallocate bcPRRO
      	select @prro_cursor = 0
      	goto bsperror
      
PostPRRN:
      	-- PRRN: loop through Non-Job Earnings details
      	declare bcPRRN cursor for 
      		select Employee, LineSeq, Craft, Class, EarnCode, isnull(Hours,0), StdPayRate --issue 29065 set Hours to 0 if null
      		from dbo.PRRN with (nolock) where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheetnum
      	
      	open bcPRRN
      	select @prrn_cursor = 1
      	
PRRN_detail_loop:
  		fetch next from bcPRRN into @employee, @lineseq, @craft, @class, @earncode, @hours, @stdpayrate
  		if @@fetch_status <> 0
  		   goto PRRN_detail_end
      		
  		--read employee info
  		--Issue #135490, remove Employee values related to State & LocalCodes & flags
  		select @inscode=InsCode, @prdept=PRDept, @cert=CertYN, @hourlyrate=HrlyRate, @glco=GLCo
  		from dbo.PREH with (nolock) where PRCo=@prco and Employee=@employee
  		if @@rowcount=0 goto PRRE_detail_loop --if employee not found, skip
      		
  		if @glco is null 
		begin
			select @msg='Missing GL company for Employee ' + convert(varchar(6),@employee), @rcode=1
			goto PRRN_detail_error
		end
  
		--Get State and Local defaults
		--Issue #135490, moved code to common procedure below which could be accessed by other procedures			
		exec @rcode = vspPRGetStateLocalDflts @prco, @employee, null, null, @postlocalcode output, @posttaxstate output,
			@postunempstate output, @postinsstate output, @errmsg output
		if @rcode <> 0 goto PRRN_detail_error

		--get factored rate
  		select @rate=0
  		if @stdpayrate='Y' select @rate=@hourlyrate
  
  		select @factor = Factor from dbo.PREC with (nolock) where PRCo = @prco and EarnCode = @earncode
  		select @rate=@rate*@factor
  
  		--compute amount
  		select @amt=@rate*@hours
  
  		-- get next batch sequence #
  		select @seq=isnull(max(BatchSeq),0)+1 from dbo.PRTB with (nolock) where Co=@prco and Mth=@month and BatchId=@prbatchid
  		if @@rowcount=0
		begin
			select @msg='Error getting next batch sequence #', @rcode=1
			goto PRRN_detail_error
		end
  		-- insert PR batch entry
  		--Issue #135490, Replaced @empunempstate, @empinsstate with @postunempstate, @postinsstate
  		insert into dbo.bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, PostSeq, Type,
  			PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, Equipment, EMGroup, RevCode,
  			EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode, PRDept, 
  			Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, DayNum)
  		values (@prco, @month, @prbatchid, @seq, 'A', @employee, @payseq, null, 'J',
  			@postdate, null, null, @phasegroup, null, @glco, null, null, null, null, 
  			null, null, @posttaxstate, @postlocalcode, @postunempstate, @postinsstate, @inscode, @prdept,		
  			@crew, @cert, @craft, @class, @earncode, @shift, @hours, @rate, @amt, @daynum)
  		
  		if @@rowcount = 0
		begin
			select @msg = 'Unable to add PR batch entry for emp#' + convert(varchar(6),@employee), @rcode = 1
			goto PRRN_detail_error
		end
  
  		goto PRRN_detail_loop
      
PRRN_detail_end:
      	close bcPRRN
      	deallocate bcPRRN
      	select @prrn_cursor = 0
      	goto PostPRRQ
      
PRRN_detail_error:
      	close bcPRRN
      	deallocate bcPRRN
      	select @prrn_cursor = 0
      	goto bsperror
      
PostPRRQ:
     	-- for bEMBF/bJCPP batch month use begin month unless timesheet posting date is past the cutoffdate ... then use end month
     	select @batchmonth=@beginmth
     	if @postdate > @cutoffdate select @batchmonth=@endmth
     
      	-- PRRQ: loop through Equipment details
      	declare bcPRRQ cursor for 
      		select EMCo, EMGroup, Equipment, LineSeq, Employee, Phase1Usage, Phase1CType, Phase1Rev,
      			Phase2Usage, Phase2CType, Phase2Rev, Phase3Usage, Phase3CType, Phase3Rev,
      			Phase4Usage, Phase4CType, Phase4Rev, Phase5Usage, Phase5CType, Phase5Rev,
      			Phase6Usage, Phase6CType, Phase6Rev, Phase7Usage, Phase7CType, Phase7Rev,
      			Phase8Usage, Phase8CType, Phase8Rev
      		from dbo.PRRQ with (nolock) where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheetnum and
      			(Phase1Usage<>0 or Phase2Usage<>0 or Phase3Usage<>0 or Phase4Usage<>0 or 
      			Phase5Usage<>0 or Phase6Usage<>0 or Phase7Usage<>0 or Phase8Usage<>0)
      	open bcPRRQ
      	select @prrq_cursor = 1
      	
      	PRRQ_detail_loop:
      		fetch next from bcPRRQ into @emco, @emgroup, @equipment, @emlineseq, @ememployee, @phase1usage, @phase1eqct, 
      			@phase1rev,	@phase2usage, @phase2eqct, @phase2rev ,@phase3usage, @phase3eqct, @phase3rev,
      			@phase4usage, @phase4eqct, @phase4rev, @phase5usage, @phase5eqct, @phase5rev, @phase6usage, 
      			@phase6eqct, @phase6rev, @phase7usage, @phase7eqct, @phase7rev, @phase8usage, @phase8eqct, @phase8rev
      		if @@fetch_status <> 0
      		   goto PRRQ_detail_end
      		
      		--determine correct EM Batch ID to use
      		select @embatchid=BatchId from dbo.PRTT with (nolock)
      		where UserId=@userid and SendSeq=@sendseq and Module='EM' and Co=@emco and BatchMth=@batchmonth
      	
      		--get glco
      		select @glco=e.GLCo from dbo.EMCO e with (nolock) join dbo.HQCO h with (nolock) on h.HQCo=e.EMCo where e.EMCo=@emco
      		if @@rowcount = 0
      		 	begin
      		 	select @msg = 'Error getting GL Company for EM batch post', @rcode = 1
      		 	goto PRRQ_detail_error
      		 	end
    
    		-- get meter readings & category from EMEM and check active status and type
    		select @prevhourmeter=HourReading, @prevodometer=OdoReading, @category=Category --, @status=Status
    		from dbo.bEMEM with (nolock) where EMCo=@emco and Equipment=@equipment
   /* 		if @rcode <> 0
    		    begin
    		    select @msg = 'Equipment ' + convert(varchar(10),@equipment) + ' is invalid', @rcode = 1
    		    goto PRRQ_detail_error
    		    end*/
    /*	  	if @status not in ('A', 'D')
    	  		begin
    		    select @msg = 'Error - Equipment ' + convert(varchar(10),@equipment) + ' is inactive', @rcode = 1
    		    goto PRRQ_detail_error
    	  		end
    		if @type = 'C'
    			begin
    		    select @msg = 'Error - Equipment ' + convert(varchar(10),@equipment) + ' is a component', @rcode = 1
    		    goto PRRQ_detail_error
    			end*/
      
    
      		--add entries to PR batch for each phase selected
      		--spin through phases
      		select @phasenum=1
      		while @phasenum<=8
      			begin
      			if @phasenum=1 select @phase=@phase1, @phaseusage=@phase1usage, @phaserev=@phase1rev, @jccosttype=@phase1eqct
      			if @phasenum=2 select @phase=@phase2, @phaseusage=@phase2usage, @phaserev=@phase2rev, @jccosttype=@phase2eqct
      			if @phasenum=3 select @phase=@phase3, @phaseusage=@phase3usage, @phaserev=@phase3rev, @jccosttype=@phase3eqct
      			if @phasenum=4 select @phase=@phase4, @phaseusage=@phase4usage, @phaserev=@phase4rev, @jccosttype=@phase4eqct
      			if @phasenum=5 select @phase=@phase5, @phaseusage=@phase5usage, @phaserev=@phase5rev, @jccosttype=@phase5eqct
      			if @phasenum=6 select @phase=@phase6, @phaseusage=@phase6usage, @phaserev=@phase6rev, @jccosttype=@phase6eqct
      			if @phasenum=7 select @phase=@phase7, @phaseusage=@phase7usage, @phaserev=@phase7rev, @jccosttype=@phase7eqct
      			if @phasenum=8 select @phase=@phase8, @phaseusage=@phase8usage, @phaserev=@phase8rev, @jccosttype=@phase8eqct
      			if @phase is not null and isnull(@phaseusage,0)<>0
      				begin
      				-- check for missing revenue code
      				if @phaserev is null
      					begin
      					select @msg = 'Equipment ' + convert(varchar(10),@equipment) + ' / Phase ' + @phase + ' missing Revenue Code', @rcode=1
      				    goto PRRQ_detail_error
      				    end
      
      				-- check for missing cost type
      				if @jccosttype is null
      					begin
      					select @msg = 'Equipment ' + convert(varchar(10),@equipment) + ' / Phase ' + @phase + ' missing cost type', @rcode=1
      				    goto PRRQ_detail_error
      				    end
      
      				--get GLOffsetAcct
      				exec @rcode = bspARMRDefaultGLAcctGet @postjcco, @postjob, @phase, @jccosttype, @offsetacct output, @msg output
      				--135248 rejection fix.  Return code from sp call not being fully evaluated.  If return code = 0
      				--then we should be clearing the @msg value since this variable is reused.
      				--if @rcode <> 0
  					--begin
  						--select @msg = 'Error getting GL offset account for EM batch post, job ' + @postjob + ', phase ' + @phase + ', cost type ' + convert(varchar(3),@jccosttype), @rcode = 1 --#27417
  						--goto PRRQ_detail_error
  					--end
  					
  					if @rcode = 0
  					begin
  						--If bspARMRDefaultGLAcctGet is successful, clear the message which will be the GL Description
  						select @msg = ''
  					end
  					else
  					begin
  						--assuming anything other then a return code of 0 is a problem.
  					  	select @msg = 'Error getting GL offset account for EM batch post, job ' + @postjob + ', phase ' + @phase + ', cost type ' + convert(varchar(3),@jccosttype), @rcode = 1 --#27417
  						goto PRRQ_detail_error
  					end
  					--end 135248
		
      				-- get revenue rate and TimeUM
      				exec @rcode = bspEMRevRateUMDflt @emco, @emgroup, 'J', @equipment, @category, @phaserev,
      					@postjcco, @postjob, @revrate output, @time_um output, @work_um output, @msg=@errmsg output
      				if @rcode <> 0
      				    begin
      				    select @msg = 'Equipment ' + convert(varchar(10),@equipment) + ': ' + isnull(@errmsg,''), @rcode = 1
      				    goto PRRQ_detail_error
      				    end
    
    				-- get Current Hour Meter
    				select @updatehourmeter=UpdateHourMeter, @hrspertimeum=HrsPerTimeUM from dbo.bEMRC with (nolock)
    				where EMGroup = @emgroup and RevCode = @phaserev
    
    				if @updatehourmeter='Y'
    					select @currhourmeter = @prevhourmeter + (@phaseusage * @hrspertimeum)
    				else
    					select @currhourmeter = 0
      
      				-- validate equipment attachments before insert
      				select @attachment = min(Equipment)
                 		from dbo.EMEM with (nolock)
                 		where EMCo = @emco and AttachToEquip = @equipment and Status = 'A'
                 		while @attachment is not null
                   		begin
                   		select @acategory = Category, @posttoattach = AttachPostRevenue
                   		from dbo.EMEM with (nolock)
                   		where EMCo = @emco and Equipment = @attachment
                   		if @posttoattach = 'Y'
                     			begin
                     			exec @rcode = bspEMRevRateUMDflt @emco, @emgroup, 'J', @attachment, @acategory, @phaserev,
      							@postjcco, @postjob, @attachrevrate output, @attachtime_um output, @work_um output, @msg=@errmsg output
                     			if @rcode <> 0
      							begin
      							select @msg = 'Equipment ' + convert(varchar(10),@equipment) + ' / Attachment ' + convert(varchar(10),@attachment) + ': ' + isnull(@errmsg,''), @rcode = 1
      				    		goto PRRQ_detail_error
      				    		end
      
      						end
                   		select @attachment = min(Equipment)
                   		from dbo.EMEM with (nolock)
                   		where EMCo = @emco and AttachToEquip = @equipment and Status = 'A' and Equipment > @attachment
                   		end
      
      				-- get next batch sequence #
      			    select @seq = isnull(max(BatchSeq),0) + 1 from dbo.bEMBF with (nolock)
      			    where Co=@emco and Mth=@batchmonth and BatchId=@embatchid
      				-- insert EM batch entry
      			    insert into dbo.bEMBF (Co, Mth, BatchId, BatchSeq, EMGroup, BatchTransType, EMTransType, Source,
      					Equipment, RevCode, ActualDate, GLCo, GLOffsetAcct, PRCo, PREmployee, JCCo, 
      					Job, PhaseGrp, JCPhase, JCCostType, RevRate, UM, RevWorkUnits, TimeUM, RevTimeUnits,
      				 	RevDollars, OffsetGLCo, PreviousHourMeter, CurrentHourMeter, PreviousOdometer, CurrentOdometer, PRCrew) --issue 24034
      			    values(@emco, @batchmonth, @embatchid, @seq, @emgroup, 'A', 'J', 'EMRev', 
      					@equipment, @phaserev, @postdate, @glco, @offsetacct, @prco, @ememployee, @postjcco, 
      					@postjob, @phasegroup, @phase, @jccosttype, @revrate, null, 0, @time_um, @phaseusage,
      				    @revrate*@phaseusage, @offsetglco, @prevhourmeter, @currhourmeter, @prevodometer, 0, @crew)
      				if @@rowcount = 0
      					begin
      					select @msg = 'Unable to add EM batch entry for equipment ' + convert(varchar(10),@equipment), @rcode = 1
      					goto PRRQ_detail_error
      					end
      				end
      			select @phasenum=@phasenum+1
      			end
      			goto PRRQ_detail_loop
      
      	PRRQ_detail_end:
      	close bcPRRQ
      	deallocate bcPRRQ
      	select @prrq_cursor = 0
      	goto PostJCProgress
      
      	PRRQ_detail_error:
      	close bcPRRQ
      	deallocate bcPRRQ
      	select @prrq_cursor = 0
      	goto bsperror
      
      	PostJCProgress:
      	--Post JC Progress (if any)
      	if @phase1units<>0 or @phase2units<>0 or @phase3units<>0 or @phase4units<>0 or @phase5units<>0 or
      			@phase6units<>0 or @phase7units<>0 or @phase8units<>0
      		begin
      		--determine correct JC Batch ID to use
      		select @jcbatchid=BatchId from dbo.PRTT with (nolock)
      		where UserId=@userid and SendSeq=@sendseq and Module='JC' and Co=@postjcco and BatchMth=@batchmonth
    			and PostDate=@postdate
      	
      		--spin through phases
  
      		select @phasenum=1
      		while @phasenum<=8
      			begin
      			if @phasenum=1 select @phase=@phase1, @phaseunits=@phase1units, @jccosttype=@phase1ct
      			if @phasenum=2 select @phase=@phase2, @phaseunits=@phase2units, @jccosttype=@phase2ct
      			if @phasenum=3 select @phase=@phase3, @phaseunits=@phase3units, @jccosttype=@phase3ct
      			if @phasenum=4 select @phase=@phase4, @phaseunits=@phase4units, @jccosttype=@phase4ct
      			if @phasenum=5 select @phase=@phase5, @phaseunits=@phase5units, @jccosttype=@phase5ct
      			if @phasenum=6 select @phase=@phase6, @phaseunits=@phase6units, @jccosttype=@phase6ct
      			if @phasenum=7 select @phase=@phase7, @phaseunits=@phase7units, @jccosttype=@phase7ct
      			if @phasenum=8 select @phase=@phase8, @phaseunits=@phase8units, @jccosttype=@phase8ct
      			if @phase is not null and isnull(@phaseunits,0)<>0
      				begin

					--Issue 135248 - Add phase if not on job...subject to locked phases rules.
					exec @rcode = bspJCADDPHASE @postjcco, @postjob, @phasegroup, @phase, 'N', null, @errmsg output

   	 				if @rcode <> 0
 					begin
 						GoTo bsperror
 					End
 					
 					--Issue 135248 - Must also add cost type if not on the phase.  This could be independent of 
 					--phase add...that is...phase could have already been on job but not cost type.

 					exec @rcode = bspJCADDCOSTTYPE @jcco = @postjcco, @job = @postjob, @phasegroup = @phasegroup, 
 					@phase = @phase, @costtype = @jccosttype, @override = 'N', @msg = @errmsg output
 					
 					if @rcode <> 0
 					begin
 						select @msg = @errmsg
 						GoTo bsperror
 					End 
 					--end Issue 135248
 					
      				--get Unit of Measure, projected, estimated, actual and plugged values
      				exec @rcode = bspJCVCOSTTYPEForTSSend @postjcco, @postjob, @phasegroup, @phase, @jccosttype,
      					@postdate, @um output, @projected output, @estimated output, @actual output, @plugged output,
   					@msg=@errmsg output
      				if @rcode <> 0
      				    begin
      				    select @msg = 'Error posting progress for phase ' + @phase + ': ' + isnull(@errmsg,''), @rcode = 1
      				    goto bsperror
      				    end
   
   				--compute total actual
   				select @totalactual = @actual + @phaseunits + isnull((select ActualUnits from dbo.bJCPP with (nolock)
   				where Co=@postjcco and Mth=@batchmonth and BatchId=@jcbatchid and Job=@postjob and 
   					PhaseGroup=@phasegroup and Phase=@phase and CostType=@jccosttype and PRCo=@prco and Crew=@crew),0)
   				--compute progress complete
--   				if @plugged='Y'
--   					begin
--   					if isnull(@projected,0) <> 0 -- issue 25815
--   						select  @progresscmplt = @totalactual / @projected
--   					else
--      						select @progresscmplt = 0
--   					end
--   				else
--   					begin
--   					if isnull(@estimated,0) <> 0 -- issue 25815
--   						select @progresscmplt = @totalactual / @estimated
--   					else
--      						select @progresscmplt = 0
--   					end

				--Issue 124951
				if @plugged='Y'
   					begin
   					if isnull(@projected,0) <> 0 -- issue 25815
						begin
							if (@totalactual / @projected) <=99.9999
								select  @progresscmplt = @totalactual / @projected
							else
								select @progresscmplt=99.999
						end
   					else
      					begin
							select @progresscmplt = 0
						end
   					end
   				else
					if isnull(@estimated,0) <> 0 -- issue 25815
					begin
						if ABS((@totalactual / @estimated)) <=99.9999
						begin
							select @progresscmplt = @totalactual / @estimated
						end

						else
						begin
							if (@totalactual / @estimated) <0
							begin
								select @progresscmplt=-99.999
							end
							else
							begin
							    select @progresscmplt=99.999
							end
						end
					end
				else
				begin
					select @progresscmplt = 0
				end
      				--post progress

     			    update dbo.bJCPP
     				set UM=@um, ActualUnits=ActualUnits+@phaseunits, ProgressCmplt=@progresscmplt
     				where Co=@postjcco and Mth=@batchmonth and BatchId=@jcbatchid and Job=@postjob and 
     					PhaseGroup=@phasegroup and Phase=@phase and CostType=@jccosttype and PRCo=@prco and Crew=@crew
     			    if @@rowcount = 0
     					begin

						select @progressseq = max(isnull(BatchSeq,0))+1 
						from bJCPP j with (nolock)
						where j.Co = @postjcco and j.Mth = @batchmonth and j.BatchId = @jcbatchid

--						if @progressseq is null set @seq = 1
						if @progressseq is null set @progressseq = 1

     	 				insert into dbo.bJCPP (Co, Mth, BatchId, Job, PhaseGroup, Phase, CostType, UM, ActualUnits, 
     	 					ProgressCmplt, PRCo, Crew, ActualDate, BatchSeq)
     	 				values (@postjcco, @batchmonth, @jcbatchid, @postjob, @phasegroup, @phase, @jccosttype, @um, @phaseunits,
     	 					@progresscmplt, @prco, @crew, @postdate, @progressseq)
     	 				
     	 				if @@rowcount = 0
     	 					begin
     	 					select @msg = 'Unable to add JC batch entry for phase ' + @phase + ', cost type ' + convert(varchar(3),@jccosttype), @rcode = 1
     	 					goto bsperror
     	 					end
     					end
      	
      				end
      				
      			select @phasenum=@phasenum+1
      			end
      		end
      
      	--plug PR BatchMth and BatchID into PRRH timesheet header, update status to 4 and clear InUseBy
     
		--issue 29065 clear sendseq as well
		--Issue 133863 - Do not clear out send sequence. This will break the link that bspPRTSSendCancel uses to 
		--to roll back the Status.  This comes into play if sending multiple timesheets.  If an error occurs
		--on the second or subsequent timesheets SendCancel will cancel all the batches created, including the
		--the ones in this send that were sent successfully.  However, since the SendSeq has been removed
		--SendCancel will not be able to locate those timesheets that should be changed back from Status 4 
		--to Status 2.  If we are going to remove the SendSeq I think we need to do this at the end of the 
		--procedure after everything has been sent.  mh 06/16/09
      	update dbo.bPRRH
      	set Status=4, PRBatchMth=@month, PRBatchId=@prbatchid /*InUseBy=null, SendSeq=null*/ 
      	where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheetnum
      
      	COMMIT TRANSACTION
      
      	goto timesheet_header_loop
      
      timesheet_header_end:
      close bcPRRH
      deallocate bcPRRH
      select @headercursor = 0
      
      --Step 5: remove inuseby from batches
      declare bcTCBatches cursor for 
    	select a.Co, a.Mth, a.BatchId, a.Source, a.TableName
    	from dbo.HQBC a with (nolock)
    	join dbo.PRTT b with (nolock) on a.Co=b.Co and a.Mth=b.BatchMth and a.BatchId=b.BatchId
    	where UserId=@userid and SendSeq=@sendseq
    
      open bcTCBatches
      
      fetch next from bcTCBatches into @co, @batchmonth, @batchid, @source, @tablename
      while @@fetch_status = 0
      	begin 
      	exec @rcode = bspHQBCExitCheck @co, @batchmonth, @batchid, @source, @tablename, @msg output
      	fetch next from bcTCBatches into @co, @batchmonth, @batchid, @source, @tablename
      	end
      
      close bcTCBatches
      deallocate bcTCBatches
      
      --Step 6: remove bPRTS entry to indicate successful completion
      delete dbo.bPRTS
      where UserId=@userid and SendSeq=@sendseq
      
      --Step 7: delete any bPRTT entries which are over a year old and are not logged in bPRTS (issue 29196)
      delete from dbo.bPRTT where datediff(day,BatchMth,getdate())>365 and not (UserId=@userid and SendSeq=@sendseq)
      
      
      bspexit:
      	if @headercursor=1
      		begin
      		close bcPRRH
      		deallocate bcPRRH
      		select @headercursor=0
      		end
      	if @prre_cursor=1
      		begin
      		close bcPRRE
      		deallocate bcPRRE
      		select @prre_cursor=0
      		end
      	if @prro_cursor=1
      		begin
      		close bcPRRO
      		deallocate bcPRRO
      		select @prro_cursor=0
      		end
      	if @prrn_cursor=1
      		begin
      		close bcPRRN
      		deallocate bcPRRN
      		select @prrn_cursor=0
      		end
      	if @prrq_cursor=1
      		begin
      		close bcPRRQ
      		deallocate bcPRRQ
      		select @prrq_cursor=0
      		end
      
      	if @rcode=0
      	begin
      		--prepare batch list to return
      		select @msg = 'Batches Created:' + char(10) + char(13)
      	
      		declare bcPRTT cursor for select Module, Co, BatchMth, BatchId from dbo.PRTT with (nolock) where UserId=@userid and SendSeq=@sendseq
      		open bcPRTT
      	
      		fetch next from bcPRTT into @batchmodule, @co, @batchmonth, @batchid
      		while @@fetch_status = 0
      		begin 
      			select @msg = @msg + @batchmodule + ' Company: ' + convert(varchar(3),@co)
     			select @msg = @msg + '   Month: ' + convert(char(2),@batchmonth,1) + '/' + convert(char(2),@batchmonth,2)
     			select @msg = @msg + '   Batch#: ' + convert(varchar(6),@batchid) + char(10) + char(13)
      			fetch next from bcPRTT into @batchmodule, @co, @batchmonth, @batchid
      		end
      		
      		close bcPRTT
      		deallocate bcPRTT

			--133863 Clear out SendSeq here after everything has been sent.  If we have made it
			--here there should not have been any errors.  Errors will drop into bsperror or
			--bsperror_no_rollback
     		update dbo.bPRRH
      		set SendSeq=null 
      		where PRCo=@prco and SendSeq = @sendseq

      	end
      
      	return @rcode
      
      bsperror:
      	ROLLBACK TRANSACTION
      
      bsperror_no_rollback:
   
     -- 	-- Set any remaining un-sent timesheets Ready to Send (status 2) and clear InUseBy
      	update bPRRH
      	set [Status]=2, PRBatchId = null, PRBatchMth = null /*, InUseBy=null*/
      	where PRCo=@prco and JCCo=isnull(@jcco,JCCo) and Job=isnull(@job,Job) and
      		PostDate<=isnull(@throughdate,PostDate) and Status=3 /*and InUseBy=@userid*/

      	if @headercursor=1
      		begin
      		close bcPRRH
      		deallocate bcPRRH
      		select @headercursor=0
      		end
      
      	-- Write error message to AbortError field in bPRTS (may not exist if error occurred in init section)
      	if exists (select * from dbo.PRTS with (nolock) where UserId=@userid and SendSeq=@sendseq)
     		update dbo.bPRTS
     	 	set AbortError=@msg
     	 	where UserId=@userid and SendSeq=@sendseq
      
      	select @msg = isnull(@msg,'') + ' - Send Aborted' --+ char(13) + char(10) + '[bspPRTSSend]'
      	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPRTSSend] TO [public]
GO
