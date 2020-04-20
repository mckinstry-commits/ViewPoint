SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDB] as select a.* From bEMDB a

GO
GRANT SELECT ON  [dbo].[EMDB] TO [public]
GRANT INSERT ON  [dbo].[EMDB] TO [public]
GRANT DELETE ON  [dbo].[EMDB] TO [public]
GRANT UPDATE ON  [dbo].[EMDB] TO [public]
GO
