SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSEM] as select a.* From bMSEM a
GO
GRANT SELECT ON  [dbo].[MSEM] TO [public]
GRANT INSERT ON  [dbo].[MSEM] TO [public]
GRANT DELETE ON  [dbo].[MSEM] TO [public]
GRANT UPDATE ON  [dbo].[MSEM] TO [public]
GO
