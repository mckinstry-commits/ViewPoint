SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[UDVersion]
AS
	SELECT * FROM vUDVersion
GO
GRANT SELECT ON  [dbo].[UDVersion] TO [public]
GRANT INSERT ON  [dbo].[UDVersion] TO [public]
GRANT DELETE ON  [dbo].[UDVersion] TO [public]
GRANT UPDATE ON  [dbo].[UDVersion] TO [public]
GO
