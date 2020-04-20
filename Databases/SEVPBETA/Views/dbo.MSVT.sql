SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSVT] as select a.* From bMSVT a

GO
GRANT SELECT ON  [dbo].[MSVT] TO [public]
GRANT INSERT ON  [dbo].[MSVT] TO [public]
GRANT DELETE ON  [dbo].[MSVT] TO [public]
GRANT UPDATE ON  [dbo].[MSVT] TO [public]
GO
