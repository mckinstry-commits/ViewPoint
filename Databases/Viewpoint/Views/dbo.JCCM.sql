SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE view [dbo].[JCCM] as select a.* From bJCCM a




GO
GRANT SELECT ON  [dbo].[JCCM] TO [public]
GRANT INSERT ON  [dbo].[JCCM] TO [public]
GRANT DELETE ON  [dbo].[JCCM] TO [public]
GRANT UPDATE ON  [dbo].[JCCM] TO [public]
GO
