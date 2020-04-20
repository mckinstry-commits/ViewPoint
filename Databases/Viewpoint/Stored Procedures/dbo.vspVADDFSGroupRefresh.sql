SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Aaron Lang, vspVADDFSGroupRefresh>
--				CC	07/14/09 - #129922 - Added link for form header to culture text
--				Matt Pement 11/30/09 - #136176 - Change to return a list based on SecurityGroup Ids
-- Create date: <6/1/07>
-- Description:	Returns group security records that do and do 
--				not exist for Form Security.
--				
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDFSGroupRefresh]


(@NameArray VARCHAR(8000),@ModArray VARCHAR(8000), @CoArray VARCHAR(8000), @culture INT = NULL) 

	-- Add the parameters for the stored procedure here
AS
Begin

Select f.Mod, h.HQCo AS Co, g.[Name], ISNULL(CultureText.CultureText, f.Title) AS Title, f.Form, ISNULL(s.[Access], 3) AS Access , ISNULL(s.[RecAdd], 'N') AS RecAdd, ISNULL(s.[RecUpdate], 'N') AS RecUpdate,

ISNULL(s.[RecDelete], 'N') AS RecDelete, ISNULL(s.AttachmentSecurityLevel, 3) AS Attachments, g.SecurityGroup, f.FormType, f.AllowAttachments 
from vDDFHSecurable  f
LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = f.TitleID
cross join (select * from DDSG where GroupType = 1)   g-- on f.SecurityGroup = g.SecurityGroup

cross join (Select * from Companies ) h

left join DDFS s on h.HQCo= s.Co and g.SecurityGroup =s.SecurityGroup and f.Form = s.Form

--where f.Form = 'AP1099Edit'

WHERE h.HQCo IN (SELECT Company FROM vfCoTableFromArray(@CoArray)) AND f.Mod IN (SELECT Names FROM vfTableFromArray(@ModArray))

AND  g.[SecurityGroup] IN (SELECT CAST(Names as int) FROM vfTableFromArray(@NameArray))

Order by g.SecurityGroup,h.HQCo, f.Title

END 



GO
GRANT EXECUTE ON  [dbo].[vspVADDFSGroupRefresh] TO [public]
GO
