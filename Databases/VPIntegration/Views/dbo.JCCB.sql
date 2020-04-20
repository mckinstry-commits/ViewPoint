SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCB] as select a.* From bJCCB a
GO
GRANT SELECT ON  [dbo].[JCCB] TO [public]
GRANT INSERT ON  [dbo].[JCCB] TO [public]
GRANT DELETE ON  [dbo].[JCCB] TO [public]
GRANT UPDATE ON  [dbo].[JCCB] TO [public]
GO
