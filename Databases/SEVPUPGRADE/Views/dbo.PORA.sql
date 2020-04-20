SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORA] as select a.* From bPORA a

GO
GRANT SELECT ON  [dbo].[PORA] TO [public]
GRANT INSERT ON  [dbo].[PORA] TO [public]
GRANT DELETE ON  [dbo].[PORA] TO [public]
GRANT UPDATE ON  [dbo].[PORA] TO [public]
GO
