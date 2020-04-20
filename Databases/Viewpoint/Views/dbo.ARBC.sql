SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBC] as select a.* From bARBC a

GO
GRANT SELECT ON  [dbo].[ARBC] TO [public]
GRANT INSERT ON  [dbo].[ARBC] TO [public]
GRANT DELETE ON  [dbo].[ARBC] TO [public]
GRANT UPDATE ON  [dbo].[ARBC] TO [public]
GO
