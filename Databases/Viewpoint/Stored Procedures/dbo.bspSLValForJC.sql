SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLValForJC    Script Date: 8/28/99 9:33:42 AM ******/
   CREATE  proc [dbo].[bspSLValForJC]
   /***********************************************************
    * CREATED BY	: DANF 01/10/2000
    * MODIFIED BY	: DC 06/25/10 - #135813 - expand subcontract number
    *
    * USAGE:
    * validates SL, returns SL Description,
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
       (@slco bCompany, @sl VARCHAR(30),  --bSL, DC #135813
       @Vendor bVendor, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint, @SLVendor bVendor
   
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
   
   select @status=Status from SLHD
   	where SLCo = @slco and SL = @sl
   if @@rowcount=0
   	begin
   	select @msg = 'Subcontract not on file!', @rcode = 1
   	goto bspexit
   	end
   
   if @status<>0
   	begin
   	select @msg = 'Subcontract not open!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg=SLHD.Description, @SLVendor=SLHD.Vendor
   	from SLHD
   	where SLHD.SLCo = @slco and SLHD.SL= @sl
   if @@rowcount<>0 AND @SLVendor <> @Vendor
   	begin
   	select @msg = 'SL Vendor ' + convert(varchar(6),@SLVendor) + ' does not match transaction.', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLValForJC] TO [public]
GO
