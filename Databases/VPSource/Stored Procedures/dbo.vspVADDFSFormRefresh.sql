SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Aaron Lang, vspVADDFSFormRefresh>
--				CC	07/14/09 - #129922 - Added link for form header to culture text
-- Create date: <6/4/07>
-- Description:	<Creates user records that do not exist and appends them onto the 
--				 list IN DDFS>
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDFSFormRefresh]

(@NameArray VARCHAR(max),@ModArray VARCHAR(8000), @CoArray VARCHAR(8000), @culture INT = NULL) --, 

	-- Add the parameters for the stored procedure here

AS
Begin
WITH FormNames (FormName)
AS
(
	SELECT Names FROM dbo.vfTableFromArray(@NameArray)
)
Select f.Mod, h.HQCo AS Co, g.[Name], ISNULL(CultureText.CultureText, f.Title) AS Title, f.Form, ISNULL(s.[Access], 3) AS Access , ISNULL(s.[RecAdd], 'N') AS RecAdd, ISNULL(s.[RecUpdate], 'N') AS RecUpdate, 

ISNULL(s.[RecDelete], 'N') AS RecDelete, ISNULL(s.AttachmentSecurityLevel, 3) AS Attachments, g.SecurityGroup, f.FormType, f.AllowAttachments 
from vDDFHSecurable  f
LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = f.TitleID
LEFT OUTER JOIN dbo.DDCTShared c1 ON f.TitleID = c1.TextID
LEFT OUTER JOIN FormNames f1 ON c1.CultureText = f1.FormName
LEFT OUTER JOIN FormNames f2 ON f.Title = f2.FormName
cross join (select * from VADDFSUsersAndGroups)   g-- on f.SecurityGroup = g.SecurityGroup

cross join (Select * from Companies ) h

left join DDFS s on h.HQCo= s.Co and g.Name =ISNULL((SELECT [Name] FROM DDSG sg WHERE sg.[SecurityGroup] = s.[SecurityGroup]),s.[VPUserName] )  and f.Form = s.Form

--where f.Form = 'AP1099Edit'

WHERE h.HQCo IN (SELECT Company FROM vfCoTableFromArray(@CoArray)) AND f.Mod IN (SELECT Names FROM vfTableFromArray(@ModArray))

AND (f2.FormName IS NOT NULL OR f1.FormName IS NOT NULL)

Order by g.SecurityGroup,h.HQCo

END 


GO
GRANT EXECUTE ON  [dbo].[vspVADDFSFormRefresh] TO [public]
GO
