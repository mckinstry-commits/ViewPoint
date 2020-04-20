SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspMSInvVoid]
   /***********************************************************
   * Created: GG 11/13/00
   * Modified: GG 01/30/02 - #14176 - initialize bMSIB.Printed 
   *			GG 02/01/02 - #14177 - initialize CheckNo, CMCo, CMAcct to bMSIB
   *			GF 07/29/2003 - issue #21933 - speed improvements
  *				GF 03/17/2008 - issue #127082 international addresses
  *
   *
   * Called from the MS Invoice Void form to pull a previously interfaced
   * invoice into an Invoice Batch to be voided.
   *
   * INPUT PARAMETERS
   *   @co             MS Co#
   *   @mth            Batch Month
   *   @batchid        Batch ID
   *   @msinv          Invoice to void
   *
   * OUTPUT PARAMETERS
   *   @errmsg         success or error message
   *
   * RETURN VALUE
   *   0               success
   *   1               fail
   *****************************************************/
    	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @msinv varchar(10) = null,
        @errmsg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint, @msihmth bMonth, @inusebatchid bBatchID, @void bYN,
       @linecount int, @batchseq int
   
   select @rcode = 0
   
   -- validate HQ Batch
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Invoice', 'MSIB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status <> 0     -- must be open
       begin
       select @errmsg = 'Invalid Batch status - must be Open!', @rcode = 1
       goto bspexit
       end
   
   -- make sure Invoice is eligible to be voided
   select @msihmth = Mth, @inusebatchid = InUseBatchId, @void = Void
   from bMSIH with (nolock) 
   where MSCo = @co and MSInv = @msinv
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid MS Invoice.', @rcode = 1
       goto bspexit
       end
   if @msihmth <> @mth
       begin
       select @errmsg = 'Invoice posted in another month.', @rcode = 1
       goto bspexit
       end
   if @inusebatchid = @batchid
       begin
       select @errmsg = 'Invoice already in the current batch.', @rcode = 1
       goto bspexit
       end
   if @void = 'Y'
       begin
       select @errmsg = 'Invoice has already been voided.', @rcode = 1
       goto bspexit
       end
   -- count # of Invoice Lines
   select @linecount = count(*) from bMSIL with (nolock) where MSCo = @co and MSInv = @msinv
   
   -- passed validation, add to Invoice Batch using a transaction to make sure Header and all Lines are added
   begin transaction
   
   -- get next Batch Sequence #
   select @batchseq = isnull(max(BatchSeq),0) + 1
   from bMSIB with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- add Invoice Batch Header, entry will be locked in bMSIH via insert trigger on bMSIB
   insert bMSIB(Co, Mth, BatchId, BatchSeq, MSInv, CustGroup, Customer, CustJob, CustPO, Description,
       ShipAddress, City, State, Zip, ShipAddress2, PaymentType, RecType, PayTerms, InvDate, DiscDate,
       DueDate, ApplyToInv, InterCoInv, LocGroup, Location, PrintLvl, SubtotalLvl, SepHaul, Interfaced,
       Void, Notes, PrintedYN, CheckNo, CMCo, CMAcct, Country)
   select MSCo, Mth, @batchid, @batchseq, MSInv, CustGroup, Customer, CustJob, CustPO, Description,
       ShipAddress, City, State, Zip, ShipAddress2, PaymentType, RecType, PayTerms, InvDate, DiscDate,
       DueDate, ApplyToInv, InterCoInv, LocGroup, Location, PrintLvl, SubtotalLvl, SepHaul, 'Y',
       'Y', Notes, 'N', CheckNo, CMCo, CMAcct, Country
   from bMSIH with (nolock) where MSCo = @co and MSInv = @msinv
   if @@rowcount <> 1
       begin
       select @errmsg = 'Unable to add Invoice to Batch', @rcode = 1
       rollback transaction
       goto bspexit
       end
   
   -- add all Invoice Lines to batch
   insert bMSID(Co, Mth, BatchId, BatchSeq, MSTrans, CustJob, CustPO, SaleDate, FromLoc,
       MatlGroup, Material, UM, UnitPrice, Ticket)
   select MSCo, @mth, @batchid, @batchseq, MSTrans, CustJob, CustPO, SaleDate, FromLoc,
       MatlGroup, Material, UM, UnitPrice, Ticket
   from bMSIL with (nolock) where MSCo = @co and MSInv = @msinv
   if @@rowcount <> @linecount
       begin
       select @errmsg = 'Unable to add all Invoice Lines to Batch', @rcode = 1
       rollback transaction
       goto bspexit
       end
   
   commit transaction
   
   
   
   bspexit:
      -- if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSInvVoid] TO [public]
GO
