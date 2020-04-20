SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMWOCopyCheckShop]
/*******************************************************************
* CREATED: 3/11/02 JM
* LAST MODIFIED:	TV 02/11/04 - 23061 added isnulls 
*				TRL 11/14/08 Issue 131082 added vspEMWOGetNextAvailable (Gets next Available WO and foramts WO)
*
* USAGE:  Checks a range of Equipment to verify assigned Shop and that Shop has LastWorkOrder.
*
* INPUT PARAMS:
*	@emco				Form EMCo
*	@copytoequip		Equipment form equipment to copy grid
*	@shopoption			Copy Work ORder Option
*						'W' Work Order, 'E' Assigned Equipment Shop(EMEM),'S' Specified Ship
*	@allowautoseq		AllowAutoSeq from EM Company parameters 'Y'/'N'
*	@autoseqmethod		LastWorkOrderOption from EM Company Parameters
*						'E' Company, 'C' Shop
*	@sourceworkorder
*
* OUTPUT PARAMS:
*	@rcode		Return code; 0 = success, 1 = failure
*	@errmsg		Error message; # copied if success, error message if failure
********************************************************************/
(@emco bCompany = null,@copytoequip bEquip = null,  @copytoequipshop varchar(20),@shopoption varchar(1) = null,
@allowautoseq varchar(1) = null, @autoseqmethod varchar(1) = null,@sourceworkorder bEquip = null,
@othershop varchar(20),@lastworkorder varchar(10)output,@errmsg varchar(255) output)
   
as
   
set nocount on
   
/* Initialize general local variables. */
declare @rcode int,@shopgroup bGroup,@sourceworkordershop varchar(20)
   
select @rcode = 0
   
/* Verify necessary parameters passed. */
if @emco is null
begin
   	select @errmsg = 'Missing EM Company!', @rcode = 1
   	goto vspexit
end

if IsNull(@copytoequip,'') = ''
begin
   	select @errmsg = 'Missing Copy To Equipment!', @rcode = 1
   	goto vspexit
end

/* Get ShopGroup from HQCO for this @emco */
select @shopgroup = ShopGroup from dbo.HQCO with(nolock) where HQCo = @emco   

If @allowautoseq = 'Y' and @autoseqmethod = 'C'
begin
	
	--Assigned Shop from EM Equipment (EMEM)
	If @shopoption = 'E'
	begin
		If IsNull(@copytoequipshop,'') = ''
		begin
			Select @errmsg = 'Equipment: ' + @copytoequip + ' has no assigned Shop',@rcode = 2
			goto vspexit
		end
		If not exists (select top 1 1 from dbo.EMSX with(nolock)
			Where ShopGroup=@shopgroup and Shop = @copytoequipshop)
		begin
			Select @errmsg= 'Equipment: ' + IsNull(@copytoequip,'') +' invalid assigned Shop: '+ @copytoequipshop ,@rcode = 1
			goto vspexit
		end
		
		select @lastworkorder = LastWorkOrder from dbo.EMSX with(nolock)
		Where ShopGroup=@shopgroup and Shop = @copytoequipshop

		If IsNull(@lastworkorder,'') = ''
		begin
			select @errmsg = 'Equipment: ' + @copytoequip +
		    ' assigned Shop: '+ IsNull(@copytoequipshop,'') + ' has no value for Last Work Order',@rcode = 3
		end
	end
	
	--Source Work Order Shop
	If @shopoption = 'W'
	begin
		if IsNull(@sourceworkorder,'')=''
		begin
   			select @errmsg = 'Missing Source Work Order!', @rcode = 1
   			goto vspexit
		end

		/* Get Equipment for CopyFromWO so that it can be excluded from any range inserted into #TargetEquip. */
		select @sourceworkordershop=IsNull(Shop,'')
		from dbo.EMWH with(nolock)
		where EMCo = @emco and WorkOrder = @sourceworkorder

		If not exists (select top 1 1 from dbo.EMSX with(nolock)
			Where ShopGroup=@shopgroup and Shop = IsNull(@sourceworkordershop,''))
		begin
			Select @errmsg= 'Source Work Order Shop: ' +  IsNull(@sourceworkordershop,'') +' has an invalid Shop',@rcode = 1
			goto vspexit
		end

		select @lastworkorder = LastWorkOrder from dbo.EMSX with(nolock)
		Where ShopGroup=@shopgroup and Shop = @sourceworkordershop

		If IsNull(@lastworkorder,'') = ''
		begin
			select @errmsg = 'Source Work Order Shop: '+ IsNull(@sourceworkordershop,'') + ' has no value for Last Work Order',@rcode = 3
		end
	end

	--Specified Shop
	If @shopoption = 'S'
	begin
		if IsNull(@othershop,'')=''
		begin
   			select @errmsg = 'Missing Other Shop!', @rcode = 1
   			goto vspexit
		end

		select @lastworkorder = LastWorkOrder from dbo.EMSX with(nolock)
		Where ShopGroup=@shopgroup and Shop = @othershop

		If IsNull(@lastworkorder,'') = ''
		begin
			select @errmsg = 'Other Shop: '+ IsNull(@othershop,'') + ' has no value for Last Work Order',@rcode = 3
		end
	end
end  

	--Check and/or re-format Work Order based on DDDTShared
If IsNull(@sourceworkorder,'') <> ''
begin
	exec @rcode = dbo.vspEMFormatWO @sourceworkorder output, @errmsg output
	If @rcode = 1
	begin
		goto vspexit
	end   
end

If IsNull(@lastworkorder,'') <> ''
begin
	exec @rcode = dbo.vspEMFormatWO @lastworkorder output, @errmsg output
	If @rcode = 1
	begin
		goto vspexit
	end   
end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOCopyCheckShop] TO [public]
GO
