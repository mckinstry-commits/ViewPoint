SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCRD] as select a.* From bJCRD a

GO
GRANT SELECT ON  [dbo].[JCRD] TO [public]
GRANT INSERT ON  [dbo].[JCRD] TO [public]
GRANT DELETE ON  [dbo].[JCRD] TO [public]
GRANT UPDATE ON  [dbo].[JCRD] TO [public]
GO
