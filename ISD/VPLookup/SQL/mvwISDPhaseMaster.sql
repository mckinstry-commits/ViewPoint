USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDPhaseMaster]    Script Date: 11/03/2014 14:36:43 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[mvwISDPhaseMaster]'))
DROP VIEW [dbo].[mvwISDPhaseMaster]
GO

USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwISDPhaseMaster]    Script Date: 11/03/2014 14:36:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create VIEW [dbo].[mvwISDPhaseMaster]
AS
SELECT 
	jcpm.*
,	ltrim(rtrim(jcpm.PhaseGroup)) + '.' + ltrim(rtrim(jcpm.Phase)) AS PhaseMasterKey
FROM
	JCPM jcpm 
WHERE
	jcpm.PhaseGroup IN (SELECT DISTINCT PhaseGroup FROM HQCO WHERE udTESTCo <> 'Y' )

GO


