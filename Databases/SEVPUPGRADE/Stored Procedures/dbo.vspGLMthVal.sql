SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspGLMthVal]
/**************************************************************
* Created: GG 4/9/07 
* Modified:
*
* Determines whether month is a fiscal year.  Used by GL Journal Reference
* maintenance form.
*
* Inputs:
*	@glco		GL Company
*	@mth		Month
*
* Output:
*	@FYEMOyn	Y = month is a fiscal year end, N = not a FYEMO
*	@msg		error message
*
* Return code:
*	0 = success, 1 = error
*
***************************************************************/
(@glco bCompany = 0, @mth bMonth = null, @FYEMOyn bYN output, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0, @FYEMOyn = 'N'

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

if exists(select top 1 1 from dbo.bGLFY (nolock) where GLCo = @glco and FYEMO = @mth)
	begin
	select @FYEMOyn = 'Y'
	end

vspexit:
	return @rcode




grant EXECUTE on vspGLMthVal to public

GO
GRANT EXECUTE ON  [dbo].[vspGLMthVal] TO [public]
GO
