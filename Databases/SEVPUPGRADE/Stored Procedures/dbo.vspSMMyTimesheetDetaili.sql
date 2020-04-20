SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 01/20/2011
-- Description:	Create SMWorkCompleted and SMMyTimesheetLink record for each date that has hours
-- Modification: 03/15/2011 EricV Added Craft, Class and Shift.
--               05/04/2011 EricV Modified for one unique WorkCompleted  for all types.
--               08/23/2011 EricV Added @SMCostType parameter.
--               02/09/2012 JG Added SMJCCostType and SMPhaseGroup parameters. 
-- =============================================
CREATE PROCEDURE [dbo].[vspSMMyTimesheetDetaili] 
	@PRCo bCompany, @EntryEmployee int, @Employee int, @StartDate smalldatetime, @Sheet smallint, 
	@Seq smallint, @SMCo bCompany, @WorkOrder int, @Scope int, @PayType varchar(10), @SMCostType smallint=NULL,
	@Hours1 bHrs, @Hours2 bHrs, @Hours3 bHrs, @Hours4 bHrs, @Hours5 bHrs, @Hours6 bHrs, @Hours7 bHrs,
	@Craft bCraft, @Class bClass, @Shift tinyint, 
	@SMJCCostType dbo.bJCCType, @SMPhaseGroup dbo.bGroup, @errmsg varchar(255) OUTPUT  
AS

BEGIN
	SET NOCOUNT ON;
	/* Flag to print debug statements */

	/* Create a matching record in SMWorkCompleted linked with records in SMBC */
	/* For each MyTimesheetDetail record one SMWorkCompleted record will be created for each day that is not null */
	DECLARE @rcode int, @Day tinyint, @Hours bHrs
	SET @rcode=0;
	
	-- Load the records with the new values for each day into a Table variable.
	DECLARE @NewTimesheetData TABLE	( Date smalldatetime, Hours numeric(12,3) )
	INSERT @NewTimesheetData (Date, Hours)
	SELECT 
		CASE WHEN Date = 'DayOne' THEN StartDate				WHEN Date = 'DayTwo' Then DATEADD(d, 1, StartDate)
		WHEN Date = 'DayThree' Then DATEADD(d, 2, StartDate)	WHEN Date = 'DayFour' Then DATEADD(d, 3, StartDate)
		WHEN Date = 'DayFive' Then DATEADD(d, 4, StartDate)		WHEN Date = 'DaySix' Then DATEADD(d, 5, StartDate)
		WHEN Date = 'DaySeven' Then DATEADD(d, 6, StartDate)	END as Date, Hours
	FROM
	(select @StartDate StartDate, @Hours1 DayOne, @Hours2 DayTwo, @Hours3 DayThree, @Hours4 DayFour, 
				@Hours5 DayFive, @Hours6 DaySix, @Hours7 DaySeven
	) AS p
	UNPIVOT (Hours FOR Date IN (DayOne, DayTwo, DayThree, DayFour, DayFive, DaySix, DaySeven)
	) AS unpvt
	
	-- Loop through the dates and hours and update the SMWorkCompleted records.			
	DECLARE @TimesheetDate smalldatetime, @WorkCompleted int, @SMWorkCompletedID bigint, @LinkRecordExists bit, @IsBilled bit, @Technician varchar(15)
	DECLARE cChanges CURSOR FOR
	SELECT Date, Hours
	FROM @NewTimesheetData
	
	OPEN cChanges
	FETCH NEXT FROM cChanges INTO @TimesheetDate, @Hours
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @Day = DateDiff(d, @StartDate, @TimesheetDate)+1
	
		IF (@Hours<>0)
		BEGIN
			/* Check to see if a link already exists, which means that the SMWorkCompleted record has already been created. */		
			IF NOT EXISTS(SELECT 1 FROM SMMyTimesheetLink WHERE PRCo=@PRCo AND SMCo=@SMCo AND EntryEmployee=@EntryEmployee AND Sheet=@Sheet 
				AND Seq=@Seq AND DayNumber=@Day AND StartDate = @StartDate)
			BEGIN		
				/* Get the next WorkCompleted sequence number. */
				SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @WorkOrder)
				
				/* Now create a linking record in SMBC for each new SMWorkCompleted record */
--IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetDetaili 2: vspSMMyTimesheetLinkCreate - Create MyTimesheetLink'
				exec @rcode = vspSMMyTimesheetLinkCreate @SMCo=@SMCo, @PRCo=@PRCo, @EntryEmployee=@EntryEmployee, @Employee=@Employee, @StartDate=@StartDate, 
					@WorkOrder=@WorkOrder, @Scope=@Scope, @Sheet=@Sheet, @Seq=@Seq, @Day=@Day, @WorkCompleted=@WorkCompleted, @errmsg=@errmsg OUTPUT

				IF (@rcode = 1)
				BEGIN
					RETURN @rcode
				END

				/* Create the SMWorkCompleted Records */
				SELECT @Technician=Technician FROM SMTechnician WHERE SMCo=@SMCo AND PRCo=@PRCo AND Employee=@Employee
				exec @rcode = vspSMWorkCompletedLaborCreate @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope=@Scope, @WorkCompleted = @WorkCompleted,
					@PayType=@PayType, @SMCostType=@SMCostType, @Technician=@Technician, @Date=@TimesheetDate, @Hours=@Hours, @Craft=@Craft, @Class=@Class, @Shift=@Shift,
					@SMJCCostType=@SMJCCostType, @SMPhaseGroup=@SMPhaseGroup, @TCPRCo=@PRCo,
					@SMWorkCompletedID=@SMWorkCompletedID OUTPUT, @msg=@errmsg OUTPUT

				IF (@rcode = 1)
				BEGIN
					RETURN @rcode
				END
				UPDATE SMMyTimesheetLink Set SMWorkCompletedID=@SMWorkCompletedID WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate
					AND Sheet=@Sheet AND Seq=@Seq AND DayNumber=@Day
			END
		END
		FETCH NEXT FROM cChanges INTO @TimesheetDate, @Hours
	END

	CLOSE cChanges
	DEALLOCATE cChanges			
			
	IF @rcode = 1
	BEGIN
		RETURN @rcode
	END
	
	RETURN @rcode
	
END
GO
GRANT EXECUTE ON  [dbo].[vspSMMyTimesheetDetaili] TO [public]
GO
