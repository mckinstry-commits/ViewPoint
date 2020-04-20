SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[RPRQ] as select a.* From vRPRQ a

GO
GRANT SELECT ON  [dbo].[RPRQ] TO [public]
GRANT INSERT ON  [dbo].[RPRQ] TO [public]
GRANT DELETE ON  [dbo].[RPRQ] TO [public]
GRANT UPDATE ON  [dbo].[RPRQ] TO [public]
GRANT SELECT ON  [dbo].[RPRQ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPRQ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPRQ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPRQ] TO [Viewpoint]
GO
