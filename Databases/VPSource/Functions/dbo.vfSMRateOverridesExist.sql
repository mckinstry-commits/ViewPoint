SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
-- Author:		Eric Vaterlaus
-- Create date: 7/13/2011
-- Description:	Determine if override values exist for specified SMRateOverrideID
=============================================*/
CREATE FUNCTION [dbo].[vfSMRateOverridesExist]
(
	@SMRateOverrideID AS bigint
)
RETURNS bYN
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Status bYN

	IF EXISTS(SELECT 1 FROM SMRateOverrideBaseRate WHERE SMRateOverrideID=@SMRateOverrideID
		AND (NOT MaterialPercent IS NULL 
			OR NOT EquipmentMarkup IS NULL
			OR NOT LaborRate IS NULL))
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideLabor WHERE SMRateOverrideID=@SMRateOverrideID)
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideEquipment WHERE SMRateOverrideID=@SMRateOverrideID)
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideMaterial WHERE SMRateOverrideID=@SMRateOverrideID)
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideStandardItem WHERE SMRateOverrideID=@SMRateOverrideID)
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideMatlBP WHERE SMRateOverrideID=@SMRateOverrideID)
		RETURN 'Y'

	RETURN 'N'
END


GO
GRANT EXECUTE ON  [dbo].[vfSMRateOverridesExist] TO [public]
GO
