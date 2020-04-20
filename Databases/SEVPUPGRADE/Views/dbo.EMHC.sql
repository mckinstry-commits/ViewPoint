SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMHC] as select a.* From bEMHC a

GO
GRANT SELECT ON  [dbo].[EMHC] TO [public]
GRANT INSERT ON  [dbo].[EMHC] TO [public]
GRANT DELETE ON  [dbo].[EMHC] TO [public]
GRANT UPDATE ON  [dbo].[EMHC] TO [public]
GO
