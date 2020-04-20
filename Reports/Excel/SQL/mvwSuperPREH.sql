----Set the options to support indexed views.
--SET NUMERIC_ROUNDABORT OFF;
--SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
--    QUOTED_IDENTIFIER, ANSI_NULLS ON;
--GO

IF OBJECT_ID ('dbo.mvwSuperPREH', 'view') IS NOT NULL
DROP VIEW dbo.mvwSuperPREH;
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 08/25/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE VIEW dbo.mvwSuperPREH
--WITH SCHEMABINDING --For indexed views
AS
SELECT  preh.PRCo, preh.Employee, preh.LastName, preh.FirstName, preh.MidName, preh.SortName, preh.Address, preh.City, preh.State, preh.Zip, preh.Address2, preh.Phone, preh.SSN, preh.Race, preh.Sex, preh.BirthDate, preh.HireDate, preh.TermDate, preh.PRGroup, preh.PRDept, preh.Craft, preh.Class, preh.InsCode, preh.TaxState, preh.UnempState, preh.InsState, preh.LocalCode, preh.GLCo, preh.UseState, preh.UseIns, preh.JCCo, preh.Job, preh.Crew, preh.LastUpdated, preh.EarnCode, preh.HrlyRate, preh.SalaryAmt, preh.OTOpt, preh.OTSched, preh.JCFixedRate, preh.EMFixedRate, preh.YTDSUI, preh.OccupCat, preh.CatStatus, preh.DirDeposit, preh.RoutingId, preh.BankAcct, preh.AcctType, preh.ActiveYN, preh.PensionYN, preh.PostToAll, preh.CertYN, preh.ChkSort, preh.AuditYN, preh.Notes, preh.UniqueAttchID, preh.Email, preh.DefaultPaySeq, preh.DDPaySeq, preh.Suffix, preh.TradeSeq, preh.CSLimit, preh.CSGarnGroup, preh.CSAllocMethod, preh.Shift, preh.NonResAlienYN, preh.KeyID, preh.Country, preh.HDAmt, preh.F1Amt, preh.LCFStock, preh.LCPStock, preh.NAICS, preh.AUEFTYN, preh.AUAccountNumber, preh.AUBSB, preh.AUReference, preh.EMCo, preh.Equipment, preh.EMGroup, preh.PayMethodDelivery, preh.CPPQPPExempt, preh.EIExempt, preh.PPIPExempt, preh.TimesheetRevGroup, preh.UpdatePRAEYN, preh.WOTaxState, preh.WOLocalCode, preh.UseLocal, preh.UseUnempState, preh.UseInsState, preh.NewHireActStartDate, preh.NewHireActEndDate, preh.CellPhone, preh.ArrearsActiveYN, preh.udOrigHireDate, preh.udEmpGroup, preh.udSource, preh.udConv, preh.udCGCTable, preh.udCGCTableID, preh.RecentRehireDate, preh.RecentSeparationDate, preh.SeparationRedundancyRetirement, preh.udJobTitle, preh.udExempt, preh.ud401kEligYN, preh.ud401kElgDate, 
		prcm.Description CraftDesc,
		prcc.Description ClassDesc,
		prgr.Description EmployeeGroup,
		glpi3.Instance GLDept, glpi3.Description GLDeptDesc,
		--jcdm.Description JCDeptDesc,
		--glpi3_2.Instance JobGLDept, glpi3_2.Description JobGLDeptDesc,
		prdp.PRDept PRDepartment, prdp.Description PRDepartmentDescription,
		hqco.HQCo PRCoID, hqco.Name PRCoName, hqco.Address PRCoAddress, hqco.City PRCoCity, hqco.State PRCoState, hqco.Zip PRCoZip, hqco.Phone PRCoPhone, hqco.Fax PRCoFax
FROM	dbo.PREH preh
		LEFT OUTER JOIN dbo.HQCO hqco 
			ON preh.PRCo = hqco.HQCo
		LEFT OUTER JOIN dbo.PRCM prcm 
			ON preh.Craft=prcm.Craft 
			AND preh.PRCo=prcm.PRCo
		LEFT OUTER JOIN dbo.PRCC prcc 
			ON preh.Class=prcc.Class
			AND preh.PRCo=prcc.PRCo
		LEFT OUTER JOIN dbo.PRGR prgr
			ON preh.PRCo = prgr.PRCo
			AND preh.PRGroup = prgr.PRGroup
		LEFT OUTER JOIN PRDP prdp
			ON preh.PRCo=prdp.PRCo
			AND preh.PRDept=prdp.PRDept
		LEFT OUTER JOIN	GLPI glpi3 
			--ON preh.PRCo=glpi3.GLCo
			ON preh.GLCo = glpi3.GLCo
		    AND glpi3.PartNo=3
		    AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4)
		--LEFT OUTER JOIN dbo.JCDM jcdm 
		--	ON preh.JCCo=jcdm.JCCo
		--LEFT OUTER JOIN GLPI glpi3_2 
		--	ON preh.JCCo=glpi3_2.GLCo
		--    AND glpi3_2.PartNo=3
		--    AND glpi3_2.Instance=SUBSTRING(jcdm.ClosedRevAcct,10,4)
GO

GRANT SELECT ON dbo.mvwSuperPREH TO [public]
GO

----Create an index on the view.
--CREATE UNIQUE CLUSTERED INDEX ix_Employee
--    ON dbo.mvwSuperPREH (FirstName, LastName);
--GO

-- Test Scripts
select * from dbo.mvwSuperPREH