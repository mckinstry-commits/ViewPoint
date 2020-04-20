SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfJBGetHQCoUsingMatlGrp]
(@matlgrp bGroup = null)
returns TinyInt
/***********************************************************
* CREATED BY	: TJL 06/02/06
* MODIFIED BY	
*
* USAGE:
* 	Returns Minimun HQCo using the MatlGroup passed in
*
* INPUT PARAMETERS:
*	Material Group
*
* OUTPUT PARAMETERS:
*	HQCo
*	
*
*****************************************************/
as
begin

declare @hqco bCompany

select @hqco = Min(HQCo) from bHQCO with (nolock) where MatlGroup = @matlgrp

exitfunction:
  			
return @hqco
end

GO
GRANT EXECUTE ON  [dbo].[vfJBGetHQCoUsingMatlGrp] TO [public]
GO
