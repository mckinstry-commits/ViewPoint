SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Modified:    Mark H		11/4/10	- Added Advanced Labor Setup Exists output param
--				Lane G		07/12/11 - Added Standard Item Overrides Exist output param
--				Jeremiah B	07/14/11 - Modified for the Material Overrides Exists param
--              Eric V      07/21/11 = Added Equipment Overrides Exist output param
--			    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
--			    Jacob VH	2/25/13 TFS-40923 Modified to no longer verify that work completed exists.
-- Create date: 10/6/2010
-- Description:	Validation for SM Rate Template
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRateTemplateVal]
	@SMCo bCompany, @RateTemplate varchar(10), @MustBeActive AS bit, @MaterialOverridesExist bYN = NULL OUTPUT, @LaborOverridesExist bYN = NULL OUTPUT, @StandardItemOverridesExist bYN = NULL OUTPUT, @EquipmentOverridesExist bYN = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	SET @msg = 
	CASE WHEN @SMCo IS NULL THEN 'Missing SM Company.'
		WHEN @RateTemplate IS NULL THEN 'Missing SM rate template.'
	END
	
	IF @msg IS NOT NULL
	BEGIN	
		RETURN 1
	END
	
	DECLARE @IsActive bYN
	
	SELECT @msg = [Description], @IsActive = Active, @EquipmentOverridesExist = EquipmentOverridesExist, @LaborOverridesExist = LaborOverridesExist, @MaterialOverridesExist = MaterialOverridesExist, @StandardItemOverridesExist = StandardItemOverridesExist
	FROM dbo.SMRateTemplate
		LEFT JOIN dbo.SMEntity ON SMRateTemplate.SMCo = SMEntity.SMCo AND SMRateTemplate.RateTemplate = SMEntity.RateTemplate AND SMEntity.EffectiveDate IS NULL
		CROSS APPLY dbo.vfSMGetAdvancedRatesExists(SMEntity.SMCo, SMEntity.EntitySeq)
	WHERE SMRateTemplate.SMCo = @SMCo AND SMRateTemplate.RateTemplate = @RateTemplate
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = 'Rate template has not been setup.'
		RETURN 1
    END
    
    IF @IsActive <> 'Y'
    BEGIN
		SET @msg = ISNULL(@msg,'') + ' - Inactive rate template.'
		RETURN 1
    END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMRateTemplateVal] TO [public]
GO
