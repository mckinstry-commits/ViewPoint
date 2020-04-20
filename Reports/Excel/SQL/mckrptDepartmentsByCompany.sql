IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mckrptDepartmentsByCompany]'))
	DROP PROCEDURE [dbo].[mckrptDepartmentsByCompany]
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 08/19/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE PROCEDURE [dbo].[mckrptDepartmentsByCompany]
	@PRCo int = null
AS
BEGIN

IF (@PRCo IS NOT NULL)
	SELECT	glpi3.Instance AS EmpGLDept
	,		REPLACE(REPLACE(glpi3.Description, CHAR(13), ''), CHAR(10), '') AS EmpGLDeptDesc
	FROM	PRDP prdp JOIN
			GLPI glpi3 ON
				prdp.PRCo=glpi3.GLCo
			AND prdp.PRCo=@PRCo
			AND glpi3.PartNo=3
			AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4)
	GROUP BY
			glpi3.Instance
	,		glpi3.Description 
ELSE
	SELECT	glpi3.Instance AS EmpGLDept
	,		REPLACE(REPLACE(glpi3.Description, CHAR(13), ''), CHAR(10), '') AS EmpGLDeptDesc
	FROM	PRDP prdp JOIN
			GLPI glpi3 ON
				prdp.PRCo=glpi3.GLCo
			AND glpi3.PartNo=3
			AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4)
	GROUP BY
			glpi3.Instance
	,		glpi3.Description
END
GO

GRANT EXECUTE
    ON OBJECT::[dbo].[mckrptDepartmentsByCompany] TO [MCKINSTRY\ViewpointUsers];
GO

--Test script
--EXEC dbo.[mckrptDepartmentsByCompany]
--EXEC dbo.[mckrptDepartmentsByCompany] 60
--EXEC dbo.[mckrptDepartmentsByCompany] 111

/*
-- Other queries
SELECT	PRCo AS PayRollCompany
FROM	PRCO

SELECT	DISTINCT PRCo AS PayRollCompany
FROM	PRDP

SELECT	prdp.PRCo AS PayRollCompany
,       glpi3.Instance AS EmpGLDept
,		glpi3.Description AS EmpGLDeptDesc
FROM	PRDP prdp JOIN
		GLPI glpi3 ON
            prdp.PRCo=glpi3.GLCo
		AND glpi3.PartNo=3
		AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4)

SELECT  DISTINCT prdp.PRCo
FROM	PRDP prdp JOIN
		GLPI glpi3 ON
		glpi3.GLCo = prdp.PRCo
	AND glpi3.PartNo=3
	AND glpi3.Instance=SUBSTRING(prdp.JCFixedRateGLAcct,10,4)

*/