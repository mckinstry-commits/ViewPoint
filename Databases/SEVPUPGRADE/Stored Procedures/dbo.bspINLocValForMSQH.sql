SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspINLocValForMSQH]
    /*************************************
    * Created By:  GF 12/19/2000
    * Modified By:
    *				RM 12/23/02 Cleanup Double Quotes
    *
    * validates IN Locations for MSQH
    *
    * Pass:
    *  INCo - Inventory Company
    *  Loc - Location to be Validated
    *
    * Success returns:
    *  Price Template
    *  Description of Location
    *
    * Error returns:
    *	1 and error message
    **************************************/
   (@INCo bCompany = null, @Loc bLoc, @activeopt bYN, @pricetemplate smallint output,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @active bYN
   
   select @rcode = 0
   
   if @INCo is null
    	begin
    	select @msg = 'Missing IN Company', @rcode = 1
    	goto bspexit
    	end
   
   if @Loc is null
       begin
    	select @msg = 'Missing IN Location', @rcode = 1
    	goto bspexit
    	end
   
   select @active=Active, @msg = Description, @pricetemplate=PriceTemplate
   from bINLM where INCo = @INCo and Loc = @Loc
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
       --if @rcode<>0 select @msg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINLocValForMSQH] TO [public]
GO
