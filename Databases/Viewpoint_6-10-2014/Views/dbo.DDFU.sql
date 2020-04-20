SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDFU]
AS
SELECT     *
FROM         dbo.vDDFU

GO
GRANT SELECT ON  [dbo].[DDFU] TO [public]
GRANT INSERT ON  [dbo].[DDFU] TO [public]
GRANT DELETE ON  [dbo].[DDFU] TO [public]
GRANT UPDATE ON  [dbo].[DDFU] TO [public]
GRANT SELECT ON  [dbo].[DDFU] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFU] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFU] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFU] TO [Viewpoint]
GO
