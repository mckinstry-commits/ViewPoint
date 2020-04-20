SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/17/11
-- Description:	Creates a new SM Effective Date Rate template by copying from an existing basic rate template or effective date rate template.
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
-- Mod: MDB 2/5/2012 Modification to use EntitySeq over
--		JVH 4/10/13 Modified to support the other entities that need to be added.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRateTemplateEffectiveDateCreate]
	@SMCo bCompany, @NewRateTemplate varchar(10), @NewEffectiveDate bDate, @CopyFromRateTemplate varchar(10), @CopyFromEffectiveDate bDate, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--First make sure that the rate template's effective date doesn't already exist.
    IF EXISTS(SELECT 1 FROM dbo.SMRateTemplateEffectiveDate WHERE SMCo = @SMCo AND RateTemplate = @NewRateTemplate AND EffectiveDate = @NewEffectiveDate)
    BEGIN
		SET @msg = 'You can not create a rate template for the given effective date since one already exists.'
		RETURN 1
    END
    
    DECLARE @rcode int, @CopyFromEntitySeq int, @NewEntitySeq int
    
    --Next check to make sure that the rate template or the rate template's effective date exist and grab the rateoverrideid so we can copy the advanced setup.
    IF @CopyFromEffectiveDate IS NULL
    BEGIN
		INSERT dbo.SMRateTemplateEffectiveDate (SMCo, RateTemplate, EffectiveDate, LaborRate, EquipmentMarkup, MaterialMarkupOrDiscount, MaterialBasis, MaterialPercent)
		SELECT SMCo, @NewRateTemplate, @NewEffectiveDate, LaborRate, EquipmentMarkup, MaterialMarkupOrDiscount, MaterialBasis, MaterialPercent
		FROM dbo.SMRateTemplate
		WHERE SMCo = @SMCo AND RateTemplate = @CopyFromRateTemplate
		IF @@rowcount <> 1
		BEGIN
			SET @msg = 'The rate template to copy from doesn''t exist. Please select an existing rate template to copy from.'
			RETURN 1
		END

		SELECT @CopyFromEntitySeq = EntitySeq
		FROM dbo.SMEntity
		WHERE SMCo = @SMCo AND RateTemplate = @CopyFromRateTemplate AND EffectiveDate IS NULL
    END
    ELSE
    BEGIN
		INSERT dbo.SMRateTemplateEffectiveDate (SMCo, RateTemplate, EffectiveDate, LaborRate, EquipmentMarkup, MaterialMarkupOrDiscount, MaterialBasis, MaterialPercent)
		SELECT SMCo, @NewRateTemplate, @NewEffectiveDate, LaborRate, EquipmentMarkup, MaterialMarkupOrDiscount, MaterialBasis, MaterialPercent
		FROM dbo.SMRateTemplateEffectiveDate
		WHERE SMCo = @SMCo AND RateTemplate = @CopyFromRateTemplate AND EffectiveDate = @CopyFromEffectiveDate
		IF @@rowcount <> 1
		BEGIN
			SET @msg = 'The effective date given for the rate template to copy from doesn''t exist. Please select an existing rate template to copy from.'
			RETURN 1
		END
		
		SELECT @CopyFromEntitySeq = EntitySeq
		FROM dbo.SMEntity
		WHERE SMCo = @SMCo AND RateTemplate = @CopyFromRateTemplate AND EffectiveDate = @CopyFromEffectiveDate
    END

	--The advance rates need to be copied over if any exist
    IF @CopyFromEntitySeq IS NOT NULL
		AND EXISTS(SELECT 1 FROM dbo.vfSMGetAdvancedRatesExists(@SMCo, @CopyFromEntitySeq) WHERE EquipmentOverridesExist = 'Y' OR LaborOverridesExist = 'Y' OR MaterialOverridesExist = 'Y' OR StandardItemOverridesExist = 'Y')
    BEGIN  
		EXEC @rcode = dbo.vspSMEntityCreate @SMEntityType = 4, @SMCo = @SMCo, @RateTemplate = @NewRateTemplate, @EffectiveDate = @NewEffectiveDate, @EntitySeq = @NewEntitySeq OUTPUT
		
		IF @rcode <> 0
		BEGIN
			SET @msg = 'The advanced rates were unable to be created.'
			RETURN @rcode
		END

		INSERT dbo.SMRateOverrideEquipment (SMCo, EntitySeq, EMCo, Equipment, RevCode, MarkupOrFlatRate, MarkupAmount, FlatRateAmount)
		SELECT SMCo, @NewEntitySeq, EMCo, Equipment, RevCode, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
		FROM dbo.SMRateOverrideEquipment
		WHERE SMCo = @SMCo AND EntitySeq = @CopyFromEntitySeq

		INSERT dbo.SMRateOverrideLabor (SMCo, EntitySeq, Seq, Technician, PRCo, Craft, Class, CallType, PayType, Rate)
		SELECT SMCo, @NewEntitySeq, Seq, Technician, PRCo, Craft, Class, CallType, PayType, Rate
		FROM dbo.SMRateOverrideLabor 
		WHERE SMCo = @SMCo AND EntitySeq = @CopyFromEntitySeq
	
		INSERT dbo.SMRateOverrideMatlBP (SMCo, EntitySeq, RateOverrideMaterialSeq, BreakPoint, [Percent])
		SELECT SMCo, @NewEntitySeq, RateOverrideMaterialSeq, BreakPoint, [Percent]
		FROM dbo.SMRateOverrideMatlBP 
		WHERE SMCo = @SMCo AND EntitySeq = @CopyFromEntitySeq

		INSERT dbo.SMRateOverrideMaterial (SMCo, EntitySeq, Seq, MatlGroup, Category, Material, MarkupOrDiscount, Basis, [Percent])
		SELECT SMCo, @NewEntitySeq, Seq, MatlGroup, Category, Material, MarkupOrDiscount, Basis, [Percent]
		FROM dbo.SMRateOverrideMaterial 
		WHERE SMCo = @SMCo AND EntitySeq = @CopyFromEntitySeq

		INSERT dbo.SMRateOverrideStandardItem (SMCo, EntitySeq, StandardItem, BillableRate, AutoAdd)
		SELECT SMCo, @NewEntitySeq, StandardItem, BillableRate, AutoAdd
		FROM dbo.SMRateOverrideStandardItem 
		WHERE SMCo = @SMCo AND EntitySeq = @CopyFromEntitySeq
    END
    
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMRateTemplateEffectiveDateCreate] TO [public]
GO
