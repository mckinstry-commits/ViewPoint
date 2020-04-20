SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCScopeCodes] as select a.* From vPCScopeCodes a

GO
GRANT SELECT ON  [dbo].[PCScopeCodes] TO [public]
GRANT INSERT ON  [dbo].[PCScopeCodes] TO [public]
GRANT DELETE ON  [dbo].[PCScopeCodes] TO [public]
GRANT UPDATE ON  [dbo].[PCScopeCodes] TO [public]
GRANT SELECT ON  [dbo].[PCScopeCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCScopeCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCScopeCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCScopeCodes] TO [Viewpoint]
GO
