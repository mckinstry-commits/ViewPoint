SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSDD] as select a.* From bMSDD a

GO
GRANT SELECT ON  [dbo].[MSDD] TO [public]
GRANT INSERT ON  [dbo].[MSDD] TO [public]
GRANT DELETE ON  [dbo].[MSDD] TO [public]
GRANT UPDATE ON  [dbo].[MSDD] TO [public]
GO
