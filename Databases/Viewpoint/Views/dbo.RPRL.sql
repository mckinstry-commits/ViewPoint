SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPRL] as select a.* From vRPRL a
GO
GRANT SELECT ON  [dbo].[RPRL] TO [public]
GRANT INSERT ON  [dbo].[RPRL] TO [public]
GRANT DELETE ON  [dbo].[RPRL] TO [public]
GRANT UPDATE ON  [dbo].[RPRL] TO [public]
GO
