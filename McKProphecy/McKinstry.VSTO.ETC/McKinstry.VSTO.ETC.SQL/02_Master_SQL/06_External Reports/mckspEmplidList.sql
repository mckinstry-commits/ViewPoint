USE [ViewpointTraining]
GO
/****** Object:  StoredProcedure [dbo].[mspJCStaffStdRatesByDeptEmp]    Script Date: 9/20/2016 4:25:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*******************************************
Created by -Theresa Parker/Arun Thomas
Axosoft #: Prophecy Tool Emplid Lookup
Purpose : For Excel report MCK Emplid List   *******/
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	09/20/2016 New Version for Prophecy (see mspJCStaffStdRatesByDeptEmp)
-- ========================================================================
ALTER procedure [dbo].[mckspEmplidList] 
	(	@PRCo     int		 = null,
		@GLDept   varchar(4) = null, --'0001'
		@Employee int		 = null)
AS
SELECT
	  cc.PRCo as 'Payroll Co'
	, eh.Employee as 'Employee#'
	, eh.LastName + ', ' + eh.FirstName + ' ' + Substring(coalesce(eh.MidName,''),1,1) as Name
	, gl.Instance as 'GL Dept'
	, gl.Description as 'GL Dept Desc'
	, eh.Class
	, cc.Description as 'Class Desc'
	, JT.[Job Title] as 'Job Title'
FROM PREHName eh 
		INNER JOIN HQCO co 
			ON eh.PRCo = co.HQCo
		INNER JOIN PRCC cc 
			ON eh.PRCo = cc.PRCo 
			AND eh.Craft = cc.Craft 
			AND eh.Class = cc.Class
		INNER JOIN PRDP dp 
			ON eh.PRCo = dp.PRCo 
			AND eh.PRDept = dp.PRDept
		INNER JOIN GLPI gl 
			ON dp.PRCo = gl.GLCo 
			AND SUBSTRING(dp.JCFixedRateGLAcct,10,4) = gl.Instance
		INNER JOIN mckEmpDetails JT
			ON eh.Employee = JT.Employee#
WHERE co.udTESTCo = 'N'
	--AND eh.PRGroup = 1
	--AND eh.Craft not like '0002.%' --Eliminates FMS
	AND eh.ActiveYN = 'Y'
	AND gl.PartNo = 3
	AND (@PRCo is null	   or eh.PRCo     = @PRCo)
	AND (@GLDept is null   or gl.Instance = @GLDept)
	AND (@Employee is null or eh.Employee = @Employee)
ORDER BY 
  eh.PRCo
, gl.Instance
, Name

GO

Grant EXECUTE ON dbo.mckspEmplidList TO [MCKINSTRY\Viewpoint Users]

