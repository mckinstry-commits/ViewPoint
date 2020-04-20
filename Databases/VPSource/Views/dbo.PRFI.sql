SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PRFI] as select a.* From bPRFI a

GO
GRANT SELECT ON  [dbo].[PRFI] TO [public]
GRANT INSERT ON  [dbo].[PRFI] TO [public]
GRANT DELETE ON  [dbo].[PRFI] TO [public]
GRANT UPDATE ON  [dbo].[PRFI] TO [public]
GO
