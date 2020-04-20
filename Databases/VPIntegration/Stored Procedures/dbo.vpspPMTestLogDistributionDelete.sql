SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMTestLogDistributionDelete]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 8/11/09
-- Modified By: GF 09/21/2011 TK-08626 changed to use standard PM Distribution view
--				GF 11/09/2011 TK-09904 use key id
--
-- Description:	delete the test log distribution item
-- =============================================
(@KeyID BIGINT)

AS
	SET NOCOUNT ON;


	DELETE FROM PMDistribution WHERE [KeyID] = @KeyID


GO
GRANT EXECUTE ON  [dbo].[vpspPMTestLogDistributionDelete] TO [VCSPortal]
GO
