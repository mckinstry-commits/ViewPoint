SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         proc [dbo].[vspAPRecurInvPostGridFill]
  
  /***********************************************************
   * CREATED BY: MV 03/13/06
   * MODIFIED By : 
   *		
   *
   * Usage:
   *	Used by APRecurInvPost form to get the batch records to fill the form grid 
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
 
 Select 'Vendor' = APHB.Vendor,'Name' = APVM.Name,'Invoice' = APHB.InvId,'Description' = APHB.Description,'Frequency' = APRH.Frequency 
		from APHB with (nolock) join APVM with (nolock) on APVM.VendorGroup=APHB.VendorGroup and APVM.Vendor=APHB.Vendor
        join APRH with (nolock) on APRH.APCo=APHB.Co and APRH.VendorGroup=APHB.VendorGroup and
			APRH.Vendor=APHB.Vendor and APRH.InvId=APHB.InvId
		where Co = @co and Mth = @batchmth And BatchId = @batchid
 
 	  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPRecurInvPostGridFill] TO [public]
GO
