SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APFT] as select a.* From bAPFT a

GO
GRANT SELECT ON  [dbo].[APFT] TO [public]
GRANT INSERT ON  [dbo].[APFT] TO [public]
GRANT DELETE ON  [dbo].[APFT] TO [public]
GRANT UPDATE ON  [dbo].[APFT] TO [public]
GO
