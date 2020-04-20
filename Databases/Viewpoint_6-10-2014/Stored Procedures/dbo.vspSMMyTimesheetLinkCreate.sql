SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 01/21/2011
-- Description:	Create links in vSMMyTimesheetLink to link SMWorkCompleted records to PRMyTimesheetDetail
-- Modifications: 01/27/11 Eric V	Modified to only create a single SMMyTimesheetLink recoord.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMMyTimesheetLinkCreate]
	@SMCo bCompany, @PRCo bCompany, @EntryEmployee int, @Employee int, @StartDate smalldatetime, @Day tinyint, @WorkOrder int, @Scope int, 
	@Sheet int, @Seq int, @WorkCompleted bigint, @SMWorkCompletedID bigint=NULL, @errmsg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rcode int
	
	BEGIN TRY
		INSERT vSMMyTimesheetLink (SMCo, PRCo, WorkOrder, Scope, WorkCompleted,
			SMWorkCompletedID, EntryEmployee, Employee, StartDate, DayNumber, Sheet, Seq)
		VALUES (@SMCo, @PRCo, @WorkOrder, @Scope, @WorkCompleted, @SMWorkCompletedID, 
			@EntryEmployee, @Employee, @StartDate, @Day, @Sheet, @Seq)
		
		Set @rcode = 0
	END TRY
	BEGIN CATCH
		SET @rcode = 1
		SET @errmsg = 'Link create between SMWorkCompleted and PRMyTimesheetDetail failed with error: ' + ERROR_MESSAGE()
	END CATCH
	
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspSMMyTimesheetLinkCreate] TO [public]
GO
