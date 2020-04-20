SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APCO] as select a.* From bAPCO a
GO
GRANT SELECT ON  [dbo].[APCO] TO [public]
GRANT INSERT ON  [dbo].[APCO] TO [public]
GRANT DELETE ON  [dbo].[APCO] TO [public]
GRANT UPDATE ON  [dbo].[APCO] TO [public]
GRANT SELECT ON  [dbo].[APCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APCO] TO [Viewpoint]
GO
