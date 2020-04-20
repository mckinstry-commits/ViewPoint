SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCBValINInsert     ******/
   
CREATE  procedure [dbo].[bspJCCBValINInsert]
/***********************************************************
* CREATED BY:	DANF 03/20/00
* MODIFIED By:	TV - 23061 added isnulls
*				CHS 04/29/2009	- #131939
*
* USAGE:
* Called from bspJCCBVal to update/insert IN distributions
* into bJCIN for an JC Cost Adjustment Entry batch.
*
* INPUT PARAMETERS:
*  @jcco                   JC Company
*  @mth                    Batch month
*  @batchid                Batch ID#
*  @inco                   Posted To IN Co#
*  @loc                    Equipment
*  @matlgroup              Material Group
*  @matl                   Material
*  @batchseq               Batch sequence
*  @oldnew                 0 = old, 1 = new
*  @job                    Job
*  @phasegroup             Phase Group
*  @phase                  Phase
*  @costtype               Cost Type
*  @actualdate             Actual Date
*  @desc                   description
*  @glco                   IN GL Co#
*  @glacct                 Inventroy GL Account
*  @pstum                  Posted unit of measure
*  @pstunits               Posted units
*  @pstunitcost            Posted Unit Cost
*  @pstecm                 Posted Unit Cost per E, C, or M
*  @psttotal               Posted Total
*  @stdum                  Standard unit of measure
*  @stdunits               Standard units - converted from posted units
*  @stdunitcost            Standard Unit Cost
*  @stdecm                 Standard Unit Cost per E, C, or M
*  @stdtotalcost           Standard Total Cost
*
* OUTPUT PARAMETERS
*  none
*
* RETURN VALUE
*  0                       success
*  1                       failure
*****************************************************/
@jcco bCompany, @mth bMonth, @batchid bBatchID, @inco bCompany, @loc bLoc,
@matlgroup bGroup, @matl bMatl, @batchseq int, @oldnew tinyint,
@job bJob, @phasegroup bGroup, @phase bPhase, @cttype bJCCType,
@acutaldate bDate, @desc bItemDesc, @glco bCompany, @glacct bGLAcct,
@pstum bUM, @pstunits bUnits, @inpstunitcost bUnitCost, @pstecm bECM, @inpsttotal bDollar,
@stdum bUM, @stdunits bUnits, @stdunitcost bUnitCost, @stdecm bECM, @stdtotalcost bDollar,
@pstunitcost bUnitCost, @psttotal bDollar
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- update JC IN Distributions
   update bJCIN
   set  StdTotalCost = @stdtotalcost
   where JCCo = @jcco and Mth = @mth and BatchId = @batchid and INCo = @inco and Loc = @loc
       and MatlGroup = @matlgroup and Material = @matl and BatchSeq = @batchseq
       and OldNew = @oldnew
   if @@rowcount = 0
	begin
       insert bJCIN
       values( @jcco, @mth, @batchid, @inco, @loc,
     @matlgroup, @matl, @batchseq, @oldnew,
     @job, @phasegroup, @phase, @cttype,
     @acutaldate, @desc, @glco, @glacct,
     @pstum, @pstunits, @inpstunitcost, @pstecm, @inpsttotal,
     @stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost,
     @pstunitcost, @psttotal )
	end
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCBValINInsert] TO [public]
GO
