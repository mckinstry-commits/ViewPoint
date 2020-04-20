SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspDDMenuItemVal]      
/***************************************      
* Created: GG 10/31/06      
* Modified:       
*   CC 07/14/09 - #129922 - Added link for form header to culture text  
*   Dave C 2/11/2010 - #137676 - Changed the vRPRT to RPRTShared to allow custom reports to be validated.  
*	Dave C 4/2/2010 - #138077 - Changed vDDFH to DDFHShared to allow custom forms to be validated.
*      
* Used to validate a Menu Item as either a standard      
* form or report.      
*      
* Inputs:      
* @itemtype  F = form, R = report id#      
* @menuitem  form or report id#      
*      
* Output:      
* @msg   form or report title, or error message      
*      
* Return code:      
* 0 = success, 1 = failure      
*      
**************************************/      
( @itemtype char(1) = null,       
 @menuitem varchar(30) = null,       
 @culture INT = NULL,      
 @msg varchar(60) = null output)      
        
as      
set nocount on      
        
declare @rcode int      
select @rcode = 0      
        
if @itemtype is null or @itemtype not in ('F','R') -- must be Form or Report      
 begin      
   select @msg = 'Invalid Item Type, must be ''F'' or ''R''.', @rcode = 1      
   goto vspexit      
   end      
if @itemtype = 'F'      
 begin      
 select @msg = ISNULL(CultureText.CultureText, d.Title)      
 from DDFHShared d
 LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = d.TitleID      
 where Form = @menuitem      
 if @@rowcount = 0      
  begin      
  select @msg = 'Invalid Form.', @rcode = 1      
  goto vspexit      
  end      
 end      
if @itemtype = 'R'      
 begin      
 select @msg = Title from dbo.RPRTShared where convert(varchar,ReportID) = @menuitem      
 if @@rowcount = 0      
  begin      
  select @msg = 'Invalid Report ID#.', @rcode = 1      
  goto vspexit      
  end      
 end      
      
vspexit:      
   return @rcode 
GO
GRANT EXECUTE ON  [dbo].[vspDDMenuItemVal] TO [public]
GO
