SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspMSJPMaterialVal]
/*************************************
 * Created By:	GF 12/21/2005
 * Modified By:	
 *
 * validates Category and Material to HQMT.Material
 *
 * Pass:
 * MatlGroup,PhaseGroup,Category,Material
 *
 * Success returns:
 * Standard Matl Phase from HQMT
 * Standard Matl CT from HQMT
 * Standard Haul Phase fromHQMT
 * Standard Haul CT from HQMT
 *0 and Description from bHQMT
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@matlgroup bGroup = null, @phasegroup bGroup = null, @category varchar(10) = null, @material bMatl = null,
 @stdmatlphase bPhase = null output, @stdmatlct bJCCType = null output,
 @stdhaulphase bPhase = null output, @stdhaulct bJCCType = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @hqmtcat varchar(10), @matlphase bPhase,
		@haulphase bPhase, @matlct bJCCType, @haulct bJCCType, @stddesc bItemDesc

select @rcode=0

if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end

if @category is null
	begin
	select @msg = 'Missing Material Category!', @rcode = 1
	goto bspexit
	end

if @material = ''
   	begin
   	select @msg = 'Missing Material!', @rcode = 1
   	goto bspexit
   	end

if @material is null goto bspexit

if @phasegroup is null
       begin
       select @msg = 'Missing Phase Group!', @rcode=1
       goto bspexit
       end

select @validcnt = Count(*) from bHQMC with (nolock) where MatlGroup=@matlgroup and Category=@category
if @validcnt = 0
	begin
	select @msg = 'Invalid Material Category!', @rcode=1
	goto bspexit
	end

select @hqmtcat=Category, @msg=Description, @stdmatlphase=MatlPhase,
		@stdmatlct=MatlJCCostType, @stdhaulphase=HaulPhase, @stdhaulct=HaulJCCostType
from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0
	begin
	select @msg = 'Invalid Material!', @rcode = 1
	goto bspexit
	end
if @hqmtcat <> @category
	begin
	select @msg = 'Material not set up for this Material Category!', @rcode=1
	goto bspexit
	end


-- -- --    if @matlphase is not null
-- -- --        begin
-- -- --        select @stddesc=Description
-- -- --        from bJCPM where PhaseGroup=@phasegroup and Phase=@matlphase
-- -- --        if @@rowcount <> 0
-- -- --            select @stdmatlphase=@matlphase + '  ' + isnull(@stddesc,'')
-- -- --        end
-- -- --    
-- -- --    if @matlct is not null
-- -- --        begin
-- -- --        select @stddesc=Description
-- -- --        from bJCCT where PhaseGroup=@phasegroup and CostType=@matlct
-- -- --        if @@rowcount <> 0
-- -- --            select @stdmatlct=convert(varchar(3),@matlct) + ' - ' + isnull(@stddesc,'')
-- -- --        end
-- -- --    
-- -- --    if @haulphase is not null
-- -- --        begin
-- -- --        select @stddesc=Description
-- -- --        from bJCPM where PhaseGroup=@phasegroup and Phase=@haulphase
-- -- --        if @@rowcount <> 0
-- -- --            select @stdhaulphase=@haulphase + '  ' + @stddesc
-- -- --        end
-- -- --    
-- -- --    if @haulct is not null
-- -- --        begin
-- -- --        select @stddesc=Description
-- -- --        from bJCCT where PhaseGroup=@phasegroup and CostType=@haulct
-- -- --        if @@rowcount <> 0
-- -- --            select @stdhaulct=convert(varchar(3),@haulct) + ' - ' + isnull(@stddesc,'')
-- -- --        end





bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSJPMaterialVal] TO [public]
GO
