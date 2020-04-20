SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/13/11
-- Description:	Retrieves if advanced rates exist for a given SMCo and EntitySeq
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetAdvancedRatesExists]
(	
	@SMCo bCompany, @EntitySeq int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
		CASE WHEN EXISTS(SELECT 1 FROM dbo.SMRateOverrideEquipment WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq) THEN 'Y' ELSE 'N' END AS EquipmentOverridesExist,
		
		CASE WHEN EXISTS(SELECT 1 FROM dbo.SMRateOverrideLabor WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq) THEN 'Y' ELSE 'N' END AS LaborOverridesExist,
		
		CASE WHEN 
			EXISTS(SELECT 1 FROM dbo.SMRateOverrideMaterial WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq) 
			OR EXISTS(SELECT 1 FROM dbo.SMRateOverrideMatlBP WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq)
			THEN 'Y' ELSE 'N' END AS MaterialOverridesExist,

		CASE WHEN EXISTS(SELECT 1 FROM dbo.SMRateOverrideStandardItem WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq) THEN 'Y' ELSE 'N' END AS StandardItemOverridesExist
)

GO
GRANT SELECT ON  [dbo].[vfSMGetAdvancedRatesExists] TO [public]
GO
