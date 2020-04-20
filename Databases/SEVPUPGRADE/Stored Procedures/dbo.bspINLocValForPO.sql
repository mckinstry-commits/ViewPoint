SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspINLocValForPO]
   /*************************************
   * CREATED BY:   GR 3/23/00
   * MODIFIED BY:  RM 12/23/02 Cleanup Double Quotes
   *				RT 08/20/03 Issue #21582, return Address2 from INLM.
   *				Dan So - 03/17/08 - #127082 - added @shipcountry
   *				DC 10/14/08 - #130536 - IN Location default tax code is not defaulting for IN line types
   *
   * validates IN Locations
   *
   * Pass:
   *   INCo - Inventory Company
   *   Loc - Location to be Validated
   *
   *
   * Success returns:
   *   Description of Location
   *   Shipping Address
   *	Tax Code
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@inco bCompany = null, @loc bLoc, @activeopt bYN, @shipaddress varchar(60) output,
        @shipcity varchar(30) output, @shipstate varchar(2) output, @shipzip varchar(12) output, 
   	@shipaddress2 varchar(60) output, @shipcountry varchar(2) output, 
   	@taxcode bTaxCode output, --DC #130536
   	@msg varchar(100) output)
   	
   as
   	set nocount on
   	declare @rcode int, @active bYN
      	select @rcode = 0
   
   if @inco is null
   	begin
   	select @msg = 'Missing IN Company', @rcode = 1
   	goto bspexit
   	end
   
   if @loc is null
   	begin
   	select @msg = 'Missing IN Location', @rcode = 1
   	goto bspexit
   	end
   
   select @active=Active, @msg = Description, @shipaddress = ShipAddress,
       @shipcity=ShipCity, @shipstate=ShipState, @shipzip = ShipZip, @shipaddress2=ShipAddress2, 
		@shipcountry = ShipCountry,
		@taxcode = TaxCode  --DC #130536
       from bINLM where INCo = @inco and Loc = @loc
   
   if @@rowcount = 0
       begin
       select @msg='Not a valid Location', @rcode=1
       goto bspexit
       end
   
   if @activeopt = 'Y' and @active = 'N'
       begin
       select @msg = 'Not an active Location', @rcode=1
       goto bspexit
       end
   
   bspexit:
      -- if @rcode<>0 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINLocValForPO] TO [public]
GO
