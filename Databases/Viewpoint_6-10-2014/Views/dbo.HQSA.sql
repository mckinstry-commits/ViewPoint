SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[HQSA] 
		AS
		SELECT * 
		FROM vHQSA
GO
GRANT SELECT ON  [dbo].[HQSA] TO [public]
GRANT INSERT ON  [dbo].[HQSA] TO [public]
GRANT DELETE ON  [dbo].[HQSA] TO [public]
GRANT UPDATE ON  [dbo].[HQSA] TO [public]
GRANT SELECT ON  [dbo].[HQSA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQSA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQSA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQSA] TO [Viewpoint]
GO
