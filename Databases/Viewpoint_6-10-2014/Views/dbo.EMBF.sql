SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMBF] as select a.* From bEMBF a
GO
GRANT SELECT ON  [dbo].[EMBF] TO [public]
GRANT INSERT ON  [dbo].[EMBF] TO [public]
GRANT DELETE ON  [dbo].[EMBF] TO [public]
GRANT UPDATE ON  [dbo].[EMBF] TO [public]
GRANT SELECT ON  [dbo].[EMBF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMBF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMBF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMBF] TO [Viewpoint]
GO
