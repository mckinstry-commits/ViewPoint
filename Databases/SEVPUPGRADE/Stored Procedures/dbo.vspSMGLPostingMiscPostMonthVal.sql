SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMGLPostingMiscPostMonthVal]
   /***********************************************************
    * Created:  ECV 04/01/11
    * Modified: 
    *
    *
    * Returns a count of Work Completed records to post that match 
    * the criteria provided.
    *
    * GL Interface Levels:
    *	0      No update
    *	1      Summarize entries by GLCo#/GL Account
    *   2      Full detail
    *
    * INPUT PARAMETERS
    *   @SMCo            SM Co#
    *   @mth             Posting Month
    *   @ServiceCenterID SM Service Center ID
    *   @DivisionID      SM Division
    *   @MinDate         Minimum Transaction Date
    *   @MaxDate         Maximum Transaction Date
    *
    * OUTPUT PARAMETERS
    *   @RecordCount	 Count of records
    *
    * RETURN VALUE
    *   0                success
    *   1                fail
    *****************************************************/

(@SMCo bCompany, @Mth bMonth, @ServiceCenter varchar(10), @Division varchar(10), 
 @MinDate smalldatetime, @MaxDate smalldatetime, @errmsg varchar(255) OUTPUT)
AS
SET NOCOUNT ON

IF EXISTS(
	SELECT 1
	FROM dbo.vfSMGetWorkCompletedMiscellaneousToBeProcessed(@SMCo, @Mth, @ServiceCenter, @Division, @MinDate, @MaxDate) WorkCompletedToUpdate
		LEFT JOIN dbo.SMWorkCompleted ON WorkCompletedToUpdate.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID 
	WHERE SMWorkCompleted.SMWorkCompletedID IS NULL OR SMWorkCompleted.MonthToPostCost = @Mth)
BEGIN
	RETURN 0
END
ELSE
BEGIN
	SET @errmsg = 'No records found for the selected post month.'
	RETURN 1
END



GO
GRANT EXECUTE ON  [dbo].[vspSMGLPostingMiscPostMonthVal] TO [public]
GO
