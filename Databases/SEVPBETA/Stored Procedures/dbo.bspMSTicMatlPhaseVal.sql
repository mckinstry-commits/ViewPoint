SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************/
CREATE proc [dbo].[bspMSTicMatlPhaseVal]
/*************************************
 * Created By:	GF 03/18/2004 - for issue #24038 phase pricing
 * Modified By: GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
 *
 * USAGE:   Validate phase code using bspJCVPhase, then get phase
 *			pricing if needed. Used in MSTicEntry
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
 *	@unitprice 		Unit Price override
 *	@ecm 			ECM override
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
 @pricetemplate smallint = null, @saledate bDate = null,
 @unitprice bUnitCost = null output, @ecm bECM = null output, @minamt bDollar = null output,
 @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @retcode int, @category varchar(10), @tmpmsg varchar(255), @pphase bPhase,
   		@priceopt tinyint, @MatlVendor bVendor, @VendorGroup bGroup

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

---- get IN company job pricing options
select @priceopt=JobPriceOpt from INCO with (nolock) where INCo=@msco
if @@rowcount = 0
	begin
	select @msg = 'Unable to get IN Company parameters', @rcode = 1
	goto bspexit
	end

---- get material unit price defaults.
exec @retcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @material, @locgroup, @fromloc, @matlum,
           @quote, @pricetemplate, @saledate, @jcco, @job, null, null, null, null, @priceopt, 'J',
           @phasegroup, @phase, @MatlVendor, @VendorGroup, 
		   @unitprice output, @ecm output, @minamt output, @tmpmsg output
if @retcode <> 0
	begin
	select @unitprice = 0, @ecm = 'E', @minamt = 0
	end



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicMatlPhaseVal] TO [public]
GO
