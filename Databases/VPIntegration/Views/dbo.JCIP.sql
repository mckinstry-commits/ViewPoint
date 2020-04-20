SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCIP] as select a.* From bJCIP a
GO
GRANT SELECT ON  [dbo].[JCIP] TO [public]
GRANT INSERT ON  [dbo].[JCIP] TO [public]
GRANT DELETE ON  [dbo].[JCIP] TO [public]
GRANT UPDATE ON  [dbo].[JCIP] TO [public]
GO
