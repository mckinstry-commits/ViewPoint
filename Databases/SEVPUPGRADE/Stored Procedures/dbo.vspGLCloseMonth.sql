SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspGLCloseMonth]
/***********************************************************
* Created: GG 08/04/06
* Modified: GG 02/22/08 - #120107 - separate subledger close
*
* Usage:
*   Called by GL Close Month form to update the last month closed in GL Company 
*	
*   Returns success, or error if test fails
*
* INPUT PARAMETERS
*   @glco			GL Company 
*	@legder			'Sub' = subledgers, 'General' = general ledger
*	@mth			Closed month
*	@apclose		Closing AP - Y/N
*	@arclose		Closing AR - Y/N
*	@subclose		Closing all other subledgers - Y/N
*
* OUTPUT PARAMETERS
*	@errmsg				error message
*
* RETURN VALUE
*   0 - success
*   1 - error
*****************************************************/
  	(@glco bCompany = null, @ledger varchar(8) = null, @mth bMonth = null, 
  	@apclose bYN = 'N', @arclose bYN = 'N', @subclose bYN = 'N', @errmsg varchar(255) output)
as
set nocount on
  
declare @rcode int
select @rcode = 0

if @glco is null
	begin
	select @errmsg = 'Missing GL Company#', @rcode = 1
	goto vspexit
	end
if @ledger is null or @ledger not in ('Sub','General') 
	begin
	select @errmsg = 'Invalid ledger designation, must be Sub or General!', @rcode = 1
	goto vspexit
	end
if @mth is null
	begin
	select @errmsg = 'Missing month!', @rcode = 1
	goto vspexit
	end
if @subclose = 'Y' and (@apclose = 'N' or @arclose = 'N') 
	begin
	select @errmsg = 'Must close AP and AR when closing other Sub Ledgers!', @rcode = 1
	goto vspexit
	end

-- update GLCO with last closed month
update bGLCO
set LastMthAPClsd = case when @ledger = 'Sub' and @apclose = 'Y' then @mth else LastMthAPClsd end,
	LastMthARClsd = case when @ledger = 'Sub' and @arclose = 'Y' then @mth else LastMthARClsd end,
	LastMthSubClsd = case when @ledger = 'Sub' and @subclose = 'Y' then @mth else LastMthSubClsd end,
	LastMthGLClsd = case when @ledger = 'General' then @mth else LastMthGLClsd end
where GLCo = @glco
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to update last month closed in GL Company.', @rcode = 1
	goto vspexit
	end

vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspGLCloseMonth] TO [public]
GO
