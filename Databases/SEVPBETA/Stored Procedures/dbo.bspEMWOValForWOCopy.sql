SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         proc [dbo].[bspEMWOValForWOCopy]
/***********************************************************
* CREATED BY: JM 2/27/02
* 		TV 2/3/04 23410 - We do not need to format the data types
*		TV 02/11/04 - 23061 added isnulls 
*		TRL 04/29/08 122308 - Return 0 when LastWorkOrder has no value
*		GP	07/24/08 129128 - Fixed validation check for null @shop to return error message to @msg
*		TRL 11/14/08 Issue 131082 added vspEMWOGetNextAvailable (Gets next Available WO and foramts WO)
*		TRL 08/03/09 Issue 133957 updated procedure to validate Shop/Work Order by EMCo
*
* USAGE:
* 	Basic validation of EM WorkOrder vs bEMWH
*	Returns WO Desc
*		EMWH.Shop 
*		EMSX.Description if avali or msg
*		Next WO from EMSX if @shopopt = 'W' for Copy From WO Shop
*
* 	Error returned if any of the following occurs:
* 		No EMCo passed
*		No WorkOrder passed
*		WorkOrder not found in EMWH
*
* INPUT PARAMETERS:
*	EMCo   		EMCo to validate against
* 	WorkOrder 	WorkOrder to validate
*	ShopOpt	'W' for Copy From WO Shop, 'E' for Copy To Equip Shop or 'S' for specified Shop
*	WOIn		WO defaulted on form load if AutoSeq = Y
*
* OUTPUT PARAMETERS:
*	@shop		Shop from EMWH
*	@shopdesc	Description from EMSX or 'No shop assigned for this WO'
*	@nextwo	Next avail WO
*	@msg      	Error message if error occurs, otherwise Description of WorkOrder from EMWH
*
* RETURN VALUE:
*	0		success
*	1		Failure
*****************************************************/
(@emco bCompany = null,@workorder bWO = null, @shopopt char(1) = null,@woin bWO = null,
@shop varchar(20) output,@shopdesc varchar(30) output,@NextWO bWO output,@errmsg varchar(255) output)
    
as

set nocount on
    
declare @rcode int, @shopgroup tinyint, @LastWO bWO,@NextWOSave bWO,
/*Issue 133975*/@autoseqYN bYN, @autoseqopt varchar(1),
@NumLeadingSpaces tinyint,@NumLeadingZeros tinyint,
@sp tinyint,/*@WOFormatOption char(1)/*R or L from DDDT */,*/@x tinyint
    
select @rcode = 0
    
if @emco is null
begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
    goto bspexit
end

if IsNull(@workorder,'') = ''
begin
	select @errmsg = 'Missing Work Order!', @rcode = 1
    goto bspexit
end

if Isnull(@shopopt,'')= ''
begin
	select @errmsg = 'Missing Shop Option!', @rcode = 1
    goto bspexit
end

/*Issue 133975*/
select @shopgroup = HQCO.ShopGroup, @autoseqYN=isnull(EMCO.WOAutoSeq,'N'), @autoseqopt =isnull(EMCO.WorkOrderOption,'')
from dbo.HQCO 
Inner join dbo.EMCO with(nolock)on EMCO.EMCo = HQCO.HQCo 
where HQCo = @emco

if @shopgroup is null
begin
	select @errmsg = 'Missing EM Shop Group!', @rcode = 1
    goto bspexit
end

select @errmsg = Description, @shop = Shop 
from dbo.EMWH with(nolock)
where EMCo = @emco and WorkOrder = @workorder
if @@rowcount = 0
begin
	select @errmsg = 'Work Order not on file!', @rcode = 1
    goto bspexit
end
--Copy To Equipment Shop within Range    
if @shopopt = 'E' or @shopopt = 'S'
begin
	select @NextWO = ''
end

--Copy From Work OrderShop
if @shopopt = 'W'
begin
	if IsNull(@shop,'') = ''
	begin
		select @errmsg = 'No Shop assigned to this Work Order!', @rcode = 1
		goto bspexit
	end
   	/* Get Work Order formatting from DDDT - if R then need to pad incremented WO's with appropriate number
   	of spaces to replicate bWO format. 
   	select @WOFormatOption = InputMask from DDDT where Datatype = 'bWO'*/
    /* Issue 122308*/
   	select @shopdesc = Description, @NextWO = IsNull(LastWorkOrder,'0')
	from dbo.EMSX  with(nolock)
   	where ShopGroup = @shopgroup and Shop = @shop
    
	/*Issue 131082 Formats and verifies and/or gets next available Work Order number*/
	/*Issue 133975 Add prameters to valid Shop and WO*/
	exec @rcode = dbo.vspEMWOGetNextAvailable @emco,  @autoseqYN, @autoseqopt,@shopgroup,@shop, @NextWO output, @errmsg output
	If @rcode = 1
	begin
		goto bspexit
	end   
end
   
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOValForWOCopy] TO [public]
GO
