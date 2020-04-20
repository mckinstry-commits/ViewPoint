SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMBG] as select a.* From bEMBG a
GO
GRANT SELECT ON  [dbo].[EMBG] TO [public]
GRANT INSERT ON  [dbo].[EMBG] TO [public]
GRANT DELETE ON  [dbo].[EMBG] TO [public]
GRANT UPDATE ON  [dbo].[EMBG] TO [public]
GO
