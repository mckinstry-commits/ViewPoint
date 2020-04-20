SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/17/11
-- Description:	Creates a new SM Effective Date Rate template by copying from an existing basic rate template or effective date rate template.
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
    
    DECLARE @rcode int, @CopyFromSMGenericEntityID bigint, @NewSMGenericEntityID bigint
    
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

		SELECT @CopyFromSMGenericEntityID = SMGenericEntityID
		FROM dbo.SMGenericEntity
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
		
		SELECT @CopyFromSMGenericEntityID = SMGenericEntityID
		FROM dbo.SMGenericEntity
		WHERE SMCo = @SMCo AND RateTemplate = @CopyFromRateTemplate AND EffectiveDate = @CopyFromEffectiveDate
    END

	--The advance rates need to be copied over if any exist
    IF @CopyFromSMGenericEntityID IS NOT NULL
		AND EXISTS(SELECT 1 FROM dbo.vfSMGetAdvancedRatesExists(@CopyFromSMGenericEntityID) WHERE EquipmentOverridesExist = 'Y' OR LaborOverridesExist = 'Y' OR MaterialOverridesExist = 'Y' OR StandardItemOverridesExist = 'Y')
    BEGIN  
		EXEC @rcode = dbo.vspSMGenericEntityCreate @SMCo = @SMCo, @RateTemplate = @NewRateTemplate, @EffectiveDate = @NewEffectiveDate, @SMGenericEntityID = @NewSMGenericEntityID OUTPUT
		
		IF @rcode <> 0
		BEGIN
			SET @msg = 'The advanced rates were unable to be created.'
			RETURN @rcode
		END

		UPDATE dbo.SMRateTemplateEffectiveDate
		SET SMRateOverrideID = @NewSMGenericEntityID
		WHERE SMCo = @SMCo AND RateTemplate = @NewRateTemplate AND EffectiveDate = @NewEffectiveDate

		INSERT dbo.SMRateOverrideEquipment (SMRateOverrideID, EMCo, Equipment, RevCode, MarkupOrFlatRate, MarkupAmount, FlatRateAmount)
		SELECT @NewSMGenericEntityID, EMCo, Equipment, RevCode, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
		FROM dbo.SMRateOverrideEquipment
		WHERE SMRateOverrideID = @CopyFromSMGenericEntityID

		INSERT dbo.SMRateOverrideLabor (SMRateOverrideID, Seq, SMCo, Technician, PRCo, Craft, Class, CallType, PayType, Rate)
		SELECT @NewSMGenericEntityID, Seq, SMCo, Technician, PRCo, Craft, Class, CallType, PayType, Rate
		FROM dbo.SMRateOverrideLabor 
		WHERE SMRateOverrideID = @CopyFromSMGenericEntityID
	
		INSERT dbo.SMRateOverrideMatlBP (SMRateOverrideID, RateOverrideMaterialSeq, BreakPoint, [Percent])
		SELECT @NewSMGenericEntityID, RateOverrideMaterialSeq, BreakPoint, [Percent]
		FROM dbo.SMRateOverrideMatlBP 
		WHERE SMRateOverrideID = @CopyFromSMGenericEntityID

		INSERT dbo.SMRateOverrideMaterial (SMRateOverrideID, Seq, MatlGroup, Category, Material, MarkupOrDiscount, Basis, [Percent])
		SELECT @NewSMGenericEntityID, Seq, MatlGroup, Category, Material, MarkupOrDiscount, Basis, [Percent]
		FROM dbo.SMRateOverrideMaterial 
		WHERE SMRateOverrideID = @CopyFromSMGenericEntityID

		INSERT dbo.SMRateOverrideStandardItem (SMRateOverrideID, SMCo, StandardItem, BillableRate, AutoAdd)
		SELECT @NewSMGenericEntityID, SMCo, StandardItem, BillableRate, AutoAdd
		FROM dbo.SMRateOverrideStandardItem 
		WHERE SMRateOverrideID = @CopyFromSMGenericEntityID
    END
    
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMRateTemplateEffectiveDateCreate] TO [public]
GO
