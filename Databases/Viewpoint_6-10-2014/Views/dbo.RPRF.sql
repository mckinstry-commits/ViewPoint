SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPRF] as select a.* From vRPRF a

GO
GRANT SELECT ON  [dbo].[RPRF] TO [public]
GRANT INSERT ON  [dbo].[RPRF] TO [public]
GRANT DELETE ON  [dbo].[RPRF] TO [public]
GRANT UPDATE ON  [dbo].[RPRF] TO [public]
GRANT SELECT ON  [dbo].[RPRF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRF] TO [Viewpoint]
GO
