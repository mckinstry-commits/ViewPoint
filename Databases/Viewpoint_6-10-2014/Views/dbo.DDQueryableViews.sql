SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view [dbo].[DDQueryableViews] as select * from vDDQueryableViews


GO
GRANT SELECT ON  [dbo].[DDQueryableViews] TO [public]
GRANT INSERT ON  [dbo].[DDQueryableViews] TO [public]
GRANT DELETE ON  [dbo].[DDQueryableViews] TO [public]
GRANT UPDATE ON  [dbo].[DDQueryableViews] TO [public]
GRANT SELECT ON  [dbo].[DDQueryableViews] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDQueryableViews] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDQueryableViews] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDQueryableViews] TO [Viewpoint]
GO
