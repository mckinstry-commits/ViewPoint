SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[UDVH] as select a.* From bUDVH a
GO
GRANT SELECT ON  [dbo].[UDVH] TO [public]
GRANT INSERT ON  [dbo].[UDVH] TO [public]
GRANT DELETE ON  [dbo].[UDVH] TO [public]
GRANT UPDATE ON  [dbo].[UDVH] TO [public]
GO
