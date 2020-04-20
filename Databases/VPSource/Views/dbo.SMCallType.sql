
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMCallType] as select a.* From vSMCallType a
GO

GRANT SELECT ON  [dbo].[SMCallType] TO [public]
GRANT INSERT ON  [dbo].[SMCallType] TO [public]
GRANT DELETE ON  [dbo].[SMCallType] TO [public]
GRANT UPDATE ON  [dbo].[SMCallType] TO [public]
GO
