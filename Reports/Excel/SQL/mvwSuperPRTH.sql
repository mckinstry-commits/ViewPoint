----Set the options to support indexed views.
--SET NUMERIC_ROUNDABORT OFF;
--SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
--    QUOTED_IDENTIFIER, ANSI_NULLS ON;
--GO

IF OBJECT_ID ('dbo.mvwSuperPRTH', 'view') IS NOT NULL
DROP VIEW dbo.mvwSuperPRTH;
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 08/26/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE VIEW dbo.mvwSuperPRTH
--WITH SCHEMABINDING --For indexed views
AS
SELECT  prth.PRCo, prth.PRGroup, prth.PREndDate, prth.Employee, prth.PaySeq, prth.PostSeq, prth.Type, prth.PostDate, prth.JCCo, prth.Job, prth.PhaseGroup, prth.Phase, prth.JCDept, prth.GLCo, prth.EMCo, prth.WO, prth.WOItem, prth.Equipment, prth.EMGroup, prth.CostCode, prth.CompType, prth.Component, prth.RevCode, prth.EquipCType, prth.UsageUnits, prth.TaxState, prth.LocalCode, prth.UnempState, prth.InsState, prth.InsCode, prth.PRDept, prth.Crew, prth.Cert, prth.Craft, prth.Class, prth.EarnCode, prth.Shift, prth.Hours, prth.Rate, prth.Amt, prth.InUseBatchId, prth.BatchId, prth.Memo, prth.UniqueAttchID, prth.EquipPhase, prth.KeyID, prth.SMCo, prth.SMWorkOrder, prth.SMScope, prth.SMPayType, prth.SMCostType, prth.SMJCCostType, prth.SMPhaseGroup, prth.PRTBKeyID, prth.udPaidDate, prth.udCMCo, prth.udCMAcct, prth.udCMRef, prth.udTCSource, prth.udSchool, prth.udSource, prth.udConv, prth.udCGCTable, prth.udCGCTableID, prth.udArea, prth.udAsteaDemandId,
		preh.FirstName, preh.MidName, preh.LastName, preh.Suffix, preh.FullName, preh.SortName, preh.Email,
		prcm.Description CraftDesc,
		prcc.Description ClassDesc,
		prgr.Description EmployeeGroup,
		glpi3.Instance GLDept, glpi3.Description GLDeptDesc,
		jcdm.Description JCDeptDesc,
		glpi3_2.Instance JobGLDept, glpi3_2.Description JobGLDeptDesc,
		prdp.PRDept PRDepartment, prdp.Description PRDepartmentDescription,
		hqco.HQCo PRCoID, hqco.Name PRCoName, hqco.Address PRCoAddress, hqco.City PRCoCity, hqco.State PRCoState, hqco.Zip PRCoZip, hqco.Phone PRCoPhone, hqco.Fax PRCoFax
FROM	dbo.bPRTH prth JOIN
		PREHName preh 
            ON prth.PRCo=preh.PRCo
			AND prth.Employee=preh.Employee
		LEFT OUTER JOIN dbo.bHQCO hqco 
			ON prth.PRCo = hqco.HQCo
		LEFT OUTER JOIN dbo.PRCM prcm 
			ON prth.Craft=prcm.Craft 
			AND prth.PRCo=prcm.PRCo
		LEFT OUTER JOIN dbo.PRCC prcc 
			ON prth.Class=prcc.Class
			AND prth.PRCo=prcc.PRCo
		LEFT OUTER JOIN dbo.PRGR prgr
			ON prth.PRCo = prgr.PRCo
			AND prth.PRGroup = prgr.PRGroup
		LEFT OUTER JOIN PRDP prdp
			ON prth.PRCo=prdp.PRCo
			AND prth.PRDept=prdp.PRDept
		LEFT OUTER JOIN	GLPI glpi3 
			--ON prth.PRCo=glpi3.GLCo
			ON prth.GLCo = glpi3.GLCo
		    AND glpi3.PartNo=3
		    AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4)
		LEFT OUTER JOIN dbo.JCDM jcdm 
			ON prth.JCCo=jcdm.JCCo
		LEFT OUTER JOIN GLPI glpi3_2 
			ON prth.JCCo=glpi3_2.GLCo
		    AND glpi3_2.PartNo=3
		    AND glpi3_2.Instance=SUBSTRING(jcdm.ClosedRevAcct,10,4)
GO

GRANT SELECT ON dbo.mvwSuperPRTH TO [public]
GO

----Create an index on the view.
--CREATE UNIQUE CLUSTERED INDEX ix_TimecardJob
--    ON dbo.mvwSuperPRTH (FirstName, LastName);
--GO

-- Test Scripts
select * from dbo.mvwSuperPRTH