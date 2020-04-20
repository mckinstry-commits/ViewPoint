SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPPayHistoryGridFill]
  
  /***********************************************************
   * CREATED BY: MV 02/03/06
   * MODIFIED By : 
   *		
   *
   * Usage:
   *	Used by APPayHistory form to get the Pay History Detail to fill the form grid 
   *
   * Input params:
   *	@apco			
   *	@cmco	
   *	@cmacct	
   *	@paymethod
   *	@cmref
   *	@cmrefseq
   *	@eftseq
   *
   * Output params:
   *	@msg		error message
   *
   * Return code:
   *	0 = success, 1 = failure
   *****************************************************/
  (@apco bCompany ,@cmco bCompany, @cmacct bCMAcct, @paymethod tinyint,
	@cmref bCMRef, @cmrefseq int, @eftseq int, @msg varchar(255)=null output)
  as
  set nocount on
  declare @rcode int, @paymethod1 varchar(1)
  select @rcode = 0
  /* check required input params */
  if @apco is null
  	begin
  	select @apco = 'Missing AP Company.', @rcode = 1
  	goto bspexit
  	end
  
  if @cmco is null
  	begin
  	select @msg = 'Missing CM Company.', @rcode = 1
  	goto bspexit
  	end
	
 select @paymethod1 = case when @paymethod=2 then 'E' else 'C' end

  select 'Month' = convert(varchar(2),datepart(mm,Mth)) + '/' + right(convert(varchar(4),datepart(yy,Mth)), 2), 
		 'Trans#' = APTrans, 'AP Reference' = APRef, 'Description' = Description, 'Inv Date' = convert(varchar(8),InvDate,1),
		 'Gross Amount' = Gross,'Retainage'= Retainage,'Prev Paid' = PrevPaid,'Prev Disc' = PrevDiscTaken,'Balance' = Balance,
		 'Disc Taken' = DiscTaken
	from APPD with (nolock) where APCo=@apco and CMCo=@cmco and CMAcct=@cmacct and PayMethod=@paymethod1 and ltrim(CMRef)= ltrim(@cmref)
			and CMRefSeq=@cmrefseq and EFTSeq=@eftseq

	  
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspAPPayHistoryGridFill] TO [public]
GO
