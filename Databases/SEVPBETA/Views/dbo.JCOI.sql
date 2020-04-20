SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCOI] as select a.* From bJCOI a
GO
GRANT SELECT ON  [dbo].[JCOI] TO [public]
GRANT INSERT ON  [dbo].[JCOI] TO [public]
GRANT DELETE ON  [dbo].[JCOI] TO [public]
GRANT UPDATE ON  [dbo].[JCOI] TO [public]
GO
