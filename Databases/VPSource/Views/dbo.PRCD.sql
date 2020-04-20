SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCD] as select a.* From bPRCD a
GO
GRANT SELECT ON  [dbo].[PRCD] TO [public]
GRANT INSERT ON  [dbo].[PRCD] TO [public]
GRANT DELETE ON  [dbo].[PRCD] TO [public]
GRANT UPDATE ON  [dbo].[PRCD] TO [public]
GO
