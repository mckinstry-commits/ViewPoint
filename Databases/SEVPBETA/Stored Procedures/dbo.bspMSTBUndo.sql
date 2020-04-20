SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspMSTBUndo]
   /***********************************************************
    * Created: GG 10/31/00
    * Modified:
    *
    * Called from MS Mass Edit form to rollback ALL changes
    * in a batch of tickets.
    *
    * INPUT PARAMETERS:
    *   @co             MS Co#
    *   @mth            Batch Month
    *   @batchid        Batch Id
    *
    * OUTPUT PARAMETERS
    *   @errmsg         error message if something went wrong
    *
    * RETURN
    *  0 = success, 1 = error
    *
    *****************************************************/
       (@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint
   
   select @rcode = 0
   
   -- validate HQ Batch - must be valid batch and locked by current user
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Tickets', 'MSTB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status <> 0
       begin
       select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
       goto bspexit
       end
   
   --set current values equal to 'old' values
   update bMSTB
   set SaleDate = OldSaleDate, Ticket = OldTic, FromLoc = OldFromLoc, VendorGroup = OldVendorGroup,
       MatlVendor = OldMatlVendor, SaleType = OldSaleType, CustGroup = OldCustGroup, Customer = OldCustomer,
       CustJob = OldCustJob, CustPO = OldCustPO, PaymentType = OldPaymentType, CheckNo = OldCheckNo, Hold = OldHold,
       JCCo = OldJCCo, Job = OldJob, PhaseGroup = OldPhaseGroup, INCo = OldINCo, ToLoc = OldToLoc, MatlGroup = OldMatlGroup,
       Material = OldMaterial, UM = OldUM, MatlPhase = OldMatlPhase, MatlJCCType = OldMatlJCCType, GrossWght = OldGrossWght,
       TareWght = OldTareWght, WghtUM = OldWghtUM, MatlUnits = OldMatlUnits, UnitPrice = OldUnitPrice, ECM = OldECM,
       MatlTotal = OldMatlTotal, MatlCost = OldMatlCost, HaulerType = OldHaulerType, HaulVendor = OldHaulVendor,
       Truck = OldTruck, Driver = OldDriver, EMCo = OldEMCo, Equipment = OldEquipment, EMGroup = OldEMGroup,
       PRCo = OldPRCo, Employee = OldEmployee, TruckType = OldTruckType, StartTime = OldStartTime, StopTime = OldStopTime,
       Loads = OldLoads, Miles = OldMiles, Hours = OldHours, Zone = OldZone, HaulCode = OldHaulCode,
       HaulPhase = OldHaulPhase, HaulJCCType = OldHaulJCCType, HaulBasis = OldHaulBasis, HaulRate = OldHaulRate,
       HaulTotal = OldHaulTotal, PayCode = OldPayCode, PayBasis = OldPayBasis, PayRate = OldPayRate,
       PayTotal = OldPayTotal, RevCode = OldRevCode, RevBasis = OldRevBasis, RevRate = OldRevRate, RevTotal = OldRevTotal,
       TaxGroup = OldTaxGroup, TaxCode = OldTaxCode, TaxType = OldTaxType, TaxBasis = OldTaxBasis, TaxTotal = OldTaxTotal,
       DiscBasis = OldDiscBasis, DiscRate = OldDiscRate, DiscOff = OldDiscOff, TaxDisc = OldTaxDisc,
       Void = OldVoid
   where Co = @co and Mth = @mth and BatchId = @batchid    -- applies to all entries in batch
   
   bspexit:
       if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTBUndo] TO [public]
GO
