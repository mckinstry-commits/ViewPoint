SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCCISICodeVal    Script Date: 05/23/2005 ******/
CREATE      proc [dbo].[vspJCCISICodeVal]
/*************************************
 * Created By:	GF 05/23/2005
 * Modified By: DANF 08/07/2006 
 *
 * USAGE:
 *	Validates SIRegion and SICode for JCCI, returns default values for contrat item.
 *	If imperial, uses JCSI.UM = def um and JCSI.UnitPrice = def up
 *	If metric, uses JCSI.MUM = def um and JCSI.UnitPrice * JCMC.MIFactor = def up
 *
 * Pass:
 * JCCo			JC Company
 * Contract		JC Contract
 * SIRegion		JC SI Region
 * SICode		JC SI Code
 *
 * Success returns:
 * 
 *	0 and either UM or MUM from JCSI
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@jcco bCompany = null, @contract bContract = null, @siregion varchar(6) = null,
 @sicode varchar(16) = null, @simetric bYN output, @description bItemDesc = null output,
 @um bUM = null output, @mum bUM = null output, @unitprice bUnitCost = 0 output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @mifactor real, @addjcsicode bYN

select @rcode = 0

if @siregion is null
	begin
  	select @msg = 'Missing Std Item Region', @rcode = 1
  	goto bspexit
  	end

if @sicode is null
  	begin
  	select @msg = 'Missing Std Item Code', @rcode = 1
  	goto bspexit
  	end

-- read flag from JCCO
select @addjcsicode=AddJCSICode
from dbo.bJCCO with (nolock) 
where JCCo=@jcco

-- -- -- get JCCM.SIMetric
select @simetric = SIMetric
from dbo.bJCCM with (nolock) 
where JCCo=@jcco and Contract=@contract
if @@rowcount = 0
	begin
	select @msg = 'Invalid JC Contract', @rcode = 1
	goto bspexit
	end

-- -- -- get JCSI data
select @description=Description, @um=UM, @mum=MUM, @unitprice=UnitPrice
from dbo.bJCSI with (nolock)
where SIRegion=@siregion and SICode=@sicode
if @@rowcount = 0
       begin
       if @addjcsicode <> 'Y'
           begin
           select @msg = 'Not a valid Std Item Code.', @rcode = 1
           goto bspexit
           end
       else
           begin
           select @msg = 'New Std Item Code', @um = null, @mum = null
           end
       end

-- -- -- if using metric UM then get factor from bJCMC
if @simetric = 'Y'
	begin
	select @mifactor=MIFactor
	from dbo.bJCMC with (nolock)
	where UM=@um and MUM=@mum
	if @@rowcount = 0 or @mifactor is null select @mifactor = 0
	-- -- -- calculate default metric unitprice
	select @unitprice = @unitprice * @mifactor
	end

select @msg = @description



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCISICodeVal] TO [public]
GO
