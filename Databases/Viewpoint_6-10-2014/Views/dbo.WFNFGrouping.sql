SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WFNFGrouping] as select a.* From vWFNFGrouping a
GO
GRANT SELECT ON  [dbo].[WFNFGrouping] TO [public]
GRANT INSERT ON  [dbo].[WFNFGrouping] TO [public]
GRANT DELETE ON  [dbo].[WFNFGrouping] TO [public]
GRANT UPDATE ON  [dbo].[WFNFGrouping] TO [public]
GRANT SELECT ON  [dbo].[WFNFGrouping] TO [Viewpoint]
GRANT INSERT ON  [dbo].[WFNFGrouping] TO [Viewpoint]
GRANT DELETE ON  [dbo].[WFNFGrouping] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[WFNFGrouping] TO [Viewpoint]
GO
