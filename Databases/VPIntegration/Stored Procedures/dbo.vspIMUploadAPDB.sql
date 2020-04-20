SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             proc [dbo].[vspIMUploadAPDB]
   	
   /***********************************************************
    * CREATED BY: MV   08/25/09
    * MODIFIED By :	MV	05/25/10 - #136500 - added param 'N' to bspProcessPartialPayment for '@ApplyCurrTaxRateYN' 
    *				GF 08/15/2010 - issue #135813 change for subcontract expanded
	*				MV 02/07/2011 - #142713 - validate AmountToPay against Invoice amount.
	*				ECV 05/25/11 - TK-05443 - Add SMPayType parameter to bspAPPayTypeGet
    *
    * USAGE: called from vspIMUploadHeaderDetailTextura. It
	*	creates bAPDB records for bAPTB and bAPPB records 
	*	created by vspIMUPloadHeaderDetailTextura.  Or for
	*	retainage, it creates bAPTBs and bAPDBs as necessary
	*	for released retainage.
    *
    * INPUT PARAMETERS
    *   VendorGroup   vendorgroup associated with the vendor
    *   Vendor	    Vendor
    *	AddressSeq    sequence # for the vendor address
    *	
    * OUTPUT PARAMETERS
    *	@msg   		error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@co bCompany, @batchmth bDate, @batchid int,@batchseq int,@ExpMth bDate,@APTrans bTrans,
	@APRef varchar(15),@InvDate bDate, @RetainageFlag bYN,@AmtToPay bDollar, @SL varchar(30), @TexturaYN bYN, @errmsg varchar(200) output) 
   as
   set nocount on
   
   declare @rcode int, @RetPayType int, @ReleasedAmt bDollar, @vendor bVendor,
	@vendorgroup bGroup, @opencursorAPTD int, @APTDMth bDate, @APTDAPTrans bTrans, @APTDAPRef varchar(15), @APTDInvDate bDate,
	@APTDLine int, @APTDSeq int, @APTDAmt bDollar, @APTDDesc varchar(30), @AmtLeftToPay bDollar, @AmtToSplit bDollar, @GrossAmt bDollar,
	@Description bDesc, @AmtOpenToPay bDollar

   
   select @rcode = 0, @opencursorAPTD = 0,@AmtLeftToPay = 0, @AmtToSplit = 0, @GrossAmt = 0, @AmtOpenToPay = 0
   
   if @co is null
   	begin
   	select @errmsg = 'Missing AP Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @batchmth is null
   	begin
   	select @errmsg = 'Missing Batch Mth!', @rcode = 1
   	goto bspexit
   	end
   
   if @batchid is null
   	begin
   	select @errmsg = 'Missing Batch Seq!', @rcode = 1
   	goto bspexit
   	end

	if @ExpMth is null
   	begin
   	select @errmsg = 'Missing Exp Mth!', @rcode = 1
   	goto bspexit
   	end
	
	if @APTrans is null
   	begin
   	select @errmsg = 'Missing AP Trans!', @rcode = 1
   	goto bspexit
   	end

	if @APRef is null
   	begin
   	select @errmsg = 'Missing AP Ref!', @rcode = 1
   	goto bspexit
   	end

	if @InvDate is null
   	begin
   	select @errmsg = 'Missing Inv Date!', @rcode = 1
   	goto bspexit
   	end

	if @AmtToPay is null
   	begin
   	select @errmsg = 'Missing Amount!', @rcode = 1
   	goto bspexit
   	end

	if @RetainageFlag is null
		begin
		select @RetainageFlag = 'N'
		end

	--validate Textura specific values
	if isnull(@TexturaYN,'N') = 'Y'
	begin
	if @SL is null and @RetainageFlag = 'R'
	begin
	select @errmsg = 'Missing SL!', @rcode = 1
	goto bspexit
	end
	end

	
	
	--get ret pay type 
	exec @rcode = dbo.bspAPPayTypeGet @co, null, null, null,null,null,
    	@RetPayType output, null,null,null, @errmsg output

	-- get vendor group and vendor
	select @vendor=Vendor, @vendorgroup = VendorGroup from dbo.APPB (nolock) where Co=@co and Mth=@batchmth
		and BatchId=@batchid and BatchSeq=@batchseq
 
--	 Regular Invoices - Non Retainage 
	if isnull(@RetainageFlag, 'N') = 'N'
	BEGIN
	-- make sure the bAPTB record exists  
	if not exists(select * from dbo.APTB (nolock) where Co=@co and Mth=@batchmth and BatchId=@batchid and
		BatchSeq=@batchseq and ExpMth=@ExpMth and APTrans=@APTrans and APRef=@APRef)
	begin
		select @errmsg = 'APTB payment transaction record does not exist for ExpMth: ' + convert(varchar(8),@ExpMth,1) +
			' APTrans: ' + convert(varchar(4),@APTrans) 
		select @rcode = 1
		goto bspexit
	end

--	 make sure APTD exists - 
   if not exists(select * from dbo.APTD d (nolock) 
	join dbo.APTH h (nolock) on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans 
	where d.APCo=@co and d.Mth=@ExpMth and d.APTrans=@APTrans and h.APRef = @APRef) 
	begin
		select @errmsg = 'APTD payment transaction detail does not exist for Mth: ' + convert(varchar(8),@ExpMth,1) +
			' APTrans: ' + convert(varchar(4),@APTrans) + ' APRef: ' + @APRef 
		select @rcode = 1
		goto bspexit
	end

	--validate open to pay against amount to pay
	IF ISNULL(@TexturaYN,'N') ='N'
	BEGIN
		SELECT @AmtOpenToPay = SUM(d.Amount - d.DiscTaken)
		FROM dbo.APTD d (NOLOCK) 
		JOIN dbo.APTH h (NOLOCK) ON d.APCo=h.APCo AND d.Mth=h.Mth AND d.APTrans=h.APTrans 
		WHERE d.APCo=@co AND d.Mth=@ExpMth AND d.APTrans=@APTrans AND h.APRef = @APRef AND d.Status=1
		-- Amount open to pay exceeds the import check amount.
		IF @AmtOpenToPay < @AmtToPay
		BEGIN
			SELECT @errmsg = 'Check amount exceeds open to pay for Mth: ' + CONVERT(VARCHAR(8),@ExpMth,1) +
				' APTrans: ' + CONVERT(varchar(4),@APTrans) + ' APRef: ' + @APRef 
			SELECT @rcode = 1
			GOTO bspexit
		END
		-- Amount open to pay is less than the import check amount.
		IF @AmtOpenToPay > @AmtToPay
		BEGIN
			SELECT @errmsg = 'Check amount is less than amount open to pay for Mth: ' + CONVERT(VARCHAR(8),@ExpMth,1) +
				' APTrans: ' + CONVERT(VARCHAR(4),@APTrans) + ' APRef: ' + @APRef 
			SELECT @rcode = 1
			GOTO bspexit
		END
	END
	ELSE
	BEGIN
		SELECT @AmtOpenToPay = SUM(d.Amount - d.DiscTaken)
		FROM dbo.APTD d (NOLOCK) 
		JOIN dbo.APTH h (NOLOCK) ON d.APCo=h.APCo AND d.Mth=h.Mth AND d.APTrans=h.APTrans 
		WHERE d.APCo=@co AND d.Mth=@ExpMth AND d.APTrans=@APTrans AND h.APRef = @APRef 
			AND d.Status=1 AND d.PayType <> @RetPayType
		-- Amount open to pay exceeds the import check amount.
		IF @AmtOpenToPay < @AmtToPay
		BEGIN
			SELECT @errmsg = 'Check amount exceeds open to pay for Mth: ' + CONVERT(VARCHAR(8),@ExpMth,1) +
				' APTrans: ' + CONVERT(varchar(4),@APTrans) + ' APRef: ' + @APRef 
			SELECT @rcode = 1
			GOTO bspexit
		END
		-- Amount open to pay is less than the import check amount.
		IF @AmtOpenToPay > @AmtToPay
		BEGIN
			SELECT @errmsg = 'Check amount is less than amount open to pay for Mth: ' + CONVERT(VARCHAR(8),@ExpMth,1) +
				' APTrans: ' + CONVERT(VARCHAR(4),@APTrans) + ' APRef: ' + @APRef 
			SELECT @rcode = 1
			GOTO bspexit
		END
	END
	

--	 Create bAPDB recs 
	if isnull(@TexturaYN,'N') ='N'
		begin
		insert into dbo.APDB (
				Co,                            
				Mth,                           
				BatchId,                       
				BatchSeq,                      
				ExpMth,                        
				APTrans,                       
				APLine,                        
				APSeq,                         
				PayType,                       
				Amount,                        
				DiscTaken,                     
				PayCategory,                   
				TotTaxAmount)
			select @co,@batchmth,@batchid,@batchseq,@ExpMth,@APTrans,d.APLine,d.APSeq,d.PayType,d.Amount,d.DiscTaken,d.PayCategory,d.TotTaxAmount
			from dbo.APTD d join dbo.APTH h on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans 
			where d.APCo=@co and d.Mth=@ExpMth and d.APTrans=@APTrans and h.APRef = @APRef and d.Status=1 
				
			if @@rowcount = 0
				begin
				select @errmsg = 'APDB payment transaction detail was not created for Mth: ' + convert(varchar(8),@ExpMth,1) +
					' APTrans: ' + convert(varchar(4),@APTrans) + ' APRef: ' + @APRef + '.'
				select @rcode = 1
				goto bspexit
				end
			else
				begin
				-- update APTB with gross, description
				select @GrossAmt = sum(Amount) from dbo.APTD where APCo = @co and Mth = @ExpMth and APTrans = @APTrans
				select @Description from dbo.APTH where APCo = @co and Mth = @ExpMth and APTrans = @APTrans
				update dbo.APTB set Gross = @GrossAmt, Description=@Description
			   from dbo.APTB where Co = @co and Mth = @batchmth and BatchId = @batchid
			   and BatchSeq = @batchseq and ExpMth = @ExpMth and APTrans = @APTrans
				end
		end				
	else
		begin
			insert into dbo.APDB (
				Co,                            
				Mth,                           
				BatchId,                       
				BatchSeq,                      
				ExpMth,                        
				APTrans,                       
				APLine,                        
				APSeq,                         
				PayType,                       
				Amount,                        
				DiscTaken,                     
				PayCategory,                   
				TotTaxAmount)
			select @co,@batchmth,@batchid,@batchseq,@ExpMth,@APTrans,d.APLine,d.APSeq,d.PayType,d.Amount,d.DiscTaken,d.PayCategory,d.TotTaxAmount
			from dbo.APTD d join dbo.APTH h on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans 
			where d.APCo=@co and d.Mth=@ExpMth and d.APTrans=@APTrans and h.APRef = @APRef and d.Status=1 and d.PayType <> @RetPayType
				
			if @@rowcount = 0
				begin
				select @errmsg = 'APDB payment transaction detail was not created for Mth: ' + convert(varchar(8),@ExpMth,1) +
					' APTrans: ' + convert(varchar(4),@APTrans) + ' APRef: ' + @APRef + '.'
				select @rcode = 1
				goto bspexit
				end
			else
				begin
				-- update APTB with gross, description
				select @GrossAmt = sum(Amount) from dbo.APTD where APCo = @co and Mth = @ExpMth and APTrans = @APTrans
				select @Description from dbo.APTH where APCo = @co and Mth = @ExpMth and APTrans = @APTrans
				update dbo.APTB set Gross = @GrossAmt, Description=@Description
			   from dbo.APTB where Co = @co and Mth = @batchmth and BatchId = @batchid
			   and BatchSeq = @batchseq and ExpMth = @ExpMth and APTrans = @APTrans
				end
		end	
	
	END 

	-- Released retainage payments - This should be Textura only
	if @RetainageFlag = 'R' and @TexturaYN = 'Y'
	BEGIN
	-- validate that there is enough released retainage for what is being paid
	select @ReleasedAmt = sum(d.Amount) from dbo.APTD d (nolock) 
	join dbo.APTL l (nolock) on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
	join dbo.APTH h (nolock) on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans
	where d.APCo=@co and h.VendorGroup=@vendorgroup	and h.Vendor=@vendor and l.LineType=7 and l.SL=@SL and d.PayType=@RetPayType and d.Status=1
	if @ReleasedAmt < @AmtToPay
	begin
		select @errmsg = 'Retainage paid exceeds released retainage for Mth: ' + convert(varchar(8),@ExpMth,1) +
			' APTrans: ' + convert(varchar(4),@APTrans) + ' SL: ' + @SL + '.'
		select @rcode = 1
		goto bspexit
	end

	--create a cursor to spin through released retainage for this SL
	declare bcAPTDr cursor local fast_forward for
   	select l.Mth,l.APTrans,h.APRef,h.InvDate,l.Description, l.APLine,d.APSeq,d.Amount from dbo.APTD d (nolock) 
	join dbo.APTL l (nolock) on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
	join dbo.APTH h (nolock) on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans
	where d.APCo=@co and h.VendorGroup=@vendorgroup	and h.Vendor=@vendor and l.LineType=7 
		and l.SL=@SL and d.PayType=@RetPayType and d.Status=1
	order by d.Mth
   
   	-- open cursor
   	open bcAPTDr
   	select @opencursorAPTD = 1
   
   	APDB_loop:	-- process each APTD
   		fetch next from bcAPTDr into @APTDMth,@APTDAPTrans,@APTDAPRef,@APTDInvDate,@APTDDesc,@APTDLine,@APTDSeq,@APTDAmt 
   
   		if @@fetch_status <> 0 goto APTD_end
		-- If there is still retainage to pay continue processing
		if @AmtLeftToPay < @AmtToPay 
		Begin
			-- Insert APTB if needed
			if @APTDMth <> @ExpMth and @APTDAPTrans<>@APTrans and @APTDAPRef<>@APRef
			begin
			if not exists(select * from dbo.APTB where Co=@co and Mth=@batchmth and BatchId=@batchid and BatchSeq=@batchseq
				and ExpMth=@APTDMth and APTrans=@APTDAPTrans and APRef=@APTDAPRef)
				begin
				insert into dbo.APTB(Co,                            
					Mth,                           
					BatchId,                       
					BatchSeq,                      
					ExpMth,                        
					APTrans,                       
					APRef,                         
					Description,                   
					InvDate,                       
					Gross,                         
					Retainage,                     
					PrevPaid,                      
					PrevDisc,                      
					Balance,                       
					DiscTaken)
				select @co,@batchmth,@batchid,@batchseq,@APTDMth,@APTDAPTrans,@APTDAPRef,@APTDDesc,@APTDInvDate,0,0,0,0,0,0
				if @@rowcount = 0
					begin
					select @errmsg = 'APTB transaction payment rec was not created for ExpMth: ' + convert(varchar(8),@APTDMth,1) +
					' APTrans: ' + convert(varchar(4),@APTDAPTrans) + ' SL: ' + @SL + '.'
					select @rcode = 1
					goto APTD_end
					end
				end 
			end

			-- insert APDB 
			if not exists(select * from dbo.APDB where Co=@co and Mth=@batchmth and BatchId=@batchid and BatchSeq=@batchseq
				and ExpMth=@APTDMth and APTrans=@APTDAPTrans and APLine=@APTDLine and APSeq=@APTDSeq)
			begin	
			-- split APTD if Amount is more than what is left to pay on retainage
			if @APTDAmt > (@AmtToPay - @AmtLeftToPay)
--			@APTDAmt >   (@AmtToPay - @AmtLeftToPay)
--			   150   > 100 (500     -    400)			
--			Seq 2 = 100 
--			Seq 3 =  50
--			Send over $50
			-- split APTD retainage payment
				begin
				select @AmtToSplit = @APTDAmt - (@AmtToPay - @AmtLeftToPay)
				exec @rcode = bspAPProcessPartialPayments @co, @APTDMth, @APTDAPTrans,@APTDLine, @APTDSeq,
				   @AmtToSplit, null, 'N', null,'Y', null, 'Y', 'N', @errmsg output
				if @rcode <> 0
					begin
					select @errmsg = @errmsg + ' - APTD payment split was not made for Mth: ' + convert(varchar(8),@APTDMth,1) +
					' APTrans: ' + convert(varchar(4),@APTDAPTrans) + ' SL: ' + @SL + '.'
					select @rcode = 1
					goto APTD_end
					end
				else
					--set APTD Amount - Amount minus what was split out
					select @APTDAmt = @APTDAmt - @AmtToSplit
				end

			-- Insert APDB	
			insert into dbo.APDB (Co,                            
				Mth,                           
				BatchId,                       
				BatchSeq,                      
				ExpMth,                        
				APTrans,                       
				APLine,                        
				APSeq,                         
				PayType,                       
				Amount,                        
				DiscTaken,                     
				PayCategory,                   
				TotTaxAmount)
			select @co,@batchmth,@batchid,@batchseq,@APTDMth,@APTDAPTrans,@APTDLine,@APTDSeq,PayType,@APTDAmt,DiscTaken,PayCategory,TotTaxAmount
			from dbo.APTD 
			where APCo=@co and Mth=@APTDMth and APTrans=@APTDAPTrans and APLine=@APTDLine and APSeq=@APTDSeq
			if @@rowcount = 0
				begin
				select @errmsg = 'APDB payment transaction detail was not created for ExpMth: ' + convert(varchar(8),@APTDMth,1) +
					' APTrans: ' + convert(varchar(4),@APTDAPTrans) + ' SL: ' + @SL + '.'
				select @rcode = 1
				goto APTD_end
				end
			else
			begin
			select @AmtLeftToPay = @AmtLeftToPay + @APTDAmt
			-- update APTB with gross, description
			select @GrossAmt = sum(Amount) from dbo.APTD where APCo = @co and Mth = @APTDMth and APTrans = @APTDAPTrans
			select @Description from dbo.APTH where APCo = @co and Mth = @APTDMth and APTrans = @APTDAPTrans
			update dbo.APTB set Gross = @GrossAmt, Description=@Description
			   from dbo.APTB where Co = @co and Mth = @batchmth and BatchId = @batchid
			   and BatchSeq = @batchseq and ExpMth = @APTDMth and APTrans = @APTDAPTrans
			end 
		end	
		End
		goto APDB_loop

		APTD_end:	
       	close bcAPTDr
           deallocate bcAPTDr
   		select @opencursorAPTD = 0

	END

   
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspIMUploadAPDB] TO [public]
GO
