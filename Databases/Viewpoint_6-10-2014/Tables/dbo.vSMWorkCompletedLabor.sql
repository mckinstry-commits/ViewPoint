CREATE TABLE [dbo].[vSMWorkCompletedLabor]
(
[SMWorkCompletedLaborID] [bigint] NOT NULL IDENTITY(1, 1),
[SMWorkCompletedID] [bigint] NOT NULL,
[IsSession] [bit] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [int] NOT NULL,
[WorkCompleted] [int] NOT NULL,
[Scope] [int] NOT NULL,
[Date] [dbo].[bDate] NOT NULL,
[CostQuantity] [dbo].[bHrs] NOT NULL,
[CostRate] [dbo].[bUnitCost] NOT NULL,
[CostTotal] [dbo].[bDollar] NULL,
[ProjCost] [dbo].[bDollar] NULL,
[ActualCost] [dbo].[bDollar] NULL,
[PriceQuantity] [dbo].[bHrs] NULL,
[PayType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[LaborCode] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PRCo] [dbo].[bCompany] NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PREndDate] [dbo].[bDate] NULL,
[PREmployee] [dbo].[bEmployee] NULL,
[PRPaySeq] [tinyint] NULL,
[PRPostSeq] [smallint] NULL,
[PRPostDate] [smalldatetime] NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Shift] [tinyint] NULL,
[SMCostType] [smallint] NULL,
[PhaseGroup] [tinyint] NULL,
[JCCostType] [dbo].[bJCCType] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 02/08/2011
-- Description:	Update or delete a record in PRMyTimesheetDetail when a SMWorkCompletedLabor record is deleted
--              that is linked to PRMyTimesheetDetail
-- Modification: 05/03/2011 EricV Added check for SM UsePRInterface flag
--               08/23/2011 EricV TK-07782 Added SMCostType.
--               09/20/2011 EricV Add check for temporary link to allow delete of posted records.
--               10/07/2011 EricV - Modified to use Scope field from vSMWorkCompletedLabor
--			   02./04/2012 TRL - Added SMJCCostType/SMPhaseGroup
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedLabord]
   ON  [dbo].[vSMWorkCompletedLabor]
   AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @errmsg varchar(255)

	/* Flag to print debug statements */
	DECLARE @PrintDebug bit
	Set @PrintDebug=1
	
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLabord 0'
	/* Check to see any records are linked to the PRMyTimesheetDetail or PRTB table. */
	IF EXISTS(SELECT 1 FROM DELETED
		INNER JOIN SMCO ON SMCO.SMCo=DELETED.SMCo
		LEFT JOIN SMMyTimesheetLink TimesheetLink 
			ON DELETED.SMWorkCompletedID=TimesheetLink.SMWorkCompletedID 
		LEFT JOIN vSMBC PayrollLink
			ON DELETED.SMWorkCompletedID=PayrollLink.SMWorkCompletedID
		WHERE SMCO.UsePRInterface='Y' AND DELETED.IsSession=0
			AND ISNULL(TimesheetLink.UpdateInProgress,0)=0
			AND ISNULL(PayrollLink.UpdateInProgress,0)=0
			AND DELETED.PREndDate IS NULL
		)
	BEGIN	
		/* At least one record in DELETED is new and not from MyTimesheetDetail or PRTB so it needs to be added to PRMyTimesheetDetail */
		DECLARE @EntryEmployee bEmployee, @Employee bEmployee, @PRCo bCompany, @PRGroup bGroup, @OldHours bUnits, @PayType varchar(10), 
				@SMCostType smallint, @SMJCCostType bJCCType, @SMPhaseGroup bGroup,
				@LineType tinyint, @Date smalldatetime, @SMCo bCompany, @WorkOrder int, @Scope int, @PrevPRCo bCompany, @DetailExists bit, 
				@StartDate smalldatetime, @Sheet int, @Seq int, @Day tinyint, @WorkCompleted int, 
				@SMWorkCompletedID int, @Craft bCraft, @Class bClass, @DftEarnCode bEDLCode, @EarnCode bEDLCode, @Shift tinyint,
				@PRPostingCo bCompany, @PRBatchMth bMonth, @PRBatchId int, @PRBatchSeq int,
				@rcode int, @userTechnician varchar(15), @userPRCo bCompany, @userEmployee bEmployee,
				@EnterTimesheetsForThemselves bYN, @EnterTimesheetsForOthers bYN, @TimesheetEditOkay bYN
				
		/* Check to see if the current login has permission to update MyTimesheets */
/* Change to use Employee assigned to Technician as the Entry employee
		exec vspSMGetLoginInfo @SMCo=@SMCo, @PRCo=@userPRCo OUTPUT, @Employee=@userEmployee OUTPUT,
			@Technician=@userTechnician OUTPUT,@EnterTimesheetsForThemselves=@EnterTimesheetsForThemselves OUTPUT, 
			@EnterTimesheetsForOthers=@EnterTimesheetsForOthers OUTPUT
*/
		
		DECLARE SMcursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT bPRMyTimesheetDetail.EntryEmployee, bPRMyTimesheetDetail.Employee, bPRMyTimesheetDetail.PRCo, DELETED.CostQuantity, 
			DELETED.[Date], bPRMyTimesheetDetail.PayType,
			DELETED.SMCostType,DELETED.JCCostType, DELETED.PhaseGroup,
			TimesheetLink.SMCo, TimesheetLink.WorkOrder, DELETED.Scope, TimesheetLink.WorkCompleted, TimesheetLink.SMWorkCompletedID,
			DELETED.Craft, DELETED.Class, DELETED.Shift, bPRMyTimesheetDetail.EarnCode, bPRMyTimesheetDetail.EarnCode, 2 as Type,
			TimesheetLink.StartDate, TimesheetLink.Sheet, TimesheetLink.Seq, PayrollLink.PostingCo, PayrollLink.InUseMth,
			PayrollLink.InUseBatchId, PayrollLink.InUseBatchSeq
		FROM DELETED
		INNER JOIN SMCO ON SMCO.SMCo=DELETED.SMCo
		LEFT JOIN vSMMyTimesheetLink TimesheetLink 
			ON DELETED.SMWorkCompletedID=TimesheetLink.SMWorkCompletedID
		LEFT JOIN bPRMyTimesheetDetail 
			ON TimesheetLink.PRCo=bPRMyTimesheetDetail.PRCo
			AND TimesheetLink.EntryEmployee=bPRMyTimesheetDetail.EntryEmployee
			AND TimesheetLink.StartDate=bPRMyTimesheetDetail.StartDate
			AND TimesheetLink.Sheet=bPRMyTimesheetDetail.Sheet
			AND TimesheetLink.Seq=bPRMyTimesheetDetail.Seq
			AND TimesheetLink.UpdateInProgress=0
		LEFT JOIN vSMBC PayrollLink
			ON DELETED.SMWorkCompletedID=PayrollLink.SMWorkCompletedID
		WHERE SMCO.UsePRInterface='Y' AND DELETED.IsSession=0
			AND ISNULL(TimesheetLink.UpdateInProgress,0)=0
			AND ISNULL(PayrollLink.UpdateInProgress,0)=0
			AND DELETED.PREndDate IS NULL
		
		OPEN SMcursor		
		FETCH NEXT FROM SMcursor INTO @EntryEmployee, @Employee, @PRCo, @OldHours, @Date, @PayType,
			@SMCostType, @SMJCCostType, @SMPhaseGroup,
			@SMCo, @WorkOrder, @Scope, 
			@WorkCompleted, @SMWorkCompletedID, @Craft, @Class, @Shift, @DftEarnCode, @EarnCode, @LineType,
			@StartDate, @Sheet, @Seq, @PRPostingCo, @PRBatchMth, @PRBatchId, @PRBatchSeq
		WHILE @@FETCH_STATUS = 0
		BEGIN
			/* Set the EntryEmployee based on the employee on the labor record. */
			SELECT @userPRCo=@PRCo, @EntryEmployee=@Employee, @EnterTimesheetsForThemselves='Y', 
				@EnterTimesheetsForOthers='Y'

			/* If the hours are not zero then we need to check for permission to delete this record. */
			IF (NOT @OldHours=0)
			BEGIN
				/* Check to see if current user is not allowed to delete the current record. */
				IF (@EnterTimesheetsForOthers='N' AND
					(@EnterTimesheetsForThemselves='N' OR NOT @Employee=@userEmployee OR NOT @PRCo=@userPRCo))
				BEGIN
					SET @errmsg = 'The current login does not have permission to update this Timesheet.'
					CLOSE SMcursor
					DEALLOCATE SMcursor
					GOTO error
				END
				/* Check to see if the current login has permission to edit the employee timesheet */	
/* Don't check this permission anymore
				exec vspSMGetLoginPermission @PRCo=@PRCo, @Employee=@Employee, @TimesheetEditOkay=@TimesheetEditOkay OUTPUT
				IF (@TimesheetEditOkay='N')
				BEGIN
					SET @errmsg = 'The current login does not have permission to update this Timesheet.'
					CLOSE SMcursor
					DEALLOCATE SMcursor
					GOTO error
				END
*/
			END
			
			IF NOT(@StartDate IS NULL)
			BEGIN
				BEGIN TRY
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLabord 1: Calling vspSMMyTimesheetDetailRecordUpdate: '+convert(varchar,@Seq)
					EXEC @rcode = vspSMMyTimesheetDetailRecordUpdate @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, @StartDate=@StartDate,
						@Sheet=@Sheet, @Seq=@Seq, @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @WorkCompleted=@WorkCompleted, @PayType=@PayType,
						@SMCostType=@SMCostType,@SMJCCostType=@SMJCCostType,@SMPhaseGroup=@SMPhaseGroup,
						@Date=@Date, @Hours=0, @OldHours=@OldHours, @SMWorkCompletedID=@SMWorkCompletedID, @Employee=@Employee, @DftEarnCode=@DftEarnCode,
						@Craft=@Craft, @Class=@Class, @EarnCode=@EarnCode, @Shift=@Shift, @Updating=1, @UpdateInProgress=1, @errmsg=@errmsg OUTPUT
					IF (@rcode=1)

					BEGIN
						/* A PRMyTimesheetDetail record could not be updated or created. */
						CLOSE SMcursor
						DEALLOCATE SMcursor
						GOTO error
					END
				END TRY
				BEGIN CATCH
					/* An error occured calling vspSMMyTimesheetDetailRecordUpdate. */
					SET @errmsg = 'Error calling vspSMMyTimesheetDetailRecordUpdate: ' + ERROR_MESSAGE()
					CLOSE SMcursor
					DEALLOCATE SMcursor
					GOTO error
				END CATCH

				/* Now delete the SMMyTimesheetLink record */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLabord 2: Deleting vSMMyTimesheetLink'
				DELETE FROM vSMMyTimesheetLink WHERE SMWorkCompletedID=@SMWorkCompletedID
			END
			ELSE IF NOT(@PRPostingCo IS NULL)
			BEGIN
				/* An error occured deleting PRTB and Link. */
				SET @errmsg = 'Payroll Timecard batch record exists.  Changes must be made in Timecard batch.'
				GOTO error
			END
			
			FETCH NEXT FROM SMcursor INTO @EntryEmployee, @Employee, @PRCo, @OldHours, @Date, @PayType, 
				@SMCostType, @SMJCCostType,@SMPhaseGroup,
				@SMCo, @WorkOrder, @Scope, 
				@WorkCompleted, @SMWorkCompletedID, @Craft, @Class, @Shift, @DftEarnCode, @EarnCode, @LineType,
				@StartDate, @Sheet, @Seq, @PRPostingCo, @PRBatchMth, @PRBatchId, @PRBatchSeq
		END
		CLOSE SMcursor
		DEALLOCATE SMcursor
	END
	ELSE
	BEGIN
		/* Check to see if any records have timecards that are posted. */
		IF EXISTS(SELECT 1 FROM DELETED
			INNER JOIN SMCO ON SMCO.SMCo=DELETED.SMCo
			WHERE SMCO.UsePRInterface='Y' AND DELETED.IsSession=0
			AND NOT DELETED.PREndDate IS NULL)
		BEGIN
			SET @errmsg='Related payroll timecards have been posted.'
			GOTO error
		END	
	END
	RETURN

   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete SM Work Completed Labor!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction	
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 02/08/2011
-- Description:	Create or update a record in PRMyTimesheetDetail when a SMWorkCompletedLabor record is inserted
--              that is not already linked to PRMyTimesheetDetail, PRTB or PRTH
-- Modifications: 03/15/2011 EricV - Added Craft, Class and Shift
--                05/03/2011 EricV - Added check for SM UsePRInterface flag
--                08/23/2011 EricV - Added update to SMCostType.
--                10/07/2011 EricV - Modified to use Scope field from vSMWorkCompletedLabor
--			    02/04/2012 TRL Added SMJCCostType
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedLabori] 
   ON  [dbo].[vSMWorkCompletedLabor]
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	/* Flag to print debug statements */
	DECLARE @PrintDebug bit
	Set @PrintDebug=0
	
	/* Check to see any records are not linked to the PRMyTimesheetDetail, PRTB or PRTH table. */
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED 
		INNER JOIN SMCO ON SMCO.SMCo=INSERTED.SMCo
		INNER JOIN vSMWorkCompleted ON vSMWorkCompleted.SMWorkCompletedID=INSERTED.SMWorkCompletedID
		LEFT JOIN SMMyTimesheetLink TimesheetLink ON vSMWorkCompleted.SMCo=TimesheetLink.SMCo
			AND vSMWorkCompleted.WorkOrder=TimesheetLink.WorkOrder
			AND vSMWorkCompleted.WorkCompleted=TimesheetLink.WorkCompleted
		LEFT JOIN vSMBC PayrollLink ON vSMWorkCompleted.SMCo=PayrollLink.SMCo
			AND vSMWorkCompleted.WorkOrder=PayrollLink.WorkOrder
			AND vSMWorkCompleted.WorkCompleted=PayrollLink.WorkCompleted
		WHERE SMCO.UsePRInterface='Y' AND INSERTED.IsSession=0 AND TimesheetLink.SMCo IS NULL AND PayrollLink.SMCo IS NULL)
	BEGIN
		/* At least one record in Inserted is new and not from MyTimesheetDetail or PRTB so it needs to be added to PRMyTimesheetDetail */
		DECLARE @EntryEmployee bEmployee, @Employee bEmployee, @PRCo bCompany, @PRGroup bGroup, @Hours bUnits, @PayType varchar(10), 
				@SMCostType smallint,@SMJCCostType bJCCType,@SMPhaseGroup bGroup,
				@LineType tinyint, @Date smalldatetime, @TSPRCo bCompany, @StartDate smalldatetime, @Sheet int, @Seq int,
				@SMCo bCompany, @WorkOrder int, @Scope int, @DetailExists bit, @Day tinyint, @WorkCompleted int, @SMBCID bigint,
				@SMWorkCompletedID int, @Craft bCraft, @Class bClass, @DftEarnCode bEDLCode, @EarnCode bEDLCode, @Shift tinyint,
				@rcode int, @errmsg varchar(255), @PREndDate smalldatetime,@userTechnician varchar(15), @userPRCo bCompany,
				@EnterTimesheetsForThemselves bYN, @EnterTimesheetsForOthers bYN, @TimesheetEditOkay bYN, @UsePRInterface bYN
								
		/* Check to see if the current login has permission to update MyTimesheets */
/* Change to use Employee assigned to Technician as the Entry employee
		exec vspSMGetLoginInfo @SMCo=@SMCo, @PRCo=@userPRCo OUTPUT, @Employee=@EntryEmployee OUTPUT,
			@Technician=@userTechnician OUTPUT,
			@EnterTimesheetsForThemselves=@EnterTimesheetsForThemselves  OUTPUT, 
			@EnterTimesheetsForOthers=@EnterTimesheetsForOthers OUTPUT
*/
		
		DECLARE SMcursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT vSMTechnician.Employee, vSMTechnician.PRCo, SMWorkCompleted.CostQuantity, INSERTED.[Date], SMWorkCompleted.PayType, 
			INSERTED.SMCostType,INSERTED.JCCostType,INSERTED.PhaseGroup,
			SMWorkCompleted.SMCo, SMWorkCompleted.WorkOrder, INSERTED.Scope, SMWorkCompleted.WorkCompleted, SMWorkCompleted.SMWorkCompletedID,
			TimesheetLink.StartDate, PayrollLink.SMBCID,
			SMWorkCompleted.Craft, SMWorkCompleted.Class, SMWorkCompleted.Shift, bPREH.EarnCode, vSMPayType.EarnCode, SMWorkCompleted.Type, SMWorkCompleted.PREndDate
		FROM INSERTED
		INNER JOIN SMCO ON SMCO.SMCo=INSERTED.SMCo
		INNER JOIN SMWorkCompleted ON SMWorkCompleted.SMWorkCompletedID=INSERTED.SMWorkCompletedID
		LEFT JOIN vSMPayType ON vSMPayType.SMCo=SMWorkCompleted.SMCo AND vSMPayType.PayType=SMWorkCompleted.PayType
		LEFT JOIN vSMTechnician ON vSMTechnician.SMCo=SMWorkCompleted.SMCo AND vSMTechnician.Technician=SMWorkCompleted.Technician
		LEFT JOIN SMMyTimesheetLink TimesheetLink ON SMWorkCompleted.SMCo=TimesheetLink.SMCo
			AND SMWorkCompleted.WorkOrder=TimesheetLink.WorkOrder AND SMWorkCompleted.Scope=TimesheetLink.Scope
			AND SMWorkCompleted.WorkCompleted=TimesheetLink.WorkCompleted
		LEFT JOIN vSMBC PayrollLink ON SMWorkCompleted.SMCo=PayrollLink.SMCo
			AND SMWorkCompleted.WorkOrder=PayrollLink.WorkOrder
			AND SMWorkCompleted.WorkCompleted=PayrollLink.WorkCompleted
		LEFT JOIN bPREH ON bPREH.PRCo=vSMTechnician.PRCo AND bPREH.Employee=vSMTechnician.Employee
	     WHERE SMCO.UsePRInterface='Y' AND INSERTED.IsSession=0 AND TimesheetLink.SMCo IS NULL AND PayrollLink.SMCo IS NULL
		OPEN SMcursor
		FETCH NEXT FROM SMcursor INTO @Employee, @PRCo, @Hours, @Date, @PayType, 
			@SMCostType, @SMJCCostType, @SMPhaseGroup,
			@SMCo, @WorkOrder, @Scope, @WorkCompleted, @SMWorkCompletedID, 
			@StartDate, @SMBCID, @Craft, @Class, @Shift, @DftEarnCode, @EarnCode, @LineType, @PREndDate
		WHILE @@FETCH_STATUS = 0
		BEGIN
			/* Set the EntryEmployee based on the employee on the labor record. */
			SELECT @userPRCo=@PRCo, @EntryEmployee=@Employee, @EnterTimesheetsForThemselves='Y', 
				@EnterTimesheetsForOthers='Y'

			IF NOT(@StartDate IS NULL) OR NOT(@SMBCID IS NULL) OR NOT(@PREndDate IS NULL)
			BEGIN
				/* Since this record is already linked to an PRMyTimesheetDetail or
					is already linked to a PRTB record or the Payroll timecard has already
					been posted then we should do nothing*/
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLabori 1: Nothing should be done'
				GOTO NextRecord				
			END
			ELSE 
			BEGIN
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLabori 2: Check user permissions'
				/* Check to see if current user is not allowed to delete the current record. */
				IF (@EnterTimesheetsForOthers='N' AND
					(@EnterTimesheetsForThemselves='N' OR NOT @Employee=@EntryEmployee OR NOT @PRCo=@userPRCo))
				BEGIN
					SET @errmsg = 'The current login does not have permission to update this Timesheet.'
					CLOSE SMcursor
					DEALLOCATE SMcursor
					GOTO error
				END
				/* Check to see if the current login has permission to edit the employee timesheet */	
/* Don't check this permission anymore
				exec vspSMGetLoginPermission @PRCo=@PRCo, @Employee=@Employee, @TimesheetEditOkay=@TimesheetEditOkay OUTPUT
				IF (@TimesheetEditOkay='N')
				BEGIN
					SET @errmsg = 'The current login does not have permission to update this Timesheet.'
					CLOSE SMcursor
					DEALLOCATE SMcursor
					GOTO error
				END
*/
				BEGIN TRY
					/* Look for an existing PRMyTimesheet record we can use. If none found then create one. */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLabori 3: Looking for existing PRMyTimesheet record'
					EXEC @rcode = vspSMMyTimesheetRecordFind @PRCo=@PRCo, @Employee=@Employee, @Date=@Date,
						@CreateFlag=1, @EntryEmployee=@EntryEmployee, @Sheet=@Sheet OUTPUT, 
						@StartDate=@StartDate OUTPUT, @errmsg=@errmsg OUTPUT
						
					IF (@rcode=1)
					BEGIN
						/* A PRMyTimesheet record does not exist and couldn't be created. */
						CLOSE SMcursor
						DEALLOCATE SMcursor
						GOTO error
					END
				END TRY
				BEGIN CATCH
					/* An error occured calling vspSMMyTimesheetRecordFind. */
					SET @errmsg = 'Error calling vspSMMyTimesheetRecordFind: ' + ERROR_MESSAGE()
					CLOSE SMcursor
					DEALLOCATE SMcursor
					GOTO error
				END CATCH

				BEGIN TRY			
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLabori 4: Creating PRMyTimesheetDetail record'
					EXEC @rcode = vspSMMyTimesheetDetailRecordUpdate @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, @StartDate=@StartDate,
						@Sheet=@Sheet, @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @WorkCompleted=@WorkCompleted, @PayType=@PayType, 
						@SMCostType=@SMCostType,@SMJCCostType=@SMJCCostType,@SMPhaseGroup=@SMPhaseGroup,
						@Date=@Date, @Hours=@Hours, @SMWorkCompletedID=@SMWorkCompletedID, @Employee=@Employee, @DftEarnCode=@DftEarnCode,
						@Craft=@Craft, @Class=@Class, @EarnCode=@EarnCode, @Shift=@Shift, @UpdateInProgress=1, @errmsg=@errmsg OUTPUT
					IF (@rcode=1)
					BEGIN
						/* A PRMyTimesheetDetail record could not be updated or created. */
						CLOSE SMcursor
						DEALLOCATE SMcursor
						GOTO error
					END
				END TRY
				BEGIN CATCH
					/* An error occured calling vspSMMyTimesheetDetailRecordUpdate. */
					SET @errmsg = 'Error calling vspSMMyTimesheetDetailRecordUpdate: ' + ERROR_MESSAGE()
					CLOSE SMcursor
					DEALLOCATE SMcursor
					GOTO error
				END CATCH
			END
			
NextRecord:
			FETCH NEXT FROM SMcursor INTO @Employee, @PRCo, @Hours, @Date, @PayType, 
				@SMCostType, @SMJCCostType,@SMPhaseGroup,
				@SMCo, @WorkOrder, @Scope, @WorkCompleted, @SMWorkCompletedID, 
				@StartDate, @SMBCID, @Craft, @Class, @Shift, @DftEarnCode, @EarnCode, @LineType, @PREndDate
		END
		
		CLOSE SMcursor
		DEALLOCATE SMcursor
	END
	RETURN

   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert SM Work Completed Labor!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction	
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 02/08/2011
-- Description:	Update PRMyTimesheet when a SMWorkCompletedLabor record is updated that is already linked to a
--              PRMyTimesheetDetail record.  This will require that a different PRMyTimesheet record is needed
--              if the StartDate, Employee or PRCo has changed, and a different PRMyTimesheetDetail record is needed if 
--				the Scope or PayType has changed.
--              02/17/2011 EricV - Add updating of PRTB record is link to it.
--				02/23/2011 EricV - Don't allow changes once related Timecards have been posted.
--              03/15/2011 EricV - Added Craft, Class and Shift
--              05/03/2011 EricV - Added check for SM UsePRInterface flag
--              08/23/2011 EricV - Added update of SMCostType field.
--              10/07/2011 EricV - Modified to use Scope field from vSMWorkCompletedLabor
--			   02./04/2012 TRL - Added SMJCCostType/SMPhaseGroup
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkCompletedLaboru] 
   ON  [dbo].[vSMWorkCompletedLabor]
   AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	
	--The ActualCost is captured during Ledger Update and doesn't need to do any updates so when it is updated the trigger returns right away.
	IF NOT EXISTS(SELECT 1 FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMWorkCompletedLabor') WHERE ColumnsUpdated NOT IN ('ActualCost'))
	BEGIN
		RETURN
	END
	
	/* Flag to print debug statements */
	DECLARE @PrintDebug bit
	Set @PrintDebug=0
	
	/* Don't allow changes that would affect existing timecard records that have been posted. */
	DECLARE @PREndDate smalldatetime, @errmsg varchar(255)
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru ~: Looking.'
					
	IF EXISTS(SELECT 1 FROM INSERTED
		INNER JOIN SMCO ON SMCO.SMCo=INSERTED.SMCo
		INNER JOIN vSMWorkCompleted ON vSMWorkCompleted.SMWorkCompletedID=INSERTED.SMWorkCompletedID
		LEFT JOIN SMMyTimesheetLink TimesheetLink ON vSMWorkCompleted.SMCo=TimesheetLink.SMCo
			AND vSMWorkCompleted.WorkOrder=TimesheetLink.WorkOrder
			AND vSMWorkCompleted.WorkCompleted=TimesheetLink.WorkCompleted
		LEFT JOIN vSMBC PayrollLink ON vSMWorkCompleted.SMCo=PayrollLink.SMCo
			AND vSMWorkCompleted.WorkOrder=PayrollLink.WorkOrder
			AND vSMWorkCompleted.WorkCompleted=PayrollLink.WorkCompleted
		WHERE SMCO.UsePRInterface='Y' AND (INSERTED.IsSession=0 AND ISNULL(TimesheetLink.UpdateInProgress,0)=0) -- Only update PRMyTimesheetDetail for changes to original record.
			AND ISNULL(TimesheetLink.UpdateInProgress,0)=0
			AND ISNULL(PayrollLink.UpdateInProgress,0)=0)
	BEGIN
		/* At least one record in Inserted is new and not from MyTimesheetDetail or PRTB so it needs to be added to PRMyTimesheetDetail */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru $: Looking.'
		DECLARE @EntryEmployee bEmployee, @Employee bEmployee, @PRCo bCompany, @PRGroup bGroup, @Hours bUnits, @PayType varchar(10), @LineType tinyint,
				@Date smalldatetime, @StartDate smalldatetime, @SMCo bCompany, @WorkOrder int, @Scope int, 
				@SMCostType smallint, @SMJCCostType bJCCType, @SMPhaseGroup bGroup,
				@PrevPRCo bCompany, @DetailExists bit, @Day tinyint, @Sheet int, @Seq int, @WorkCompleted int, 
				@SMWorkCompletedID int, @Craft bCraft, @Class bClass, @Shift tinyint, @DftEarnCode bEDLCode, @EarnCode bEDLCode,
				@OldHours bUnits, @OldPayType varchar(10), 
				@OldSMCostType smallint, @OldSMJCCostType bJCCType, @OldSMPhaseGroup bGroup,
				@OldEmployee bEmployee, @OldDate smalldatetime, @OldScope int,
				@TSPRco bCompany, @TSEntryEmployee bEmployee, @TSEmployee bEmployee, @TSStartDate smalldatetime, @TSSheet int, @TSSeq int, @TSDay tinyint,
				@PRPostingCo bCompany, @PRBatchMth bMonth, @PRBatchId int, @PRBatchSeq int, @PRPostDate smalldatetime,
				@rcode int, @SMCursorOpen bit, @userTechnician varchar(15), @userPRCo bCompany, @OldCraft bCraft, @OldClass bClass, @OldShift tinyint,
				@EnterTimesheetsForThemselves bYN, @EnterTimesheetsForOthers bYN, @TimesheetEditOkay bYN
				, @UpdateInProgress bit
				
		/* Check to see if the current login has permission to update MyTimesheets */
/* Change to use Employee assigned to Technician as the Entry employee
		exec vspSMGetLoginInfo @SMCo=@SMCo, @PRCo=@userPRCo OUTPUT, @Employee=@EntryEmployee OUTPUT,
			@Technician=@userTechnician OUTPUT,
			@EnterTimesheetsForThemselves=@EnterTimesheetsForThemselves  OUTPUT, 
			@EnterTimesheetsForOthers=@EnterTimesheetsForOthers OUTPUT
*/

		DECLARE SMcursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT vSMTechnician.Employee, vSMTechnician.PRCo, INSERTED.CostQuantity, INSERTED.[Date], INSERTED.PayType, 
			INSERTED.SMCostType,INSERTED.JCCostType,INSERTED.PhaseGroup,
			SMWorkCompleted.SMCo, SMWorkCompleted.WorkOrder, INSERTED.Scope, SMWorkCompleted.WorkCompleted, INSERTED.SMWorkCompletedID,
			SMWorkCompleted.Craft, SMWorkCompleted.Class, SMWorkCompleted.Shift, bPREH.EarnCode, vSMPayType.EarnCode, SMWorkCompleted.Type,
			DELETED.CostQuantity OldCostQuantity, DELETED.PayType OldPayType, 
			DELETED.SMCostType OldSMCostType,  DELETED.JCCostType OldSMJCCostType,DELETED.PhaseGroup OldSMPhaseGroup,
			CASE WHEN NOT TimesheetLink.StartDate IS NULL THEN TimesheetLink.Employee
				WHEN NOT bPRTB.Co IS NULL THEN bPRTB.Employee
				ELSE SMWorkCompleted.PREmployee END
			OldEmployee,
			DELETED.[Date] OldDate,
			DELETED.Scope OldScope, DELETED.Craft OldCraft, DELETED.Class OldClass, DELETED.Shift OldShift,
			TimesheetLink.PRCo, TimesheetLink.EntryEmployee, TimesheetLink.Employee, TimesheetLink.StartDate, TimesheetLink.Sheet, TimesheetLink.Seq, TimesheetLink.DayNumber,
			PayrollLink.PostingCo, PayrollLink.InUseMth, PayrollLink.InUseBatchId, PayrollLink.InUseBatchSeq, SMWorkCompleted.PREndDate, PayrollLink.UpdateInProgress
		FROM INSERTED
		INNER JOIN SMCO ON SMCO.SMCo=INSERTED.SMCo
		INNER JOIN SMWorkCompleted ON INSERTED.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
		INNER JOIN DELETED ON INSERTED.SMWorkCompletedID = DELETED.SMWorkCompletedID
		LEFT JOIN vSMPayType ON vSMPayType.SMCo=SMWorkCompleted.SMCo 
			AND vSMPayType.PayType=SMWorkCompleted.PayType
		LEFT JOIN vSMTechnician ON vSMTechnician.SMCo=SMWorkCompleted.SMCo 
			AND vSMTechnician.Technician=SMWorkCompleted.Technician
		LEFT JOIN bPREH ON bPREH.PRCo=vSMTechnician.PRCo 
			AND bPREH.Employee=vSMTechnician.Employee
		LEFT JOIN vSMMyTimesheetLink TimesheetLink ON SMWorkCompleted.SMCo=TimesheetLink.SMCo
			AND SMWorkCompleted.WorkOrder=TimesheetLink.WorkOrder
			AND SMWorkCompleted.WorkCompleted=TimesheetLink.WorkCompleted
		LEFT JOIN vSMBC PayrollLink ON SMWorkCompleted.SMWorkCompletedID=PayrollLink.SMWorkCompletedID
		LEFT JOIN bPRTB ON bPRTB.Co=PayrollLink.PostingCo AND bPRTB.Mth=PayrollLink.InUseMth
			AND bPRTB.BatchId=PayrollLink.InUseBatchId AND bPRTB.BatchSeq=PayrollLink.InUseBatchSeq
		WHERE SMCO.UsePRInterface='Y' AND (INSERTED.IsSession=0 AND ISNULL(TimesheetLink.UpdateInProgress,0)=0) -- Only update PRMyTimesheetDetail for changes to original record.
			AND ISNULL(TimesheetLink.UpdateInProgress,0)=0 
			AND ISNULL(PayrollLink.UpdateInProgress,0)=0
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 0: Looking.'
		OPEN SMcursor
		Set @SMCursorOpen=1
		FETCH NEXT FROM SMcursor INTO @Employee, @PRCo, @Hours, @Date, @PayType, 
			@SMCostType, @SMJCCostType,@SMPhaseGroup,
			@SMCo, @WorkOrder, @Scope, @WorkCompleted, @SMWorkCompletedID, 
			@Craft, @Class, @Shift, @DftEarnCode, @EarnCode, @LineType, @OldHours, @OldPayType, 
			@OldSMCostType, @OldSMJCCostType,@OldSMPhaseGroup,
			@OldEmployee, @OldDate, @OldScope, @OldCraft, @OldClass, @OldShift,
			@TSPRco, @TSEntryEmployee, @TSEmployee, @TSStartDate, @TSSheet, @TSSeq, @TSDay, @PRPostingCo, @PRBatchMth, @PRBatchId, @PRBatchSeq,
			@PREndDate, @UpdateInProgress
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			/* Set the EntryEmployee based on the employee on the labor record. */
			SELECT @userPRCo=@PRCo, @EntryEmployee=@Employee, @EnterTimesheetsForThemselves='Y', 
				@EnterTimesheetsForOthers='Y'

			/* Check to see if any fields have been changed that require an update to payroll */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru A: Checking current employee permission.'
IF (@PrintDebug=1) PRINT ' EnterTimesheetsForThemselves='+ISNULL(@EnterTimesheetsForThemselves,'NULL')+' EnterTimesheetsForOthers='+ISNULL(@EnterTimesheetsForOthers,'NULL')+' Employee='+CONVERT(varchar, ISNULL(@Employee,0))+' OldEmployee='+CONVERT(varchar, ISNULL(@OldEmployee,0))+' EntryEmployee='+CONVERT(varchar, ISNULL(@EntryEmployee,0))
IF (@PrintDebug=1) PRINT ' Scope='+CONVERT(varchar, ISNULL(@Scope,0))+' OldScope='+Convert(varchar, ISNULL(@OldScope,0))
			IF(dbo.vfIsEqual(@Employee,@OldEmployee)&dbo.vfIsEqual(@Date,@OldDate)&dbo.vfIsEqual(@PayType,@OldPayType)&dbo.vfIsEqual(@SMCostType,@OldSMCostType)&dbo.vfIsEqual(@Hours,@OldHours)&dbo.vfIsEqual(@Scope,@OldScope)&
				dbo.vfIsEqual(@Craft,@OldCraft)&dbo.vfIsEqual(@Class,@OldClass)&dbo.vfIsEqual(@Shift,@OldShift)=0)
			BEGIN
IF (@PrintDebug=1) 
BEGIN
	IF(dbo.vfIsEqual(@Employee,@OldEmployee)=0) PRINT ' Employee='+CONVERT(varchar, ISNULL(@Employee,0))+' OldEmployee='+Convert(varchar, ISNULL(@OldEmployee,0))
	IF(dbo.vfIsEqual(@Date,@OldDate)=0) PRINT ' Date='+CONVERT(varchar, ISNULL(@Date,0), 101)+' OldDate='+Convert(varchar, ISNULL(@OldDate,0),101)
	IF(dbo.vfIsEqual(@PayType,@OldPayType)=0) PRINT ' PayType='+@PayType+' OldPayType='+@OldPayType
	IF(dbo.vfIsEqual(@SMCostType,@OldSMCostType)=0) PRINT ' SMCostType='+ISNULL(@SMCostType,'')+' OldSMCostType='+ISNULL(@OldSMCostType,'')
	IF(dbo.vfIsEqual(@Hours,@OldHours)=0) PRINT ' Hours='+CONVERT(varchar, ISNULL(@Hours,0))+' OldHours='+Convert(varchar, ISNULL(@OldEmployee,0))
	IF(dbo.vfIsEqual(@Scope,@OldScope)=0) PRINT ' Scope='+CONVERT(varchar, ISNULL(@Scope,0))+' OldScope='+Convert(varchar, ISNULL(@OldScope,0))
	IF(dbo.vfIsEqual(@Craft,@OldCraft)=0) PRINT ' Craft='+@Craft+' OldCraft='+@OldCraft
	IF(dbo.vfIsEqual(@Class,@OldClass)=0) PRINT ' Class='+@Class+' OldClass='+@OldClass
	IF(dbo.vfIsEqual(@Shift,@OldShift)=0) PRINT ' Shift='+@Shift+' OldShift='+@OldShift
END

				/* Check to see if current user is not allowed to update time for other users. */
				IF (@EnterTimesheetsForOthers='N' AND (NOT @Employee=@EntryEmployee OR NOT @PRCo=@userPRCo))
				BEGIN
					SET @errmsg = 'The current login does not have permission to update Timesheets for other users.'
					GOTO error
				END
				/* Check to see if current user is not allowed to update time for the previous user. */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru B: Checking current employee permission.'
				IF (@EnterTimesheetsForOthers='N' AND (NOT @EntryEmployee=@OldEmployee OR NOT @PRCo=@userPRCo))
				BEGIN
					SET @errmsg = 'The current login does not have permission to update Timesheets for other users.'
					GOTO error
				END
				/* Check to see if current user is not allowed to update time for themselves. */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru C: Checking current employee permission.'
				IF (@EnterTimesheetsForThemselves='N' OR (@EnterTimesheetsForOthers='N' AND @EnterTimesheetsForThemselves='Y' AND NOT(@Employee=@EntryEmployee AND @PRCo=@userPRCo)))
				BEGIN
					SET @errmsg = 'The current login does not have permission to update their Timesheets.'
					GOTO error
				END
				/* Check to see if the current login has permission to edit the employee timesheet */	
/* Don't check this permission anymore
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru D: Checking current employee permission. Employee='+CONVERT(varchar, @Employee)
				exec vspSMGetLoginPermission @PRCo=@PRCo, @Employee=@Employee, @TimesheetEditOkay=@TimesheetEditOkay OUTPUT
				IF (@TimesheetEditOkay='N')
				BEGIN
					SET @errmsg = 'The current login does not have permission to update this Timesheet.'
					GOTO error
				END
*/
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru E: Checking payroll status.'
				/* Check to see if the Payroll record has been posted for this record and something has changesd that shouldn't */
				/* @PRPostingCo will not be null if the record is being updated by the PRTB posting process */
				IF (@PREndDate IS NOT NULL AND @PRPostingCo IS NULL)
				BEGIN
					SET @errmsg = 'The Payroll record has been posted. This change is not allowed.'
					GOTO error
				END
				ELSE IF (@PREndDate IS NULL AND @PRPostingCo IS NOT NULL)
				/* Check to see if the Timecard is in a batch */
				BEGIN
					SET @errmsg = 'The Payroll record is in a batch.'
					GOTO error
				END

				/* Check to see if the current login has permission to edit the old employee timesheet */	
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru F: Checking old employee permission. OldEmployee='+CONVERT(varchar, ISNULL(@OldEmployee,0))+' OldHours='+CONVERT(varchar, ISNULL(@OldHours,0))+' EntryEmployee='+CONVERT(varchar, ISNULL(@TSEntryEmployee,0))
/* Don't check this permission anymore
				exec vspSMGetLoginPermission @PRCo=@PRCo, @Employee=@OldEmployee, @TimesheetEditOkay=@TimesheetEditOkay OUTPUT
				IF (@TimesheetEditOkay='N' AND NOT ISNULL(@OldHours,0) = 0)
				BEGIN
					SET @errmsg = 'The current login does not have permission to update this Timesheet.'
					GOTO error
				END
*/				/* Find out if we are updating PRMyTimesheet */
				IF NOT(@TSEntryEmployee IS NULL)
				BEGIN
					BEGIN TRY
						/* Look for an existing PRMyTimesheet record we can use. If none found then create one. */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 1: vspSMMyTimesheetRecordFind'
						EXEC @rcode = vspSMMyTimesheetRecordFind @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, 
						@Employee=@Employee, @Date=@Date, @CreateFlag=1, @Sheet=@Sheet OUTPUT, 
						@StartDate=@StartDate OUTPUT, @errmsg=@errmsg OUTPUT
						
						IF (@rcode=1)
						BEGIN
							/* A PRMyTimesheet record does not exist and couldn't be created. */
							SET @errmsg = 'A PRMyTimesheet record could not be created.'
							GOTO error
						END
					END TRY
					BEGIN CATCH
						/* An error occured calling vspSMMyTimesheetRecordFind. */
						SET @errmsg = 'Error calling vspSMMyTimesheetRecordFind: ' + ERROR_MESSAGE()
						GOTO error
					END CATCH
					/* Determine if the same PRMyTimesheetDetail record can be used */
					IF (dbo.vfIsEqual(@TSEntryEmployee, @EntryEmployee)&dbo.vfIsEqual(@StartDate,@TSStartDate)&dbo.vfIsEqual(@TSPRco,@PRCo)&dbo.vfIsEqual(@Employee,@OldEmployee)&dbo.vfIsEqual(@PayType,@OldPayType)&dbo.vfIsEqual(@SMCostType,@OldSMCostType)&dbo.vfIsEqual(@Scope,@OldScope)&dbo.vfIsEqual(@Date,@OldDate)&dbo.vfIsEqual(@Shift,@OldShift)&dbo.vfIsEqual(@Craft,@OldCraft)&dbo.vfIsEqual(@Class,@OldClass)=0)
					BEGIN
						/* The same PRMyTimesheetDetail record cannot be used so we need to remove the hours from the old PRMyTimesheetDetail record */
						BEGIN TRY
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 2: vspSMMyTimesheetDetailRecordUpdate Seq='+Convert(varchar,isnull(@TSSeq,0))
							EXEC @rcode = vspSMMyTimesheetDetailRecordUpdate @PRCo=@TSPRco, @EntryEmployee=@TSEntryEmployee, @StartDate=@TSStartDate,
								@Sheet=@TSSheet, @Seq=@TSSeq, @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@OldScope, @WorkCompleted=@WorkCompleted, @PayType=@OldPayType, 
								@SMCostType=@OldSMCostType, @SMJCCostType=@OldSMJCCostType,@SMPhaseGroup=@OldSMPhaseGroup,
								@Date=@OldDate, @Hours=0, @OldHours=@OldHours, @SMWorkCompletedID=@SMWorkCompletedID, @Employee=@OldEmployee, @DftEarnCode=@DftEarnCode,
								@Craft=@OldCraft, @Class=@OldClass, @EarnCode=@EarnCode, @Shift=@OldShift, @Updating=1, @UpdateInProgress=1, @errmsg=@errmsg OUTPUT

							/* Now delete the link to PRMyTimesheetDetail day  */
							DELETE vSMMyTimesheetLink WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder AND WorkCompleted=@WorkCompleted

							IF (@rcode=1)
							BEGIN
								/* A PRMyTimesheetDetail record could not be updated or created. */
								GOTO error
							END
						END TRY
						BEGIN CATCH
							/* An error occured calling vspSMMyTimesheetDetailRecordUpdate. */
							SET @errmsg = 'Error calling vspSMMyTimesheetDetailRecordUpdate0: ' + ERROR_MESSAGE()
							GOTO error
						END CATCH
						/* The PRMyTimesheet record may have been deleted if no PRMyTimesheetDetail records for it still exists. */
						BEGIN TRY
							/* Look for an existing PRMyTimesheet record we can use. If none found then create one. */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 3: vspSMMyTimesheetRecordFind'
							EXEC @rcode = vspSMMyTimesheetRecordFind @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, 
								@Employee=@Employee, @Date=@Date, @CreateFlag=1, @Sheet=@Sheet OUTPUT, 
								@StartDate=@StartDate OUTPUT, @errmsg=@errmsg OUTPUT
							
							IF (@rcode=1)
							BEGIN
								/* A PRMyTimesheet record does not exist and couldn't be created. */
								GOTO error
							END
						END TRY
						BEGIN CATCH
							/* An error occured calling vspSMMyTimesheetRecordFind. */
							SET @errmsg = 'Error calling vspSMMyTimesheetRecordFind: ' + ERROR_MESSAGE()
							GOTO error
						END CATCH
						
						/* Now insert the new PRMyTimesheetDetail record. */
						BEGIN TRY			
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 4: vspSMMyTimesheetDetailRecordUpdate'
							EXEC @rcode = vspSMMyTimesheetDetailRecordUpdate @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, @StartDate=@StartDate,
								@Sheet=@Sheet, @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @WorkCompleted=@WorkCompleted, @PayType=@PayType, 
								@SMCostType=@SMCostType,@SMJCCostType=@SMJCCostType,@SMPhaseGroup=@SMPhaseGroup,
								@Date=@Date, @Hours=@Hours, @SMWorkCompletedID=@SMWorkCompletedID, @Employee=@Employee, @DftEarnCode=@DftEarnCode,
								@Craft=@Craft, @Class=@Class, @EarnCode=@EarnCode, @Shift=@Shift, @UpdateInProgress=1, @errmsg=@errmsg OUTPUT
							
							IF (@rcode=1)
							BEGIN
								/* A PRMyTimesheetDetail record could not be updated or created. */
								GOTO error
							END
						END TRY
						BEGIN CATCH
							/* An error occured calling vspSMMyTimesheetDetailRecordUpdate. */
							SET @errmsg = 'Error calling vspSMMyTimesheetDetailRecordUpdate1: ' + ERROR_MESSAGE()
							GOTO error
						END CATCH
					END
					ELSE
					BEGIN
						/* Now we can update the PRMyTimesheetDetail record. */
						BEGIN TRY
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 5: vspSMMyTimesheetDetailRecordUpdate'
							EXEC @rcode = vspSMMyTimesheetDetailRecordUpdate @PRCo=@TSPRco, @EntryEmployee=@TSEntryEmployee, @StartDate=@TSStartDate,
								@Sheet=@TSSheet, @Seq=@TSSeq, @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@OldScope, @WorkCompleted=@WorkCompleted, @PayType=@OldPayType, 
								@SMCostType=@OldSMCostType,@SMJCCostType=@SMJCCostType,@SMPhaseGroup=@SMPhaseGroup,
								@Date=@Date, @Hours=@Hours, @OldHours=@OldHours, @SMWorkCompletedID=@SMWorkCompletedID, @Employee=@TSEmployee, @DftEarnCode=@DftEarnCode,
								@Craft=@OldCraft, @Class=@OldClass, @EarnCode=@EarnCode, @Shift=@OldShift, @Updating=1, @UpdateInProgress=1, @errmsg=@errmsg OUTPUT
						
							IF (@rcode=1)
							BEGIN
								/* A PRMyTimesheetDetail record could not be updated or created. */
								GOTO error
							END
						END TRY
						BEGIN CATCH
							/* An error occured calling vspSMMyTimesheetDetailRecordUpdate. */
							SET @errmsg = 'Error calling vspSMMyTimesheetDetailRecordUpdate2: ' + ERROR_MESSAGE()
							GOTO error
						END CATCH
					END
				END
				ELSE IF ISNULL(@OldHours,0)=0
				BEGIN
					/* The previous hours were zero so a new timesheet needs to be created. */
					BEGIN TRY
						/* Look for an existing PRMyTimesheet record we can use. If none found then create one. */
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 6: Looking for existing PRMyTimesheet record'
						EXEC @rcode = vspSMMyTimesheetRecordFind @PRCo=@PRCo, @Employee=@Employee, @Date=@Date,
							@CreateFlag=1, @EntryEmployee=@EntryEmployee, @Sheet=@Sheet OUTPUT, 
							@StartDate=@StartDate OUTPUT, @errmsg=@errmsg OUTPUT
							
						IF (@rcode=1)
						BEGIN
							/* A PRMyTimesheet record does not exist and couldn't be created. */
							SET @errmsg = 'Error when calling vspSMMyTimesheetRecordFind: ' + @errmsg
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 6.1: '+@errmsg
							GOTO error
						END
					END TRY
					BEGIN CATCH
						/* An error occured calling vspSMMyTimesheetRecordFind. */
						SET @errmsg = 'Error calling vspSMMyTimesheetRecordFind: ' + ERROR_MESSAGE()
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 6.2: '+@errmsg
						GOTO error
					END CATCH

					BEGIN TRY			
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 7: Creating PRMyTimesheetDetail record'
						EXEC @rcode = vspSMMyTimesheetDetailRecordUpdate @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, @StartDate=@StartDate,
							@Sheet=@Sheet, @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @WorkCompleted=@WorkCompleted, @PayType=@PayType,
							 @SMCostType=@SMCostType,@SMJCCostType=@SMJCCostType,@SMPhaseGroup=@SMPhaseGroup,
							@Date=@Date, @Hours=@Hours, @SMWorkCompletedID=@SMWorkCompletedID, @Employee=@Employee, @DftEarnCode=@DftEarnCode,
							@Craft=@Craft, @Class=@Class, @EarnCode=@EarnCode, @Shift=@Shift, @UpdateInProgress=1, @errmsg=@errmsg OUTPUT
						IF (@rcode=1)
						BEGIN
							/* A PRMyTimesheetDetail record could not be updated or created. */
							SET @errmsg = 'Error when calling vspSMMyTimesheetDetailRecordUpdate: ' + @errmsg
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 7.1: '+@errmsg
							GOTO error
						END
					END TRY
					BEGIN CATCH
						/* An error occured calling vspSMMyTimesheetDetailRecordUpdate. */
						SET @errmsg = 'Error calling vspSMMyTimesheetDetailRecordUpdate: ' + ERROR_MESSAGE()
IF (@PrintDebug=1) PRINT 'vtSMWorkCompletedLaboru 7.1: '+@errmsg
						GOTO error
					END CATCH
						
				END
				ELSE IF NOT(@PRBatchMth IS NULL) AND @UpdateInProgress=0
				BEGIN
					SET @errmsg = 'Payroll Timecard batch record exists.  Changes must be made in Timecard batch.'
					GOTO error
				END
			END
			
			FETCH NEXT FROM SMcursor INTO @Employee, @PRCo, @Hours, @Date, @PayType, 
				@SMCostType, @SMJCCostType,@SMPhaseGroup,
				@SMCo, @WorkOrder, @Scope, @WorkCompleted, @SMWorkCompletedID, 
				@Craft, @Class, @Shift, @DftEarnCode, @EarnCode, @LineType, @OldHours, @OldPayType, 
				@OldSMCostType, @OldSMJCCostType,@OldSMPhaseGroup,
				@OldEmployee, @OldDate, @OldScope, @OldCraft, @OldClass, @OldShift,
				@TSPRco, @TSEntryEmployee, @TSEmployee, @TSStartDate, @TSSheet, @TSSeq, @TSDay, @PRPostingCo, @PRBatchMth, @PRBatchId, @PRBatchSeq,
				@PREndDate, @UpdateInProgress
		END

		IF (@SMCursorOpen=1)
		BEGIN
			CLOSE SMcursor
			DEALLOCATE SMcursor
			SET @SMCursorOpen=0
		END
	END
	RETURN

   error:
	IF (@SMCursorOpen=1)
	BEGIN
		CLOSE SMcursor
		DEALLOCATE SMcursor
		SET @SMCursorOpen=0
	END
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update SM Work Completed Labor!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompletedLabor_Audit_Delete ON dbo.vSMWorkCompletedLabor
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditCreateAuditTriggers

 BEGIN TRY 

							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ActualCost' , 
								CONVERT(VARCHAR(MAX), deleted.[ActualCost]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Class' , 
								CONVERT(VARCHAR(MAX), deleted.[Class]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostQuantity' , 
								CONVERT(VARCHAR(MAX), deleted.[CostQuantity]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostRate' , 
								CONVERT(VARCHAR(MAX), deleted.[CostRate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CostTotal' , 
								CONVERT(VARCHAR(MAX), deleted.[CostTotal]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Craft' , 
								CONVERT(VARCHAR(MAX), deleted.[Craft]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Date' , 
								CONVERT(VARCHAR(MAX), deleted.[Date]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Description' , 
								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'IsSession' , 
								CONVERT(VARCHAR(MAX), deleted.[IsSession]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'JCCostType' , 
								CONVERT(VARCHAR(MAX), deleted.[JCCostType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'LaborCode' , 
								CONVERT(VARCHAR(MAX), deleted.[LaborCode]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRCo' , 
								CONVERT(VARCHAR(MAX), deleted.[PRCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PREmployee' , 
								CONVERT(VARCHAR(MAX), deleted.[PREmployee]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PREndDate' , 
								CONVERT(VARCHAR(MAX), deleted.[PREndDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[PRGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRPaySeq' , 
								CONVERT(VARCHAR(MAX), deleted.[PRPaySeq]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRPostDate' , 
								CONVERT(VARCHAR(MAX), deleted.[PRPostDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PRPostSeq' , 
								CONVERT(VARCHAR(MAX), deleted.[PRPostSeq]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PayType' , 
								CONVERT(VARCHAR(MAX), deleted.[PayType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PhaseGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[PhaseGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PriceQuantity' , 
								CONVERT(VARCHAR(MAX), deleted.[PriceQuantity]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ProjCost' , 
								CONVERT(VARCHAR(MAX), deleted.[ProjCost]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCostType' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCostType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMWorkCompletedID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMWorkCompletedLaborID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedLaborID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Scope' , 
								CONVERT(VARCHAR(MAX), deleted.[Scope]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Shift' , 
								CONVERT(VARCHAR(MAX), deleted.[Shift]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkCompleted' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkCompleted]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
								
							SELECT
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(deleted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(deleted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkOrder' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkOrder]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							
 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompletedLabor_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompletedLabor_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompletedLabor_Audit_Insert ON dbo.vSMWorkCompletedLabor
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

-- log additions to the ActualCost column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ActualCost' , 
								NULL , 
								[ActualCost] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Class column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Class' , 
								NULL , 
								[Class] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostQuantity column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostQuantity' , 
								NULL , 
								[CostQuantity] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostRate column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostRate' , 
								NULL , 
								[CostRate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CostTotal column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CostTotal' , 
								NULL , 
								[CostTotal] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Craft column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Craft' , 
								NULL , 
								[Craft] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Date column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Date' , 
								NULL , 
								[Date] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Description column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Description' , 
								NULL , 
								[Description] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the IsSession column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'IsSession' , 
								NULL , 
								[IsSession] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the JCCostType column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'JCCostType' , 
								NULL , 
								[JCCostType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the LaborCode column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'LaborCode' , 
								NULL , 
								[LaborCode] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRCo column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRCo' , 
								NULL , 
								[PRCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PREmployee column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PREmployee' , 
								NULL , 
								[PREmployee] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PREndDate column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PREndDate' , 
								NULL , 
								[PREndDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRGroup column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRGroup' , 
								NULL , 
								[PRGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRPaySeq column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRPaySeq' , 
								NULL , 
								[PRPaySeq] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRPostDate column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRPostDate' , 
								NULL , 
								[PRPostDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PRPostSeq column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PRPostSeq' , 
								NULL , 
								[PRPostSeq] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PayType column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PayType' , 
								NULL , 
								[PayType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PhaseGroup column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PhaseGroup' , 
								NULL , 
								[PhaseGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PriceQuantity column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PriceQuantity' , 
								NULL , 
								[PriceQuantity] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the ProjCost column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ProjCost' , 
								NULL , 
								[ProjCost] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMCo column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								[SMCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMCostType column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCostType' , 
								NULL , 
								[SMCostType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMWorkCompletedID column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMWorkCompletedID' , 
								NULL , 
								[SMWorkCompletedID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMWorkCompletedLaborID column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMWorkCompletedLaborID' , 
								NULL , 
								[SMWorkCompletedLaborID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Scope column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Scope' , 
								NULL , 
								[Scope] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Shift column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Shift' , 
								NULL , 
								[Shift] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the WorkCompleted column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkCompleted' , 
								NULL , 
								[WorkCompleted] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the WorkOrder column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
							
							SELECT 
								'vSMWorkCompletedLabor' , 
								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkOrder' , 
								NULL , 
								[WorkOrder] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompletedLabor_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompletedLabor_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkCompletedLabor_Audit_Update ON dbo.vSMWorkCompletedLabor
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 

							IF UPDATE([ActualCost])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ActualCost' , 								CONVERT(VARCHAR(MAX), deleted.[ActualCost]) , 								CONVERT(VARCHAR(MAX), inserted.[ActualCost]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[ActualCost] <> deleted.[ActualCost]) OR (inserted.[ActualCost] IS NULL AND deleted.[ActualCost] IS NOT NULL) OR (inserted.[ActualCost] IS NOT NULL AND deleted.[ActualCost] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Class])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Class' , 								CONVERT(VARCHAR(MAX), deleted.[Class]) , 								CONVERT(VARCHAR(MAX), inserted.[Class]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[Class] <> deleted.[Class]) OR (inserted.[Class] IS NULL AND deleted.[Class] IS NOT NULL) OR (inserted.[Class] IS NOT NULL AND deleted.[Class] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostQuantity])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostQuantity' , 								CONVERT(VARCHAR(MAX), deleted.[CostQuantity]) , 								CONVERT(VARCHAR(MAX), inserted.[CostQuantity]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[CostQuantity] <> deleted.[CostQuantity]) OR (inserted.[CostQuantity] IS NULL AND deleted.[CostQuantity] IS NOT NULL) OR (inserted.[CostQuantity] IS NOT NULL AND deleted.[CostQuantity] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostRate])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostRate' , 								CONVERT(VARCHAR(MAX), deleted.[CostRate]) , 								CONVERT(VARCHAR(MAX), inserted.[CostRate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[CostRate] <> deleted.[CostRate]) OR (inserted.[CostRate] IS NULL AND deleted.[CostRate] IS NOT NULL) OR (inserted.[CostRate] IS NOT NULL AND deleted.[CostRate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CostTotal])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CostTotal' , 								CONVERT(VARCHAR(MAX), deleted.[CostTotal]) , 								CONVERT(VARCHAR(MAX), inserted.[CostTotal]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[CostTotal] <> deleted.[CostTotal]) OR (inserted.[CostTotal] IS NULL AND deleted.[CostTotal] IS NOT NULL) OR (inserted.[CostTotal] IS NOT NULL AND deleted.[CostTotal] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Craft])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Craft' , 								CONVERT(VARCHAR(MAX), deleted.[Craft]) , 								CONVERT(VARCHAR(MAX), inserted.[Craft]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[Craft] <> deleted.[Craft]) OR (inserted.[Craft] IS NULL AND deleted.[Craft] IS NOT NULL) OR (inserted.[Craft] IS NOT NULL AND deleted.[Craft] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Date])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Date' , 								CONVERT(VARCHAR(MAX), deleted.[Date]) , 								CONVERT(VARCHAR(MAX), inserted.[Date]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[Date] <> deleted.[Date]) OR (inserted.[Date] IS NULL AND deleted.[Date] IS NOT NULL) OR (inserted.[Date] IS NOT NULL AND deleted.[Date] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Description])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Description' , 								CONVERT(VARCHAR(MAX), deleted.[Description]) , 								CONVERT(VARCHAR(MAX), inserted.[Description]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([IsSession])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'IsSession' , 								CONVERT(VARCHAR(MAX), deleted.[IsSession]) , 								CONVERT(VARCHAR(MAX), inserted.[IsSession]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[IsSession] <> deleted.[IsSession]) OR (inserted.[IsSession] IS NULL AND deleted.[IsSession] IS NOT NULL) OR (inserted.[IsSession] IS NOT NULL AND deleted.[IsSession] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([JCCostType])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'JCCostType' , 								CONVERT(VARCHAR(MAX), deleted.[JCCostType]) , 								CONVERT(VARCHAR(MAX), inserted.[JCCostType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[JCCostType] <> deleted.[JCCostType]) OR (inserted.[JCCostType] IS NULL AND deleted.[JCCostType] IS NOT NULL) OR (inserted.[JCCostType] IS NOT NULL AND deleted.[JCCostType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([LaborCode])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'LaborCode' , 								CONVERT(VARCHAR(MAX), deleted.[LaborCode]) , 								CONVERT(VARCHAR(MAX), inserted.[LaborCode]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[LaborCode] <> deleted.[LaborCode]) OR (inserted.[LaborCode] IS NULL AND deleted.[LaborCode] IS NOT NULL) OR (inserted.[LaborCode] IS NOT NULL AND deleted.[LaborCode] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRCo])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRCo' , 								CONVERT(VARCHAR(MAX), deleted.[PRCo]) , 								CONVERT(VARCHAR(MAX), inserted.[PRCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PRCo] <> deleted.[PRCo]) OR (inserted.[PRCo] IS NULL AND deleted.[PRCo] IS NOT NULL) OR (inserted.[PRCo] IS NOT NULL AND deleted.[PRCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PREmployee])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PREmployee' , 								CONVERT(VARCHAR(MAX), deleted.[PREmployee]) , 								CONVERT(VARCHAR(MAX), inserted.[PREmployee]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PREmployee] <> deleted.[PREmployee]) OR (inserted.[PREmployee] IS NULL AND deleted.[PREmployee] IS NOT NULL) OR (inserted.[PREmployee] IS NOT NULL AND deleted.[PREmployee] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PREndDate])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PREndDate' , 								CONVERT(VARCHAR(MAX), deleted.[PREndDate]) , 								CONVERT(VARCHAR(MAX), inserted.[PREndDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PREndDate] <> deleted.[PREndDate]) OR (inserted.[PREndDate] IS NULL AND deleted.[PREndDate] IS NOT NULL) OR (inserted.[PREndDate] IS NOT NULL AND deleted.[PREndDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRGroup])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRGroup' , 								CONVERT(VARCHAR(MAX), deleted.[PRGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[PRGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PRGroup] <> deleted.[PRGroup]) OR (inserted.[PRGroup] IS NULL AND deleted.[PRGroup] IS NOT NULL) OR (inserted.[PRGroup] IS NOT NULL AND deleted.[PRGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRPaySeq])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRPaySeq' , 								CONVERT(VARCHAR(MAX), deleted.[PRPaySeq]) , 								CONVERT(VARCHAR(MAX), inserted.[PRPaySeq]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PRPaySeq] <> deleted.[PRPaySeq]) OR (inserted.[PRPaySeq] IS NULL AND deleted.[PRPaySeq] IS NOT NULL) OR (inserted.[PRPaySeq] IS NOT NULL AND deleted.[PRPaySeq] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRPostDate])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRPostDate' , 								CONVERT(VARCHAR(MAX), deleted.[PRPostDate]) , 								CONVERT(VARCHAR(MAX), inserted.[PRPostDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PRPostDate] <> deleted.[PRPostDate]) OR (inserted.[PRPostDate] IS NULL AND deleted.[PRPostDate] IS NOT NULL) OR (inserted.[PRPostDate] IS NOT NULL AND deleted.[PRPostDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PRPostSeq])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PRPostSeq' , 								CONVERT(VARCHAR(MAX), deleted.[PRPostSeq]) , 								CONVERT(VARCHAR(MAX), inserted.[PRPostSeq]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PRPostSeq] <> deleted.[PRPostSeq]) OR (inserted.[PRPostSeq] IS NULL AND deleted.[PRPostSeq] IS NOT NULL) OR (inserted.[PRPostSeq] IS NOT NULL AND deleted.[PRPostSeq] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PayType])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PayType' , 								CONVERT(VARCHAR(MAX), deleted.[PayType]) , 								CONVERT(VARCHAR(MAX), inserted.[PayType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PayType] <> deleted.[PayType]) OR (inserted.[PayType] IS NULL AND deleted.[PayType] IS NOT NULL) OR (inserted.[PayType] IS NOT NULL AND deleted.[PayType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PhaseGroup])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PhaseGroup' , 								CONVERT(VARCHAR(MAX), deleted.[PhaseGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[PhaseGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PhaseGroup] <> deleted.[PhaseGroup]) OR (inserted.[PhaseGroup] IS NULL AND deleted.[PhaseGroup] IS NOT NULL) OR (inserted.[PhaseGroup] IS NOT NULL AND deleted.[PhaseGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PriceQuantity])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PriceQuantity' , 								CONVERT(VARCHAR(MAX), deleted.[PriceQuantity]) , 								CONVERT(VARCHAR(MAX), inserted.[PriceQuantity]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[PriceQuantity] <> deleted.[PriceQuantity]) OR (inserted.[PriceQuantity] IS NULL AND deleted.[PriceQuantity] IS NOT NULL) OR (inserted.[PriceQuantity] IS NOT NULL AND deleted.[PriceQuantity] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([ProjCost])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ProjCost' , 								CONVERT(VARCHAR(MAX), deleted.[ProjCost]) , 								CONVERT(VARCHAR(MAX), inserted.[ProjCost]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[ProjCost] <> deleted.[ProjCost]) OR (inserted.[ProjCost] IS NULL AND deleted.[ProjCost] IS NOT NULL) OR (inserted.[ProjCost] IS NOT NULL AND deleted.[ProjCost] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMCo])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMCostType])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCostType' , 								CONVERT(VARCHAR(MAX), deleted.[SMCostType]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCostType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[SMCostType] <> deleted.[SMCostType]) OR (inserted.[SMCostType] IS NULL AND deleted.[SMCostType] IS NOT NULL) OR (inserted.[SMCostType] IS NOT NULL AND deleted.[SMCostType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMWorkCompletedID])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkCompletedID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkCompletedID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[SMWorkCompletedID] <> deleted.[SMWorkCompletedID]) OR (inserted.[SMWorkCompletedID] IS NULL AND deleted.[SMWorkCompletedID] IS NOT NULL) OR (inserted.[SMWorkCompletedID] IS NOT NULL AND deleted.[SMWorkCompletedID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMWorkCompletedLaborID])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkCompletedLaborID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkCompletedLaborID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkCompletedLaborID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[SMWorkCompletedLaborID] <> deleted.[SMWorkCompletedLaborID]) OR (inserted.[SMWorkCompletedLaborID] IS NULL AND deleted.[SMWorkCompletedLaborID] IS NOT NULL) OR (inserted.[SMWorkCompletedLaborID] IS NOT NULL AND deleted.[SMWorkCompletedLaborID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Scope])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Scope' , 								CONVERT(VARCHAR(MAX), deleted.[Scope]) , 								CONVERT(VARCHAR(MAX), inserted.[Scope]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[Scope] <> deleted.[Scope]) OR (inserted.[Scope] IS NULL AND deleted.[Scope] IS NOT NULL) OR (inserted.[Scope] IS NOT NULL AND deleted.[Scope] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Shift])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Shift' , 								CONVERT(VARCHAR(MAX), deleted.[Shift]) , 								CONVERT(VARCHAR(MAX), inserted.[Shift]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[Shift] <> deleted.[Shift]) OR (inserted.[Shift] IS NULL AND deleted.[Shift] IS NOT NULL) OR (inserted.[Shift] IS NOT NULL AND deleted.[Shift] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([WorkCompleted])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkCompleted' , 								CONVERT(VARCHAR(MAX), deleted.[WorkCompleted]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkCompleted]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[WorkCompleted] <> deleted.[WorkCompleted]) OR (inserted.[WorkCompleted] IS NULL AND deleted.[WorkCompleted] IS NOT NULL) OR (inserted.[WorkCompleted] IS NOT NULL AND deleted.[WorkCompleted] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([WorkOrder])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
								
								SELECT 							'vSMWorkCompletedLabor' , 								'<KeyString IsSession = "' + REPLACE(CAST(ISNULL(inserted.[IsSession],'') AS VARCHAR(MAX)),'"', '&quot;') + '" SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkCompleted = "' + REPLACE(CAST(ISNULL(inserted.[WorkCompleted],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkOrder' , 								CONVERT(VARCHAR(MAX), deleted.[WorkOrder]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkOrder]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkCompletedLaborID] = deleted.[SMWorkCompletedLaborID] 
									AND ((inserted.[WorkOrder] <> deleted.[WorkOrder]) OR (inserted.[WorkOrder] IS NULL AND deleted.[WorkOrder] IS NOT NULL) OR (inserted.[WorkOrder] IS NOT NULL AND deleted.[WorkOrder] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 



 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkCompletedLabor_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkCompletedLabor_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] ADD CONSTRAINT [PK_vSMWorkCompletedLabor] PRIMARY KEY CLUSTERED  ([SMWorkCompletedLaborID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] ADD CONSTRAINT [IX_vSMWorkCompletedLabor_SMWorkCompletedID_IsSession] UNIQUE NONCLUSTERED  ([SMWorkCompletedID], [IsSession]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] ADD CONSTRAINT [IX_vSMWorkCompletedLabor_WorkOrder_WorkCompleted_SMCo_IsSession] UNIQUE NONCLUSTERED  ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedLabor_bJCCT] FOREIGN KEY ([PhaseGroup], [JCCostType]) REFERENCES [dbo].[bJCCT] ([PhaseGroup], [CostType])
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedLabor_vSMLaborCode] FOREIGN KEY ([SMCo], [LaborCode]) REFERENCES [dbo].[vSMLaborCode] ([SMCo], [LaborCode])
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedLabor_vSMPayType] FOREIGN KEY ([SMCo], [PayType]) REFERENCES [dbo].[vSMPayType] ([SMCo], [PayType])
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedLabor_vSMWorkCompleted] FOREIGN KEY ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted]) REFERENCES [dbo].[vSMWorkCompleted] ([SMWorkCompletedID], [SMCo], [WorkOrder], [WorkCompleted])
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkCompletedLabor_vSMWorkCompletedDetail] FOREIGN KEY ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) REFERENCES [dbo].[vSMWorkCompletedDetail] ([WorkOrder], [WorkCompleted], [SMCo], [IsSession]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] NOCHECK CONSTRAINT [FK_vSMWorkCompletedLabor_bJCCT]
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] NOCHECK CONSTRAINT [FK_vSMWorkCompletedLabor_vSMLaborCode]
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] NOCHECK CONSTRAINT [FK_vSMWorkCompletedLabor_vSMPayType]
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] NOCHECK CONSTRAINT [FK_vSMWorkCompletedLabor_vSMWorkCompleted]
GO
ALTER TABLE [dbo].[vSMWorkCompletedLabor] NOCHECK CONSTRAINT [FK_vSMWorkCompletedLabor_vSMWorkCompletedDetail]
GO
