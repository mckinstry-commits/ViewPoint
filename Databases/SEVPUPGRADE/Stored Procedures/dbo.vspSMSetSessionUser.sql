SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/9/2011
-- Description:	Updates the user for a SM Session
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSetSessionUser]
	@SMSessionID int, @SetToCurrentUser bit = NULL, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE dbo.SMSession WITH (NOWAIT)
	SET UserName = CASE WHEN @SetToCurrentUser = 1 THEN SUSER_NAME() ELSE NULL END
	WHERE SMSessionID = @SMSessionID
END
GO
GRANT EXECUTE ON  [dbo].[vspSMSetSessionUser] TO [public]
GO
