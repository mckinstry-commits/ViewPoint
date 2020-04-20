SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[SMCallType] 
AS
SELECT a.* FROM dbo.vSMCallType a










GO
GRANT SELECT ON  [dbo].[SMCallType] TO [public]
GRANT INSERT ON  [dbo].[SMCallType] TO [public]
GRANT DELETE ON  [dbo].[SMCallType] TO [public]
GRANT UPDATE ON  [dbo].[SMCallType] TO [public]
GO
