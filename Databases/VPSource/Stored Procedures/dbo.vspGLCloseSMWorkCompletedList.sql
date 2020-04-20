SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspGLCloseSMWorkCompletedList]
   /**************************************************
   * Created:	GP 1/03/2013 MB
   * This procedure returns a list of Work Completed Misc lines that prevent a month from being closed.
   * Modified:
   *
   **************************************************/
   	(@glco bCompany, @mth bMonth)
AS
BEGIN
	SET NOCOUNT ON

	SELECT SMWorkCompletedMisc.SMCo, dbo.vfToMonthString(SMWorkCompletedMisc.MonthToPostCost) PostMonth
	FROM dbo.SMCO
		CROSS APPLY vfSMGetWorkCompletedMiscellaneousToBeProcessed(SMCO.SMCo, NULL, NULL, NULL, NULL, NULL)
		INNER JOIN dbo.SMWorkCompletedDetail ON vfSMGetWorkCompletedMiscellaneousToBeProcessed.SMWorkCompletedID = SMWorkCompletedDetail.SMWorkCompletedID
		INNER JOIN dbo.SMWorkCompletedMisc ON SMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompletedMisc.SMWorkCompletedID AND SMWorkCompletedDetail.IsSession = SMWorkCompletedMisc.IsSession
	WHERE SMWorkCompletedDetail.GLCo = @glco AND SMWorkCompletedMisc.MonthToPostCost <= @mth
	ORDER BY SMWorkCompletedMisc.MonthToPostCost

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspGLCloseSMWorkCompletedList] TO [public]
GO
