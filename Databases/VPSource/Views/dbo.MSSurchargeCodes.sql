SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO














CREATE view [dbo].[MSSurchargeCodes] as select a.* From bMSSurchargeCodes a















GO
GRANT SELECT ON  [dbo].[MSSurchargeCodes] TO [public]
GRANT INSERT ON  [dbo].[MSSurchargeCodes] TO [public]
GRANT DELETE ON  [dbo].[MSSurchargeCodes] TO [public]
GRANT UPDATE ON  [dbo].[MSSurchargeCodes] TO [public]
GO
