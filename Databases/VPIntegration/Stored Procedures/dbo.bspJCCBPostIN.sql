SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspJCCBPostIN]
   /***********************************************************
    * CREATED BY: DANF 03/21/00
    *             Modified 06/21/00 Change IN source to JC
    *             Modified to always update IN....
    *				TV - 23061 added isnulls
	*				GP 11/25/08 - 131227, increased description param to 60 char.
    *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *
    * USAGE: Called from the bspJCCBPost procedure to post IN distributions
    *	tracked in bJCIN.  Interface level to IN is assigned in bJCCO.
    *
    * Interface levels:
    *	0      No update of actual units or costs but will still update
    *         onorder and received n/invcd units to INMT
    *	1      Interface at the transaction line level.  Each line on an invoice
    *		   creates a bINDT entry.
    *
    * INPUT PARAMETERS
    *	@co			    JC Co#
    *	@mth			Batch month
    *	@batchid		Batch ID#
    *	@dateposted	    Posting date
    *
    * OUTPUT PARAMETERS
    *	@errmsg		    Message used for errors
    *
    * RETURN VALUE
    *	0	success
    *	1	fail
    *****************************************************/
   
   (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
   	@errmsg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @inco bCompany, @loc bLoc, @matlgroup bGroup, @material bMatl,@batchseq int, @oldnew tinyint,
           @job bJob, @phasegroup bGroup, @phase bPhase, @costtype bJCCType, @actualdate bDate, @desc bItemDesc,
           @glco bCompany, @glacct bGLAcct, @pstum bUM, @pstunits bUnits, @pstunitcost bUnitCost, @pstecm bECM, @psttotal bDollar,
           @stdum bUM, @stdunits bUnits, @stdunitcost bUnitCost, @stdecm bECM, @stdtotalcost bDollar, @ininterfacelvl tinyint,
   	    @openJCINcursor tinyint, @po varchar(30), @poitem bItem, @rcode int, @seq int, @totalcost bDollar,
           @intrans bTrans, @transdesc bDesc, @um bUM, @unitcost bUnitCost, @units bUnits, @unitprice bUnitCost, @totalprice bDollar,
           @msg varchar(255)
   select @rcode = 0
   
   --get IN interface level
   select @ininterfacelvl = 1
   --select @ininterfacelvl = GLMaterialLevel from bJCCO where JCCo = @co
   
   --declare cusrsor on JCIN
   declare JCIN_cursor cursor for
       select INCo, Loc, MatlGroup, Material, BatchSeq, OldNew,
              Job, PhaseGroup, Phase, CostType, ActualDate, Description,
              GLCo, GLAcct, PstUM, PstUnits, PstUnitCost, PstECM, PstTotal,
              StdUM, StdUnits, StdUnitCost, StdECM, StdTotalCost, UnitPrice, TotalPrice
       from bJCIN
       where JCCo = @co and Mth = @mth and BatchId = @batchid
   
       --open cursor
       open JCIN_cursor
       select @openJCINcursor = 1
   
       --loop through all the records
       JCIN_posting_loop:
   
           fetch next from JCIN_cursor into @inco, @loc, @matlgroup, @material, @batchseq, @oldnew,
           @job, @phasegroup, @phase, @costtype, @actualdate, @desc,
           @glco, @glacct, @pstum, @pstunits, @pstunitcost, @pstecm, @psttotal,
           @stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost, @unitprice, @totalprice
   
           if @@fetch_status = -1 goto JCIN_posting_end
           if @@fetch_status <> 0 goto JCIN_posting_loop
   
           begin transaction
   
           -- IN Interface Level 0 no updates to actuals but updates to On Order and Received not Invoiced units
           -- which is done below for interface level 0 and 1
   
           if (@stdunits <> 0 or @stdtotalcost <> 0) and @ininterfacelvl >0
               begin
   
               --get next available transaction # for INDT
               exec @intrans = bspHQTCNextTrans 'bINDT', @inco, @mth, @msg output
    	        if @intrans = 0
                   begin
      	            select @errmsg = 'Unable to update IN Detail.  ' + @msg, @rcode=1
                   goto JCIN_posting_error
          	        end
   
               --add IN Detail entry
               insert bINDT (INCo, Mth, INTrans, BatchId, MatlGroup, Loc, Material,
         	        PostedDate, ActDate, Source, TransType,  Description,
                   GLCo, GLAcct, JCCo, Job, PhaseGroup, Phase, JCCType,
                   PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
                   StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
                   PECM, TotalPrice)
   	        values (@inco, @mth, @intrans, @batchid, @matlgroup, @loc, @material,
               	@dateposted, @actualdate, 'JC', 'JC Sale', @desc,
                   @glco, @glacct, @co, @job, @phasegroup, @phase, @costtype,
                   @pstum, @pstunits, @pstunitcost, @pstecm, @psttotal,
                   @stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost, @unitprice,
                   @pstecm, @totalprice)
   
               if @@error <> 0 goto JCIN_posting_error
   
               --update to Onhand, LastUnitCost, LastECM LastCostUpdate, Average Unit Cost are done in INDT trigger
   
               end   --end of interface level 1
   
              --delete current row from cursor
   	       delete bJCIN
              where JCCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and OldNew = @oldnew
              if @@rowcount <> 1
                begin
    	         select @errmsg = 'Unable to remove posted distributions from JCIN.', @rcode = 1
     	         goto JCIN_posting_error
    	         end
   
           commit transaction
   
           goto JCIN_posting_loop
   
   JCIN_posting_error:
           rollback transaction
           goto bspexit
   
   JCIN_posting_end:
           close JCIN_cursor
           deallocate JCIN_cursor
           select @openJCINcursor = 0
   
   bspexit:
       if @openJCINcursor = 1
           begin
    		close JCIN_cursor
    		deallocate JCIN_cursor
    		end
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCBPostIN] TO [public]
GO
