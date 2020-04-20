SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APUI] as select a.* From bAPUI a
GO
GRANT SELECT ON  [dbo].[APUI] TO [public]
GRANT INSERT ON  [dbo].[APUI] TO [public]
GRANT DELETE ON  [dbo].[APUI] TO [public]
GRANT UPDATE ON  [dbo].[APUI] TO [public]
GRANT SELECT ON  [dbo].[APUI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APUI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APUI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APUI] TO [Viewpoint]
GO
