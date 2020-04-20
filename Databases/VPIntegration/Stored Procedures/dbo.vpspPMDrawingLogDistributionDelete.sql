SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMDrawingLogDistributionDelete]
-- =============================================
-- Created By:	GF 11/10/2011 TK-00000
-- Modified By:
--
--
-- Description:	delete the DRAWING log distribution item
-- =============================================
(@KeyID BIGINT)

AS
SET NOCOUNT ON;


DELETE FROM PMDistribution WHERE [KeyID] = @KeyID;




GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogDistributionDelete] TO [VCSPortal]
GO
