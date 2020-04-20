SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPFD] as select a.* From vRPFD a
GO
GRANT SELECT ON  [dbo].[RPFD] TO [public]
GRANT INSERT ON  [dbo].[RPFD] TO [public]
GRANT DELETE ON  [dbo].[RPFD] TO [public]
GRANT UPDATE ON  [dbo].[RPFD] TO [public]
GRANT SELECT ON  [dbo].[RPFD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPFD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPFD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPFD] TO [Viewpoint]
GO
