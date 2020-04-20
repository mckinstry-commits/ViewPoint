SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPTHTotalGet    Script Date: 8/28/99 9:34:05 AM ******/
   
    CREATE proc [dbo].[bspAPTHTotalGet]
       /********************************************************
       * CREATED BY: 	SE 9/22/97
       * MODIFIED BY:	GG 04/26/99
       *              kb 10/29/2 - issue #18878 - fix double quotes
	   *				MV 08/05/08 - #128288 - VAT taxtype
       *
       * USAGE:
       * 	Retrieves totals for an AP Invoice
       *
       * INPUT PARAMETERS:
       *	@apco		AP Co#
       *    @mth		Batch month
       *    @batchid	Batch ID #
       *    @batchseq	Batch Seq #
       *	@aptrans	AP Trans
       *
       * OUTPUT PARAMETERS:
       *	@gross		Gross Invoice
       *    @freight	Freight
       *    @salestax	Sales Tax
       *    @retainage	Retainage
       *    @discount	Discount
       *    @total		Total Invoice
       *	@msg		Error message
       *
       * RETURN VALUE:
       * 	0 	    Success
       *	1 & message Failure
       *
       **********************************************************/
       	(@apco  bCompany, @mth bMonth, @batchid bBatchID, @batchseq int,
       	@aptrans bTrans, @gross bDollar = null output,
       	@freight bDollar = null output, @salestax bDollar = null output,
       	@retainage bDollar = null output, @discount bDollar = null output,
       	@total bDollar = null output,  @msg varchar(60) output)
       as
   
       set nocount on
   
       declare @rcode int, @gross2 bDollar, @freight2 bDollar, @salestax2 bDollar,
       @retainage2 bDollar, @discount2 bDollar
   
       select @rcode = 0
       select @gross = 0, @freight = 0, @salestax = 0, @retainage = 0, @discount = 0, @total = 0
   
    -- get existing and changed amounts
    if @aptrans is not null
    	begin
        -- get amounts from existing lines
        select @gross = isnull(sum(GrossAmt),0),
            @freight = isnull(sum(case MiscYN when 'Y' then MiscAmt else 0 end),0),
            @salestax = isnull(sum(case TaxType when 2 then 0 else TaxAmt end),0),
            @retainage = isnull(sum(Retainage),0),
            @discount = isnull(sum(Discount),0)
        from bAPTL
        where APCo = @apco and Mth = @mth and APTrans = @aptrans
   
        -- get changed amounts from batch lines
        select @gross2 = isnull(sum(GrossAmt - OldGrossAmt),0),
            @freight2 = isnull(sum(case MiscYN when 'Y' then MiscAmt else 0 end) -
                sum(case OldMiscYN when 'Y' then OldMiscAmt else 0 end),0),
            @salestax2 = isnull(sum(case TaxType when 2 then 0 else TaxAmt end) -
                sum(case OldTaxType when 2 then 0 else OldTaxAmt end),0),
            @retainage2 = isnull(sum(Retainage - OldRetainage),0),
            @discount2 = isnull(sum(Discount - OldDiscount),0)
    	from bAPLB
    	where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    		and BatchTransType = 'C'
   
        -- combine existing amounts with changes
        select @gross = @gross + @gross2, @freight = @freight + @freight2, @salestax = @salestax + @salestax2,
            @retainage = @retainage + @retainage2, @discount = @discount + @discount2
    	end
   
    -- get amounts from new lines
   
    select @gross2 = isnull(sum(GrossAmt),0),
        @freight2 = isnull(sum (CASE MiscYN WHEN 'Y' THEN MiscAmt ELSE 0 END),0),
        @salestax2 = isnull(sum (CASE TaxType WHEN 2 THEN 0 ELSE TaxAmt END),0),
        @retainage2 = isnull(sum(Retainage),0),
        @discount2 = isnull(sum(Discount),0)
    from bAPLB
    where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and BatchTransType = 'A'
   
    -- accumulate new and changed amounts
    select @gross = @gross + @gross2, @freight = @freight + @freight2,
       	@salestax = @salestax + @salestax2, @retainage = @retainage + @retainage2,
       	@discount = @discount + @discount2
   
    -- get deleted lines from batch
    select @gross2 = isnull(sum(GrossAmt),0),
    	@freight2 = isnull(sum (CASE MiscYN WHEN 'Y' THEN MiscAmt ELSE 0 END),0),
            @salestax2 = isnull(sum (CASE TaxType WHEN 2 THEN 0 ELSE TaxAmt END),0),
            @retainage2 = isnull(sum(Retainage),0),
             @discount2 = isnull(sum(Discount),0)
    from bAPLB
    where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and BatchTransType = 'D'
   
    -- subtract out deleted lines
    select @gross = @gross - @gross2, @freight = @freight - @freight2,
       	@salestax = @salestax - @salestax2, @retainage = @retainage - @retainage2,
       	@discount = @discount - @discount2
   
    -- accumulate invoice total
    select @total = @gross + @freight + @salestax
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPTHTotalGet] TO [public]
GO
