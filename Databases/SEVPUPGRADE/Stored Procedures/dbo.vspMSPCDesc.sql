SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSPCDesc    Script Date: 11/30/2005 ******/
CREATE   proc [dbo].[vspMSPCDesc]
/*************************************
 * Created By:	GF 11/30/2005
 * Modified by:
 *
 * called from MSPayCodes to return pay code key description
 *
 * Pass:
 * MSCo			MS Company
 * PayCode		MS Pay Code
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
(@msco bCompany, @paycode bPayCode, @mspr_exists bYN = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@paycode,'') <> ''
	begin
	select @msg = Description
	from MSPC with (nolock) where MSCo=@msco and PayCode=@paycode
	-- -- -- check for rates in MSPR
	if exists(select top 1 1 from MSPR with (nolock) where MSCo=@msco and PayCode=@paycode)
		select @mspr_exists = 'Y'
	else
		select @mspr_exists = 'N'
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSPCDesc] TO [public]
GO
