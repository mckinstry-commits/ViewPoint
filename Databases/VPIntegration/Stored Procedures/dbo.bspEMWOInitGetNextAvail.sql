SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                proc [dbo].[bspEMWOInitGetNextAvail]
/********************************************************
* CREATED BY: 	JM 11/18/98
* MODIFIED BY: JM 12/7/98 - Changed '= null' to 'is null'.
*	JM 10/23/01 - Modified code that pulls next avail from EMSX or EMCO to work only
*	under AutoSeq; modified logic
*	JM 2-12-02 Corrected reference to EMSX to include ShopGroup in key.
* TV 07/05/03 - clean this up and Issue 22059
* TV 12/08/03 23208 - Problems with Justification.
* TV 1/12/04 23479 - Justify WO probs with Shop.
* TV 02/11/04 - 23061 added isnulls 
* TV 08/16/04 - 25354 needed to incriment by 1
* TRL 11/14/08 Issue 131082 changed WO formatting to vspEMFormatWO from bfJustifyStringToDatatype
* TRL 03/10/08 Issue 131745, fixed getting next available work order when auto seq = no
* TRL 08/03/09 Issue 133975 added parameters to validatie shop/wo
* USAGE:
* 	Returns the next available numeric WorkOrder for an EMCo from a starting WorkOrder.
*
* INPUT PARAMETERS:
*   EM Company
*   Equipment
*   Starting WO
*   Autoseq
*   AutoOpt
*   OverrideShop
*
* OUTPUT PARAMETERS:
*	Next Available WO
*	Error Message, if one
*
* RETURN VALUE:
* 	0	Success
*	1 	Failure
*********************************************************/
(@emco bCompany = 0, 
@equip bEquip = null, 
@startingwo bWO, 
@autoseq char(1) = null, 
@autoopt char(1) = null,
@overrideshop varchar(20) = null,
@nextavailwo bWO output,
@errmsg varchar(255) output)
   
as
  
set nocount on
   
declare @i int, @rcode tinyint, @shop varchar(20), @shopgroup bGroup
   
select @rcode = 0, @i = 1
   
--Verify required parameters passed. 
if @emco is null
begin
  	select @errmsg = 'Missing EM Co!', @rcode = 2
 	goto bspexit
end
if IsNull(@equip,'') = ''
begin
   	select @errmsg = 'Missing Equipment!', @rcode = 2
   	goto bspexit
end
if IsNull(@autoseq,'')=''
begin
   	select @errmsg = 'Missing AutoSeq!', @rcode = 2
	goto bspexit
end
   
--Get ShopGroup from bHQCO for @emco 
select @shopgroup = ShopGroup from dbo.HQCO with(nolock) where HQCo = @emco
   
--Need to get shop from EMEM when override shop is null TV 1/12/04 23479
select @shop = isnull(@overrideshop,(select Shop from dbo.EMEM with(nolock) where EMCo = @emco and Equipment = @equip))
   
-- Override passed @startingwo for Co-based AutoSeq 
if @autoseq = 'Y' and @autoopt = 'E' --by Company
begin
   	select @startingwo = IsNull(LastWorkOrder,'0')  from dbo.EMCO with(nolock) where EMCo = @emco --25354

	/*131082 and 133975*/
	exec @rcode = dbo.vspEMWOGetNextAvailable @emco, @autoseq, @autoopt, @shopgroup,@shop, @startingwo output, @errmsg output
	If @rcode = 1
	begin
		goto bspexit
	end
end 
 
--Override passed @startingwo for Shop-based AutoSeq 
if @autoseq = 'Y' and @autoopt = 'C' --by Shop
begin
	select @startingwo = IsNull(LastWorkOrder,'0')  --25354
    from dbo.EMSX with(nolock)
    where ShopGroup = @shopgroup and Shop = @shop

	/*131082 and 133975*/
	exec @rcode = dbo.vspEMWOGetNextAvailable @emco, @autoseq, @autoopt, @shopgroup,@shop, @startingwo output, @errmsg output
	If @rcode = 1
	begin
		goto bspexit
	end
end

/*Issue 131745*/
if @autoseq = 'N'
begin
	/*131082 and 133975*/
	exec @rcode = dbo.vspEMWOGetNextAvailable @emco, @autoseq, @autoopt, @shopgroup,@shop, @startingwo output, @errmsg output
	If @rcode = 1
	begin
		goto bspexit
	end
end

select @nextavailwo = @startingwo   

--If no WO to be returned, return error. Otherwise, update LastWorkOrder in bEMCO or bEMSX if AutoSeq 
if IsNull(@nextavailwo,'')=''
begin
   	select @rcode = 1, @errmsg = 'Error getting next available Work Order.'
   	goto bspexit
end
   
--update proper fields for last WO used..	
If @autoseq = 'Y' and @autoopt = 'E'
begin
	update dbo.EMCO
	set LastWorkOrder =  @nextavailwo 
	where EMCo = @emco
end

If @autoseq = 'Y' and @autoopt = 'C'
begin
	update dbo.EMSX
	set LastWorkOrder =  @nextavailwo 
	where Shop = @shop and ShopGroup = @shopgroup 
end

bspexit:
If @rcode<>0 
begin
	select @errmsg= isnull(@errmsg,'')
end

return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMWOInitGetNextAvail] TO [public]
GO
