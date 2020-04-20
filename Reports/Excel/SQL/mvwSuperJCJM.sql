----Set the options to support indexed views.
--SET NUMERIC_ROUNDABORT OFF;
--SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
--    QUOTED_IDENTIFIER, ANSI_NULLS ON;
--GO

IF OBJECT_ID ('dbo.mvwSuperJCJM', 'view') IS NOT NULL
DROP VIEW dbo.mvwSuperJCJM;
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 09/15/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE VIEW dbo.mvwSuperJCJM
--WITH SCHEMABINDING --For indexed views
AS
SELECT  jcjm.JCCo, jcjm.Job, jcjm.Description JobDesc, jcjm.Contract, jcjm.JobStatus, jcjm.BidNumber, jcjm.LockPhases, 
		jcjm.ProjectMgr, jcjm.JobPhone, jcjm.JobFax, 
		jcjm.MailAddress, jcjm.MailCity, jcjm.MailState, jcjm.MailZip, jcjm.MailAddress2, 
		jcjm.ShipAddress, jcjm.ShipCity, jcjm.ShipState, jcjm.ShipZip, jcjm.ShipAddress2, 
		jcjm.LiabTemplate, jcjm.TaxGroup, jcjm.TaxCode, jcjm.InsTemplate, 
		jcjm.MarkUpDiscRate, jcjm.PRLocalCode, jcjm.PRStateCode, jcjm.Certified, jcjm.EEORegion, jcjm.SMSACode, 
		jcjm.CraftTemplate, jcjm.ProjMinPct, jcjm.Notes JobNotes, jcjm.SLCompGroup, jcjm.POCompGroup, jcjm.VendorGroup, 
		jcjm.ArchEngFirm, jcjm.OTSched, jcjm.PriceTemplate, jcjm.HaulTaxOpt, jcjm.GeoCode, jcjm.BaseTaxOn, jcjm.UpdatePlugs, 
		--jcjm.UniqueAttchID, jcjm.KeyID, 
		jcjm.ContactCode, jcjm.ClosePurgeFlag, jcjm.OurFirm, jcjm.AutoAddItemYN, jcjm.OverProjNotes, jcjm.WghtAvgOT, 
		jcjm.HrsPerManDay, jcjm.AutoGenSubNo, jcjm.SecurityGroup, jcjm.DefaultStdDaysDue, jcjm.DefaultRFIDaysDue, jcjm.UpdateAPActualsYN, jcjm.UpdateMSActualsYN, 
		jcjm.AutoGenPCONo, jcjm.AutoGenMTGNo, jcjm.AutoGenRFINo, jcjm.RateTemplate, jcjm.RevGrpInv, jcjm.MailCountry, jcjm.ShipCountry, jcjm.CertDate, 
		jcjm.AutoGenRFQNo, jcjm.ApplyEscalators, jcjm.UseTaxYN, jcjm.TimesheetRevGroup, jcjm.PotentialProjectID, jcjm.PCVisibleInJC, jcjm.SubmittalReviewDaysResponsibleFirm, 
		jcjm.SubmittalReviewDaysApprovingFirm, jcjm.SubmittalReviewDaysRequestingFirm, jcjm.SubmittalReviewDaysAutoCalcYN, jcjm.SubmittalApprovingFirm, jcjm.SubmittalApprovingFirmContact, 
		--jcjm.udSource, jcjm.udConv, jcjm.udCGCTable, jcjm.udCGCTableID, jcjm.udDatePhaseDelete, jcjm.udBET, jcjm.FourProjectsContainerName, jcjm.FourProjectsContainerId, 
		--jcjm.udBuildNum, jcjm.udSquFootage, jcjm.udOccOwn, jcjm.udDTReqd, jcjm.udDTRespParty, jcjm.udEnergySRating, jcjm.udLeedTarget, jcjm.udGovntYN, jcjm.udAARAYN, jcjm.udJobsNowYN, jcjm.udEnable84YN, jcjm.udBuyAmericanYN, jcjm.udGovSector, jcjm.udGovtOwner, jcjm.udAwardAgency, jcjm.udPubFundTrail, jcjm.udSINNum, jcjm.udProcVeh, jcjm.udIFFFeeYN, jcjm.udCRMNum, jcjm.udProjWrkstrm, jcjm.udBLocAddress, jcjm.udBLocAddress2, jcjm.udBLocCity, jcjm.udBLocState, jcjm.udBLocZip, jcjm.udAcctMngr, jcjm.udRFPDueDate, jcjm.udDesignStrt, jcjm.udDesignEnd, jcjm.udConstStrt, jcjm.udConstEnd, jcjm.udWABOTax, jcjm.udGovtOwnYN, jcjm.udRiskProfile, jcjm.udOCCIPCCIPYN, jcjm.udExistingBuildYN, jcjm.udPrevailWage, jcjm.udWorkRecYN, jcjm.udAuthType, jcjm.udFAR, jcjm.udFARYN, jcjm.udVARYN, jcjm.udDEARYN, jcjm.udBOClass, jcjm.udStateSpecificTax, jcjm.udProjIns, jcjm.udProjSummary, jcjm.udHardcardYN, jcjm.udPublicFundsYN, 
		jcjm.udDateChanged JobDateChanged, jcjm.udProjStart, jcjm.udProjEnd, jcjm.udCGCJob,
		jcjp.PhaseGroup, jcjp.Phase, jcjp.Description JobPhaseDesc, 
		--jcjp.Contract, jcjp.ProjMinPct,
		jcjp.Item, jcjp.ActiveYN, jcjp.Notes PhaseNotes, jcjp.InsCode, 
		--jcjp.UniqueAttchID, jcjp.KeyID, 
		--jcjp.udSource, jcjp.udConv, jcjp.udCGCTable, jcjp.udCGCTableID, jcjp.udSellRate, jcjp.udJCDept
		jcch.CostType, jcch.UM, jcch.BillFlag, jcch.ItemUnitFlag, jcch.PhaseUnitFlag, jcch.BuyOutYN, jcch.LastProjDate, jcch.Plugged, 
		jcch.OrigHours, jcch.OrigUnits, jcch.OrigCost, jcch.ProjNotes, jcch.SourceStatus, jcch.InterfaceDate, jcch.Notes PhaseCostTypeNotes, 
		--jcch.ActiveYN, jcch.UniqueAttchID, jcch.KeyID, 
		--jcch.udSource, jcch.udConv, jcch.udCGCTable, jcch.udCGCTableID,
		jcch.udDateCreated, jcch.udDateChanged JobCostTypeDateChanged, jcch.udSellRate, jcch.udMarkup,
		jcct.Description CostTypeDesc, jcct.Abbreviation, jcct.TrackHours, jcct.LinkProgress, jcct.Notes CostTypeNotes, jcct.JBCostTypeCategory,
		--jcct.UniqueAttchID, jcct.KeyID
		jcmp.Name MgrName, jcmp.Phone MgrPhone, jcmp.FAX MgrFax, jcmp.MobilePhone MgrMobilePhone, jcmp.Pager MgrPager, jcmp.Internet MgrInternet, jcmp.Email MgrEmail, jcmp.udEmployee MgrUdEmployee, jcmp.udPRCo MgrPRCo,
		--jcmp.UniqueAttchID, jcmp.KeyID, jcmp.udSource, jcmp.udConv, jcmp.udCGCTable, jcmp.udCGCTableID
		glpi_1.Instance ContractGLDept, glpi_1.Description ContractGLDeptDesc,
		glpi_2.Instance ItemGLDept, glpi_2.Description ItemGLDeptDesc
FROM	dbo.bJCJM jcjm
		LEFT OUTER JOIN dbo.bJCJP jcjp
			ON jcjp.JCCo=jcjm.JCCo
			AND jcjp.Job=jcjm.Job
		LEFT OUTER JOIN dbo.bJCCH jcch
			ON jcch.JCCo=jcjp.JCCo
			AND jcch.Job=jcjp.Job
			AND jcch.PhaseGroup=jcjp.PhaseGroup
			AND jcch.Phase=jcjp.Phase
		LEFT OUTER JOIN dbo.bJCCT jcct
			ON jcct.PhaseGroup=jcch.PhaseGroup
			AND jcct.CostType=jcch.CostType
		LEFT OUTER JOIN dbo.bJCMP jcmp
			ON jcmp.JCCo=jcjm.JCCo
			AND jcmp.ProjectMgr=jcjm.ProjectMgr
		LEFT OUTER JOIN dbo.bJCCM jccm
			ON jccm.JCCo=jcjm.JCCo
			AND jccm.Contract=jcjm.Contract
		LEFT OUTER JOIN dbo.bJCDM jcdm_1
			ON jcdm_1.JCCo=jccm.JCCo
			AND jcdm_1.Department=jccm.Department
		LEFT OUTER JOIN dbo.bGLPI glpi_1
			ON glpi_1.GLCo=jcdm_1.JCCo
			AND glpi_1.PartNo=3
			AND glpi_1.Instance=SUBSTRING(jcdm_1.OpenRevAcct,10,4)
		LEFT OUTER JOIN dbo.bJCCI jcci
			ON jcci.JCCo=jcjp.JCCo
			AND jcci.Contract=jcjp.Contract
			AND jcci.Item=jcjp.Item
		LEFT OUTER JOIN dbo.bJCDM jcdm_2
			ON jcdm_2.JCCo=jcci.JCCo
			AND jcdm_2.Department=jcci.Department
		LEFT OUTER JOIN dbo.bGLPI glpi_2
			ON glpi_2.GLCo=jcdm_2.JCCo
			AND glpi_2.PartNo=3
			AND glpi_2.Instance=SUBSTRING(jcdm_2.OpenRevAcct,10,4)
GO

GRANT SELECT ON dbo.mvwSuperJCJM TO [public]
GO 

----Create an index on the view.
--CREATE UNIQUE CLUSTERED INDEX ix_Job
--    ON dbo.mvwSuperJCJM (Job, Phase);
--GO

-- Test Scripts
select * from dbo.mvwSuperJCJM