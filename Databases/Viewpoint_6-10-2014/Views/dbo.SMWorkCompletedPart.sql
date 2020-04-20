SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMWorkCompletedPart] as select a.* From vSMWorkCompletedPart a
GO
GRANT SELECT ON  [dbo].[SMWorkCompletedPart] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedPart] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedPart] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedPart] TO [public]
GRANT SELECT ON  [dbo].[SMWorkCompletedPart] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkCompletedPart] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkCompletedPart] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkCompletedPart] TO [Viewpoint]
GO
