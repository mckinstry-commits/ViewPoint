----Set the options to support indexed views.
--SET NUMERIC_ROUNDABORT OFF;
--SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
--    QUOTED_IDENTIFIER, ANSI_NULLS ON;
--GO

IF OBJECT_ID ('dbo.mvwSuperJCCM', 'view') IS NOT NULL
DROP VIEW dbo.mvwSuperJCCM;
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 09/15/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE VIEW dbo.mvwSuperJCCM
--WITH SCHEMABINDING --For indexed views
AS
SELECT  jccm.JCCo, jccm.Contract, jccm.Description ContractDesc, jccm.Department, jccm.ContractStatus, 
jccm.OriginalDays, jccm.CurrentDays, 
--jccm.StartMonth, 
jccm.MonthClosed, jccm.ProjCloseDate, jccm.ActualCloseDate, 
jccm.CustGroup, jccm.Customer, jccm.PayTerms, jccm.TaxInterface, 
--jccm.TaxGroup, jccm.TaxCode, 
jccm.RetainagePCT, jccm.DefaultBillType, 
--jccm.OrigContractAmt, jccm.ContractAmt, jccm.BilledAmt, jccm.ReceivedAmt, jccm.CurrentRetainAmt, 
--jccm.InBatchMth, jccm.InUseBatchId, 
jccm.Notes ContractNotes, jccm.SIRegion ContractSIRegion, 
jccm.SIMetric, jccm.ProcessGroup, jccm.BillAddress, jccm.BillAddress2, jccm.BillCity, jccm.BillState, jccm.BillZip, jccm.BillNotes, jccm.BillOnCompletionYN, jccm.CustomerReference, jccm.CompleteYN, jccm.RoundOpt, jccm.ReportRetgItemYN, jccm.ProgressFormat, jccm.TMFormat, 
--jccm.BillGroup, jccm.BillDayOfMth, jccm.ArchitectName, jccm.ArchitectProject, jccm.ContractForDesc, jccm.StartDate, jccm.JBTemplate, jccm.JBFlatBillingAmt, jccm.JBLimitOpt, --jccm.UniqueAttchID, jccm.RecType, jccm.OverProjNotes, jccm.ClosePurgeFlag, jccm.MiscDistCode, jccm.SecurityGroup, jccm.UpdateJCCI, --jccm.KeyID, jccm.BillCountry, jccm.PotentialProject, jccm.MaxRetgOpt, jccm.MaxRetgPct, jccm.MaxRetgAmt, jccm.InclACOinMaxYN, jccm.MaxRetgDistStyle, jccm.udPOC, jccm.udGMAXAmt, jccm.udConMethod, jccm.udConChannel, jccm.udPrimeYN, jccm.udSubstantiation, jccm.udCGCJobNum,  jccm.udBillDelMethod, jccm.udBillEmail, jccm.udBOClass, jccm.udTerm, jccm.udTermMth, jccm.udBillCompleteOL,
--jccm.udSource, jccm.udConv, jccm.udCGCTable, jccm.udCGCTableID, jccm.udRevType, 
jcci.JCCo ItemJCCo, jcci.Contract ItemContract, jcci.Item, jcci.Description ItemDesc, 
jcci.Department ContractItemDepartment, jcci.TaxGroup , jcci.TaxCode, 
jcci.UM, jcci.SIRegion ContractItemSIRegion, jcci.SICode, jcci.RetainPCT, jcci.OrigContractAmt, jcci.OrigContractUnits, jcci.OrigUnitPrice, jcci.ContractAmt, jcci.ContractUnits, jcci.UnitPrice, jcci.BilledAmt, jcci.BilledUnits, jcci.ReceivedAmt, jcci.CurrentRetainAmt, jcci.BillType, 
jcci.BillGroup, jcci.BillDescription, jcci.BillOriginalUnits, jcci.BillOriginalAmt, jcci.BillCurrentUnits, jcci.BillCurrentAmt, jcci.BillUnitPrice, jcci.Notes ContractItemNotes, jcci.InitSubs, jcci.UniqueAttchID, jcci.StartMonth, jcci.MarkUpRate, jcci.ProjNotes, jcci.ProjPlug, jcci.udLockYN, jcci.udRevType, jcci.udProjDelivery,
--jcci.KeyID, jcci.InitAsZero, jcci.udSource, jcci.udCGCTable, jcci.udCGCTableID, jcci.udConv, jcci.udOrigItem
jcdm_1.Description ContractDeptDesc, jcdm_1.GLCo ContractGLCo, jcdm_1.OpenRevAcct ContractOpenRevAcct, jcdm_1.ClosedRevAcct ContractClosedRevAcct, jcdm_1.Notes ContractDeptNotes, 
--jcdm_1.UniqueAttchID ContractDeptUniqueAttachID,
jcdm_2.Description ItemDeptDesc, jcdm_2.GLCo ItemGLCo, jcdm_2.OpenRevAcct ItemOpenRevAcct, jcdm_2.ClosedRevAcct ItemClosedRevAcct, jcdm_2.Notes ItemDeptNotes, 
--jcdm_2.UniqueAttchID ItemDeptUniqueAttachID,
glpi_1.Instance ContractGLDept, glpi_1.Description ContractGLDeptDesc,
--glpi_1.UniqueAttchID, glpi_1.KeyID, glpi_1.udSource, glpi_1.udConv, glpi_1.udCGCTable, glpi_1.udCGCTableID
glpi_2.Instance ItemGLDept, glpi_2.Description ItemGLDeptDesc,
--glpi_2.UniqueAttchID, glpi_2.KeyID, glpi_2.udSource, glpi_2.udConv, glpi_2.udCGCTable, glpi_2.udCGCTableID
jcmp.Name MgrName, jcmp.Phone MgrPhone, jcmp.FAX MgrFax, jcmp.MobilePhone MgrMobilePhone, jcmp.Pager MgrPager, jcmp.Internet MgrInternet, jcmp.Email MgrEmail, jcmp.udEmployee MgrUdEmployee, jcmp.udPRCo MgrPRCo
--, jcmp.UniqueAttchID, jcmp.KeyID, jcmp.udSource, jcmp.udConv, jcmp.udCGCTable, jcmp.udCGCTableID
FROM	dbo.bJCCM jccm
		LEFT OUTER JOIN dbo.bJCCI jcci
			ON jcci.JCCo=jccm.JCCo
			AND jcci.Contract=jccm.Contract
		LEFT OUTER JOIN dbo.bJCDM jcdm_1
			ON jcdm_1.JCCo=jccm.JCCo
			AND jcdm_1.Department=jccm.Department
		LEFT OUTER JOIN dbo.bGLPI glpi_1
			ON glpi_1.GLCo=jcdm_1.JCCo
			AND glpi_1.PartNo=3
			AND glpi_1.Instance=SUBSTRING(jcdm_1.OpenRevAcct,10,4)
		LEFT OUTER JOIN dbo.bJCDM jcdm_2
			ON jcdm_2.JCCo=jcci.JCCo
			AND jcdm_2.Department=jcci.Department
		LEFT OUTER JOIN dbo.bGLPI glpi_2
			ON glpi_2.GLCo=jcdm_2.JCCo
			AND glpi_2.PartNo=3
			AND glpi_2.Instance=SUBSTRING(jcdm_2.OpenRevAcct,10,4)
		LEFT OUTER JOIN dbo.bJCMP jcmp
			ON jcmp.JCCo=jccm.JCCo
			AND jcmp.ProjectMgr=jccm.udPOC
GO

GRANT SELECT ON dbo.mvwSuperJCCM TO [public]
GO


----Create an index on the view.
--CREATE UNIQUE CLUSTERED INDEX ix_Contract
--    ON dbo.mvwSuperJCCM (Contract, Item);
--GO

-- Test Scripts
select * from dbo.mvwSuperJCCM