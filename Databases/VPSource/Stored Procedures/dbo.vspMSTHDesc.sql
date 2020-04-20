SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSTHDesc    Script Date: 12/01/2005 ******/
CREATE proc [dbo].[vspMSTHDesc]
/*************************************
 * Created By:	GF 12/01/2005
 * Modified by:
 *
 * called from MSPriceTemplate to return price template code key description
 *
 * Pass:
 * MSCo				MS Company
 * PriceTemplate	MS Price Template
 *
 * Returns:
 * Description
 * MSTP_Exists		MS Price Template Rates Exists
 *
 * Success returns:
 *	0 and Description from MSTH
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@msco bCompany, @pricetemplate smallint, @mstp_exists bYN = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@pricetemplate,0) <> 0
	begin
	select @msg = Description
	from MSTH with (nolock) where MSCo=@msco and PriceTemplate=@pricetemplate
	-- -- -- check for rates in MSPR
	if exists(select top 1 1 from MSTP with (nolock) where MSCo=@msco and PriceTemplate=@pricetemplate)
		select @mstp_exists = 'Y'
	else
		select @mstp_exists = 'N'
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSTHDesc] TO [public]
GO
