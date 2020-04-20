SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDTC
AS
SELECT     dbo.vDDTC.*
FROM         dbo.vDDTC

GO
GRANT SELECT ON  [dbo].[DDTC] TO [public]
GRANT INSERT ON  [dbo].[DDTC] TO [public]
GRANT DELETE ON  [dbo].[DDTC] TO [public]
GRANT UPDATE ON  [dbo].[DDTC] TO [public]
GRANT SELECT ON  [dbo].[DDTC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDTC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDTC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDTC] TO [Viewpoint]
GO
