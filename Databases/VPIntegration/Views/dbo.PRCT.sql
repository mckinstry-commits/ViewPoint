SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCT] as select a.* From bPRCT a
GO
GRANT SELECT ON  [dbo].[PRCT] TO [public]
GRANT INSERT ON  [dbo].[PRCT] TO [public]
GRANT DELETE ON  [dbo].[PRCT] TO [public]
GRANT UPDATE ON  [dbo].[PRCT] TO [public]
GO
