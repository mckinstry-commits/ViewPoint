SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/20/12
-- Description:	Get the advanced rate for a specified Material or Category.
=============================================*/
CREATE FUNCTION [dbo].[vfSMRateMaterialAdvanced]
(
	@SMRateOverrideID AS bigint,
	@MaterialGroup AS bGroup,
	@Category AS bCat,
	@Material AS bMatl
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT TOP 1 *
	FROM
	(
		SELECT 2 AdvancedRateSource, MarkupOrDiscount, Basis, [Percent], Seq RateOverrideMaterialSeq
		FROM dbo.vSMRateOverrideMaterial
		WHERE SMRateOverrideID = @SMRateOverrideID AND MatlGroup = @MaterialGroup AND Material = @Material
		
		UNION ALL
		
		SELECT 1 AdvancedRateSource, MarkupOrDiscount, Basis, [Percent], Seq RateOverrideMaterialSeq
		FROM dbo.vSMRateOverrideMaterial
		WHERE SMRateOverrideID = @SMRateOverrideID AND MatlGroup = @MaterialGroup AND Category = @Category
	) GetAdvancedRates
	ORDER BY AdvancedRateSource DESC
)
GO
GRANT SELECT ON  [dbo].[vfSMRateMaterialAdvanced] TO [public]
GO
