SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspARGetGLLastMthSubClsdOnLoad]
/******************************************************
* Created: TJL	07/01/05
* Modified:	TJL 07/24/07 - Add check for Menu Company (HQCo) in AR Module Company Master
*			GG 02/25/08 - #120107 - separate sub ledger close, use last mth AR closed
*
*
* Gets month last month AR closed.  Called by AR Purge forms
*
* returns 0 if successful, 1 and error msg if error
*******************************************************/
(@arco bCompany, @glco bCompany output, @custgroup bGroup output, @taxgroup bGroup output, 
	@matlgroup bGroup output, @lastmthsubclsd bMonth output, @msg varchar(60) output)
as 
set nocount on
declare @rcode int

select @rcode = 0
  	
if @arco is null
	begin
	select @msg = 'Missing AR Company.', @rcode = 1
	goto vspexit
	end
else
	begin
	select top 1 1 
	from dbo.ARCO with (nolock)
	where ARCo = @arco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@arco) + ' not setup in AR.', @rcode = 1
		goto vspexit
		end
	end

/* Get AR Form Load information */
select @glco = a.GLCo, @custgroup = h.CustGroup, @taxgroup = h.TaxGroup,
	@matlgroup = h.MatlGroup
from bARCO a with (nolock)
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where a.ARCo = @arco and h.HQCo = @arco
if @@rowcount = 0
	begin
	select @msg = 'Error getting AR Common information.', @rcode = 1
	goto vspexit
	end

/* Get LastMthSubClsd */
select @lastmthsubclsd = LastMthARClsd	-- #120107 use AR close month
from bGLCO with (nolock)
where GLCo = @glco
if @@rowcount = 0
	begin
	select @msg = 'Not a valid GL Company.', @rcode = 1
	goto vspexit
	end
  
vspexit:
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[vspARGetGLLastMthSubClsdOnLoad]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARGetGLLastMthSubClsdOnLoad] TO [public]
GO
