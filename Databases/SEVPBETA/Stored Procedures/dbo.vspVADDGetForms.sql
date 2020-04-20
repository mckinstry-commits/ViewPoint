SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspVADDGetForms]
/********************************
* Created: 	MJ 9/26/05
* Modified:		CC	07/09/09 - #129922 - Added link for form header to culture text
*
* Used to return all forms
*
* Input:
*	

* Output:
*	
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
@culture INT = NULL	
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0


select Form, ISNULL(CultureText.CultureText, DDFHShared.Title) AS Title, FormClassName, AssemblyName 
from DDFHShared
LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = DDFHShared.TitleID

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDGetForms] TO [public]
GO
