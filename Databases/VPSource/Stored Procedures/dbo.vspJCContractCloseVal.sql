SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCContractCloseVal    Script Date: 8/28/99 9:32:57 AM ******/
   CREATE   proc [dbo].[vspJCContractCloseVal]
/***********************************************************
* CREATED BY: DANF 10/05/2006
* MODIFIED By :	GP 11/11/2008 - Issue 130955, added check for null @job.
*				GF 08/22/2009 - issue #135256 performance changes
*
*
* USAGE:
* validates JC contract
* an error is returned if any of the following occurs
* no contract passed, no contract found in JCCM.
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   Contract  Contract to validate
*
*
* OUTPUT PARAMETERS

*   @status      Status of the contract
*   @department  Department of the contract
*   @customer    Customer of the contract
*   @startmonth  StartMonth of the contract
*   @msg      error message if error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, 
	@contract bContract = null,
	@batchmonth bMonth = null,
    @batchid bBatchID = null,
	@job bJob = null, 
	@status tinyint output,
	@startmonth bMonth=null output, 
	@lstMthRevenue bMonth=null output, -- 20
	@lstMthCost bMonth=null output, -- 25
	@lstMthOrigContractUnits bMonth=null output, -- 200
	@lstMthOrigContractAmount bMonth=null output, -- 205 
	@lstMthContractAmount bMonth=null output, -- 210
	@lstMthContractUnits bMonth=null output, -- 215
	@lstMthBilledTax bMonth=null output, -- 220 
	@lstMthBilledAmount bMonth=null output, -- 225
	@lstMthCurrentRetainageAmount bMonth=null output, -- 230
	@lstMthActualHours bMonth=null output, -- 235
	@lstMthActualUnits bMonth=null output, -- 240
	@lstMthActualCost bMonth=null output, -- 245
	@lstMthOrigHours bMonth=null output, -- 250
	@lstMthOrigUnits bMonth=null output, -- 255
	@lstMthOrigCost bMonth=null output, -- 260
	@lstMthCurrEstHours bMonth=null output, -- 265
	@lstMthCurrEstUnits bMonth=null output, -- 270
	@lstMthCurrEstCost bMonth=null output, -- 275
	@lstMthProjHours bMonth=null output, -- 280
	@lstMthProjUnits bMonth=null output, -- 285
	@lstMthProjCost bMonth=null output, -- 290
	@lstMthForecastHours bMonth=null output, -- 295
	@lstMthForecastUnits bMonth=null output, -- 300
	@lstMthForecastCost bMonth=null output, -- 305
	@lstMthTotalCmtdUnits bMonth=null output, -- 310
	@lstMthTotalCmtdCost bMonth=null output, -- 315
	@lstMthRemainCmtdUnits bMonth=null output, -- 320
	@lstMthRemainCmtdCost bMonth=null output, -- 325
	@lstMthRecvdNotInvcdUnits bMonth=null output, -- 330
	@lstMthRecvdNotInvcdCost bMonth=null output, -- 335
	@warning varchar(255) output, -- 400
	@msg varchar(255) output)

as
set nocount on

declare @rcode int,  @bid int, @bmth bMonth
		
select @rcode = 0, @status=1
  
if @jcco is null
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

if @contract is null
	begin
	select @msg = 'Missing Contract!', @rcode = 1
	goto bspexit
	end

if @batchmonth is not null and @batchid is not null
	begin
	select @bid = BatchId, @bmth=Mth from JCXB with (nolock)
				where JCXB.Co = @jcco and JCXB.Contract=@contract and 
					(Mth <> @batchmonth or BatchId <> @batchid)
	if @@rowcount <> 0 
		begin
		select @msg ='Contract already exists in JCClose batch: ' +
				convert(varchar(10),@bid) + ' for Mth: ' +
				convert(varchar(3),@bmth,1) +
				substring(convert(varchar(8),@bmth,1),7,2) , @rcode = 1
		goto bspexit
		end

	end

select @msg = Description, @status=ContractStatus, @startmonth=StartMonth
from dbo.JCCM with (nolock)
where JCCo = @jcco and Contract = @contract
if isnull(@status,0) = 3 
	begin
	select @msg = 'Contract is already closed!', @rcode = 1
	goto bspexit
	end
if isnull(@status,0) = 1 and @startmonth > @batchmonth 
	begin
	select @msg = 'Month Closed may not be earlier than the start month!', @rcode = 1
	goto bspexit
	end
		
		
--    Select @lstMthRevenue = (Select max(JCIP.Mth) from JCIP with (nolock) 
--							where JCIP.JCCo= @jcco and JCIP.Contract= @contract and 
--							(isnull(JCIP.OrigContractAmt,0) <> 0 or isnull(JCIP.OrigContractUnits,0) <> 0 or 
--							isnull(JCIP.ContractAmt,0) <> 0 or isnull(JCIP.ContractUnits,0) <> 0 or 
--							isnull(JCIP.BilledAmt,0) <> 0 or isnull(JCIP.CurrentRetainAmt,0) <> 0 or isnull(JCIP.BilledTax,0) <> 0)),
--			@lstMthOrigContractUnits = (Select max(JCIP.Mth) from JCIP with (nolock) 
--										where JCIP.JCCo= @jcco and JCIP.Contract= @contract and isnull(JCIP.OrigContractUnits,0) <> 0 ),
--			@lstMthOrigContractAmount = (Select max(JCIP.Mth) from JCIP with (nolock) 
--										where JCIP.JCCo= @jcco and JCIP.Contract= @contract and isnull(JCIP.OrigContractAmt,0) <> 0 ),
--			@lstMthContractAmount = (Select max(JCIP.Mth) from JCIP with (nolock) 
--										where JCIP.JCCo= @jcco and JCIP.Contract= @contract and isnull(JCIP.ContractAmt,0) <> 0 ),
--			@lstMthContractUnits = (Select max(JCIP.Mth) from JCIP with (nolock) 
--									where JCIP.JCCo= @jcco and JCIP.Contract= @contract and isnull(JCIP.ContractUnits,0) <> 0 ),
--			@lstMthBilledTax = (Select max(JCIP.Mth) from JCIP with (nolock) 
--								where JCIP.JCCo= @jcco and JCIP.Contract= @contract and isnull(JCIP.BilledTax,0) <> 0 ),
--			@lstMthBilledAmount = (Select max(JCIP.Mth) from JCIP with (nolock) 
--									where JCIP.JCCo= @jcco and JCIP.Contract= @contract and isnull(JCIP.BilledAmt,0) <> 0 ),
--			@lstMthCurrentRetainageAmount = (Select max(JCIP.Mth) from JCIP with (nolock) 
--											where JCIP.JCCo= @jcco and JCIP.Contract= @contract and isnull(JCIP.CurrentRetainAmt,0) <> 0 ),
--			@lstMthCost = (Select max(JCCP.Mth) from JCCP with (nolock)
--						join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)
--						where  JCJM.JCCo= @jcco and JCJM.Contract= @contract and 
--						(isnull(JCCP.ActualHours,0) <> 0 or isnull(JCCP.ActualUnits,0) <> 0 or isnull(JCCP.ActualCost,0) <> 0 or 
--						isnull(JCCP.OrigEstHours,0) <> 0 or isnull(JCCP.OrigEstUnits,0) <> 0 or isnull(JCCP.OrigEstCost,0) <> 0 or 
--						isnull(JCCP.CurrEstHours,0) <> 0 or isnull(JCCP.CurrEstUnits,0) <> 0 or isnull(JCCP.CurrEstCost,0) <> 0 or 
--						isnull(JCCP.ProjHours,0) <> 0 or isnull(JCCP.ProjUnits,0) <> 0 or isnull(JCCP.ProjCost,0) <> 0 or 
--						isnull(JCCP.ForecastHours,0) <> 0 or isnull(JCCP.ForecastUnits,0) <> 0 or isnull(JCCP.ForecastCost,0) <> 0 or 
--						isnull(JCCP.TotalCmtdUnits,0) <> 0 or isnull(JCCP.TotalCmtdCost,0) <> 0 or isnull(JCCP.RemainCmtdUnits,0) <> 0 or 
--						isnull(JCCP.RemainCmtdCost,0) <> 0 or isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 or isnull(JCCP.RecvdNotInvcdCost,0) <> 0 )),
--			 @lstMthActualHours = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ActualHours,0) <> 0 ),
--			 @lstMthActualUnits = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ActualUnits,0) <> 0 ),
--			 @lstMthActualCost = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ActualCost,0) <> 0 ),
--			 @lstMthOrigHours = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.OrigEstHours,0) <> 0 ),
--			 @lstMthOrigUnits = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.OrigEstUnits,0) <> 0 ),
--			 @lstMthOrigCost = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.OrigEstCost,0) <> 0 ),
--			 @lstMthCurrEstHours = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.CurrEstHours,0) <> 0 ),
--			 @lstMthCurrEstUnits = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.CurrEstUnits,0) <> 0 ),
--			 @lstMthCurrEstCost = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.CurrEstCost,0) <> 0 ),
--			 @lstMthProjHours = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ProjHours,0) <> 0 ),
--			 @lstMthProjUnits = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ProjUnits,0) <> 0 ),
--			 @lstMthProjCost = (Select max(JCCP.Mth) from JCCP with (nolock)join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ProjCost,0) <> 0 ),
--			 @lstMthForecastHours = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ForecastHours,0) <> 0 ),
--			 @lstMthForecastUnits = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ForecastUnits,0) <> 0 ),
--			 @lstMthForecastCost = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.ForecastCost,0) <> 0 ),
--			 @lstMthTotalCmtdUnits = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job) 
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.TotalCmtdUnits,0) <> 0 ),
--			 @lstMthTotalCmtdCost = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.TotalCmtdCost,0) <> 0 ),
--			 @lstMthRemainCmtdUnits = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job) 
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.RemainCmtdUnits,0) <> 0 ),
--			 @lstMthRemainCmtdCost = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.RemainCmtdCost,0) <> 0 ),
--			 @lstMthRecvdNotInvcdUnits = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 ),
--			 @lstMthRecvdNotInvcdCost = (Select max(JCCP.Mth) from JCCP with (nolock) join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)  
--				  where JCJM.JCCo= @jcco and JCJM.Contract= @contract and isnull(JCCP.RecvdNotInvcdCost,0) <> 0 )
--			from JCCM with (nolock)
--			left join JCJM with (nolock) on JCCM.JCCo=JCJM.JCCo and JCCM.Contract=JCJM.Contract
--			where JCCM.JCCo = @jcco and JCCM.Contract = @contract 
--				and (JCJM.Job = case when @job is null then '' else @job end or @job is null) -- Issue 130955
--			GROUP BY JCCM.Contract, JCJM.Job, JCCM.ContractStatus

----JCIP
select
	@lstMthRevenue = max(Case when isnull(JCIP.OrigContractAmt,0) <> 0 or isnull(JCIP.OrigContractUnits,0) <> 0 or 
						isnull(JCIP.ContractAmt,0) <> 0 or isnull(JCIP.ContractUnits,0) <> 0 or 
						isnull(JCIP.BilledAmt,0) <> 0 or isnull(JCIP.CurrentRetainAmt,0) <> 0 or 
						isnull(JCIP.BilledTax,0) <> 0 then Mth Else Null end),
	@lstMthOrigContractUnits=		max(Case when isnull(JCIP.OrigContractUnits,0) <> 0 then Mth else NULL end),
	@lstMthOrigContractAmount=		max(Case when isnull(JCIP.OrigContractAmt,0) <> 0 then Mth else NULL end),
	@lstMthContractAmount=			max(Case when isnull(JCIP.ContractAmt,0) <> 0 then Mth else NULL end),
	@lstMthContractUnits=			max(Case when isnull(JCIP.ContractUnits,0) <> 0 then Mth else NULL end),
	@lstMthBilledTax=				max(Case when isnull(JCIP.BilledTax,0) <> 0 then Mth else NULL end),
	@lstMthBilledAmount=			max(Case when isnull(JCIP.BilledAmt,0) <> 0 then Mth else NULL end),
	@lstMthCurrentRetainageAmount=	max(Case when isnull(JCIP.CurrentRetainAmt,0) <> 0 then Mth else NULL end)
from bJCIP JCIP where JCCo=@jcco and Contract=@contract


----JCCP
select 
@lstMthCost= max(Case when isnull(JCCP.ActualHours,0) <> 0 or isnull(JCCP.ActualUnits,0) <> 0 or isnull(JCCP.ActualCost,0) <> 0 or 
				isnull(JCCP.OrigEstHours,0) <> 0 or isnull(JCCP.OrigEstUnits,0) <> 0 or isnull(JCCP.OrigEstCost,0) <> 0 or 
				isnull(JCCP.CurrEstHours,0) <> 0 or isnull(JCCP.CurrEstUnits,0) <> 0 or isnull(JCCP.CurrEstCost,0) <> 0 or 
				isnull(JCCP.ProjHours,0) <> 0 or isnull(JCCP.ProjUnits,0) <> 0 or isnull(JCCP.ProjCost,0) <> 0 or 
				isnull(JCCP.ForecastHours,0) <> 0 or isnull(JCCP.ForecastUnits,0) <> 0 or isnull(JCCP.ForecastCost,0) <> 0 or 
				isnull(JCCP.TotalCmtdUnits,0) <> 0 or isnull(JCCP.TotalCmtdCost,0) <> 0 or isnull(JCCP.RemainCmtdUnits,0) <> 0 or 
				isnull(JCCP.RemainCmtdCost,0) <> 0 or isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 or isnull(JCCP.RecvdNotInvcdCost,0) <> 0  then Mth Else Null end),
		@lstMthActualHours=			max(Case when isnull(JCCP.ActualHours,0) <> 0 then Mth else NULL end),
		@lstMthActualUnits=			max(Case when isnull(JCCP.ActualUnits,0) <> 0 then Mth else NULL end),
		@lstMthActualCost=			max(Case when isnull(JCCP.ActualCost,0) <> 0 then Mth else NULL end),
		@lstMthOrigHours=			max(Case when isnull(JCCP.OrigEstHours,0) <> 0 then Mth else NULL end),
		@lstMthOrigUnits=			max(Case when isnull(JCCP.OrigEstUnits,0) <> 0 then Mth else NULL end),
		@lstMthOrigCost=			max(Case when isnull(JCCP.OrigEstCost,0) <> 0 then Mth else NULL end),
		@lstMthCurrEstHours=		max(Case when isnull(JCCP.CurrEstHours,0) <> 0 then Mth else NULL end),
		@lstMthCurrEstUnits=		max(Case when isnull(JCCP.CurrEstUnits,0) <> 0 then Mth else NULL end),
		@lstMthCurrEstCost=			max(Case when isnull(JCCP.CurrEstCost,0) <> 0 then Mth else NULL end),
		@lstMthProjHours=			max(Case when isnull(JCCP.ProjHours,0) <> 0 then Mth else NULL end),
		@lstMthProjUnits=			max(Case when isnull(JCCP.ProjUnits,0) <> 0 then Mth else NULL end),
		@lstMthProjCost=			max(Case when isnull(JCCP.ProjCost,0) <> 0 then Mth else NULL end),
		@lstMthForecastHours=		max(Case when isnull(JCCP.ForecastHours,0) <> 0 then Mth else NULL end),
		@lstMthForecastUnits=		max(Case when isnull(JCCP.ForecastUnits,0) <> 0 then Mth else NULL end),
		@lstMthForecastCost=		max(Case when isnull(JCCP.ForecastCost,0) <> 0 then Mth else NULL end),
		@lstMthTotalCmtdUnits=		max(Case when isnull(JCCP.TotalCmtdUnits,0) <> 0 then Mth else NULL end),
		@lstMthTotalCmtdCost=		max(Case when isnull(JCCP.TotalCmtdCost,0) <> 0 then Mth else NULL end),
		@lstMthRemainCmtdUnits=		max(Case when isnull(JCCP.RemainCmtdUnits,0) <> 0 then Mth else NULL end),
		@lstMthRemainCmtdCost=		max(Case when isnull(JCCP.RemainCmtdCost,0) <> 0 then Mth else NULL end),
		@lstMthRecvdNotInvcdUnits=	max(Case when isnull(JCCP.RecvdNotInvcdUnits,0) <> 0 then Mth else NULL end),
		@lstMthRecvdNotInvcdCost=	max(Case when isnull(JCCP.RecvdNotInvcdCost,0) <> 0 then Mth else NULL end)
from bJCCP JCCP with (nolock)
join JCJM with (nolock) on JCCP.JCCo=JCJM.JCCo and JCCP.Job=isnull(@job,JCJM.Job)
join JCCM with (nolock) on JCCM.JCCo=JCJM.JCCo and JCCM.Contract=JCJM.Contract
where JCCM.JCCo = @jcco and JCCM.Contract = @contract 
and (JCJM.Job = case when @job is null then '' else @job end or @job is null) -- Issue 130955

if @@rowcount = 0
	begin
	select @msg = 'Contract not on file!', @rcode = 1
	goto bspexit
	end

If @batchmonth < @lstMthRevenue 
	begin
	select @warning = 'Revenue postings in future months.  Unable to close.'
	goto bspexit
	end

If @batchmonth < @lstMthCost 
	begin
	select @warning = 'Cost postings in future months.  Unable to close.'
	goto bspexit
	end

If @batchmonth < @lstMthCost and @batchmonth < @lstMthRevenue
	begin
	select @warning = 'Cost and Revenue postings in future months.  Unable to close.'
	goto bspexit
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCContractCloseVal] TO [public]
GO
