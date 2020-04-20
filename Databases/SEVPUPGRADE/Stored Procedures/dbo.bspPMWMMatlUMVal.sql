SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE    proc [dbo].[bspPMWMMatlUMVal]
/*************************************
   * Created By:   GF 07/26/2004
   * Modified By:	GF 05/26/2005 - #27996 6.x changes
   *
   * validates UM for material import records. If Material Code not empty then UM must be
   * HQUM.UM, HQMT.StdUM, HQMT.MetricUM, HQMT.SalesUM, HQMU.UM
   *
   * Pass:
   * PM Company
   * HQ MatlGroup
   * PM Material
   * PM Material UM
   *
   * Success returns:
   *	0 and Description from bHQUM
   *
   * Error returns:
   *	1 and error message
   **************************************/
(@pmco bCompany = null, @matlgroup bGroup = null, @material bMatl = null, @um bUM = null, 
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @stdum bUM, @salesum bUM, @metricum bUM

select @rcode = 0

if @pmco is null
       begin
       select @msg = 'Missing MS Company!', @rcode = 1
       goto bspexit
       end

if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end

if @um is null
       begin
       select @msg = 'Missing Unit of measure!', @rcode=1
       goto bspexit
       end

------ validate to HQUM
select @msg=Description from HQUM with (nolock) where UM=@um
if @@rowcount=0
	begin
	select @msg = 'Invalid Unit of measure!', @rcode = 1
	goto bspexit
	end

if isnull(@material,'') = '' goto bspexit

------ get UM's from HQMT
select @stdum=StdUM, @salesum=SalesUM, @metricum=MetricUM
from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0
   	begin
   	select @msg = 'Invalid material!', @rcode=1
   	goto bspexit
   	end

------ done if material UM = one of HQMT UM's
if @um = @stdum goto bspexit
if @um = @salesum goto bspexit
if @um = @metricum goto bspexit

------ check HQMU for material um
select @validcnt = count(*)
from HQMU with (nolock) where MatlGroup=@matlgroup and Material=@material and UM=@um
if @validcnt = 0
	begin
   	select @msg = 'Invalid unit of measure, not standard or in HQMU!', @rcode=1
   	goto bspexit
   	end



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWMMatlUMVal] TO [public]
GO
