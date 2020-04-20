SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMLB] as select a.* From bEMLB a
GO
GRANT SELECT ON  [dbo].[EMLB] TO [public]
GRANT INSERT ON  [dbo].[EMLB] TO [public]
GRANT DELETE ON  [dbo].[EMLB] TO [public]
GRANT UPDATE ON  [dbo].[EMLB] TO [public]
GO
