SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspAPInterCoInvGridFill]
  
  /***********************************************************
   * CREATED BY: MV 02/01/07
   * MODIFIED By : 
   *		
   *
   * Usage:
   *	Used by APIntercoInvoice form to get batch records to fill the form grid 
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
  
        Select 'Invoice' = i.MSInv, 'Sold To Co#' = i.SoldToCo, 'Inv Date' = i.InvDate, 'Due Date' = i.DueDate, 
			'Material' = isnull(sum(x.MatlTotal),0), 'Haul Charge' = isnull(sum(x.HaulTotal),0),
			 'Tax' = isnull(sum(x.TaxTotal),0),'Total' = isnull(sum(x.MatlTotal + x.HaulTotal + x.TaxTotal),0)
		from MSII i left join MSIX x on i.MSCo=x.MSCo and i.MSInv=x.MSInv 
        where i.InUseAPCo=@co and i.Mth=@batchmth and i.InUseBatchId=@batchid
		group by i.MSInv, i.SoldToCo, i.InvDate, i.DueDate
	  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPInterCoInvGridFill] TO [public]
GO
