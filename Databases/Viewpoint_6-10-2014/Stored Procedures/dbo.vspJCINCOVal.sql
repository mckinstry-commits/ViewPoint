SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCAPCOVal ******/
CREATE proc [dbo].[vspJCINCOVal]
/*********************************************
* Created By:	DANF 03/28/2006
* Modified By:
*
* Purpose: To validate IN Company number from JC Cost Adjustment
* set up form and returns default Material Group.
*
* PASS IN:
* @hqco		HQ Company
*
* RETURN:
* @materialGroup	GL Company default
* @msg				HQ Company name
*
*********************************************/
(@inco bCompany = 0, @materialgroup bGroup = 0 output, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @inco = 0
	begin
  	select @msg = 'Missing HQ Company#!', @rcode = 1
  	goto bspexit
  	end

select @msg = Name from HQCO with (nolock) where @inco = HQCo
if @@rowcount = 0
  	begin
  	select @msg = 'Not a valid HQ Company!', @rcode = 1
  	end


-- -- -- get default gl company
select @materialgroup = MatlGroup from HQCO with (nolock) where HQCo=@inco




bspexit:
	if @rcode<> 0 select @msg=isnull(@msg,'')
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCINCOVal] TO [public]
GO
