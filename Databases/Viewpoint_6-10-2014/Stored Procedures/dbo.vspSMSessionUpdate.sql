SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/13/13
-- Description:	Updates the user for a SM Session
-- =============================================
CREATE PROCEDURE [dbo].[vspSMSessionUpdate]
	@SMSessionID int, @ConvertPreBilling bit = 0, @SetToCurrentUser bit = NULL, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE dbo.vSMSession WITH (NOWAIT)
	SET UserName = CASE WHEN @SetToCurrentUser = 1 THEN SUSER_NAME() ELSE NULL END
	WHERE SMSessionID = @SMSessionID

	IF @ConvertPreBilling = 1
	BEGIN
		UPDATE dbo.vSMSession WITH (NOWAIT)
		SET Prebilling = 0
		WHERE SMSessionID = @SMSessionID
	END
END
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionUpdate] TO [public]
GO
