SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMInspectionLogDistributionDelete]
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/14/09
-- Modified By: GF 09/21/2011 TK-08626 changed to use standard PM Distribution view
--
--
-- Description:	delete the inspection log distribution item
-- =============================================
(@KeyID BIGINT)

AS
SET NOCOUNT ON;


DELETE FROM PMDistribution WHERE [KeyID] = @KeyID;




GO
GRANT EXECUTE ON  [dbo].[vpspPMInspectionLogDistributionDelete] TO [VCSPortal]
GO
