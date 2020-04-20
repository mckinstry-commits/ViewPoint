SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/13/11
-- Description:	Retrieves if advanced rates exist for a given SMRateOverrideID
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetAdvancedRatesExists]
(	
	@SMRateOverrideID bigint
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
		CASE WHEN EXISTS(SELECT 1 FROM dbo.SMRateOverrideEquipment WHERE SMRateOverrideID = @SMRateOverrideID) THEN 'Y' ELSE 'N' END AS EquipmentOverridesExist,
		
		CASE WHEN EXISTS(SELECT 1 FROM dbo.SMRateOverrideLabor WHERE SMRateOverrideID = @SMRateOverrideID) THEN 'Y' ELSE 'N' END AS LaborOverridesExist,
		
		CASE WHEN 
			EXISTS(SELECT 1 FROM dbo.SMRateOverrideMaterial WHERE SMRateOverrideID = @SMRateOverrideID) 
			OR EXISTS(SELECT 1 FROM dbo.SMRateOverrideMatlBP WHERE SMRateOverrideID = @SMRateOverrideID)
			THEN 'Y' ELSE 'N' END AS MaterialOverridesExist,

		CASE WHEN EXISTS(SELECT 1 FROM dbo.SMRateOverrideStandardItem WHERE SMRateOverrideID = @SMRateOverrideID) THEN 'Y' ELSE 'N' END AS StandardItemOverridesExist
)

GO
GRANT SELECT ON  [dbo].[vfSMGetAdvancedRatesExists] TO [public]
GO
