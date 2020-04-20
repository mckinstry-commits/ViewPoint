SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCMDepositVal    Script Date: 8/28/99 9:34:09 AM ******/
CREATE  PROC [dbo].[bspARCMDepositVal]
/***********************************************************
* CREATED BY: JM 5/31/97
* MODIFIED By : JE 4/27/98 - added logic if a new deposit then 
*			don't check variables
*		JM 6/19/98 - corrected select statement
*		JM 6/23/98 - removed restriction that Source 
* 				must = 'AR Deposit' per JRE - use 
* 				warning only if already in CMDT
*		SR 08/07/02 - issue 18136
*		TJL 08/19/02 - Issue #18136, Incorporate @rcode = 2 for needed flexibility. 
*		TJL 03/25/03 - Issue #19299, relative to if CMAcct is NULL
*		TJL 08/08/03 - Issue #22087, Performance mods, add NoLocks
*		TJL 10/24/08 - Issue #129358, Give Duplicate CMRef# warning when in same Mth in 6x as was in 5x
*
* USAGE:
* 	Validates ARBH.CMDeposit - can't edit or add a new 
*	Batch Header with reconciled CMDeposit
*	Called directly from ARCashReceipts and ARMiscRec
*
* INPUT PARAMETERS
*   ARBH.Co (ie ARCo)
*   ARBH.CMCo
*   ARBH.CMAcct
*   ARBH.CMDeposit to validate
*   BatchMth
*
* OUTPUT PARAMETERS
*   @errmsg      Description or error message
*
* RETURN VALUE
*   0	success	-	CMDeposit not currently used in bCMDT
*   1 	failure	-	CMDeposit in bCMDT and fails specific validation. Do not allow its use by user.
*	2	Exists	-	CMDeposit exists in bCMDT but DOES NOT fail validation. Used for Warning only.
*

*****************************************************/
   
(@ARCo bCompany = null, @cmco bCompany = null, @cmacct int = null,
	@cmdeposit varchar(10) = null, @batchmth bMonth = null, @errmsg varchar(200) output)
as
set nocount on
declare @StmtDate bDate
declare @SourceCo bCompany
declare @Source bSource
declare @CMTransType bCMTransType
declare @InUseBatchId int
declare @rcode int
declare @Void bYN
declare @Mth bMonth
declare @cnt int
   
select @rcode = 0

/* since input parameters can be null, leave if all are null */
if @cmco is null and @cmacct is null and @cmdeposit is null and @batchmth is null goto bspexit

/* else make sure they are all passed */
if @cmco is null
	begin
   	--select @errmsg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
if @cmacct is null
   	begin
   	--select @errmsg = 'Missing CM Account!', @rcode = 1
   	goto bspexit
   	end
if @cmdeposit is null
   	begin
   	select @errmsg = 'Missing CM Deposit!', @rcode = 1
   	goto bspexit
   	end
if @batchmth is null
   	begin
   	select @errmsg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   
select @errmsg = 'Warning: CM Deposit already exists in CMDT!'

/* validate CM Deposit */
select @SourceCo = SourceCo, @Source = Source, @CMTransType = CMTransType, 
	@InUseBatchId = InUseBatchId, @StmtDate = StmtDate, @Void = Void, @Mth = Mth
from bCMDT with (nolock)
where CMCo = @cmco and CMAcct = @cmacct and	CMTransType = 2 
	and	CMRef  = @cmdeposit 
	
select @cnt=@@rowcount

if @cnt=0
   	begin 
   	goto bspexit  /* If there is no deposit# then skip validations, rcode = 0 */
   	end
else
   	begin
   	select @rcode = 7	/* The deposit# does exists but not yet officially an error */
   	end
   
/* The deposit# does exist, validate further */
If @SourceCo <> @ARCo
	begin
	select @errmsg = @errmsg + ' - CM Deposit invalid - CM Source Co <> ARCo', @rcode = 1
	goto bspexit
	end
--removed 6/23/98 per JRE - use warning only if already in CMDT
--If @Source <> 'AR Deposit'
--		begin
--		select @errmsg = 'CM Deposit invalid - Source not AR Deposit', @rcode = 1
--		goto bspexit
--		end
If @StmtDate is not null
	begin
	select @errmsg = @errmsg + ' - CM Deposit invalid - CM Statement cleared', @rcode = 1
	goto bspexit
	end
If @CMTransType <> 2
	begin
	select @errmsg = @errmsg + ' - CM Deposit invalid - CM Trans Type not D-Type', @rcode = 1
	goto bspexit
	end
If @Mth <> @batchmth
	begin
	select @errmsg = @errmsg + ' - CM Deposit invalid - Deposit Month <> Batch Mth', @rcode = 1
	goto bspexit
	end
If @Void = 'Y'
	begin
	select @errmsg = @errmsg + ' - CM Deposit invalid - Deposit Void', @rcode = 1
	goto bspexit
	end
If @InUseBatchId is not null
	begin
	select @errmsg = @errmsg + ' - CM Deposit invalid - CM Stmt being cleared', @rcode = 1
	goto bspexit
	end
   
bspexit:
/* error message will be returned for @rcode 1 or 2 */
if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARCMDepositVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARCMDepositVal] TO [public]
GO
