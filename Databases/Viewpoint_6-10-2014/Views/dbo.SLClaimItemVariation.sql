SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE view [dbo].[SLClaimItemVariation] as select a.* From vSLClaimItemVariation a








GO
GRANT SELECT ON  [dbo].[SLClaimItemVariation] TO [public]
GRANT INSERT ON  [dbo].[SLClaimItemVariation] TO [public]
GRANT DELETE ON  [dbo].[SLClaimItemVariation] TO [public]
GRANT UPDATE ON  [dbo].[SLClaimItemVariation] TO [public]
GRANT SELECT ON  [dbo].[SLClaimItemVariation] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLClaimItemVariation] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLClaimItemVariation] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLClaimItemVariation] TO [Viewpoint]
GO
