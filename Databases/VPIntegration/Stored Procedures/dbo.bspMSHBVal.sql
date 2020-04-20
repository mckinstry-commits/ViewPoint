SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspMSHBVal]
   /***********************************************************
    * CREATED BY:	GG 10/31/00
    * MODIFIED By: GG 01/26/01 - clear Inventory distributions in bMSIN
    *				GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
    *
    * USAGE:
    * Called from MS Batch Process form to validate a Hauler Time Sheet batch
    *
    * Errors in batch added to bHQBE using bspHQBEInsert
    *
    * INPUT PARAMETERS
    *   @msco          MS Co#
    *   @mth           Batch Month
    *   @batchid       Batch ID
    *
    * OUTPUT PARAMETERS
    *   @errmsg        error message
    *
    * RETURN VALUE
    *   0              success
    *   1              fail
   *****************************************************/
       @msco bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int, @errorstart varchar(10), @errortext varchar(255), @status tinyint, @opencursor tinyint,
       @msglco bCompany, @jrnl bJrnl, @seq int, @transtype char(1), @haultrans bTrans, @freightbill varchar(10),
       @saledate bDate, @haultype char(1), @vendorgroup bGroup, @haulvendor bVendor, @truck bTruck, @driver varchar(30),
       @emco bCompany, @equip bEquip, @emgroup bGroup, @prco bCompany, @employee bEmployee, @oldfreightbill varchar(10),
       @oldsaledate bDate, @oldhaultype char(1), @oldvendorgroup bGroup, @oldhaulvendor bVendor, @oldtruck bTruck,
       @olddriver varchar(30), @oldemco bCompany, @oldequip bEquip, @oldprco bCompany, @oldemployee bEmployee,
       @inusebatchid bBatchID, @itemcount int, @deletecount int, @glco bCompany
   
   select @rcode = 0
   
   -- validate HQ Batch
   exec @rcode = bspHQBatchProcessVal @msco, @mth, @batchid, 'MS Haul', 'MSHB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status < 0 or @status > 3
       begin
       select @errmsg = 'Invalid Batch status!', @rcode = 1
       goto bspexit
       end
   -- set HQ Batch status to 1 (validation in progress)
   update bHQBC set Status = 1
   where Co = @msco and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
       begin
       select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
       goto bspexit
       end
   
   -- clear HQ Batch Errors
   delete bHQBE where Co = @msco and Mth = @mth and BatchId = @batchid
   
   -- clear IN, JC, EM, and GL distribution entries
   delete bMSIN where MSCo = @msco and Mth = @mth and BatchId = @batchid
   delete bMSJC where MSCo = @msco and Mth = @mth and BatchId = @batchid
   delete bMSRB where MSCo = @msco and Mth = @mth and BatchId = @batchid
   delete bMSEM where MSCo = @msco and Mth = @mth and BatchId = @batchid
   delete bMSGL where MSCo = @msco and Mth = @mth and BatchId = @batchid
   
   -- get Company info from MS Company
   select @msglco = GLCo, @jrnl = Jrnl
   from bMSCO where MSCo = @msco
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid MS Company #' + convert(varchar(3),@msco), @rcode = 1
       goto bspexit
       end
   -- validate Month in MS GL Co# - subledgers must be open
   exec @rcode = bspHQBatchMonthVal @msglco, @mth, 'MS', @errmsg output
   if @rcode <> 0 goto bspexit
   
   -- validate Journal
   if not exists(select * from bGLJR where GLCo = @msglco and Jrnl = @jrnl)
       begin
       select @errmsg = 'Invalid Journal ' + isnull(@jrnl,'') + ' assigned in MS Company!', @rcode = 1
       goto bspexit
       end
   
   -- declare cursor on MS Haul Batch Header for validation
   declare bcMSHB cursor LOCAL FAST_FORWARD
   	for select BatchSeq,BatchTransType,HaulTrans,FreightBill,SaleDate,HaulerType,
       VendorGroup,HaulVendor,Truck,Driver,EMCo,Equipment,EMGroup,PRCo,Employee,OldFreightBill,
       OldSaleDate,OldHaulerType,OldVendorGroup,OldHaulVendor,OldTruck,OldDriver,OldEMCo,OldEquipment,
       OldPRCo,OldEmployee
   from bMSHB where Co = @msco and Mth = @mth and BatchId = @batchid
   
   -- open cursor
   open bcMSHB
   
   -- set open cursor flag to true
   select @opencursor = 1
   
   MSHB_loop:
       fetch next from bcMSHB into @seq, @transtype, @haultrans, @freightbill, @saledate, @haultype,
           @vendorgroup, @haulvendor, @truck, @driver, @emco, @equip, @emgroup, @prco, @employee,
           @oldfreightbill, @oldsaledate, @oldhaultype, @oldvendorgroup, @oldhaulvendor, @oldtruck,
           @olddriver, @oldemco, @oldequip, @oldprco, @oldemployee
   

       if @@fetch_status <> 0 goto MSHB_end
   
       -- save Batch Sequence # for any errors that may be found
       select @errorstart = 'Seq#' + convert(varchar(6),@seq)
   
       -- validate transaction type
       if @transtype not in ('A','C','D')
       begin
           select @errortext = @errorstart + ' -  Invalid transaction type, must be (A, C, or D).'
           exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
           if @rcode <> 0 goto bspexit
           goto MSHB_loop
           end
   
       -- validation specific to Add entries
       if @transtype = 'A'
           begin
           -- validate Haul Trans#
           if @haultrans is not null
               begin
    	        select @errortext = @errorstart + ' - New entries must have a null Haul Transaction #!'
               exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	        if @rcode <> 0 goto bspexit
               goto MSHB_loop
               end
           end

       -- validation specific to both Change and Delete entries
       if @transtype in ('C','D')
           begin
           -- validate Trans#
           if @haultrans is null
               begin
               select @errortext = @errorstart + ' - Change and Delete entries must have a Haul Transaction #!'
               exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	        if @rcode <> 0 goto bspexit
               goto MSHB_loop
               end
           -- check MS Haul Header
           select @inusebatchid = InUseBatchId
           from bMSHH where MSCo = @msco and Mth = @mth and HaulTrans = @haultrans
           if @@rowcount = 0
               begin
               select @errortext = @errorstart + ' - Invalid Haul Transaction #!'
               exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	        if @rcode <> 0 goto bspexit
               goto MSHB_loop
               end
           if isnull(@inusebatchid,0) <> @batchid
               begin
               select @errortext = @errorstart + ' - Haul Transaction # is not locked by the current Batch!'
               exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	        if @rcode <> 0 goto bspexit
               goto MSHB_loop
               end
           end
       -- validation specific to Delete entries
       if @transtype = 'D'
           begin
           -- make sure all Haul Lines have been added to the batch and marked for deletion
           select @itemcount = count(*) from bMSTD where MSCo = @msco and Mth = @mth and HaulTrans = @haultrans
           select @deletecount = count(*)
           from bMSLB
           where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType = 'D'
           if @itemcount <> @deletecount
               begin
    	        select @errortext = @errorstart + ' - In order to delete a Haul Transaction all lines must be in the current batch and marked for delete! '
    	        exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    	        if @rcode <> 0 goto bspexit
               goto MSHB_loop
    	        end
           -- make sure no add or change Haul Lines exist for this entry
           if exists(select * from bMSLB where Co = @msco and Mth = @mth and BatchId = @batchid
               and BatchSeq = @seq and BatchTransType in ('A','C'))
               begin
    	        select @errortext = @errorstart + ' - In order to delete a Haul Transaction you cannot have any Add or Change lines! '
    	        exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    	        if @rcode <> 0 goto bspexit
               goto MSHB_loop
               end
           end
       -- validation specific to Add and Change entries
       if @transtype in ('A','C')
           begin
           -- validate Hauler Type
           if @haultype not in ('E','H')
            begin
               select @errortext = @errorstart + ' - Invalid Hauler Type, must be (E or H)!'
               exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	        if @rcode <> 0 goto bspexit
               goto MSHB_loop
               end

           -- validate Haul Vendor
       if @haultype = 'H'
               begin
               if not exists(select * from bAPVM where VendorGroup = @vendorgroup and Vendor = @haulvendor and ActiveYN = 'Y')
                   begin
                   select @errortext = @errorstart + ' - Invalid Haul Vendor, either missing or inactive!'
                   exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	            if @rcode <> 0 goto bspexit
                   goto MSHB_loop
                   end
               end
           -- validate Equipment
           if @haultype = 'E'
               begin
               if not exists(select * from bEMEM where EMCo = @emco and Equipment = @equip and Type<>'C' and [Status]='A')
                   begin
                   select @errortext = @errorstart + ' - Invalid or inactive equipment. Either the equipment is missing, set as a component or not active!'
                   exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	            if @rcode <> 0 goto bspexit
                   goto MSHB_loop
                   end
               -- validate Employee

               if @employee is not null
                   begin
                   if not exists(select * from bPREH where PRCo = @prco and Employee = @employee and ActiveYN = 'Y')
                       begin
                       select @errortext = @errorstart + ' - Invalid Employee, either missing or inactive!'
                       exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
     	                if @rcode <> 0 goto bspexit
                       goto MSHB_loop
                       end
                   end
               end
           end
   
       -- validate Haul Lines and create distributions
       exec @rcode = bspMSLBVal @msco, @mth, @batchid, @seq, @transtype, @haultype, @emgroup, @errmsg output
       if @rcode = 1 goto bspexit
   
       goto MSHB_loop
   
   MSHB_end:   -- finished with Hauler Time Sheet entries
       close bcMSHB
       deallocate bcMSHB
       select @opencursor = 0
   
   -- make sure debits and credits balance
   select @glco = m.GLCo
   from bMSGL m join bGLAC g on m.GLCo = g.GLCo and m.GLAcct = g.GLAcct --and g.AcctType <> 'M'  -- exclude memo accounts for qtys
   where m.MSCo = @msco and m.Mth = @mth and m.BatchId = @batchid
   group by m.GLCo
   having isnull(sum(Amount),0) <> 0
   if @@rowcount <> 0
       begin
       select @errortext =  'GL Company ' + convert(varchar(3),isnull(@glco,'')) + ' entries do not balance!'
       exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       if @rcode <> 0 goto bspexit
       end
   
   -- check HQ Batch Errors and update HQ Batch Control status
   select @status = 3	/* valid - ok to post */
   if exists(select * from bHQBE where Co = @msco and Mth = @mth and BatchId = @batchid)
       select @status = 2	/* validation errors */
   
   update bHQBC
   set Status = @status
   where Co = @msco and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
       begin
    	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    	goto bspexit
    	end
   
   bspexit:
       if @opencursor = 1
    		begin
    		close bcMSHB
    		deallocate bcMSHB
    		end
   
       if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHBVal] TO [public]
GO
