SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTT] as select a.* From bPRTT a

GO
GRANT SELECT ON  [dbo].[PRTT] TO [public]
GRANT INSERT ON  [dbo].[PRTT] TO [public]
GRANT DELETE ON  [dbo].[PRTT] TO [public]
GRANT UPDATE ON  [dbo].[PRTT] TO [public]
GO
