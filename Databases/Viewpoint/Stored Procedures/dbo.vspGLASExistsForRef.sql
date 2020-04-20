SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspGLASExistsForRef]
/**************************************************************
* Created: GG 4/9/07 
* Modified:
*
* Determines whether a GL Journal Reference has Account Summary entries.
* Used by GL Journal Reference maintenance form.
*
* Inputs:
*	@glco			GL Company
*	@mth			Month
*	@jrnl			Journal
*	@glref			GL Reference
*
* Output:
*	@GLASexists		Y = Acct Summary entries exists for GL Jrnl Ref, N = no entries exist
*	@msg		error message
*
* Return code:
*	0 = success, 1 = error
*
***************************************************************/
	(@glco bCompany = 0, @mth bMonth = null, @jrnl bJrnl = null, @glref bGLRef = null,
	 @GLASexists bYN output, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0, @GLASexists = 'N'

if @glco = 0
	begin
	select @msg = 'Missing GL Company!', @rcode = 1
	goto vspexit
	end
if @mth is null
	begin
	select @msg = 'Missing Month!', @rcode = 1
	goto vspexit
	end
if @jrnl is null
	begin
	select @msg = 'Missing Journal!', @rcode = 1
	goto vspexit
	end
if @glref is null
	begin
	select @msg = 'Missing GL Reference!', @rcode = 1
	goto vspexit
	end

if exists(select top 1 1 from dbo.bGLAS (nolock) where GLCo = @glco and Mth = @mth
			and Jrnl = @jrnl and GLRef = @glref)
	begin
	select @GLASexists = 'Y'
	end

vspexit:
	return @rcode




grant EXECUTE on [vspGLASExistsForRef] to public

GO
GRANT EXECUTE ON  [dbo].[vspGLASExistsForRef] TO [public]
GO
