SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspSMEquipValRates]

/***********************************************************
* CREATED BY: Eric V 07/21/2011
* MODIFIED By : 
*	
* USAGE:
*	Validates EMEM.Equipment and returns flags needed for SM Rate Overrides
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
*
* OUTPUT PARAMETERS
*	ret val		EMEM column
*	-------		-----------
*	@category	Category
*	@revcode	RevenueCode
*	@errmsg		Description or Error msg if error
**********************************************************/
   
(@emco bCompany,
@equip bEquip,
@category bCat = null output,
@revcode bRevCode = null output,
@errmsg varchar(255) output)

as
set nocount on
declare @rcode int, @msg varchar(60)
select @rcode = 0
   
if @emco is null
	begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto bspexit
	end

if @equip is null
	begin
	select @errmsg = 'Missing Equipment!', @rcode = 1
	goto bspexit
	end

/* validate equipment and retrieve emem flags */
exec @rcode = dbo.bspEMEquipVal @emco, @equip, @msg=@errmsg output
if @rcode <> 0 goto bspexit

select @revcode = RevenueCode, @category=Category
from EMEM with (nolock)
where EMCo = @emco and Equipment = @equip

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSMEquipValRates] TO [public]
GO
