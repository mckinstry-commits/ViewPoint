SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/5/09
-- Description:	Validation for Reviewer field in PR My Timesheet Approval form
-- =============================================
CREATE PROCEDURE [dbo].[vspPRReviewerValidation]
	(@msg VARCHAR(60) = NULL OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @msg = 'jacob'
	RETURN 1
	
END

GO
GRANT EXECUTE ON  [dbo].[vspPRReviewerValidation] TO [public]
GO
