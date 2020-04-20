SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDDU] as select * from vDDDU

GO
GRANT SELECT ON  [dbo].[DDDU] TO [public]
GRANT INSERT ON  [dbo].[DDDU] TO [public]
GRANT DELETE ON  [dbo].[DDDU] TO [public]
GRANT UPDATE ON  [dbo].[DDDU] TO [public]
GRANT SELECT ON  [dbo].[DDDU] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDDU] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDDU] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDDU] TO [Viewpoint]
GO
