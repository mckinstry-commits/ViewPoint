SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLValNoBatch    Script Date: 8/28/99 9:33:42 AM ******/
   CREATE  proc [dbo].[bspSLValForSLComply]
   /***********************************************************
    * CREATED BY	: MV 03/14/03
    * MODIFIED BY	: DC 06/25/10 - #135813 - expand subcontract number
    *
    * USAGE:
    * validates SL, returns SL Description, Vendor, and Vendor Description and flag SL as inuse
    * 	and Status 
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
       @source char(1), @VendorName char(30) output, @Vendor bVendor output, @job bJob output, @jobdesc bDesc output, @jcco bCompany output,
   	@status tinyint output,	@msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int,/* @status tinyint,*/ @VendorGroup bGroup
   
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
   /*if @source <> 'P'
   begin
   if @status<>0
   	begin
   	select @msg = 'Subcontract not open!', @rcode = 1
   	goto bspexit
   	end
   end*/
   
   select @msg=SLHD.Description, @job=SLHD.Job, @Vendor=SLHD.Vendor, @VendorName=APVM.Name,
   	@VendorGroup=SLHD.VendorGroup, @jcco=SLHD.JCCo,	@jobdesc=JCJM.Description 
   
   	from SLHD JOIN APVM ON APVM.VendorGroup=SLHD.VendorGroup and APVM.Vendor=SLHD.Vendor
   	join JCJM on JCJM.JCCo=SLHD.JCCo and JCJM.Job=SLHD.Job
   	where SLHD.SLCo = @slco and SLHD.SL= @sl
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLValForSLComply] TO [public]
GO
