SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOAutoSeq    Script Date: 2/12/2002 9:55:29 AM ******/
CREATE    proc [dbo].[bspEMWOAutoSeq]
/**************************************************************************
*Created 2/6/01 tv
*Modified:	JM 2-12-02 - Added ShopGroup to queries to EMSX to (1) correct validation (2) avoid return of 
*		multiple rows and error in EMSX update trigger.
*		TV 02/11/04 -  23061 added isnulls 
*		TV 07/30/04 -  25262 WO need to be verified by Co
*		TRL 03/07/08 - 127275 AutoSeq value not being returned
*		TRL 04/28/08 - 126052 If LastWorkOrder is null, give it a value of 0
*		TRL 11/14/08 - 131082 added vspEMWOGetNextAvailable (Gets next Available WO and foramts WO)
*		TRL 08/03/09 - 133975	Added input paramters @formstatus, @autoopt,@shopgroup,@shop for vspEMOGetNextAvailable
*
*USAGE: returns next available Work Order number to EMWOEdit
*
*   Inputs:
*	EMCO
*	Shop
*	Auto Sequence 
*	Auto Sequence Option
*	Equipment Number
*
*   Outputs:
*	Work Order number
*	error message, if there is one
*
*   RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
***************************************************************************/
(@emco bCompany = null, @shop varchar(10) = null,  @formstatus char(1) = null, 
@autoopt char(1) = null, @equipnum varchar(10) = null,  
@wonumber bWO output, @msg varchar(255) output)

as
   
set nocount on
   
declare @rcode int, @shopgroup bGroup
   
select @rcode = 0
  
/* Get ShopGroup from HQCO */
select @shopgroup = ShopGroup from dbo.HQCO with (nolock) where HQCo = @emco
   
if @formstatus = 'Y'
begin
	-- If option is to sequence by shop--
	if @autoopt = 'C'
	begin	
   		if not exists ( select top 1 1 from dbo.EMSX with (nolock) where ShopGroup = @shopgroup and Shop = @shop)
		begin	
   			select @msg = 'Not a valid Shop Number.', @rcode = 1
   			goto bpexit
		end
		/*Issue 126052*/
   		select @wonumber = (select IsNull(LastWorkOrder,'0') from dbo.EMSX with (nolock) where ShopGroup = @shopgroup and Shop = @shop)
   		--search for next avail WO--
   		
		/*Issue 131082	Formats and verifies and/or gets next available Work Order number*/
		/*Issue 133975	Added input paramters @formstatus, @autoopt,@shopgroup,@shop for vspEMOGetNextAvailable*/
		exec @rcode = dbo.vspEMWOGetNextAvailable @emco, @formstatus, @autoopt,@shopgroup,@shop, @wonumber output, @msg output
		If @rcode = 1
		begin
			goto bpexit
		end

   		update dbo.EMSX
   		set LastWorkOrder =  @wonumber
   		where ShopGroup = @shopgroup and Shop = @shop
   	end
   
	--If option is for sequence by Company--
   	if @autoopt = 'E'
   	begin
		/*Issue 126052*/
   		select @wonumber = (select IsNull(LastWorkOrder,'0') from dbo.EMCO with (nolock) where EMCo = @emco)
		If @rcode = 1
        begin
			goto bpexit
		end 
		
		/*Issue 131082	--Formats and verifies and/or gets next available Work Order number*/
		/*Issue 133975	Added input paramters @formstatus, @autoopt,@shopgroup,@shop for vspEMOGetNextAvailable*/
		exec @rcode = dbo.vspEMWOGetNextAvailable @emco, @formstatus, @autoopt,@shopgroup,@shop, @wonumber output, @msg output
		If @rcode = 1
		begin
			goto bpexit
		end

   		update dbo.EMCO
   		set LastWorkOrder =  @wonumber
   		where EMCo = @emco
   	end
end				

bpexit:
if @rcode<>0
begin
	 select @msg=isnull(@msg,'')
end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOAutoSeq] TO [public]
GO
