SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PROP] as select a.* From bPROP a

GO
GRANT SELECT ON  [dbo].[PROP] TO [public]
GRANT INSERT ON  [dbo].[PROP] TO [public]
GRANT DELETE ON  [dbo].[PROP] TO [public]
GRANT UPDATE ON  [dbo].[PROP] TO [public]
GO
