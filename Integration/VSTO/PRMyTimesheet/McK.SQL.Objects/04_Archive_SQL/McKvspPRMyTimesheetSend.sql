USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='McKvspPRMyTimesheetSend' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.McKvspPRMyTimesheetSend'
	DROP PROCEDURE dbo.McKvspPRMyTimesheetSend
End
GO

Print 'CREATE PROCEDURE dbo.McKvspPRMyTimesheetSend'
GO


 CREATE PROCEDURE [dbo].[McKvspPRMyTimesheetSend]
   /***********************************************************

	Purpose:			Used by the 'McK PR MyTimesheet Excel VSTO' to batch Pay Sequence sets into separate batches for payroll to:
						1.) print checks to employee's location (PREH.udPaySequence is the geographic locations where checks will be printed to)
						2.) distribute work via batches
	Modified:		8.8.2018
	Created:			8.8.2018
	Modified By:	Leo Gurdian
	
	09.06.2018	LG - Added PaySeq in returned results
	08.08.2018	LG - Slightly modified vspPRMyTimesheetSend; line 129

    * CREATED BY: JH/EN 8/27/09
    * MODIFIED By :  MH 11/19/09 -  Assumption in SP was all time was being posted to a job.  Was only
	*			getting the Job's GLCo.  On Non-Job time entries we need to be getting GLCo from either
	*			PREH or PRCO. 
	*			TJL 03/01/10 - Issue #135490, Add Office TaxState & Office LocalCode to PR Employee Master
	*			MH  02/17/11 - 131640 - Modified to update PRTB with SM data.
	*           ECV 06/27/11 - AT-03279 - Added Scope to update of SMBC record.
	*           ECV 08/23/11 - TK-07782 - Added SMCostType.
    *		    TRL 02/04/12 - TK-12277 Added SMJCCostType/SMPhaseGroup
    *			ECV 06/07/12 TK-14637 removed SMPhaseGroup. Use PhaseGroup instead.
	*			JVH 3/29/13  - TFS-44846 - Updated to handle deriving sm gl accounts
	*			EricV 12/19/13 TFS-67909 Default InsCode from SM Work Order Scope
	*           JayR 03/04/15 TFS-133148 Adding a forceseek to help with deadlock    
	*			EricV 10/09/15 TFS-131717 Use CraftTemplate on Work Order to determine rates for SM type lines.
	*			EN 02/15/2016	TFS-71910 resolve issues with how timecard insurance code is determined
	*			JP 09/30/2016	TFS-332713 Modified cursor declaration adding local fast_forward
	*			EN 11/18/2016	TFS Feature 339442 / User Story 339444 - updated input params for call to bspIMPRTB_INSCODE and resolved issue with sending wrong insurance state in the call
	*			AW 06/27/2017	TFS 364158 Fix the Inscode default to use insurance template instead of craft template.
	*			AW 07/12/2017   TFS 364366 don't hard error on an invalid Ins State/Code validation.
	*			ECV 12/07/17 VSTS-47388 Add StandardItem parameter to call to vfSMGetAccountingTreatment
	*
    * USAGE:
    * Called by frmPRTimesheetSend to transfer the personal timesheets into a payroll batch.
    *
    * INPUT PARAMETERS
    *   @prco		PR Co to posted to 
    *   @prgroup	PR Group of batch
	*	@throughdate	
    * OUTPUT PARAMETERS
	*	@raceinpreh	equals Y if there are any entries in PREH containing this race code
    *   @msg      error message if error occurs otherwise Description of Race
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
	(@prco bCompany, @prgroup bGroup, @throughdate bDate, @enddate bDate, @payseq smallint, @prrestrict bYN, 
	 @msg varchar(1000) OUTPUT)
as

--Issue #135490, remove PRCo, Job, Employ variables related to State & LocalCodes & flags
    declare @rcode int, @batchmonth bMonth, @source bSource, @tablename varchar(20), @adjust bYN,
      	@batchid bBatchID, @headercursor tinyint, @detailcursor tinyint, @seq smallint, @crew varchar(10),
      	@postdate bDate, @sheet smallint, @entryemployee bEmployee, @employee bEmployee, @craft bCraft,
      	@class bClass, @jcco bCompany, @job bJob, @shift tinyint, @phasegroup bGroup, @phase bPhase,
      	@inscode bInsCode, @prdept bDept, @cert bYN, @batchseq int, 
      	@earncode bEDLCode, @useempins char(1), @hournum tinyint, @hours bHrs,
      	@craftTemplate smallint, @insTemplate smallint, @rate bUnitCost, @begindate bDate, @daynum smallint,
     	@day1hrs bHrs, @day2hrs bHrs, @day3hrs bHrs, @day4hrs bHrs, @day5hrs bHrs, @day6hrs bHrs, @day7hrs bHrs,
		@amt bDollar, @beginmth bMonth, @postday smallint, @insbyphase bYN, 
   		@posttaxstate varchar(4), @postunempstate varchar(4), 
   		@postinsstate varchar(4), @postlocalcode bLocalCode, 
   		@jobtaxstate varchar(4), @glco bCompany,
   		@validphasechars int, @pphase bPhase, @startdate bDate, @errmsg varchar(255), @linetype char(1),
   		@SMWorkCompletedID bigint, @WorkCompleted int, @SMCo bCompany, @WorkOrder int, @Scope int, @PayType varchar(10),
		@SMCostType smallint, @SMJCCostType bJCCType, @sminscode bInsCode, @prem_useins bYN

	select @rcode = 0, @msg = ''

  	-- read company regular/overtime/doubletime earnings codes and tax state info
  	--Issue #135490, remove PRCo values related to State & LocalCodes & flags
 	select @insbyphase=InsByPhase
 	from dbo.PRCO with (nolock) where PRCo=@prco
	if @@rowcount = 0
		begin
		select @errmsg = 'Missing PR Company entry!', @rcode = 1
		goto bspexit
		end
	
	-- get PR Pay Period data
	select @begindate=BeginDate, @beginmth=BeginMth
	from dbo.PRPC with (nolock)
	where PRCo=@prco and PRGroup=@prgroup and PREndDate=@enddate
	if @@rowcount=0
		begin
		select @msg = 'Missing pay period!', @rcode = 1
		goto bspexit
		end

	-- set batch month equal to beginning month for pay period
	select @batchmonth = @beginmth
    
	-- Create PRTB batch
	select @adjust = 'N'

	-- create PR batch
	select @source = 'PR Entry', @tablename = 'PRTB'
    
	exec @batchid = bspHQBCInsert @prco, @batchmonth, @source, @tablename, @prrestrict, @adjust, @prgroup, @enddate, @errmsg
	
	if @batchid = 0  
		begin
		select @msg = 'Unable to create PR batch for PR Company' + convert(varchar(3),@prco) + ': ' + isnull(@errmsg,''), @rcode = 1
		goto bspexit
		end

    -- Proceed with MyTimesheet transfer to batches

	-- loop through MyTimesheet header looking for specific PRCo and PRGroup, through a specific start date, and Status = "Ready to Send"
	DECLARE bcPRMyTimesheetHeader CURSOR LOCAL FAST_FORWARD FOR
	SELECT MyTS.EntryEmployee, MyTS.StartDate, MyTS.Sheet
	FROM PRMyTimesheet MyTS WITH (NOLOCK)
		INNER JOIN PREH WITH (NOLOCK) ON MyTS.PRCo = PREH.PRCo AND MyTS.EntryEmployee = PREH.Employee AND PREH.udPaySequence = @payseq 	/*** @payseq added *** to devide into separate batches  */
	WHERE MyTS.PRCo = @prco 
		--AND (MyTS.StartDate <= @throughdate OR @throughdate IS NULL)
		AND (MyTS.StartDate = @throughdate) --LEO corrected to only pull data for the specified start date, so it doesn't pull other open pay periods, though only 1 pay period should be open at time.
		AND (MyTS.Status = 2 OR MyTS.Status = 3)
		AND PREH.PRGroup = @prgroup

	OPEN bcPRMyTimesheetHeader
	SELECT @headercursor = 1
   
header_loop:
	FETCH NEXT FROM bcPRMyTimesheetHeader INTO @entryemployee, @startdate, @sheet

  	IF @@fetch_status<>0
		GOTO header_loop_end

	BEGIN TRANSACTION

    -- loop through MyTimesheet detail
	DECLARE bcPRMyTimesheetDetail CURSOR LOCAL FAST_FORWARD FOR
	SELECT PRMyTimesheetDetail.Seq, PRMyTimesheetDetail.Employee, PRMyTimesheetDetail.JCCo, PRMyTimesheetDetail.Job, PRMyTimesheetDetail.PhaseGroup, 
		PRMyTimesheetDetail.Phase, PRMyTimesheetDetail.EarnCode, PRMyTimesheetDetail.Craft, PRMyTimesheetDetail.Class, PRMyTimesheetDetail.Shift,
			DayOne, DayTwo, DayThree, DayFour, DayFive, DaySix, DaySeven, PRMyTimesheetDetail.SMCo, PRMyTimesheetDetail.WorkOrder, PRMyTimesheetDetail.Scope, PayType, 
			PRMyTimesheetDetail.SMCostType, PRMyTimesheetDetail.SMJCCostType, PRMyTimesheetDetail.LineType, vSMWorkOrderScope.InsCode
	FROM dbo.PRMyTimesheetDetail WITH (NOLOCK)
	LEFT JOIN dbo.vSMWorkOrderScope ON vSMWorkOrderScope.SMCo = PRMyTimesheetDetail.SMCo AND vSMWorkOrderScope.WorkOrder = PRMyTimesheetDetail.WorkOrder AND vSMWorkOrderScope.Scope = PRMyTimesheetDetail.Scope 
	WHERE PRCo = @prco and EntryEmployee = @entryemployee and StartDate = @startdate and Sheet = @sheet

	OPEN bcPRMyTimesheetDetail
	SELECT @detailcursor = 1
   
detail_loop:
	FETCH NEXT FROM bcPRMyTimesheetDetail INTO @seq, @employee, @jcco, @job, @phasegroup, @phase, @earncode, @craft, @class, @shift,
		@day1hrs, @day2hrs, @day3hrs, @day4hrs, @day5hrs, @day6hrs, @day7hrs, @SMCo, @WorkOrder, @Scope, @PayType, 
		@SMCostType, @SMJCCostType, @linetype, @sminscode

  	IF @@fetch_status<>0
		GOTO detail_loop_end

	--read employee PREH info
	--Issue #135490, remove Employee values related to State & LocalCodes & flags
	SELECT	 @prdept	= PRDept
			,@cert		= CertYN
			,@useempins	= UseIns
			,@crew		= Crew
			,@inscode	= InsCode
	FROM	dbo.PREH 
	WHERE	PRCo = @prco 
		AND Employee = @employee;

	IF @@rowcount = 0
	BEGIN --if employee not found, cancel sending the sheet
		SELECT @errmsg = 'Employee ' + isnull(convert(varchar,@employee),'NULL') + ' in PR Company ' + isnull(convert(varchar,@prco),'NULL') + ' does not exist!';
		GOTO detail_loop_error;
	END;

	--mh  If this is a non-job timecard there may not be a job company or job.  Look to PREH and then PRCO. GLCo is required
	--in PRCO but if for some reason it is null we have serious problems.
	IF @jcco IS NOT NULL AND @job IS NOT NULL
	BEGIN
		--get jc company's GLCO for posting job PR timecards or SM timecards for job related work orders
		SELECT @glco = GLCo
		FROM dbo.JCCO
		WHERE JCCo = @jcco
	END
	ELSE IF @linetype = 'S'
	BEGIN
		SELECT @glco = GLCo
		FROM dbo.vfSMGetAccountingTreatment(@SMCo, @WorkOrder, @Scope, 'L', @SMCostType, null)
	END
	ELSE
	BEGIN
		SET @glco = ISNULL((SELECT GLCo FROM dbo.PREH WHERE PRCo = @prco AND Employee = @employee), (SELECT GLCo FROM dbo.PRCO WHERE PRCo = @prco))
	END

	
	--mh  If this is a non-job timecard there may not be a job company or job.
	--Issue #135490, remove Job values related to State & LocalCodes & flags
	if (@jcco is not null and @job is not null)
		begin
			--read job's craft template for rate lookup plus job state and local
			select @craftTemplate=CraftTemplate, @insTemplate=InsTemplate
			from dbo.JCJM with (nolock) where JCCo=@jcco and Job=@job
			if @@rowcount=0 
			begin --if there is a problem, cancel sending the sheet
				select @errmsg = 'JC Company ' + isnull(convert(varchar,@jcco),'NULL') + ', Job ' + isnull(convert(varchar,@job),'NULL') + ' does not exist!'
				goto detail_loop_error
			end
		end
	else if (@WorkOrder is not null)
		begin
			select @craftTemplate=CraftTemplate
			from dbo.SMWorkOrder with (nolock) where SMCo=@SMCo and WorkOrder=@WorkOrder
			if @@rowcount=0 
			begin --if there is a problem, cancel sending the sheet
				select @errmsg = 'SM Company ' + isnull(convert(varchar,@SMCo),'NULL') + ', WorkOrder ' + isnull(convert(varchar,@WorkOrder),'NULL') + ' does not exist!'
				goto detail_loop_error
			end
		end
	
	--add entries to PR batch for each day with hours posted
	--spin through days
	select @daynum=1
	while @daynum<=7
		begin
		if @daynum = 1 select @hours = @day1hrs
		if @daynum = 2 select @hours = @day2hrs
		if @daynum = 3 select @hours = @day3hrs
		if @daynum = 4 select @hours = @day4hrs
		if @daynum = 5 select @hours = @day5hrs
		if @daynum = 6 select @hours = @day6hrs
		if @daynum = 7 select @hours = @day7hrs
		if isnull(@hours,0) <> 0
			begin
			--determine timecard date
			select @postdate = DATEADD(day, @daynum - 1, @startdate)

			--determine timecard day
			select @postday = DATEDIFF(day, @begindate, @postdate) + 1

			--get rate/amt
			exec @rcode = bspPRRateDefault @prco, @employee, @postdate, @craft, @class, @craftTemplate, 
				@shift, @earncode, @rate output, @errmsg output
			if @rcode <> 0 goto detail_loop_error
			select @amt = isnull(@rate,0) * @hours
	
			--Get State and Local defaults
			--Issue #135490, moved code to common procedure below which could be accessed by other procedures	
			IF @job IS NULL AND @linetype = 'S'
			BEGIN
				EXEC @rcode = vspPRGetCustomerStateLocalDflts	@prco, @employee, @SMCo, @WorkOrder, @postlocalcode output, @posttaxstate output,
																@postunempstate output, @postinsstate output, @errmsg output
					IF @rcode <> 0
					BEGIN
						GOTO detail_loop_error
					END
			END
			ELSE
			BEGIN	
				EXEC @rcode = vspPRGetStateLocalDflts	@prco, @employee, @jcco, @job, @postlocalcode output, @posttaxstate output,
														@postunempstate output, @postinsstate output, @errmsg output
				IF @rcode <> 0 
				BEGIN
					GOTO detail_loop_error
				END
			END

			-- determine insurance code
			IF @job IS NULL AND @linetype = 'S' AND @sminscode IS NOT NULL AND @useempins = 'N' AND @insbyphase = 'Y'
			BEGIN
				SET @inscode = @sminscode;
			END;

			-- determine insurance code depending on job/phase/insurance template/insurance rate threshold/employee override
			EXEC @rcode=dbo.bspIMPRTB_INSCODE	 @PRCo			= @prco
												,@Employee		= @employee
												,@JCCo			= @jcco
												,@Job			= @job
												,@Phase			= @phase
												,@PhaseGroup	= @phasegroup
												,@InsState		= @postinsstate
												,@Rate			= @rate
												,@EarnCode		= @earncode
												,@Craft			= @craft
												,@Class			= @class
												,@Template		= @insTemplate
												,@PostDate		= @postdate
												,@InsCode		= @inscode		OUTPUT
												,@msg			= @errmsg		OUTPUT;

			-- ingore @rcode here TFS 364366


			-- get next batch sequence #
			select @batchseq=isnull(max(BatchSeq),0)+1 from dbo.bPRTB with (nolock) where Co=@prco and Mth=@batchmonth and BatchId=@batchid
			if @@rowcount=0
				begin
				select @errmsg='Error getting next batch sequence #', @rcode=1
				goto detail_loop_error
				end

			IF @linetype = 'S'
			BEGIN
				-- Create link to SM Work Completed
				SELECT @SMWorkCompletedID = SMMyTimesheetLink.SMWorkCompletedID, @WorkCompleted = SMWorkCompleted.WorkCompleted
				FROM SMMyTimesheetLink
				INNER JOIN SMWorkCompleted ON SMWorkCompleted.SMWorkCompletedID = SMMyTimesheetLink.SMWorkCompletedID
				WHERE SMMyTimesheetLink.PRCo = @prco and SMMyTimesheetLink.EntryEmployee = @entryemployee
				and SMMyTimesheetLink.StartDate = @startdate and SMMyTimesheetLink.Sheet = @sheet AND SMMyTimesheetLink.Seq=@seq and SMMyTimesheetLink.DayNumber = @daynum

				IF @@rowcount = 0
				BEGIN
					SELECT @errmsg = 'Unable to add SMBC record. SMCo='+CONVERT(varchar,ISNULL(@SMCo,0))+' SMWorkCompletedID='+CONVERT(varchar, ISNULL(@SMWorkCompletedID,0)), @rcode = 1
					GOTO detail_loop_error				
				END
				BEGIN TRY
					INSERT SMBC (SMCo, PostingCo, WorkOrder, Scope, LineType, WorkCompleted, InUseMth, InUseBatchId, InUseBatchSeq, [Source], SMWorkCompletedID, UpdateInProgress)
					VALUES (@SMCo, @prco, @WorkOrder, @Scope, 2, @WorkCompleted, @batchmonth, @batchid, @batchseq, 'PRTimecard', @SMWorkCompletedID, 1)
				END TRY
				BEGIN CATCH
					SELECT @errmsg = 'Unable to add SMBC record. SMCo='+CONVERT(varchar,ISNULL(@SMCo,0))+' WorkOrder='+CONVERT(varchar, ISNULL(@WorkOrder,0))+' WorkCompleted='+CONVERT(varchar, ISNULL(@WorkCompleted,0))+'  SMWorkCompletedID='+CONVERT(varchar, ISNULL(@SMWorkCompletedID,0)), @rcode = 1
					GOTO detail_loop_error				
				END CATCH
			END		

			-- insert PR batch entry
			insert into dbo.bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, PostSeq, [Type],
				PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, Equipment, EMGroup, RevCode,
				EquipCType, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode, PRDept, 
				Crew, Cert, Craft, Class, EarnCode, Shift, Hours, Rate, Amt, DayNum, SMCo, SMWorkOrder, 
				SMScope, SMPayType, SMCostType,SMJCCostType)
			values (@prco, @batchmonth, @batchid, @batchseq, 'A', @employee, @payseq, null, @linetype,
				@postdate, @jcco, @job, @phasegroup, @phase, @glco, null, null, null, null, 
				null, null, @posttaxstate, @postlocalcode, @postunempstate, @postinsstate, @inscode, @prdept, 
				@crew, @cert, @craft, @class, @earncode, @shift, @hours, @rate, @amt, @postday, @SMCo, @WorkOrder, 
				@Scope, @PayType, @SMCostType,@SMJCCostType)
			
			if @@rowcount = 0
				begin
				select @errmsg = 'Unable to add PR batch entry for emp#' + isnull(convert(varchar(6),@employee),'NULL'), @rcode = 1
				goto detail_loop_error
				end

			IF @linetype = 'S'
			BEGIN
				-- Remove the UpdateInProgress flag from the link to SM Work Completed
				UPDATE SMBC 
				SET UpdateInProgress=0 
				FROM SMBC WITH (FORCESEEK)
				WHERE SMWorkCompletedID=@SMWorkCompletedID
			END
			end --if isnull(@hours,0)<>0
		select @hournum=@hournum+1
  		select @daynum=@daynum+1
		end --while @daynum<=7

	GOTO detail_loop
      
detail_loop_end:
  	CLOSE bcPRMyTimesheetDetail
  	DEALLOCATE bcPRMyTimesheetDetail
  	SELECT @detailcursor = 0

	-- update MyTimesheet batch mth, batch Id, and Status
	update dbo.bPRMyTimesheet
	set PRBatchMth = @batchmonth, PRBatchId = @batchid, Status = 4, ErrorMessage = null /*sent status*/
	where PRCo = @prco and EntryEmployee = @entryemployee and StartDate = @startdate and Sheet = @sheet

	COMMIT TRANSACTION

	-- get next header entry
  	GOTO header_loop
	
detail_loop_error:
  	CLOSE bcPRMyTimesheetDetail
  	DEALLOCATE bcPRMyTimesheetDetail
  	SELECT @detailcursor = 0

	ROLLBACK TRANSACTION

	-- set MyTimesheet Status to 3 (Send Error)
	update dbo.bPRMyTimesheet
	set Status = 3, ErrorMessage = @errmsg
	where PRCo = @prco and EntryEmployee = @entryemployee and StartDate = @startdate and Sheet = @sheet
	
	select @msg = 'Completed but with errors - not all timesheets were processed!' + char(10) + char(13) + @errmsg

  	GOTO header_loop -- continue with posting
     
header_loop_end:
  	CLOSE bcPRMyTimesheetHeader
  	DEALLOCATE bcPRMyTimesheetHeader
  	SELECT @headercursor = 0

	-- clear inuseby from PR batch
    exec @rcode = bspHQBCExitCheck @prco, @batchmonth, @batchid, @source, @tablename, @msg output

 
  bspexit:
  
	
  
  	if @headercursor=1
  		begin
  		close bcPRMyTimesheetHeader
  		deallocate bcPRMyTimesheetHeader
  		select @headercursor=0
  		end
  	if @detailcursor=1
  		begin
  		close bcPRMyTimesheetDetail
  		deallocate bcPRMyTimesheetDetail
  		select @detailcursor=0
  		end
  
  	if @rcode=0
  		begin
  		--prepare batch list to return
  		select @msg = @msg + 'Created Batch:' + char(10) + char(13)
		select @msg = @msg + 'PR Company: ' + convert(varchar(3),@prco)
		select @msg = @msg + '   Month: ' + convert(char(2),@batchmonth,1) + '/' + convert(char(2),@batchmonth,2)
		select @msg = @msg + '   Batch#: ' + convert(varchar(6),@batchid) + char(10) + char(13)
		select @msg = @msg + '   PaySeq: ' + convert(varchar(6),@payseq) + char(10) + char(13)
  		end
  
  	return @rcode

GO


Grant EXECUTE ON dbo.McKvspPRMyTimesheetSend TO [MCKINSTRY\Viewpoint Users]

GO
--exec dbo.McKvspPRMyTimesheetSend