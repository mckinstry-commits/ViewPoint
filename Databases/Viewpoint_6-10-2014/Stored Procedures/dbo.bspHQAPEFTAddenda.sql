SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         PROCEDURE [dbo].[bspHQAPEFTAddenda]
     /************************************
       * Created: 09/11/01 MV
       * Modified: 10/09/01 MV
       * 	      12/5/01 MV - issue 15489 - changed select to join on
       *				APTB with the batchseq 	
   	* 			6/19/2 kb - issue #17687 - change for CTX format to use APTB to
   	*				get values instead of APTL
       *		 6/26/02 - MV - For CTX removed joins with APTL, APTH 
       * This SP is used in HQExport form frmAPEFTExport.
       * This SP creates and returns addenda record(s)
       * Any changes here will require changes to the form.
       *
       ***********************************/
       (@apco bCompany, @month bDate, @batchid bBatchID,@vendorgroup bGroup, @vendor bVendor,
         @addendaformat tinyint, @addendatype tinyint, @appbtaxformcode varchar (10) = null,
         @appbemployee bEmployee = null,@batchseq int)
     
      as
      set nocount on
     
      declare @prco bCompany,
         @employee bEmployee, @dlcode bEDLCode, @taxformcode as varchar (10),
         @taxperiodenddate bDate, @amounttype varchar (10), @amount bDollar,
         @amttype2 varchar(10), @amount2 bDollar, @amttype3 varchar (10),
         @amount3 bDollar, @caseidentifier varchar (12), @ssn varchar (11),
         @lastname varchar (30), @firstname varchar (30), @grossamt bDollar,
         @netamt bDollar, @maxpaydate bDate
     
      --CCD+ format
      if @addendaformat = 1
         begin
         if @addendatype = 1 -- Federal tax payments
             begin
             select max(TaxPeriodEndDate), max(AmountType), sum(h.Amount),
     		max(AmtType2), sum(Amount2), max(AmtType3), sum(Amount3)
     		From APTH h JOIN APTB b ON h.APCo=b.Co and h.InUseMth=b.Mth and h.InUseBatchId=b.BatchId and h.APTrans=b.APTrans
     		WHERE APCo = @apco and InUseBatchId = @batchid and h.VendorGroup = @vendorgroup and h.Vendor = @vendor
     		and h.PayMethod = 'E' and h.TaxFormCode = @appbtaxformcode and b.BatchSeq=@batchseq
     	 end
         if @addendatype = 2 --child support payments
             begin
             
     		select @maxpaydate = max(h.InvDate) from APTH h JOIN APTB b 
     		ON h.APCo=b.Co and h.InUseMth=b.Mth and h.InUseBatchId=b.BatchId and h.APTrans=b.APTrans
     		where APCo= @apco and InUseBatchId = @batchid and VendorGroup = @vendorgroup and
                 	Vendor = @vendor and b.BatchSeq=@batchseq
     	
     
             select d.CSCaseId, @maxpaydate, a.InvTotal, c.SSN, d.CSMedCov,c.LastName, c.FirstName, d.CSFipsCode, c.ActiveYN
             from APTH a JOIN APTB b ON a.APCo=b.Co and a.InUseMth=b.Mth and a.InUseBatchId=b.BatchId and a.APTrans=b.APTrans
     		join PREH c on a.PRCo = c.PRCo and a.Employee = c.Employee
             join PRED d on a.PRCo = d.PRCo and a.Employee = d.Employee and a.DLcode = d.DLCode
             where a.APCo= @apco and a.InUseBatchId = @batchid and
                 a.VendorGroup = @vendorgroup and a.Vendor = @vendor and b.BatchSeq=@batchseq
     
     	     end
         end
     --CTX format
      if @addendaformat = 2
         begin
         if @addendatype = 3 -- Stub Detail
             begin
   			select APRef,InvDate, Description, Gross,'NetAmt'=(Gross-Retainage-PrevPaid-PrevDisc-Balance-DiscTaken) 
   			from	APTB WHERE Co = @apco and Mth=@month and BatchId = @batchid and BatchSeq=@batchseq
   	      end
         end

GO
GRANT EXECUTE ON  [dbo].[bspHQAPEFTAddenda] TO [public]
GO
