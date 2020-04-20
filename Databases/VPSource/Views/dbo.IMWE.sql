SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[IMWE] as select a.* From bIMWE a

GO
GRANT SELECT ON  [dbo].[IMWE] TO [public]
GRANT INSERT ON  [dbo].[IMWE] TO [public]
GRANT DELETE ON  [dbo].[IMWE] TO [public]
GRANT UPDATE ON  [dbo].[IMWE] TO [public]
GO
