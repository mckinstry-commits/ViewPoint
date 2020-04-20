SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/20/12
-- Description:	Get the advanced rate for a specified Material or Category.
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
=============================================*/
CREATE FUNCTION [dbo].[vfSMRateMaterialAdvanced]
(
	@SMCo bCompany,
	@EntitySeq int,
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
		WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq AND MatlGroup = @MaterialGroup AND Material = @Material
		
		UNION ALL
		
		SELECT 1 AdvancedRateSource, MarkupOrDiscount, Basis, [Percent], Seq RateOverrideMaterialSeq
		FROM dbo.vSMRateOverrideMaterial
		WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq AND MatlGroup = @MaterialGroup AND Category = @Category
	) GetAdvancedRates
	ORDER BY AdvancedRateSource DESC
)
GO
GRANT SELECT ON  [dbo].[vfSMRateMaterialAdvanced] TO [public]
GO
