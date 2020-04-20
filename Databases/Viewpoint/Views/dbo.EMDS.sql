SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDS] as select a.* From bEMDS a

GO
GRANT SELECT ON  [dbo].[EMDS] TO [public]
GRANT INSERT ON  [dbo].[EMDS] TO [public]
GRANT DELETE ON  [dbo].[EMDS] TO [public]
GRANT UPDATE ON  [dbo].[EMDS] TO [public]
GO
