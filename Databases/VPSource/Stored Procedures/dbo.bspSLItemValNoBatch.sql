
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLItemValNoBatch    Script Date: 8/28/99 9:33:41 AM ******/
   CREATE  proc [dbo].[bspSLItemValNoBatch]
   /***********************************************************
    * CREATED BY	:
    * MODIFIED BY	:	DC 06/25/10 - 135813 - expand subcontract number
    *
    * USAGE:
    * validates SL, returns SL Description, Vendor, and Vendor Description and flag SL as inuse
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   SLCo  PO Co to validate against 
    *   SL to validate
    * 
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of SL, Vendor, 
   
    *   Vendor group, and Vendor Name
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/    
       (@slco bCompany, @sl VARCHAR(30), --bSL, DC #135813
       @item bItem, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint
   
   select @rcode = 0
   
   if @slco is null
   	begin
   	select @msg = 'Missing SL Company!', @rcode = 1
   	goto bspexit
   	end
      
   if @sl is null
   	begin   
   	select @msg = 'Missing Subcontract!', @rcode = 1
   	goto bspexit
   	end
      
   if @item is null
   	begin
   	select @msg = 'Missing SL Item!', @rcode = 1
   	goto bspexit
   	end
   
   select @status=Status, @msg = t.Description from SLHD d
   	join SLIT t on t.SLCo = d.SLCo and t.SL = d.SL
   	where t.SLCo = @slco and t.SL = @sl and t.SLItem = @item
   
   if @@rowcount=0 
   	begin
   	select @msg = 'Subcontract Item not on file!', @rcode = 1
   	goto bspexit
   	end
   if @status<>0 
   	begin
   	select @msg = 'Subcontract not open!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO

GRANT EXECUTE ON  [dbo].[bspSLItemValNoBatch] TO [public]
GO
