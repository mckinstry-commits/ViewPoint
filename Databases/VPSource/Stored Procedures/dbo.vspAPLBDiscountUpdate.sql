SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPLBDiscountUpdate]
   	
   /***********************************************************
    * CREATED BY: MV   07/10/09 - #133727 
    * MODIFIED By : 
    *
    * USAGE:
    * Called from APEntry when vendor's payterms change
	* recalculate discount, taxbasis and taxamt if using netamtopt for all lines.
    *
    * INPUT PARAMETERS
    *   Co		batch company
	*	Mth		batch month
	*	BatchId	batch id
    *	
    * OUTPUT PARAMETERS
    *   		                     
	*
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@co int, @mth bMonth, @batchid int, @seq int, @discpct float, @taxrate float, @msg varchar(100) output) 
   as
   set nocount on
   
   	declare @rcode int,@usetaxdisc bYN 
   	select @rcode = 0
   
   if @co is null
   	begin
   	select @msg = 'Missing Batch Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @msg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   
   if @batchid is null
   	begin
   	select @msg = 'Missing Batch ID!', @rcode = 1
   	goto bspexit
   	end

   --get NetAmtOpt flag
   select @usetaxdisc = NetAmtOpt from APCO where APCo=@co

  if exists (Select top 1 1 from APLB where Co = @co and Mth = @mth and BatchId = @batchid
		 and BatchSeq=@seq)
	begin
	update APLB set Discount = ((isnull(GrossAmt,0) - isnull(Retainage,0)) * isnull(@discpct,0.0)),
		TaxBasis = case when @usetaxdisc = 'Y' then isnull(GrossAmt,0) - isnull(Discount,0) else isnull(TaxBasis,0) end,
		TaxAmt = case when @usetaxdisc = 'Y' then isnull(TaxBasis,0) * isnull(@taxrate,0.0) else isnull(TaxAmt,0) end
	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
	end
   
   bspexit:
   	return @rcode
           

GO
GRANT EXECUTE ON  [dbo].[vspAPLBDiscountUpdate] TO [public]
GO
