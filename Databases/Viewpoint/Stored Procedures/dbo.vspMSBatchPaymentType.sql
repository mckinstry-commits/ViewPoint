SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspMSBatchPaymentType]
/***********************************************************
* Created By:	GF 05/15/2007
* Modified By:	
*
* Used in MS Batch Processing to get count of MSIB records for the
* payment type.
*
*
* Input params:
* @co			MS Company
* @mth			MS Batch Month
* @batchid		MS Batch Id
* @paymenttype	MS Invoice Payment Type
*
*
* Output params:
*	none
*
* Returns:
*	# of records
**************************************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @paymenttype varchar(1) = null)
as
set nocount on

---- return # of records in MSIB that are cash or credit card payment types
select count(*) from dbo.MSIB with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid and PaymentType=@paymenttype





vspexit:
	return

GO
GRANT EXECUTE ON  [dbo].[vspMSBatchPaymentType] TO [public]
GO
