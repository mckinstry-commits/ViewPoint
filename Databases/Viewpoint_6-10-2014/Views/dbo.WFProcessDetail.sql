SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[WFProcessDetail] as select a.* From vWFProcessDetail a

GO
GRANT SELECT ON  [dbo].[WFProcessDetail] TO [public]
GRANT INSERT ON  [dbo].[WFProcessDetail] TO [public]
GRANT DELETE ON  [dbo].[WFProcessDetail] TO [public]
GRANT UPDATE ON  [dbo].[WFProcessDetail] TO [public]
GRANT SELECT ON  [dbo].[WFProcessDetail] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFProcessDetail] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFProcessDetail] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFProcessDetail] TO [Viewpoint]
GO
