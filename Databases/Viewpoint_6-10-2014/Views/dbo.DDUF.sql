SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[DDUF]
  AS
  SELECT a.*
  FROM bDDUF a

GO
GRANT SELECT ON  [dbo].[DDUF] TO [public]
GRANT INSERT ON  [dbo].[DDUF] TO [public]
GRANT DELETE ON  [dbo].[DDUF] TO [public]
GRANT UPDATE ON  [dbo].[DDUF] TO [public]
GRANT SELECT ON  [dbo].[DDUF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDUF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDUF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDUF] TO [Viewpoint]
GO
