SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsInsuranceUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @InsuranceAgent VARCHAR(60), @InsuranceName VARCHAR(60), @InsurancePhone bPhone, @InsuranceFax bPhone, @InsuranceContact VARCHAR(30), @InsuranceEmail VARCHAR(60), @InsuranceYears TINYINT, @InsuranceAddress1 VARCHAR(60), @InsuranceCity VARCHAR(30), @InsuranceState VARCHAR(4), @InsuranceZip bZip, @InsuranceCountry CHAR(2), @InsuranceAddress2 VARCHAR(60), @WCInsuranceName VARCHAR(60), @WCForm VARCHAR(60), @WCPolicyNumber VARCHAR(60), @WCPeriodFrom bDate, @WCPeriodTo bDate, @WCEach NUMERIC(18,0), @WCEachMax NUMERIC(18,0), @WCDiseaseLimit NUMERIC(18,0), @WCDiseaseLimitMax NUMERIC(18,0), @WCDiseaseEach NUMERIC(18,0), @WCDiseaseEachMax NUMERIC(18,0), @WCLimit NUMERIC(18,0), @PLInsuranceName VARCHAR(60), @PLForm VARCHAR(30), @PLPolicyNumber VARCHAR(60), @PLPeriodFrom bDate, @PLPeriodTo bDate, @PLDeductible NUMERIC(18,0), @PLExtendedPeriod TINYINT, @PLProjectLimit NUMERIC(18,0), @PLPriorActs bYN, @GCLInsuranceName VARCHAR(60), @GCLForm VARCHAR(60), @GCLPolicyNumber VARCHAR(60), @GCLPeriodFrom bDate, @GCLPeriodTo bDate, @GCLClaimsMade SMALLINT, @GCLExclusion bYN, @GCLGeneralAggregateCurrent NUMERIC(18,0), @GCLGeneralAggregateMax NUMERIC(18,0), @GCLProductCurrent NUMERIC(18,0), @GCLProductMax NUMERIC(18,0), @GCLPersonalCurrent NUMERIC(18,0), @GCLPersonalMax NUMERIC(18,0), @GCLEachCurrent NUMERIC(18,0), @GCLEachMax NUMERIC(18,0), @GCLMedicalCurrent NUMERIC(18,0), @GCLMedicalMax NUMERIC(18,0), @GCLFireCurrent NUMERIC(18,0), @GCLFireMax NUMERIC(18,0), @GCLDeductible NUMERIC(18,0), @GCLPerProjectLimit bYN, @ELInsuranceName VARCHAR(60), @ELForm VARCHAR(60), @ELPolicyNumber VARCHAR(60), @ELPeriodFrom bDate, @ELPeriodTo bDate, @ELType TINYINT, @ELClaimsMade SMALLINT, @ELAggregateCurrent NUMERIC(18,0), @ELAggregateMax NUMERIC(18,0), @ELEachCurrent NUMERIC(18,0), @ELEachMax NUMERIC(18,0), @ALInsuranceName VARCHAR(60), @ALForm VARCHAR(30), @ALPolicyNumber VARCHAR(60), @ALPeriodFrom bDate, @ALPeriodTo bDate, @ALCombinedCurrent NUMERIC(18,0), @ALCombinedMax NUMERIC(18,0), @ALBodyAccidentCurrent NUMERIC(18,0), @ALBodyAccidentMax NUMERIC(18,0), @ALBodyPerPersonCurrent NUMERIC(18,0), @ALBodyPerPersonMax NUMERIC(18,0), @ALPropertyCurrent NUMERIC(18,0), @ALPropertyMax NUMERIC(18,0))
AS
SET NOCOUNT ON;

BEGIN
	-- Validation
	DECLARE @rcode INT, @msg VARCHAR(255)
	
	EXEC @rcode = vpspPCValidateStateCountry @InsuranceState, @InsuranceCountry
	IF @rcode != 0
	BEGIN
		GOTO vpspExit
	END
	
	IF (NOT @PLPeriodFrom IS NULL AND NOT @PLPeriodTo IS NULL)
	BEGIN
		IF @PLPeriodFrom >= @PLPeriodTo
		BEGIN
			SELECT @rcode = 1, @msg = 'Professional Liability: Period From date must be before Period To date.'
			RAISERROR(@msg, 11, -1);
			GOTO vpspExit
		END
	END
	
	IF (NOT @WCPeriodFrom IS NULL AND NOT @WCPeriodTo IS NULL)
	BEGIN
		IF @WCPeriodFrom >= @WCPeriodTo
		BEGIN
			SELECT @rcode = 1, @msg = 'Workers Comp. Liability: Period From date must be before Period To date.'
			RAISERROR(@msg, 11, -1);
			GOTO vpspExit
		END
	END
	
	IF (NOT @ELPeriodFrom IS NULL AND NOT @ELPeriodTo IS NULL)
	BEGIN
		IF @ELPeriodFrom >= @ELPeriodTo
		BEGIN
			SELECT @rcode = 1, @msg = 'Excess Liability: Period From date must be before Period To date.'
			RAISERROR(@msg, 11, -1);
			GOTO vpspExit
		END
	END
	
	IF (NOT @GCLPeriodFrom IS NULL AND NOT @GCLPeriodTo IS NULL)
	BEGIN
		IF @GCLPeriodFrom >= @GCLPeriodTo
		BEGIN
			SELECT @rcode = 1, @msg = 'Commercial General Liability: Period From date must be before Period To date.'
			RAISERROR(@msg, 11, -1);
			GOTO vpspExit
		END
	END
	
	IF (NOT @ALPeriodFrom IS NULL AND NOT @ALPeriodTo IS NULL)
	BEGIN
		IF @ALPeriodFrom >= @ALPeriodTo
		BEGIN
			SELECT @rcode = 1, @msg = 'Automobile Liability: Period From date must be before Period To date.'
			RAISERROR(@msg, 11, -1);
			GOTO vpspExit
		END
	END
	
	-- Validation successful
	UPDATE PCQualifications
	SET
		InsuranceAgent = @InsuranceAgent,
		InsuranceName = @InsuranceName,
		InsurancePhone = @InsurancePhone,
		InsuranceFax = @InsuranceFax,
		InsuranceContact = @InsuranceContact,
		InsuranceEmail = @InsuranceEmail,
		InsuranceYears = @InsuranceYears,
		InsuranceAddress1 = @InsuranceAddress1,
		InsuranceCity = @InsuranceCity,
		InsuranceState = @InsuranceState,
		InsuranceZip = @InsuranceZip,
		InsuranceCountry = @InsuranceCountry,
		InsuranceAddress2 = @InsuranceAddress2,
		WCInsuranceName = @WCInsuranceName,
		WCForm = @WCForm,
		WCPolicyNumber = @WCPolicyNumber,
		WCPeriodFrom = @WCPeriodFrom,
		WCPeriodTo = @WCPeriodTo,
		WCEach = @WCEach,
		WCEachMax = @WCEachMax,
		WCDiseaseLimit = @WCDiseaseLimit,
		WCDiseaseLimitMax = @WCDiseaseLimitMax,
		WCDiseaseEach = @WCDiseaseEach,
		WCDiseaseEachMax = @WCDiseaseEachMax,
		WCLimit = @WCLimit,
		PLInsuranceName = @PLInsuranceName,
		PLForm = @PLForm,
		PLPolicyNumber = @PLPolicyNumber,
		PLPeriodFrom = @PLPeriodFrom,
		PLPeriodTo = @PLPeriodTo,
		PLDeductible = @PLDeductible,
		PLExtendedPeriod = @PLExtendedPeriod,
		PLProjectLimit = @PLProjectLimit,
		PLPriorActs = @PLPriorActs,
		GCLInsuranceName = @GCLInsuranceName,
		GCLForm = @GCLForm,
		GCLPolicyNumber = @GCLPolicyNumber,
		GCLPeriodFrom = @GCLPeriodFrom,
		GCLPeriodTo = @GCLPeriodTo,
		GCLClaimsMade = @GCLClaimsMade,
		GCLExclusion = @GCLExclusion,
		GCLGeneralAggregateCurrent = @GCLGeneralAggregateCurrent,
		GCLGeneralAggregateMax = @GCLGeneralAggregateMax,
		GCLProductCurrent = @GCLProductCurrent,
		GCLProductMax = @GCLProductMax,
		GCLPersonalCurrent = @GCLPersonalCurrent,
		GCLPersonalMax = @GCLPersonalMax,
		GCLEachCurrent = @GCLEachCurrent,
		GCLEachMax = @GCLEachMax,
		GCLMedicalCurrent = @GCLMedicalCurrent,
		GCLMedicalMax = @GCLMedicalMax,
		GCLFireCurrent = @GCLFireCurrent,
		GCLFireMax = @GCLFireMax,
		GCLDeductible = @GCLDeductible,
		GCLPerProjectLimit = @GCLPerProjectLimit,
		ELInsuranceName = @ELInsuranceName,
		ELForm = @ELForm,
		ELPolicyNumber = @ELPolicyNumber,
		ELPeriodFrom = @ELPeriodFrom,
		ELPeriodTo = @ELPeriodTo,
		ELType = @ELType,
		ELClaimsMade = @ELClaimsMade,
		ELAggregateCurrent = @ELAggregateCurrent,
		ELAggregateMax = @ELAggregateMax,
		ELEachCurrent = @ELEachCurrent,
		ELEachMax = @ELEachMax,
		ALInsuranceName = @ALInsuranceName,
		ALForm = @ALForm,
		ALPolicyNumber = @ALPolicyNumber,
		ALPeriodFrom = @ALPeriodFrom,
		ALPeriodTo = @ALPeriodTo,
		ALCombinedCurrent = @ALCombinedCurrent,
		ALCombinedMax = @ALCombinedMax,
		ALBodyAccidentCurrent = @ALBodyAccidentCurrent,
		ALBodyAccidentMax = @ALBodyAccidentMax,
		ALBodyPerPersonCurrent = @ALBodyPerPersonCurrent,
		ALBodyPerPersonMax = @ALBodyPerPersonMax,
		ALPropertyCurrent = @ALPropertyCurrent,
		ALPropertyMax = @ALPropertyMax
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
	
vpspExit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsInsuranceUpdate] TO [VCSPortal]
GO
