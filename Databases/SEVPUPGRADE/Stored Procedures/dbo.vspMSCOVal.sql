SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSCOVal ******/
CREATE proc [dbo].[vspMSCOVal]
/*********************************************
* Created By:	GF 11/23/2005
* Modified By:
*
* Purpose: To validate MS Company number from MS Company
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
(@hqco bCompany = 0, @glco bCompany = 0 output, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @hqco = 0
	begin
  	select @msg = 'Missing HQ Company#!', @rcode = 1
  	goto bspexit
  	end

select @msg = Name from HQCO with (nolock) where @hqco = HQCo
if @@rowcount = 0
  	begin
  	select @msg = 'Not a valid HQ Company!', @rcode = 1
  	end


-- -- -- get default gl company
select @glco = GLCo from INCO with (nolock) where INCo=@hqco
if @@rowcount = 0 select @glco=@hqco




bspexit:
	if @rcode<> 0 select @msg=isnull(@msg,'')
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSCOVal] TO [public]
GO
