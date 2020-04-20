SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE       proc [dbo].[bspAPPurge]
    
/****************************************************************************************
* CREATED BY: kb 10/10/97
* MODIFIED By : kb 8/4/98
*              GR 07/23/99     -- Modified to use tables instead of views
*              GG 07/26/99     -- Added Temporary Vendor purge
*              GR 01/17/00     -- corrected temporary vendor purge
*              GR 012/12/00    -- modified to scroll through each transaction line instead
*                                 of just being by each transaction to check for existence before deleting\
*              kb 10/29/2 - issue #18878 - fix double quotes
*				MV 08/19/03 - #22086 remove pseudo cursors and old style joins 
*				MV 09/19/03 - #22517 - purge lineless transactions, commented out purge flag for selected vendor
*				MV 02/10/04 - #23691 - close cursors only if they were opened.
*				MV 12/21/05 - #119693 - don't check for null in @tempandpaidyn
*				MV 02/20/07 - #12127 - check for vendor in bAPPH and delete from bAPAA 
*				MV 10/23/08 - #126754 - purge Pay History before purging temp vendors
*				GF 06/24/2010 - issue #135813 expanded SL to varchar(30)
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 02/28/2013 TFS-42481 added year to purge ATO annual tax payments
*				GF 05/13/2013 TFS-45317 added option for T5018 period end date annual totals
*				@1099totsyn will be used for all 3 countries to indicate if totals should be purged.
*
*
* Called by AP Purge program to delete paid transactions, temporary vendors,
* monthly vendor totals, annual 1099 totals, and/or payment history.
* Will skip transactions posted to POs or Subcontracts that still exist.
*
* INPUT PARAMETERS
*  @co                     AP Company
*  @tempandpaidyn          'Y' = purge paid transactions and temporary vendors
*  @vendorgroup            Vendor Group
*  @vendor                 Vendor to purge paid transaction - if null, all Vendors where Selective Purge = 'N'
*  @transmth               Purge through month for transactions - no payments after this month
*  @vendortotsyn           'Y' = purge vendor activity totals
*  @vendortotmth           Purge through month for vendor activity totals
*  @1099totsyn             'Y' = purge 1099 totals
*  @1099year               Purge through year ending month for 1099 totals
*  @payhistoryyn           'Y' = purge payment history
*  @payhistorymth          Purge through month for payment history
*
* OUTPUT PARAMETERS
*  @nothing                0 = something purged, 1 = nothinbg was purged
*  @msg                    error message
*
* RETURN VALUE
*  @rcode                  0 = success, 1 = failure
****************************************************************************************/
(@co bCompany, @tempandpaidyn bYN = null, @vendorgroup bGroup = null, @vendor bVendor = null,
 @transmth bMonth = null, @vendortotsyn bYN = null, @vendortotmth bMonth = null, @1099totsyn bYN = null,
 @1099year bMonth=null, @payhistoryyn bYN = null, @payhistorymth bMonth = null,
 ----TFS-42481 TFS-45317
 @ATOTaxYear CHAR(4) = NULL,
 @T5PeriodEndDate bDate = NULL,
 @nothing tinyint output, @msg varchar(255) output)
    
      as
    
      set nocount on
    
      declare @rcode int,  @KeyMonth bMonth, @KeyTrans bTrans, @KeyVendor bVendor, @KeyLine  int,
            @validcnt1 int, @validcnt2 int, @opencursor int, @mth bMonth, @aptrans int, @po varchar(30),
   		 @sl VARCHAR(30), @tempvendor bVendor
    
      select @rcode=0, @nothing=1, @validcnt1=0, @validcnt2=0,@opencursor = 0
    
      -- Paid Transactions and Temporary Vendors
      if @tempandpaidyn ='Y' and @transmth is not null
      	BEGIN
      	if @vendor is null -- all Vendors, except those flagged for selective purge
      	begin
   		-- get transactions to purge  
   		declare bcAPPurge cursor LOCAL FAST_FORWARD for
   		select Mth, APTrans
   			from bAPTH h WITH (NOLOCK)
   			JOIN bAPVM v WITH (NOLOCK) on h.VendorGroup=v.VendorGroup and
   			h.Vendor=v.Vendor
   			WHERE h.APCo=@co and h.Mth <=@transmth and h.OpenYN='N' and v.Purge = 'N'	
   
   		open bcAPPurge
   		select @opencursor = 1
   
   		APPurge_loop:
   		fetch next from bcAPPurge into @mth, @aptrans
   
   		if @@fetch_status <> 0 goto APPurge_end
   
   		-- POs and SLs must be purged before deleting their paid transactions
   		select @po=PO, @sl=SL from bAPTL WITH (NOLOCK) where APCo=@co and Mth=@mth
   			and APTrans=@aptrans and LineType in (6, 7)
   			if @@rowcount > 0
   			begin
   			if @po is not null and exists (select 1 from bPOHD WITH (NOLOCK) where
   				POCo=@co and PO=@po) goto APPurge_loop
   			if @sl is not null and exists (select 1 from bSLHD WITH (NOLOCK) where
   				SLCo=@co and SL=@sl) goto APPurge_loop
   			end
   
   		-- Check for unpaid detail or detail with paid month > transmth 
   		if exists (select top 1 1 from bAPTD WITH (NOLOCK)
   		 	where APCo=@co and Mth=@mth and APTrans=@aptrans and
   			((Status < 3)  or (PaidMth>@transmth)))goto APPurge_loop
   			
   		-- set Purge flag to prevent HQ auditing
      	    update bAPTH set Purge='Y' where APCo=@co and Mth=@mth and APTrans=@aptrans
    		--delete transaction
            delete from bAPTD where APCo=@co and Mth=@mth and APTrans=@aptrans
   			delete from bAPTL where APCo=@co and Mth=@mth and APTrans=@aptrans
   			delete from bAPTH where APCo=@co and Mth=@mth and APTrans=@aptrans
   
   		 if @@rowcount=0  select @nothing=1 else select @nothing=0	
   
   		-- get next transaction
   		goto APPurge_loop	
   		end		

   
        -- purge paid transactions for select Vendor
      	if @vendor is not null
      	begin
   		-- get transactions to purge  
   		declare bcAPPurge cursor LOCAL FAST_FORWARD for
   		select Mth, APTrans
   			from bAPTH h WITH (NOLOCK)
   			JOIN bAPVM v WITH (NOLOCK) on h.VendorGroup=v.VendorGroup and
   			h.Vendor=v.Vendor
   			WHERE h.APCo=@co and h.Mth <=@transmth and h.Vendor=@vendor and h.OpenYN='N' /*and v.Purge = 'N' #22517*/
   		open bcAPPurge
   		select @opencursor = 1
   
   		APPurge2_loop:
   		fetch next from bcAPPurge into @mth, @aptrans
   
   		if @@fetch_status <> 0 goto APPurge_end
   
   		-- POs and SLs must be purged before deleting their paid transactions
   		select @po=PO, @sl=SL from bAPTL WITH (NOLOCK) where APCo=@co and Mth=@mth
   			and APTrans=@aptrans and LineType in (6, 7)
   			if @@rowcount > 0
   			begin
   			if @po is not null and exists (select 1 from bPOHD WITH (NOLOCK) where
   				POCo=@co and PO=@po) goto APPurge_loop
   			if @sl is not null and exists (select 1 from bSLHD WITH (NOLOCK) where
   				SLCo=@co and SL=@sl) goto APPurge_loop
   			end
   
   		-- Check for unpaid detail or detail with paid month > transmth 
   		if exists (select top 1 1 from bAPTD WITH (NOLOCK)
   		 	where APCo=@co and Mth=@mth and APTrans=@aptrans and
   			((Status < 3)  or (PaidMth>@transmth)))goto APPurge_loop
   			
   		-- set Purge flag to prevent HQ auditing
      	    update bAPTH set Purge='Y' where APCo=@co and Mth=@mth and APTrans=@aptrans
    		--delete transaction
            delete from bAPTD where APCo=@co and Mth=@mth and APTrans=@aptrans
   		 delete from bAPTL where APCo=@co and Mth=@mth and APTrans=@aptrans
   		 delete from bAPTH where APCo=@co and Mth=@mth and APTrans=@aptrans
   
   		 if @@rowcount=0  select @nothing=1 else select @nothing=0	
   
   		-- loop back for next transaction
   		goto APPurge2_loop
   		end
   
   	APPurge_end:
   		if @opencursor = 1
   		begin   
   			close bcAPPurge
   	    	deallocate bcAPPurge
   	    	select @opencursor = 0
   		end
   
    	-- Purge transactions without lines #22517
   	declare bcAPPurgeNoLines cursor LOCAL FAST_FORWARD for
   		select Mth, APTrans
   			from bAPTH h WITH (NOLOCK)
   			JOIN bAPVM v WITH (NOLOCK) on h.VendorGroup=v.VendorGroup and
   			h.Vendor=v.Vendor
   			WHERE h.APCo=@co and h.Mth <=@transmth and v.Purge = 'N'	
   
   		open bcAPPurgeNoLines
   		select @opencursor = 1
   
   	APPurgeNoLines_loop:
   		fetch next from bcAPPurgeNoLines into @mth, @aptrans
   
   		if @@fetch_status <> 0 goto APPurgeNoLines_end
   
   		select top 1 1 from bAPTL WITH (NOLOCK) where APCo=@co and Mth=@mth and APTrans=@aptrans
   		if @@rowcount = 0
   		begin
   		delete from bAPTH where APCo=@co and Mth=@mth and APTrans=@aptrans
   		if @@rowcount=0  select @nothing=1 else select @nothing=0	
   		end
   
   		goto APPurgeNoLines_loop
   
   	APPurgeNoLines_end:
   		if @opencursor = 1
   		begin   
   			close bcAPPurgeNoLines
   	    	deallocate bcAPPurgeNoLines
   	    	select @opencursor = 0
   		end
   
   	END -- End of Paid Transactions and Temporary Vendors
   
   
-- Purge Payment History
      if @payhistoryyn='Y'
      	begin
          -- update Purge flag to prevent HQ auditing during delete
      	update bAPPH set PurgeYN='Y' where APCo=@co and PaidMth<=@payhistorymth
          -- purge Payment History
   		delete bAPPD from bAPPD p JOIN bAPPH h on p.APCo=h.APCo and p.CMCo=h.CMCo and p.CMAcct=h.CMAcct
      		and p.PayMethod=h.PayMethod and p.CMRef=h.CMRef and p.CMRefSeq=h.CMRefSeq and
      		p.EFTSeq=h.EFTSeq
   		where h.APCo=@co and h.PaidMth <=@payhistorymth
   	 
      	delete bAPPH where APCo=@co and PaidMth<=@payhistorymth
    
      	if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
         else select @nothing=0                                      --something purged
    
      	end
    
     	-- purge Temporary Vendors
     	-- Skip Vendors that have any bAPTH, bPOHD, bSLHD, bAPRH, bAPPH entries in any AP Co#
     	select @vendorgroup = VendorGroup from bHQCO WITH (NOLOCK) where HQCo = @co
   		declare bcTempPurge cursor LOCAL FAST_FORWARD for
   		select Vendor from bAPVM WITH (NOLOCK) WHERE VendorGroup = @vendorgroup and TempYN = 'Y'
   
   		open bcTempPurge
   		select @opencursor = 1
   
   	APTempPurge_loop:
   		fetch next from bcTempPurge into @tempvendor
   
   		if @@fetch_status <> 0 goto APTempPurge_end
   		
   		-- check temp vendor for transactions, POs, SLs, recurring, unapproved, payment history 
   		if exists ( select top 1 1 from bAPTH WITH (NOLOCK) where VendorGroup = @vendorgroup and Vendor=@tempvendor)
   			goto APTempPurge_loop
   		if exists ( select top 1 1 from bPOHD WITH (NOLOCK) where VendorGroup = @vendorgroup and Vendor=@tempvendor)
   			goto APTempPurge_loop
   		if exists ( select top 1 1 from bSLHD WITH (NOLOCK) where VendorGroup = @vendorgroup and Vendor=@tempvendor)
   			goto APTempPurge_loop
   		if exists ( select top 1 1 from bAPRH WITH (NOLOCK) where VendorGroup = @vendorgroup and Vendor=@tempvendor)
   			goto APTempPurge_loop
   		if exists ( select top 1 1 from bAPUI WITH (NOLOCK) where VendorGroup = @vendorgroup and Vendor=@tempvendor)
   			goto APTempPurge_loop
		if exists ( select top 1 1 from bAPPH WITH (NOLOCK) where VendorGroup = @vendorgroup and Vendor=@tempvendor)
   			goto APTempPurge_loop
   
   		-- remove Vendor 1099 Totals
         	delete bAPFT where VendorGroup = @vendorgroup and Vendor = @tempvendor
         	-- remove Vendor Activity
         	delete bAPVA where VendorGroup = @vendorgroup and Vendor = @tempvendor
         	-- remove Vendor Compliance
         	delete bAPVC where VendorGroup = @vendorgroup and Vendor = @tempvendor
         	-- remove Vendor Hold Codes
         	delete bAPVH where VendorGroup = @vendorgroup and Vendor = @tempvendor
         	-- remove Addtional Addresses
         	delete bAPAA where VendorGroup = @vendorgroup and Vendor = @tempvendor
			-- remove Vendor Master
         	delete bAPVM where VendorGroup = @vendorgroup and Vendor = @tempvendor
         	if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
         	else select @nothing=0                                        --something purged
    
   		-- loop back for next temp vendor
   		goto APTempPurge_loop
   
   	APTempPurge_end:
   		if @opencursor = 1
   		begin   
   			close bcTempPurge
   	    	deallocate bcTempPurge
   	    	select @opencursor = 0	
   		end
   
    
-- Purge Vendor Activity
if @vendortotsyn='Y'
begin
	delete bAPVA where APCo=@co and Mth<=@vendortotmth
    
	if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
	else select @nothing=0                                        --something purged
    
end
    
---- TFS-47315 moved the 1099 totals purge into try catch
-- Purge Vendor 1099 Totals
--if @1099totsyn='Y'
--BEGIN
--delete bAPFT where APCo=@co and YEMO<=@1099year
--if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
--else select @nothing=0                                        --something purged
--end



---- TFS-42481 TFS-47315 Purge Annual 1099 totals/tax payment/T5018 totals
IF @1099totsyn = 'Y'
	BEGIN
    
	---- delete tax payments
	BEGIN TRY
    
		---- start a transaction, commit after fully processed
		BEGIN TRANSACTION;
  
		IF @1099year IS NOT NULL
			BEGIN
			---- delete 1099 totals          
        	delete bAPFT where APCo=@co and YEMO<=@1099year
    
      		if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
			else select @nothing=0                                        --something purged          
			END
        
		IF @ATOTaxYear IS NOT NULL
			BEGIN      
			---- delete ATO payee data
			DELETE FROM dbo.vAPAUPayeeTaxPaymentATO WHERE APCo = @co AND TaxYear = @ATOTaxYear

			---- delete ATO payer data
			DELETE FROM dbo.vAPAUPayerTaxPaymentATO WHERE APCo = @co AND TaxYear = @ATOTaxYear

			if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
				else select @nothing=0                                    --something purged
			END
  
		----TFS-47315
		IF @T5PeriodEndDate IS NOT NULL
			BEGIN      
			---- delete T5018 detail data
			DELETE FROM dbo.vAPT5018PaymentDetail WHERE APCo = @co AND PeriodEndDate <= @T5PeriodEndDate

			---- delete T5018 header data
			DELETE FROM dbo.vAPT5018Payment WHERE APCo = @co AND PeriodEndDate <= @T5PeriodEndDate

			if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
				else select @nothing=0                                    --something purged
			END

		---- insert for payee payments has completed. commit transaction
		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		-- Test XACT_STATE:
			-- If 1, the transaction is committable.
			-- If -1, the transaction is uncommittable and should 
			--     be rolled back.
			-- XACT_STATE = 0 means that there is no transaction and
			--     a commit or rollback operation would generate an error.
		IF XACT_STATE() <> 0
			BEGIN
			ROLLBACK TRANSACTION
			SET @msg = CAST(ERROR_MESSAGE() AS VARCHAR(200)) 
			SET @rcode = 1
			END
	END CATCH

	END




bspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspAPPurge] TO [public]
GO
