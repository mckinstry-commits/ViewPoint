SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE view [dbo].[HQApprovalModuleCompany] as 

SELECT 'HQ' AS [Mod] 
		,HQCo AS [Co]
		,[Name]
FROM HQCO

UNION ALL

SELECT 'JC' AS [Mod] 
		,JCCo AS [Co]
		,[Name]
FROM JCCO
JOIN HQCO WITH(NOLOCK) 
	ON JCCO.JCCo = HQCO.HQCo

UNION ALL

SELECT 'IN' AS [Mod] 
		,INCo AS [Co]
		,[Name]
FROM INCO
JOIN HQCO WITH(NOLOCK) 
	ON INCO.INCo = HQCO.HQCo

UNION ALL

SELECT 'EM' AS [Mod] 
		,EMCo AS [Co]
		,[Name]
FROM EMCO
JOIN HQCO WITH(NOLOCK) 
	ON EMCO.EMCo = HQCO.HQCo

UNION ALL

SELECT 'SL' AS [Mod] 
		,SLCo AS [Co]
		,[Name]
FROM SLCO
JOIN HQCO WITH(NOLOCK) 
	ON SLCO.SLCo = HQCO.HQCo

UNION ALL

SELECT 'GL' AS [Mod] 
		,GLCo AS [Co]
		,[Name]
FROM GLCO
JOIN HQCO WITH(NOLOCK) 
	ON GLCO.GLCo = HQCO.HQCo

GO
GRANT SELECT ON  [dbo].[HQApprovalModuleCompany] TO [public]
GRANT INSERT ON  [dbo].[HQApprovalModuleCompany] TO [public]
GRANT DELETE ON  [dbo].[HQApprovalModuleCompany] TO [public]
GRANT UPDATE ON  [dbo].[HQApprovalModuleCompany] TO [public]
GRANT SELECT ON  [dbo].[HQApprovalModuleCompany] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQApprovalModuleCompany] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQApprovalModuleCompany] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQApprovalModuleCompany] TO [Viewpoint]
GO
