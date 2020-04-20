SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************/
CREATE  proc [dbo].[bspMSTicMatlPhaseGet]
/*************************************
 * Created By:   GF 07/06/2000
 * Modified By:
 *
 * USAGE:   Called from other MSTicEntry SP to get default phase and cost type.
 *
 *
 * INPUT PARAMETERS
 *  MS Company, MatlGroup, Material, Category, LocGroup, FromLoc, PhaseGroup, Quote
 *
 * OUTPUT PARAMETERS
 *  MatlPhase   Material Phase
 *  MatlCT      Material Cost Type
 *  HaulPhase   Haul Phase
 *  HaulCT      Haul Cost Type
 *  @msg        error message if error occurs
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *
 **************************************/
(@msco bCompany = null, @matlgroup bGroup = null, @material bMatl = null,
 @category varchar(10) = null, @locgroup bGroup = null, @fromloc bLoc = null,
 @phasegroup bGroup = null, @quote varchar(10) = null, @matlphase bPhase output,
 @matlct bJCCType output, @haulphase bPhase output, @haulct bJCCType output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0

if @msco is null
       begin
       select @msg = 'Missing MS Company', @rcode = 1
       goto bspexit
       end

if @locgroup is null
   	begin
   	select @msg = 'Missing From Location Group', @rcode = 1
   	goto bspexit
   	end

if @matlgroup is null
       begin
       select @msg = 'Missing Material Group', @rcode = 1
       goto bspexit
       end

if @phasegroup is null
       begin
       select @msg = 'Missing Phase Group', @rcode = 1
       goto bspexit
       end

if @category is null
   	begin
   	select @msg = 'Missing Material Category', @rcode = 1
   	goto bspexit
   	end

---- get phase and cost type from MSJP
if @quote is not null
   BEGIN
       -- only search levels 1-2 if from location is not null
       if @fromloc is not null
       BEGIN
           -- first level
           if @material is not null
               begin
               select @matlphase=MatlPhase, @matlct=MatlCostType, @haulphase=HaulPhase, @haulct=HaulCostType
               from bMSJP with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
               and MatlGroup=@matlgroup and Category=@category and Material=@material and PhaseGroup=@phasegroup
               if @@rowcount <> 0 goto bspexit
               end
           -- second level
           select @matlphase=MatlPhase, @matlct=MatlCostType, @haulphase=HaulPhase, @haulct=HaulCostType
           from bMSJP with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@fromloc
           and MatlGroup=@matlgroup and Category=@category and Material is null and PhaseGroup=@phasegroup
           if @@rowcount <> 0 goto bspexit
       END
       -- third level
       if @material is not null
           begin
           select @matlphase=MatlPhase, @matlct=MatlCostType, @haulphase=HaulPhase, @haulct=HaulCostType
           from bMSJP with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
           and MatlGroup=@matlgroup and Category=@category and Material=@material and PhaseGroup=@phasegroup
           if @@rowcount <> 0 goto bspexit
           end
       -- fourth level
       select @matlphase=MatlPhase, @matlct=MatlCostType, @haulphase=HaulPhase, @haulct=HaulCostType
       from bMSJP with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc is null
       and MatlGroup=@matlgroup and Category=@category and Material is null and PhaseGroup=@phasegroup
       if @@rowcount =0 select @rcode = 1
   END




bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicMatlPhaseGet] TO [public]
GO
