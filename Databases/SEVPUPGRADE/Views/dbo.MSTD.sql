SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSTD] as select a.* From bMSTD a
GO
GRANT SELECT ON  [dbo].[MSTD] TO [public]
GRANT INSERT ON  [dbo].[MSTD] TO [public]
GRANT DELETE ON  [dbo].[MSTD] TO [public]
GRANT UPDATE ON  [dbo].[MSTD] TO [public]
GO
