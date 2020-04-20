SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSQHDesc    Script Date: 12/05/2005 ******/
CREATE  proc [dbo].[vspMSQHDesc]
/*************************************
 * Created By:	GF 12/05/2005
 * Modified by:
 *
 * called from MSQuote to return quote header key description.
 * Also gets next quote when MSCO.AutoQuote flag is 'Y'.
 *
 * Pass:
 * MSCo				MS Company
 * Quote			MS Quote
 *
 * Returns:
 * Description
 * NextQuote		MS Next Quote when auto generate feature active
 *
 * Success returns:
 *	0 and Description from MSPC
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@msco bCompany, @quote varchar(10), @next_quote varchar(10) = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @autoquote bYN

select @rcode = 0, @msg = '', @autoquote = 'N', @next_quote = ''

if isnull(@quote,'') <>''
	begin
	select @msg = Description
	from MSQH with (nolock) where MSCo=@msco and Quote=@quote
	end

-- -- -- -- -- -- get next quote if MSCO.AutoQuote flag is 'Y'
-- -- -- select @autoquote=AutoQuote from MSCO with (nolock) where MSCo=@msco
-- -- -- if @@rowcount <> 0 and @autoquote = 'Y'
-- -- -- 	begin
-- -- -- 	exec @rcode = dbo.bspMSGetNextQuote @msco, @next_quote
-- -- -- 	if @rcode <> 0 select @next_quote = ''
-- -- -- 	select @rcode = 0
-- -- -- 	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSQHDesc] TO [public]
GO
