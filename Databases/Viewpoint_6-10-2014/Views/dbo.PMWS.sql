SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMWS] as select a.* From bPMWS a

GO
GRANT SELECT ON  [dbo].[PMWS] TO [public]
GRANT INSERT ON  [dbo].[PMWS] TO [public]
GRANT DELETE ON  [dbo].[PMWS] TO [public]
GRANT UPDATE ON  [dbo].[PMWS] TO [public]
GRANT SELECT ON  [dbo].[PMWS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMWS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMWS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMWS] TO [Viewpoint]
GO
