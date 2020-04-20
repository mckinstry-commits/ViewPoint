SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPORBExpValJob    Script Date: 8/28/99 9:36:01 AM ******/
   CREATE  procedure [dbo].[bspPORBExpValJob]
   /*********************************************
    * Created: DANF 04/23/01
    * Modified: DANF 09/05/02 - 17738 Added PhaseGroup
    *
    * Usage:
    *  Called from the PO Receiving Batch validation procedure (bspPORBVal)
    *  to validate Job information.
    *
    * Input:
    *  @jcco       JC Co# - Job item
    *  @phasegroup Phase Group
    *  @job        Job
    *  @phase      Phase
    *  @jcctype    JC Cost Type
    *  @matlgroup  Material Group
    *  @material   Material
    *  @um         Posted unit of measure
    *  @units      Posted units
    *
    * Output:
    *  @jcum       Unit of Measure tracked for the Job, Phase, and Cost Type
    *  @jcunits    Units expressed in JC unit of measure.  0.00 if not convertable.
    *  @msg        Error message
    *
    * Return:
    *  0           success
    *  1           error
    *************************************************/
   
       @jcco bCompany, @phasegroup bGroup, @job bJob, @phase bPhase, @jcctype bJCCType, @matlgroup bGroup,
       @material bMatl, @um bUM, @units bUnits, @jcum bUM output, @jcunits bUnits output,
       @msg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int, @umconv bUnitCost, @stdum bUM, @jcumconv bUnitCost
   
   select @rcode = 0, @jcunits = 0
   
   -- validate Job, Phase, and Cost Type, get JC unit of measure
   exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @phase, @jcctype, @jcum output, @msg output
   if @rcode <> 0 goto bspexit
   
   -- if JC unit of measure equals posted unit of measure, set JC units eqaul to posted
   if @jcum = @um
       begin
       select @jcunits = @units
       goto bspexit
       end
   
   if @matlgroup is null or @material is null or @units = 0 goto bspexit
   
   -- get conversion for posted unit of measure
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto bspexit
   
   -- get conversion for JC unit of measure
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @stdum output, @msg output
   if @rcode <> 0 goto bspexit
   
   if @jcumconv <> 0 select @jcunits = @units * (@umconv / @jcumconv)
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPORBExpValJob] TO [public]
GO
