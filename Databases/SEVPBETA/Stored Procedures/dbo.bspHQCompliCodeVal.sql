SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCompliCodeVal    Script Date: 8/28/99 9:34:49 AM ******/
   CREATE   procedure [dbo].[bspHQCompliCodeVal]
   /*************************************
   * Created: CJW 2/26/97
   * Revised: CJW 2/26/97
   *			 MV 03/21/05 #27188 - return APVC Memo
   *			GF 03/10/2011 issue #143533
   *
   *
   * validates HQ Compliance Codes
   *
   * Pass:
   *	Compliance Code to be validated
   *
   * Success returns:
   *	0 and Description from bHQCP, Verify flag, and Compliance Type
   *
   * Error returns:
   *	1 and error message
   **************************************/
   ----#143533
(@co bCompany, @po VARCHAR(30), @CompCode bCompCode = null, @POorSl varchar (1), @Verify bYN output,
 @CompType char(1) output, @memo varchar(255) output, @msg varchar(60) output)
as 
set nocount ON

declare @rcode int
select @rcode = 0
   	
   if @CompCode is null
   	begin
   	select @msg = 'Missing compliance code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description,@Verify=Verify, @CompType=CompType from bHQCP where CompCode = @CompCode
   
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid compliance code.', @rcode = 1
   		end
   
   if @POorSl = 'P' -- PO
   begin
   select @memo = Memo from APVC with (nolock) join POHD with (nolock) on APVC.APCo=POHD.POCo and
   	APVC.VendorGroup=POHD.VendorGroup and APVC.Vendor=POHD.Vendor 
   	where APVC.APCo=@co and APVC.CompCode=@CompCode and POHD.PO=@po 
   	goto bspexit
   end
   
   if @POorSl = 'S' -- SL
   begin
   select @memo = Memo from APVC with (nolock) join SLHD with (nolock) on APVC.APCo=SLHD.SLCo and
   	APVC.VendorGroup=SLHD.VendorGroup and APVC.Vendor=SLHD.Vendor 
   	where APVC.APCo=@co and APVC.CompCode=@CompCode and SLHD.SL=@po
   end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQCompliCodeVal] TO [public]
GO
