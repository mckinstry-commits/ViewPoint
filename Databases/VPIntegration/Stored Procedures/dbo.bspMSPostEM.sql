SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************/
   CREATE   procedure [dbo].[bspMSPostEM]
   /***********************************************************
      * Created: GG 11/07/00
      * Modfied: GG 02/22/01 - update ExpGLCo in bEMRD with summary interface
      *	    	GG 05/30/01 - added @@rowcount check after bEMRD and bEMRB inserts
      *			GG 05/11/02 - #13929 - update Hours with unit based revenue
      *			GF 08/01/2003 - issue #21933 - speed improvements
      *			GF 12/03/2003 - issue #23139 - added EMTrans to MSEM for rowset update.
      *			GF 02/17/2004 - issue #23799 - need to update previous hour reading
      *			TV 03/03/04 - issue 23950 Not updating Hour meter in EMRD correctly
      * 		TV 03/19/04 - issue 24114 Using only posted date. Adding actual date
      *		    TV 04/14/04 23255- Update EMEM on the Batch Process.
      *			JayR 08/09/2012 TK-14356 Fix an Insert were the columns were not fully specified.
      *
      * Called from bspMSTBPost and bspMSHBPost procedures to post
      * EM Revenue distributions tracked in bMSEM and bMSRB for
      * both Ticket and Hauler Time Sheet batches.
      *
      * Sign on values in 'old' entries has already been reversed.
      *
      * EM Interface Levels:
      *	0      No update
      *	1      Summarize entries by EMCo#/Equipment/RevenueCode/SalesType
      *  2      Full detail
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
     
     declare @rcode int, @msglco bCompany, @eminterfacelvl tinyint, @openMSEM tinyint, @emco bCompany, @equipment bEquip,
         	@emgroup bGroup, @revcode bRevCode, @transtype char(1), @units bUnits, @revenue bDollar, @glco bCompany,
         	@glacct bGLAcct, @um bUM, @basis char(1), @timeunits bUnits, @workunits bUnits, @timeum bUM, @workum bUM,
         	@revrate bUnitCost, @category varchar(10), @ememhrs bHrs, @msg varchar(255), @emtrans bTrans, @oldnew tinyint,
         	@mstrans bTrans, @saledate bDate, @fromloc bLoc, @matlgroup bGroup, @material bMatl, @jcco bCompany,
         	@job bJob, @custgroup bGroup, @customer bCustomer, @inco bCompany, @toloc bLoc, @prco bCompany, 
     		@employee bEmployee, @selltoco bCompany, @matlcategory varchar(10), @lmhaulexpglacct bGLAcct, 
     		@lohaulexpglacct bGLAcct, @lshaulexpglacct bGLAcct, @lchaulexpglacct bGLAcct, @haulexpglacct bGLAcct, 
     		@seq int, @phasegroup bGroup, @phase bPhase, @jcct bJCCType, @haulline smallint, @hrs bHrs, @hrsum bUM,
     		@msem_count bTrans, @msem_trans bTrans, @emrdhrs bHrs, @updatehours char, @actualdate bDate 
     
     select @rcode = 0, @openMSEM = 0
     
     --get MS GL Co# and EM interface level
     select @msglco = GLCo, @eminterfacelvl = EMInterfaceLvl
     from bMSCO with (nolock) where MSCo = @co
     if @@rowcount <> 1
         begin
         select @errmsg = 'Invalid MS Co#', @rcode = 1
         goto bspexit
         end
     if @eminterfacelvl not in (0,1,2)
         begin
         select @errmsg = 'Invalid EM Interface level assigned in MS Company.', @rcode = 1
         goto bspexit
         end
     
     /** Post Equipment Revenue distributions **/
     
     -- No update to EM
     if @eminterfacelvl = 0
         begin
         delete bMSRB where MSCo = @co and Mth = @mth and BatchId = @batchid
         delete bMSEM where MSCo = @co and Mth = @mth and BatchId = @batchid
         goto MSEM_posting_end
      	end
     
     -- Summary update to EM - one entry per EMCo#/Equipment/RevCode/SaleType
     if @eminterfacelvl = 1
         begin
         -- use summary level cursor on MS EM Distributions
         declare bcMSEM cursor LOCAL FAST_FORWARD for
         select EMCo, Equipment, EMGroup, RevCode, SaleType,
             convert(numeric(12,3),sum(Units)), convert(numeric(12,2),sum(Amount)), convert(numeric(10,2),sum(Hours))
      	from bMSEM with (nolock) 
         where MSCo = @co and Mth = @mth and BatchId = @batchid
      	group by EMCo, Equipment, EMGroup, RevCode, SaleType
     
         --open cursor
         open bcMSEM
         select @openMSEM = 1
     
         MSEM_summary_loop:
             fetch next from bcMSEM into @emco, @equipment, @emgroup, @revcode, @transtype, @units, @revenue, @hrs
     
             if @@fetch_status = -1 goto MSEM_posting_end
             if @@fetch_status <> 0 goto MSEM_summary_loop
     
     		-- get Hours U/M 
     		select @hrsum = HoursUM from bEMCO with (nolock) where EMCo = @emco
     		if @@rowcount = 0
                 begin
                 select @errmsg = 'Invalid EM Co#', @rcode = 1
                 goto bspexit
                 end
     
             --get other info from EM Distribution (should be the same for all entries with this equip and revcode)
    		 --TV 03/19/04 - issue 24114 Using only posted date. Adding actual date
             select @glco = GLCo, @glacct = GLAcct, @um = UM, @actualdate = SaleDate
             from bMSEM with (nolock) 
             where MSCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equipment = @equipment
                 and EMGroup = @emgroup and RevCode = @revcode and SaleType = @transtype
     
             --check basis on Revenue Code
             select @basis = Basis from bEMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode
             if @@rowcount = 0
                 begin
                 select @errmsg = 'Invalid EM Revenue Code', @rcode = 1
                 goto bspexit
                 end
             select @timeunits = 0, @workunits = 0, @timeum = null, @workum = null, @revrate = 0
             if @basis = 'H' select @timeunits = @units, @timeum = @um
             if @basis = 'U'	select @workunits = @units, @workum = @um, @timeunits = @hrs, @timeum = @hrsum
     
             if @units <> 0 select @revrate = @revenue / @units
     
             -- get Equipment Category and current Hour Meter Reading for Equipment
             select @category = Category, @ememhrs = isnull(HourReading,0)
             from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
             if @@rowcount = 0
                 begin
                 select @errmsg = 'Invalid Equipment', @rcode = 1
                 goto bspexit
                 end
     		
             begin transaction
     		
     		--Check to see if we are updating the Meter hours
     		--TV 03/03/04 - issue 23950 Not updating Hour meter in EMRD correctly
    		select @updatehours = UpdtHrMeter from bEMRH with (nolock)
     		where EMCo = @emco and EMGroup = @emgroup and  Equipment = @equipment and RevCode = @revcode
      		if @@rowcount = 0
      			begin
      			select @updatehours = UpdtHrMeter from bEMRR with (nolock)
      			where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
      			end
    
     		if @updatehours = 'Y'
     			begin 
     			select @emrdhrs = @ememhrs + @hrs
     			end 
     		else
     			begin
     			select @emrdhrs = @ememhrs
     			end 
     
             if @units <> 0 or @revenue <> 0
                 begin
                 --get next available transaction # for bEMRD
                 exec @emtrans = dbo.bspHQTCNextTrans 'bEMRD', @emco, @mth, @msg output
      	        if @emtrans = 0
                     begin
        	            select @errmsg = 'Unable to update EM Revenue Detail.  ' + isnull(@msg,''), @rcode = 1
                     goto MSEM_posting_error
            	        end
     
                 insert bEMRD (EMCo, Mth, Trans, BatchID, EMGroup, Equipment, RevCode, Source, TransType,
                     PostDate, ActualDate, GLCo, RevGLAcct, ExpGLCo, ExpGLAcct, Memo, Category, UM, WorkUnits, TimeUM, TimeUnits,
                     Dollars, RevRate, HourReading, PreviousHourReading, MSCo)
     	        values (@emco, @mth, @emtrans, @batchid, @emgroup, @equipment, @revcode, 'MS', @transtype,
                     @dateposted, @actualdate, @glco, @glacct, @msglco, null, 'MS Equipment Usage', @category, @workum, @workunits,
                     @timeum, @timeunits, @revenue, @revrate, @emrdhrs, @ememhrs, @co)
     		    if @@rowcount = 0
     				begin
                     select @errmsg = 'Unable to add EM Revenue entry', @rcode = 1
                 	goto MSEM_posting_error
                 	end
     
                 -- add Revenue Breakdown entries
                 insert bEMRB (EMCo, Mth, Trans, EMGroup, RevBdownCode, Equipment, RevCode, Amount)
                 select @emco, @mth, @emtrans, @emgroup, RevBdownCode, @equipment, @revcode, sum(Amount)
                 from bMSRB with (nolock) 
                 where MSCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equipment = @equipment
                 and EMGroup = @emgroup and RevCode = @revcode and SaleType = @transtype
                 group by RevBdownCode
     		    if @@rowcount = 0
     				begin
                     select @errmsg = 'Unable to add EM Revenue Breakdown entry', @rcode = 1
                 	goto MSEM_posting_error
                 	end
                 end
     
             --delete Revenue Breakdown distributions
             delete bMSRB
             where MSCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equipment = @equipment
                 and EMGroup = @emgroup and RevCode = @revcode and SaleType = @transtype
     
             --delete EM distribution entries
     		delete bMSEM
             where MSCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equipment = @equipment
             and EMGroup = @emgroup and RevCode = @revcode and SaleType = @transtype
     
             commit transaction
     
             goto MSEM_summary_loop
         end
     
     
     -- Detail update to EM - one entry per EMCo/Equip/RevCode/SaleType/BatchSeq/HaulLine/OldNew
     if @eminterfacelvl = 2
         begin
   
         -- use detail level cursor on MS EM Distributions
         declare bcMSEM cursor LOCAL FAST_FORWARD for
         select EMCo, Equipment, EMGroup, RevCode, SaleType, BatchSeq, HaulLine, OldNew, MSTrans, SaleDate,
             FromLoc, MatlGroup, Material, JCCo, Job, PhaseGroup, Phase, JCCType, CustGroup, Customer, INCo,
             ToLoc, PRCo, Employee, GLCo, GLAcct, UM, Units, RevRate, Amount, Hours, EMTrans
      	from bMSEM with (nolock) 
         where MSCo = @co and Mth = @mth and BatchId = @batchid
     
         --open cursor
         open bcMSEM
         select @openMSEM = 1
     
         MSEM_detail_loop:
             fetch next from bcMSEM into @emco, @equipment, @emgroup, @revcode, @transtype, @seq, @haulline, @oldnew, @mstrans, @saledate,
                 @fromloc, @matlgroup, @material, @jcco, @job, @phasegroup, @phase, @jcct, @custgroup, @customer, @inco,
                 @toloc, @prco, @employee, @glco, @glacct, @um, @units, @revrate, @revenue, @hrs, @emtrans
     
             if @@fetch_status = -1 goto MSEM_posting_end
             if @@fetch_status <> 0 goto MSEM_detail_loop
     
     		-- get Hours U/M 
     		select @hrsum = HoursUM from bEMCO with (nolock) where EMCo = @emco
     		if @@rowcount = 0
                 begin
                 select @errmsg = 'Invalid EM Co#', @rcode = 1
                 goto bspexit
                 end
     
             --check basis on Revenue Code
             select @basis = Basis from bEMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode
             if @@rowcount = 0
                 begin
                 select @errmsg = 'Invalid EM Revenue Code', @rcode = 1
                 goto bspexit
                 end
             select @timeunits = 0, @workunits = 0, @timeum = null, @workum = null
             if @basis = 'H' select @timeunits = @units, @timeum = @um
             if @basis = 'U' select @workunits = @units, @workum = @um, @timeunits = @hrs, @timeum = @hrsum
     
             --set sell to Co#
             select @selltoco = case @transtype when 'J' then @jcco when 'I' then @inco else null end
     
             --get Material Category
             select @matlcategory = Category from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
             if @@rowcount = 0
                 begin
                 select @errmsg = 'Invalid Material', @rcode = 1
                 goto bspexit
                 end
     
             --get Haul Expense Account
             select @lmhaulexpglacct = case @transtype when 'C' then CustHaulExpEquipGLAcct when 'J' then JobHaulExpEquipGLAcct
                 else InvHaulExpEquipGLAcct end
             from bINLM with (nolock) where INCo = @co and Loc = @fromloc
             if @transtype = 'C'
                 begin
                 --check for Location/Category override
                 select @lohaulexpglacct = CustHaulExpEquipGLAcct
                 from bINLO with (nolock) where INCo = @co and Loc = @fromloc and MatlGroup = @matlgroup and Category = @matlcategory
                 end
             else
                 begin
                 --check for Location/Co override
                 select @lshaulexpglacct = case @transtype when 'J' then JobHaulExpEquipGLAcct else InvHaulExpEquipGLAcct end
                 from bINLS with (nolock) 
                 where INCo = @co and Loc = @fromloc and Co = @selltoco
                 --check for Location/Company/Category override
                 select @lchaulexpglacct = case @transtype when 'J' then JobHaulExpEquipGLAcct else InvHaulExpEquipGLAcct end
                 from bINLC with (nolock) 
                 where INCo = @co and Loc = @fromloc and Co = @selltoco and MatlGroup = @matlgroup and Category = @matlcategory
                 end
             if @transtype in ('J','I') select @haulexpglacct = isnull(@lchaulexpglacct,isnull(@lshaulexpglacct,@lmhaulexpglacct))
             if @transtype = 'C' select @haulexpglacct = isnull(@lohaulexpglacct,@lmhaulexpglacct)
     
             -- get Equipment Category and current Hour Meter Reading for Equipment
             select @category = Category, @ememhrs = isnull(HourReading,0)
             from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
             if @@rowcount = 0
                 begin
                 select @errmsg = 'Invalid Equipment', @rcode = 1
                 goto bspexit
                 end
     
     
             begin transaction
     
             -- add in new units and revenue to EM Revenue Detail
             if @timeunits <> 0 or @workunits <> 0 or @revenue <> 0
                 begin
     			--Check to see if we are updating the Meter hours
     		--TV 03/03/04 - issue 23950 Not updating Hour meter in EMRD correctly
    		select @updatehours = UpdtHrMeter from bEMRH with (nolock)
     		where EMCo = @emco and EMGroup = @emgroup and  Equipment = @equipment and RevCode = @revcode
      		if @@rowcount = 0
      			begin
      			select @updatehours = UpdtHrMeter from bEMRR with (nolock)
      			where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
      			end
    
     		if @updatehours = 'Y'
     			begin 
     			select @emrdhrs = @ememhrs + @hrs
     			end 
     		else
     			begin
     			select @emrdhrs = @ememhrs
     			end
   
   		-- get next available transaction # for bEMRD
   		exec @emtrans = bspHQTCNextTrans 'bEMRD', @emco, @mth, @errmsg output
   		if @emtrans = 0
   			begin
      	        	select @errmsg = 'Unable to update EM Revenue Detail. ', @rcode = 1
   			goto MSEM_posting_error
      	        	end
   
      	    	insert bEMRD (EMCo, Mth, Trans, BatchID, EMGroup, Equipment, RevCode, Source, TransType, PostDate, ActualDate,
                    	JCCo, Job, PhaseGroup, JCPhase, JCCostType, PRCo, Employee, GLCo, RevGLAcct, ExpGLCo, ExpGLAcct,
                     Memo, Category, UM, WorkUnits, TimeUM, TimeUnits, Dollars, RevRate, HourReading, PreviousHourReading,
     				MSCo, MSTrans, FromLoc, CustGroup, Customer, INCo, ToLoc)
     	    	values (@emco, @mth, @emtrans, @batchid, @emgroup, @equipment, @revcode, 'MS', @transtype, @dateposted, @saledate,
                     @jcco, @job, @phasegroup, @phase, @jcct, @prco, @employee, @glco, @glacct, @msglco, @haulexpglacct,
                     'MS Equipment Usage', @category, @workum, @workunits, @timeum, @timeunits, @revenue, @revrate, 
     				@emrdhrs, @ememhrs,
                     @co, @mstrans, @fromloc, @custgroup, @customer, @inco, @toloc)
     	    	if @@rowcount = 0
     				begin
                     select @errmsg = 'Unable to add EM Revenue entry', @rcode = 1
                 	goto MSEM_posting_error
                 	end
     
                 -- add Revenue Breakdown entries
                 insert bEMRB (EMCo, Mth, Trans, EMGroup, RevBdownCode, Equipment, RevCode, Amount)
                 select @emco, @mth, @emtrans, @emgroup, RevBdownCode, @equipment, @revcode, sum(Amount)
                 from bMSRB with (nolock) 
                 where MSCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equipment = @equipment
                 and EMGroup = @emgroup and RevCode = @revcode and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
                 group by RevBdownCode
     	    	if @@rowcount = 0
     				begin
                     select @errmsg = 'Unable to add EM Revenue Breakdown entry', @rcode = 1
                 	goto MSEM_posting_error
                 	end
                 end
     
             --delete Revenue Breakdown distributions
             delete bMSRB
             where MSCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equipment = @equipment
                 and EMGroup = @emgroup and RevCode = @revcode and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
     
             --delete EM distribution entry
     	    delete bMSEM
             where MSCo = @co and Mth = @mth and BatchId = @batchid and EMCo = @emco and Equipment = @equipment
                 and EMGroup = @emgroup and RevCode = @revcode and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
             if @@rowcount <> 1
                 begin
                 select @errmsg = 'Unable to delete MS EM distribution entry', @rcode = 1
                 goto MSEM_posting_error
                 end
   
   			--TV 04/14/04 23255- Update EMEM on the Batch Process.
   			exec @rcode =  bspEMEMJobLocDateUpdate @emco, @equipment, @jcco,@job, @saledate, @saledate, @errmsg output
   			if @rcode <> 0 	goto bspexit
   
     
             commit transaction
     
             goto MSEM_detail_loop
         end
     
     MSEM_posting_error:
         rollback transaction
         goto bspexit
     
     
     MSEM_posting_end:
         if @openMSEM = 1
             begin
             close bcMSEM
             deallocate bcMSEM
             set @openMSEM = 0
             end
     
     
     
     bspexit:
         if @openMSEM = 1
             begin
      		close MSEM_cursor
      		deallocate MSEM_cursor
     		set @openMSEM = 0
      		end
     
         if @rcode <> 0 select @errmsg = @errmsg
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPostEM] TO [public]
GO
