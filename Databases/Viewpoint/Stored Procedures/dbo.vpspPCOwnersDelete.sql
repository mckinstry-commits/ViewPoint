SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[vpspPCOwnersDelete]
	-- Add the parameters for the stored procedure here
	(@Original_KeyID INT)
AS
SET NOCOUNT ON;

BEGIN
	DELETE FROM PCOwners
	WHERE KeyID = @Original_KeyID
END



GO
GRANT EXECUTE ON  [dbo].[vpspPCOwnersDelete] TO [VCSPortal]
GO
