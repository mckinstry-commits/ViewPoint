SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSMD] as select a.* From bMSMD a
GO
GRANT SELECT ON  [dbo].[MSMD] TO [public]
GRANT INSERT ON  [dbo].[MSMD] TO [public]
GRANT DELETE ON  [dbo].[MSMD] TO [public]
GRANT UPDATE ON  [dbo].[MSMD] TO [public]
GO
