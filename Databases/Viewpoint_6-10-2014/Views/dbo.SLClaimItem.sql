SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[SLClaimItem] as select a.* From vSLClaimItem a


GO
GRANT SELECT ON  [dbo].[SLClaimItem] TO [public]
GRANT INSERT ON  [dbo].[SLClaimItem] TO [public]
GRANT DELETE ON  [dbo].[SLClaimItem] TO [public]
GRANT UPDATE ON  [dbo].[SLClaimItem] TO [public]
GRANT SELECT ON  [dbo].[SLClaimItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLClaimItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLClaimItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLClaimItem] TO [Viewpoint]
GO
