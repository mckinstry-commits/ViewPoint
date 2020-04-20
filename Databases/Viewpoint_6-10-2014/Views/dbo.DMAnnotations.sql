SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[DMAnnotations] as select a.* From vDMAnnotations a
GO
GRANT SELECT ON  [dbo].[DMAnnotations] TO [public]
GRANT INSERT ON  [dbo].[DMAnnotations] TO [public]
GRANT DELETE ON  [dbo].[DMAnnotations] TO [public]
GRANT UPDATE ON  [dbo].[DMAnnotations] TO [public]
GRANT SELECT ON  [dbo].[DMAnnotations] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DMAnnotations] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DMAnnotations] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DMAnnotations] TO [Viewpoint]
GO
