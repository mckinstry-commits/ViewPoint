SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		<Aaron Lang, vspVADDFSUserRefresh2>
	Modified:
				CC	07/14/09 - #129922 - Added link for form header to culture text
-- Create date: <6/1/07>
-- Description:	Returns user security records that do and do 
--				not exist for Form Security.
-- =============================================
*/
CREATE PROCEDURE [dbo].[vspVADDFSUserRefresh2]

(@NameArray VARCHAR(max),@ModArray VARCHAR(8000), @CoArray VARCHAR(8000), @culture INT = NULL) 

	-- Add the parameters for the stored procedure here
AS
Begin

Select f.Mod, h.HQCo AS Co, u.[VPUserName], ISNULL(CultureText.CultureText, f.Title) AS Title, f.Form, ISNULL(s.[Access], 3) AS Access , ISNULL(s.[RecAdd], 'N') AS RecAdd, ISNULL(s.[RecUpdate], 'N') AS RecUpdate, 

ISNULL(s.[RecDelete], 'N') AS RecDelete, ISNULL(s.AttachmentSecurityLevel, 3) AS Attachments, -1 AS SecurityGroup, f.[FormType], f.AllowAttachments 
from vDDFHSecurable  f

LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = f.TitleID
cross join (select * from DDUP)   u-- on f.SecurityGroup = g.SecurityGroup

cross join (Select * from Companies ) h

left join DDFS s on h.HQCo= s.Co and u.[VPUserName] =s.[VPUserName] and f.Form = s.Form

--where f.Form = 'AP1099Edit'

WHERE h.HQCo IN (SELECT Company FROM vfCoTableFromArray(@CoArray)) AND f.Mod IN (SELECT Names FROM vfTableFromArray(@ModArray))

AND  u.[VPUserName] IN (SELECT Names FROM vfTableFromArray(@NameArray))

Order by u.[VPUserName], h.HQCo, f.Title

end


GO
GRANT EXECUTE ON  [dbo].[vspVADDFSUserRefresh2] TO [public]
GO
