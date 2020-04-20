SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/13/2011
-- Description:	Validation for SM Rate Template Effective Date
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRateTemplateEffectiveDateVal]
	@SMCo bCompany, @RateTemplate varchar(10), @EffectiveDate bDate, @EquipmentOverridesExist bYN = NULL OUTPUT, @LaborOverridesExist bYN = NULL OUTPUT, @MaterialOverridesExist bYN = NULL OUTPUT, @StandardItemOverridesExist bYN = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	SET @msg = 
	CASE
		WHEN @SMCo IS NULL THEN 'Missing SM Company.'
		WHEN @RateTemplate IS NULL THEN 'Missing SM rate template.'
		WHEN @EffectiveDate IS NULL THEN 'Missing Effective Date.'
	END
	
	IF @msg IS NOT NULL
	BEGIN	
		RETURN 1
	END

	SELECT @EquipmentOverridesExist = EquipmentOverridesExist, @LaborOverridesExist = LaborOverridesExist, @MaterialOverridesExist = MaterialOverridesExist, @StandardItemOverridesExist = StandardItemOverridesExist
	FROM dbo.SMRateTemplateEffectiveDate
		LEFT JOIN dbo.SMEntity ON SMRateTemplateEffectiveDate.SMCo = SMEntity.SMCo AND SMRateTemplateEffectiveDate.RateTemplate = SMEntity.RateTemplate AND SMRateTemplateEffectiveDate.EffectiveDate = SMEntity.EffectiveDate
		CROSS APPLY dbo.vfSMGetAdvancedRatesExists(SMEntity.SMCo, SMEntity.EntitySeq)
	WHERE SMRateTemplateEffectiveDate.SMCo = @SMCo AND SMRateTemplateEffectiveDate.RateTemplate = @RateTemplate AND SMRateTemplateEffectiveDate.EffectiveDate = @EffectiveDate
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = 'Rate template effective date has not been set up.'
		RETURN 1
    END
	
	RETURN 0
END




GO
GRANT EXECUTE ON  [dbo].[vspSMRateTemplateEffectiveDateVal] TO [public]
GO
