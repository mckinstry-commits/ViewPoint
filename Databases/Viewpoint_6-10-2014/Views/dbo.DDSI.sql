SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[DDSI] as select a.* From vDDSI a
                                                                                             



GO
GRANT SELECT ON  [dbo].[DDSI] TO [public]
GRANT INSERT ON  [dbo].[DDSI] TO [public]
GRANT DELETE ON  [dbo].[DDSI] TO [public]
GRANT UPDATE ON  [dbo].[DDSI] TO [public]
GRANT SELECT ON  [dbo].[DDSI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDSI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDSI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDSI] TO [Viewpoint]
GO
