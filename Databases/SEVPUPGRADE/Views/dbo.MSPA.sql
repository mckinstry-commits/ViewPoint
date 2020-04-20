SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSPA] as select a.* From bMSPA a

GO
GRANT SELECT ON  [dbo].[MSPA] TO [public]
GRANT INSERT ON  [dbo].[MSPA] TO [public]
GRANT DELETE ON  [dbo].[MSPA] TO [public]
GRANT UPDATE ON  [dbo].[MSPA] TO [public]
GO
