SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMAD] as select a.* From bEMAD a

GO
GRANT SELECT ON  [dbo].[EMAD] TO [public]
GRANT INSERT ON  [dbo].[EMAD] TO [public]
GRANT DELETE ON  [dbo].[EMAD] TO [public]
GRANT UPDATE ON  [dbo].[EMAD] TO [public]
GO
