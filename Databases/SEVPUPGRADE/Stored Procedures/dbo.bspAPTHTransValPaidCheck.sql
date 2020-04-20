SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPTHTransValPaidCheck    Script Date: 8/28/99 9:34:05 AM ******/
   
     CREATE  proc [dbo].[bspAPTHTransValPaidCheck]
        /********************************************************
        * CREATED BY: 	kb 5/16/2  --rejection of issue #14164 to return whether or not there are open lines on the trans
        * MODIFIED BY: kb 6/20/2 - issue #14164 to check APLB also for BatchTransType = A lines
        *
        * USAGE:
        * 	Retrieves totals for an AP Invoice
        *
        * INPUT PARAMETERS:
        *	@apco		AP Co#
        *  @mth		Batch month
        *	@aptrans	AP Trans
        *
        * OUTPUT PARAMETERS:
        *  @openlinesYN - Y if any lines on the transaction are not paid
        *	@msg		Error message
        *
        * RETURN VALUE:
        * 	0 	    Success
        *	1 & message Failure
        *
        **********************************************************/
        	(@apco  bCompany, @mth bMonth, @aptrans bTrans, @openlinesYN bYN output,
             @msg varchar(60) output)
        as
   
        set nocount on
   
        declare @rcode int, @countOpen int
   
        select @rcode = 0
   
        if @apco is null
           begin
           select @msg = 'AP Company is missing', @rcode = 1
           goto bspexit
           end
        if @mth is null
           begin
           select @msg = 'AP month is missing', @rcode = 1
           goto bspexit
           end
        if @aptrans is null
           begin
           select @msg = 'AP transaction  is missing', @rcode = 1
           goto bspexit
           end
   
       select @openlinesYN = 'N'
   
       select @countOpen = count(*) from bAPTD where APCo = @apco and Mth = @mth
         and APTrans = @aptrans and Status <3
       if @countOpen > 0 select @openlinesYN = 'Y'
   
   	if @openlinesYN = 'N'
   		begin
   		select @countOpen = count(*) from bAPLB l
   		  join APHB h on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId
   		  and h.BatchSeq = l.BatchSeq where l.Co = @apco and h.Mth = @mth
   		  and h.APTrans = @aptrans and l.BatchTransType = 'A'
   		if @countOpen > 0 select @openlinesYN = 'Y'
   		end
   
   	if @openlinesYN = 'N'
   		begin
   		select @countOpen = count(*) from bAPLB l
   		  join APHB h on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId
   		  and h.BatchSeq = l.BatchSeq where l.Co = @apco and h.Mth = @mth
   		  and h.APTrans = @aptrans 
   		
   		if @countOpen = 0 
   			begin
   			select @countOpen = count(*) from bAPTL l 
   			  where APCo = @apco and Mth = @mth and APTrans = @aptrans 
   			if @countOpen = 0 select @openlinesYN = 'Y'
   			end
   		end
   		
   
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPTHTransValPaidCheck] TO [public]
GO
