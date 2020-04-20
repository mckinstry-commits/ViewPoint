SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  view [dbo].[DDGridGroupingForm] as
select a.* From vDDGridGroupingForm a





GO
GRANT SELECT ON  [dbo].[DDGridGroupingForm] TO [public]
GRANT INSERT ON  [dbo].[DDGridGroupingForm] TO [public]
GRANT DELETE ON  [dbo].[DDGridGroupingForm] TO [public]
GRANT UPDATE ON  [dbo].[DDGridGroupingForm] TO [public]
GRANT SELECT ON  [dbo].[DDGridGroupingForm] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDGridGroupingForm] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDGridGroupingForm] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDGridGroupingForm] TO [Viewpoint]
GO
