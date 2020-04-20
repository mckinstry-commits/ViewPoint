SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************/
CREATE proc [dbo].[bspMSTicHaulPhaseVal]
/*************************************
 * Created By:	GF 03/18/2004 - for issue #24038 phase pricing
 * Modified By:
 *
 * USAGE:   Validate phase code using bspJCVPhase, then get haul rate
 *			override if exists. Used in MSTicEntry
 *
 *
 * INPUT PARAMETERS
 * @msco			MS Company
 * @jcco			JC Company
 * @job				JC Job
 * @phasegroup		JC Phase Group
 * @phase			Phase Code
 * @override		Phase Override flag
 * @matlgroup		Material Group
 * @material		Material
 * @locgroup		From Location group
 * @fromloc			From Location
 * @matlum			Material UM
 * @quote			Quote
 * @pricetemplate	Price Template
 * @saledate		Sale Date
 *
 *
 * OUTPUT PARAMETERS
 *	@haulrate 		Haul Rate override
 *	@minamt 		MinAmt override
 *  @msg            error message
 *
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *
 **************************************/
(@msco bCompany = null, @jcco bCompany = null, @job bJob=null, @phasegroup bGroup = null,
 @phase bPhase = null, @override bYN = 'N', @matlgroup bGroup = null, @material bMatl = null,
 @locgroup bGroup = null, @fromloc bLoc = null, @matlum bUM = null, @quote varchar(10) = null,
 @trucktype varchar(10) = null, @zone varchar(10) = null, @haulcode bHaulCode = null,
 @basis tinyint = null, @haulrate bUnitCost = null output, @minamt bDollar = null output,
 @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @retcode int, @category varchar(10), @tmpmsg varchar(255), @pphase bPhase

select @rcode = 0, @retcode = 0

if @msco is null
	begin
	select @msg = 'Missing MS Company', @rcode = 1
	goto bspexit
	end

if @jcco is null
	begin
	select @msg = 'Missing JC Company', @rcode = 1
	goto bspexit
   	end

---- do standard phase validation
exec @rcode = dbo.bspJCVPHASE @jcco, @job, @phase, @phasegroup, @override, 
   			null, null, null, null, null, null, null, null, @msg output
if @rcode <> 0 goto bspexit

---- get category for material
select @category=Category from HQMT with (nolock)
where MatlGroup=@matlgroup and Material=@material

---- get haul code values
exec @retcode = dbo.bspMSTicHaulRateGet @msco, @haulcode, @matlgroup, @material, @category, @locgroup,
				@fromloc, @trucktype, @matlum, @quote, @zone, @basis, @jcco, @phasegroup, @phase,
   				@haulrate output, @minamt output, @tmpmsg output
if @retcode <> 0
	begin
	select @haulrate = 0, @minamt = 0
	end


bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicHaulPhaseVal] TO [public]
GO
