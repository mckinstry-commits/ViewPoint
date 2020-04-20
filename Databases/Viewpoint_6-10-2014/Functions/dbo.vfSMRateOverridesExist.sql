SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
-- Author:		Eric Vaterlaus
-- Create date: 7/13/2011
-- Description:	Determine if override values exist for specified SMCo and EntitySeq
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
=============================================*/
CREATE FUNCTION [dbo].[vfSMRateOverridesExist]
(
	@SMCo bCompany, @EntitySeq int
)
RETURNS bYN
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Status bYN

	IF EXISTS(SELECT 1 FROM SMRateOverrideBaseRate WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq
		AND (NOT MaterialPercent IS NULL 
			OR NOT EquipmentMarkup IS NULL
			OR NOT LaborRate IS NULL))
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideLabor WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq)
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideEquipment WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq)
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideMaterial WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq)
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideStandardItem WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq)
		RETURN 'Y'

	IF EXISTS(SELECT 1 FROM SMRateOverrideMatlBP WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq)
		RETURN 'Y'

	RETURN 'N'
END


GO
GRANT EXECUTE ON  [dbo].[vfSMRateOverridesExist] TO [public]
GO
