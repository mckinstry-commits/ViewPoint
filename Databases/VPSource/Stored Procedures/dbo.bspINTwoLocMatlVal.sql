SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspINTwoLocMatlVal]
   /***********************************************************************************
   * Created By:	ae 12/23/99
   * Modified by:	Gr 03/07/00 clean up  and added outputs pararms to return costmethod
   *				ae 5/15/00 Fixed Issue 7031
   *				GP 05/06/09 - Modifed @descrip bItemDesc
   *
   * validates Material stocked at the 'To' and 'From' Location in IN Materital(INMT)
   * Used by Transfer Program
   * Pass:
   *	@inco           IN Company
   *   @ToLoc          IN Location
   *   @FromLoc        IN Location
   *   @matlgrp        Material Group
   *   @material       Material
   *   @activeopt      Active option - Y = must be active, N = may be inactive
   *
   * Success returns:
   *	0
   *   UM           Std Unit of Measure
   *   Description  Description from HQMT
   *   OnHand, UnitCost and ECM for To and From Locations
   *
   * Error returns:
   *	1 and error message
   ************************************************************************************/
   	(@inco bCompany = null,  @FromLoc bLoc = null, @ToLoc bLoc = null,
       @matlgrp bGroup = null, @material bMatl = null,
       @activeopt bYN = null, @um bUM output,
       @fromonhand bUnits output, @fromunitcost bUnitCost output, @fromecm bECM output,
       @toonhand bUnits output, @tounitcost bUnitCost output, @toecm bECM output, @descrip bItemDesc output,
       @fromcostmethod int output, @tocostmethod int output, @msg varchar(256) output)
   as
   	set nocount on
   	declare @rcode int, @active bYN,  @locgroup bGroup, @validcnt int, @category varchar(10)
   
	select @rcode = 0,  @fromunitcost=0, @fromcostmethod=0, @fromonhand=0, 
		@tounitcost=0, @tocostmethod=0,  @toonhand=0
   
   if @inco is null
       begin
       select @msg='Missing IN Company', @rcode=1
       goto bspexit
       end
   
   if @ToLoc is null
       begin
       select @msg='Missing To Location', @rcode=1
       goto bspexit
       end
   
   if @FromLoc is null
       begin
       select @msg='Missing From Location', @rcode=1
       goto bspexit
       end
   
   if @matlgrp is null
       begin
       select @msg='Missing Material Group', @rcode=1
       goto bspexit
       end
   
   if @material is null
       begin
       select @msg='Missing Material', @rcode=1
       goto bspexit
       end
   
   if @activeopt is null
       begin
       select @msg = 'Missing Active Option', @rcode = 1
       goto bspexit
       end
   
   --Get HQMT defaults
   select @msg = Description, @descrip = Description, @um = StdUM, @category=Category
   from bHQMT where MatlGroup = @matlgrp and Material = @material
   
   --Get cost method for From Location
   select @fromcostmethod=CostMethod from bINLO
   where INCo=@inco and Loc=@FromLoc and MatlGroup=@matlgrp and Category=@category
   if @fromcostmethod is null or @fromcostmethod = 0
       begin
       select @fromcostmethod=CostMethod from bINLM
       where INCo=@inco and Loc=@FromLoc
       if @fromcostmethod is null or @fromcostmethod = 0
           begin
           select @fromcostmethod=CostMethod from bINCO
           where INCo=@inco
           end
       end
   
   --validate INMT
   select @active = Active, @fromonhand = IsNull(OnHand,0),
     @fromunitcost=case @fromcostmethod when 1 then AvgCost when 2 then LastCost else StdCost end,
     @fromecm=case @fromcostmethod when 1 then AvgECM when 2 then LastECM else StdECM end
   from bINMT
   where INCo = @inco and Loc = @FromLoc and Material=@material and MatlGroup=@matlgrp
   if @@rowcount = 0
       begin
       select @msg='Material not set up in the From IN Location Materials', @rcode=1
       goto bspexit
       end
   
   if @activeopt = 'Y' and @active = 'N'
       begin
       select @msg = 'Must be an active Material in From Location.', @rcode = 1
       goto bspexit
       end
   
   --Get cost method for To Location
   select @tocostmethod=CostMethod from bINLO
   where INCo=@inco and Loc=@ToLoc and MatlGroup=@matlgrp and Category=@category
   if @tocostmethod is null or @tocostmethod = 0
       begin
       select @tocostmethod=CostMethod from bINLM
       where INCo=@inco and Loc=@ToLoc
       if @tocostmethod is null or @tocostmethod = 0
           begin
           select @tocostmethod=CostMethod from bINCO
           where INCo=@inco
           end
       end
   
   --validate material in HQMT and INMT
   select @active = Active, @toonhand = IsNull(OnHand,0),
     @tounitcost=case @tocostmethod when 1 then AvgCost when 2 then LastCost else StdCost end,
     @toecm=case @tocostmethod when 1 then AvgECM when 2 then LastECM else StdECM end
   from bINMT
   where INCo = @inco and Loc = @ToLoc and Material=@material and MatlGroup=@matlgrp
   
   if @@rowcount = 0
       begin
       select @msg='Material not set up in the To IN Location Materials', @rcode=1
       goto bspexit
       end
   
   if @activeopt = 'Y' and @active = 'N'
       begin
       select @msg = 'Must be an active Material in To Location.', @rcode = 1
       goto bspexit
       end
   
   bspexit:
     --  if @rcode<>0 select @msg
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINTwoLocMatlVal] TO [public]
GO
