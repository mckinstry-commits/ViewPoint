CREATE TABLE [dbo].[vPCQualifications]
(
[APVMKeyID] [bigint] NOT NULL,
[Qualified] [dbo].[bYN] NULL,
[DoNotUse] [dbo].[bYN] NULL,
[DoNotUseReason] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OfficeType] [char] (1) COLLATE Latin1_General_BIN NULL,
[HasParentOrganization] [dbo].[bYN] NULL,
[ParentName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ParentAddress1] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ParentAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ParentCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ParentState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ParentZip] [dbo].[bZip] NULL,
[ParentCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[OrganizationType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OrganizationCountry] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[OrganizationState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OrganizationDate] [dbo].[bDate] NULL,
[TIN] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OtherNames] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[CurrentExecutiveEmployees] [int] NULL,
[CurrentOfficeEmployees] [int] NULL,
[CurrentShopEmployees] [int] NULL,
[CurrentJobSiteEmployees] [int] NULL,
[CurrentTradesEmployees] [int] NULL,
[AverageExecutiveEmployees] [int] NULL,
[AverageOfficeEmployees] [int] NULL,
[AverageShopEmployees] [int] NULL,
[AverageJobSiteEmployees] [int] NULL,
[AverageTradesEmployees] [int] NULL,
[TradeAssociations] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShopType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OwnersOut] [smallint] NULL,
[OwnersIn] [smallint] NULL,
[ManagementOut] [smallint] NULL,
[ManagementIn] [smallint] NULL,
[PMOut] [smallint] NULL,
[PMIn] [smallint] NULL,
[AccountingSoftwareName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AccountingSoftwareRevision] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[AccountingSoftwareInstallationDate] [dbo].[bDate] NULL,
[AccountingSoftwareOS] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AccountingSoftwareDatabase] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PMSoftwareName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PMSoftwareRevision] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PMSoftwareInstallationDate] [dbo].[bDate] NULL,
[PMSoftwareOS] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PMSoftwareDatabase] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PSSoftwareName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PSSoftwareRevision] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PSSoftwareInstallationDate] [dbo].[bDate] NULL,
[PSSoftwareOS] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PSSoftwareDatabase] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DMSoftwareName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[DMSoftwareRevision] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DMSoftwareInstallationDate] [dbo].[bDate] NULL,
[DMSoftwareOS] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DMSoftwareDatabase] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[JobSiteConnectionType] [char] (1) COLLATE Latin1_General_BIN NULL,
[SafetyExecutiveName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SafetyExecutiveTitle] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SafetyExecutivePhone] [dbo].[bPhone] NULL,
[SafetyExecutiveEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SafetyExecutiveFax] [dbo].[bPhone] NULL,
[SafetyExecutiveCertifications] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SafetyInspections] [dbo].[bYN] NULL,
[SafetyFallProtection] [dbo].[bYN] NULL,
[SafetySiteProgram] [dbo].[bYN] NULL,
[SafetyPolicy] [dbo].[bYN] NULL,
[SafetyTrainingNew] [dbo].[bYN] NULL,
[SafetyMeetingsNew] [dbo].[bYN] NULL,
[SafetyMeetingsNewFrequency] [tinyint] NULL,
[SafetyMeetingsField] [dbo].[bYN] NULL,
[SafetyMeetingsFieldFrequency] [tinyint] NULL,
[SafetyMeetingsEmployees] [dbo].[bYN] NULL,
[SafetyMeetingsEmployeesFrequency] [tinyint] NULL,
[SafetyMeetingsSubs] [dbo].[bYN] NULL,
[SafetyMeetingsSubsFrequency] [tinyint] NULL,
[SafetyAnnualGoals] [dbo].[bYN] NULL,
[SafetyRecognitionProgram] [dbo].[bYN] NULL,
[SafetyDisciplinaryProgram] [dbo].[bYN] NULL,
[SafetyInvestigations] [dbo].[bYN] NULL,
[SafetyReviews] [dbo].[bYN] NULL,
[SafetyReturnToWorkProgram] [dbo].[bYN] NULL,
[SafetySexualHarassment] [dbo].[bYN] NULL,
[SafetyAffirmativeActionPlan] [dbo].[bYN] NULL,
[SafetyDisciplinaryPolicy] [dbo].[bYN] NULL,
[DrugScreeningPreEmployment] [dbo].[bYN] NULL,
[DrugScreeningRandom] [dbo].[bYN] NULL,
[DrugScreeningPeriodic] [dbo].[bYN] NULL,
[DrugScreeningPostAccident] [dbo].[bYN] NULL,
[DrugScreeningOnSuspicion] [dbo].[bYN] NULL,
[DrugScreeningRequired] [dbo].[bYN] NULL,
[QualityExecutiveName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[QualityExecutiveTitle] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[QualityExecutivePhone] [dbo].[bPhone] NULL,
[QualityExecutiveEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[QualityExecutiveFax] [dbo].[bPhone] NULL,
[QualityExecutiveCertifications] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[QualityPolicy] [dbo].[bYN] NULL,
[QualityTQM] [dbo].[bYN] NULL,
[QualityLeedsCertified] [dbo].[bYN] NULL,
[QualityLeedsExperience] [dbo].[bYN] NULL,
[LargestEverAmount] [numeric] (18, 0) NULL,
[LargestEverYear] [smallint] NULL,
[LargestEverProjectName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LargestEverGC] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LargestEverInScope] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LargestThisYear] [smallint] NULL,
[LargestThisYearAmount] [numeric] (18, 0) NULL,
[LargestThisYearProjectName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LargestThisYearGC] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LargestThisYearInScope] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LargestLastYear] [smallint] NULL,
[LargestLastYearAmount] [numeric] (18, 0) NULL,
[LargestLastYearProjectName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LargestLastYearGC] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LargestLastYearInScope] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ThisYearVolume] [numeric] (18, 0) NULL,
[ThisYearProjects] [int] NULL,
[CurrentBacklog] [numeric] (18, 0) NULL,
[PreferMin] [tinyint] NULL,
[Prefer100K] [tinyint] NULL,
[Prefer200K] [tinyint] NULL,
[Prefer500K] [tinyint] NULL,
[Prefer1M] [tinyint] NULL,
[Prefer3M] [tinyint] NULL,
[Prefer6M] [tinyint] NULL,
[Prefer10M] [tinyint] NULL,
[Prefer15M] [tinyint] NULL,
[Prefer25M] [tinyint] NULL,
[Prefer50M] [tinyint] NULL,
[PreferMax] [tinyint] NULL,
[DBNumber] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DBRating] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[DBPayRecord] [tinyint] NULL,
[DBDateOfRating] [dbo].[bDate] NULL,
[RevenueYear] [smallint] NULL,
[RevenueAmount] [numeric] (18, 0) NULL,
[NetIncome] [numeric] (18, 0) NULL,
[NetEquity] [numeric] (18, 0) NULL,
[WorkingCapital] [numeric] (18, 0) NULL,
[AverageEmployees] [int] NULL,
[LiquidatedDamages] [dbo].[bYN] NULL,
[LiquidatedDamageNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BankName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BankBranch] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BankAddress1] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BankAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BankCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BankState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[BankCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[BankZip] [dbo].[bZip] NULL,
[BankContact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BankPhone] [dbo].[bPhone] NULL,
[BankFax] [dbo].[bPhone] NULL,
[BankEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BankYears] [tinyint] NULL,
[BankLineOfCreditTotal] [numeric] (18, 0) NULL,
[BankLineOfCreditAvailable] [numeric] (18, 0) NULL,
[BankLineOfCreditExpiration] [dbo].[bDate] NULL,
[CPAName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CPAAddress1] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CPAAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CPACity] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CPAState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[CPACountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[CPAZip] [dbo].[bZip] NULL,
[CPAContact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CPAPhone] [dbo].[bPhone] NULL,
[CPAFax] [dbo].[bPhone] NULL,
[CPAEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[CPAYears] [tinyint] NULL,
[CPAFinancialStatements] [tinyint] NULL,
[BondName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BondBroker] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BondAddress1] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BondAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BondCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BondState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[BondCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[BondZip] [dbo].[bZip] NULL,
[BondContact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BondPhone] [dbo].[bPhone] NULL,
[BondFax] [dbo].[bPhone] NULL,
[BondEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BondYears] [tinyint] NULL,
[BondCapacity] [numeric] (18, 0) NULL,
[BondCapicityPerJob] [numeric] (18, 0) NULL,
[BondLastDate] [dbo].[bDate] NULL,
[BondLastAmount] [numeric] (18, 0) NULL,
[BondLastRate] [dbo].[bRate] NULL,
[BondFinish] [dbo].[bYN] NULL,
[BondFinishNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BondPersonalGuarantee] [dbo].[bYN] NULL,
[InsuranceName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[InsuranceAgent] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[InsuranceAddress1] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[InsuranceAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[InsuranceCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InsuranceState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[InsuranceCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[InsuranceZip] [dbo].[bZip] NULL,
[InsuranceContact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InsurancePhone] [dbo].[bPhone] NULL,
[InsuranceFax] [dbo].[bPhone] NULL,
[InsuranceEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[InsuranceYears] [tinyint] NULL,
[GCLInsuranceName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GCLForm] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GCLPolicyNumber] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[GCLPeriodFrom] [dbo].[bDate] NULL,
[GCLPeriodTo] [dbo].[bDate] NULL,
[GCLClaimsMade] [smallint] NULL,
[GCLExclusion] [dbo].[bYN] NULL,
[GCLGeneralAggregateCurrent] [numeric] (18, 0) NULL,
[GCLGeneralAggregateMax] [numeric] (18, 0) NULL,
[GCLProductCurrent] [numeric] (18, 0) NULL,
[GCLProductMax] [numeric] (18, 0) NULL,
[GCLPersonalCurrent] [numeric] (18, 0) NULL,
[GCLPersonalMax] [numeric] (18, 0) NULL,
[GCLEachCurrent] [numeric] (18, 0) NULL,
[GCLEachMax] [numeric] (18, 0) NULL,
[GCLMedicalCurrent] [numeric] (18, 0) NULL,
[GCLMedicalMax] [numeric] (18, 0) NULL,
[GCLFireCurrent] [numeric] (18, 0) NULL,
[GCLFireMax] [numeric] (18, 0) NULL,
[GCLDeductible] [numeric] (18, 0) NULL,
[GCLPerProjectLimit] [dbo].[bYN] NULL,
[ELInsuranceName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ELForm] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ELPolicyNumber] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ELPeriodFrom] [dbo].[bDate] NULL,
[ELPeriodTo] [dbo].[bDate] NULL,
[ELClaimsMade] [smallint] NULL,
[ELType] [tinyint] NULL,
[ELEachCurrent] [numeric] (18, 0) NULL,
[ELEachMax] [numeric] (18, 0) NULL,
[ELAggregateCurrent] [numeric] (18, 0) NULL,
[ELAggregateMax] [numeric] (18, 0) NULL,
[WCInsuranceName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[WCForm] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[WCPolicyNumber] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[WCPeriodFrom] [dbo].[bDate] NULL,
[WCPeriodTo] [dbo].[bDate] NULL,
[WCLimit] [numeric] (18, 0) NULL,
[WCEach] [numeric] (18, 0) NULL,
[WCEachMax] [numeric] (18, 0) NULL,
[WCDiseaseLimit] [numeric] (18, 0) NULL,
[WCDiseaseLimitMax] [numeric] (18, 0) NULL,
[WCDiseaseEach] [numeric] (18, 0) NULL,
[WCDiseaseEachMax] [numeric] (18, 0) NULL,
[ALInsuranceName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ALForm] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ALPolicyNumber] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ALPeriodFrom] [dbo].[bDate] NULL,
[ALPeriodTo] [dbo].[bDate] NULL,
[ALCombinedCurrent] [numeric] (18, 0) NULL,
[ALCombinedMax] [numeric] (18, 0) NULL,
[ALBodyAccidentCurrent] [numeric] (18, 0) NULL,
[ALBodyAccidentMax] [numeric] (18, 0) NULL,
[ALBodyPerPersonCurrent] [numeric] (18, 0) NULL,
[ALBodyPerPersonMax] [numeric] (18, 0) NULL,
[ALPropertyCurrent] [numeric] (18, 0) NULL,
[ALPropertyMax] [numeric] (18, 0) NULL,
[PLInsuranceName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PLForm] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PLPolicyNumber] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PLPeriodFrom] [dbo].[bDate] NULL,
[PLPeriodTo] [dbo].[bDate] NULL,
[PLLimit] [numeric] (18, 0) NULL,
[PLDeductible] [numeric] (18, 0) NULL,
[PLProjectLimit] [numeric] (18, 0) NULL,
[PLExtendedPeriod] [tinyint] NULL,
[PLPriorActs] [dbo].[bYN] NULL,
[QBankrupt] [dbo].[bYN] NULL,
[QBankruptsNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QIndicted] [dbo].[bYN] NULL,
[QIndictedNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QDisbarred] [dbo].[bYN] NULL,
[QDisbarredNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QCompliance] [dbo].[bYN] NULL,
[QComplianceNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QLitigation] [dbo].[bYN] NULL,
[QLitigationNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QJudgements] [dbo].[bYN] NULL,
[QJudgementNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QLabor] [dbo].[bYN] NULL,
[QLaborNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DoNotUseChangedBy] [dbo].[bVPUserName] NULL,
[DoNotUseChangedDate] [dbo].[bDate] NULL,
[QualifiedChangedBy] [dbo].[bVPUserName] NULL,
[QualifiedChangedDate] [dbo].[bDate] NULL,
[QualifiedNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OrganizationEstablished] [dbo].[bDate] NULL,
[QualityLEEDProjects] [tinyint] NULL,
[QualityLEEDProfessionals] [tinyint] NULL,
[Preferred] [dbo].[bYN] NULL,
[PreferredChangedBy] [dbo].[bVPUserName] NULL,
[PreferredChangedDate] [dbo].[bDate] NULL,
[PreferredNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[vtPCQualificationsi]
   ON  [dbo].[vPCQualifications]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @errMsg VARCHAR(255)

--Parent Organization validation
	-- Validate Parent Organization Country
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE ParentCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Parent Organization Country'
		GOTO error
	END
	
	-- Validate Parent Organization State
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE ParentState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Parent Organization State'
		GOTO error
	END
	
	-- Validate Parent Organization Country/Parent Organization State combinations
	IF EXISTS(
		SELECT TOP 1 1 
		FROM (SELECT ParentState, ParentCountry FROM INSERTED WHERE ParentCountry IS NOT NULL AND ParentState IS NOT NULL) i 
		LEFT JOIN HQST hqst(NOLOCK) ON i.ParentCountry = hqst.Country AND i.ParentState = hqst.[State]
		WHERE [State] IS NULL)
	BEGIN
		SELECT @errMsg = 'Invalid Parent Organization Country and Parent Organization State combination'
		GOTO error
	END
	
--	Incorportaion validation
	-- Validate Incorportaion Country
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE OrganizationCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Incorportaion Country'
		GOTO error
	END
	
	-- Validate Incorportaion State
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE OrganizationState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Incorportaion State'
		GOTO error
	END
	
	-- Validate Incorportaion Country/Incorportaion State combinations
	IF EXISTS(
		SELECT TOP 1 1 
		FROM (SELECT OrganizationState, OrganizationCountry FROM INSERTED WHERE OrganizationCountry IS NOT NULL AND OrganizationState IS NOT NULL) i 
		LEFT JOIN HQST hqst(NOLOCK) ON i.OrganizationCountry = hqst.Country AND i.OrganizationState = hqst.[State]
		WHERE [State] IS NULL)
	BEGIN
		SELECT @errMsg = 'Invalid Incorportaion Country and Incorportaion State combination'
		GOTO error
	END
	
--	Bank validation
	-- Validate Bank Country
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE BankCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Bank Country'
		GOTO error
	END
	
	-- Validate Bank State
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE BankState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Bank State'
		GOTO error
	END
	
	-- Validate Bank Country/Bank State combinations
	IF EXISTS(
		SELECT TOP 1 1 
		FROM (SELECT BankState, BankCountry FROM INSERTED WHERE BankCountry IS NOT NULL AND BankState IS NOT NULL) i 
		LEFT JOIN HQST hqst(NOLOCK) ON i.BankCountry = hqst.Country AND i.BankState = hqst.[State]
		WHERE [State] IS NULL)
	BEGIN
		SELECT @errMsg = 'Invalid Bank Country and Bank State combination'
		GOTO error
	END
	
--	CPA validation
	-- Validate CPA Country
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE CPACountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid CPA Country'
		GOTO error
	END
	
	-- Validate CPA State
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE CPAState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid CPA State'
		GOTO error
	END
	
	-- Validate CPA Country/CPA State combinations
	IF EXISTS(
		SELECT TOP 1 1 
		FROM (SELECT CPAState, CPACountry FROM INSERTED WHERE CPACountry IS NOT NULL AND CPAState IS NOT NULL) i 
		LEFT JOIN HQST hqst(NOLOCK) ON i.CPACountry = hqst.Country AND i.CPAState = hqst.[State]
		WHERE [State] IS NULL)
	BEGIN
		SELECT @errMsg = 'Invalid CPA Country and CPA State combination'
		GOTO error
	END
	
--	Bond validation
	-- Validate Bond Country
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE BondCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Bond Country'
		GOTO error
	END
	
	-- Validate Bond State
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE BondState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Bond State'
		GOTO error
	END
	
	-- Validate Bond Country/Bond State combinations
	IF EXISTS(
		SELECT TOP 1 1 
		FROM (SELECT BondState, BondCountry FROM INSERTED WHERE BondCountry IS NOT NULL AND BondState IS NOT NULL) i 
		LEFT JOIN HQST hqst(NOLOCK) ON i.BondCountry = hqst.Country AND i.BondState = hqst.[State]
		WHERE [State] IS NULL)
	BEGIN
		SELECT @errMsg = 'Invalid Bond Country and Bond State combination'
		GOTO error
	END
	
--	Insurance validation
	-- Validate Insurance Country
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE InsuranceCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Insurance Country'
		GOTO error
	END
	
	-- Validate Insurance State
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE InsuranceState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Insurance State'
		GOTO error
	END
	
	-- Validate Insurance Country/Insurance State combinations
	IF EXISTS(
		SELECT TOP 1 1 
		FROM (SELECT InsuranceState, InsuranceCountry FROM INSERTED WHERE InsuranceCountry IS NOT NULL AND InsuranceState IS NOT NULL) i 
		LEFT JOIN HQST hqst(NOLOCK) ON i.InsuranceCountry = hqst.Country AND i.InsuranceState = hqst.[State]
		WHERE [State] IS NULL)
	BEGIN
		SELECT @errMsg = 'Invalid Insurance Country and Insurance State combination'
		GOTO error
	END
	
	RETURN

error:
	SELECT @errMsg = @errMsg +  ' - cannot insert PC Qualifications!'
	RAISERROR(@errMsg, 11, -1);
	ROLLBACK TRANSACTION

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Modified By:	GP 6/14/2011 - TK-06080 Set Active flag in APVM when Qualified flag set.
--				NH 6/14/2012 - TK-15726 Removed APVM update because it was setting ALL
--							   of the vendors to qualified, update now happens on the view
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[vtPCQualificationsu]
   ON  [dbo].[vPCQualifications]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @errMsg VARCHAR(255)

--Parent Organization validation
	-- Validate Parent Organization Country
	IF UPDATE(ParentCountry)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE ParentCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Parent Organization Country'
			GOTO error
		END
	END
	
	-- Validate Parent Organization State
	IF UPDATE(ParentState)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE ParentState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Parent Organization State'
			GOTO error
		END
	END
	
	-- Validate Parent Organization Country/Parent Organization State combinations
	IF UPDATE(ParentCountry) OR UPDATE(ParentState)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1 
			FROM (SELECT ParentState, ParentCountry FROM INSERTED WHERE ParentCountry IS NOT NULL AND ParentState IS NOT NULL) i 
			LEFT JOIN HQST hqst(NOLOCK) ON i.ParentCountry = hqst.Country AND i.ParentState = hqst.[State]
			WHERE [State] IS NULL)
		BEGIN
			SELECT @errMsg = 'Invalid Parent Organization Country and Parent Organization State combination'
			GOTO error
		END
	END
	
--	Incorportaion validation
	-- Validate Incorportaion Country
	IF UPDATE(OrganizationCountry)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE OrganizationCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Incorportaion Country'
			GOTO error
		END
	END
	
	-- Validate Incorportaion State
	IF UPDATE(OrganizationState)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE OrganizationState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Incorportaion State'
			GOTO error
		END
	END
	
	-- Validate Incorportaion Country/Incorportaion State combinations
	IF UPDATE(OrganizationCountry) OR UPDATE(OrganizationState)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1 
			FROM (SELECT OrganizationState, OrganizationCountry FROM INSERTED WHERE OrganizationCountry IS NOT NULL AND OrganizationState IS NOT NULL) i 
			LEFT JOIN HQST hqst(NOLOCK) ON i.OrganizationCountry = hqst.Country AND i.OrganizationState = hqst.[State]
			WHERE [State] IS NULL)
		BEGIN
			SELECT @errMsg = 'Invalid Incorportaion Country and Incorportaion State combination'
			GOTO error
		END
	END
	
--	Bank validation
	-- Validate Bank Country
	IF UPDATE(BankCountry)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE BankCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Bank Country'
			GOTO error
		END
	END
	
	-- Validate Bank State
	IF UPDATE(BankState)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE BankState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Bank State'
			GOTO error
		END
	END
	
	-- Validate Bank Country/Bank State combinations
	IF UPDATE(BankCountry) OR UPDATE(BankState)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1 
			FROM (SELECT BankState, BankCountry FROM INSERTED WHERE BankCountry IS NOT NULL AND BankState IS NOT NULL) i 
			LEFT JOIN HQST hqst(NOLOCK) ON i.BankCountry = hqst.Country AND i.BankState = hqst.[State]
			WHERE [State] IS NULL)
		BEGIN
			SELECT @errMsg = 'Invalid Bank Country and Bank State combination'
			GOTO error
		END
	END
	
--	CPA validation
	-- Validate CPA Country
	IF UPDATE(CPACountry)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE CPACountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid CPA Country'
			GOTO error
		END
	END
	
	-- Validate CPA State
	IF UPDATE(CPAState)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE CPAState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid CPA State'
			GOTO error
		END
	END
	
	-- Validate CPA Country/CPA State combinations
	IF UPDATE(CPACountry) OR UPDATE(CPAState)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1 
			FROM (SELECT CPAState, CPACountry FROM INSERTED WHERE CPACountry IS NOT NULL AND CPAState IS NOT NULL) i 
			LEFT JOIN HQST hqst(NOLOCK) ON i.CPACountry = hqst.Country AND i.CPAState = hqst.[State]
			WHERE [State] IS NULL)
		BEGIN
			SELECT @errMsg = 'Invalid CPA Country and CPA State combination'
			GOTO error
		END
	END
	
--	Bond validation
	-- Validate Bond Country
	IF UPDATE(BondCountry)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE BondCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Bond Country'
			GOTO error
		END
	END
	
	-- Validate Bond State
	IF UPDATE(BondState)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE BondState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Bond State'
			GOTO error
		END
	END
	
	-- Validate Bond Country/Bond State combinations
	IF UPDATE(BondCountry) OR UPDATE(BondState)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1 
			FROM (SELECT BondState, BondCountry FROM INSERTED WHERE BondCountry IS NOT NULL AND BondState IS NOT NULL) i 
			LEFT JOIN HQST hqst(NOLOCK) ON i.BondCountry = hqst.Country AND i.BondState = hqst.[State]
			WHERE [State] IS NULL)
		BEGIN
			SELECT @errMsg = 'Invalid Bond Country and Bond State combination'
			GOTO error
		END
	END
	
--	Insurance validation
	-- Validate Insurance Country
	IF UPDATE(InsuranceCountry)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE InsuranceCountry NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Insurance Country'
			GOTO error
		END
	END
	
	-- Validate Insurance State
	IF UPDATE(InsuranceState)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE InsuranceState NOT IN(SELECT [State] FROM HQST (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Insurance State'
			GOTO error
		END
	END
	
	-- Validate Insurance Country/Insurance State combinations
	IF UPDATE(InsuranceCountry) OR UPDATE(InsuranceState)
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1 
			FROM (SELECT InsuranceState, InsuranceCountry FROM INSERTED WHERE InsuranceCountry IS NOT NULL AND InsuranceState IS NOT NULL) i 
			LEFT JOIN HQST hqst(NOLOCK) ON i.InsuranceCountry = hqst.Country AND i.InsuranceState = hqst.[State]
			WHERE [State] IS NULL)
		BEGIN
			SELECT @errMsg = 'Invalid Insurance Country and Insurance State combination'
			GOTO error
		END
	END
	
	RETURN

error:
	SELECT @errMsg = @errMsg +  ' - cannot insert PC Qualifications!'
	RAISERROR(@errMsg, 11, -1);
	ROLLBACK TRANSACTION

END


GO
ALTER TABLE [dbo].[vPCQualifications] ADD CONSTRAINT [PK_vPCQualifications] PRIMARY KEY CLUSTERED  ([APVMKeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCQualifications] WITH NOCHECK ADD CONSTRAINT [FK_vPCQualifications_bAPVM] FOREIGN KEY ([APVMKeyID]) REFERENCES [dbo].[bAPVM] ([KeyID])
GO
