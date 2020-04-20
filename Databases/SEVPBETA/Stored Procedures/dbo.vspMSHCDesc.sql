SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSHCDesc    Script Date: 11/30/2005 ******/
CREATE proc [dbo].[vspMSHCDesc]
/*************************************
 * Created By:	GF 11/30/2005
 * Modified by:
 *
 * called from MSHaulCodes to return haul code key description
 *
 * Pass:
 * MSCo			MS Company
 * HaulCode		MS Haul Code
 *
 * Returns:
 * Description
 * MSPR_Exists	MS Pay Rates Exists for pay code
 *
 * Success returns:
 *	0 and Description from MSPC
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@msco bCompany, @haulcode bHaulCode, @mshr_exists bYN = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@haulcode,'') <> ''
	begin
	select @msg = Description
	from MSHC with (nolock) where MSCo=@msco and HaulCode=@haulcode
	-- -- -- check for rates in MSPR
	if exists(select top 1 1 from MSHR with (nolock) where MSCo=@msco and HaulCode=@haulcode)
		select @mshr_exists = 'Y'
	else
		select @mshr_exists = 'N'
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSHCDesc] TO [public]
GO
