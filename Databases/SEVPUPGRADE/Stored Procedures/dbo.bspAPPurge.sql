
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspbcAPPurge    Script Date: 8/28/99 9:34:04 AM ******/
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
	   *				GF 02/28/2013 TFS-42481 added option and year to purge ATO annual tax payments
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
		  ----TFS-42481
		  @ATOPurge bYN = 'N', @ATOTaxYear CHAR(4) = NULL,
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
   	
   	
   -- #22086 COMMENTED OUT PSEUDO CURSOR CODING
   --      -- get first Month
   --    		select @KeyMonth=min(Mth) from bAPTH where APCo=@co
   --    		while @KeyMonth is not null
   --    			begin
   --                -- get the first Transaction
   --    			select @KeyTrans=min(l.APTrans) from bAPTH c, bAPTL l, bAPTD d, bAPVM b
   --    				where c.APCo=d.APCo and c.Mth=d.Mth and c.APTrans=d.APTrans
   --    				and c.APCo=l.APCo and c.Mth=l.Mth and c.APTrans=l.APTrans
   --    				and b.VendorGroup=c.VendorGroup and b.Vendor=c.Vendor
   --    				and d.APCo=@co and d.Mth=@KeyMonth and d.Status>=3 and b.Purge='N'
   --    				/*and (l.LineType<6 or (l.LineType=6 and l.PO not in (select PO from
   --    				bPOHD where POCo=@co)) or (l.LineType=7 and l.SL not in (select SL
   --    				from bSLHD where SLCo=@co)))*/ and (c.APTrans not in (select APTrans from bAPTD
   --    				where APCo=@co and Mth=@KeyMonth and (Status<3 or (PaidMth>@transmth or
   --    				PaidMth is null))))
   --  
   --    			while @KeyTrans is not null
   --    				begin
   --              --get the total count on transaction lines
   --              select @validcnt1=Count(*) from bAPTL
   --                  where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans
   --  
   --  			--get the first line
   --  				select @KeyLine=min(l.APLine) from bAPTH c, bAPTL l, bAPTD d, bAPVM b
   --    					where c.APCo=d.APCo and c.Mth=d.Mth and c.APTrans=d.APTrans
   --    					and c.APCo=l.APCo and c.Mth=l.Mth and c.APTrans=l.APTrans
   --    					and b.VendorGroup=c.VendorGroup and b.Vendor=c.Vendor
   --    					and d.APCo=@co and d.Mth=@KeyMonth and d.Status>=3 and b.Purge='N'
   --    					and (l.LineType<6 or (l.LineType=6 and l.PO not in (select PO from
   --    					bPOHD where POCo=@co)) or (l.LineType=7 and l.SL not in (select SL
   --    					from bSLHD where SLCo=@co))) and (c.APTrans not in (select APTrans from bAPTD
   --    					where APCo=@co and Mth=@KeyMonth and (Status<3 or (PaidMth>@transmth or
   --    					PaidMth is null)))) and l.APTrans=@KeyTrans
   --  
   --  				while @KeyLine is not null
   --  					begin
   --                 		select @validcnt2=@validcnt2+1
   --  			--get next line
   --  					select @KeyLine=min(l.APLine) from bAPTH c, bAPTL l, bAPTD d, bAPVM b
   --    						where c.APCo=d.APCo and c.Mth=d.Mth and c.APTrans=d.APTrans
   --    						and c.APCo=l.APCo and c.Mth=l.Mth and c.APTrans=l.APTrans
   --    						and b.VendorGroup=c.VendorGroup and b.Vendor=c.Vendor
   --    						and d.APCo=@co and d.Mth=@KeyMonth and d.Status>=3 and b.Purge='N'
   --    						and (l.LineType<6 or (l.LineType=6 and l.PO not in (select PO from
   --    						bPOHD where POCo=@co)) or (l.LineType=7 and l.SL not in (select SL
   --    						from bSLHD where SLCo=@co))) and (c.APTrans not in (select APTrans from bAPTD
   --    						where APCo=@co and Mth=@KeyMonth and (Status<3 or (PaidMth>@transmth or
   --    						PaidMth is null)))) and l.APTrans=@KeyTrans and l.APLine >@KeyLine
   --  					if @@rowcount=0 select @KeyLine=null
   --  					end
   --  
   --                  if @validcnt1=@validcnt2
   --                      begin
   --  			-- set Purge flag to prevent HQ auditing
   --                 	    update bAPTH set Purge='Y' where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans
   --  			--delete transaction
   --                      delete from bAPTD where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans
   --    				    delete from bAPTL where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans
   --  				    delete from bAPTH where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans
   --  
   --    				    if @@rowcount=0  select @nothing=1
   --                  			else select @nothing=0
   --                      end
   --  
   --  		    --set the counters to zero
   --                  select @validcnt1=0, @validcnt2=0
   --  
   --              -- get next Transaction
   --    				select @KeyTrans=min(l.APTrans) from bAPTH c, bAPTL l, bAPTD d, bAPVM b
   --    					where c.APCo=d.APCo and c.Mth=d.Mth and c.APTrans=d.APTrans
   --    					and c.APCo=l.APCo and c.Mth=l.Mth and c.APTrans=l.APTrans
   --    					and b.VendorGroup=c.VendorGroup and b.Vendor=c.Vendor
   --    					and d.APCo=@co and d.Mth=@KeyMonth and d.Status>=3 and b.Purge='N'
   --    					/*and (l.LineType<6 or (l.LineType=6 and l.PO not in (select PO from
   --    					bPOHD where POCo=@co)) or (l.LineType=7 and l.SL not in (select SL
   --    					from bSLHD where SLCo=@co)))*/ and (c.APTrans not in (select APTrans from bAPTD
   --    					where APCo=@co and Mth=@KeyMonth and (Status<3 or (PaidMth>@transmth or
   --    					PaidMth is null)))) and l.APTrans>@KeyTrans
   --    				if @@rowcount=0 select @KeyTrans=null
   --    				end
   --             -- get next Month
   --    			select @KeyMonth=min(Mth) from bAPTH where APCo=@co and Mth>@KeyMonth
   --    			if @@rowcount=0 select @KeyMonth=null
   --    			end
   --    		end
    	-- END COMMENT OUT
   
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
   
   	-- #22086 COMMENTED OUT PSEUDO CURSOR CODING
   --          -- get first month
   --    		select @KeyMonth=min(Mth) from bAPTH where APCo=@co
   --    		while @KeyMonth is not null
   --    			begin
   --              -- get first Transaction
   --    			select @KeyTrans=min(l.APTrans) from bAPTH c, bAPTL l, bAPTD d, bAPVM b
   --    				where c.APCo=d.APCo and c.Mth=d.Mth and c.APTrans=d.APTrans
   --    				and c.APCo=l.APCo and c.Mth=l.Mth and c.APTrans=l.APTrans
   --    				and b.VendorGroup=c.VendorGroup and b.Vendor=c.Vendor
   -- 
   --    				and d.APCo=@co and d.Mth=@KeyMonth and d.Status>=3 --and b.Purge='N'
   --    				/*and (l.LineType<6 or (l.LineType=6 and l.PO not in (select PO from
   --    				bPOHD where POCo=@co)) or (l.LineType=7 and l.SL not in (select SL
   --    					from bSLHD where SLCo=@co)))*/ and (c.APTrans not in (select APTrans from bAPTD
   --    				where APCo=@co and Mth=@KeyMonth and (Status<3 or (PaidMth>@transmth or
   --    				PaidMth is null)))) and c.VendorGroup=@vendorgroup and c.Vendor=@vendor
   --  
   --    			while @KeyTrans is not null
   --    				begin
   --                  --get the total count on transaction lines
   --                  select @validcnt1=Count(*) from bAPTL
   --                  where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans
   --  
   --  				--get the first line
   --  				select @KeyLine=min(l.APLine) from bAPTH c, bAPTL l, bAPTD d, bAPVM b
   --    					where c.APCo=d.APCo and c.Mth=d.Mth and c.APTrans=d.APTrans
   --    					and c.APCo=l.APCo and c.Mth=l.Mth and c.APTrans=l.APTrans
   --    					and b.VendorGroup=c.VendorGroup and b.Vendor=c.Vendor
   --    					and d.APCo=@co and d.Mth=@KeyMonth and d.Status>=3 --and b.Purge='N'
   --    					and (l.LineType<6 or (l.LineType=6 and l.PO not in (select PO from
   --    					bPOHD where POCo=@co)) or (l.LineType=7 and l.SL not in (select SL
   --    					from bSLHD where SLCo=@co))) and (c.APTrans not in (select APTrans from bAPTD
   --    					where APCo=@co and Mth=@KeyMonth and (Status<3 or (PaidMth>@transmth or
   --    					PaidMth is null)))) and c.VendorGroup=@vendorgroup and c.Vendor=@vendor and l.APTrans=@KeyTrans
   --  
   --  				while @KeyLine is not null
   --  					begin
   --  			        select @validcnt2=@validcnt2+1
   --  			--get next line
   --  					select @KeyLine=min(l.APLine) from bAPTH c, bAPTL l, bAPTD d, bAPVM b
   --    						where c.APCo=d.APCo and c.Mth=d.Mth and c.APTrans=d.APTrans
   --    						and c.APCo=l.APCo and c.Mth=l.Mth and c.APTrans=l.APTrans
   --    						and b.VendorGroup=c.VendorGroup and b.Vendor=c.Vendor
   --    						and d.APCo=@co and d.Mth=@KeyMonth and d.Status>=3 --and b.Purge='N'
   --    						and (l.LineType<6 or (l.LineType=6 and l.PO not in (select PO from
   --    						bPOHD where POCo=@co)) or (l.LineType=7 and l.SL not in (select SL
   --    						from bSLHD where SLCo=@co))) and (c.APTrans not in (select APTrans from bAPTD
   --    						where APCo=@co and Mth=@KeyMonth and (Status<3 or (PaidMth>@transmth or
   --    						PaidMth is null)))) and c.VendorGroup=@vendorgroup and c.Vendor=@vendor
   --  						and l.APTrans=@KeyTrans and l.APLine>@KeyLine
   --  					if @@rowcount=0 select @KeyLine=null
   --  					end
   --  
   --                  if @validcnt1=@validcnt2
   --                      begin
   --                 	    update bAPTH set Purge='Y' where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans
   --  			     -- delete transaction
   --    				  delete from bAPTD where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans    --and APLine=@KeyLine
   --    				  delete from bAPTL where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans    --and APLine=@KeyLine
   --  				  delete from bAPTH where APCo=@co and Mth=@KeyMonth and APTrans=@KeyTrans
   --  
   --    				    if @@rowcount=0  select @nothing=1
   --                  			else select @nothing=0
   --                      end
   --  
   --                   --set the counters to zero
   --                      select @validcnt1=0, @validcnt2=0
   --  
   --                  -- get next Transaction
   --    				select @KeyTrans=min(l.APTrans), @KeyLine=min(l.APLine) from bAPTH c, bAPTL l, bAPTD d, bAPVM b
   --    					where c.APCo=d.APCo and c.Mth=d.Mth and c.APTrans=d.APTrans
   --    					and c.APCo=l.APCo and c.Mth=l.Mth and c.APTrans=l.APTrans
   --    					and b.VendorGroup=c.VendorGroup and b.Vendor=c.Vendor
   --    					and d.APCo=@co and d.Mth=@KeyMonth and d.Status>=3 --and b.Purge='N'
   --    					/*and (l.LineType<6 or (l.LineType=6 and l.PO not in (select PO from
   --    					bPOHD where POCo=@co)) or (l.LineType=7 and l.SL not in (select SL
   --    					from bSLHD where SLCo=@co)))*/ and (c.APTrans not in (select APTrans from bAPTD
   --    					where APCo=@co and Mth=@KeyMonth and (Status<3 or (PaidMth>@transmth or
   --    					PaidMth is null)))) and l.APTrans>@KeyTrans and c.VendorGroup=@vendorgroup
   --    					and c.Vendor=@vendor
   --    				if @@rowcount=0 select @KeyTrans=null
   --    				end
   --              -- get next Month
   --    			select @KeyMonth=min(Mth) from bAPTH where APCo=@co and Mth>@KeyMonth
   --    			if @@rowcount=0 select @KeyMonth=null
   --    			end
   --    		end
   --    	end
    -- END COMMENT OUT 
   
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
   
   
   /* #22086  - COMMENTED OUT PSEUDO CURSOR CODING
     select @KeyVendor=min(Vendor) from bAPVM where VendorGroup = @vendorgroup and TempYN = 'Y'
         and Vendor not in (select distinct Vendor from bAPTH where VendorGroup = @vendorgroup)
    
         and Vendor not in (select distinct Vendor from bPOHD where VendorGroup = @vendorgroup)
         and Vendor not in (select distinct Vendor from bSLHD where VendorGroup = @vendorgroup)
     and Vendor not in (select distinct Vendor from bAPRH where VendorGroup = @vendorgroup)
    
     while @KeyVendor is not null
         begin
         -- remove Vendor 1099 Totals
         delete bAPFT where VendorGroup = @vendorgroup and Vendor = @KeyVendor
         -- remove Vendor Activity
         delete bAPVA where VendorGroup = @vendorgroup and Vendor = @KeyVendor
         -- remove Vendor Compliance
         delete bAPVC where VendorGroup = @vendorgroup and Vendor = @KeyVendor
         -- remove Vendor Hold Codes
         delete bAPVH where VendorGroup = @vendorgroup and Vendor = @KeyVendor
         -- remove Vendor Master
         delete bAPVM where VendorGroup = @vendorgroup and Vendor = @KeyVendor
   t=0 and @nothing=1 select @nothing=1              --nothing purged
         else select @nothing=0                                        --something purged
    
         -- get next Vendor
         select @KeyVendor=min(Vendor) from bAPVM where VendorGroup = @vendorgroup and TempYN = 'Y'
             and Vendor not in (select distinct Vendor from bAPTH where VendorGroup = @vendorgroup)
             and Vendor not in (select distinct Vendor from bPOHD where VendorGroup = @vendorgroup)
             and Vendor not in (select distinct Vendor from bSLHD where VendorGroup = @vendorgroup)
             and Vendor not in (select distinct Vendor from bAPRH where VendorGroup = @vendorgroup)
    
         if @@rowcount=0 select @KeyVendor=null
         end
   */ --END COMMENT OUT
    
      -- Purge Vendor Activity
      if @vendortotsyn='Y'
      	begin
      	delete bAPVA where APCo=@co and Mth<=@vendortotmth
    
      	if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
        else select @nothing=0                                        --something purged
    
      	end
    
      -- Purge Vendor 1099 Totals
      if @1099totsyn='Y'
      	begin
      	delete bAPFT where APCo=@co and YEMO<=@1099year
    
      	if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
        else select @nothing=0                                        --something purged
    
      	end



---- TFS-42481 Purge Annual Tax Payment History
IF @ATOPurge = 'Y'
	BEGIN
    
	---- delete tax payments
	BEGIN TRY
    
		---- start a transaction, commit after fully processed
		BEGIN TRANSACTION;
  
		---- delete ATO payee data
		DELETE FROM dbo.vAPAUPayeeTaxPaymentATO WHERE APCo = @co AND TaxYear = @ATOTaxYear

		---- delete ATO payer data
		DELETE FROM dbo.vAPAUPayerTaxPaymentATO WHERE APCo = @co AND TaxYear = @ATOTaxYear

		if @@rowcount=0 and @nothing=1 select @nothing=1              --nothing purged
			else select @nothing=0                                    --something purged

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
