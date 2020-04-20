SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspAPRecurInvLineDesc]
  /***************************************************
  * CREATED BY    : MV 
  * LAST MODIFIED : 
  * Usage:
  *   Returns line description to APRecurInvItems form
  *
  * Input:
  *	@apco         
  *	@vendorgroup      
  * @vendor
  * @InvId
  * @line
  *
  * Output:
  *   @msg          Line description 
  *
  *************************************************/
  	(@apco bCompany = null, @vendorgroup bGroup, @vendor bVendor,
	 @InvId varchar(10),@line int ,@msg varchar(60) output)
  as
  
  set nocount on
  
if exists (select 1 from bAPRL with (nolock)
  where APCo=@apco and VendorGroup=@vendorgroup 
	and Vendor = @vendor and InvId=@InvId and Line=@line)
	begin 
		select @msg=Description
		  from bAPRL with (nolock)
		  where APCo=@apco and VendorGroup=@vendorgroup 
			and Vendor = @vendor and InvId=@InvId and Line=@line
	end
else
	begin
		select @msg = ''
	end

GO
GRANT EXECUTE ON  [dbo].[vspAPRecurInvLineDesc] TO [public]
GO
