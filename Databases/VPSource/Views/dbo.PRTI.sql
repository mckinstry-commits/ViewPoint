SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTI] as select a.* From bPRTI a
GO
GRANT SELECT ON  [dbo].[PRTI] TO [public]
GRANT INSERT ON  [dbo].[PRTI] TO [public]
GRANT DELETE ON  [dbo].[PRTI] TO [public]
GRANT UPDATE ON  [dbo].[PRTI] TO [public]
GO
