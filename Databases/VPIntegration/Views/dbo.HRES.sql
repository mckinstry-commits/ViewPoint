SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRES] as select a.* From bHRES a
GO
GRANT SELECT ON  [dbo].[HRES] TO [public]
GRANT INSERT ON  [dbo].[HRES] TO [public]
GRANT DELETE ON  [dbo].[HRES] TO [public]
GRANT UPDATE ON  [dbo].[HRES] TO [public]
GO
