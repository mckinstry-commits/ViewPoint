SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspMSInvGetNext]
/***********************************************************
 * Created By:   GF 11/14/2000
 * Modified By:	GF 02/06/2007 - issue #123745 for convert with bigint for LastInvNum
 *				GF 05/07/2007 - issue #124523 another bigint change for lastinvnum
 *
 *
 *
 * Called from the MS Invoice Edit form to get the next invoice.
 *
 * INPUT PARAMETERS
 *   MSCo    MS Company
 *
 * OUTPUT PARAMETERS
 *   @msg            next invoice number or error message
 *
 * RETURN VALUE
 *   0               success
 *   1               fail
 *****************************************************/
(@co bCompany = null, @msinv varchar(10) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @arco bCompany, @invopt char(2), @invautonum bYN

select @rcode = 0, @msinv = null

---- get MS company info
select @arco=ARCo, @invopt=InvOpt from bMSCO with (nolock) where MSCo=@co
if @@rowcount = 0
	begin
	select @msg = 'Missing MS Company!', @rcode = 1
	goto bspexit
	end

---- get AR company info
select @invautonum from bARCO with (nolock) where ARCo=@arco
if @@rowcount = 0
	begin
	select @msg = 'Missing AR Company!', @rcode = 1
	goto bspexit
	end

---- get next invoice number
next_Invoice:
if @invopt = 'MS'
	begin
	select @msinv = convert(varchar(10),convert(bigint,isnull(LastInv,'0')) + 1)
	from bMSCO with (nolock) where MSCo=@co
	update bMSCO set LastInv=@msinv where MSCo=@co    -- update last invoice #
	end
else
	begin
	select @msinv = convert(varchar(10),convert(bigint,isnull(InvLastNum,'0')) + 1)
	from bARCO with (nolock) where ARCo=@arco
	update bARCO set InvLastNum = convert(bigint,@msinv) where ARCo=@arco    -- update last invoice #
	end

---- invoice should be right justified 10 chars
select @msinv = space(10 - datalength(@msinv)) + @msinv
---- skip Invoice # if already used
if exists(select 1 from bMSIH with (nolock) where MSCo=@co and MSInv=@msinv) goto next_Invoice
if exists(select 1 from bMSIB with (nolock) where Co=@co and MSInv=@msinv) goto next_Invoice




bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSInvGetNext] TO [public]
GO
