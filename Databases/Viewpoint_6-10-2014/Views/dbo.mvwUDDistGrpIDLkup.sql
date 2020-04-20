SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[mvwUDDistGrpIDLkup] 
	as 

	select 
		'R' AS Type
		,'Region' AS TypeDescription
		, R.KeyID
		, NULL AS IDCompany
		, R.Region AS ID
		, RespPersonCo AS ResponsiblePersonCo
		, ResponsiblePerson AS ResponsiblePerson
		, R.Name  AS Description
	From dbo.udRegion R
	UNION ALL
	SELECT 
		'O' AS Type
		,'Operating Unit' AS TypeDescription
		, OU.KeyID
		, OU.Co 
		, OU.OperatingUnit AS ID
		, OU.Co AS ResponsiblePersonCo
		, OU.ResponsiblePerson
		, OU.UnitName AS Description
	FROM dbo.udOperatingUnit OU
	UNION ALL
	SELECT 
		'C' AS Type
		,'HQCO'
		, CO.KeyID
		, CO.HQCo
		, CONVERT(VARCHAR(3), CO.HQCo)
		, CO.HQCo, ''
		,CO.Name
	FROM dbo.HQCO CO
	UNION ALL
	SELECT 
		'D' 
		,'GL Department'
		, GL.KeyID
		, GL.Co
		, GL.GLDept
		, GL.Co
		, GL.ResponsiblePerson
		, PI.Description
	FROM dbo.udGLDept GL
		INNER JOIN GLPI PI ON PI.GLCo = GL.Co AND PI.Instance = GL.GLDept AND PI.PartNo = 3
	UNION ALL	
	SELECT 
		'X'
		,'Department Region'
		, DR.KeyID
		, DR.GLCo
		, CONVERT(VARCHAR(30),DR.Seq)
		, DR.PMCo
		, DR.RespPerson
		, ISNULL(DRg.Description,'') + ' / ' + ISNULL(Rr.Name, '')
	FROM dbo.udDeptReg DR
		LEFT OUTER JOIN dbo.GLPI DRg ON DRg.GLCo = DR.GLCo AND DRg.Instance = DR.Dept AND DRg.PartNo=3 
		LEFT OUTER JOIN dbo.udRegion Rr ON Rr.Region = DR.Region


GO
