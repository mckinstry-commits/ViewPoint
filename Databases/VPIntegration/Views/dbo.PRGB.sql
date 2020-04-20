SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRGB] as select a.* From bPRGB a

GO
GRANT SELECT ON  [dbo].[PRGB] TO [public]
GRANT INSERT ON  [dbo].[PRGB] TO [public]
GRANT DELETE ON  [dbo].[PRGB] TO [public]
GRANT UPDATE ON  [dbo].[PRGB] TO [public]
GO
