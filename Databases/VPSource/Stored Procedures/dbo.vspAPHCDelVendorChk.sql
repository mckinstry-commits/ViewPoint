SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspAPHCDelVendorChk]  
/************************************************************************
* CREATED:   TRL 02/19/2010  Issue 137736
* MODIFIED: 
*
*Checks to see if HQ Hold code is still in use by a vendor
*
* returns 0 if successfull
* returns 1 and error msg if failed
*************************************************************************/
(@holdcode bHoldCode, @errmsg varchar(255) = null output)  

as
 
set nocount on
   
declare @rcode int, @usecount  int, @apco bCompany, @apvendor bVendor 

select @rcode = 0


--Check for use in APVH  
select @usecount = count(*) from dbo.APVH with(nolock) where HoldCode=@holdcode
if @usecount <> 0 
begin
	select @apco = max(APCo) from dbo.APVH with(nolock) where HoldCode=@holdcode
	
	select @apvendor = max(Vendor) from dbo.APVH with(nolock) where APCo=@apco and HoldCode=@holdcode
	
	select @errmsg = 'Hold Code ' + @holdcode + ' in use in AP Vendor Codes.'
	+ ' AP Co: ' 	+convert(varchar,@apco)+ ', Vendor:  ' + convert(varchar,@apvendor),@rcode = 1
	
   	goto vspexit
 end

--Check for use in APTH 
select @usecount = count(*) from dbo.APTH  with(nolock)where HoldCode=@holdcode
if @usecount <> 0 
begin
	select @apco = max(APCo) from dbo.APTH with(nolock) where HoldCode=@holdcode
	
	select @apvendor = max(Vendor) from dbo.APTH with(nolock) where APCo=@apco and HoldCode=@holdcode
	
	select @errmsg = 'Hold Code ' + @holdcode + ' in use in AP Entry.'
	+ ' AP Co: ' 	+convert(varchar,@apco)+ ', Vendor:  ' + convert(varchar,@apvendor),@rcode = 1
	
	goto vspexit
end

--Check for use in APHB 
select @usecount = count(*) from dbo.APHB with(nolock)  where HoldCode=@holdcode
if @usecount <> 0 
begin
	select @apco = max(Co) from dbo.APHB with(nolock) where HoldCode=@holdcode
	
	select @apvendor = max(Vendor) from dbo.APHB with(nolock) where Co=@apco and HoldCode=@holdcode
	
	select @errmsg = 'Hold Code ' + @holdcode + ' in use in AP Entry.'
	+ ' AP Co: ' 	+convert(varchar,@apco)+ ', Vendor:  ' + convert(varchar,@apvendor),@rcode = 1
	
	goto vspexit
end

--Check for use in POHD 
select @usecount = count(*) from dbo.POHD with(nolock)  where HoldCode=@holdcode
if @usecount <> 0 
begin
	select @apco = max(POCo) from dbo.POHD with(nolock) where HoldCode=@holdcode 
	
	select @apvendor = max(Vendor) from dbo.POHD with(nolock) where POCo=@apco and HoldCode=@holdcode 
	
	select @errmsg = 'Hold Code ' + @holdcode + ' in use in PO Entry.'
	+ ' PO Co: ' 	+convert(varchar,@apco)+ ', Vendor:  ' + convert(varchar,@apvendor),@rcode = 1
	
	goto vspexit
end

--Check for use in SLHD 
select @usecount = count(*) from dbo.SLHD with(nolock)  where HoldCode=@holdcode
if @usecount <> 0 
begin
	select @apco = max(SLCo) from dbo.SLHD with(nolock) where HoldCode=@holdcode  

	select @apvendor = max(Vendor) from dbo.SLHD with(nolock) where SLCo=@apco and HoldCode=@holdcode
	
	select @errmsg = 'Hold Code ' + @holdcode + ' in use in SL Entry. ' 
	+ ' SL Co: ' 	+convert(varchar,@apco)+ ', Vendor:  ' + convert(varchar,@apvendor),@rcode = 1
	
	goto vspexit
end
 
vspexit:
	
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPHCDelVendorChk] TO [public]
GO
