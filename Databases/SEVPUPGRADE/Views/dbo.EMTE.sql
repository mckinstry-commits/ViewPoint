SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMTE] as select a.* From bEMTE a
GO
GRANT SELECT ON  [dbo].[EMTE] TO [public]
GRANT INSERT ON  [dbo].[EMTE] TO [public]
GRANT DELETE ON  [dbo].[EMTE] TO [public]
GRANT UPDATE ON  [dbo].[EMTE] TO [public]
GO
