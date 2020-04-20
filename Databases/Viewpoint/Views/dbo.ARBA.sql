SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBA] as select a.* From bARBA a

GO
GRANT SELECT ON  [dbo].[ARBA] TO [public]
GRANT INSERT ON  [dbo].[ARBA] TO [public]
GRANT DELETE ON  [dbo].[ARBA] TO [public]
GRANT UPDATE ON  [dbo].[ARBA] TO [public]
GO
