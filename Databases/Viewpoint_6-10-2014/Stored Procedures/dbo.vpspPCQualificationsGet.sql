SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vpspPCQualificationsGet]
	-- Add the parameters for the stored procedure here
	(@VendorGroup bGroup, @Vendor bVendor)
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @rowsExist AS BIT
	
	SELECT @rowsExist = COUNT(*)
	FROM PCQualifications
	WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor

	IF @rowsExist = 0
	BEGIN
		--We ran into an issue where a portal user was set up with an invalid vendor/vendor group
		--The portal would crash so we are putting some sql in to remove the invalid vendor/vendor group and
		--alert the user to the issue
		
		RAISERROR('Your account was setup with an invalid vendor and vendor group combination. You must setup your account''s vendor and vendor group correctly before being able to use this control.', 16, 1)
	END
	ELSE
	BEGIN
		SELECT
		  [VendorGroup]
		  ,[Vendor]
		  ,[GLCo]
		  ,[ActiveYN]
		  ,[Name]
		  ,[SortName]
		  ,[Phone]
		  ,[AddnlInfo]
		  ,[Address]
		  ,[City]
		  ,[State] AS CompanyState
		  ,[Zip]
		  ,[Country] AS CompanyCountry
		  ,[Address2]
		  ,[POAddress]
		  ,[POCity]
		  ,[POState]
		  ,[POZip]
		  ,[POCountry]
		  ,[POAddress2]
		  ,[Type]
		  ,[EMail]
		  ,[URL]
		  ,[Fax]
		  ,[APVMKeyIDFromAPVM]
		  ,[APVMKeyID]
		  ,[Qualified]
		  ,dbo.vpfYesNo(Qualified) AS QualifiedDescription
		  ,[DoNotUse]
		  ,[DoNotUseReason]
		  ,[OfficeType]
		  ,[HasParentOrganization]
		  ,[ParentName]
		  ,[ParentAddress1]
		  ,[ParentAddress2]
		  ,[ParentCity]
		  ,[ParentState]
		  ,[ParentZip]
		  ,[ParentCountry]
		  ,[OrganizationType]
		  ,[OrganizationCountry]
		  ,[OrganizationState]
		  ,[OrganizationDate]
		  ,[TIN]
		  ,[OtherNames]
		  ,[CurrentExecutiveEmployees]
		  ,[CurrentOfficeEmployees]
		  ,[CurrentShopEmployees]
		  ,[CurrentJobSiteEmployees]
		  ,[CurrentTradesEmployees]
		  ,[AverageExecutiveEmployees]
		  ,[AverageOfficeEmployees]
		  ,[AverageShopEmployees]
		  ,[AverageJobSiteEmployees]
		  ,[AverageTradesEmployees]
		  ,[TradeAssociations]
		  ,[ShopType]
		  ,[OwnersOut]
		  ,[OwnersIn]
		  ,[ManagementOut]
		  ,[ManagementIn]
		  ,[PMOut]
		  ,[PMIn]
		  ,[AccountingSoftwareName]
		  ,[AccountingSoftwareRevision]
		  ,[AccountingSoftwareInstallationDate]
		  ,[AccountingSoftwareOS]
		  ,[AccountingSoftwareDatabase]
		  ,[PMSoftwareName]
		  ,[PMSoftwareRevision]
		  ,[PMSoftwareInstallationDate]
		  ,[PMSoftwareOS]
		  ,[PMSoftwareDatabase]
		  ,[PSSoftwareName]
		  ,[PSSoftwareRevision]
		  ,[PSSoftwareInstallationDate]
		  ,[PSSoftwareOS]
		  ,[PSSoftwareDatabase]
		  ,[DMSoftwareName]
		  ,[DMSoftwareRevision]
		  ,[DMSoftwareInstallationDate]
		  ,[DMSoftwareOS]
		  ,[DMSoftwareDatabase]
		  ,[JobSiteConnectionType]
		  ,[SafetyExecutiveName]
		  ,[SafetyExecutiveTitle]
		  ,[SafetyExecutivePhone]
		  ,[SafetyExecutiveEmail]
		  ,[SafetyExecutiveFax]
		  ,[SafetyExecutiveCertifications]
		  ,[SafetyInspections]
		  ,dbo.vpfYesNo(SafetyInspections) AS SafetyInspectionsDescription
		  ,[SafetyFallProtection]
		  ,dbo.vpfYesNo(SafetyFallProtection) AS SafetyFallProtectionDescription
		  ,[SafetySiteProgram]
		  ,dbo.vpfYesNo(SafetySiteProgram) AS SafetySiteProgramDescription
		  ,[SafetyPolicy]
		  ,dbo.vpfYesNo(SafetyPolicy) AS SafetyPolicyDescription
		  ,[SafetyTrainingNew]
		  ,dbo.vpfYesNo(SafetyTrainingNew) AS SafetyTrainingNewDescription
		  ,[SafetyMeetingsNewFrequency]
		  ,[SafetyMeetingsFieldFrequency]
		  ,[SafetyMeetingsEmployeesFrequency]
		  ,[SafetyMeetingsSubsFrequency]
		  ,[SafetyAnnualGoals]
		  ,dbo.vpfYesNo(SafetyAnnualGoals) AS SafetyAnnualGoalsDescription
		  ,[SafetyRecognitionProgram]
		  ,dbo.vpfYesNo(SafetyRecognitionProgram) AS SafetyRecognitionProgramDescription
		  ,[SafetyDisciplinaryProgram]
		  ,dbo.vpfYesNo(SafetyDisciplinaryProgram) AS SafetyDisciplinaryProgramDescription
		  ,[SafetyInvestigations]
		  ,dbo.vpfYesNo(SafetyInvestigations) AS SafetyInvestigationsDescription
		  ,[SafetyReviews]
		  ,dbo.vpfYesNo(SafetyReviews) AS SafetyReviewsDescription
		  ,[SafetyReturnToWorkProgram]
		  ,dbo.vpfYesNo(SafetyReturnToWorkProgram) AS SafetyReturnToWorkProgramDescription
		  ,[SafetySexualHarassment]
		  ,dbo.vpfYesNo(SafetySexualHarassment) AS SafetySexualHarassmentDescription
		  ,[SafetyAffirmativeActionPlan]
		  ,dbo.vpfYesNo(SafetyAffirmativeActionPlan) AS SafetyAffirmativeActionPlanDescription
		  ,[SafetyDisciplinaryPolicy]
		  ,dbo.vpfYesNo(SafetyDisciplinaryPolicy) AS SafetyDisciplinaryPolicyDescription
		  ,[DrugScreeningPreEmployment]
		  ,dbo.vpfYesNo(DrugScreeningPreEmployment) AS DrugScreeningPreEmploymentDescription
		  ,[DrugScreeningRandom]
		  ,dbo.vpfYesNo(DrugScreeningRandom) AS DrugScreeningRandomDescription
		  ,[DrugScreeningPeriodic]
		  ,dbo.vpfYesNo(DrugScreeningPeriodic) AS DrugScreeningPeriodicDescription
		  ,[DrugScreeningPostAccident]
		  ,dbo.vpfYesNo(DrugScreeningPostAccident) AS DrugScreeningPostAccidentDescription
		  ,[DrugScreeningOnSuspicion]
		  ,dbo.vpfYesNo(DrugScreeningOnSuspicion) AS DrugScreeningOnSuspicionDescription
		  ,[DrugScreeningRequired]
		  ,dbo.vpfYesNo(DrugScreeningRequired) AS DrugScreeningRequiredDescription
		  ,[QualityExecutiveName]
		  ,[QualityExecutiveTitle]
		  ,[QualityExecutivePhone]
		  ,[QualityExecutiveEmail]
		  ,[QualityExecutiveFax]
		  ,[QualityExecutiveCertifications]
		  ,[QualityPolicy]
		  ,dbo.vpfYesNo(QualityPolicy) AS QualityPolicyDescription
		  ,[QualityTQM]
		  ,dbo.vpfYesNo(QualityTQM) AS QualityTQMDescription
		  ,[QualityLEEDProjects]
		  ,[QualityLEEDProfessionals]
		  ,[LargestEverAmount]
		  ,[LargestEverYear]
		  ,[LargestEverProjectName]
		  ,[LargestEverGC]
		  ,[LargestEverInScope]
		  ,[LargestThisYear]
		  ,[LargestThisYearAmount]
		  ,[LargestThisYearProjectName]
		  ,[LargestThisYearGC]
		  ,[LargestThisYearInScope]
		  ,[LargestLastYear]
		  ,[LargestLastYearAmount]
		  ,[LargestLastYearProjectName]
		  ,[LargestLastYearGC]
		  ,[LargestLastYearInScope]
		  ,[ThisYearVolume]
		  ,[ThisYearProjects]
		  ,[CurrentBacklog]
		  ,[PreferMin]
		  ,[Prefer100K]
		  ,[Prefer200K]
		  ,[Prefer500K]
		  ,[Prefer1M]
		  ,[Prefer3M]
		  ,[Prefer6M]
		  ,[Prefer10M]
		  ,[Prefer15M]
		  ,[Prefer25M]
		  ,[Prefer50M]
		  ,[PreferMax]
		  ,[DBNumber]
		  ,[DBRating]
		  ,[DBPayRecord]
		  ,[DBDateOfRating]
		  ,[RevenueYear]
		  ,[RevenueAmount]
		  ,[NetIncome]
		  ,[NetEquity]
		  ,[WorkingCapital]
		  ,[AverageEmployees]
		  ,[LiquidatedDamageNotes]
		  ,[BankName]
		  ,[BankBranch]
		  ,[BankAddress1]
		  ,[BankAddress2]
		  ,[BankCity]
		  ,[BankState]
		  ,[BankCountry]
		  ,[BankZip]
		  ,[BankContact]
		  ,[BankPhone]
		  ,[BankFax]
		  ,[BankEmail]
		  ,[BankYears]
		  ,[BankLineOfCreditTotal]
		  ,[BankLineOfCreditAvailable]
		  ,[BankLineOfCreditExpiration]
		  ,[CPAName]
		  ,[CPAAddress1]
		  ,[CPAAddress2]
		  ,[CPACity]
		  ,[CPAState]
		  ,[CPACountry]
		  ,[CPAZip]
		  ,[CPAContact]
		  ,[CPAPhone]
		  ,[CPAFax]
		  ,[CPAEmail]
		  ,[CPAYears]
		  ,[CPAFinancialStatements]
		  ,[BondName]
		  ,[BondBroker]
		  ,[BondAddress1]
		  ,[BondAddress2]
		  ,[BondCity]
		  ,[BondState]
		  ,[BondCountry]
		  ,[BondZip]
		  ,[BondContact]
		  ,[BondPhone]
		  ,[BondFax]
		  ,[BondEmail]
		  ,[BondYears]
		  ,[BondCapacity]
		  ,[BondCapicityPerJob]
		  ,[BondLastDate]
		  ,[BondLastAmount]
		  ,[BondLastRate]
		  ,[BondFinishNotes]
		  ,[BondPersonalGuarantee]
		  ,dbo.vpfYesNo(BondPersonalGuarantee) AS BondPersonalGuaranteeDescription
		  ,[InsuranceName]
		  ,[InsuranceAgent]
		  ,[InsuranceAddress1]
		  ,[InsuranceAddress2]
		  ,[InsuranceCity]
		  ,[InsuranceState]
		  ,[InsuranceCountry]
		  ,[InsuranceZip]
		  ,[InsuranceContact]
		  ,[InsurancePhone]
		  ,[InsuranceFax]
		  ,[InsuranceEmail]
		  ,[InsuranceYears]
		  ,[GCLInsuranceName]
		  ,[GCLForm]
		  ,[GCLPolicyNumber]
		  ,[GCLPeriodFrom]
		  ,[GCLPeriodTo]
		  ,[GCLClaimsMade]
		  ,[GCLExclusion]
		  ,dbo.vpfYesNo(GCLExclusion) AS GCLExclusionDescription
		  ,[GCLGeneralAggregateCurrent]
		  ,[GCLGeneralAggregateMax]
		  ,[GCLProductCurrent]
		  ,[GCLProductMax]
		  ,[GCLPersonalCurrent]
		  ,[GCLPersonalMax]
		  ,[GCLEachCurrent]
		  ,[GCLEachMax]
		  ,[GCLMedicalCurrent]
		  ,[GCLMedicalMax]
		  ,[GCLFireCurrent]
		  ,[GCLFireMax]
		  ,[GCLDeductible]
		  ,[GCLPerProjectLimit]
		  ,dbo.vpfYesNo(GCLPerProjectLimit) AS GCLPerProjectLimitDescription
		  ,[ELInsuranceName]
		  ,[ELForm]
		  ,[ELPolicyNumber]
		  ,[ELPeriodFrom]
		  ,[ELPeriodTo]
		  ,[ELClaimsMade]
		  ,[ELType]
		  ,[ELEachCurrent]
		  ,[ELEachMax]
		  ,[ELAggregateCurrent]
		  ,[ELAggregateMax]
		  ,[WCInsuranceName]
		  ,[WCForm]
		  ,[WCPolicyNumber]
		  ,[WCPeriodFrom]
		  ,[WCPeriodTo]
		  ,[WCLimit]
		  ,[WCEach]
		  ,[WCEachMax]
		  ,[WCDiseaseLimit]
		  ,[WCDiseaseLimitMax]
		  ,[WCDiseaseEach]
		  ,[WCDiseaseEachMax]
		  ,[ALInsuranceName]
		  ,[ALForm]
		  ,[ALPolicyNumber]
		  ,[ALPeriodFrom]
		  ,[ALPeriodTo]
		  ,[ALCombinedCurrent]
		  ,[ALCombinedMax]
		  ,[ALBodyAccidentCurrent]
		  ,[ALBodyAccidentMax]
		  ,[ALBodyPerPersonCurrent]
		  ,[ALBodyPerPersonMax]
		  ,[ALPropertyCurrent]
		  ,[ALPropertyMax]
		  ,[PLInsuranceName]
		  ,[PLForm]
		  ,[PLPolicyNumber]
		  ,[PLPeriodFrom]
		  ,[PLPeriodTo]
		  ,[PLLimit]
		  ,[PLDeductible]
		  ,[PLProjectLimit]
		  ,[PLExtendedPeriod]
		  ,[PLPriorActs]
		  ,dbo.vpfYesNo(PLPriorActs) AS PLPriorActsDescription
		  ,[QBankrupt]
		  ,[QBankruptsNotes]
		  ,[QIndicted]
		  ,[QIndictedNotes]
		  ,[QDisbarred]
		  ,[QDisbarredNotes]
		  ,[QCompliance]
		  ,[QComplianceNotes]
		  ,[QLitigation]
		  ,[QLitigationNotes]
		  ,[QJudgements]
		  ,[QJudgementNotes]
		  ,[QLabor]
		  ,[QLaborNotes]
		  ,[Notes]
		  ,[UniqueAttchID]
		  ,[KeyID]
		  ,c0.VendorDescription AS VendorTypeDescription
		  ,c1.DisplayValue AS OrganizationTypeDescription
		  ,c2.DisplayValue AS OfficeTypeDescription
		  ,c4.DisplayValue AS ShopTypeDescription
		  ,c5.DisplayValue AS JobSiteConnectionTypeDescription
		  ,c6.DisplayValue AS SafetyMeetingsNewFrequencyDescription
		  ,c7.DisplayValue AS SafetyMeetingsFieldFrequencyDescription
		  ,c8.DisplayValue AS SafetyMeetingsEmployeesFrequencyDescription
		  ,c9.DisplayValue AS SafetyMeetingsSubsFrequencyDescription
		  ,c10.DisplayValue AS CPAFinancialStatementsDescription
		  ,c11.DisplayValue AS ELTypeDescription
		FROM PCQualifications
			LEFT JOIN pvPCVendorType c0
				ON c0.KeyField = PCQualifications.Type
			LEFT JOIN DDCI c1 
				ON c1.ComboType = 'PCOrganizationType' AND PCQualifications.OrganizationType = c1.DatabaseValue
			LEFT JOIN DDCI c2 
				ON c2.ComboType = 'PCOfficeType' AND PCQualifications.OfficeType = c2.DatabaseValue
			LEFT JOIN DDCI c4
				ON c4.ComboType = 'PCShopType' AND PCQualifications.ShopType = c4.DatabaseValue
			LEFT JOIN DDCI c5
				ON c5.ComboType = 'PCConnectivityType' AND PCQualifications.JobSiteConnectionType = c5.DatabaseValue
			LEFT JOIN DDCI c6
				ON c6.ComboType = 'PCFrequencyType' AND PCQualifications.SafetyMeetingsNewFrequency = c6.DatabaseValue
			LEFT JOIN DDCI c7
				ON c7.ComboType = 'PCFrequencyType' AND PCQualifications.SafetyMeetingsFieldFrequency = c7.DatabaseValue
			LEFT JOIN DDCI c8
				ON c8.ComboType = 'PCFrequencyType' AND PCQualifications.SafetyMeetingsEmployeesFrequency = c8.DatabaseValue
			LEFT JOIN DDCI c9
				ON c9.ComboType = 'PCFrequencyType' AND PCQualifications.SafetyMeetingsSubsFrequency = c9.DatabaseValue
			LEFT JOIN DDCI c10
				ON c10.ComboType = 'PCFinancialStatement' AND PCQualifications.CPAFinancialStatements = c10.DatabaseValue	
			LEFT JOIN DDCI c11
				ON c11.ComboType = 'PCELType' AND PCQualifications.ELType = c11.DatabaseValue
		WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor
	END
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsGet] TO [VCSPortal]
GO
