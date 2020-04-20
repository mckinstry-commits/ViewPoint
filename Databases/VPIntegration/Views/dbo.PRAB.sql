SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRAB] as select a.* From bPRAB a
GO
GRANT SELECT ON  [dbo].[PRAB] TO [public]
GRANT INSERT ON  [dbo].[PRAB] TO [public]
GRANT DELETE ON  [dbo].[PRAB] TO [public]
GRANT UPDATE ON  [dbo].[PRAB] TO [public]
GO
