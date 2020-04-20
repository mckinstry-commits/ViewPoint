SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspGLCOInfoGet]
/***********************************************************
* Created: GG 02/24/06
* Modified: GG 02/20/08 - #120107 - added params @lastmthapclsd and @lastmtharclsd
*
* Usage:
*   Called by multiple GL forms to retrieve GL Company parameters
*	
*   Returns success, or error if test fails
*
* INPUT PARAMETERS
*   @glco			GL Company 
*
* OUTPUT PARAMETERS
*	@lastmthsubclsd		Last month other subledgers closed
*	@lastmthglclsd		Last month GL closed
*	@maxopen			Maximum # of open months
*	@cashaccrual		CashAccrual flag - C=Cash, A=Accrual
*	@xcompjrnlentry		Cross Company Journal Entry flag
*	@lastmthapclsd		Last month AP closed
*	@lastmtharclsd		Last month AR closed
*	@errmsg				error message
*
* RETURN VALUE
*   0 - success
*   1 - error
*****************************************************/
  	(@glco bCompany = null, @lastmthsubclsd bMonth output, @lastmthglclsd bMonth output, 
	@maxopen tinyint output, @cashaccrual char(1) output, @xcompjrnlentry bYN output,
	@lastmthapclsd bMonth output, @lastmtharclsd bMonth output, @errmsg varchar(255) output)
as
set nocount on
  
declare @rcode int
select @rcode = 0

select @lastmthsubclsd = LastMthSubClsd, @lastmthglclsd = LastMthGLClsd, @maxopen = MaxOpen, 
	@cashaccrual = CashAccrual, @xcompjrnlentry = XCompJrnlEntryYN, @lastmthapclsd = LastMthAPClsd,
	@lastmtharclsd = LastMthARClsd
from dbo.bGLCO (nolock)
where GLCo = @glco
if @@rowcount = 0
  	begin
  	select @errmsg = 'GL Company#:' + convert(varchar,@glco) + ' not setup!', @rcode = 1
  	end

vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspGLCOInfoGet] TO [public]
GO
