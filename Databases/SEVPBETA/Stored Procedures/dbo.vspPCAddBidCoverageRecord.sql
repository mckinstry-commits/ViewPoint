SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/25/10
-- Description:	The BidCoverage form tab needs to add/delete records to vPCBidPackage before trying
--				to do any updates otherwise the updates will update nothing
-- =============================================
CREATE PROCEDURE [dbo].[vspPCAddBidCoverageRecord]
	@Company bCompany, @PotentialProject varchar(20), @BidPackage varchar(20), @ScopePhaseSeq bigint, @VendorGroup bGroup, @Vendor bVendor, @ContactSeq tinyint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM PCBidCoverage WHERE JCCo = @Company AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage AND ScopePhaseSeq = @ScopePhaseSeq AND VendorGroup = @VendorGroup AND Vendor = @Vendor AND ContactSeq = @ContactSeq)
	BEGIN 
		INSERT PCBidCoverage
		([JCCo]
		   ,[PotentialProject]
		   ,[BidPackage]
		   ,[ScopePhaseSeq]
		   ,[VendorGroup]
		   ,[Vendor]
		   ,[ContactSeq])
		VALUES (@Company, @PotentialProject, @BidPackage, @ScopePhaseSeq, @VendorGroup, @Vendor, @ContactSeq)
	END
END

GO
GRANT EXECUTE ON  [dbo].[vspPCAddBidCoverageRecord] TO [public]
GO
