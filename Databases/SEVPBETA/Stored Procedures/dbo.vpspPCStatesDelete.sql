SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		<Jeremiah Barkley>
-- Create date: <1/21/09>
-- Description:	<PCStatesDelete Script>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCStatesDelete]
	-- Add the parameters for the stored procedure here
	(@Original_KeyID INT)
AS
SET NOCOUNT ON;

BEGIN
	DELETE FROM PCStates
	WHERE KeyID = @Original_KeyID
END


GO
GRANT EXECUTE ON  [dbo].[vpspPCStatesDelete] TO [VCSPortal]
GO
