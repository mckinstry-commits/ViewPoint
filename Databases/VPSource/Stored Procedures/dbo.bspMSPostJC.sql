SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************/
CREATE procedure [dbo].[bspMSPostJC]
/***********************************************************
* Created: GG 10/28/00
* Modfied: GG 05/30/01 - added @@rowcount checks after bJCCD inserts
*          GF 07/05/2001 - Fixed bspexit, cursor name incorrect.
*          GF 10/08/2001 - Fixed delete statement, missing phase in where clause.
*			GF 08/01/2003 - issue #21933 - performance improvements
*			GF 12/03/2003 - issue #23139 - added CostTrans to MSJC for rowset update.
*			GF 05/02/2004 - issue #24418 - added EMGroup and RevCode to MSJC for rowset update.
*			GF 06/22/2004 - issue #24806 - if posted um is null use @jcum when insert into JCCD.
*			GG 07/20/07 - #30639 - include SaleDate in Summary level interface
*
*
* Called from the bspMSTBPost and bspMSHBPost procedures to post
* JC distributions tracked in bMSJC for both Ticket and Hauler Time
* Sheet batches.
*
* Sign on values in 'old' entries has already been reversed.
*
* JC Interface Levels:
*	0      No update
*	1      Summary - one entry per JCCo#/Job/Phase/CostType/Location/Material/SaleDate/GLCo/GLAcct/UM/TaxCode/TaxType
*	2      Full detail - JCCo/Job/Phase/JCCT/Location/Material/BatchSeq/OldNew
*
* INPUT PARAMETERS
*	@co			    MS/IN Co#
*	@mth			Batch month
*	@batchid		Batch ID#
*	@dateposted	    Posting date
*
* OUTPUT PARAMETERS
*	@errmsg		    Message used for errors
*
* RETURN VALUE
*	0 = success, 1 = fail
*****************************************************/
    (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int, @jcinterfacelvl tinyint, @openMSJC tinyint, @jcco bCompany, @job bJob, @phasegroup bGroup,
    		@phase bPhase, @jcct bJCCType, @fromloc bLoc, @matlgroup bGroup, @material bMatl, @glco bCompany,
    		@glacct bGLAcct, @um bUM, @jcum bUM, @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint,
    		@hrs bHrs, @units bUnits, @amount bDollar, @jcunits bUnits, @taxbasis bDollar, @taxtotal bDollar,
    		@description bDesc, @unitcost bUnitCost, @jcunitcost bUnitCost, @jctrans bTrans, @msg varchar(255),
    		@seq int, @oldnew tinyint, @mstrans bTrans, @ticket bTic, @saledate bDate, @vendorgroup bGroup,
    		@vendor bVendor, @ecm bECM, @emco bCompany, @equipment bEquip, @prco bCompany, @employee bEmployee,
    		@haulline smallint, @msjc_count bTrans, @msjc_trans bTrans, @emgroup bGroup, @revcode bRevCode
    
    select @rcode = 0, @openMSJC = 0
    
    --get IN interface level
    select @jcinterfacelvl = JCInterfaceLvl
    from bMSCO with (nolock) where MSCo = @co
    if @@rowcount <> 1
        begin
        select @errmsg = 'Invalid MS Co#', @rcode = 1
        goto bspexit
        end
    if @jcinterfacelvl not in (0,1,2)
        begin
        select @errmsg = 'Invalid JC Interface level assigned in MS Company.', @rcode = 1
        goto bspexit
        end
    
    -- Post Job Cost distributions 
    
    -- No update to JC
    if @jcinterfacelvl = 0
        begin
        delete bMSJC where MSCo = @co and Mth = @mth and BatchId = @batchid
        goto MSJC_posting_end
     	end
    --#30639 - added SaleDate to summary interface level
    -- Summary update to JC - one entry per JCCo#/Job/Phase/CostType/Location/Material/SaleDate/GLCo/GLAcct/UM/TaxCode/TaxType
    if @jcinterfacelvl = 1
        begin
        -- use summary level cursor on MS JC Distributions
        declare bcMSJC cursor LOCAL FAST_FORWARD for
        select JCCo, Job, PhaseGroup, Phase, JCCType, FromLoc, MatlGroup, Material, SaleDate, GLCo, GLAcct, UM, JCUM,
            TaxGroup, TaxCode, TaxType, convert(numeric(10,2),sum(Hrs)), convert(numeric(12,3),sum(Units)),
            convert(numeric(12,2),sum(Amount)), convert(numeric(12,3),sum(JCUnits)),
            convert(numeric(12,2),sum(TaxBasis)), convert(numeric(12,2),sum(TaxTotal))
     	from bMSJC
        where MSCo = @co and Mth = @mth and BatchId = @batchid
     	group by JCCo, Job, PhaseGroup, Phase, JCCType, FromLoc, MatlGroup, Material, SaleDate, GLCo, GLAcct, UM, JCUM,
            TaxGroup, TaxCode, TaxType
    
        --open cursor
        open bcMSJC
        select @openMSJC = 1
    
        MSJC_summary_loop:
            fetch next from bcMSJC into @jcco, @job, @phasegroup, @phase, @jcct, @fromloc, @matlgroup, @material,
                @saledate, @glco, @glacct, @um, @jcum, @taxgroup, @taxcode, @taxtype, @hrs, @units, @amount, @jcunits,
                @taxbasis, @taxtotal
    
            if @@fetch_status = -1 goto MSJC_posting_end
            if @@fetch_status <> 0 goto MSJC_summary_loop
    
    	   --check if hours are tracked
            if not exists(select top 1 1 from bJCCT with (nolock) where PhaseGroup = @phasegroup and CostType = @jcct and TrackHours = 'Y')
                select @hrs = 0 -- not tracking hours in this cost type
    
            --get Material description
            select @description = 'Material Sales'
            select @description = Description from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
    
			-- set JC units and unit cost
            select @unitcost = 0, @jcunitcost = 0
            if @units <> 0 select @unitcost = @amount / @units
            if @jcunits <> 0 select @jcunitcost = @amount / @jcunits
            if @jcunits is null select @jcunits = 0
            if @jcunitcost is null select @jcunitcost = 0
    
            begin transaction
    
            if @units <> 0 or @amount <> 0
                begin
                --get next available transaction # for INDT
                exec @jctrans = dbo.bspHQTCNextTrans 'bJCCD', @jcco, @mth, @msg output
     	        if @jctrans = 0
                    begin
       	            select @errmsg = 'Unable to update JC Cost Detail.  ' + isnull(@msg,''), @rcode = 1
                    goto MSJC_posting_error
           	        end
    
                --add JC Cost Detail entry
                insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
                    JCTransType, Source, Description, BatchId, GLCo, GLTransAcct, UM, ActualUnitCost,
                    PerECM, ActualHours, ActualUnits, ActualCost, PostedUM, PostedUnits, PostedUnitCost,
                    PostedECM, MatlGroup, Material, INCo, Loc, TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt)
                values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcct, @dateposted, @saledate,
                    'MS', 'MS Tickets', @description, @batchid, @glco, @glacct, @jcum, @jcunitcost, 'E', @hrs,
                    @jcunits, @amount, isnull(@um,@jcum), @units, @unitcost, 'E', @matlgroup, @material, @co, @fromloc,
                    @taxtype, @taxgroup, @taxcode, @taxbasis, @taxtotal)
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Unable to add JC Cost Detail entry', @rcode = 1
                	goto MSJC_posting_error
                	end
                end
    
            --delete distribution entries
    	    delete bMSJC
            where MSCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and PhaseGroup = @phasegroup
                and Phase = @phase and JCCType = @jcct and FromLoc = @fromloc and MatlGroup = @matlgroup
                and Material = @material and SaleDate = @saledate and GLCo = @glco and GLAcct = @glacct 
				and isnull(UM,'') = isnull(@um,'') and isnull(JCUM,'') = isnull(@jcum,'')
				and isnull(TaxGroup,0) = isnull(@taxgroup,0)
                and isnull(TaxCode,'') = isnull(@taxcode,'') and isnull(TaxType,0) = isnull(@taxtype,0)
    
            commit transaction
    
            goto MSJC_summary_loop
        end
    
    -- Detail update to JC - one entry per JCCo/Job/Phase/JCCT/Location/Material/BatchSeq/OldNew
    if @jcinterfacelvl = 2
        begin
    	-- delete MSJC distributions where Units and Amount equal zero. Not sent to JCCD.
    	delete bMSJC where MSCo = @co and Mth = @mth and BatchId = @batchid and Units = 0 and Amount = 0
   
        -- use detail level cursor on MS JC Distributions
        declare bcMSJC cursor LOCAL FAST_FORWARD for
        select JCCo, Job, PhaseGroup, Phase, JCCType, FromLoc, MatlGroup, Material, BatchSeq, HaulLine, OldNew, MSTrans,
            Ticket, SaleDate, VendorGroup, Vendor, GLCo, GLAcct, Hrs, UM, Units, UnitPrice, ECM, Amount,
            JCUM, JCUnits, JCUnitCost, EMCo, Equipment, PRCo, Employee, TaxGroup, TaxCode, TaxType,
            TaxBasis, TaxTotal, CostTrans, EMGroup, RevCode
     	from bMSJC
        where MSCo = @co and Mth = @mth and BatchId = @batchid
    
        --open cursor
        open bcMSJC
        select @openMSJC = 1
    
        MSJC_detail_loop:
            fetch next from bcMSJC into @jcco, @job, @phasegroup, @phase, @jcct, @fromloc, @matlgroup, @material,
                @seq, @haulline, @oldnew, @mstrans, @ticket, @saledate, @vendorgroup, @vendor, @glco, @glacct,
                @hrs, @um, @units, @unitcost, @ecm, @amount, @jcum, @jcunits, @jcunitcost, @emco, @equipment,
                @prco, @employee, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxtotal, @jctrans, @emgroup, @revcode
    
            if @@fetch_status = -1 goto MSJC_posting_end
            if @@fetch_status <> 0 goto MSJC_detail_loop
    
    	   --check if hours are tracked
            if not exists(select top 1 1 from bJCCT with (nolock) where PhaseGroup = @phasegroup and CostType = @jcct and TrackHours = 'Y')
                set @hrs = 0 -- not tracking hours in this cost type
    
            --get Material description
            set @description = 'Material Sales'
            select @description = Description from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
    
            begin transaction
    
   	if @units <> 0 or @amount <> 0
   		begin 			
                --get next available transaction # for INDT
   		exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @msg output
   		if @jctrans = 0
   			begin
   			select @errmsg = 'Unable to update JC Cost Detail.  ' + @msg, @rcode = 1
   			goto MSJC_posting_error
   			end
    
                --add JC Cost Detail entry
                insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
                    JCTransType, Source, Description, BatchId, GLCo, GLTransAcct, UM, ActualUnitCost,
                    PerECM, ActualHours, ActualUnits, ActualCost, PostedUM, PostedUnits, PostedUnitCost,
                    PostedECM, PRCo, Employee, VendorGroup, Vendor, MatlGroup, Material, INCo, Loc, MSTrans,
                    MSTicket, EMCo, EMEquip, TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt, EMGroup, EMRevCode)
                values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcct, @dateposted, @saledate,
                    'MS', 'MS Tickets', @description, @batchid, @glco, @glacct, @jcum, @jcunitcost, 'E', @hrs,
                    @jcunits, @amount, isnull(@um,@jcum), @units, @unitcost, @ecm, @prco, @employee, @vendorgroup,
                    @vendor, @matlgroup, @material, @co, @fromloc, @mstrans, @ticket, @emco, @equipment,
                    @taxtype, @taxgroup, @taxcode, @taxbasis, @taxtotal, @emgroup, @revcode)
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Unable to add JC Cost Detail entry', @rcode = 1
                	goto MSJC_posting_error
                	end
   		end
    
            --delete distribution entry
    	    delete bMSJC
            where MSCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
                and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcct and FromLoc = @fromloc
                and MatlGroup = @matlgroup and Material = @material and BatchSeq = @seq and HaulLine = @haulline
    		    and OldNew = @oldnew
            if @@rowcount <> 1
                begin
                select @errmsg = 'Unable to delete MS JC distribution entry'+ convert(varchar(8),@seq), @rcode = 1
                goto MSJC_posting_error
                end
    
            commit transaction
    
            goto MSJC_detail_loop
        end
    
    MSJC_posting_error:
        rollback transaction
        goto bspexit
    
    
    MSJC_posting_end:
        if @openMSJC = 1
            begin
            close bcMSJC
            deallocate bcMSJC
            set @openMSJC = 0
            end






bspexit:
	if @openMSJC = 1
		begin
		close bcMSJC
		deallocate bcMSJC
		set @openMSJC = 0
		end

	if @rcode <> 0 select @errmsg = @errmsg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPostJC] TO [public]
GO
