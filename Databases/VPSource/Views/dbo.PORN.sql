SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORN] as select a.* From bPORN a

GO
GRANT SELECT ON  [dbo].[PORN] TO [public]
GRANT INSERT ON  [dbo].[PORN] TO [public]
GRANT DELETE ON  [dbo].[PORN] TO [public]
GRANT UPDATE ON  [dbo].[PORN] TO [public]
GO
