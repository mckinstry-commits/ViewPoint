SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[DDCTShared] AS
SELECT DDTM.TextID, DDTM.TextType, DDTM.CultureText, DDCL.KeyID AS CultureID FROM DDTM
	INNER JOIN DDCL ON DDCL.Culture = 'en-US'
UNION ALL
SELECT DDTM.TextID, DDTM.TextType, DDCT.CultureText, DDCT.CultureID FROM DDTM
	INNER JOIN DDCT ON DDTM.TextID = DDCT.TextID

GO
GRANT SELECT ON  [dbo].[DDCTShared] TO [public]
GRANT INSERT ON  [dbo].[DDCTShared] TO [public]
GRANT DELETE ON  [dbo].[DDCTShared] TO [public]
GRANT UPDATE ON  [dbo].[DDCTShared] TO [public]
GRANT SELECT ON  [dbo].[DDCTShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDCTShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDCTShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDCTShared] TO [Viewpoint]
GO
