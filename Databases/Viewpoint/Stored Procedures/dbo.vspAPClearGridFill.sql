SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPClearGridFill]
  
  /***********************************************************
   * CREATED BY: MV 09/27/05
   * MODIFIED By :	MV 09/29/08 #129923 - Don't format InvDate  
   *		
   *
   * Usage:
   *	Used by APClear form to get the batch records to fill the form grid 
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
  	select @msg = 'Missing Company.', @rcode = 1
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
  
  select 'Month' = convert(varchar(2),datepart(mm,ExpMth)) + '/' + right(convert(varchar(4),datepart(yy,ExpMth)), 2), 
		 'AP Trans' = APTrans, 'AP Reference' = APRef, 'Description' = Description, 'Inv Date' = InvDate,
		 'Gross' = Gross,'Paid'= Paid,'Remaining' = Remaining 
		from APCT with (nolock) where Co=@co and Mth= @batchmth and BatchId= @batchid
	  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPClearGridFill] TO [public]
GO
