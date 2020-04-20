SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/5/09
-- Description:	Validation for Reviewer field in PR My Timesheet Approval form
-- =============================================
CREATE PROCEDURE [dbo].[vspPRMyTimesheetReviewerVal]
	(@Reviewer VARCHAR(60), @VPUserName bVPUserName, @msg VARCHAR(60) = NULL OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @msg = Name
	FROM HQRV
	WHERE Reviewer = @Reviewer

	IF @msg IS NULL
	BEGIN
		SET @msg = 'Reviewer ' + @Reviewer + ' doesn''t exist'
		RETURN 1
	END
	
	IF NOT EXISTS(SELECT TOP 1 1 FROM HQRP WHERE Reviewer = @Reviewer AND VPUserName = @VPUserName)
	BEGIN
		SET @msg = 'You are not currently a member of the ' + @Reviewer + ' reviewer.'
		RETURN 1
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspPRMyTimesheetReviewerVal] TO [public]
GO
