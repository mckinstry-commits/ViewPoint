CREATE TABLE [dbo].[bPRMyTimesheetDetail]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[EntryEmployee] [dbo].[bEmployee] NOT NULL,
[StartDate] [dbo].[bDate] NOT NULL,
[Sheet] [smallint] NOT NULL,
[Seq] [smallint] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[EarnCode] [dbo].[bEDLCode] NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Shift] [tinyint] NULL,
[DayOne] [dbo].[bHrs] NULL,
[DayTwo] [dbo].[bHrs] NULL,
[DayThree] [dbo].[bHrs] NULL,
[DayFour] [dbo].[bHrs] NULL,
[DayFive] [dbo].[bHrs] NULL,
[DaySix] [dbo].[bHrs] NULL,
[DaySeven] [dbo].[bHrs] NULL,
[CreatedBy] [dbo].[bVPUserName] NOT NULL,
[CreatedOn] [smalldatetime] NOT NULL,
[Approved] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRMyTimesheetDetail_Approved] DEFAULT ('N'),
[ApprovedBy] [dbo].[bVPUserName] NULL,
[ApprovedOn] [smalldatetime] NULL,
[LineType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SMCo] [dbo].[bCompany] NULL,
[WorkOrder] [int] NULL,
[Scope] [int] NULL,
[PayType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SMCostType] [smallint] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[Memo] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 01/18/2011
-- Description:	
--                05/03/2011 EricV Added check for SM UsePRInterface flag
-- =============================================

CREATE TRIGGER [dbo].[btPRMyTimesheetDetaild] 
   ON  [dbo].[bPRMyTimesheetDetail] for DELETE as  
BEGIN

	/* Flag to print debug statements */
	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @SMWorkCompletedID int

	select @numrows = @@rowcount
	if @numrows = 0 return

	DECLARE @PrintDebug bit
	Set @PrintDebug=0

	SET NOCOUNT ON

	IF EXISTS(SELECT 1 FROM DELETED
		WHERE LineType='S')
	BEGIN
		-- Delete the corresponding SMWorkCompleted records that have not been invoiced.
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaild 1: Collect SMWorkCompletedID'
		DECLARE @SMWorkCompleted TABLE (SMWorkCompletedID int)
		INSERT INTO @SMWorkCompleted (SMWorkCompletedID)
			SELECT SMWorkCompletedID FROM SMWorkCompleted
			LEFT JOIN SMInvoice 
				ON SMInvoice.SMCo=SMWorkCompleted.SMCo 
				AND SMInvoice.SMInvoiceID = SMWorkCompleted.SMInvoiceID
			WHERE SMInvoice.SMInvoiceID IS NULL AND SMWorkCompletedID IN (
				SELECT SMWorkCompleted.SMWorkCompletedID FROM DELETED 
				INNER JOIN vSMMyTimesheetLink 
					ON vSMMyTimesheetLink.EntryEmployee=DELETED.EntryEmployee 
					AND vSMMyTimesheetLink.Employee=DELETED.Employee 
					AND vSMMyTimesheetLink.StartDate=DELETED.StartDate 
					AND vSMMyTimesheetLink.Sheet=DELETED.Sheet 
					AND vSMMyTimesheetLink.Seq=DELETED.Seq
				INNER JOIN SMWorkCompleted
					ON SMWorkCompleted.SMCo=vSMMyTimesheetLink.SMCo
					AND SMWorkCompleted.WorkOrder=vSMMyTimesheetLink.WorkOrder
					AND SMWorkCompleted.WorkCompleted=vSMMyTimesheetLink.WorkCompleted
					AND SMWorkCompleted.Type=2
				WHERE vSMMyTimesheetLink.UpdateInProgress=0)

		DECLARE idcursor CURSOR FOR
		SELECT SMWorkCompletedID FROM @SMWorkCompleted
		
		OPEN idcursor
		FETCH NEXT FROM idcursor INTO @SMWorkCompletedID
		WHILE @@FETCH_STATUS = 0
		BEGIN
				
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaild 2: Set UpdateInProgress=1 in links'
			UPDATE vSMMyTimesheetLink SET UpdateInProgress=1
				WHERE SMWorkCompletedID=@SMWorkCompletedID
		
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaild 3: Delete SMWorkCompleted'
			DELETE SMWorkCompleted 
				WHERE SMWorkCompletedID = @SMWorkCompletedID

IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaild 4: Delete SMMyTimesheetLink'
			DELETE vSMMyTimesheetLink
				WHERE SMWorkCompletedID = @SMWorkCompletedID		

			FETCH NEXT FROM idcursor INTO @SMWorkCompletedID
		END
		CLOSE idcursor
		DEALLOCATE idcursor
		
		-- Set the CostQty and ProjCost to zero on the corresponding SMWorkCompleted records that have been invoiced.
		IF EXISTS(SELECT 1 FROM SMWorkCompleted
			LEFT JOIN SMInvoice 
				ON SMInvoice.SMCo=SMWorkCompleted.SMCo 
				AND SMInvoice.SMInvoiceID = SMWorkCompleted.SMInvoiceID
			WHERE NOT SMInvoice.SMInvoiceID IS NULL AND SMWorkCompletedID IN (
				SELECT SMWorkCompleted.SMWorkCompletedID FROM DELETED 
				INNER JOIN vSMMyTimesheetLink
					ON vSMMyTimesheetLink.EntryEmployee=DELETED.EntryEmployee 
					AND vSMMyTimesheetLink.Employee=DELETED.Employee 
					AND vSMMyTimesheetLink.StartDate=DELETED.StartDate 
					AND vSMMyTimesheetLink.Sheet=DELETED.Sheet 
					AND vSMMyTimesheetLink.Seq=DELETED.Seq
				INNER JOIN SMWorkCompleted ON SMWorkCompleted.SMCo=vSMMyTimesheetLink.SMCo
					AND SMWorkCompleted.WorkOrder=vSMMyTimesheetLink.WorkOrder
					AND SMWorkCompleted.WorkCompleted=vSMMyTimesheetLink.WorkCompleted
					AND SMWorkCompleted.Type=2
				WHERE vSMMyTimesheetLink.UpdateInProgress=0))
		BEGIN
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaild 5: Collect Invoiced SMWorkCompletedID'
			DELETE FROM @SMWorkCompleted
			
			INSERT INTO @SMWorkCompleted (SMWorkCompletedID)
				SELECT SMWorkCompletedID FROM SMWorkCompleted
				LEFT JOIN SMInvoice 
					ON SMInvoice.SMCo=SMWorkCompleted.SMCo 
					AND SMInvoice.SMInvoiceID = SMWorkCompleted.SMInvoiceID
				WHERE NOT SMInvoice.SMInvoiceID IS NULL AND SMWorkCompletedID IN (
					SELECT SMWorkCompleted.SMWorkCompletedID FROM DELETED 
					INNER JOIN vSMMyTimesheetLink
						ON vSMMyTimesheetLink.EntryEmployee=DELETED.EntryEmployee 
						AND vSMMyTimesheetLink.Employee=DELETED.Employee 
						AND vSMMyTimesheetLink.StartDate=DELETED.StartDate 
						AND vSMMyTimesheetLink.Sheet=DELETED.Sheet 
						AND vSMMyTimesheetLink.Seq=DELETED.Seq
					INNER JOIN SMWorkCompleted ON SMWorkCompleted.SMCo=vSMMyTimesheetLink.SMCo
						AND SMWorkCompleted.WorkOrder=vSMMyTimesheetLink.WorkOrder
						AND SMWorkCompleted.WorkCompleted=vSMMyTimesheetLink.WorkCompleted
						AND SMWorkCompleted.Type=2
					WHERE vSMMyTimesheetLink.UpdateInProgress=0)
			
			DECLARE idcursor CURSOR FOR
			SELECT SMWorkCompletedID FROM @SMWorkCompleted
			
			OPEN idcursor
			FETCH NEXT FROM idcursor INTO @SMWorkCompletedID
			WHILE @@FETCH_STATUS = 0
			BEGIN

IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaild 6: Set UpdateInProgress=1 in links'
				UPDATE vSMMyTimesheetLink SET UpdateInProgress=1
					WHERE SMWorkCompletedID = @SMWorkCompletedID
		
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaild 7: Update SMWorkCompleted'
				UPDATE vSMWorkCompletedLabor SET CostQuantity=0, ProjCost=0 
					WHERE SMWorkCompletedID = @SMWorkCompletedID
			
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaild 8: DELETE vSMMyTimesheetLink'
				-- Delete the corresponding SMMyTimesheetLink records.
				DELETE vSMMyTimesheetLink
				WHERE SMWorkCompletedID = @SMWorkCompletedID

				FETCH NEXT FROM idcursor INTO @SMWorkCompletedID
			END
			CLOSE idcursor
			DEALLOCATE idcursor
		END
	END
	
-- Auditing?

   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR My Timesheet Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 07/23/2009
-- Description:	
-- Modifications: 01/18/2011 EricV Add update to SM Work Completed record.
--                03/15/2011 EricV Added Craft, Class and Shift
--                05/03/2011 EricV Added check for SM UsePRInterface flag
--                08/08/2011 EricV Moved location fo SELECT @PrintDebug. Causing problems with @@rowcount.
--                08/25/2011 EricV Added SMCostType field
--                02/09/2012 JG Added SMJCCostType and SMPhaseGroup fields
--				  06/11/2012 EricV TK-14637 Remove references to SMPhaseGroup. Use PhaseGroup instead.
-- =============================================

CREATE TRIGGER [dbo].[btPRMyTimesheetDetaili] 
   ON  [dbo].[bPRMyTimesheetDetail] for INSERT as  
BEGIN

	/* Flag to print debug statements */
	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

	select @numrows = @@rowcount
	if @numrows = 0 return

	DECLARE @PrintDebug bit
	Set @PrintDebug=0

	SET NOCOUNT ON

	/* validate timesheet */
	select @validcnt = count(1) from dbo.bPRMyTimesheet (nolock) p
	join inserted i on p.PRCo = i.PRCo and p.EntryEmployee = i.EntryEmployee and p.StartDate = i.StartDate and
	p.Sheet = i.Sheet
	
	if @validcnt <> @numrows
	begin
		select @errmsg = 'Invalid Timesheet: '+convert(varchar, @numrows)+' '+convert(varchar, @validcnt)
		goto error
	end
	
	/* validate status */	
	if exists(select 1 from bPRMyTimesheet p join inserted i on p.PRCo = i.PRCo and
	p.EntryEmployee = i.EntryEmployee and p.StartDate = i.StartDate and p.Sheet = i.Sheet
	where p.Status > 0)
	begin
		select @errmsg = 'Timesheet has been locked and cannot be edited'
		goto error
	end

	-- Check to see if any SM record exists
	IF NOT EXISTS(SELECT 1 FROM INSERTED WHERE LineType = 'S')
	BEGIN
		goto SMUpdateEnd
	END
	
	/* Create a matching record in SMWorkCompleted linked with records in SMBC */
	/* For each MyTimesheetDetail record one SMWorkCompleted record will be created for each day that is not null */
	DECLARE @PRCo bCompany, @EntryEmployee int, @Employee int, @StartDate smalldatetime, @Sheet smallint, 
			@Seq smallint, @SMCo bCompany, @WorkOrder int, @Scope int, @PayType varchar(10), @Hours1 bHrs, 
			@Hours2 bHrs, @Hours3 bHrs, @Hours4 bHrs, @Hours5 bHrs, @Hours6 bHrs, @Hours7 bHrs, @rcode int,
			@Craft bCraft, @Class bClass, @Shift tinyint, @SMCostType smallint, 
			@SMJCCostType dbo.bJCCType, @SMPhaseGroup dbo.bGroup
	
	DECLARE cInserted CURSOR FOR
	SELECT INSERTED.PRCo, INSERTED.EntryEmployee, INSERTED.Employee, INSERTED.StartDate, INSERTED.Sheet, 
		INSERTED.Seq, INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope, INSERTED.PayType, INSERTED.DayOne,
		INSERTED.DayTwo, INSERTED.DayThree, INSERTED.DayFour, INSERTED.DayFive, INSERTED.DaySix, INSERTED.DaySeven, 
		INSERTED.Craft, INSERTED.Class, INSERTED.Shift, INSERTED.SMCostType,
		INSERTED.SMJCCostType, INSERTED.PhaseGroup
	FROM INSERTED 
	WHERE LineType = 'S'
	
	OPEN cInserted
	FETCH NEXT FROM cInserted INTO @PRCo, @EntryEmployee, @Employee, @StartDate, @Sheet, @Seq, 
		@SMCo, @WorkOrder, @Scope, @PayType, @Hours1, @Hours2, @Hours3, @Hours4, @Hours5, @Hours6, @Hours7,
		@Craft, @Class, @Shift, @SMCostType, @SMJCCostType, @SMPhaseGroup
	WHILE @@FETCH_STATUS = 0
		BEGIN
			/* Create the SMWorkCompleted records */
--IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetaili 1: vspSMMyTimesheetDetaili'
			exec @rcode = vspSMMyTimesheetDetaili @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, @Employee=@Employee, 
			@StartDate=@StartDate, @Sheet=@Sheet, @Seq=@Seq, @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Craft=@Craft, @Class=@Class, @Shift=@Shift,
			@Scope=@Scope, @PayType=@PayType, @SMCostType=@SMCostType, @Hours1=@Hours1, @Hours2=@Hours2, @Hours3=@Hours3, @Hours4=@Hours4,
			@Hours5=@Hours5, @Hours6=@Hours6, @Hours7=@Hours7, 
			@SMJCCostType=@SMJCCostType, @SMPhaseGroup=@SMPhaseGroup, @errmsg=@errmsg OUTPUT  
			IF (@rcode = 1)
				BEGIN
					goto error
				END

			/* Get the next MyTimesheetDetail record */
			FETCH NEXT FROM cInserted INTO @PRCo, @EntryEmployee, @Employee, @StartDate, @Sheet, @Seq, 
				@SMCo, @WorkOrder, @Scope, @PayType, @Hours1, @Hours2, @Hours3, @Hours4, @Hours5, @Hours6, @Hours7,
				@Craft, @Class, @Shift, @SMCostType, @SMJCCostType, @SMPhaseGroup
		END
	
	CLOSE cInserted
	DEALLOCATE cInserted

SMUpdateEnd:
-- Auditing?
	
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR My Timesheet Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 07/24/2009
-- Description:	
-- Modifications: 01/18/2011 EricV - Add update to SM Work Completed record.
--                03/15/2011 EricV - Added Craft, Class and Shift
--                05/02/2011 Jacob V - Added code to automatically unapprove SM records
--                05/04/2011 Eric V  Modified for one unique WorkCompleted for all types.
--                05/05/2011 Eric V  Check UsePRInterface flag in SMCO.
--                08/25/2011 Eric V  Added SMCostType.
--				  02/09/2012 JG - TK-12388 - Added SMJCCostType and SMPhaseGroup.
-- =============================================

CREATE TRIGGER [dbo].[btPRMyTimesheetDetailu]
   ON  [dbo].[bPRMyTimesheetDetail] for Update as  
BEGIN

	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

	select @numrows = @@rowcount
	if @numrows = 0 return

	/* Flag to print debug statements */
	DECLARE @PrintDebug bit
	Set @PrintDebug=0

	SET NOCOUNT ON

	/* check for key changes */
	if update(PRCo)
	begin
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change PR Company'
			goto error
		end
	end

	if update(EntryEmployee)
	begin	
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and i.EntryEmployee = d.EntryEmployee
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change EntryEmployee'
			goto error
		end
	end

	if update(StartDate)
	begin	
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and i.StartDate = d.StartDate
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Start Date'
			goto error
		end
	end

	if update(Sheet)
	begin	
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and i.Sheet = d.Sheet
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Sheet Number'
			goto error
		end
	end

	if update(Seq)
	begin	
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and i.Seq = d.Seq
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Sequence Number'
			goto error
		end
	end
	
	/* validate timesheet */
	select @validcnt = count(1) from dbo.bPRMyTimesheet (nolock) p
	join inserted i on p.PRCo = i.PRCo and p.EntryEmployee = i.EntryEmployee and p.StartDate = i.StartDate and
	p.Sheet = i.Sheet
	
	if @validcnt <> @numrows
	begin
		select @errmsg = 'Invalid Timesheet'
		goto error
	end


	if update(Approved)
	begin
	/* update timesheet to status 2 if all time card entries have been approved 
		only update the timesheets that are related to the time cards we just updated */
			update bPRMyTimesheet
			set [Status] = 2
			from bPRMyTimesheet
				inner join 
					(
					--This query returns all the time sheets related to our update and that need to be updated
					select bPRMyTimesheetDetail.PRCo, bPRMyTimesheetDetail.EntryEmployee, bPRMyTimesheetDetail.StartDate, bPRMyTimesheetDetail.Sheet
					from bPRMyTimesheetDetail
						inner join
						(
							--This query limits the time sheets that can be updated
							-- to only the timesheets that are related to this update
							-- We use distinct to narrow down our records to one with those
							-- values so that our join doesn't return multiple rows that mess up our count
							select distinct PRCo, EntryEmployee, StartDate, Sheet
							from inserted
						) TimeSheetsThatCanBeUpdated
						on bPRMyTimesheetDetail.PRCo = TimeSheetsThatCanBeUpdated.PRCo
							and bPRMyTimesheetDetail.EntryEmployee = TimeSheetsThatCanBeUpdated.EntryEmployee
							and bPRMyTimesheetDetail.StartDate = TimeSheetsThatCanBeUpdated.StartDate
							and bPRMyTimesheetDetail.Sheet = TimeSheetsThatCanBeUpdated.Sheet
					group by  bPRMyTimesheetDetail.PRCo,  bPRMyTimesheetDetail.EntryEmployee,  bPRMyTimesheetDetail.StartDate,  bPRMyTimesheetDetail.Sheet
					having count(*) = count(case when Approved = 'Y' then 1 else null end)
					) TimeSheetsThatAreFullApproved
					on bPRMyTimesheet.PRCo = TimeSheetsThatAreFullApproved.PRCo
						and bPRMyTimesheet.EntryEmployee = TimeSheetsThatAreFullApproved.EntryEmployee
						and bPRMyTimesheet.StartDate = TimeSheetsThatAreFullApproved.StartDate
						and bPRMyTimesheet.Sheet = TimeSheetsThatAreFullApproved.Sheet
			where [Status] < 2
			
	/* update timesheet to status 1 if not all time card entries have been approved 
		only update the timesheets that are related to the time cards we just updated */
			update bPRMyTimesheet
			set [Status] = 1
			from bPRMyTimesheet
				inner join 
					(
					--This query returns all the time sheets related to our update and that need to be updated
					select bPRMyTimesheetDetail.PRCo, bPRMyTimesheetDetail.EntryEmployee, bPRMyTimesheetDetail.StartDate, bPRMyTimesheetDetail.Sheet
					from bPRMyTimesheetDetail
						inner join
						(
							--This query limits the time sheets that can be updated
							-- to only the timesheets that are related to this update
							-- We use distinct to narrow down our records to one with those
							-- values so that our join doesn't return multiple rows that mess up our count
							select distinct PRCo, EntryEmployee, StartDate, Sheet
							from inserted
						) TimeSheetsThatCanBeUpdated
						on bPRMyTimesheetDetail.PRCo = TimeSheetsThatCanBeUpdated.PRCo
							and bPRMyTimesheetDetail.EntryEmployee = TimeSheetsThatCanBeUpdated.EntryEmployee
							and bPRMyTimesheetDetail.StartDate = TimeSheetsThatCanBeUpdated.StartDate
							and bPRMyTimesheetDetail.Sheet = TimeSheetsThatCanBeUpdated.Sheet
					group by  bPRMyTimesheetDetail.PRCo,  bPRMyTimesheetDetail.EntryEmployee,  bPRMyTimesheetDetail.StartDate,  bPRMyTimesheetDetail.Sheet
					having count(*) <> count(case when Approved = 'Y' then 1 else null end)
					) TimeSheetsThatAreFullApproved
					on bPRMyTimesheet.PRCo = TimeSheetsThatAreFullApproved.PRCo
						and bPRMyTimesheet.EntryEmployee = TimeSheetsThatAreFullApproved.EntryEmployee
						and bPRMyTimesheet.StartDate = TimeSheetsThatAreFullApproved.StartDate
						and bPRMyTimesheet.Sheet = TimeSheetsThatAreFullApproved.Sheet
			where [Status] between 2 and 3
	end;
	
	-- Unapprove records that were approved at one point if the timesheet is in unlocked mode
	-- This happens when the person responsible for the timesheet has it in unlocked mode and there were records already approved
	WITH TimeSheetDetailsThatNeedToBeUnapproved(PRCo, EntryEmployee, StartDate, Sheet, Seq, NeedsToBeUnapproved)
	AS
	(
		SELECT INSERTED.PRCo
			,INSERTED.EntryEmployee
			,INSERTED.StartDate
			,INSERTED.Sheet
			,INSERTED.Seq
			, ~(dbo.vfIsEqual(INSERTED.Employee, DELETED.Employee)
				& dbo.vfIsEqual(INSERTED.JCCo, DELETED.JCCo)
				& dbo.vfIsEqual(INSERTED.PhaseGroup, DELETED.PhaseGroup)
				& dbo.vfIsEqual(INSERTED.Phase, DELETED.Phase)
				& dbo.vfIsEqual(INSERTED.EarnCode, DELETED.EarnCode)
				& dbo.vfIsEqual(INSERTED.Craft, DELETED.Craft)
				& dbo.vfIsEqual(INSERTED.Class, DELETED.Class)
				& dbo.vfIsEqual(INSERTED.Shift, DELETED.Shift)
				& dbo.vfIsEqual(INSERTED.SMCostType, DELETED.SMCostType)
				& dbo.vfIsEqual(INSERTED.SMJCCostType, DELETED.SMJCCostType)
				& dbo.vfIsEqual(INSERTED.PhaseGroup, DELETED.PhaseGroup)
				& dbo.vfIsEqual(INSERTED.DayOne, DELETED.DayOne)
				& dbo.vfIsEqual(INSERTED.DayTwo, DELETED.DayTwo)
				& dbo.vfIsEqual(INSERTED.DayThree, DELETED.DayThree)
				& dbo.vfIsEqual(INSERTED.DayFour, DELETED.DayFour)
				& dbo.vfIsEqual(INSERTED.DayFive, DELETED.DayFive)
				& dbo.vfIsEqual(INSERTED.DaySix, DELETED.DaySix)
				& dbo.vfIsEqual(INSERTED.DaySeven, DELETED.DaySeven)
				& dbo.vfIsEqual(INSERTED.LineType, DELETED.LineType)
				& dbo.vfIsEqual(INSERTED.SMCo, DELETED.SMCo)
				& dbo.vfIsEqual(INSERTED.WorkOrder, DELETED.WorkOrder)
				& dbo.vfIsEqual(INSERTED.Scope, DELETED.Scope)
				& dbo.vfIsEqual(INSERTED.PayType, DELETED.PayType)) --The ~ is a bitwise not operator. We are basically doing bit operations to see if any values have changed.
		FROM INSERTED
		INNER JOIN DELETED ON INSERTED.PRCo = DELETED.PRCo 
			AND INSERTED.EntryEmployee = DELETED.EntryEmployee 
			AND INSERTED.StartDate = DELETED.StartDate
			AND INSERTED.Sheet = DELETED.Sheet
			AND INSERTED.Seq = DELETED.Seq
		INNER JOIN bPRMyTimesheet ON INSERTED.PRCo = bPRMyTimesheet.PRCo 
			AND INSERTED.EntryEmployee = bPRMyTimesheet.EntryEmployee 
			AND INSERTED.StartDate = bPRMyTimesheet.StartDate
			AND INSERTED.Sheet = bPRMyTimesheet.Sheet
		WHERE [Status] = 0
	)
	
	UPDATE bPRMyTimesheetDetail
	SET Approved = 'N'
		,ApprovedBy = NULL
		,ApprovedOn = NULL
	FROM bPRMyTimesheetDetail
		INNER JOIN TimeSheetDetailsThatNeedToBeUnapproved ON bPRMyTimesheetDetail.PRCo = TimeSheetDetailsThatNeedToBeUnapproved.PRCo
			AND bPRMyTimesheetDetail.EntryEmployee = TimeSheetDetailsThatNeedToBeUnapproved.EntryEmployee
			AND bPRMyTimesheetDetail.StartDate = TimeSheetDetailsThatNeedToBeUnapproved.StartDate
			AND bPRMyTimesheetDetail.Sheet = TimeSheetDetailsThatNeedToBeUnapproved.Sheet
			AND bPRMyTimesheetDetail.Seq = TimeSheetDetailsThatNeedToBeUnapproved.Seq
	WHERE NeedsToBeUnapproved = 1

	-- Check to see if any SM record exists
	IF NOT EXISTS(SELECT 1 FROM INSERTED
		INNER JOIN DELETED ON INSERTED.PRCo=DELETED.PRCo AND INSERTED.EntryEmployee=DELETED.EntryEmployee
			AND INSERTED.StartDate=DELETED.StartDate AND INSERTED.Sheet=DELETED.Sheet AND INSERTED.Seq=DELETED.Seq
		WHERE INSERTED.LineType='S' OR DELETED.LineType='S')
	BEGIN
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 0: No type S records in INSERTED.'
		goto SMUpdateEnd
	END
	
	-- Update SMWorkCompleted with Changes.
	/* Create a matching record in SMWorkCompleted linked with records in SMBC */
	/* For each MyTimesheetDetail record one SMWorkCompleted record will be created for each day that is not null */
	DECLARE @WorkCompleted int, @PRCo bCompany, @EntryEmployee int, @StartDate smalldatetime, @Sheet smallint, @Seq smallint,
			@SMCo bCompany, @WorkOrder int, @Scope int, @PayType varchar(10), @NextSeq int, @TaxCode varchar(10), @SMCostType smallint,
			@Technician varchar(15), @Employee int, @TaxRate bRate, @Day tinyint, @ServiceSite varchar(20), @rcode int,
			@msg varchar(255), @Hours bHrs, @Hours2 bHrs, @Hours3 bHrs, @Hours4 bHrs, @Hours5 bHrs, @Hours6 bHrs, @Hours7 bHrs,
			@bSMCursorOpen bit, @bSMChangesCursorOpen bit, @UpdateInProgress bit, @LineType char(1), 
			@Craft bCraft, @Class bClass, @Shift tinyint, @SMJCCostType dbo.bJCCType, @SMPhaseGroup dbo.bGroup
	
	DECLARE cInserted CURSOR FOR
	SELECT INSERTED.PRCo, INSERTED.EntryEmployee, INSERTED.Employee, INSERTED.StartDate, INSERTED.Sheet, INSERTED.Seq, 
		INSERTED.LineType, INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope, INSERTED.PayType, INSERTED.SMCostType, INSERTED.DayOne, INSERTED.DayTwo, 
		INSERTED.DayThree, INSERTED.DayFour, INSERTED.DayFive, INSERTED.DaySix, INSERTED.DaySeven,
		INSERTED.Craft, INSERTED.Class, INSERTED.Shift,	INSERTED.SMJCCostType, INSERTED.PhaseGroup
	FROM INSERTED 
	INNER JOIN DELETED ON INSERTED.PRCo=DELETED.PRCo AND INSERTED.EntryEmployee=DELETED.EntryEmployee
			AND INSERTED.StartDate=DELETED.StartDate AND INSERTED.Sheet=DELETED.Sheet AND INSERTED.Seq=DELETED.Seq
	WHERE INSERTED.LineType = 'S' OR DELETED.LineType='S'
	
	OPEN cInserted
	FETCH NEXT FROM cInserted INTO @PRCo, @EntryEmployee, @Employee, @StartDate, @Sheet, @Seq, @LineType,
		@SMCo, @WorkOrder, @Scope, @PayType, @SMCostType, @Hours, @Hours2, @Hours3, @Hours4, @Hours5, @Hours6, @Hours7,
		@Craft, @Class, @Shift,@SMJCCostType, @SMPhaseGroup
	SET @bSMCursorOpen = 1
	
	WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @OldHours bHrs, @OldHours1 bHrs, @OldHours2 bHrs, @OldHours3 bHrs, @OldHours4 bHrs, @OldHours5 bHrs, @OldHours6 bHrs,
				@OldHours7 bHrs, @OldSMCo bCompany, @OldWorkOrder int, @OldScope int, @OldPayType varchar(10), @OldSMCostType smallint, @OldEmployee int,
				@OldStartDate smalldatetime, @NewHours bHrs, @OldLineType char(1), @OldCraft bCraft, @OldClass bClass, @OldShift TINYINT,
				@OldSMJCCostType dbo.bJCCType, @OldSMPhaseGroup dbo.bGroup

			SELECT @OldHours1=isnull(DayOne,0), @OldHours2=isnull(DayTwo,0), @OldHours3=isnull(DayThree,0), @OldHours4=isnull(DayFour,0), @OldHours5=isnull(DayFive,0), @OldHours6=isnull(DaySix,0),
			@OldHours7=isnull(DaySeven,0), @OldSMCo=SMCo, @OldWorkOrder=WorkOrder, @OldScope=Scope, @OldPayType=PayType, @OldSMCostType=SMCostType, @OldEmployee=Employee,
			@OldStartDate=StartDate, @OldLineType=LineType, @OldCraft=Craft, @OldClass=Class, @OldShift=Shift,
			@OldSMJCCostType=SMJCCostType, @OldSMPhaseGroup=PhaseGroup
			FROM DELETED WHERE PRCo=@PRCo AND EntryEmployee = @EntryEmployee AND StartDate = @StartDate AND Sheet = @Sheet and Seq = @Seq

IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 1: StartDate='+Convert(varchar, @StartDate, 101)+' EntryEmployee='+Convert(varchar, isnull(@EntryEmployee,0))+' Employee='+Convert(varchar, isnull(@Employee,0))+' StartDate='+Convert(varchar, @StartDate,101)+' Sheet='+Convert(varchar, isnull(@Sheet,0))+' Seq='+Convert(varchar, isnull(@Seq,0))+
	' Old1='+CONVERT(varchar,@OldHours1)+' Old2='+CONVERT(varchar,@OldHours2)+' Old3='+CONVERT(varchar,@OldHours3)+' Old4='+CONVERT(varchar,@OldHours4)+' Old5='+CONVERT(varchar,@OldHours5)+' Old6='+CONVERT(varchar,@OldHours6)+' Old7='+CONVERT(varchar,@OldHours7)

			/* Get the Technician from the Employee number */
			SELECT @Technician=Technician FROM vSMTechnician WHERE SMCo = @SMCo AND PRCo = @PRCo
			AND Employee = @Employee
			IF @@ROWCOUNT = 0
				BEGIN
					SET @msg = 'Employee ' + Convert(varchar, @Employee) + ' is not a valid SM technician for SMCo ' + convert(varchar, @SMCo) +'.'
					goto error
				END

			-- Load the records with the new values for each day into a Table variable.
			DECLARE @NewTimesheetData TABLE	( Date smalldatetime, Hours numeric(12,3) )
			INSERT @NewTimesheetData (Date, Hours)
			SELECT 
				CASE WHEN Date = 'DayOne' THEN StartDate				WHEN Date = 'DayTwo' Then DATEADD(d, 1, StartDate)
				WHEN Date = 'DayThree' Then DATEADD(d, 2, StartDate)	WHEN Date = 'DayFour' Then DATEADD(d, 3, StartDate)
				WHEN Date = 'DayFive' Then DATEADD(d, 4, StartDate)		WHEN Date = 'DaySix' Then DATEADD(d, 5, StartDate)
				WHEN Date = 'DaySeven' Then DATEADD(d, 6, StartDate)	END as Date, Hours
			FROM
			(select @StartDate StartDate, ISNULL(@Hours,0) DayOne, ISNULL(@Hours2,0) DayTwo, ISNULL(@Hours3,0) DayThree, ISNULL(@Hours4,0) DayFour, 
						ISNULL(@Hours5,0) DayFive, ISNULL(@Hours6,0) DaySix, ISNULL(@Hours7,0) DaySeven
			) AS p
			UNPIVOT (Hours FOR Date IN (DayOne, DayTwo, DayThree, DayFour, DayFive, DaySix, DaySeven)
			) AS unpvt
			
			-- Load the records with the old values for each day into a Table variable.
			DECLARE @OldTimesheetData TABLE	( Date smalldatetime, Hours numeric(12,3) )
			INSERT @OldTimesheetData (Date, Hours)
			SELECT 
				CASE WHEN Date = 'DayOne' THEN StartDate				WHEN Date = 'DayTwo' Then DATEADD(d, 1, StartDate)
				WHEN Date = 'DayThree' Then DATEADD(d, 2, StartDate)	WHEN Date = 'DayFour' Then DATEADD(d, 3, StartDate)
				WHEN Date = 'DayFive' Then DATEADD(d, 4, StartDate)		WHEN Date = 'DaySix' Then DATEADD(d, 5, StartDate)
				WHEN Date = 'DaySeven' Then DATEADD(d, 6, StartDate)	END as Date, Hours
			FROM
			(select @OldStartDate StartDate, ISNULL(@OldHours1,0) DayOne, ISNULL(@OldHours2,0) DayTwo, ISNULL(@OldHours3,0) DayThree, ISNULL(@OldHours4,0) DayFour, 
						ISNULL(@OldHours5,0) DayFive, ISNULL(@OldHours6,0) DaySix, ISNULL(@OldHours7,0) DaySeven
			) AS p
			UNPIVOT (Hours FOR Date IN (DayOne, DayTwo, DayThree, DayFour, DayFive, DaySix, DaySeven)
			) AS unpvt

			-- Compare each day and update SM with changes.
			DECLARE @TimesheetData TABLE ( Date smalldatetime, OldHours numeric(12,3), NewHours numeric(12,3) )
			INSERT @TimesheetData
			SELECT ISNULL(Old.Date, New.Date), ISNULL(Old.Hours,0),
			ISNULL(New.Hours,0) FROM @NewTimesheetData New 
			FULL OUTER JOIN @OldTimesheetData Old ON New.Date = Old.Date

			-- Loop through the dates and hours and update the SMWorkCompleted records if the link is not already in UpdateInProcess mode.
			DECLARE @TimesheetDate smalldatetime, @SMWorkCompletedID bigint, @LinkRecordExists bit, @IsBilled bit
			DECLARE cChanges CURSOR FOR
			SELECT Date, OldHours, NewHours
			FROM @TimesheetData
			
			OPEN cChanges
			FETCH NEXT FROM cChanges INTO @TimesheetDate, @OldHours, @NewHours
			SET @bSMChangesCursorOpen = 1
			WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @Day = DateDiff(d, @StartDate, @TimesheetDate)+1
					-- Check to see if this SMWorkCompleted record is already linked to a PRMyTimesheetDetail record.
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 2: Search TimesheetDate='+convert(varchar,isnull(@TimesheetDate,0),101)+' EntryEmployee='+CONVERT(VARCHAR, isnull(@EntryEmployee,0))+' Employee='+CONVERT(VARCHAR, isnull(@Employee,0))+' StartDate='+CONVERT(VARCHAR, isnull(@StartDate,0),101)+' Day='+CONVERT(VARCHAR, isnull(@Day,0))+' Sheet='+CONVERT(VARCHAR, isnull(@Sheet,0))+' Seq='+CONVERT(VARCHAR, isnull(@Seq,0))+
	' OldHours='+CONVERT(varchar,isnull(@OldHours,0))+' NewHours='+CONVERT(varchar,isnull(@NewHours,0))
IF (@PrintDebug=1) PRINT ' PayType='+isnull(@PayType,'')+' WorkOrder='+Convert(varchar,isnull(@WorkOrder,0))+' Scope='+Convert(varchar,isnull(@Scope,0))
					IF EXISTS(SELECT 1 FROM vSMMyTimesheetLink WHERE EntryEmployee=@EntryEmployee AND StartDate=@StartDate
						AND DayNumber=@Day AND Sheet=@Sheet AND Seq=@Seq)
					BEGIN
						SET @LinkRecordExists = 1
						SELECT @SMWorkCompletedID=SMWorkCompletedID, @UpdateInProgress=UpdateInProgress FROM vSMMyTimesheetLink 
							WHERE vSMMyTimesheetLink.EntryEmployee=@EntryEmployee
							AND vSMMyTimesheetLink.StartDate=@StartDate
							AND vSMMyTimesheetLink.DayNumber=@Day
							AND vSMMyTimesheetLink.Sheet=@Sheet
							AND vSMMyTimesheetLink.Seq=@Seq
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 3: MyTimesheet already linked: SMWorkCompletedID='+Convert(varchar, isnull(@SMWorkCompletedID,0))+' Day='+COnvert(varchar,isnull(@Day,0))+' UpdateInProgress='+Convert(varchar,isnull(@UpdateInProgress,-1))
					END
					ELSE 
					BEGIN
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 3.1: MyTimesheet not linked: SMWorkCompletedID='+Convert(varchar, isnull(@SMWorkCompletedID,0))+' Day='+Convert(varchar,ISNULL(@Day,0))+' UpdateInProgress='+Convert(varchar,isnull(@UpdateInProgress,0))
IF (@PrintDebug=1) PRINT ' EntryEmployee='+CONVERT(VARCHAR, ISNULL(@EntryEmployee,0))+' StartDate='+CONVERT(VARCHAR, @StartDate,101)+' Day='+CONVERT(VARCHAR, isnull(@Day,0))+' Sheet='+CONVERT(VARCHAR, isnull(@Sheet,0))+' Seq='+CONVERT(VARCHAR, isnull(@Seq,0))
IF (@PrintDebug=1) PRINT ' PayType='+ISNULL(@PayType,'NULL')+' WorkOrder='+Convert(varchar,ISNULL(@WorkOrder,0))+' Scope='+Convert(varchar,ISNULL(@Scope,0))+' OldHours='+Convert(varchar,ISNULL(@OldHours,0))+' Hours='+Convert(varchar,ISNULL(@Hours,0))
IF (@PrintDebug=1) PRINT ' OldPayType='+ISNULL(@OldPayType,'NULL')+' OldWorkOrder='+Convert(varchar,ISNULL(@OldWorkOrder,0))+' OldScope='+Convert(varchar,ISNULL(@OldScope,0))+' OldHours='+Convert(varchar,ISNULL(@OldHours,0))+' Hours='+Convert(varchar,ISNULL(@Hours,0))
IF (@PrintDebug=1) PRINT ' OldCraft='+ISNULL(@OldCraft,'NULL')+' OldClass='+ISNULL(@OldClass,'NULL')+' OldShift='+Convert(varchar,ISNULL(@OldShift,0))
						SELECT @LinkRecordExists = 0, @UpdateInProgress=0, @SMWorkCompletedID = NULL
					END
						
					-- If the link indicates that an update is in progress, then the SMWorkCompleted record does not need to be updated. */
					IF (@UpdateInProgress=1)
					BEGIN
						/* Update the Locked flag on this record since the change is coming from SM */
						--UPDATE PRMyTimesheet SET Locked
						GOTO SMNextDay
					END
					-- Also check to see if anything about this day has changed that requires an update to SMWorkCompleted
					IF (@LinkRecordExists=1 AND (dbo.vfIsEqual(@OldHours,@NewHours)&dbo.vfIsEqual(@OldSMCo,@SMCo)&dbo.vfIsEqual(@OldWorkOrder,@WorkOrder)&dbo.vfIsEqual(@OldScope,@Scope)&
						dbo.vfIsEqual(@OldPayType,@PayType)&dbo.vfIsEqual(@OldSMCostType,@SMCostType)&dbo.vfIsEqual(@OldEmployee,@Employee)&dbo.vfIsEqual(@LineType,@OldLineType)&dbo.vfIsEqual(@OldCraft,@Craft)&
						dbo.vfIsEqual(@OldClass,@Class)&dbo.vfIsEqual(@OldShift,@Shift)&
						dbo.vfIsEqual(@OldSMJCCostType,@SMJCCostType)&dbo.vfIsEqual(@OldSMPhaseGroup,@SMPhaseGroup)=1))
					BEGIN
						-- Everything that matters is still the same so don't bother to update SMWorkCompleted.
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 3.2: Skipping update: OldHours='+Convert(varchar,@OldHours)+' NewHours='+Convert(varchar,@NewHours)
						GOTO SMNextDay
					END
					-- Check to see if the SMWorkCompleted record has been billed.
					IF EXISTS(SELECT 1 FROM SMWorkCompleted
							LEFT JOIN SMInvoice 
								ON SMInvoice.SMCo=SMWorkCompleted.SMCo 
								AND SMInvoice.SMInvoiceID=SMWorkCompleted.SMInvoiceID
							WHERE NOT SMInvoice.SMInvoiceID IS NULL
								AND SMWorkCompleted.SMWorkCompletedID=@SMWorkCompletedID)
						SET @IsBilled = 1
					ELSE
						SET @IsBilled = 0
						
					-- If the current type is not SM then set NewHours to zero.
					IF (NOT @LineType='S' AND @OldLineType='S')
						SET @NewHours=0
					-- If the current type is SM and the old type was not then set OldHours to zero.
					IF (@LineType='S' AND NOT @OldLineType='S')
						SET @OldHours=0
						
					IF (@LinkRecordExists=1 AND (ISNULL(@NewHours,0)=0 OR (dbo.vfIsEqual(@SMCo,@OldSMCo)&dbo.vfIsEqual(@WorkOrder,@OldWorkOrder)&dbo.vfIsEqual(@Scope,@OldScope)=0)))
						BEGIN
							BEGIN TRY
								/* Set the UpdateInProgress flag in the SMMyTimesheetLink table so the change to the SMWorkCompleted
									record won't trigger a change back to the PRMyTimesheetDetail table. */
								UPDATE vSMMyTimesheetLink SET UpdateInProgress=1
									WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet 
									AND Seq=@Seq AND DayNumber=@Day
								
								-- Check to see if the SMWorkCompleted record has been billed.
								IF (@IsBilled = 1)
								BEGIN
									-- The SMWorkCompleted record has been billed so it cannot be deleted.  Just set the Cost values to zero.
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 6: UPDATE SMWorkCompleted'
									UPDATE vSMWorkCompletedLabor SET CostQuantity=0, ProjCost=0
										WHERE SMWorkCompletedID IN 
										(SELECT SMWorkCompleted.SMWorkCompletedID FROM vSMMyTimesheetLink
										INNER JOIN SMWorkCompleted 
											ON SMWorkCompleted.SMCo=vSMMyTimesheetLink.SMCo
											AND SMWorkCompleted.WorkOrder=vSMMyTimesheetLink.WorkOrder
											AND SMWorkCompleted.WorkCompleted=vSMMyTimesheetLink.WorkCompleted
											AND SMWorkCompleted.Type=2
										WHERE vSMMyTimesheetLink.EntryEmployee=@EntryEmployee 
											AND vSMMyTimesheetLink.StartDate=@StartDate 
											AND vSMMyTimesheetLink.Sheet=@Sheet 
											AND vSMMyTimesheetLink.Seq=@Seq 
											AND vSMMyTimesheetLink.DayNumber=@Day
										)
									-- Delete the SMMyTimesheetLink record
									DELETE vSMMyTimesheetLink
										WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet 
										AND Seq=@Seq AND DayNumber=@Day
									SET @LinkRecordExists=0
								END
								ELSE
								BEGIN
									-- Delete the SMWorkCompleted record that is linked to the MyTimesheetDetail record.
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 7: DELETE SMWorkCompleted'
									DELETE SMWorkCompleted WHERE SMWorkCompletedID IN 
										(SELECT SMWorkCompleted.SMWorkCompletedID FROM vSMMyTimesheetLink 
										INNER JOIN SMWorkCompleted 
											ON SMWorkCompleted.SMCo=vSMMyTimesheetLink.SMCo
											AND SMWorkCompleted.WorkOrder=vSMMyTimesheetLink.WorkOrder
											AND SMWorkCompleted.WorkCompleted=vSMMyTimesheetLink.WorkCompleted
											AND SMWorkCompleted.Type=2
										WHERE vSMMyTimesheetLink.PRCo=@PRCo
											AND vSMMyTimesheetLink.EntryEmployee=@EntryEmployee 
											AND vSMMyTimesheetLink.StartDate=@StartDate 
											AND vSMMyTimesheetLink.Sheet=@Sheet 
											AND vSMMyTimesheetLink.Seq=@Seq 
											AND vSMMyTimesheetLink.DayNumber=@Day
										)
									-- Delete the SMMyTimesheetLink record
									DELETE vSMMyTimesheetLink
										WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet 
										AND Seq=@Seq AND DayNumber=@Day
									SET @LinkRecordExists=0
								END
								/* Now change the UpdateInProgress flag back. */
								UPDATE vSMMyTimesheetLink SET UpdateInProgress=0
									WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet 
									AND Seq=@Seq AND DayNumber=@Day

							END TRY
							BEGIN CATCH
								SET @errmsg = 'Error updating SMWorkCompleted when IsBilled = ' + CASE WHEN @IsBilled=1 THEN 'True' ELSE 'False' END + ': ' + ERROR_MESSAGE()
								GOTO error
							END CATCH
						END
					IF (@LinkRecordExists=0 AND ISNULL(@NewHours,0)<>0)
						BEGIN
							SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @WorkOrder)
							
							/* Now create a linking record in vSMMyTimesheetLink for each new SMWorkCompleted record.
								The link must be created first so that the Insert of the SMWorkCompleted Labor record 
								doesn't trigger the create of a PRMyTimesheetDetail record.
							*/
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 4: vspSMMyTimesheetLinkCreate'
							exec @rcode = vspSMMyTimesheetLinkCreate @SMCo=@SMCo, @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, @Employee=@Employee,
								@StartDate=@StartDate, @WorkOrder=@WorkOrder, @Scope=@Scope, @Sheet=@Sheet, @Seq=@Seq, 
								@Day=@Day, @WorkCompleted=@WorkCompleted, @errmsg=@errmsg OUTPUT
							
							IF (@rcode = 1)
							BEGIN
								SET @errmsg = 'Error creating SMMyTimesheetLink.'
								GOTO error
							END
								
							-- Add a SMWorkCompleted record
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 5: vspSMWorkCompletedLaborCreate'
							exec @rcode = vspSMWorkCompletedLaborCreate @SMCo=@SMCo, @WorkOrder=@WorkOrder, @WorkCompleted = @WorkCompleted, @Scope=@Scope, @PayType=@PayType, @SMCostType=@SMCostType,
								@Technician=@Technician, @Date=@TimesheetDate, @Hours=@NewHours,
								@TCPRCo=@PRCo, @Craft=@Craft, @Class=@Class, @Shift=@Shift, 
								@SMJCCostType=@SMJCCostType, @SMPhaseGroup=@SMPhaseGroup,
								@SMWorkCompletedID=@SMWorkCompletedID OUTPUT, @msg=@errmsg OUTPUT
								
							IF (@rcode = 1)
							BEGIN
								SET @errmsg = 'Error creating SMWorkCompletedLabor.'
								GOTO error
							END

							-- Update link with the SMWorkCompletedID
							UPDATE vSMMyTimesheetLink SET SMWorkCompletedID=@SMWorkCompletedID
								WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet 
								AND Seq=@Seq AND DayNumber=@Day
							
						END
					ELSE IF (ISNULL(@NewHours,0)<>0)
						BEGIN
							/* Set the UpdateInProgress flag in the SMMyTimesheetLink table so the change to the SMWorkCompleted
								record won't trigger a change back to the PRMyTimesheetDetail table. */
							UPDATE vSMMyTimesheetLink SET UpdateInProgress=1
								FROM vSMMyTimesheetLink
								INNER JOIN vSMMyTimesheetLink Link2 on vSMMyTimesheetLink.EntryEmployee=Link2.EntryEmployee
									AND vSMMyTimesheetLink.Sheet=Link2.Sheet AND vSMMyTimesheetLink.StartDate=Link2.StartDate
									AND vSMMyTimesheetLink.Seq=Link2.Seq
								WHERE Link2.SMWorkCompletedID=@SMWorkCompletedID
							--UPDATE vSMMyTimesheetLink SET UpdateInProgress=1
							--	WHERE SMWorkCompletedID=@SMWorkCompletedID

							-- Update SMWorkCompleted with the new information for SMCo, Workorder, Technician and hours.
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 8: vspSMWorkCompletedLaborUpdate'
							exec @rcode = vspSMWorkCompletedLaborUpdate @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @PayType=@PayType, @SMCostType=@SMCostType,
								@Technician=@Technician, @Date=@TimesheetDate, @Hours=@NewHours, @SMWorkCompletedID=@SMWorkCompletedID, 
								@TCPRCo=@PRCo, @Craft=@Craft, @Class=@Class, @Shift=@Shift, @IsBilled=@IsBilled, 
								@SMJCCostType=@SMJCCostType, @SMPhaseGroup=@SMPhaseGroup,
								@msg=@errmsg OUTPUT
							IF (@rcode = 1)
							BEGIN
								SET @errmsg = 'Error updating SMWorkCompletedLabor.'
								GOTO error
							END

							/* Now change the UpdateInProgress flag back. */
							UPDATE vSMMyTimesheetLink SET UpdateInProgress=0
								FROM vSMMyTimesheetLink
								INNER JOIN vSMMyTimesheetLink Link2 on vSMMyTimesheetLink.EntryEmployee=Link2.EntryEmployee
									AND vSMMyTimesheetLink.Sheet=Link2.Sheet AND vSMMyTimesheetLink.StartDate=Link2.StartDate
									AND vSMMyTimesheetLink.Seq=Link2.Seq
								WHERE Link2.SMWorkCompletedID=@SMWorkCompletedID
							--UPDATE vSMMyTimesheetLink SET UpdateInProgress=0
							--	WHERE SMWorkCompletedID=@SMWorkCompletedID
							
						END				
SMNextDay:
					FETCH NEXT FROM cChanges INTO @TimesheetDate, @OldHours, @NewHours
IF (@PrintDebug=1) PRINT 'btPRMyTimesheetDetailu 9: Fetch - TimesheetDate='+Convert(varchar, isnull(@TimesheetDate,0),101)+' OldHours='+Convert(varchar, @OldHours)+' NewHours='+Convert(varchar, @NewHours)
				END
			
			CLOSE cChanges
			DEALLOCATE cChanges
			SET @bSMChangesCursorOpen=0
	
			/* Get the next MyTimesheetDetail record */
SMNextTimesheet:
		FETCH NEXT FROM cInserted INTO @PRCo, @EntryEmployee, @Employee, @StartDate, @Sheet, @Seq, @LineType,
			@SMCo, @WorkOrder, @Scope, @PayType, @SMCostType, @Hours, @Hours2, @Hours3, @Hours4, @Hours5, @Hours6, @Hours7,
			@Craft, @Class, @Shift, @SMJCCostType, @SMPhaseGroup
		END
	
	CLOSE cInserted
	DEALLOCATE cInserted
	SET @bSMCursorOpen=0
	
SMUpdateEnd:
-- Auditing?


   return
   error:
	IF @bSMChangesCursorOpen=1
	BEGIN
		CLOSE cChanges
		DEALLOCATE cChanges
	END
	IF (@bSMCursorOpen = 1)
	BEGIN
		CLOSE cInserted
		DEALLOCATE cInserted
	END
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR My Timesheet Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

END
GO
ALTER TABLE [dbo].[bPRMyTimesheetDetail] ADD CONSTRAINT [CK_bPRMyTimesheetDetail_RequiredJobPhase] CHECK (([dbo].[vfEqualsNull]([Phase])=(1) OR [dbo].[vfEqualsNull]([Job])=(0) AND [dbo].[vfEqualsNull]([PhaseGroup])=(0)))
GO
ALTER TABLE [dbo].[bPRMyTimesheetDetail] ADD CONSTRAINT [PK_bPRMyTimesheetDetail] PRIMARY KEY CLUSTERED  ([PRCo], [EntryEmployee], [StartDate], [Sheet], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPRMyTimesheetDetail] WITH NOCHECK ADD CONSTRAINT [FK_bPRMyTimesheetDetail_vSMPayType] FOREIGN KEY ([SMCo], [PayType]) REFERENCES [dbo].[vSMPayType] ([SMCo], [PayType])
GO
ALTER TABLE [dbo].[bPRMyTimesheetDetail] WITH NOCHECK ADD CONSTRAINT [FK_bPRMyTimesheetDetail_vSMWorkOrderScope] FOREIGN KEY ([SMCo], [WorkOrder], [Scope]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope])
GO
