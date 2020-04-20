SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBER] as select a.* From bJBER a

GO
GRANT SELECT ON  [dbo].[JBER] TO [public]
GRANT INSERT ON  [dbo].[JBER] TO [public]
GRANT DELETE ON  [dbo].[JBER] TO [public]
GRANT UPDATE ON  [dbo].[JBER] TO [public]
GO
