SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspEMShopVal    Script Date: 1/31/2007 9:31:36 AM ******/
CREATE   proc [dbo].[vspEMShopWOVal] 
/*************************************
* Validates EM Shop
*  modified 1/31/2007 TRL  return INCo
*		Modified: 11/26/01 RM Added Shop Group 
*		TV 02/11/04 - 23061 added isnulls
*		DC 04/29/04 - 20981 Added validation on @co and @shop
*
* Pass:
*	EM Shop
*
* Success returns:
*	0 and Description, InvLoc from bEMSX
*
* Error returns:
*	1 and error message
**************************************/
(@co bCompany, @autoseqYN bYN, @autoseqopt varchar(1), 
@shop varchar(20), @wo bWO, @errmsg varchar(256) output)
   
 as
 
 set nocount on
   
declare @rcode int,@shopgroup bGroup,@emco bCompany
   
select @rcode = 0
   
if @co is null
begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
end


if isnull(@autoseqYN,'N')= 'Y' and  isnull(@autoseqopt,'') = 'C' and isnull(@shop,'') <> ''
begin 
	--Get Shop Group
	select @shopgroup = ShopGroup from dbo.HQCO with (nolock) where HQCo = @co
	  
	 --Validate Shop
	if not exists (select top 1 1  from dbo.EMSX with (nolock)
	   where Shop = @shop and ShopGroup = @shopgroup)
	begin
		select @errmsg = 'Invalid EM Shop!', @rcode = 1
		goto vspexit
	end
	
	--Does shop and wo exit in another EM Company
	If exists (select top 1 1 from dbo.EMWH with(nolock) where ShopGroup = @shopgroup and Shop = @shop and WorkOrder = @wo)
	begin
		--Get first occurance of EM Company with Shop and WO
		select @emco = min(EMCo) from dbo.EMWH with(nolock) where ShopGroup = @shopgroup and Shop = @shop and WorkOrder = @wo 
		select @errmsg = 'Work Order:' + @wo + 'already exists for Shop:  ' + @shop + ' in EM Company: ' + convert(varchar,@emco) + '!', @rcode =1
		goto vspexit
	end
end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMShopWOVal] TO [public]
GO
