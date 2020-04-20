SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMTD] as select a.* From bEMTD a
GO
GRANT SELECT ON  [dbo].[EMTD] TO [public]
GRANT INSERT ON  [dbo].[EMTD] TO [public]
GRANT DELETE ON  [dbo].[EMTD] TO [public]
GRANT UPDATE ON  [dbo].[EMTD] TO [public]
GRANT SELECT ON  [dbo].[EMTD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMTD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMTD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMTD] TO [Viewpoint]
GO
