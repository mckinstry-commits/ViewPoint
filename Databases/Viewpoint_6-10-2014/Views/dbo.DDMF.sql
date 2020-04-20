SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDMF] as select * from vDDMF

GO
GRANT SELECT ON  [dbo].[DDMF] TO [public]
GRANT INSERT ON  [dbo].[DDMF] TO [public]
GRANT DELETE ON  [dbo].[DDMF] TO [public]
GRANT UPDATE ON  [dbo].[DDMF] TO [public]
GRANT SELECT ON  [dbo].[DDMF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDMF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDMF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDMF] TO [Viewpoint]
GO
