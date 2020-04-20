SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspARCustJobGridFill]   
  
(@ARCo bCompany = null, @BatchMth bMonth = null,  @BatchId bBatchID = null, @BatchSeq int = null,
	@CustJob varchar(15) = null, @ApplyAll varchar(1) = 'N', @msg varchar(100) output)
  
/**************************************************************************************
*  CREATED BY:	TJL 09/09/05 - Issue #28269, 6x recode
*  MODIFIED BY:	
*
*
*  USAGE:
*	Fill Grid on form ARInitializeReceiptJob
*
*  INPUT PARAMETERS:
*	ARCo
*	Batch Month
*	Batch ID
*	Batch Seq
*	Customer Job Number
*	ApplyOpt
*
*  OUTPUT PARAMETERS:
*
*  RETURN VALUE:
*	0	Success
*	1	1 and Message failure
*
****************************************************************************************/
AS
  
declare @rcode int, @CustGroup bGroup, @Customer bCustomer
  
set nocount on

select @rcode=0
  
if @ARCo is null
  	begin
  	select @msg = 'AR Company  is missing', @rcode = 1
   	goto vspexit
   	end

if @BatchMth is null
  	begin
  	select @msg = 'BatchMth  is missing', @rcode = 1
   	goto vspexit
   	end

if @BatchId is null
  	begin
  	select @msg = 'BatchId  is missing', @rcode = 1
   	goto vspexit
   	end

if  @BatchSeq is null
  	begin
  	select @msg = ' BatchSeq  is missing', @rcode = 1
   	goto vspexit
   	end

if  @CustJob is null
  	begin
  	select @msg = ' CustJob  is missing', @rcode = 1
   	goto vspexit
   	end

if  @ApplyAll is null
  	begin
  	select @msg = ' ApplyOpt  is missing', @rcode = 1
   	goto vspexit
   	end
  
/* These values are available as long as there is a payment being initialized */
select @CustGroup=CustGroup, @Customer=Customer
from bARBH with (nolock)
where Co = @ARCo and Mth = @BatchMth and BatchId = @BatchId and BatchSeq = @BatchSeq
if @@rowcount <> 1
	begin
	select @msg='BatchSeq not found in ARBH', @rcode=1
	goto vspexit
	end

/* Get record set based on CustJob number to be displayed in Grid */
select distinct  bARTH.Invoice,
	     bMSIH.ShipAddress,
	     bARTH.AmountDue,
	     bARTH.ARCo,
	     bARTH.Mth,
	     bARTH.ARTrans,
	     bARTH.TransDate,
	     ApplyYN = @ApplyAll
from bARTH with (nolock)
join bARTL with (nolock) on bARTH.ARCo = bARTL.ARCo and bARTH.Mth = bARTL.Mth	and bARTH.ARTrans = bARTL.ARTrans
join bMSIH with (nolock) on bARTH.ARCo = bMSIH.MSCo and bARTH.Invoice = bMSIH.MSInv
where bARTH.ARCo = @ARCo and bARTH.CustGroup = @CustGroup and bARTH.Customer = @Customer
	and bARTL.Mth = bARTL.ApplyMth and bARTL.ARTrans = bARTL.ApplyTrans and bARTL.ARLine = bARTL.ApplyLine
	and bARTL.Mth <= @BatchMth
	and bARTH.AmountDue <> 0
	and bARTL.CustJob = @CustJob
	and bARTH.InUseBatchID is null
order by bARTH.Invoice, bARTH.Mth, bARTH.ARTrans
  
if @@rowcount = 0
	begin
	select @msg = 'There are no Invoices posted for CustJob:  ' + @CustJob, @rcode = 7
	goto vspexit
	end
  
vspexit:
select @msg = @msg		--+ char(10) + char(13) + char(10) + char(13) + 'vspARCustJobGridFill'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARCustJobGridFill] TO [public]
GO
