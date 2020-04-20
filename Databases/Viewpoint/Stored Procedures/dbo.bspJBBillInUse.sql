SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBBillInUse]
/***********************************************************
* CREATED BY	: kb 3/3/00
* MODIFIED BY	: kb 8/9/00 - added billsource input to validate by source
*                kb 3/21/01 - changed datatype of billnum from int to varchar - Issue #12695
*		TJL 03/06/06 - Issue #28199:  Return JBIN.InvDescription in @msg
*		TJL 10/03/06 - Issue #28048, 6x Recode, adjusted message text only
*
* USED IN:
*   JBBillHeader
*
* USAGE:
*checks to see if Bill is in use in a interface batch, can't get in it to edit if it is
*
* INPUT PARAMETERS
*   @co JB Co to check against
*   @mth BillMonth
*   @billnum  Bill Number
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
(@co bCompany, @mth bMonth, @billnum varchar(9), @billsource char(1),
	@overlimit bYN output, @errorsexist bYN output, @msg varchar(255) output)
as

set nocount on

declare @rcode int, @InUse bBatchID, @InUseMth bMonth, @inuseby bVPUserName, @status tinyint,
	@source bSource

if @billnum is null or @billnum = 'NEW' goto bspexit
   
select @rcode = 0, @overlimit = 'N', @errorsexist = 'N'

/* Check source and don't allow access to T&M bills if 'P' or Prog bills if 'T'*/
if @billsource = 'T'
	begin
	if exists(select 1 from bJBIN with (nolock) where JBCo = @co and BillMonth = @mth and
		BillNumber =  @billnum and BillType = 'P')
		begin
	   	select @msg = 'You have entered a Progress BillNumber.  Only T&&M Bills can be accessed here.', @rcode = 1
	   	goto bspexit
	   	end

	if exists(select 1 from bJBBE with (nolock) where JBCo = @co and BillMonth = @mth
		and BillNumber = @billnum and BillError = 101)
		select @overlimit = 'Y'
	
	if exists(select 1 from bJBJE with (nolock) where JBCo = @co and BillMonth = @mth
		and BillNumber = @billnum)
		select @errorsexist = 'Y'
	end
   
if @billsource = 'P'
	begin
	if exists(select 1 from bJBIN with (nolock) where JBCo = @co and BillMonth = @mth and
		BillNumber = @billnum and BillType = 'T')
	   	begin
	   	select @msg = 'You have entered a T&&M BillNumber.  Only Progress Bills can be accessed here.', @rcode = 1
	   	goto bspexit
	   	end
	end

/* InUseBatch checks */
select @InUse=null
   
select @msg = InvDescription, @InUse=InUseBatchId, @InUseMth=InUseMth 
from bJBIN with (nolock)
where JBCo = @co and BillMonth=@mth and BillNumber = @billnum
if @@rowcount=0	goto bspexit
   
if not @InUse is null
   	begin
   	select @source=Source
	from HQBC
	where Co=@co and BatchId=@InUse and Mth=@InUseMth
	if @@rowcount <> 0
		begin
		select @msg = 'Bill is currently in an interface BatchMth for ' +
			case when DataLength(isnull(Convert(varchar(2),DATEPART(month, @InUseMth)), '')) = 1 
				Then '0' + isnull(convert(varchar(2), DATEPART(month, @InUseMth)), '')
					else isnull(convert(varchar(2),DATEPART(month, @InUseMth)), '') end + '/' +
			isnull(substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4),'') +
			' BatchId #' + isnull(convert(varchar(6),@InUse),'') + ' and cannot be edited.', @rcode = 1
   
		goto bspexit
		end
	else
		begin
		select @msg='Bill is currently in an interface batch.', @rcode=1
		goto bspexit
		end
   	end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBBillInUse] TO [public]
GO
