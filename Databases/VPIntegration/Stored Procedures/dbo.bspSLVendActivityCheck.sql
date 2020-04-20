SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[bspSLVendActivityCheck]
   /***********************************************************
    * CREATED BY	: MV 08/23/05 #28542
    * MODIFIED BY	: DC 06/25/10 - #135813 - expand subcontract number
    *              
    *
    * USED IN:
    * SL Entry 
    *
    * USAGE:
    * Check for SL activity if the vendor is changed. Activity
    *	is invoicing, change order, worksheet
    *
    * INPUT PARAMETERS
    *  Co  		the company we're in 
    *  SL			the subcontract		
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if there is activity in
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
       (@co bCompany , @sl VARCHAR(30), --bSL,   DC #135813
       @msg varchar(255)output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
            
   if exists (select 1 from bAPTL where APCo=@co and SL=@sl)
   		begin
        select @msg = 'SL has been invoiced.  Cannot change Vendor.', @rcode = 1
        goto bspexit
        end
   	
   if exists (select 1 from bSLCD where SLCo=@co and SL=@sl)
		begin
   		select @msg = 'SL has change orders.  Cannot change Vendor.', @rcode=1
   		goto bspexit
   		end
      	
   if exists (select 1 from bSLWH where SLCo=@co and SL=@sl)
   		begin
        select @msg = 'SL is in a Worksheet. Delete SL from the Worksheet before changing Vendor.', @rcode = 1
        goto bspexit
        end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLVendActivityCheck] TO [public]
GO
