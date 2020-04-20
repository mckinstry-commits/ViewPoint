SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[brptMSTBChanged]
 /**************************************************
 * Created: GG 11/03/05
 * Modified: DK 09/29/11
 *
 * Returns the records in a MS Ticket Batch with changed values.
 * Used to report results of the Mass Edit process - only includes columns
 * that can be changed during that process in the where clause.
 *
 * Inputs:
 *	@co			MS Company #
 *	@mth		Batch month
 *	@batchid	Batch ID#
 *	
 * Issue: TK-08130
 * Change: Added HQCO.DefaultCountry for filtering in the RPT
 * 
 ***************************************************/
 	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null)
 as 
 select b.*, HQCO.Name, HQCO.DefaultCountry from MSTB b 
 join HQCO on HQCO.HQCo = b.Co
 where b.Co = @co and Mth = @mth and BatchId = @batchid
 	and (isnull(SaleDate,'') <> isnull(OldSaleDate,'') or isnull(FromLoc,'') <> isnull(OldFromLoc,'')
 	or isnull(SaleType,'') <> isnull(OldSaleType,'') or isnull(b.CustGroup,0) <> isnull(OldCustGroup,'')
 	or isnull(b.Customer,0) <> isnull(OldCustomer,0) or isnull(CustJob,'') <> isnull(OldCustJob,'')
 	or isnull(CustPO,'') <> isnull(OldCustPO,'') or isnull(PaymentType,'') <> isnull(OldPaymentType,'')
 	or isnull(Hold,'') <> isnull(OldHold,'') or isnull(JCCo,0) <> isnull(OldJCCo,0) 
 	or isnull(Job,'') <> isnull(OldJob,'') or isnull(b.PhaseGroup,0) <> isnull(OldPhaseGroup,0)
 	or isnull(INCo,0) <> isnull(OldINCo,0) or isnull(ToLoc,'') <> isnull(OldToLoc,'')
 	or isnull(Material,'') <> isnull(OldMaterial,'') or isnull(UM,'') <> isnull(OldUM,'')
 	or isnull(MatlPhase,'') <> isnull(OldMatlPhase,'') or isnull(MatlJCCType,0) <> isnull(OldMatlJCCType,0)
 	or isnull(WghtUM,'') <> isnull(OldWghtUM,'') or isnull(MatlUnits,0) <> isnull(OldMatlUnits,0)
 	or isnull(UnitPrice,0) <> isnull(OldUnitPrice,0) or isnull(MatlTotal,0) <> isnull(OldMatlTotal,0)
 	or isnull(MatlCost,0) <> isnull(OldMatlCost,0) or isnull(HaulerType,'') <> isnull(OldHaulerType,'')
 	or isnull(HaulVendor,0) <> isnull(OldHaulVendor,0) or isnull(Truck,'') <> isnull(OldTruck,'')
 	or isnull(Driver,'') <> isnull(OldDriver,'') or isnull(EMCo,0) <> isnull(OldEMCo,0)
 	or isnull(Equipment,'') <> isnull(OldEquipment,'') or isnull(b.EMGroup,0) <> isnull(OldEMGroup,0)
 	or isnull(PRCo,0) <> isnull(OldPRCo,0) or isnull(Employee,0) <> isnull(OldEmployee,0)
 	or isnull(HaulCode,'') <> isnull(OldHaulCode,'') or isnull(HaulPhase,'') <> isnull(OldHaulPhase,'')
 	or isnull(HaulJCCType,0) <> isnull(OldHaulJCCType,0) or isnull(HaulBasis,0) <> isnull(OldHaulBasis,0)
 	or isnull(HaulRate,0) <> isnull(OldHaulRate,0) or isnull(HaulTotal,0) <> isnull(OldHaulTotal,0)
 	or isnull(PayCode,'') <> isnull(OldPayCode,'') or isnull(PayBasis,0) <> isnull(OldPayBasis,0)
 	or isnull(PayRate,0) <> isnull(OldPayRate,0) or isnull(PayTotal,0) <> isnull(OldPayTotal,0)
 	or isnull(RevCode,'') <> isnull(OldRevCode,'') or isnull(RevBasis,0) <> isnull(OldRevBasis,0)
 	or isnull(RevRate,0) <> isnull(OldRevRate,0) or isnull(RevTotal,0) <> isnull(OldRevTotal,0)
 	or isnull(b.TaxGroup,0) <> isnull(OldTaxGroup,0) or isnull(TaxCode,'') <> isnull(OldTaxCode,'')
 	or isnull(TaxType,0) <> isnull(OldTaxType,0) or isnull(TaxBasis,0) <> isnull(OldTaxBasis,0)
 	or isnull(TaxTotal,0) <> isnull(OldTaxTotal,0) or isnull(DiscBasis,0) <> isnull(OldDiscBasis,0)
 	or isnull(DiscRate,0) <> isnull(OldDiscRate,0) or isnull(DiscOff,0) <> isnull(OldDiscOff,0)
 	or isnull(TaxDisc,0) <> isnull(OldTaxDisc,0) or isnull(TruckType,'') <> isnull(OldTruckType,''))

GO
GRANT EXECUTE ON  [dbo].[brptMSTBChanged] TO [public]
GO
