SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric C Vaterlaus
-- Modified:    ECV 7/13/2011 Modified for table changes.
--				Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
-- Create date: 7/12/2011
-- Description:	Validation for SM Rate Override Base
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRateOverrideBaseVal]
	@SMCo bCompany,
	@EntitySeq int,
	@AdvancedMaterialSetupExists AS bYN OUTPUT, 
	@AdvancedLaborSetupExists as bYN OUTPUT, 
	@AdvancedEquipmentSetupExists as bYN OUTPUT, 
	@AdvancedStdItemsSetupExists as bYN OUTPUT, 
	@msg varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	IF @EntitySeq IS NULL
	BEGIN
		SET @msg = 'Missing SM EntitySeq!'
		RETURN 1
	END
		
    SELECT @AdvancedMaterialSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM dbo.SMRateOverrideMaterial
	WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq
	
	IF (@AdvancedMaterialSetupExists = 'N')
	BEGIN
		SELECT @AdvancedMaterialSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
		FROM dbo.SMRateOverrideMatlBP
		WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq
	END
	
	SELECT @AdvancedLaborSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM dbo.SMRateOverrideLabor
	WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq
	
	SELECT @AdvancedEquipmentSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM dbo.SMRateOverrideEquipment
	WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq

	SELECT @AdvancedStdItemsSetupExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM dbo.SMRateOverrideStandardItem
	WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq
	
	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMRateOverrideBaseVal] TO [public]
GO
