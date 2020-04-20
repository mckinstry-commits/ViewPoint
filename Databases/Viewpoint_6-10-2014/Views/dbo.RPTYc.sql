SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[RPTYc] as select a.* From vRPTYc a
   
  




GO
GRANT SELECT ON  [dbo].[RPTYc] TO [public]
GRANT INSERT ON  [dbo].[RPTYc] TO [public]
GRANT DELETE ON  [dbo].[RPTYc] TO [public]
GRANT UPDATE ON  [dbo].[RPTYc] TO [public]
GRANT SELECT ON  [dbo].[RPTYc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPTYc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPTYc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPTYc] TO [Viewpoint]
GO
