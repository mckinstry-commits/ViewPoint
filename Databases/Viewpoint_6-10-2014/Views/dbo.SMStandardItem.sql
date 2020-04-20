SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMStandardItem] as select a.* From vSMStandardItem a
GO
GRANT SELECT ON  [dbo].[SMStandardItem] TO [public]
GRANT INSERT ON  [dbo].[SMStandardItem] TO [public]
GRANT DELETE ON  [dbo].[SMStandardItem] TO [public]
GRANT UPDATE ON  [dbo].[SMStandardItem] TO [public]
GRANT SELECT ON  [dbo].[SMStandardItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMStandardItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMStandardItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMStandardItem] TO [Viewpoint]
GO
