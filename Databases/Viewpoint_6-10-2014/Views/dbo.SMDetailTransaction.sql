SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMDetailTransaction]
AS
	SELECT *
	FROM dbo.vSMDetailTransaction
GO
GRANT SELECT ON  [dbo].[SMDetailTransaction] TO [public]
GRANT INSERT ON  [dbo].[SMDetailTransaction] TO [public]
GRANT DELETE ON  [dbo].[SMDetailTransaction] TO [public]
GRANT UPDATE ON  [dbo].[SMDetailTransaction] TO [public]
GRANT SELECT ON  [dbo].[SMDetailTransaction] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMDetailTransaction] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMDetailTransaction] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMDetailTransaction] TO [Viewpoint]
GO
