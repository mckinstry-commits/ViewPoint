SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPUnappInvPostGridFill]
  
  /***********************************************************
   * CREATED BY: MV 09/21/06
   * MODIFIED By:	MV 08/12/08 #128288 VAT TaxType
   *		TJL 10/07/08 - Issue #129923, Modify form code for International Dates
   *		
   *
   * Usage:
   *	Used by APUnappInvPost form to get the batch records to fill the form grid 
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

  SELECT
	'UI Month' = x.UIMth,
	'UI Seq' = x.UISeq,
	'Vendor' = x.Vendor,
	'Name' = (select APVM.Name from APVM with (nolock) where APVM.VendorGroup=x.VendorGroup and APVM.Vendor=x.Vendor),
	'AP Reference' = x.APRef,
	'Inv Date' = x.InvDate, 
    'Invoice Total' =(Select sum(b.GrossAmt+ case b.TaxType when 2 then 0 else b.TaxAmt end 
		+ case b.MiscYN when 'Y' then b.MiscAmt else 0 end) FROM APLB b with (nolock) 
		where b.Co=x.Co and b.Mth=x.Mth and b.BatchId=x.BatchId and b.BatchSeq=x.BatchSeq)
	 FROM APHB x with (nolock) 
	 WHERE x.Co=@co  and x.Mth=@batchmth And x.BatchId=@batchid and x.UIMth is not null and x.UISeq is not null 
	 GROUP BY x.UIMth, x.UISeq, x.Vendor, x.APRef,x.InvDate, x.VendorGroup, x.Co, x.BatchSeq, x.BatchId, x.Mth 
	 ORDER BY x.UIMth, x.UISeq
	  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPUnappInvPostGridFill] TO [public]
GO
