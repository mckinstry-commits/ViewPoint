SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspAPPrePaidGridFill]
  
  /***********************************************************
   * CREATED BY: MV 12/29/05
   * MODIFIED By :	MV 10/07/08 - #129923 - for International dates return ExpMth as date 
   *		
   *
   * Usage:
   *	Used by APPrePaid form to get the batch records to fill the form grid 
   *
   * Input params:
   *	@co			company
   *	@batchmth	Batch Month
   *	@batchid	Batch Id
   *
   * Output params:
   *	@msg		error message
   *
   * Return code:
   *	0 = success, 1 = failure
   *****************************************************/
  (@co bCompany ,@batchmth bMonth,@batchid int, @msg varchar(255)=null output)
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  /* check required input params */
  if @co is null
  	begin
  	select @co = 'Missing Company.', @rcode = 1
  	goto bspexit
  	end
  
  if @batchmth is null
  	begin
  	select @msg = 'Missing Batch Month.', @rcode = 1
  	goto bspexit
  	end

 if @batchid is null
  	begin
  	select @msg = 'Missing Batch Id.', @rcode = 1
  	goto bspexit
  	end
  
 select 'CM Acct' = p.CMAcct, 'Check #' = p.CMRef, 'Seq #' = p.CMRefSeq,
		'Exp Mth'= ExpMth,
--		'Exp Mth'= convert(varchar(2),datepart(mm,ExpMth)) + '/' + right(convert(varchar(4),datepart(yy,ExpMth)), 2),
		'AP Trans'= t.APTrans,'Vendor' = p.Vendor,'Name'= p.Name, 'In Use By' = b.InUseBy, t.BatchSeq
		from APTB t with (nolock)
		join APPB p with (nolock) on p.Co=t.Co and p.Mth=t.Mth and p.BatchId=t.BatchId and p.BatchSeq=t.BatchSeq 
        join APTH h with (nolock) on h.APCo=t.Co and h.Mth=t.ExpMth and h.APTrans=t.APTrans 
        join HQBC b with (nolock) on b.Co=h.APCo and b.BatchId=h.BatchId and b.Mth=h.Mth
		where t.Co=@co and t.Mth= @batchmth and t.BatchId= @batchid and h.PrePaidYN='Y' and h.PrePaidProcYN='N'
	  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPPrePaidGridFill] TO [public]
GO
