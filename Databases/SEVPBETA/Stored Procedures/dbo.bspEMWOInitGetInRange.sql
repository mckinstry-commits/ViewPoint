SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            proc [dbo].[bspEMWOInitGetInRange]
/********************************************************
* CREATED BY: 	JM 10/23/98
* MODIFIED BY: JM 11/16/98 - Rewrote to account for
*		component/parent equip relationship and
*		between a range of WorkOrders.
*		JM 12/7/98 - Changed '= null' to 'is null'.
*       JM 9/7/99 - Changed from returning max to the next
*           available with call to bspEMWOInitGetNextAvail
*	JM 10/23/01 - Added several params and code to allow selection for AutoSeq option
* 	JM 2-12-02 Corrected reference to EMSX to include ShopGroup in key.
*   TV 07/05/03 - TV clean up and Issue 22059
*   TV 10/20/03 - Added Auto ID 22746
*   TV 12/09/03 23208 - and some clean up
*	TV 02/11/04 - 23061 added isnulls 
* USAGE:
* 	Returns a WorkOrder to use in initialization process
*	as follows:
*
*	(1) If the passed Equipment is a Component, returns the
*	    WO for the Component's parent Equipment if one has
* 	    already been set up within a range of WO's. If the
*       WO hasnt already been setup for the parent, returns
*       the next available WO within the range of WO's.
*
*	(2) If passed Equipment is not a Component, returns the
*       next available WO.
*
* INPUT PARAMETERS:
*	EM Company
*	Passed Equipment - can be either an Equipment or Component
*	First WO in range - start of range
*	Last WO in range - end of range
*	AutoSeq - 'Y' or 'N'
*	AutoSeqOpt - 'C' by shop, 'E' by company
*	OverrideShop - If AutoSeq by Shop, the shop to use in lieu of Equip's Shop
*
* OUTPUT PARAMETERS:
*	Next Available WO
*	Error Message, if one
*
* RETURN VALUE:
* 	0	Success
*	1 	Failure
*********************************************************/
(@emco bCompany = null, 
@equip bEquip = null, 
@firstwoinrange bWO = null, 
@lastwoinrange bWO = null, 
@autoseq char(1) = null, 
@autoopt char(1) = null, 
@overrideshop varchar(20) = null, 
@autoid as varchar(255),
@wo bWO output, 
@errmsg varchar(60) output)
   
as
   
set nocount on
   
declare @equiptype char(1),	@maxwo int,	@numrows tinyint, @rcode int, @shopgroup bGroup
   
select @rcode = 0
   
-- Verify required parameters were passed. 
if @emco = 0
begin
   	select @errmsg = 'Missing EM Company#!', @rcode = 2
   	goto bspexit
end

if IsNull(@equip,'')=''
begin
   	select @errmsg = 'Missing Equipment!', @rcode = 2
   	goto bspexit
end

if IsNull(@firstwoinrange,'')='' and IsNull(@autoseq,'')=''
begin
   	select @errmsg = 'Missing First WO in Range under manual WO sequencing!', @rcode = 2
   	goto bspexit
end
   
if IsNull(@lastwoinrange,'')=''and IsNull(@autoseq,'')=''
begin
   	select @errmsg = 'Missing Last WO in Range under manual WO sequencing!', @rcode = 2
   	goto bspexit
end

if IsNull(@autoopt,'')='' and IsNull(@autoseq,'')=''
begin
   	select @errmsg = 'Missing AutoSeq Option under WO AutoSequencing!', @rcode = 2
   	goto bspexit
end
   
if @firstwoinrange is null and @autoseq = 'Y'
begin
	if @autoopt = 'C' --by Shop
    begin
       	--Get ShopGroup from bHQCO for @emco 
       	select @firstwoinrange = IsNull(LastWorkOrder,'0') from dbo.EMSX with(nolock) 
       	where ShopGroup = (select ShopGroup from dbo.HQCO  with(nolock) where HQCo = @emco)and
       	Shop = isnull(@overrideshop,(select Shop from dbo.EMEM with(nolock) where EMCo = @emco and Equipment = @equip)) 
    end
    if @autoopt = 'E' --by Company
	begin
   	    select @firstwoinrange = IsNull(LastWorkOrder,'0') from dbo.EMCO with(nolock) where EMCo = @emco
	end

    if IsNull(@firstwoinrange,'')=''
    begin
		select @errmsg = 'Missing LastWorkOrder in ' + case when @autoopt = 'C' then 'bEMSX' else 'bEMCO' end + ' under WO AutoSequencing!', @rcode = 2
		goto bspexit
    end
       
    select @lastwoinrange = @firstwoinrange
       	
    select @equiptype = Type from dbo.EMEM with(nolock) where EMCo = @emco and Equipment = @equip
       
       
    select @wo = WorkOrder from dbo.EMWH  with(nolock) 
    where EMCo = @emco and  AutoInitSessionID = @autoid and WorkOrder >= @firstwoinrange and WorkOrder <= @lastwoinrange and
	Equipment = case when @equiptype = 'C' then (select CompOfEquip from dbo.EMEM with(nolock)  where EMCo = @emco and Equipment = @equip) else @equip end
end
     
   
if (@equiptype = 'E'and isnull(@wo,'') <> '') or isnull(@wo,'')= ''--A parent Equipment or not found for Component above. 
begin
	/*131082*/
	exec @rcode = bspEMWOInitGetNextAvail @emco, @equip, @firstwoinrange, @autoseq,
    @autoopt, @overrideshop, @wo output, @errmsg output
    if @rcode = 1 or isnull(@wo,'') = ''
    begin
          select @errmsg = 'Error getting next available Work Order!'
          goto bspexit
    end
end
   
bspexit:
	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMWOInitGetInRange]'

   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOInitGetInRange] TO [public]
GO
