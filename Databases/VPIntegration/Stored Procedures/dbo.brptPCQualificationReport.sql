SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================      
-- Author:  Mike Brewer      
-- Create date: 4/23/09      
-- Description: PCQualificationReport      
-- =============================================      
CREATE PROCEDURE [dbo].[brptPCQualificationReport]      
-- @Type  varchar(12) --Report or Blank Form      
(@APCo bCompany, @Vendor bVendor)      
AS      
BEGIN      


--declare  @APCo bCompany
--set @APCo = 1
--
--
--declare @Vendor bVendor
--set @Vendor = 1



    
select      
'R' as 'CRType',      
GLCo,      
(select Name from HQCO where HQCo = @APCo) as 'CompanyName',      
PCQualifications.Vendor,      
PCQualifications.VendorGroup,      
--'InfoHeader',      
PCQualifications.[Name],      
SortName,      
PCQualifications.Phone,  
PCQualifications.Fax,     
-----------------------------      
----'Payment Address',      
AddnlInfo,      
PCQualifications.[Address],      
PCQualifications.City,      
PCQualifications.[State],      
PCQualifications.Zip,      
PCQualifications.Country,      
PCQualifications.Address2,   --10      
-----------------------------      
----'Vendor Type',      
case [Type] when 'R' then 'X' else '' end as 'Vendor Type Regular',      
case [Type] when 'S' then 'X' else '' end as 'Vendor Type Supplier',      
EMail,      
URL,      
--------------------------------------------      
--'Purchase Address',      
POAddress,      
POCity,      
POState,      
POZip,      
POCountry,      
POAddress2,      
-------------------------------------      
----[Name] as 'Company',  --20      
OrganizationEstablished,---------------------------------------------------------------------------------- 
OrganizationType,      
OrganizationCountry,      
OrganizationState, 
OrganizationDate,
TIN,      
case OfficeType     
when 'B' then 'Branch'     
when 'M' then 'Main'    
when 'R' then 'Regional'    
else Null end as 'OfficeType',  
OtherNames,   
TradeAssociations,
case Qualified when 'Y' then 'X' else '' end as 'Qualified',      --???????????
QualifiedNotes,
case DoNotUse when 'Y' then 'X' else '' end as 'DoNotUse',      
case DoNotUse when 'Y' then DoNotUseReason else '' end as 'DoNotUseReason',   
   --30      
----------------------------------------------      
----'Parent Organization',      
ParentName,      
ParentAddress1,      
ParentCity,      
ParentState,      
ParentZip,      
ParentCountry,      
ParentAddress2,         
---------------------------------      
 
------------------------------------------      
------Headcount      
------'Number of Employees',      
CurrentExecutiveEmployees,      
AverageExecutiveEmployees,      
CurrentOfficeEmployees,      
AverageOfficeEmployees,--4      
CurrentShopEmployees,  --50      
AverageShopEmployees,      
CurrentJobSiteEmployees,      
AverageJobSiteEmployees,      
CurrentTradesEmployees,      
AverageTradesEmployees,      
-----------------------------------------------      
OwnersOut,      
OwnersIn,      
ManagementOut,      
ManagementIn,      
PMOut,   --60      
PMIn,        
----------------------------------------        
case ShopType     
when 'M' then 'Mixed'     
when 'O' then 'Open Shop'    
when 'U' then 'Union'    
else Null end as 'ShopType',      
-----------------------------------      
-------Technology      
AccountingSoftwareName,      
AccountingSoftwareInstallationDate,      
AccountingSoftwareRevision,      
AccountingSoftwareOS,      
AccountingSoftwareDatabase,      
PMSoftwareName,      
PMSoftwareInstallationDate,      
PMSoftwareRevision,    --70      
PMSoftwareOS,         
PMSoftwareDatabase,      
PSSoftwareName,      
PSSoftwareInstallationDate,      
PSSoftwareRevision,      
PSSoftwareOS,      
PSSoftwareDatabase,      
DMSoftwareName,      
DMSoftwareInstallationDate,      
DMSoftwareRevision,  --80      
DMSoftwareOS,         
DMSoftwareDatabase,      
case JobSiteConnectionType     
when 'D' then 'Mixed'     
when 'H' then 'High Speed'    
when 'N' then 'None'    
when 'W' then 'Wireless'    
else Null end as 'JobSiteConnectionType',      
-----------------------------------------------------------------------      
--------Safety      
SafetyExecutiveName,      
SafetyExecutiveTitle,      
SafetyExecutivePhone,      
SafetyExecutiveEmail,      
SafetyExecutiveFax,      
SafetyExecutiveCertifications,      
case SafetyInspections when 'Y' then 'X' else '' end as 'SafetyInspections',      
case SafetyFallProtection when 'Y' then 'X' else '' end as 'SafetyFallProtection',      
case SafetySiteProgram when 'Y' then 'X' else '' end as 'SafetySiteProgram',      
case SafetyTrainingNew when 'Y' then 'X' else '' end as 'SafetyTrainingNew',      
case SafetyRecognitionProgram when 'Y' then 'X' else '' end as 'SafetyRecognitionProgram',      
case SafetyDisciplinaryProgram when 'Y' then 'X' else '' end as 'SafetyDisciplinaryProgram',      
case SafetyInvestigations when 'Y' then 'X' else '' end as 'SafetyInvestigations',      
case SafetySexualHarassment when 'Y' then 'X' else '' end as 'SafetySexualHarassment',      
case SafetyAffirmativeActionPlan when 'Y' then 'X' else '' end as 'SafetyAffirmativeActionPlan',      
case SafetyReviews when 'Y' then 'X' else '' end as 'SafetyReviews',      
case DrugScreeningRequired when 'Y' then 'X' else '' end as 'DrugScreeningRequired',      
case SafetyPolicy when 'Y' then 'X' else '' end as 'SafetyPolicy',      
case SafetyDisciplinaryPolicy when 'Y' then 'X' else '' end as 'SafetyDisciplinaryPolicy',      
case SafetyAnnualGoals when 'Y' then 'X' else '' end as 'SafetyAnnualGoals',      
case SafetyReturnToWorkProgram when 'Y' then 'X' else '' end as 'SafetyReturnToWorkProgram',      
case DrugScreeningPreEmployment when 'Y' then 'X' else '' end as 'DrugScreeningPreEmployment',      
case DrugScreeningRandom when 'Y' then 'X' else '' end as 'DrugScreeningRandom',      
case DrugScreeningPeriodic when 'Y' then 'X' else '' end as 'DrugScreeningPeriodic',      
case DrugScreeningPostAccident when 'Y' then 'X' else '' end as 'DrugScreeningPostAccident',      
case DrugScreeningOnSuspicion when 'Y' then 'X' else '' end as 'DrugScreeningOnSuspicion',      
----Document Safety Meetings      
case SafetyMeetingsNew when 'Y' then 'X' else '' end as 'SafetyMeetingsNew',      
case SafetyMeetingsNew when 'Y' then      
 (case SafetyMeetingsNewFrequency       
 when 0 then 'Once'      
 when 1 then 'Daily'      
 when 2 then 'Weekly'      
 when 3 then 'Bi-Weekly'      
 when 4 then 'Monthly'      
 when 5 then 'Quarterly'      
 when 6 then 'Annual'      
 end ) else '' end as 'SafetyMeetingsNewFrequency',      
----------------------------------------------------------------------------------      
case SafetyMeetingsField when 'Y' then 'X' else '' end as 'SafetyMeetingsField',      
case SafetyMeetingsField when 'Y' then      
 (case SafetyMeetingsFieldFrequency       
 when 0 then 'Once'      
 when 1 then 'Daily'      
 when 2 then 'Weekly'      
 when 3 then 'Bi-Weekly'      
 when 4 then 'Monthly'      
 when 5 then 'Quarterly'      
 when 6 then 'Annual'      
 end ) else '' end as 'SafetyMeetingsFieldFrequency',      
----------------------------------------------------------------------------------      
case SafetyMeetingsEmployees when 'Y' then 'X' else '' end as 'SafetyMeetingsEmployees',      
case SafetyMeetingsEmployees when 'Y' then      
 (case SafetyMeetingsEmployeesFrequency       
 when 0 then 'Once'      
 when 1 then 'Daily'      
 when 2 then 'Weekly'      
 when 3 then 'Bi-Weekly'      
 when 4 then 'Monthly'      
 when 5 then 'Quarterly'      
 when 6 then 'Annual'      
 end ) else '' end as 'SafetyMeetingsEmployeesFrequency',      
----------------------------------------------------------------------------------      
case SafetyMeetingsSubs when 'Y' then 'X' else '' end as 'SafetyMeetingsSubs',      
case SafetyMeetingsSubs when 'Y' then      
 (case SafetyMeetingsSubsFrequency       
 when 0 then 'Once'      
 when 1 then 'Daily'      
 when 2 then 'Weekly'      
 when 3 then 'Bi-Weekly'      
 when 4 then 'Monthly'      
 when 5 then 'Quarterly'      
 when 6 then 'Annual'      
 end ) else '' end as 'SafetyMeetingsSubsFrequency',      
-------------------------      
----Quality      
QualityExecutiveName,      
QualityExecutiveTitle,      
QualityExecutivePhone,      
QualityExecutiveEmail,      
QualityExecutiveFax,      
QualityExecutiveCertifications,      
case QualityPolicy  when 'Y' then 'X' else '' end as 'QualityPolicy',      
case QualityTQM  when 'Y' then 'X' else '' end as 'QualityTQM',      
case QualityLeedsCertified  when 'Y' then 'X' else '' end as 'QualityLeedsCertified',  
QualityLEEDProfessionals as 'NumOfLeedPros',
case QualityLeedsExperience  when 'Y' then 'X' else '' end as 'QualityLeedsExperience', 
QualityLEEDProjects,
-------------------------      
----Projects      
LargestEverAmount,      
LargestEverYear,      
LargestEverProjectName,      
LargestEverGC,      
LargestEverInScope,      
----------------------      
LargestLastYearAmount,      
LargestLastYear,      
LargestLastYearProjectName,      
LargestLastYearGC,      
LargestLastYearInScope,      
----------------------------      
LargestThisYearAmount,      
LargestThisYear,      
LargestThisYearProjectName,      
LargestThisYearGC,      
LargestThisYearInScope,      
-------------------------------      
PreferMin,      
Prefer100K,      
Prefer200K,      
Prefer500K,      
Prefer1M,      
Prefer3M,      
Prefer6M,      
Prefer10M,      
Prefer15M,      
Prefer25M,      
Prefer50M,      
PreferMax,      
--------------------------------      
--Insurance      
----Insurance Agency      
InsuranceAgent,      
InsuranceName,      
InsurancePhone,      
InsuranceFax,      
InsuranceContact,      
InsuranceEmail,      
InsuranceYears,      
----Address      
InsuranceAddress1,      
InsuranceCity,      
InsuranceState,      
InsuranceZip,      
InsuranceCountry,      
InsuranceAddress2,      
------Workers Comp and Employers Liability      
WCInsuranceName,      
WCForm,      
WCPolicyNumber,      
WCPeriodFrom,      
WCPeriodTo,      
--      
WCEach,      
WCEachMax,      
WCDiseaseLimit,      
WCDiseaseLimitMax,      
WCDiseaseEach,      
WCDiseaseEachMax,      
WCLimit,      
------Professional Liability Insurance      
PLInsuranceName,      
PLForm,      
PLPolicyNumber,      
PLPeriodFrom,      
PLPeriodTo,      
PLDeductible,      
PLExtendedPeriod,      
PLProjectLimit,      
case PLPriorActs  when 'Y' then 'X' else '' end as 'PLPriorActs',      
--Liability      
------Commercial General Liability      
GCLInsuranceName,      
GCLForm,      
GCLPolicyNumber,      
GCLPeriodFrom,      
GCLPeriodTo,      
GCLClaimsMade,      
case GCLExclusion  when 'Y' then 'X' else '' end as 'GCLExclusion',      
GCLGeneralAggregateCurrent,      
GCLGeneralAggregateMax,      
GCLProductCurrent,      
GCLProductMax,      
GCLPersonalCurrent,      
GCLPersonalMax,      
GCLEachCurrent,      
GCLEachMax,      
GCLMedicalCurrent,      
GCLMedicalMax,      
GCLFireCurrent,      
GCLFireMax,      
GCLDeductible,      
case GCLPerProjectLimit  when 'Y' then 'X' else '' end as 'GCLPerProjectLimit',      
------Excess Liability      
ELInsuranceName,      
ELForm,      
ELPolicyNumber,      
ELPeriodFrom,      
ELPeriodTo,      
Case ELType 
	when 1 then '1-Umbrella'
	when 2 then '2-Excess'
else Null end as 'ELType',
ELClaimsMade,
ELAggregateCurrent,      
ELAggregateMax,      
ELEachCurrent,      
ELEachMax,      
----Automotive Liability      
ALInsuranceName,      
ALForm,      
ALPolicyNumber,      
ALPeriodFrom,      
ALPeriodTo,      
ALCombinedCurrent,      
ALCombinedMax,      
ALBodyAccidentCurrent,      
ALBodyAccidentMax,      
ALBodyPerPersonCurrent,      
ALBodyPerPersonMax,      
ALPropertyCurrent,      
ALPropertyMax,      
---------------------------------------------------------------------      
--Financial      
----Financial Information      
DBNumber,      
DBRating,      
DBPayRecord,      
DBDateOfRating,      
RevenueYear,      
RevenueAmount,      
NetIncome,      
NetEquity,      
WorkingCapital,      
AverageEmployees,      
ThisYearVolume,      
ThisYearProjects,      
CurrentBacklog,      
case LiquidatedDamages  when 'Y' then 'X' else '' end as 'LiquidatedDamages',      
case LiquidatedDamages  when 'Y' then LiquidatedDamageNotes else '' end as 'LiquidatedDamageNotes',     
------Bank Information      
BankName,      
BankBranch,      
BankContact,      
BankPhone,      
BankFax,      
BankEmail,      
BankYears,      
BankLineOfCreditTotal,      
BankLineOfCreditAvailable,      
BankLineOfCreditExpiration,      
------Bank Address      
BankAddress1,      
BankCity,      
BankState,      
BankZip,      
BankCountry,      
BankAddress2,      
-------------------------------------------------      
--CPA      
----CPA Firm Information      
CPAName,      
CPAContact,      
CPAPhone,      
CPAFax,      
CPAEmail,      
CPAYears,      
case CPAFinancialStatements    
when 0 then 'Audited'    
when 1 then 'Reviewed'    
when 2 then 'Other'     
else '' end as 'CPAFinancialStatements',    
------CPA Address      
CPAAddress1,      
CPACity,      
CPAState,      
CPAZip,      
CPACountry,      
CPAAddress2,      
----------------------------------------------      
--Bonding      
----Surety Company Information      
BondName,      
BondBroker,      
BondContact,      
BondPhone,      
BondFax,      
BondEmail,      
BondYears,      
BondCapacity,      
BondCapicityPerJob,      
BondLastDate,      
BondLastAmount,      
BondLastRate,      
----Surety Company Address      
BondAddress1,      
BondCity,      
BondState,      
BondZip,      
BondCountry,      
BondAddress2,      
case BondFinish  when 'Y' then 'X' else '' end as 'BondFinish',      
case BondFinish  when 'Y' then BondFinishNotes else '' end as 'BondFinishNotes',      
case BondPersonalGuarantee  when 'Y' then 'X' else '' end as 'BondPersonalGuarantee',      
--Legal      
case QBankrupt  when 'Y' then 'X' else '' end as 'QBankrupt',      
case QBankrupt  when 'Y' then QBankruptsNotes else '' end as 'QBankruptsNotes',    
case QIndicted   when 'Y' then 'X' else '' end as 'QIndicted',      
case QIndicted   when 'Y' then QIndictedNotes else '' end as 'QIndictedNotes',     
case QDisbarred   when 'Y' then 'X' else '' end as 'QDisbarred',     
case QDisbarred   when 'Y' then QDisbarredNotes else '' end as 'QDisbarredNotes',    
case QCompliance   when 'Y' then 'X' else '' end as 'QCompliance',      
case QCompliance   when 'Y' then QComplianceNotes else '' end as 'QComplianceNotes',      
case QLitigation   when 'Y' then 'X' else '' end as 'QLitigation',      
case QLitigation   when 'Y' then QLitigationNotes else '' end as 'QLitigationNotes',      
case QJudgements   when 'Y' then 'X' else '' end as 'QJudgements',      
case QJudgements   when 'Y' then QJudgementNotes else '' end as 'QJudgementNotes',      
case QLabor   when 'Y' then 'X' else '' end as 'QLabor',      
case QLabor   when 'Y' then QLaborNotes else '' end as 'QLaborNotes',  
PCQualifications.Notes  
from PCQualifications     
join HQCO H  
 on PCQualifications.VendorGroup = H.VendorGroup  
where H.HQCo = @APCo and  
PCQualifications.Vendor = @Vendor    
  

  
--      
Union All      
--      
select       
'B' as 'CRType',      
NULL as 'GLCo',      
NULL as 'CompanyName',      
NULL as 'Vendor',      
NULL as 'VendorGroup',      
NULL as 'Name',      
NULL as 'SortName',       
NULL as 'Phone', 
Null as 'Fax',      
NULL as 'AddnlInfo',       
NULL as 'Address',       
NULL as 'City',       
NULL as 'State',       
NULL as 'Zip',       
NULL as 'Country',       
NULL as 'Address2',       
NULL as 'Vendor Type Regular',      
NULL as 'Vendor Type Supplier',      
NULL as 'EMail',      
NULL as 'URL',      
--------------------------------------------      
--'Purchase Address',      
NULL as 'POAddress',      
NULL as 'POCity',      
NULL as 'POState',      
NULL as 'POZip',      
NULL as 'POCountry',      
NULL as 'POAddress2',      
------------------------------------      
----[Name] as 'Company',  --20 
Null as 'OrganizationEstablished',     
NULL as 'OrganizationType',      
NULL as 'OrganizationCountry',      
NULL as 'OrganizationState',      
NULL as 'OrganizationDate',      
NULL as 'TIN',      
NULL as 'OfficeType', 
Null as 'OtherNames',     
Null as 'TradeAssociations',
NULL as 'Qualified',  
NULL as 'QualifiedNotes',    
NULL as 'DoNotUse',
NULL as 'DoNotUseReason',
NULL as 'ParentName',      
NULL as 'ParentAddress1',      
NULL as 'ParentCity',      
NULL as 'ParentState',      
NULL as 'ParentZip',      
NULL as 'ParentCountry',      
NULL as 'ParentAddress2'  ,      
-------------------------------------      
--------Headcount      
--------'Number of Employees',      
NULL as 'CurrentExecutiveEmployees',      
NULL as 'AverageExecutiveEmployees',      
NULL as 'CurrentOfficeEmployees',      
NULL as 'AverageOfficeEmployees',--4      
NULL as 'CurrentShopEmployees',  --50      
NULL as 'AverageShopEmployees',      
NULL as 'CurrentJobSiteEmployees',      
NULL as 'AverageJobSiteEmployees',      
NULL as 'CurrentTradesEmployees',      
NULL as 'AverageTradesEmployees',      
---------------------------------------      
----2 Year Turnover      
NULL as 'OwnersOut',      
NULL as 'OwnersIn',      
NULL as 'ManagementOut',      
NULL as 'ManagementIn',      
NULL as 'PMOut',   --60      
NULL as 'PMIn',      
------------------------------      
NULL as 'ShopType',      
--------------------------------------      
NULL as 'AccountingSoftwareName',      
NULL as 'AccountingSoftwareInstallationDate',      
NULL as 'AccountingSoftwareRevision',      
NULL as 'AccountingSoftwareOS',      
NULL as 'AccountingSoftwareDatabase',      
NULL as 'PMSoftwareName',      
NULL as 'PMSoftwareInstallationDate',      
NULL as 'PMSoftwareRevision',    --70      
NULL as 'PMSoftwareOS',         
NULL as 'PMSoftwareDatabase',      
NULL as 'PSSoftwareName',      
NULL as 'PSSoftwareInstallationDate',      
NULL as 'PSSoftwareRevision',      
NULL as 'PSSoftwareOS',      
NULL as 'PSSoftwareDatabase',      
NULL as 'DMSoftwareName',      
NULL as 'DMSoftwareInstallationDate',      
NULL as 'DMSoftwareRevision',  --80      
NULL as 'DMSoftwareOS',         
NULL as 'DMSoftwareDatabase',      
NULL as 'JobSiteConnectionType',      
-----------------------------------------      
NULL as 'SafetyExecutiveName',      
NULL as 'SafetyExecutiveTitle',      
NULL as 'SafetyExecutivePhone',      
NULL as 'SafetyExecutiveEmail',      
NULL as 'SafetyExecutiveFax',      
NULL as 'SafetyExecutiveCertifications',      
NULL as 'SafetyInspections', --90      
NULL as 'SafetyFallProtection',        
NULL as 'SafetySiteProgram',      
NULL as 'SafetyTrainingNew',      
----+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++      
NULL as 'SafetyRecognitionProgram',      
NULL as 'SafetyDisciplinaryProgram',      
NULL as 'SafetyInvestigations',      
NULL as 'SafetySexualHarassment',      
NULL as 'SafetyAffirmativeActionPlan',      
NULL as 'SafetyReviews',      
NULL as 'DrugScreeningRequired',      
NULL as 'SafetyPolicy',      
NULL as 'SafetyDisciplinaryPolicy',      
NULL as 'SafetyAnnualGoals',      
NULL as 'SafetyReturnToWorkProgram',      
NULL as 'DrugScreeningPreEmployment',      
NULL as 'DrugScreeningRandom',      
NULL as 'DrugScreeningPeriodic',      
NULL as 'DrugScreeningPostAccident',      
NULL as 'DrugScreeningOnSuspicion',      
---------------------------      
------Document Safety Meetings      
Null as 'SafetyMeetingsNew',      
'Once      Daily      Weekly      Bi-Weekly      Monthly      Quarterly      Annual' as 'SafetyMeetingsNewFrequency',      
NULL as 'SafetyMeetingsField',      
'Once      Daily      Weekly      Bi-Weekly      Monthly      Quarterly      Annual' as 'SafetyMeetingsFieldFrequency',      
Null as 'SafetyMeetingsEmployees',      
'Once      Daily      Weekly      Bi-Weekly      Monthly      Quarterly      Annual' as 'SafetyMeetingsEmployeesFrequency',      
Null as 'SafetyMeetingsSubs',      
'Once      Daily      Weekly      Bi-Weekly      Monthly      Quarterly      Annual' as 'SafetyMeetingsSubsFrequency',      
----Quality      
NULL as 'QualityExecutiveName',      
NULL as 'QualityExecutiveTitle',      
NULL as 'QualityExecutivePhone',      
NULL as 'QualityExecutiveEmail',      
NULL as 'QualityExecutiveFax',      
NULL as 'QualityExecutiveCertifications',      
NULL as 'QualityPolicy',      
NULL as 'QualityTQM',      
NULL as 'QualityLeedsCertified',  
Null as 'NumOfLeedsPros',    
NULL as 'QualityLeedsExperience',  
Null as 'QualityLEEDProjects',    
---------------------------      
------Projects      
NULL as 'LargestEverAmount',      
NULL as 'LargestEverYear',      
NULL as 'LargestEverProjectName',      
NULL as 'LargestEverGC',      
NULL as 'LargestEverInScope',      
----------------------      
NULL as 'LargestLastYearAmount',      
NULL as 'LargestLastYear',      
NULL as 'LargestLastYearProjectName',      
NULL as 'LargestLastYearGC',      
NULL as 'LargestLastYearInScope',      
----------------------------      
NULL as 'LargestThisYearAmount',      
NULL as 'LargestThisYear',      
NULL as 'LargestThisYearProjectName',      
NULL as 'LargestThisYearGC',      
NULL as 'LargestThisYearInScope',      
-------------------------------      
NULL as 'PreferMin',      
NULL as 'Prefer100K',      
NULL as 'Prefer200K',      
NULL as 'Prefer500K',      
NULL as 'Prefer1M',      
NULL as 'Prefer3M',      
NULL as 'Prefer6M',      
NULL as 'Prefer10M',      
NULL as 'Prefer15M',      
NULL as 'Prefer25M',      
NULL as 'Prefer50M',      
NULL as 'PreferMax',      
----Insurance      
------Insurance Agency      
NULL as 'InsuranceAgent',      
NULL as 'InsuranceName',      
NULL as 'InsurancePhone',      
NULL as 'InsuranceFax',      
NULL as 'InsuranceContact',      
NULL as 'InsuranceEmail',      
NULL as 'InsuranceYears',      
------Address      
NULL as 'InsuranceAddress1',      
NULL as 'InsuranceCity',      
NULL as 'InsuranceState',      
NULL as 'InsuranceZip',      
NULL as 'InsuranceCountry',      
NULL as 'InsuranceAddress2',      
------Workers Comp and Employers Liability      
NULL as 'WCInsuranceName',      
NULL as 'WCForm',      
NULL as 'WCPolicyNumber',      
NULL as 'WCPeriodFrom',      
NULL as 'WCPeriodTo',      
----      
NULL as 'WCEach',      
NULL as 'WCEachMax',      
NULL as 'WCDiseaseLimit',      
NULL as 'WCDiseaseLimitMax',      
NULL as 'WCDiseaseEach',      
NULL as 'WCDiseaseEachMax',      
NULL as 'WCLimit',      
------Professional Liability Insurance      
NULL as 'PLInsuranceName',      
NULL as 'PLForm',      
NULL as 'PLPolicyNumber',      
NULL as 'PLPeriodFrom',      
NULL as 'PLPeriodTo',      
NULL as 'PLDeductible',      
NULL as 'PLExtendedPeriod',      
NULL as 'PLProjectLimit',      
NULL as 'PLPriorActs',      
----Liability      
------Commercial General Liability      
NULL as 'GCLInsuranceName',      
NULL as 'GCLForm',      
NULL as 'GCLPolicyNumber',      
NULL as 'GCLPeriodFrom',      
NULL as 'GCLPeriodTo',      
NULL as 'GCLClaimsMade',      
NULL as 'GCLExclusion',      
NULL as 'GCLGeneralAggregateCurrent',      
NULL as 'GCLGeneralAggregateMax',      
NULL as 'GCLProductCurrent',      
NULL as 'GCLProductMax',      
NULL as 'GCLPersonalCurrent',      
NULL as 'GCLPersonalMax',      
NULL as 'GCLEachCurrent',      
NULL as 'GCLEachMax',      
NULL as 'GCLMedicalCurrent',      
NULL as 'GCLMedicalMax',      
NULL as 'GCLFireCurrent',      
NULL as 'GCLFireMax',      
NULL as 'GCLDeductible',      
NULL as 'GCLPerProjectLimit',      
------Excess Liability      
NULL as 'ELInsuranceName',      
NULL as 'ELForm',      
NULL as 'ELPolicyNumber',      
NULL as 'ELPeriodFrom',      
NULL as 'ELPeriodTo',      
NULL as 'ELType',      
NULL as 'ELClaimsMade',      
NULL as 'ELAggregateCurrent',      
NULL as 'ELAggregateMax',      
NULL as 'ELEachCurrent',      
NULL as 'ELEachMax',      
------Automotive Liability      
NULL as 'ALInsuranceName',      
NULL as 'ALForm',      
NULL as 'ALPolicyNumber',      
NULL as 'ALPeriodFrom',      
NULL as 'ALPeriodTo',      
NULL as 'ALCombinedCurrent',      
NULL as 'ALCombinedMax',      
NULL as 'ALBodyAccidentCurrent',      
NULL as 'ALBodyAccidentMax',      
NULL as 'ALBodyPerPersonCurrent',      
NULL as 'ALBodyPerPersonMax',      
NULL as 'ALPropertyCurrent',      
NULL as 'ALPropertyMax',      
-----------------------------------------------------------------------      
----Financial      
------Financial Information      
NULL as 'DBNumber',      
NULL as 'DBRating',      
NULL as 'DBPayRecord',      
NULL as 'DBDateOfRating',      
NULL as 'RevenueYear',      
NULL as 'RevenueAmount',      
NULL as 'NetIncome',      
NULL as 'NetEquity',      
NULL as 'WorkingCapital',      
NULL as 'AverageEmployees',      
NULL as 'ThisYearVolume',      
NULL as 'ThisYearProjects',      
NULL as 'CurrentBacklog',      
NULL as 'LiquidatedDamages',      
NULL as 'LiquidatedDamageNotes',      
------Bank Information      
NULL as 'BankName',      
NULL as 'BankBranch',      
NULL as 'BankContact',      
NULL as 'BankPhone',      
NULL as 'BankFax',      
NULL as 'BankEmail',      
NULL as 'BankYears',      
NULL as 'BankLineOfCreditTotal',      
NULL as 'BankLineOfCreditAvailable',      
NULL as 'BankLineOfCreditExpiration',      
------Bank Address      
NULL as 'BankAddress1',      
NULL as 'BankCity',      
NULL as 'BankState',      
NULL as 'BankZip',      
NULL as 'BankCountry',      
NULL as 'BankAddress2',      
---------------------------------------------------      
----CPA      
------CPA Firm Information      
NULL as 'CPAName',      
NULL as 'CPAContact',      
NULL as 'CPAPhone',      
NULL as 'CPAFax',      
NULL as 'CPAEmail',      
NULL as 'CPAYears',      
'  Audited      Reviewed      Other  ' as 'CPAFinancialStatements',    
----CPA Address      
NULL as 'CPAAddress1',      
NULL as 'CPACity',      
NULL as 'CPAState',      
NULL as 'CPAZip',      
NULL as 'CPACountry',    
NULL as 'CPAAddress2',      
------------------------------------------------      
----Bonding      
------Surety Company Information      
NULL as 'BondName',      
NULL as 'BondBroker',      
NULL as 'BondContact',      
NULL as 'BondPhone',      
NULL as 'BondFax',      
NULL as 'BondEmail',      
NULL as 'BondYears',      
NULL as 'BondCapacity',      
NULL as 'BondCapicityPerJob',      
NULL as 'BondLastDate',      
NULL as 'BondLastAmount',      
NULL as 'BondLastRate',      
----Surety Company Address      
NULL as 'BondAddress1',      
NULL as 'BondCity',      
NULL as 'BondState',      
NULL as 'BondZip',      
NULL as 'BondCountry',      
NULL as 'BondAddress2',      
NULL as 'BondFinish',      
NULL as 'BondFinishNotes',      
NULL as 'BondPersonalGuarantee',      
--Legal      
NULL as 'QBankrupt',      
NULL as 'QBankruptsNotes',      
NULL as  'QIndicted',      
NULL as 'QIndictedNotes',      
NULL as  'QDisbarred',      
NULL as 'QDisbarredNotes',      
NULL as  'QCompliance',      
NULL as 'QComplianceNotes',      
NULL as  'QLitigation',      
NULL as 'QLitigationNotes',      
NULL as  'QJudgements',      
NULL as 'QJudgementNotes',      
NULL as 'QLabor',      
NULL as 'QLaborNotes',      
NULL as 'Notes'  
--      
end  
GO
GRANT EXECUTE ON  [dbo].[brptPCQualificationReport] TO [public]
GO
