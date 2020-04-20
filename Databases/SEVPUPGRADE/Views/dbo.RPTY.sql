SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPTY] as select a.* From vRPTY a
GO
GRANT SELECT ON  [dbo].[RPTY] TO [public]
GRANT INSERT ON  [dbo].[RPTY] TO [public]
GRANT DELETE ON  [dbo].[RPTY] TO [public]
GRANT UPDATE ON  [dbo].[RPTY] TO [public]
GO
