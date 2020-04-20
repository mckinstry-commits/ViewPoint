SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRRP] as select a.* From bHRRP a

GO
GRANT SELECT ON  [dbo].[HRRP] TO [public]
GRANT INSERT ON  [dbo].[HRRP] TO [public]
GRANT DELETE ON  [dbo].[HRRP] TO [public]
GRANT UPDATE ON  [dbo].[HRRP] TO [public]
GO
