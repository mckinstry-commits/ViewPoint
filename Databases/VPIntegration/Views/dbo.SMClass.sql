SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMClass]
AS
SELECT a.* FROM dbo.vSMClass a



GO
GRANT SELECT ON  [dbo].[SMClass] TO [public]
GRANT INSERT ON  [dbo].[SMClass] TO [public]
GRANT DELETE ON  [dbo].[SMClass] TO [public]
GRANT UPDATE ON  [dbo].[SMClass] TO [public]
GO
