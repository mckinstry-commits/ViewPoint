SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQRD] as select a.* From vHQRD a
GO
GRANT SELECT ON  [dbo].[HQRD] TO [public]
GRANT INSERT ON  [dbo].[HQRD] TO [public]
GRANT DELETE ON  [dbo].[HQRD] TO [public]
GRANT UPDATE ON  [dbo].[HQRD] TO [public]
GO
