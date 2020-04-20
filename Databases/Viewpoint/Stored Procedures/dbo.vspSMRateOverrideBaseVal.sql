SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric C Vaterlaus
-- Modified:    ECV 7/13/2011 Modified for table changes to remove SMRateOverrideTypeID
-- Create date: 7/12/2011
-- Description:	Validation for SM Rate Override Base
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRateOverrideBaseVal]
	@SMRateOverrideID bigint, 
	@AdvancedMaterialSetupExists AS bYN OUTPUT, 
	@AdvancedLaborSetupExists as bYN OUTPUT, 
	@AdvancedEquipmentSetupExists as bYN OUTPUT, 
	@AdvancedStdItemsSetupExists as bYN OUTPUT, 
	@msg varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	IF @SMRateOverrideID IS NULL
	BEGIN
		SET @msg = 'Missing SM RateOverrideID!'
		RETURN 1
	END
		
    SELECT @AdvancedMaterialSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM dbo.SMRateOverrideMaterial
	WHERE SMRateOverrideID = @SMRateOverrideID
	
	IF (@AdvancedMaterialSetupExists = 'N')
	BEGIN
		SELECT @AdvancedMaterialSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
		FROM dbo.SMRateOverrideMatlBP
		WHERE SMRateOverrideID = @SMRateOverrideID
	END
	
	SELECT @AdvancedLaborSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM dbo.SMRateOverrideLabor
	WHERE SMRateOverrideID = @SMRateOverrideID
	
	SELECT @AdvancedEquipmentSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM dbo.SMRateOverrideEquipment
	WHERE SMRateOverrideID = @SMRateOverrideID

	SELECT @AdvancedStdItemsSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM dbo.SMRateOverrideStandardItem
	WHERE SMRateOverrideID = @SMRateOverrideID
	
	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMRateOverrideBaseVal] TO [public]
GO
