SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[vpspPCOSHADelete]
	-- Add the parameters for the stored procedure here
	(@Original_KeyID INT)
AS
SET NOCOUNT ON;

BEGIN
	DELETE FROM PCOSHA
	WHERE KeyID = @Original_KeyID
END



GO
GRANT EXECUTE ON  [dbo].[vpspPCOSHADelete] TO [VCSPortal]
GO
