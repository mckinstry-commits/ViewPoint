SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDSLSecure]
/**************************************************
* Created:	??
* Modified:	DANF 3/16/2005 - #26761 top 100 percent, order by
*			DANF 06/30/2005 - Remove Fix #26761 taking out top 100 percent and order by.
*			GG 01/19/06 - VP6.0 - use vDD tables
*			JRK 11/20/06 - use vDDSLc rather than vDDSL so we have access to InUse.
*
*	Used by:	VA Secure Data and Datatypes
***************************************************/
as
SELECT  s.*, 
	case substring(s.TableName,1,3) when 'bud' then u.Description else  a.Description end AS Description
FROM  dbo.vDDSLc s with (nolock)
LEFT OUTER JOIN dbo.vDDTH a with (nolock) ON a.TableName = SUBSTRING(s.TableName, 2, LEN(a.TableName))
LEFT OUTER JOIN dbo.bUDTH u with (nolock) ON u.TableName = SUBSTRING(s.TableName, 2, LEN(u.TableName))

GO
GRANT SELECT ON  [dbo].[DDSLSecure] TO [public]
GRANT INSERT ON  [dbo].[DDSLSecure] TO [public]
GRANT DELETE ON  [dbo].[DDSLSecure] TO [public]
GRANT UPDATE ON  [dbo].[DDSLSecure] TO [public]
GRANT SELECT ON  [dbo].[DDSLSecure] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDSLSecure] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDSLSecure] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDSLSecure] TO [Viewpoint]
GO
