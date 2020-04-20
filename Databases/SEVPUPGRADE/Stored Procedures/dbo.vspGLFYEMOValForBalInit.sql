SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspGLFYEMOValForBalInit]
/**************************************************************
* Created: GG 02/17/06
* Modified:
*
* Validates a month as a Fiscal Year Ending Month for a
* given GL Co#. Used by GL Beginning Balance Init
*
* Input:
*	@glco		GL Company #
*	@mth		Month
*
* Output:
*	@pfyemo		Prior fiscal year ending month
*	@errmsg		Error message 
*
* Return code:
*	0 = success, 1 = error
*
***************************************************************/
   
   	(@glco bCompany = 0, @mth bMonth = null, @pfyemo bMonth output, @errmsg varchar(255) output)
as

set nocount on
declare @rcode int
select @rcode = 0, @pfyemo = null
   
if @glco = 0
	begin
	select @errmsg = 'Missing GL Company!', @rcode = 1
	goto vspexit
	end
if @mth is null
	begin
	select @errmsg = 'Missing Month!', @rcode = 1
	goto vspexit
	end
-- validate month as Fiscal Year Ending Month   
if (select count(*) from GLFY (nolock) where GLCo = @glco and FYEMO = @mth) = 0
   	begin
   	select @errmsg = 'This month is not a valid Fiscal Year Ending month!', @rcode = 1
	goto vspexit
   	end
-- get prior Fiscal Year 
select @pfyemo = max(FYEMO)
from GLFY (nolock)
where GLCo = @glco and FYEMO < @mth
if @pfyemo is null
	begin
   	select @errmsg = 'No prior Fiscal Year exists - will not be able to initialize!', @rcode = 1
   	goto vspexit
   	end
   
vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspGLFYEMOValForBalInit] TO [public]
GO
