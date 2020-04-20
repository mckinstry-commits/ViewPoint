SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 02/08/2011
-- Description:	Update existing or create new SMMyTimesheetDetail record for SM.
-- Modifications: 03/15/2011 EricV - Added Craft, Class and Shift
--				EN 6/6/11 D-02028 when insert into PRMyTimesheetDetail, plug CreatedOn date with no timestamp by using dbo.vfDateOnly() rather than GETDATE()
--              EricV 08/23/11 - TK-07782 Added SMCostType parameter.
--			    TRL 02/04/12 - TK-12277 Added SMJCCostType/SMPhaseGroup parameters
--              EricV 05/25/12 TK-14637 Added update of JCCo, Job and Phase when creating PRMyTimesheetDetail record.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMMyTimesheetDetailRecordUpdate]
	@PRCo bCompany, @EntryEmployee bEmployee, @StartDate smalldatetime, @Sheet int, @Seq int = NULL,
	@SMCo bCompany, @WorkOrder int, @Scope int, @WorkCompleted int, @PayType varchar(15), 
	@SMCostType smallint,@SMJCCostType bJCCType, @SMPhaseGroup bGroup, 
	@Date smalldatetime, @Hours bUnits, @DftEarnCode bEDLCode=NULL, @Updating bit=0, @OldHours bUnits=NULL,
	@SMWorkCompletedID bigint, @Employee bEmployee, @Craft bCraft = NULL, @Class bClass = NULL, 
	@EarnCode bEDLCode=NULL, @Shift tinyint=NULL, @UpdateInProgress bit=0, @errmsg varchar(255)=NULL OUTPUT
AS
BEGIN
	/* The @Updating flag indicates that this is an update to an existing record.
	
		If @Updating=0 then a record with hours>0 for the day specified will not be updated and a new 
		record will be inserted.
		
		If @Updating=1 then an existing record will be located and the hours for the day specified will
		be updated.  After the update the PRMyTimesheetDetail record will be deleted if the hours for
		every weekday is zero or null.  The PRMyTimesheet record will be deleted if all of the associated
		PRMyTimesheetDetail records have been deleted.
	*/
	/* Flag to print debug statements */
	DECLARE @PrintDebug bit
	Set @PrintDebug=0
	
	SET NOCOUNT ON;
	
	DECLARE @Day tinyint, @DetailExists bit, @NextSeq int, @DayOne bHrs, @DayTwo bHrs, @DayThree bHrs, 
	@DayFour bHrs, @DayFive bHrs, @DaySix bHrs, @DaySeven bHrs, @LineType char(1), @TimesheetStatus int,
	@JCCo bCompany, @Job bJob, @Phase bPhase
	
	/* Set the PR My Time Sheet Line Type For an SM Work Order and get job fields form scope */
	SELECT @LineType='S', @JCCo=JCCo, @Job=Job, @Phase=Phase FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@WorkOrder AND Scope=@Scope
	
	/* Set the Day index based on the StartDate */
	SELECT @Day=DATEDIFF(d, @StartDate, @Date)+1
	
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetailRecordUpdate 1: Updating='+convert(varchar,ISNULL(@Updating,0))+' UpdateInProgress='+Convert(varchar, ISNULL(@UpdateInProgress,0))+' EntryEmployee='+Convert(varchar, isnull(@EntryEmployee,0))+' StartDate='+Convert(varchar, @StartDate,101)+' Seq='+Convert(Varchar,ISNULL(@Seq,0))+' Day='+CONVERT(varchar,ISNULL(@Day,0))+' Employee='+Convert(varchar, isnull(@Employee,0))
IF (@PrintDebug=1) PRINT ' Date='+COnvert(varchar, @Date,101)+' OldHours='+Convert(varchar,isnull(@OldHours,0))
IF (@PrintDebug=1) PRINT ' Craft='+ISNULL(@Craft,'NULL')+' Class='+ISNULL(@Class,'NULL')+' Shift='+CONVERT(varchar, ISNULL(@Shift,0))
IF (@PrintDebug=1) PRINT +' SMCostType='+CONVERT(varchar, ISNULL(@SMCostType,0))+' SMPhaseGroup='+CONVERT(varchar, ISNULL(@SMPhaseGroup,0))+' SMJCCostType='+CONVERT(varchar, ISNULL(@SMJCCostType,0))
	/* Look for the existing PRMyTimesheetDetail record. If this is an update then the Hours in the record must match the OldHours.*/
	SET @DetailExists=0;
	SELECT @DetailExists=1, @Seq=Seq, @DayOne=DayOne, @DayTwo=DayTwo, @DayThree=DayThree, @DayFour=DayFour, 
			@DayFive=DayFive, @DaySix=DaySix, @DaySeven=DaySeven
		FROM PRMyTimesheetDetail
		WHERE dbo.vfIsEqual(PRCo,@PRCo)&dbo.vfIsEqual(EntryEmployee,@EntryEmployee)&dbo.vfIsEqual(StartDate,@StartDate)&dbo.vfIsEqual(Sheet,@Sheet)&
			dbo.vfIsEqual(SMCo,@SMCo)&dbo.vfIsEqual(WorkOrder,@WorkOrder)&dbo.vfIsEqual(Scope,@Scope)&dbo.vfIsEqual(PayType,@PayType)&
			dbo.vfIsEqual(SMCostType,@SMCostType)&dbo.vfIsEqual(SMJCCostType,@SMJCCostType)&
			dbo.vfIsEqual(Employee,@Employee)&dbo.vfIsEqual(Craft,@Craft)&dbo.vfIsEqual(Class,@Class)&dbo.vfIsEqual(Shift,@Shift)=1
			AND
			(
				(@Updating=0 AND 
					(ISNULL(CASE WHEN @Day=1 THEN DayOne
					 WHEN @Day=2 Then DayTwo
					 WHEN @Day=3 Then DayThree
					 WHEN @Day=4 Then DayFour
					 WHEN @Day=5 Then DayFive
					 WHEN @Day=6 Then DaySix
					 WHEN @Day=7 Then DaySeven END,0)=0
					)
				) OR 				
				(@Updating=1 AND 
					(ISNULL(CASE WHEN @Day=1 THEN DayOne
					 WHEN @Day=2 Then DayTwo
					 WHEN @Day=3 Then DayThree
					 WHEN @Day=4 Then DayFour
					 WHEN @Day=5 Then DayFive
					 WHEN @Day=6 Then DaySix
					 WHEN @Day=7 Then DaySeven END,0)=@OldHours
					)
				)
			)
		ORDER BY Seq DESC
	
	/* Set the variable for the correct day being updated to the value in @Hours
		and set the variables for the other days to the current value.  */
	IF (@Hours=0) SET @Hours=NULL
	SELECT @DayOne=CASE WHEN @Day=1 THEN @Hours ELSE @DayOne END,
			@DayTwo=CASE WHEN @Day=2 THEN @Hours ELSE @DayTwo END,
			@DayThree=CASE WHEN @Day=3 THEN @Hours ELSE @DayThree END,
			@DayFour=CASE WHEN @Day=4 THEN @Hours ELSE @DayFour END,
			@DayFive=CASE WHEN @Day=5 THEN @Hours ELSE @DayFive END,
			@DaySix=CASE WHEN @Day=6 THEN @Hours ELSE @DaySix END,
			@DaySeven=CASE WHEN @Day=7 THEN @Hours ELSE @DaySeven END
	
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetailRecordUpdate 2: DetailExists='+Convert(varchar,isnull(@DetailExists,0))+' Updating='+convert(varchar,isnull(@Updating,0))+' UpdateInProgress='+Convert(varchar, ISNULL(@UpdateInProgress,0))+' EntryEmployee='+Convert(varchar, isnull(@EntryEmployee,0))
IF (@PrintDebug=1) PRINT ' StartDate='+Convert(varchar, @StartDate,101)+' Sheet='+Convert(Varchar,ISNULL(@Sheet,0))+' Seq='+Convert(Varchar,ISNULL(@Seq,0))+' Day='+CONVERT(varchar,ISNULL(@Day,0))+' Employee='+Convert(varchar, isnull(@Employee,0))
IF (@PrintDebug=1) PRINT ' DayOne='+Convert(varchar,isnull(@DayOne,0))+' DayTwo='+Convert(varchar,isnull(@DayTwo,0))+' DayThree='+Convert(varchar,isnull(@DayThree,0))+' DayFour='+Convert(varchar,isnull(@DayFour,0))+' DayFive=='+Convert(varchar,isnull(@DayFive,0))+' DaySix='+Convert(varchar,isnull(@DaySix,0))+' DaySeven='+Convert(varchar,isnull(@DaySeven,0))
	
	IF(@DetailExists=1)
		/* A record was found so the current Seq will be used as the Next Seq to be used. */
		SELECT @NextSeq=@Seq
	ELSE
	BEGIN
		/* No detail record is found that can be used so one must be created. Select the next Seq to be used. */
		SELECT @NextSeq=ISNULL(Max(Seq),0)+1 FROM PRMyTimesheetDetail
			WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet
	END
	
	/* Create the link 
		Before the detail record can be update or created the SMMyTimesheetLink record has to be created
		so the trigger won't try and create a SMWorkCompleted record.			
		If none found then create one. */
	IF (@Updating=0)
	BEGIN TRY
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetailRecordUpdate 3: Inserting SMMyTimesheetLink: UpdateInProgress='+Convert(varchar, isnull(@UpdateInProgress,0))+' EntryEmployee='+Convert(varchar, isnull(@EntryEmployee,0))+' Employee='+Convert(varchar, isnull(@Employee,0))+' StartDate='+Convert(varchar, @StartDate, 101)+' Day='+Convert(varchar, isnull(@Day,0))
IF (@PrintDebug=1) PRINT ' Sheet='+Convert(varchar, isnull(@Sheet,0))+' Seq='+Convert(varchar, isnull(@NextSeq,0))+' PayType='+@PayType+' WorkOrder='+Convert(varchar,@WorkOrder)+' Scope='+Convert(varchar,@Scope)
		INSERT SMMyTimesheetLink (SMCo, PRCo, WorkOrder, Scope, WorkCompleted, SMWorkCompletedID, EntryEmployee, 
			Employee, StartDate, DayNumber, Sheet, Seq, UpdateInProgress) VALUES (@SMCo, @PRCo, @WorkOrder, @Scope, @WorkCompleted, 
			@SMWorkCompletedID, @EntryEmployee, @Employee, @StartDate, @Day, @Sheet, @NextSeq, @UpdateInProgress)
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Failed to create SMMyTimesheetLink record: ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	/* Now either create a new record or update the existing one. */
	IF (ISNULL(@DetailExists,0)=0 AND @Updating=0)
	BEGIN
		/* Create the PRMyTimesheetDetail record */
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetailRecordUpdate 4: Inserting PRMyTimesheetDetail.'
IF (@PrintDebug=1) PRINT ' StartDate='+CONVERT(varchar, @StartDate, 101)+' Sheet='+CONVERT(varchar, @Sheet)+' Seq='+CONVERT(varchar,ISNULL(@NextSeq,0))
IF (@PrintDebug=1) PRINT ' Employee='+CONVERT(varchar, @Employee)+' PayType='+@PayType+' WorkOrder='+Convert(varchar,@WorkOrder)+' Scope='+Convert(varchar,@Scope)
		BEGIN TRY
			/* Since we are updating an existing PRMyTimesheetDetail record that may already be linked to other WOrk Completed record, we need to mark
				those links that an update is in progress. */
			UPDATE SMMyTimesheetLink Set UpdateInProgress=1 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@NextSeq
			/* We want to leave the UpdateInProgress off of the current day that we are adding. */
			UPDATE SMMyTimesheetLink Set UpdateInProgress=0 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@NextSeq AND DayNumber=@Day

			/* Get the current Locked status of the PRMyTimesheet record and turn it off */
			SELECT @TimesheetStatus=Status from PRMyTimesheet WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet
			IF (@TimesheetStatus IN (1,2))
				UPDATE PRMyTimesheet SET Status=0 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet
			
			INSERT PRMyTimesheetDetail (PRCo, EntryEmployee, StartDate, Sheet, Seq, Employee, EarnCode, Craft, Class, Shift,
				DayOne, DayTwo, DayThree, DayFour, DayFive, DaySix, DaySeven, CreatedBy, CreatedOn, LineType, SMCo, WorkOrder,
				Scope, PayType, SMCostType, SMJCCostType, PhaseGroup, JCCo, Job, Phase)
				VALUES (@PRCo, @EntryEmployee, @StartDate, @Sheet, @NextSeq, @Employee, ISNULL(@EarnCode, @DftEarnCode), @Craft, @Class, @Shift,
				@DayOne, @DayTwo, @DayThree, @DayFour, @DayFive, @DaySix, @DaySeven, suser_name(), dbo.vfDateOnly(), @LineType, @SMCo, @WorkOrder,
				@Scope, @PayType, @SMCostType, @SMJCCostType, @SMPhaseGroup, @JCCo, @Job, @Phase)

			IF (@TimesheetStatus IN (1,2))
				UPDATE PRMyTimesheet SET Status= 1 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet

			IF (@UpdateInProgress=1)
			BEGIN
				UPDATE SMMyTimesheetLink Set UpdateInProgress=0 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@NextSeq
			END
		END TRY
		BEGIN CATCH
			SET @errmsg = 'Failed to create PRMyTimesheetDetail record: ' + ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END
	ELSE
	BEGIN
		/* Update the PRMyTimesheetDetail record */
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetailRecordUpdate 5: Updating PRMyTimesheetDetail: UpdateInProgress='+Convert(varchar, @UpdateInProgress)
		BEGIN TRY
			IF (@UpdateInProgress=1)
			BEGIN
				UPDATE SMMyTimesheetLink SET UpdateInProgress=1 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee 
					AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@Seq
			END

			/* Get the current Locked status of the PRMyTimesheet record and turn it off */
			SELECT @TimesheetStatus=Status from PRMyTimesheet WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet
			IF (@TimesheetStatus IN (1,2))
				UPDATE PRMyTimesheet SET Status = 0 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet

IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetailRecordUpdate 6: EntryEmployee='+CONVERT(VARCHAR, @EntryEmployee)
IF (@PrintDebug=1) PRINT ' StartDate='+CONVERT(varchar, @StartDate, 101)+' Sheet='+CONVERT(varchar, @Sheet)+' Seq='+CONVERT(varchar,ISNULL(@Seq,0))
IF (@PrintDebug=1) PRINT ' Employee='+CONVERT(varchar, @Employee)+' PayType='+@PayType+' WorkOrder='+Convert(varchar,@WorkOrder)+' Scope='+Convert(varchar,@Scope)
IF (@PrintDebug=1) PRINT ' DayOne='+CONVERT(varchar, ISNULL(@DayOne,0))+' DayTwo='+CONVERT(varchar, ISNULL(@DayTwo,0))+' DayThree='+CONVERT(varchar, ISNULL(@DayThree,0))+' DayFour='+CONVERT(varchar, ISNULL(@DayFour,0))+' DayFive='+CONVERT(varchar, ISNULL(@DayFive,0))+' DaySix='+CONVERT(varchar, ISNULL(@DaySix,0))+' DaySeven='+CONVERT(varchar, ISNULL(@DaySeven,0))
			UPDATE PRMyTimesheetDetail SET EarnCode=ISNULL(@EarnCode, @DftEarnCode), Craft=@Craft, Class=@Class, Shift=@Shift,
				DayOne=@DayOne, DayTwo=@DayTwo, DayThree=@DayThree, DayFour=@DayFour, DayFive=@DayFive, DaySix=@DaySix, DaySeven=@DaySeven, 
				SMCo=@SMCo, WorkOrder=@WorkOrder, Scope=@Scope, PayType=@PayType, 
				SMCostType=@SMCostType,SMJCCostType=@SMJCCostType,PhaseGroup=@SMPhaseGroup
			WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@Seq
			
			IF (@TimesheetStatus IN (1,2))
				UPDATE PRMyTimesheet SET Status= 1 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet

			IF (@UpdateInProgress=1)
			BEGIN
				UPDATE SMMyTimesheetLink SET UpdateInProgress=0 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee 
					AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@Seq
			END
		END TRY
		BEGIN CATCH
IF (@PrintDebug=1) PRINT 'Failed to update PRMyTimesheetDetail record: ' + ERROR_MESSAGE()
			SET @errmsg = 'Failed to update PRMyTimesheetDetail record: ' + ERROR_MESSAGE()
			RETURN 1
		END CATCH
		
		IF (@Updating=1 AND ISNULL(@Hours,0)=0)
		BEGIN
			/* Delete PRMyTimesheetDetail record if the hours for every day of the week is zero */
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetailRecordUpdate 7: Deleting PRMyTimesheetDetail: UpdateInProgress='+Convert(varchar, @UpdateInProgress)
IF (@PrintDebug=1) PRINT ' StartDate='+CONVERT(varchar, @StartDate, 101)+' EntryEmployee='+CONVERT(varchar, @EntryEmployee)+' Sheet='+CONVERT(varchar, @Sheet)
			BEGIN TRY
				IF (@UpdateInProgress=1)
				BEGIN
					UPDATE SMMyTimesheetLink SET UpdateInProgress=1 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee 
						AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@Seq
				END

				/* Get the current Locked status of the PRMyTimesheet record and turn it off */
				SELECT @TimesheetStatus=Status from PRMyTimesheet WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet
				IF (@TimesheetStatus IN (1,2))
					UPDATE PRMyTimesheet SET Status=0 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet

				DELETE FROM PRMyTimesheetDetail WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@Seq
					AND ISNULL(DayOne,0)=0 AND ISNULL(DayTwo,0)=0 AND ISNULL(DayThree,0)=0 AND ISNULL(DayFour,0)=0 AND ISNULL(DayFive,0)=0 AND ISNULL(DaySix,0)=0 AND ISNULL(DaySeven,0)=0 

				IF (@UpdateInProgress=1)
				BEGIN
					UPDATE SMMyTimesheetLink SET UpdateInProgress=0 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee 
						AND StartDate=@StartDate AND Sheet=@Sheet AND Seq=@Seq
					DELETE SMMyTimesheetLink WHERE SMWorkCompletedID=@SMWorkCompletedID
				END

				IF (@TimesheetStatus IN (1,2))
					UPDATE PRMyTimesheet SET Status=1 WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate AND Sheet=@Sheet

			END TRY
			BEGIN CATCH
				SET @errmsg = 'Failed to delete PRMyTimesheetDetail record: ' + ERROR_MESSAGE()
				RETURN 1
			END CATCH
			/* Delete PRMyTimesheet record if there are no associated PRMyTimesheetDetail */
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetailRecordUpdate 8: Deleting PRMyTimesheet: UpdateInProgress='+Convert(varchar, @UpdateInProgress)
IF (@PrintDebug=1) PRINT ' StartDate='+CONVERT(varchar, @StartDate, 101)+' EntryEmployee='+CONVERT(varchar, @EntryEmployee)+' Sheet='+CONVERT(varchar, @Sheet)
			DELETE PRMyTimesheet FROM PRMyTimesheet 
				LEFT JOIN PRMyTimesheetDetail ON PRMyTimesheetDetail.PRCo=PRMyTimesheet.PRCo 
				AND PRMyTimesheetDetail.EntryEmployee=PRMyTimesheet.EntryEmployee 
				AND PRMyTimesheetDetail.StartDate=PRMyTimesheet.StartDate 
				AND PRMyTimesheetDetail.Sheet=PRMyTimesheet.Sheet
			WHERE PRMyTimesheet.PRCo=@PRCo AND PRMyTimesheet.EntryEmployee=@EntryEmployee 
				AND PRMyTimesheet.StartDate=@StartDate AND PRMyTimesheet.Sheet=@Sheet 
				AND PRMyTimesheetDetail.Seq IS NULL
				AND PRMyTimesheet.Status=1
		END
	END
	
	RETURN 0
	
END

GO
GRANT EXECUTE ON  [dbo].[vspSMMyTimesheetDetailRecordUpdate] TO [public]
GO
