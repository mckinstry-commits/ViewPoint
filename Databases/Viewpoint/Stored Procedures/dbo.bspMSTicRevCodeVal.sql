SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE proc [dbo].[bspMSTicRevCodeVal]
/******************************************************
 * Created By:  GF  07/03/2000
 * Modified By: GG 01/24/01 -- initialized output parameters to null
 *      		RM 03/26/01 - Added input params and validation to base on Haul Code
 *              GF 04/17/2001 - use EM SP to get allow rate override flag for equipment
 *				GF 04/29/2003 - @rcode was returning 1 with no error message. problem was
 *								exec @rcode = bspEMRevRateUMDflt, s/b @retcode
 *
 * USAGE:   Validate EM Revenue Code entered in MS TicEntry and MS HaulEntry.
 *  Will also calculate the revenue basis to be used as the
 *  default in MS TicEntry and MS HaulEntry.
 *
 *
 * Input Parameters
 *  @msco           MS Company
 *	@emco		    EM Company
 * 	@emgroup	    EM Group
 *	@revcode	    Revenue code to validate
 *  @equipment      EM Equipment
 *  @category       EM Equipment Category
 *  @jcco           JC Company
 *  @job            JC Job
 *  @matlgroup      Material Group
 *  @material       Material
 *  @fromloc        From Location
 *  @units          Material units sold
 *  @umconv         Material U/M conversion factor to Std U/M
 *  @hours          Hours
 *
 * Output Parameters
 *  @revbasisamt    Default EM Revenue Basis
 *  @rate           Default Revenue Rate
 *  @basis          Revenue Basis Type (U,H)
 *	@basistooltip   Description explaining the make-up of the revenue basis
 *  @totaltooltip   Description including revenue rate
 *  @allowrateoride Flag to indicate whether revenue rate can be overridden
 *	@msg            Revenue Code description from EMRC or error message
 *
 * Return Value
 *  0	success
 *  1	failure
 ***************************************************/
(@msco bCompany = null, @emco bCompany = null, @emgroup bGroup = null, @revcode bRevCode = null,
 @equipment bEquip = null, @category bCat = null, @jcco bCompany = null, @job bJob = null,
 @matlgroup bGroup = null, @material bMatl = null, @fromloc bLoc = null, @units bUnits = 0,
 @umconv bUnitCost = 0, @hours bHrs = 0, @revbasisamt bUnits = null output, @rate bDollar = null output,
 @basis char(1) = null output, @basistooltip varchar(255) = null output, @totaltooltip varchar(255) = null output,
 @haulcode bHaulCode = null, @haulbased bYN = null output, @haulum bUM = null, @allowrateoride bYN = null output,
 @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @retcode int, @transtype varchar(10), @time_um bUM, @hrspertime bHrs,
		@work_um bUM, @hqstdum bUM, @workumconv bUnitCost, @stdum bUM, @tmpmsg varchar(255),
		@revbased bYN, @haulbasis tinyint, @revum bUM, @postworkunits bYN, @rev_basis char(1),
		@hrfactor bHrs, @lockphases bYN, @rev_msg varchar(60), @job_msg varchar(60), @updatehrs bYN

select @rcode = 0, @transtype = 'X', @allowrateoride = 'Y'

if @msco is null
     	begin
     	select @msg = 'Missing MS company.', @rcode = 1
     	goto bspexit
     	end
if @emco is null
     	begin
     	select @msg = 'Missing EM company.', @rcode = 1
     	goto bspexit
     	end
if @emgroup is null
        begin
        select @msg = 'Missing EM Group', @rcode = 1
        goto bspexit
        end
if @revcode is null
     	begin
     	select @msg = 'Missing Revenue code', @rcode = 1
     	goto bspexit
     	end

if @jcco is not null and @job is not null
	begin
	select @transtype = 'J'
	end

---- get material info
if @matlgroup is not null and @material is not null
	begin
	select @hqstdum = StdUM
	from HQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
	if @@rowcount = 0 select @hqstdum = null
	end
else
	begin
	select @hqstdum = null
	end

---- validate Revenue Code
select @msg = Description, @hrspertime = HrsPerTimeUM, @basis = Basis,
		@haulbased=HaulBased, @revum=WorkUM
from EMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode
if @@rowcount = 0
	begin
	select @msg = 'Revenue code not set up.', @rcode = 1
	goto bspexit
	end

if @hrspertime is null select @hrspertime = 0

---- get EM Rate and UM
exec @retcode = dbo.bspEMRevRateUMDflt @emco,@emgroup,@transtype,@equipment,@category,@revcode,
						@jcco,@job,@rate output, @time_um output, @work_um output, @tmpmsg output

if @rate is null select @rate = 0

---- validate revenue code and/or the job and retrieve some important usage flags
exec @retcode = dbo.bspEMUsageFlagsGet @emco, @emgroup, @transtype, @equipment, @category, @revcode,
						@jcco, @job,@postworkunits output, @allowrateoride output, @rev_basis output,
						@hrfactor output, @lockphases output, @rev_msg output, @job_msg output,
						@updatehrs output, @tmpmsg output
if @retcode <> 0 or @allowrateoride is null select @allowrateoride = 'Y'

select @totaltooltip = 'Revenue Rate is ' + convert(varchar(12),@rate)

---- calculate revenue basis value for (H)ours type basis
if @basis = 'H'
	begin
	if @hrspertime <> 0
		select @revbasisamt = @hours/@hrspertime
	else
		select @revbasisamt = 0

	---- set tooltip
	select @basistooltip = 'Revenue Basis is Hours:  Time UM is ' + @time_um
	select @basistooltip = @basistooltip + ':  Hours Per Time is ' + convert(varchar(12),@hrspertime)
	select @basistooltip = @basistooltip + ':  Calculated Basis is ' + convert(varchar(12),@revbasisamt)
	if @haulbased <> 'Y' goto bspexit
	end

---- get work um conversion factor
if @work_um is null or @material is null
	begin
	select @workumconv = 0
	end
else
	if @work_um=@hqstdum
		begin
		select @workumconv = 1
		end
	else
		begin
		select @workumconv=Conversion from INMU with (nolock) 
		where MatlGroup=@matlgroup and INCo=@msco and Material=@material and Loc=@fromloc and UM=@work_um
		if @@rowcount = 0
			begin
			exec @retcode = bspHQStdUMGet @matlgroup,@material,@work_um,@workumconv output,@stdum output,@tmpmsg output
			end
		end

	select  @haulbasis=HaulBasis,@revbased = RevBased
    from MSHC with (nolock) where MSCo=@msco and HaulCode=@haulcode

	if @haulbased = 'Y'
		begin
		if @revbased = 'Y'
			begin
			select @rcode = 1,@msg = 'Cannot Use Rev Code based on Haul Code while Haul Code is based on Rev Code.'
			goto bspexit
			end

		if @haulbasis in (3,4,5)
			begin
			select @haulum = UM from MSHC with (nolock) where MSCo = @msco and HaulCode = @haulcode
			end

		if ((@haulbasis in (1,3,4,5) and @basis <> 'U') or (@haulbasis= 2 and @basis <> 'H')) and @basis is not null
			begin
			select @rcode = 1,@msg = 'When using a RevCode that is based on the Haul Code, the basis must be the same.'
			goto bspexit
			end

		if  @haulbasis <> 2 and @revum <> isnull(@haulum,@revum)
			begin
			select @rcode = 1,@msg = 'When using a Rev Code that is based on the Haul Code, the UM must be the same.'
			goto bspexit
			end

		if @basis = 'H' goto bspexit
		end

	---- calculate revenue basis value for (U)nits type basis
    if @umconv is null select @umconv = 0
    if @workumconv is null select @workumconv = 0

	if @workumconv <> 0
        select @revbasisamt = @units*@umconv/@workumconv
    else
        select @revbasisamt = 0

	---- set tooltip
    select @basistooltip = 'Revenue Basis is Units:  Work UM is ' + @work_um
    select @basistooltip = @basistooltip + ':  Work Conversion is ' + convert(varchar(14),@workumconv)
    select @basistooltip = @basistooltip + ':  Calculated Basis is ' + convert(varchar(12),@revbasisamt)



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicRevCodeVal] TO [public]
GO
