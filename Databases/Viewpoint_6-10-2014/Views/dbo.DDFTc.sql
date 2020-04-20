SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  view [dbo].[DDFTc] as select a.* From vDDFTc a
                                                                                               




GO
GRANT SELECT ON  [dbo].[DDFTc] TO [public]
GRANT INSERT ON  [dbo].[DDFTc] TO [public]
GRANT DELETE ON  [dbo].[DDFTc] TO [public]
GRANT UPDATE ON  [dbo].[DDFTc] TO [public]
GRANT SELECT ON  [dbo].[DDFTc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFTc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFTc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFTc] TO [Viewpoint]
GO
