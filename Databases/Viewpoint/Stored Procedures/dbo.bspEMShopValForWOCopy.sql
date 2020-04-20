SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMShopValForWOCopy]
/***********************************************************
* CREATED BY: JM 2/27/02
* MODIFIED By : TV 02/11/04 - 23061 added isnulls
*				TRL 04/29/08 Issue 122308 when last work order has no value, return 0
*				TRL 11/14/08 Issue 131082 added vspEMWOGetNextAvailable (Gets next Available WO and foramts WO)
*				TRL 08/03/09 Issue 133956 updated procedure to validate Shop/Work Order by EMCo
*               ECV 06/01/10 Issue 139788 Variable @msg was being reused when vspEMWOGetNextAvailable was called
*                            and loosing the value of Description from EMSX. Created new variable @msg2.
*
* USAGE:
*	Validates Shop
*	Returns Shop Desc
*		Next WO from EMSX if @shopopt = 'S' for Specified Shop
*
* INPUT PARAMETERS
*	@shop		Shop from EMEM
*	@shopopt	'W' for Copy From WO Shop, 'E' for Copy To Equip Shop or 'S' for specified Shop
*
* OUTPUT PARAMETERS
*	@NextWO	Next avail WO
*	@msg 		error or Description
*
* RETURN VALUE
*	0 success
*	1 error
    ***********************************************************/
(@emco bCompany, @shop varchar(20) = null, @shopopt char(1), @NextWO bWO output, @msg varchar(60) output)
   
as
   
set nocount on
   
declare @rcode int,@shopgroup bGroup,@autoseqYN bYN, @autoseqopt varchar(1)
   	 
select @rcode = 0

/*133975*/
select @shopgroup = HQCO.ShopGroup, @autoseqYN=WOAutoSeq, @autoseqopt =WorkOrderOption 
from dbo.EMCO with(nolock) 
inner join dbo.HQCO with(nolock)on HQCO.HQCo=EMCO.EMCo
where EMCo=@emco

If @shopgroup = null
begin
	select @msg='Missing EM Shop Group!',@rcode = 1
end

select @msg = Description  from dbo.EMSX with(nolock) where Shop = @shop and ShopGroup=@shopgroup
if @@rowcount = 0
begin
	select @msg = 'Not a valid Shop', @rcode = 1
	goto bspexit
end

/*Issue 122308*/
select @NextWO = Isnull(LastWorkOrder,0) from dbo.EMSX with(nolock) 
where ShopGroup = @shopgroup and Shop = @shop 

/*Issue 131082 Formats and verifies and/or gets next available Work Order number*/
/*Issue 133975 Add prameters to valid Shop and WO*/
/*Issue 139788 Add new parameter @msg2 for calling vspEMWOGetNextAvailable */
DECLARE @msg2 varchar(60)

exec @rcode = dbo.vspEMWOGetNextAvailable @emco, @autoseqYN, @autoseqopt, @shopgroup, @shop,@NextWO output, @msg2 output 
If @rcode = 1
begin
	/*Issue 139788 If vspEMWOGetNextAvailable results in error then set @msg to error message in @msg2 */
	select @msg = @msg2
	goto bspexit
end   
  
bspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMShopValForWOCopy] TO [public]
GO
