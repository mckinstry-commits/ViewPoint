SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDTS] as select * from vDDTS

GO
GRANT SELECT ON  [dbo].[DDTS] TO [public]
GRANT INSERT ON  [dbo].[DDTS] TO [public]
GRANT DELETE ON  [dbo].[DDTS] TO [public]
GRANT UPDATE ON  [dbo].[DDTS] TO [public]
GRANT SELECT ON  [dbo].[DDTS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDTS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDTS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDTS] TO [Viewpoint]
GO
