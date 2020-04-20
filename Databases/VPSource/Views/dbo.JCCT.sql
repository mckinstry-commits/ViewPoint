SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCT] as select a.* From bJCCT a
GO
GRANT SELECT ON  [dbo].[JCCT] TO [public]
GRANT INSERT ON  [dbo].[JCCT] TO [public]
GRANT DELETE ON  [dbo].[JCCT] TO [public]
GRANT UPDATE ON  [dbo].[JCCT] TO [public]
GO
