SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMMF] as select a.* From bPMMF a
GO
GRANT SELECT ON  [dbo].[PMMF] TO [public]
GRANT INSERT ON  [dbo].[PMMF] TO [public]
GRANT DELETE ON  [dbo].[PMMF] TO [public]
GRANT UPDATE ON  [dbo].[PMMF] TO [public]
GO
