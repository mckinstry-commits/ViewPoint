SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[SLClaimHeader] as select a.* From vSLClaimHeader a

GO
GRANT SELECT ON  [dbo].[SLClaimHeader] TO [public]
GRANT INSERT ON  [dbo].[SLClaimHeader] TO [public]
GRANT DELETE ON  [dbo].[SLClaimHeader] TO [public]
GRANT UPDATE ON  [dbo].[SLClaimHeader] TO [public]
GO
