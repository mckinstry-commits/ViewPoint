SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspEMPost_Cost_DetailInsert_IN]
    /***********************************************************
     * CREATED BY: DANF 06/26/00
     * MODIFIED BY: TV 02/11/04 - 23061 added isnulls
	 *				GP 11/25/08 - 131227, increased description param to 60 char.
	*				TRL 02/04/2010 Issue 137916  change @description to 60 characters  
	*				GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
	*
     *
     * USAGE: Called from the bspPost_Main procedure to post IN distributions
     *	tracked in bEMIN.
     *
     * Interface levels:
     *	0      No update of actual units or costs but will still update
     *         onorder and received n/invcd units to INMT
     *	1      Interface at the transaction line level.  Each line on an invoice
     *		   creates a bINDT entry.
     *
     * INPUT PARAMETERS
     *	@co			    EM Co#
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
    
    declare @emco bCompany, @inco bCompany, @inlocation bLoc, @matlgroup bGroup, @material bMatl,@batchseq int, @oldnew tinyint,
            @actualdate bDate, @description bItemDesc, @wo bWO, @woitem bItem, @equipment bEquip, @emgroup bGroup,
            @costcode bCostCode, @emcosttype bEMCType, @comptype varchar(10), @component bEquip,
            @glco bCompany, @glacct bGLAcct, @pstum bUM, @pstunits bUnits, @pstunitcost bUnitCost, @pstecm bECM, @pstcost bDollar,
            @stdum bUM, @stdunits bUnits, @stdunitcost bUnitCost, @stdecm bECM, @stdtotalcost bDollar, @ininterfacelvl tinyint,
    	    @openEMINcursor tinyint, @rcode int, @seq int, @totalcost bDollar, @ecm bECM,
            @intrans bTrans, @transdesc bItemDesc/*137916*/, @um bUM, @unitcost bUnitCost, @units bUnits, @unitprice bUnitCost, @totalprice bDollar,
            @emtrans bTrans, @msg varchar(255)
    select @rcode = 0
    
    --declare cusrsor on EMIN
    declare EMIN_cursor cursor for
        select EMCo, Mth, BatchId, INCo, INLocation, MatlGroup,
    			Material, BatchSeq, OldNew, EMTrans, ActualDate, WO, WOItem, Equip, EMGroup,
    			CostCode, EMCType, CompType, Component, GLCo, GLAcct, Description,
    			PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
                StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost,
                UnitPrice, PECM, TotalPrice
        from bEMIN
        where EMCo = @co and Mth = @mth and BatchId = @batchid
    
        --open cursor
        open EMIN_cursor
        select @openEMINcursor = 1
    
        --loop through all the records
        EMIN_posting_loop:
    
            fetch next from EMIN_cursor into @emco, @mth, @batchid, @inco, @inlocation, @matlgroup,
    			@material, @batchseq, @oldnew, @emtrans, @actualdate, @wo, @woitem, @equipment, @emgroup,
    			@costcode, @emcosttype, @comptype, @component, @glco, @glacct, @description,
    			@pstum, @pstunits, @pstunitcost, @pstecm, @pstcost,
                @stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost,
                @unitprice, @ecm, @totalprice
    
            if @@fetch_status = -1 goto EMIN_posting_end
            if @@fetch_status <> 0 goto EMIN_posting_loop
    
            begin transaction
    
                --get next available transaction # for INDT
                exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @inco, @mth, @msg output
     	        if @intrans = 0
                    begin
       	            select @errmsg = 'Unable to update IN Detail.  ' + isnull(@msg,''), @rcode=1
                    goto EMIN_posting_error
           	        end
    
     			/* Insert Invertory EM Detail. */
    			insert bINDT (INCo, Mth, INTrans, Loc, MatlGroup,
                    Material, ActDate, PostedDate, Source, TransType,
                    EMCo, Equip, EMGroup, CostCode, EMCType, GLCo,
                    GLAcct, Description, WO, WOItem, CompType, Component,
                    PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
                    StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost,
            UnitPrice, PECM, TotalPrice, BatchId)
    			values (@inco, @mth, @intrans, @inlocation, @matlgroup,
                    @material, @actualdate,
                    ----#141031
                    dbo.vfDateOnly(), 'EM', 'EM Sale',
                    @co, @equipment, @emgroup, @costcode, @emcosttype, @glco,
                    @glacct, @description, @wo, @woitem, @comptype, @component,
                    @pstum, @pstunits, @pstunitcost, @pstecm, @pstcost,
                    @stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost,
                    @unitprice, @ecm, @totalprice, @batchid)
    
    
                if @@error <> 0 goto EMIN_posting_error
    
                --update to Onhand, LastUnitCost, LastECM LastCostUpdate, Average Unit Cost are done in INDT trigger
    
               --delete current row from cursor
    	       delete bEMIN
               where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and OldNew = @oldnew
               if @@rowcount <> 1
                 begin
     	         select @errmsg = 'Unable to remove posted distributions from EMIN.', @rcode = 1
      	         goto EMIN_posting_error
     	         end
   
            commit transaction
    
            goto EMIN_posting_loop
    
    EMIN_posting_error:
            rollback transaction
            goto bspexit
    
    EMIN_posting_end:
            close EMIN_cursor
            deallocate EMIN_cursor
            select @openEMINcursor = 0
    
    bspexit:
        if @openEMINcursor = 1
            begin
     		close EMIN_cursor
     		deallocate EMIN_cursor
     		end
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Cost_DetailInsert_IN] TO [public]
GO
