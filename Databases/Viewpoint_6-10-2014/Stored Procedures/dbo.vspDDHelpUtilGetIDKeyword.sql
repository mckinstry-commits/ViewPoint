SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspDDHelpUtilGetIDKeyword]
/********************************
* Created: MJ 02/02/04  
* Modified: AMR - TK-08834 - removing bDDFI
*
* Used to retrieve the previous 5.x Help ID
* as well as the 6.x Help Keyword 
*
* Input:
*	@form		current form name
*	@seq		current form name
*
* Output:
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30), @seq varchar(4), @errmsg varchar(60) output)
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0

-- get Keyword from vDDFI
SELECT HelpKeyword from vDDFI where Form = @form and Seq = @seq


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDHelpUtilGetIDKeyword] TO [public]
GO
