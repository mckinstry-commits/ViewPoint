SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOINLocAddress    Script Date: 3/15/2004 2:57:34 PM ******/
   CREATE     proc [dbo].[bspEMWOINLocAddress]
   /***********************************************************
    * CREATED BY: DC 3/15/2004
	*				DC 03/20/2008 - #127387  Modify RQEntry for International Addresses
    *			   
   * validates IN Locations
   *
   * Pass:
   *   EMCo - EM Company
   *   WorkOrder - Work Order 
   *
   *
   * Success returns:
   *   Description of Location
   *   Shipping Address
   *
   * Error returns:
   *	1 and error message
    *****************************************************/
   	(@emco bCompany = null, @workorder bWO = null, @shipaddress varchar(60) output,
        @shipcity varchar(30) output, @shipstate varchar(2) output, @shipzip varchar(12) output, 
   	 @shipaddress2 varchar(60) output, 
	@shipcountry varchar(2) output, --DC #127387
	 @msg varchar(255) output)
   
   
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @workorder is null
   	begin
   	select @msg = 'Missing Work Order!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   from bEMWH
   where EMCo = @emco
   	and WorkOrder = @workorder
   if @@rowcount = 0
   	begin
   	select @msg = 'Work Order not on file!', @rcode = 1
   	goto bspexit
   	end
   
   select @shipaddress = l.ShipAddress, @shipcity = l.ShipCity, 
   	@shipstate = l.ShipState, @shipzip = l.ShipZip, @shipaddress2 = l.ShipAddress2,
	@shipcountry = l.ShipCountry
   from bEMWH h 
   join bINLM l on l.INCo = h.INCo and l.Loc = h.InvLoc
   where h.EMCo = @emco and h.WorkOrder = @workorder and l.Active = 'Y'
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOINLocAddress]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOINLocAddress] TO [public]
GO
