SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE proc [dbo].[bspMSINCompanyVal]
/***********************************************************
 * CREATED BY:		GF 09/09/2002
 * MODIFIED By:
 *
 * USAGE:
 * validates IN Company number for use in MS Ticket Entry.
 *
 * INPUT PARAMETERS
 *   INCo   IN Co to Validate
 *
 * OUTPUT PARAMETERS
 * @glco		IN company GL company
 * @taxgroup	Tax group for IN company.
 * @negwarn		Negative warning flag from IN company
 * @msg		If Error, error message, otherwise description of Company
 * RETURN VALUE
 *   0   success
 *   1   fail
 *****************************************************/
(@inco bCompany = 0, @glco bCompany output, @taxgroup bGroup output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if isnull(@inco,0) = 0
	begin
	select @msg = 'Missing IN Company!', @rcode = 1
	goto bspexit
	end

---- get GL company
select @glco=GLCo from INCO where INCo = @inco
if @@rowcount = 0
	begin
	select @msg = 'Not a valid IN Company!', @rcode = 1
	goto bspexit
	end

---- get name and tax group from HQCO
select @msg=Name, @taxgroup=TaxGroup from HQCO where HQCo = @inco
if @@rowcount = 0
	begin
	select @msg = 'Not a valid IN Company!', @rcode = 1
	goto bspexit
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSINCompanyVal] TO [public]
GO
