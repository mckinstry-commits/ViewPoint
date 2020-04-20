SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APEM] as select a.* From bAPEM a

GO
GRANT SELECT ON  [dbo].[APEM] TO [public]
GRANT INSERT ON  [dbo].[APEM] TO [public]
GRANT DELETE ON  [dbo].[APEM] TO [public]
GRANT UPDATE ON  [dbo].[APEM] TO [public]
GO
