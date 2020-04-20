SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMWH] as select a.* From bEMWH a
GO
GRANT SELECT ON  [dbo].[EMWH] TO [public]
GRANT INSERT ON  [dbo].[EMWH] TO [public]
GRANT DELETE ON  [dbo].[EMWH] TO [public]
GRANT UPDATE ON  [dbo].[EMWH] TO [public]
GRANT SELECT ON  [dbo].[EMWH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMWH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMWH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMWH] TO [Viewpoint]
GO
