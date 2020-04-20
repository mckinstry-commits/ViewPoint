SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMWP] as select a.* From bEMWP a
GO
GRANT SELECT ON  [dbo].[EMWP] TO [public]
GRANT INSERT ON  [dbo].[EMWP] TO [public]
GRANT DELETE ON  [dbo].[EMWP] TO [public]
GRANT UPDATE ON  [dbo].[EMWP] TO [public]
GRANT SELECT ON  [dbo].[EMWP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMWP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMWP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMWP] TO [Viewpoint]
GO
