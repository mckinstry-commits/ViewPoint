SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDSL] as select * from vDDSL

GO
GRANT SELECT ON  [dbo].[DDSL] TO [public]
GRANT INSERT ON  [dbo].[DDSL] TO [public]
GRANT DELETE ON  [dbo].[DDSL] TO [public]
GRANT UPDATE ON  [dbo].[DDSL] TO [public]
GRANT SELECT ON  [dbo].[DDSL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDSL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDSL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDSL] TO [Viewpoint]
GO
