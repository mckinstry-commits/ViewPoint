SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/2/10
-- Description:	Load proc for PC Bid Communication
-- =============================================
CREATE PROCEDURE [dbo].[vspPCBidCommunicationInfoGet]
	@Company bCompany, @PotentialProject VARCHAR(20), @FaxServerName VARCHAR(50) OUTPUT, @ReplyToEmail VARCHAR(60) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @FaxServerName = FaxServerName
	FROM dbo.PMCO
	WHERE PMCo = @Company
	
	SELECT TOP 1 @ReplyToEmail = PrimaryContactEmail
	FROM dbo.PCBidPackage
	WHERE JCCo = @Company AND PotentialProject = @PotentialProject
	ORDER BY BidPackage
END

GO
GRANT EXECUTE ON  [dbo].[vspPCBidCommunicationInfoGet] TO [public]
GO
