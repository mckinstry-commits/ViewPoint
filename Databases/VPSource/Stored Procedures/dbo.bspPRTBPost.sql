
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPRTBPost    Script Date: 8/28/99 9:36:34 AM ******/
     CREATE PROCEDURE [dbo].[bspPRTBPost]
    /***********************************************************
     * CREATED BY: kb 2/3/98
     * MODIFIED By : GG 06/02/99
     *              GG 01/27/99 - Initialize bPRSQ ChkType value
     *              GG 05/01/00 - Mod for Memo column
     *              GG 01/29/01 - removed bPRSQ.InUse
     *              MV 06/20/01 - Issue 12769 BatchUserMemoUpdate
     *				GG 10/23/01 - Clceanup, shorten transaction, added validation, removed local variables
     *				EN 12/13/01 - issue 14693 - use direct deposit sequence feature when insert bPRSQ entries
     *				EN 2/15/02 - issue 11031 - override pay method of 'E' with 'C' if OverrideDirDep feature is being used
     *				EN 2/26/02 - issue 13689 - must remove in use flag so delete trigger will work
     *				EN 3/8/02 - issue 14181 Write EquipPhase to bPRTH
     *              CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
     *				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
     *				SR 07/09/02 - issue 17738 pass @phasegroup to bspJCVPHASE
     *				EN 10/9/02 - issue 18877 change double quotes to single
     *				EN 12/08/03 - issue 23061  added isnull check, with (nolock), and dbo
     *				EN 2/11/04 - issue 18616 re-index attachments
     *				EN 4/6/04 - issue 24213 handle attachments
     *				EN 4/12/04 - issue 18616 fix problem with index stats not getting updated
     *				TV 04/14/04 23255 - Update EMEM Job, JobDate and DateLastUsed when Job Type
     *				EN 9/05/06 issue 122181 added code to speed up posting
     *				GH 12/06/06 - issue 123303  skipping user memo update proc if no users memos exist
	 *				EN 1/10/07 - issue 27864 changed HQBC TableName reference from 'PRTZGrid' to 'PRTB'
	 *				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
	 *				mh 05/18/09 - Issue 133439/127603
	 *				EN 5/28/2009 #132025 added "local fast_forward" to cursor declare statement
	 *				EN 12/7/2009 #125127  don't include EquipCType when insert PRTH when there is no equipment
	 *				MH 02/02/2011 - 142827 SM Changes
	 *              ECV 02/22/11 - 131640 Update links to SM during posting.
	 *				ECV 03/15/11 - Added Craft, Class and Shift to WorkCompleted update.
	 *              ECV 08/23/11 - Added SMCostType to WorkCompleted update.
	 *				GF 11/02/2011 TK-00000 changed @Technician from 10 to 15
	 *				JG 02/09/2012 - TK-12388 - Added SMJCCostType and SMPhaseGroup.
	 *				MH 04/09/2012 - TK-12388 - Corrected SMJCCostType post to Work Completed on changed timecards.
	 *				ECV 03/19/12 - issue 146018 Do not delete WorkCompleted when PR timecard changed to zero hours.
	 *				ECV 06/07/12 TK-14637 removed SMPhaseGroup. Use PhaseGroup instead.
	 *				JayR 11/16/2012 TK-16638.  Change how the join is done to bPRTH so deadlocks do not occur.
	 *				JVH 4/29/13 - TFS-44860 Updated check to see if work completed is part of an invoice
     *
     * USAGE:
     * 	Called by the PR Timecard Btch Posting program to post a validated batch
     *	of PR Timecards
     *
     * INPUT PARAMETERS
     *   @co            PR Co#
     *   @mth           Month of batch
     *   @batchid       Batch ID to validate
     *   @dateposted    Posting date to write out if successful
     *
     * OUTPUT PARAMETERS
     *   @errmsg        error message
     *
     * RETURN VALUE
     *   0              success
     *   1              fail
     *****************************************************/
    
     	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
    	 @dateposted bDate = null, @errmsg varchar(255) output)
    as
    set nocount on
    
DECLARE @DebugFlag bit
SET @DebugFlag=0

    declare @rcode int, @opencursor tinyint, @status tinyint, @msg varchar(255), @seq int, @transtype char(1),
    	@employee bEmployee, @payseq tinyint, @postseq smallint, @jcco bCompany, @job bJob, @phase bPhase,
     	@prgroup bGroup, @prenddate bDate, @cmco bCompany, @cmacct bCMAcct, @paymethod char(1), @chktype char(1),
     	@posttoall bYN, @dirdeposit char(1), @jcdept bDept, @dept bDept, @errorstart varchar(50),
        @Notes varchar(256), @phasegroup_lower tinyint, @guid uniqueIdentifier, @linetype char(1), @oldlinetype char(1)
   
    -- for equipment posting TV 04/14/04 23255
    declare @emco bCompany, @equip bEquip, @jobdate bDate
    
    declare @smbcid bigint
    declare @ddpayseq tinyint -- issue 14693

    declare @prtbud_flag bYN

	DECLARE @SMCo bCompany, @Technician varchar(15), @bTechnicianInvalid bit, @IsBilled bit,
		@SMWorkOrder int, @SMScope int, @SMPayType varchar(10), @SMCostType smallint, @hours bHrs, @amt money, @oldAmt money,
		@oldSMCo bCompany, @oldSMWorkOrder int, @oldSMScope int, @oldSMPayType varchar(10), @oldSMCostType smallint,
		@oldHours bHrs, @oldEmployee bEmployee, @PostDate smalldatetime, @oldPaySeq int, @oldPostSeq INT,
		@SMJCCostType dbo.bJCCType, @OldSMJCCostType dbo.bJCCType, @PhaseGroup dbo.bGroup, @OldPhaseGroup dbo.bGroup
		
	DECLARE @WorkCompleted int, @smworkcompletedid bigint, @newsmworkcompletedid bigint, 
		@newWorkCompleted int, @Craft bCraft, @Class bClass, @Shift tinyint,
		@oldCraft bCraft, @oldClass bClass, @oldShift tinyint  -- issue 131640

    select @rcode = 0
    
    select @prtbud_flag = 'N'

    -- check for date posted
    if @dateposted is null
    	begin
        select @errmsg = 'Missing batch posting date!', @rcode = 1
        goto bspexit
        end
    
    -- validate HQ Batch
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'PR Entry', 'PRTB', @errmsg output, @status output
    if @rcode <> 0 goto bspexit
    if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
    	begin
        select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
        goto bspexit
        end
    -- get PR info from Batch Control entry - already validated
    select @prgroup = PRGroup, @prenddate = PREndDate
    from dbo.bHQBC with (nolock)
    where Co = @co and Mth = @mth and BatchId = @batchid
    
    -- set HQ Batch status to 4 (posting in progress)
    update dbo.bHQBC
    set Status = 4, DatePosted = @dateposted
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
        select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
        goto bspexit
        end

   -- -- -- check for submittal user memos
   if exists(select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME like 'ud%' and TABLE_NAME='bPRTB')
   	select @prtbud_flag = 'Y'
    
    -- create a cursor on Timecard batch entries
    declare bcPRTB cursor local fast_forward for
    select BatchSeq, BatchTransType, Employee, PaySeq, PostSeq, JCCo, Job, Phase, PhaseGroup, UniqueAttchID, [Type], OldType
    from dbo.bPRTB with (nolock)
    where Co = @co and Mth = @mth and BatchId = @batchid
    
    open bcPRTB
    select @opencursor = 1
    
    -- loop through all rows in PR Timecard Batch
    pr_posting_loop:
    	fetch next from bcPRTB into @seq, @transtype, @employee, @payseq, @postseq,
    		@jcco, @job, @phase, @phasegroup_lower, @guid, @linetype, @oldlinetype
    
    
    	if @@fetch_status <> 0  goto pr_posting_end
    
        select @errorstart = 'Seq#' + convert(varchar(6),@seq)
    
    	-- get current JC Department, to be updated with each job timecard
        select @jcdept = null
        if @jcco is not null and @job is not null and @phase is not null
    		begin
    		exec @rcode = bspJCVPHASE @jcco, @job, @phase, @phasegroup_lower, 'N', @dept = @jcdept output, @msg = @msg output
    		if @rcode = 1
    			begin
    			select @errmsg = @errorstart + ' - ' + isnull(@msg,''), @rcode = 1
    			goto bspexit
    			end
    		end
    
    	-- set Processed flag to 'N' in Employee Seq Control
     	update dbo.bPRSQ
        set Processed = 'N'
        where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
    		and PaySeq = @payseq
    	if @@rowcount = 0
    		begin
    		-- get Employee defaults
     		select @posttoall = PostToAll, @dirdeposit = DirDeposit, @ddpayseq = DDPaySeq -- issue 14693 (read DDPaySeq)
            from dbo.bPREH with (nolock)
            where PRCo = @co and Employee = @employee
    		if @@rowcount = 0
    			begin
    			select @errmsg = @errorstart + ' - Invalid Employee!', @rcode = 1
    			goto bspexit
    			end
    
            select @paymethod = 'C', @chktype = 'C' -- default to computer check
     		if @dirdeposit = 'A' and (select OverrideDirDep from dbo.PRPS with (nolock) where PRCo=@co and PRGroup=@prgroup and PREndDate=@prenddate and PaySeq=@payseq)='N' --issue 11031 - added check for OverrideDirDep
    			begin
    			if (@ddpayseq is null or @ddpayseq = '') or @ddpayseq = @payseq -- issue 14693 (add dirdepseq comparison)
    				select @paymethod = 'E', @chktype = null -- active EFT
    			end
    
     		select @cmco = CMCo, @cmacct = CMAcct
            from dbo.bPRGR with (nolock)
            where PRCo = @co and PRGroup = @prgroup
    		if @@rowcount = 0
    			begin
    			select @errmsg = @errorstart + ' - Invalid PR Group!', @rcode = 1
    			goto bspexit
    			end
    
    		-- add Employee Payment Sequence Control
     		insert dbo.bPRSQ (PRCo, PRGroup, PREndDate, Employee, PaySeq, CMCo, CMAcct, PayMethod,
     			ChkType, Hours, Earnings, Dedns, SUIEarnings, PostToAll, Processed, CMInterface)
     		values(@co, @prgroup, @prenddate, @employee, @payseq, @cmco, @cmacct, @paymethod,
     			@chktype, 0, 0, 0, 0, @posttoall, 'N', 'N')
    		if @@rowcount <> 1
    			begin
    			select @errmsg = @errorstart + ' - Unable to add or update Employee Sequence Control entry!', @rcode = 1
    			goto bspexit
    			end
    		end
    
    
        begin transaction	-- start a transaction to post batch entry
    
    	if @transtype = 'A'     -- add new PR Timecard
            begin
            -- get next Posting Sequence #
            DECLARE @intMaxRetry INT;
			SET @intMaxRetry = 5;
			SET @postseq = NULL;
            
            WHILE (@intMaxRetry >= 0 AND @postseq IS NULL)
            BEGIN
				SET @intMaxRetry = @intMaxRetry - 1;  --Prevent us from looping forever.
				
				--We could add this into the insert however it might end up locking more rows then desired -> deadlock!!!!
    			SELECT @postseq = isnull(max(PostSeq),0)+1
				FROM dbo.bPRTH with (nolock)
				WHERE PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
    				and Employee = @employee and PaySeq = @payseq
    		
    			BEGIN TRY 
					insert dbo.bPRTH (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, Type, PostDate, JCCo, Job,
						 PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode, CompType,
     					Component, RevCode, EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState,
     					InsCode, PRDept, Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, BatchId, JCDept, Memo,
    					UniqueAttchID, --issue 24213
    					EquipPhase, SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType, --issue 14181, 142827
    					SMJCCostType,PRTBKeyID) 
    				select @co, @prgroup, @prenddate, Employee, PaySeq, @postseq, Type, PostDate, JCCo, Job,
       					PhaseGroup, Phase, GLCo, EMCo, WO, WOItem, Equipment, EMGroup, CostCode, CompType,
         				Component, RevCode, 
						Case when Equipment is not null then EquipCType else null end,
						UsageUnits, TaxState, LocalCode, UnempState, InsState,
         				InsCode, PRDept, Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, @batchid, @jcdept, Memo,
    					@guid, --issue 24213
    					EquipPhase, SMCo, SMWorkOrder, SMScope, SMPayType, SMCostType, --issue 14181, 142827
    					SMJCCostType,
    					KeyID
    				from dbo.bPRTB with (nolock)
    				where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    			END TRY 
    			BEGIN CATCH
    				--If we are attempting to insert the same row then we will try again.
    				IF ERROR_NUMBER() = 2601 AND ERROR_MESSAGE() LIKE '%biPRTH%'
    					BEGIN
	    					SET @postseq = NULL;	
	    					--DECLARE @delay VARCHAR(8) --If we conflicted 
							--SELECT @delay = '00:00:0' + CAST(ABS(CHECKSUM(NEWID())) % 5 AS VARCHAR(10))
							--WAITFOR DELAY @delay
    					END
    				ELSE 
    					BEGIN
    						goto pr_posting_error;
    					END
    			END CATCH;
    		END
    		
    		if @postseq IS NULL
    			begin
    			select @errmsg = @errorstart + ' - Unable to add new Timecard! ';
    			goto pr_posting_error
    			end

    		-- 131640 Begin
    		-- If this record is linked to SM then update links
    		SET @smworkcompletedid=NULL
   			select @smbcid = SMBCID, @smworkcompletedid=vSMBC.SMWorkCompletedID
   			from vSMBC
   			where PostingCo = @co and InUseMth = @mth and InUseBatchId = @batchid and InUseBatchSeq = @seq
IF @DebugFlag=1 PRINT 'bspPRTBPost A1: Select SMBC link. smbcid='+CONVERT(varchar, @smbcid)+' SMWOrkCompletedID='+CONVERT(varchar, @smworkcompletedid)
   			
   			if NOT(@smworkcompletedid IS NULL)
   			BEGIN
   				BEGIN TRY
IF @DebugFlag=1 PRINT 'bspPRTBPost A2: Update SMBC link'
   					UPDATE vSMBC Set UpdateInProgress=1 WHERE SMWorkCompletedID= @smworkcompletedid

					-- Get PostDate from the PRTB record
					SELECT @PostDate = PostDate FROM dbo.bPRTB WITH (NOLOCK)
    					WHERE Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq 					
    					
   					-- Update SMWorkCompletedLabor with the info to link to PRTH
IF @DebugFlag=1 PRINT 'bspPRTBPost A3: Update vSMWorkCompletedLabor'
    				UPDATE vSMWorkCompletedLabor SET PRCo=@co, PRGroup=@prgroup, PREndDate=@prenddate, PREmployee=@employee,
    					PRPaySeq=@payseq, PRPostSeq=@postseq, PRPostDate=@PostDate
    					WHERE SMWorkCompletedID=@smworkcompletedid
IF @DebugFlag=1 PRINT 'bspPRTBPost A4: Update vSMWorkCompleted'
    				UPDATE vSMWorkCompleted SET CostCo=@co, PRGroup=@prgroup, PREndDate=@prenddate, PREmployee=@employee,
    					PRPaySeq=@payseq, PRPostSeq=@postseq, PRPostDate=@PostDate
    					WHERE SMWorkCompletedID=@smworkcompletedid
    				
				END TRY
				BEGIN CATCH
		    		select @errmsg = @errorstart + 'Error updating SMWorkCompleted: '+ERROR_MESSAGE()
    				goto pr_posting_error
				END CATCH
    		END
			-- 131640 End
			
		--Issue 133439/127603   
--   	--issue 18616 4/12/04
-- 		if @guid is not null --issue 122181 added 'if' clause
-- 			begin
-- 			update bHQAT
-- 			set TableName = 'PRTH'
-- 			where UniqueAttchID = @guid
-- 			end
    
         	-- update PostSeq in bPRTB batch table for BatchUserMemoUpdate
IF @DebugFlag=1 PRINT 'bspPRTBPost 1: Update PRTB post seq'
         	update dbo.bPRTB set PostSeq = @postseq
         	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    		if @@rowcount = 0
    			begin
    			select @errmsg = @errorstart + ' - Unable to update Timecard Batch entry!'
    			goto pr_posting_error
    			end
    		end

			/* Delete the SMBC link - The link cannot be deleted before the PRTB is updated or a new
				SMWorkCompleted record will be created. */
			IF NOT(@smbcid IS NULL)
			BEGIN
IF @DebugFlag=1 PRINT 'bspPRTBPost 2: Delete SMBC link'
				DELETE FROM vSMBC WHERE SMBCID=@smbcid
			END
			
    	if @transtype = 'C'     -- update existing PR Timecard
          	begin
          	update dbo.bPRTH
           	set Type = b.Type, JCCo = b.JCCo, Job = b.Job, PhaseGroup = b.PhaseGroup, Phase = b.Phase, GLCo = b.GLCo,
                 EMCo = b.EMCo, WO = b.WO, WOItem = b.WOItem, Equipment = b.Equipment, EMGroup = b.EMGroup,
                 CostCode = b.CostCode, CompType = b.CompType, Component = b.Component, RevCode = b.RevCode,
                 EquipCType = b.EquipCType, UsageUnits = b.UsageUnits, TaxState = b.TaxState, LocalCode = b.LocalCode,
                 UnempState = b.UnempState, InsState = b.InsState, InsCode = b.InsCode, PRDept = b.PRDept, Crew = b.Crew,
                 Cert = b.Cert, Craft = b.Craft, Class = b.Class, EarnCode = b.EarnCode, Shift = b.Shift, Hours = b.Hours,
                 Rate = b.Rate, Amt= b.Amt, BatchId = @batchid, JCDept = @jcdept, PostDate = b.PostDate, Memo = b.Memo,
    			 UniqueAttchID = b.UniqueAttchID, --issue 24213
    			 EquipPhase = b.EquipPhase, --issue 14181
    			 SMCo = b.SMCo, SMWorkOrder = b.SMWorkOrder, SMScope = b.SMScope, SMPayType = b.SMPayType, SMCostType = b.SMCostType,
    			 SMJCCostType = b.SMJCCostType,
    			 PRTBKeyID = b.KeyID
    		from bPRTH t
    		join bPRTB b on t.PRCo = b.Co and t.Employee = b.Employee and t.PaySeq = b.PaySeq and t.PostSeq = b.PostSeq
           	where t.PRCo = @co and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.PaySeq = @payseq
                and t.PostSeq = @postseq and t.Employee = @employee and b.Mth = @mth and b.BatchId = @batchid
    			and b.BatchSeq = @seq
           	if @@rowcount <> 1
    			begin
    			select @errmsg = @errorstart + ' - Unable to update existing Timecard!'
    			goto pr_posting_error
    			end
   
			--Issue 131640 Begin
    		-- Changes and Deletes are not handled in PRTB so they must be now.
    		-- Need to update the SMWorkCompleted record
    		IF @linetype='S' OR @oldlinetype='S'
   			BEGIN
				SELECT @SMCo=SMCo, @SMWorkOrder=SMWorkOrder, @SMScope=SMScope, @SMPayType=SMPayType, @SMCostType=SMCostType,
					@oldSMCo=OldSMCo, @oldSMWorkOrder=OldSMWorkOrder, @oldSMScope=OldSMScope, @oldSMPayType=OldSMPayType, @oldSMCostType=OldSMCostType,
					@oldHours=OldHours, @oldEmployee=OldEmployee, @oldlinetype=OldType, @hours=Hours, @amt=Amt, @oldAmt=OldAmt,
					@PostDate=PostDate, @oldPaySeq=OldPaySeq, @oldPostSeq=OldPostSeq, @Craft=Craft, @Class=Class, @Shift=Shift,
					@oldCraft=OldCraft, @oldClass=OldClass, @oldShift=OldShift, @SMJCCostType = SMJCCostType, @PhaseGroup = PhaseGroup,
					@OldSMJCCostType = OldSMJCCostType
				FROM dbo.bPRTB
         		WHERE Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
         		
				select @smworkcompletedid=C.SMWorkCompletedID, @Technician=D.Technician, @WorkCompleted=C.WorkCompleted
				from vSMWorkCompleted C
				INNER JOIN vSMWorkCompletedDetail D ON D.SMWorkCompletedID = C.SMWorkCompletedID
				where C.CostCo=@co AND C.PRGroup=@prgroup AND C.PREndDate=@prenddate AND C.PREmployee=@employee AND C.PRPaySeq=@oldPaySeq AND C.PRPostSeq=@oldPostSeq

IF @DebugFlag=1 PRINT 'bspPRTBPost C1: SMWorkCompletedID = '+CONVERT(varchar, @smworkcompletedid)
         		/* Check to see if anything has changed that affects SM */
         		IF (dbo.vfIsEqual(@linetype,@oldlinetype)&dbo.vfIsEqual(@SMCo,@oldSMCo)&dbo.vfIsEqual(@SMWorkOrder,@oldSMWorkOrder)&dbo.vfIsEqual(@SMScope,@oldSMScope)&dbo.vfIsEqual(@amt,@oldAmt)&
         			dbo.vfIsEqual(@employee,@oldEmployee)&dbo.vfIsEqual(@SMPayType,@oldSMPayType)&dbo.vfIsEqual(@SMCostType,@oldSMCostType)&dbo.vfIsEqual(@hours,@oldHours)&dbo.vfIsEqual(@Craft,@oldCraft)&
         			dbo.vfIsEqual(@Class,@oldClass)&dbo.vfIsEqual(@Shift,@oldShift)&dbo.vfIsEqual(@SMJCCostType,@OldSMJCCostType)=0)

				BEGIN
IF @DebugFlag=1 PRINT 'bspPRTBPost C1.1: LineType='+@linetype+'  OldLineType='+@oldlinetype
IF @DebugFlag=1 PRINT 'bspPRTBPost C1.1: Hours='+CONVERT(varchar,@hours)+'  OldHours='+CONVERT(varchar,@oldHours)
IF @DebugFlag=1 PRINT 'bspPRTBPost C1.1: SMCo='+CONVERT(varchar,@SMCo)+' OldSMCo='+Convert(varchar,@oldSMCo)
IF @DebugFlag=1 PRINT 'bspPRTBPost C1.1: SMWorkOrder='+CONVERT(varchar,@SMWorkOrder)+' OldSMWorkOrder='+CONVERT(varchar,@oldSMWorkOrder)
					/* Check to see if a new SMWorkCompleted record will need to be added */
					IF (@linetype='S' AND @oldlinetype<>'S')
					BEGIN
IF @DebugFlag=1 PRINT 'bspPRTBPost C2: Insert SMBC link'
						SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @SMWorkOrder)

						-- A link record needs to be created so a MyTimesheet record won't be created.
						INSERT vSMBC (PostingCo, SMCo, WorkOrder, LineType, [Source], WorkCompleted, SMWorkCompletedID, UpdateInProgress, InUseMth, InUseBatchId, InUseBatchSeq)
							VALUES (@co, @SMCo, @SMWorkOrder, 2, 'PRTimecard', @WorkCompleted, @smworkcompletedid, 1, @mth, @batchid, @seq)
								
						-- Add a SMWorkCompleted record
IF @DebugFlag=1 PRINT 'bspPRTBPost C3: Call vspSMWorkCompletedLaborCreate'
						exec @rcode = vspSMWorkCompletedLaborCreate @SMCo=@SMCo, @WorkOrder=@SMWorkOrder, @WorkCompleted = @WorkCompleted,
							@Scope=@SMScope, @PayType=@SMPayType, @SMCostType=@SMCostType, 
							@SMJCCostType=@SMJCCostType, @SMPhaseGroup=@PhaseGroup,
							@Technician=@Technician, @Date=@PostDate, @Hours=@hours, 
							@TCPRCo=@co, @TCPRGroup=@prgroup, @TCPREndDate=@prenddate, @TCPREmployee=@employee,
							@TCPRPaySeq=@payseq, @TCPRPostSeq=@postseq, @TCPRPostDate=@PostDate, 
							@Craft=@Craft, @Class=@Class, @Shift=@Shift, @SMWorkCompletedID = @smworkcompletedid OUTPUT, @msg=@errmsg OUTPUT

						-- Now the link should be deleted.
IF @DebugFlag=1 PRINT 'bspPRTBPost C4: Delete SMBC link'
						DELETE vSMBC WHERE SMWorkCompletedID=@smworkcompletedid

						IF (NOT @rcode=0)
						BEGIN
    						select @errmsg = @errorstart + ' - Unable to create SM Work Completed: ' + @errmsg
    						goto pr_posting_error
						END
					END
					ELSE IF (@oldlinetype='S' AND @linetype='S' AND dbo.vfIsEqual(@SMCo,@oldSMCo)&dbo.vfIsEqual(@SMWorkOrder,@oldSMWorkOrder)&dbo.vfIsEqual(@SMScope,@oldSMScope)=0)
					BEGIN
						-- The existing Work Completed record needs to be deleted.
						-- Check to see if the SMWorkCompleted record has been billed.
						IF EXISTS
						(
							SELECT 1
							FROM dbo.vSMWorkCompleted
								INNER JOIN dbo.vSMInvoiceDetail ON vSMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
							WHERE vSMWorkCompleted.SMWorkCompletedID = @smworkcompletedid
						)
							SET @IsBilled = 1
						ELSE
							SET @IsBilled = 0
IF @DebugFlag=1 PRINT 'bspPRTBPost C8: IsBilled='+CONVERT(varchar, @IsBilled)
												
						-- A link record needs to be created so a MyTimesheet record won't be created.
IF @DebugFlag=1 PRINT 'bspPRTBPost C9: Insert SMBC link'
						INSERT vSMBC (PostingCo, SMCo, WorkOrder, LineType, [Source], WorkCompleted, SMWorkCompletedID, UpdateInProgress, InUseMth, InUseBatchId, InUseBatchSeq)
							VALUES (@co, @oldSMCo, @oldSMWorkOrder, 2, 'PRTimecard', @WorkCompleted, @smworkcompletedid, 1, @mth, @batchid, @seq)
								
						-- The posting information must be removed from the vSMWorkCompletedLabor record before the record can be deleted or changed.
IF @DebugFlag=1 PRINT 'bspPRTBPost C10: Update SMWorkCompleted Posting Info'
						UPDATE vSMWorkCompletedLabor SET PRCo=NULL, PRGroup=NULL, PREndDate=NULL, PREmployee=NULL, PRPaySeq=NULL, PRPostSeq=NULL, PRPostDate=NULL WHERE SMWorkCompletedID=@smworkcompletedid
						UPDATE vSMWorkCompleted SET CostCo=NULL, PREndDate=NULL, PREmployee=NULL, PRPaySeq=NULL, PRPostSeq=NULL
							WHERE SMWorkCompletedID=@smworkcompletedid
							
						IF (@IsBilled = 1)
						BEGIN
							-- The SMWorkCompleted record has been billed so it cannot be deleted.  Just set the Cost values to zero.
IF @DebugFlag=1 PRINT 'bspPRTBPost C11: Update SMWorkCompleted Cost to zero'
							UPDATE vSMWorkCompletedLabor SET CostQuantity=0, ProjCost=0
								WHERE SMWorkCompletedID=@smworkcompletedid
								
						END
						ELSE
						BEGIN
							-- Delete the SMWorkCompleted record that is linked to the MyTimesheetDetail record.
IF @DebugFlag=1 PRINT 'bspPRTBPost C12: Delete SMWorkCompleted'
							DELETE SMWorkCompleted WHERE SMWorkCompletedID=@smworkcompletedid
						END
						-- Now the link should be deleted.
						DELETE vSMBC WHERE SMWorkCompletedID=@smworkcompletedid								
						
						-- Now insert the new Work Completed record.
						-- A link record needs to be created so a MyTimesheet record won't be created
						SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @SMWorkOrder)
							
IF @DebugFlag=1 PRINT 'bspPRTBPost C13: Insert vSMBC Link'
						INSERT vSMBC (PostingCo, SMCo, WorkOrder, LineType, [Source], WorkCompleted, SMWorkCompletedID, UpdateInProgress, InUseMth, InUseBatchId, InUseBatchSeq)
							VALUES (@co, @SMCo, @SMWorkOrder, 2, 'PRTimecard', @WorkCompleted, @smworkcompletedid, 1, @mth, @batchid, @seq)
							
IF @DebugFlag=1 PRINT 'bspPRTBPost C14: Call vspSMWorkCompletedLaborCreate'
						exec @rcode = vspSMWorkCompletedLaborCreate @SMCo=@SMCo, @WorkOrder=@SMWorkOrder, @WorkCompleted = @WorkCompleted,
							@Scope=@SMScope, @PayType=@SMPayType, @SMCostType=@SMCostType, 
							@SMJCCostType=@SMJCCostType, @SMPhaseGroup=@PhaseGroup,
							@Technician=@Technician, @Date=@PostDate, @Hours=@hours, 
							@TCPRCo=@co, @TCPRGroup=@prgroup, @TCPREndDate=@prenddate, @TCPREmployee=@employee,
							@TCPRPaySeq=@payseq, @TCPRPostSeq=@postseq, @TCPRPostDate=@PostDate,
							@Craft=@Craft, @Class=@Class, @Shift=@Shift,
							@SMWorkCompletedID=@newsmworkcompletedid OUTPUT, @msg=@errmsg OUTPUT
						
						IF (NOT @rcode=0)
						BEGIN
							select @errmsg = @errorstart + ' - Unable to create SM Work Completed: ' + @errmsg
							goto pr_posting_error
						END
						
						-- Now the link should be deleted.
IF @DebugFlag=1 PRINT 'bspPRTBPost C15: Delete SMBC link'
						DELETE vSMBC WHERE SMWorkCompletedID=@smworkcompletedid
					END
					ELSE IF (@oldlinetype='S' AND @linetype='S' AND (dbo.vfIsEqual(@hours,@oldHours)&dbo.vfIsEqual(@SMPayType,@oldSMPayType)&dbo.vfIsEqual(@SMCostType,@oldSMCostType)&dbo.vfIsEqual(@Craft,@oldCraft)&
         				dbo.vfIsEqual(@Class,@oldClass)&dbo.vfIsEqual(@Shift,@oldShift)&dbo.vfIsEqual(@SMJCCostType,@OldSMJCCostType)=0) AND dbo.vfIsEqual(@SMCo,@oldSMCo)&dbo.vfIsEqual(@SMWorkOrder,@oldSMWorkOrder)&dbo.vfIsEqual(@SMScope,@oldSMScope)=1)
					BEGIN
						-- A link record needs to be created so a MyTimesheet record won't be created.
IF @DebugFlag=1 PRINT 'bspPRTBPost C5: Create SMBC link'
						INSERT vSMBC (PostingCo, SMCo, WorkOrder, LineType, [Source], WorkCompleted, SMWorkCompletedID, UpdateInProgress, InUseMth, InUseBatchId, InUseBatchSeq)
							VALUES (@co, @oldSMCo, @oldSMWorkOrder, 2, 'PRTimecard', @WorkCompleted, @smworkcompletedid, 1, @mth, @batchid, @seq)
						
						-- Update SMWorkCompleted with the new information for SMCo, Workorder, Technician and hours.
IF @DebugFlag=1 PRINT 'bspPRTBPost C6: Call vspSMWorkCompletedLaborUpdate'
						exec @rcode = vspSMWorkCompletedLaborUpdate @SMCo=@SMCo, @WorkOrder=@SMWorkOrder, @Scope=@SMScope, @PayType=@SMPayType, @SMCostType=@SMCostType,
							@Technician=@Technician, @Date=@PostDate, @Hours=@hours, @SMWorkCompletedID=@smworkcompletedid, 
							@TCPRCo=@co, @TCPRGroup=@prgroup, @TCPREndDate=@prenddate, @TCPREmployee=@employee,
							@TCPRPaySeq=@payseq, @TCPRPostSeq=@postseq, @TCPRPostDate=@PostDate, 
							@Craft=@Craft, @Class=@Class, @Shift=@Shift, @SMJCCostType=@SMJCCostType, @SMPhaseGroup=@PhaseGroup, 
							@msg=@errmsg OUTPUT
						
						IF (NOT @rcode=0)
						BEGIN
    						select @errmsg = @errorstart + ' - Unable to update SM Work Completed: ' + @errmsg
    						goto pr_posting_error
						END
						
						-- Now the link should be delted.
IF @DebugFlag=1 PRINT 'bspPRTBPost C7: Delete SMBC link'
						DELETE vSMBC WHERE SMWorkCompletedID=@smworkcompletedid						
					END
					ELSE IF (@oldlinetype='S' AND @linetype<>'S')
					BEGIN	
						-- Check to see if the SMWorkCompleted record has been billed.
						IF EXISTS
						(
							SELECT 1
							FROM dbo.vSMWorkCompleted
								INNER JOIN dbo.vSMInvoiceDetail ON vSMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
							WHERE vSMWorkCompleted.SMWorkCompletedID = @smworkcompletedid
						)
							SET @IsBilled = 1
						ELSE
							SET @IsBilled = 0
						-- A link record needs to be created so a MyTimesheet record won't be created.
IF @DebugFlag=1 PRINT 'bspPRTBPost C16: Create SMBC link'
						INSERT vSMBC (PostingCo, SMCo, WorkOrder, LineType, [Source], WorkCompleted, SMWorkCompletedID, UpdateInProgress, InUseMth, InUseBatchId, InUseBatchSeq)
							VALUES (@co, @oldSMCo, @oldSMWorkOrder, 2, 'PRTimecard', @WorkCompleted, @smworkcompletedid, 1, @mth, @batchid, @seq)
						
						IF (@IsBilled=1)
						BEGIN	
IF @DebugFlag=1 PRINT 'bspPRTBPost C17: Call vspSMWorkCompletedLaborUpdate'
							-- Update SMWorkCompleted with the new information for SMCo, Workorder, Technician and hours.
							exec @rcode = vspSMWorkCompletedLaborUpdate @SMCo=@oldSMCo, @WorkOrder=@oldSMWorkOrder, @Scope=@oldSMScope, @PayType=@oldSMPayType, @SMCostType=@oldSMCostType,
								@Technician=@Technician, @Date=@PostDate, @Hours=@hours, @SMWorkCompletedID=@smworkcompletedid,
								@TCPRCo=@co, @TCPRGroup=@prgroup, @TCPREndDate=NULL, @TCPREmployee=NULL,
								@TCPRPaySeq=NULL, @TCPRPostSeq=NULL, @TCPRPostDate=NULL, 
								@Craft=@Craft, @Class=@Class, @Shift=@Shift, @SMJCCostType=@SMJCCostType, @SMPhaseGroup=@PhaseGroup, 
								@msg=@errmsg OUTPUT
							
							IF (NOT @rcode=0)
							BEGIN
    							select @errmsg = @errorstart + ' - Unable to update SM Work Completed: ' + @errmsg
    							goto pr_posting_error
							END
						END
						ELSE
						BEGIN
							-- The Payroll posted enddate must be removed before the record can be deleted.
							UPDATE vSMWorkCompletedLabor SET PRCo=NULL, PRGroup=NULL, PREndDate=NULL, PREmployee=NULL, PRPaySeq=NULL, PRPostSeq=NULL, PRPostDate=NULL WHERE SMWorkCompletedID=@smworkcompletedid
IF @DebugFlag=1 PRINT 'bspPRTBPost C18: Delete SMWorkCompleted'
							DELETE SMWorkCompleted WHERE SMWorkCompletedID=@smworkcompletedid
						END
						
						-- Now the link should be delted.
IF @DebugFlag=1 PRINT 'bspPRTBPost C19: Delete SMBC link'
						DELETE vSMBC WHERE SMWorkCompletedID=@smworkcompletedid
					END
				END --IF NOT(@linetype=@oldlinetype AND 
			END --IF @linetype='S' OR @oldlinetype='S'
			--Issue 131640 End
			
			--Issue 133439/127603
--   		--issue 18616 4/12/04
-- 		if @guid is not null --issue 122181 added 'if' clause
-- 		  begin
--   	      update bHQAT
--   	      set TableName = 'PRTH'
--   	      where UniqueAttchID = @guid
-- 		  end
   
    		end
    
    	if @transtype = 'D'      -- delete existing PR Timecard and related detail
        begin
            -- remove Addons
     	    delete dbo.bPRTA
     	    where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and
                 PaySeq = @payseq and PostSeq = @postseq
     	    -- remove Liabilities
     	    delete dbo.bPRTL
     	    where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and
     		    PaySeq = @payseq and PostSeq = @postseq
             -- remove PR Timecard
    
    		-- issue 13689 - must remove in use flag so delete trigger will work
      		update dbo.bPRTH
      		set InUseBatchId = null
     	    where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and
     	        PaySeq = @payseq and PostSeq = @postseq
    
      	    delete from dbo.bPRTH
     	    where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and
     	        PaySeq = @payseq and PostSeq = @postseq
    		if @@rowcount <> 1
    		begin
    			select @errmsg = @errorstart + ' - Unable to remove Timecard!'
    			goto pr_posting_error
    		end

    		-- 131640 Begin
    		-- Changes and Deletes are not handled in PRTB so they must be now.
    		-- Need to update the SMWorkCompleted record
    		IF EXISTS(SELECT 1 FROM vSMWorkCompletedLabor
   							WHERE PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate and PREmployee = @employee and
     							PRPaySeq = @payseq and PRPostSeq = @postseq)
   			BEGIN
IF @DebugFlag=1 PRINT 'bspPRTBPost D1'
				SELECT @SMCo=SMCo, @SMWorkOrder=SMWorkOrder, @SMScope=SMScope, @SMPayType=SMPayType, @SMCostType=SMCostType,
					@oldSMCo=OldSMCo, @oldSMWorkOrder=OldSMWorkOrder, @oldSMScope=OldSMScope, @oldSMPayType=OldSMPayType, @oldSMCostType=OldSMCostType,
					@oldHours=OldHours, @oldEmployee=OldEmployee, @oldlinetype=OldType, @hours=Hours, @amt=Amt, @oldAmt=OldAmt,
					@PostDate=PostDate, @oldPaySeq=OldPaySeq, @oldPostSeq=OldPostSeq, @Craft=Craft, @Class=Class, @Shift=Shift,
					@oldCraft=OldCraft, @oldClass=OldClass, @oldShift=OldShift,
					@SMJCCostType=SMJCCostType, @PhaseGroup=@PhaseGroup, 
					@OldSMJCCostType=OldSMJCCostType, @OldPhaseGroup=OldPhaseGroup
				FROM dbo.bPRTB
         		WHERE Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

				SELECT @SMCo=SMCo, @smworkcompletedid=SMWorkCompletedID, @Technician=Technician,
					@WorkCompleted=WorkCompleted
				FROM SMWorkCompleted
				WHERE PRCo=@co AND PRGroup=@prgroup AND PREndDate=@prenddate AND PREmployee=@employee AND PRPaySeq=@oldPaySeq AND PRPostSeq=@oldPostSeq
IF @DebugFlag=1 PRINT 'bspPRTBPost D2: SMWorkCompletedID='+CONVERT(varchar, isnull(@smworkcompletedid,0))
IF @DebugFlag=1 PRINT ' PRGroup='+CONVERT(varchar, isnull(@prgroup,0))+'  PREndDate='+CONVERT(varchar, isnull(@prenddate,0), 101)+' PREmployee='+CONVERT(varchar, isnull(@employee,0))+' PRPaySeq='+CONVERT(varchar, @oldPaySeq)+' PRPostSeq='+CONVERT(varchar, @oldPostSeq)
	    		
				-- Check to see if the SMWorkCompleted record has been billed.
				IF EXISTS
				(
					SELECT 1
					FROM dbo.vSMWorkCompleted
						INNER JOIN dbo.vSMInvoiceDetail ON vSMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
					WHERE vSMWorkCompleted.SMWorkCompletedID = @smworkcompletedid
				)
					SET @IsBilled = 1
				ELSE
					SET @IsBilled = 0
IF @DebugFlag=1 PRINT 'bspPRTBPost D3: IsBilled='+CONVERT(varchar, @IsBilled)
				BEGIN TRY
					-- The SMWorkCompleted record has been billed so it cannot be deleted.  Just set the Cost values to zero.
					-- A link record must be created so a PRMyTimesheet record will not be created by the SMWorkCompleted Trigger
IF @DebugFlag=1 PRINT 'bspPRTBPost D4: Creating SMBC link'
					INSERT vSMBC (SMCo, PostingCo, WorkOrder, LineType, [Source], WorkCompleted, SMWorkCompletedID, UpdateInProgress, InUseMth, InUseBatchId, InUseBatchSeq)
					VALUES (@SMCo, @co, @SMWorkOrder, 2, 'PRTimecard', @WorkCompleted, @smworkcompletedid, 1, @mth, @batchid, @seq)
					
					-- Check to see if the SMWorkCompleted record has been billed.
					IF (@IsBilled = 1)
					BEGIN
IF @DebugFlag=1 PRINT 'bspPRTBPost D5: Updating SMWorkCompleted'
						-- Update the Work Completed record.						
						UPDATE vSMWorkCompletedLabor SET CostQuantity=0, ProjCost=0, PRCo=NULL, PRGroup=NULL, PREndDate=NULL, PREmployee=NULL, PRPaySeq=NULL, PRPostSeq=NULL, PRPostDate=NULL
							WHERE SMWorkCompletedID = @smworkcompletedid
						UPDATE vSMWorkCompleted SET CostCo=NULL, PRGroup=NULL, PREndDate=NULL, PREmployee=NULL, PRPaySeq=NULL, PRPostSeq=NULL, PRPostDate=NULL
							WHERE SMWorkCompletedID = @smworkcompletedid

						-- Delete the LINK record
IF @DebugFlag=1 PRINT 'bspPRTBPost D6: Delete SMBC link'
						DELETE vSMBC
							WHERE SMWorkCompletedID = @smworkcompletedid
					END
					ELSE
					BEGIN
IF @DebugFlag=1 PRINT 'bspPRTBPost D7: UPDATE SMWorkCompleted SET PREndDate=NULL'
						-- The Payroll Enddate must be cleared before the record can be delted.
						UPDATE vSMWorkCompletedLabor SET PRCo=NULL, PRGroup=NULL, PREndDate=NULL, PREmployee=NULL, PRPaySeq=NULL, PRPostSeq=NULL, PRPostDate=NULL WHERE SMWorkCompletedID = @smworkcompletedid
						UPDATE vSMWorkCompleted SET CostCo=NULL, PRGroup=NULL, PREndDate=NULL, PREmployee=NULL, PRPaySeq=NULL, PRPostSeq=NULL, PRPostDate=NULL WHERE SMWorkCompletedID = @smworkcompletedid		
					
						-- Delete the LINK record
IF @DebugFlag=1 PRINT 'bspPRTBPost D8: Delete SMBC link'
						DELETE vSMBC
							WHERE SMWorkCompletedID = @smworkcompletedid

IF @DebugFlag=1 PRINT 'bspPRTBPost D9: Delete SMWorkCompleted'
						-- Delete the SMWorkCompleted record that is linked to the MyTimesheetDetail record.
						
						--Update IsDeleted to true so that it no longer shows
						UPDATE dbo.vSMWorkCompleted
						SET IsDeleted = 1, CostsCaptured = 0
						WHERE SMWorkCompletedID = @smworkcompletedid

						--If ledger update was run against the work completed at some point then it should be deleted through ledger update
						DELETE dbo.vSMWorkCompleted WHERE SMWorkCompletedID = @smworkcompletedid AND PRLedgerUpdateMonthID IS NULL
					END
				END TRY
				BEGIN CATCH
		    		select @errmsg = @errorstart + 'Error deleting SMWorkCompleted. SQL Error=' + ERROR_MESSAGE()
    				goto pr_posting_error
				END CATCH
			END -- IF EXISTS
    		-- 131640 END
			
			--Issue 133439/127603    
--    		-- issue 24213 remove Attachments
--    		if @guid is not null delete bHQAT where UniqueAttchID = @guid --issue 122181 added 'if' clause
    
     	end --if @transtype = 'D'
    
    	-- update user memos in bPRTH before deleting the batch record */
        if @transtype in ('A','C')
        	begin
	-- -- -- copy user memos if any
   		if @prtbud_flag = 'Y'
   			begin
        		exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'PR TimeCards', @errmsg output
        			if @rcode <> 0	goto pr_posting_error
			end
   
   	
   		--TV 04/14/04 23255 - Update EMEM Job, JobDate and DateLastUsed when Job Type
   		select @emco = EMCo, @equip = Equipment, @jobdate = PostDate
   		from bPRTB
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and Type = 'J'
   		if isnull(@emco,'') <> ''and isnull(@equip,'') <> ''and isnull(@jobdate,'') <> ''
   			begin			
   			exec @rcode =  bspEMEMJobLocDateUpdate @emco, @equip, @jcco, @job, @jobdate, @jobdate, @errmsg output
   			if @rcode <> 0 	goto pr_posting_error
   			end 
   
        	end
    
    	-- delete Timecard Batch entry
        delete dbo.bPRTB
        where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	if @@rowcount = 0
    		begin
    		select @errmsg = @errorstart + ' - Unable to remove Timecard Batch entry!'
    		goto pr_posting_error
    		end
    
    	commit transaction
    
    	-- issue 18616 Refresh indexes for this header if attachments exist
    	if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
    
        goto pr_posting_loop    -- next Timecard batch entry
    
    pr_posting_error:		-- error occured within transaction - rollback any updates
    	rollback transaction
    	select @rcode = 1
    	goto bspexit
    
    pr_posting_end:     -- finished with batch entries
    -- set interface levels note string
        select @Notes=Notes from dbo.bHQBC with (nolock)
        where Co = @co and Mth = @mth and BatchId = @batchid
        if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
        select @Notes=@Notes +
            'EM Cost Employee Interface set at: ' + convert(char(1), a.EMCostEmployee) + char(13) + char(10) +
            'EM Interface set at: ' + convert(char(1), a.EMInterface) + char(13) + char(10) +
            'GL Interface set at: ' + convert(char(1), a.GLInterface) + char(13) + char(10) +
            'JC Interface set at: ' + convert(char(1), a.JCInterface) + char(13) + char(10)
        from dbo.bPRCO a with (nolock) where PRCo=@co
         -- remove HQ Close Control entries
         delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    
         -- set HQ Batch status to 5 (posted)
    	update dbo.bHQBC
        set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
     	where Co = @co and Mth = @mth and BatchId = @batchid
     	if @@rowcount = 0
     		begin
     		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     		goto bspexit
     		end
    
    bspexit:
    	if @opencursor = 1
     		begin
     		close bcPRTB
     		deallocate bcPRTB
     		end
    
    	--if @rcode = 1 select @errmsg = @errmsg + char(13) + char(13) + '[bspPRTBPost]'
     	return @rcode

GO

GRANT EXECUTE ON  [dbo].[bspPRTBPost] TO [public]
GO
