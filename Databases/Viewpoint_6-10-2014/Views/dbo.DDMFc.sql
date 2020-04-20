SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDMFc] as select a.* From vDDMFc a
GO
GRANT SELECT ON  [dbo].[DDMFc] TO [public]
GRANT INSERT ON  [dbo].[DDMFc] TO [public]
GRANT DELETE ON  [dbo].[DDMFc] TO [public]
GRANT UPDATE ON  [dbo].[DDMFc] TO [public]
GRANT SELECT ON  [dbo].[DDMFc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDMFc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDMFc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDMFc] TO [Viewpoint]
GO
