SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMWH] as select a.* From bIMWH a
GO
GRANT SELECT ON  [dbo].[IMWH] TO [public]
GRANT INSERT ON  [dbo].[IMWH] TO [public]
GRANT DELETE ON  [dbo].[IMWH] TO [public]
GRANT UPDATE ON  [dbo].[IMWH] TO [public]
GO
