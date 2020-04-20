SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlValEM    Script Date: 8/28/99 9:34:53 AM ******/
CREATE  proc [dbo].[bspHQMatlValEM]
/*************************************
* Created By:	??
* Modified BY:	TRL 12/17/08 Issue 127133 added isnulls and @existsYN parameter
*				GF 04/29/2009 - issue #131939 material description expanded to 60-characters
*
*
* validates HQ Material vs HQMT.Material
*
* Pass:
*	HQ MatlGroup
*	HQ Material
*	Validation flag.  Yes or No
*
* Success returns:
*	0 and Description from bHQMT
*
* Error returns:
*	1 and error message
**************************************/
(@matlgroup bGroup = null, @material bMatl = null, @valflag varchar(1) = 'N',
 @sum bUM output, @desc bItemDesc output, @existsYN bYN output, @msg varchar(60) output)
as 
set nocount on

declare @rcode int

select @rcode = 0, @msg = null, @sum = null

if @matlgroup is null
begin
	select @msg = 'Missing Material Group', @rcode = 1
	goto bspexit
end

--127133
if IsNull(@material,'') = ''
begin
	select @msg = 'Missing Material', @rcode = 1
	goto bspexit
end

---- validate material to HQMT
--127133
select @desc = IsNull(Description,''), @sum = SalesUM,
@existsYN= case when IsNull(Material,'') = '' then 'N' else 'Y'end
from dbo.HQMT with (nolock)
where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0 
begin
	if @valflag = 'Y' 
	begin
		select @msg = 'Not a valid Material', @rcode = 1
		goto bspexit
	end
end

if @rcode = 0
begin
	select @msg = @desc
end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatlValEM] TO [public]
GO
