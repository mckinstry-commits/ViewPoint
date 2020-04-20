SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMGL] as select a.* From bEMGL a

GO
GRANT SELECT ON  [dbo].[EMGL] TO [public]
GRANT INSERT ON  [dbo].[EMGL] TO [public]
GRANT DELETE ON  [dbo].[EMGL] TO [public]
GRANT UPDATE ON  [dbo].[EMGL] TO [public]
GO
