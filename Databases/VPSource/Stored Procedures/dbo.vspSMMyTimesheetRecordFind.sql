
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
--              JVH		6/8/13 TFS-54772 Used tables instead of views to determine start date so that datatype security doesn't break functionality
-- =============================================
CREATE PROCEDURE [dbo].[vspSMMyTimesheetRecordFind] (
	@PRCo bCompany, @EntryEmployee bEmployee, @Employee bEmployee, 
	@Date smalldatetime, @CreateFlag bit=0, 
	@Sheet int OUTPUT, @StartDate smalldatetime OUTPUT, 
	@errmsg varchar(255) OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int, @TimesheetEditOkay bYN
	SET @rcode=0

	/* Check to see if the current login has permission to edit the employee timesheet */	
	exec vspSMGetLoginPermission @PRCo=@PRCo, @Employee=@Employee, @TimesheetEditOkay=@TimesheetEditOkay OUTPUT

	BEGIN TRY
		IF EXISTS(SELECT 1 FROM PRMyTimesheet WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee 
			AND @Date BETWEEN StartDate AND DATEADD(d, 6, StartDate) AND Status IN (0,1,2))
		BEGIN
			/* Find the key fields for the existing PRMyTimesheet record. */
			SELECT TOP 1 @StartDate=StartDate, @Sheet=Sheet
				FROM PRMyTimesheet WHERE PRCo=@PRCo AND EntryEmployee=@EntryEmployee
				AND @Date BETWEEN StartDate AND DATEADD(d, 6, StartDate) AND Status IN (0,1,2)
				ORDER BY StartDate DESC, Sheet DESC

		END
		ELSE IF (@CreateFlag = 1)
		BEGIN
			/* Since no PRMyTimesheet record exists that we can use we need to create one. */
			/* Set the StartDate to the closest monday prior to the date. */
			BEGIN TRY
				/* Find the most current Pay Period and get the day of the week of the beginnning date */
				/* Find the date that has the same day of the week as the beginning of the pay period andis at or before @Date */
				SELECT TOP 1 @StartDate = DATEADD(d, DATEPART(dw, bPRPC.BeginDate) - DATEPART(dw, @Date), @Date),
					@StartDate = CASE WHEN @StartDate > @Date THEN DATEADD(wk, -1, @StartDate) ELSE @StartDate END
				FROM dbo.bPREH
					INNER JOIN dbo.bPRPC ON bPREH.PRCo = bPRPC.PRCo AND bPREH.PRGroup = bPRPC.PRGroup
				WHERE bPREH.PRCo = @PRCo AND bPREH.Employee = @Employee AND bPRPC.BeginDate <= @Date
				ORDER BY bPRPC.PREndDate DESC
				IF @@ROWCOUNT = 0
				BEGIN
					--If the are no pay periods that match then use Sunday as the start date
					SELECT @StartDate = DATEADD(d, 1 - DATEPART(dw, @Date), @Date)
				END

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
