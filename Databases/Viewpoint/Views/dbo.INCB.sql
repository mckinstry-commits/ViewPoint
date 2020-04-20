SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INCB] as select a.* From bINCB a
GO
GRANT SELECT ON  [dbo].[INCB] TO [public]
GRANT INSERT ON  [dbo].[INCB] TO [public]
GRANT DELETE ON  [dbo].[INCB] TO [public]
GRANT UPDATE ON  [dbo].[INCB] TO [public]
GO
