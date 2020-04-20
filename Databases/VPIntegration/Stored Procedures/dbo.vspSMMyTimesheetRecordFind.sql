SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 2/8/2011
-- Description:	Find an existing PRMyTimesheet record and create if asked.
-- Modification: The EntryEmployee of the record found has to match the EntryEmployee provided.
--				EN		6/6/11 D-02028 when insert into PRMyTimesheetDetail, plug CreatedOn date with no timestamp by using dbo.vfDateOnly() rather than GETDATE()
--              EricV	04/12/12 TK-14025 Use the Payroll pay period to determine the Start Date.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMMyTimesheetRecordFind] (
	@PRCo bCompany, @EntryEmployee bEmployee, @Employee bEmployee, 
	@Date smalldatetime, @CreateFlag bit=0, 
	@Sheet int OUTPUT, @StartDate smalldatetime OUTPUT, 
	@errmsg varchar(255) OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;
	/* Flag to print debug statements */
	DECLARE @PrintDebug bit
	Set @PrintDebug=0
	
	DECLARE @rcode int, @TimesheetEditOkay bYN, @PayrollWeekStartDate tinyint, @PRGroup bGroup
	SET @rcode=0

	/* Check to see if the current login has permission to edit the employee timesheet */	
	exec vspSMGetLoginPermission @PRCo=@PRCo, @Employee=@Employee, @TimesheetEditOkay=@TimesheetEditOkay OUTPUT
		
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetRecordFind 0: Start'
	
	BEGIN TRY
		IF EXISTS(SELECT 1 FROM PRMyTimesheet WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee 
			AND @Date BETWEEN StartDate AND DATEADD(d, 6, StartDate) AND Status IN (0,1,2))
		BEGIN
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetRecordFind 1'
			/* Find the key fields for the existing PRMyTimesheet record. */
			SELECT TOP 1 @StartDate=StartDate, @Sheet=Sheet
				FROM PRMyTimesheet WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee
				AND @Date BETWEEN StartDate AND DATEADD(d, 6, StartDate) AND Status IN (0,1,2)
				ORDER BY StartDate DESC, Sheet DESC

		END
		ELSE IF (@CreateFlag = 1)
		BEGIN
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetRecordFind 3: Creating with EntryEmployee = Employee'
			/* Since no PRMyTimesheet record exists that we can use we need to create one. */
			/* Set the StartDate to the closest monday prior to the date. */
			BEGIN TRY
				/* Find the most current Pay Period and get the day of the week of the beginnning date */
				SELECT @PRGroup=PRGroup FROM PREH WHERE PRCo=@PRCo AND Employee=@Employee 
				SELECT TOP 1 @PayrollWeekStartDate=DATEPART(dw, BeginDate) FROM PRPC WHERE PRCo=@PRCo AND PRGroup=@PRGroup AND BeginDate<=@Date ORDER BY PREndDate DESC
				/* Find the date that has the same day of the week as the beginning of the pay period andis at or before @Date */
				SELECT @EntryEmployee=@EntryEmployee, 
					@StartDate=CASE WHEN DATEPART(dw, @Date)-@PayrollWeekStartDate >= 0 THEN DATEADD(d, (DATEPART(dw, @Date)-@PayrollWeekStartDate)*-1, @Date)ELSE DATEADD(d, -7, DATEADD(d, (DATEPART(dw, @Date)-@PayrollWeekStartDate)*-1, @Date)) END
				SELECT @Sheet=ISNULL(MAX(Sheet),0)+1 FROM PRMyTimesheet WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee AND StartDate=@StartDate
				
				INSERT INTO PRMyTimesheet (PRCo, EntryEmployee, StartDate, Sheet, Status, CreatedOn, CreatedBy, PersonalTimesheet) 
					VALUES (@PRCo, @EntryEmployee, @StartDate, @Sheet, 1, dbo.vfDateOnly(), suser_name(), CASE WHEN @EntryEmployee=@Employee THEN 'Y' ELSE 'N' END)	
			END TRY
			BEGIN CATCH
				/* Record failed to create. */
				SET @errmsg = 'Failed to create PRMyTimesheet record: ' + ERROR_MESSAGE()
				SET @rcode=1
			END CATCH
		END
		ELSE
		BEGIN
IF (@PrintDebug=1) PRINT 'vspSMMyTimesheetRecordFind 4: Existing record not found.'
			/* None exists and none was created. */
			SET @errmsg = 'No suitable PRMyTimesheet record found.'
			SET @rcode=1
		END
	END TRY
	BEGIN CATCH
		SELECT @rcode=1, @errmsg='Error search for PRMyTimesheet record: ' +ERROR_MESSAGE()
	END CATCH
		
	RETURN @rcode
	
END

GO
GRANT EXECUTE ON  [dbo].[vspSMMyTimesheetRecordFind] TO [public]
GO
