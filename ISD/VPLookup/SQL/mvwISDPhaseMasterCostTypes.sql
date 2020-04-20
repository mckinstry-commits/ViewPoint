USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDPhaseMasterCostTypes]    Script Date: 11/03/2014 14:37:09 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[mvwISDPhaseMasterCostTypes]'))
DROP VIEW [dbo].[mvwISDPhaseMasterCostTypes]
GO

USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDPhaseMasterCostTypes]    Script Date: 11/03/2014 14:37:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create VIEW [dbo].[mvwISDPhaseMasterCostTypes]
AS	
SELECT 
	jcpc.* 
,	jcct.Abbreviation AS CostTypeCode
,	jcct.Description AS CostTypeDesc
,	ltrim(rtrim(jcpc.PhaseGroup)) + '.' + ltrim(rtrim(jcpc.Phase)) AS PhaseMasterKey
,	ltrim(rtrim(jcpc.PhaseGroup)) + '.' + ltrim(rtrim(jcpc.Phase)) + '.' +  ltrim(rtrim(jcct.Abbreviation)) AS PhaseMasterCostTypeKey
FROM 
	JCPC jcpc LEFT OUTER JOIN
	mvwISDPhaseMaster t1 ON
		jcpc.PhaseGroup=t1.PhaseGroup
	AND jcpc.Phase=t1.Phase JOIN
	JCCT jcct ON
		jcct.PhaseGroup=jcpc.PhaseGroup
	AND jcct.CostType=jcpc.CostType
	

GO


