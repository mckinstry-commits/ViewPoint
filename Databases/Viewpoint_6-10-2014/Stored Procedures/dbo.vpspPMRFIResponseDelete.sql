SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMRFIResponseDelete]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/20/09
-- Description:	delete the RFI Response item
-- =============================================
(@KeyID BIGINT)

AS
	SET NOCOUNT ON;


	DELETE FROM PMRFIResponse WHERE [KeyID] = @KeyID



GO
GRANT EXECUTE ON  [dbo].[vpspPMRFIResponseDelete] TO [VCSPortal]
GO
