SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCAPCOVal ******/
CREATE proc [dbo].[vspJCAPCOVal]
/*********************************************
* Created By:	DANF 03/28/2006
* Modified By:
*
* Purpose: To validate AP Company number from JC Cost Adjustment
* set up form and returns default GL Company.
*
* PASS IN:
* @hqco		HQ Company
*
* RETURN:
* @glco		GL Company default
* @msg		HQ Company name
*
*********************************************/
(@apco bCompany = 0, @vendorgroup bGroup = 0 output, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @apco = 0
	begin
  	select @msg = 'Missing HQ Company#!', @rcode = 1
  	goto bspexit
  	end

select @msg = Name from HQCO with (nolock) where @apco = HQCo
if @@rowcount = 0
  	begin
  	select @msg = 'Not a valid HQ Company!', @rcode = 1
  	end


-- -- -- get default gl company
select @vendorgroup = VendorGroup from HQCO with (nolock) where HQCo=@apco




bspexit:
	if @rcode<> 0 select @msg=isnull(@msg,'')
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCAPCOVal] TO [public]
GO
