SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            procedure [dbo].[bspAPDtlDiscountDistribution]
    
       
    /***********************************************************
     * CREATED BY: EN 11/06/97
     * MODIFIED BY: EN 1/25/99
     * 		MV 3/15/02 14160 - distribute discoffered and
     * 		disctaken to bAPWD which updates bAPTD
     *         kb 5/28/2 - issue #14160
     *			MV 09/20/02 - issue 18629
     *         kb 10/28/2 - issue #18878 - fix double quotes
     *			MV 06/24/03 - #21573 - fix check for retainage
     *			MV 02/13/04 - #18769 - Pay Category 
     *			MV 10/16/07 - #28547 - distribute discount by percentage
     * USAGE:
     * Distributes a specified discount to all details for a
     * transaction which are either open or on hold.  Replaces
     * any previous discounts for these details.  Discount
     * offered and/or discount taken will be changed.
     * 
     *  INPUT PARAMETERS
     *   @apco	AP company number
     *   @mth	expense month of trans
     *   @aptrans	transaction to restrict by 
     *   @discountamt	discount amount to distribute
     *   @optdiscoffered	option to change DiscOffered fields
     *   @optdisctaken	option to change DiscTaken fields
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs 
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
    *********************************
    **********************************/ 
    (@apco bCompany = 0, @mth bMonth, @aptrans bTrans, @discountamt bDollar = null,
     @discountpct bPct = null, @usediscpctyn bYN = null, @usediscamtyn bYN = null,
		@optdiscoffered varchar(1),@optdisctaken varchar(1), @msg varchar(90) output)
    
    as
    set nocount on
    
    declare @rcode tinyint, @totaldiscoffer bDollar, @totaldisctaken bDollar, @totalamount bDollar,
   	@apretpaytype tinyint
    
    select @rcode=0
    
    /* validate discount amount */
    if @usediscamtyn = 'Y' and @discountamt is null 
    	begin
    	 select @msg = 'Missing discount amount.', @rcode = 1
    	 goto bspexit
    	end
    if @usediscamtyn = 'Y' and @discountamt < 0
    	begin
    	 select @msg = 'Discount amount must be positive.', @rcode = 1
    	 goto bspexit
    	end
	if @usediscpctyn = 'Y' and @discountpct is null
		begin
    	 select @msg = 'Missing discount percent.', @rcode = 1
    	 goto bspexit
    	end
	if @usediscpctyn = 'Y' and @discountpct < 0
		begin
    	 select @msg = 'Discount percent must be positive.', @rcode = 1
    	 goto bspexit
    	end

    /* do not allow discount on retainage-only transactions */
   --  if (select sum(Amount) from bAPTD
   --   where APCo=@apco and Mth=@mth and APTrans=@aptrans and Status<>3 and Status<>4
   --   and PayType<>(select RetPayType from bAPCO where APCo=@apco)) = 0
   --   	begin
   --  	 select @msg = 'Cannot apply a discount to transactions with no retainage or zero amount.', @rcode = 1
   --  	 goto bspexit
   --   	end
     select @apretpaytype = RetPayType from bAPCO where APCo=@apco 
     select 1 from bAPTD d with (nolock) where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.Status < 3
       --and d.PayType<> @apretpaytype
     	and ((d.PayCategory is null and d.PayType<> @apretpaytype) 
   		 or (d.PayCategory is not null and d.PayType <> (select c.RetPayType from bAPPC c with (nolock)
   			where c.APCo=@apco and c.PayCategory=d.PayCategory)))
   	if @@rowcount = 0
   	begin
    	 select @msg = 'Cannot apply a discount to retainage only transactions.', @rcode = 1
    	 goto bspexit
   	end
    
    select @totalamount = isnull((select sum(d.Amount) from bAPTD d where d.APCo=@apco
    		and d.Mth=@mth and d.APTrans=@aptrans and d.Status < 3
   		and ((d.PayCategory is null and d.PayType<>@apretpaytype) 
   		 	 or (d.PayCategory is not null and d.PayType <> (select c.RetPayType from bAPPC c with (nolock)
   				where c.APCo=@apco and c.PayCategory=d.PayCategory)))),0)
    		/*and d.PayType<>(select RetPayType from bAPCO where APCo=@apco)),0)*/
     	
	--calculate discount amount if using discount percent
	if @usediscpctyn = 'Y'
		begin
		select @discountamt =  @totalamount * @discountpct
		end
	
    /* update discounts - bAPWD updates bAPTD */	
    if @optdiscoffered='Y'
    	begin
    	/* distribute discounts */
    	update bAPWD
    		set DiscOffered = @discountamt*(t.Amount/@totalamount)
    		from bAPTD t join bAPWD w on w.APCo = t.APCo and w.Mth = t.Mth and w.APTrans = t.APTrans
           and w.APLine = t.APLine and w.APSeq = t.APSeq
    		where t.APCo=@apco and t.Mth=@mth and t.APTrans=@aptrans and t.Status < 3 
   		and ((t.PayCategory is null and t.PayType<>@apretpaytype) 
   		 	 or (t.PayCategory is not null and t.PayType <> (select c.RetPayType from bAPPC c with (nolock)
   				where c.APCo=@apco and c.PayCategory=t.PayCategory)))
    		/*and t.PayType<>(select RetPayType from bAPCO where APCo=@apco)*/
    
    	/* handle rounding error (if any) */	
    	select @totaldiscoffer = isnull((select sum(d.DiscOffer) from bAPTD d where d.APCo=@apco
    		and d.Mth=@mth and d.APTrans=@aptrans and d.Status < 3 
   		and ((d.PayCategory is null and d.PayType<>@apretpaytype) 
   		 	 or (d.PayCategory is not null and d.PayType <> (select c.RetPayType from bAPPC c with (nolock)
   				where c.APCo=@apco and c.PayCategory=d.PayCategory)))),0)
    		--and PayType<>(select RetPayType from bAPCO where APCo=@apco)),0)
    
   	update bAPWD
   		set DiscOffered=DiscOffered+(@discountamt-@totaldiscoffer)
    		from bAPTD t join bAPWD w on w.APCo = t.APCo and w.Mth = t.Mth and w.APTrans = t.APTrans
           and w.APLine = t.APLine and w.APSeq = t.APSeq
    		where t.APCo=@apco and t.Mth=@mth and t.APTrans=@aptrans and t.Status < 3 
   		and ((t.PayCategory is null and t.PayType<>@apretpaytype) 
   		 	 or (t.PayCategory is not null and t.PayType <> (select c.RetPayType from bAPPC c with (nolock)
   				where c.APCo=@apco and c.PayCategory=t.PayCategory)))
   		and t.APSeq=(select max(t2.APSeq) from bAPTD t2 where t2.APCo=@apco and t2.Mth=@mth and t2.APTrans=@aptrans and t2.Status < 3
   			 and ((t2.PayCategory is null and t2.PayType<>@apretpaytype) 
   		 	 	or (t2.PayCategory is not null and t2.PayType <> (select c2.RetPayType from bAPPC c2 with (nolock)
   							where c2.APCo=@apco and c2.PayCategory=t2.PayCategory))))
   --  		and t.PayType<>(select RetPayType from bAPCO where APCo=@apco
   -- 		and t.APSeq=(select max(APSeq) from bAPTD where APCo=@apco and Mth=@mth
   --  		and APTrans=@aptrans and Status < 3)
    	
    	end
    	
    if @optdisctaken='Y'
    	begin
    	/* distribute discounts */
    	update bAPWD 
    		set DiscTaken=@discountamt*(t.Amount/@totalamount)
    		from bAPTD t join bAPWD w on w.APCo = t.APCo and w.Mth = t.Mth 
           and w.APTrans = t.APTrans and w.APLine = t.APLine and w.APSeq = t.APSeq --w.APSeq -- #18629
    		where t.APCo=@apco and t.Mth=@mth and t.APTrans=@aptrans and t.Status<3
   		and ((t.PayCategory is null and t.PayType<>@apretpaytype) 
   		 	 or (t.PayCategory is not null and t.PayType <> (select c.RetPayType from bAPPC c with (nolock)
   				where c.APCo=@apco and c.PayCategory=t.PayCategory))) 
    		--and t.PayType<>(select RetPayType from bAPCO where APCo=@apco)
    	/*update bAPTD
    		set DiscTaken=@discountamt*(Amount/@totalamount)
    		where APCo=@apco and Mth=@mth and APTrans=@aptrans and Status<>3 and Status<>4
    		and PayType<>(select RetPayType from bAPCO where APCo=@apco)*/
    	/*update bAPTD
    		set DiscTaken=@discountamt*(Amount/isnull((select sum(Amount) from bAPTD where APCo=@apco
    		and Mth=@mth and APTrans=@aptrans and Status<>3 and Status<>4
    		and PayType<>(select RetPayType from bAPCO where APCo=@apco)),0))
    		where APCo=@apco and Mth=@mth and APTrans=@aptrans and Status<>3 and Status<>4
    		and PayType<>(select RetPayType from bAPCO where APCo=@apco)*/
    
    	
    	/* handle rounding error (if any) */	
    	select @totaldisctaken = isnull((select sum(d.DiscTaken) from bAPTD d where d.APCo=@apco
    		and d.Mth=@mth and d.APTrans=@aptrans and d.Status<3 
   		and ((d.PayCategory is null and d.PayType<>@apretpaytype) 
   		 	 or (d.PayCategory is not null and d.PayType <> (select c.RetPayType from bAPPC c with (nolock)
   				where c.APCo=@apco and c.PayCategory=d.PayCategory)))),0)
    		--and PayType<>(select RetPayType from bAPCO where APCo=@apco)),0)
    	update bAPWD 
    		set DiscTaken=t.DiscTaken+(@discountamt-@totaldisctaken)
    		from bAPTD t join bAPWD w on w.APCo = t.APCo and w.Mth = t.Mth 
           and w.APTrans = t.APTrans and w.APLine = t.APLine and w.APSeq = t.APSeq
    		where t.APCo=@apco and t.Mth=@mth and t.APTrans=@aptrans and t.Status<3
   		and ((t.PayCategory is null and t.PayType<>@apretpaytype) 
   		 	 or (t.PayCategory is not null and t.PayType <> (select c.RetPayType from bAPPC c with (nolock)
   				where c.APCo=@apco and c.PayCategory=t.PayCategory)))
   		and t.APSeq=(select max(t2.APSeq) from bAPTD t2 where t2.APCo=@apco and t2.Mth=@mth and t2.APTrans=@aptrans and t2.Status < 3
   			 and ((t2.PayCategory is null and t2.PayType<>@apretpaytype) 
   		 	 	or (t2.PayCategory is not null and t2.PayType <> (select c2.RetPayType from bAPPC c2 with (nolock)
   							where c2.APCo=@apco and c2.PayCategory=t2.PayCategory)))) 
   --  		and t.PayType<>(select RetPayType from bAPCO where APCo=@apco)
   --  		and t.APSeq=(select max(APSeq) from bAPTD where APCo=@apco and Mth=@mth
   --  		and APTrans=@aptrans and Status<>3 and Status<>4)
    	/*update bAPTD
    		set DiscTaken=DiscTaken+(@discountamt-@totaldisctaken)
    		where APCo=@apco and Mth=@mth and APTrans=@aptrans and Status<>3 and Status<>4
    		and PayType<>(select RetPayType from bAPCO where APCo=@apco)
    		and APSeq=(select max(APSeq) from bAPTD where APCo=@apco and Mth=@mth
    		and APTrans=@aptrans and Status<>3 and Status<>4)*/
    	
    	/*update bAPTD
    		set DiscTaken=DiscTaken+(@discountamt-isnull((select sum(DiscTaken) from bAPTD where APCo=@apco
    		and Mth=@mth and APTrans=@aptrans and Status<>3 and Status<>4
    		and PayType<>(select RetPayType from bAPCO where APCo=@apco)),0))
    		where APCo=@apco and Mth=@mth and APTrans=@aptrans and Status<>3 and Status<>4
    		and PayType<>(select RetPayType from bAPCO where APCo=@apco)
    		and APSeq=(select max(APSeq) from bAPTD where APCo=@apco and Mth=@mth
    		and APTrans=@aptrans and Status<>3 and Status<>4)*/
    
    
    	end
    		
    bspexit:
    
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPDtlDiscountDistribution] TO [public]
GO
