SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POHD] as select a.* From bPOHD a
GO
GRANT SELECT ON  [dbo].[POHD] TO [public]
GRANT INSERT ON  [dbo].[POHD] TO [public]
GRANT DELETE ON  [dbo].[POHD] TO [public]
GRANT UPDATE ON  [dbo].[POHD] TO [public]
GO
