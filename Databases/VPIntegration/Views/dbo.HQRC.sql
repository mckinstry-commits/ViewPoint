SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQRC] as select a.* From bHQRC a

GO
GRANT SELECT ON  [dbo].[HQRC] TO [public]
GRANT INSERT ON  [dbo].[HQRC] TO [public]
GRANT DELETE ON  [dbo].[HQRC] TO [public]
GRANT UPDATE ON  [dbo].[HQRC] TO [public]
GO
