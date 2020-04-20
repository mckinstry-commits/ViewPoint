SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCContractCloseInitialize    Script Date: 8/28/99 9:32:57 AM ******/
   CREATE   proc [dbo].[vspJCContractCloseInitialize]
   	(@jcco bCompany = 0, 
	@batchmonth bMonth = null,
    @batchid bBatchID = null,
	@status char(1) = null,
	@closedate bDate = null,		
	@initialize char(1)=null,
	@begcontract bContract = null, 
	@endcontract bContract = null, 
	@throughmonth bMonth = null,
	@msg varchar(255) output)

   as
   set nocount on

   /***********************************************************
    * CREATED BY: DANF 10/05/2006
    * MODIFIED By : 
    *
    * USAGE:
    * initialize contract close batch.
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against
    *   batchmonth  
    *	batchid
	*	status  - Close status S = Soft close or F for Final Close
	*   initialize - R by contract range or M by month
	*   begcontract - when initialize = R
	*	endcontract - when initialize = R
	*	throughmonth - when initialize = M
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Contract
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   
   	declare @rcode int,  @MaxSeq int, @contract bContract, @lstmthrevenue bMonth, @lstmthcost bMonth, @contractstatus tinyint
			
   	select @rcode = 0, @MaxSeq = 0
      
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end

      
   if @initialize is null
   	begin
   	select @msg = 'Missing Initialize option!', @rcode = 1
   	goto bspexit
   	end


if @initialize = 'M' and @throughmonth is null
   	begin
   	select @msg = 'Missing through month!', @rcode = 1
   	goto bspexit
   	end


--Cycle Mode would include all Contracts that match the following conditions:
--    By "Range of Contracts "
--        Final Close(m_BatchStatus) will include contracts that have a Contract Status of Open(1) or Soft Closed (2)
--        Soft Close(m_BatchStatus) will include contracts that have a Contract Status of Open(1)
--        Contract Close Batch Month(m_BatchMonth) is equal to or latter than the Contract start month(StartMonth)!

if @initialize = 'R' 
	begin

		if @status = 'S'
			begin

			DECLARE Contract_Cursor CURSOR local fast_forward  FOR
			select JCCM.Contract, JCContractLastMthActivity.lstMthRevenue, JCContractLastMthActivity.lstMthCost, JCCM.ContractStatus
			from JCCM with (nolock) 
			join JCContractLastMthActivity JCContractLastMthActivity
			on JCCM.JCCo = JCContractLastMthActivity.JCCo and JCCM.Contract = JCContractLastMthActivity.Contract and isnull(JCContractLastMthActivity.Job,'') = ''
			where JCCM.JCCo = @jcco and JCCM.Contract >= @begcontract and JCCM.Contract <= @endcontract
				 and JCCM.StartMonth <= @batchmonth  and JCCM.ContractStatus = 1 
			and not exists(select top 1 1 
							from JCXB o with (nolock) where o.Co = JCCM.JCCo and o.Contract=JCCM.Contract)
			OPEN Contract_Cursor
			FETCH NEXT FROM Contract_Cursor INTO @contract, @lstmthrevenue, @lstmthcost, @contractstatus
			WHILE @@FETCH_STATUS = 0
			   BEGIN
					select @MaxSeq = isnull(MAX(BatchSeq),0) from JCXB x with (nolock) where x.Co = @jcco and x.Mth = @batchmonth and x.BatchId = @batchid

					insert into bJCXB (Co, Mth, BatchId, Contract, Job, LastContractMth, LastJobMth, CloseDate, SoftFinal, CloseStatus,BatchSeq)
					values			(@jcco,  @batchmonth, @batchid, @contract, null, @lstmthrevenue, @lstmthcost, @closedate, @status, @contractstatus, @MaxSeq+1 )

					EXEC @rcode = [dbo].[vspJCXBAddRemove] @jcco, @batchmonth, @batchid, @closedate, @lstmthrevenue, @lstmthcost,  @contract,@status, 'A', @msg = @msg OUTPUT

					FETCH NEXT FROM Contract_Cursor INTO @contract, @lstmthrevenue, @lstmthcost, @contractstatus
			   END
			CLOSE Contract_Cursor
			DEALLOCATE Contract_Cursor

			end
		else
			begin

			DECLARE Contract_Cursor CURSOR local fast_forward  FOR
			select JCCM.Contract, JCContractLastMthActivity.lstMthRevenue, JCContractLastMthActivity.lstMthCost, JCCM.ContractStatus
			from JCCM with (nolock) 
			join JCContractLastMthActivity JCContractLastMthActivity
			on JCCM.JCCo = JCContractLastMthActivity.JCCo and JCCM.Contract = JCContractLastMthActivity.Contract and isnull(JCContractLastMthActivity.Job,'') = ''
			where JCCM.JCCo = @jcco and JCCM.Contract >= @begcontract and JCCM.Contract <= @endcontract
				 and JCCM.StartMonth <= @batchmonth and (JCCM.ContractStatus = 1 or JCCM.ContractStatus = 2)
			and not exists(select top 1 1 
							from JCXB o with (nolock) where o.Co = JCCM.JCCo and o.Contract=JCCM.Contract)
			OPEN Contract_Cursor
			FETCH NEXT FROM Contract_Cursor INTO @contract, @lstmthrevenue, @lstmthcost, @contractstatus
			WHILE @@FETCH_STATUS = 0
			   BEGIN
					select @MaxSeq = isnull(MAX(BatchSeq),0) from JCXB x with (nolock) where x.Co = @jcco and x.Mth = @batchmonth and x.BatchId = @batchid

					insert into bJCXB (Co, Mth, BatchId, Contract, Job, LastContractMth, LastJobMth, CloseDate, SoftFinal, CloseStatus,BatchSeq)
					values			(@jcco, @batchmonth, @batchid, @contract, null, @lstmthrevenue, @lstmthcost, @closedate, @status, @contractstatus, @MaxSeq+1 )

					EXEC @rcode = [dbo].[vspJCXBAddRemove] @jcco, @batchmonth, @batchid, @closedate, @lstmthrevenue, @lstmthcost,  @contract,@status, 'A', @msg = @msg OUTPUT

					FETCH NEXT FROM Contract_Cursor INTO @contract, @lstmthrevenue, @lstmthcost, @contractstatus
			   END
			CLOSE Contract_Cursor
			DEALLOCATE Contract_Cursor

			end

	end

--    "Through Closed Month"
--        Final Close(m_BatchStatus) will include contracts that have a Contract Status of Open(1) or Soft Closed (2)
--        Soft Close(m_BatchStatus) will include contracts that have a Contract Status of Open(1)
--        Contract Close Batch Month(m_BatchMonth) is equal to or latter than the Contract start month(StartMonth)!
--        Contract Month Closed is less than "Through Closed Month"
if @initialize = 'M'
	begin
		if @status = 'S'
			begin
			DECLARE Contract_Cursor CURSOR local fast_forward  FOR
			select JCCM.Contract, JCContractLastMthActivity.lstMthRevenue, JCContractLastMthActivity.lstMthCost, JCCM.ContractStatus
			from JCCM with (nolock) 
			join JCContractLastMthActivity JCContractLastMthActivity
			on JCCM.JCCo = JCContractLastMthActivity.JCCo and JCCM.Contract = JCContractLastMthActivity.Contract and isnull(JCContractLastMthActivity.Job,'') = ''
			where JCCM.JCCo = @jcco and JCCM.MonthClosed <= @throughmonth and JCCM.StartMonth <= @batchmonth and JCCM.ContractStatus = 1
			and not exists(select top 1 1 
							from JCXB o with (nolock) where o.Co = JCCM.JCCo and o.Contract=JCCM.Contract)
			OPEN Contract_Cursor
			FETCH NEXT FROM Contract_Cursor INTO @contract, @lstmthrevenue, @lstmthcost, @contractstatus
			WHILE @@FETCH_STATUS = 0
			   BEGIN
					select @MaxSeq = isnull(MAX(BatchSeq),0) from JCXB x with (nolock) where x.Co = @jcco and x.Mth = @batchmonth and x.BatchId = @batchid

					insert into bJCXB (Co, Mth, BatchId, Contract, Job, LastContractMth, LastJobMth, CloseDate, SoftFinal, CloseStatus,BatchSeq)
					values			(@jcco, @batchmonth, @batchid, @contract, null, @lstmthrevenue, @lstmthcost, @closedate, @status, @contractstatus, @MaxSeq+1 )

					EXEC @rcode = [dbo].[vspJCXBAddRemove] @jcco, @batchmonth, @batchid,	@closedate, @lstmthrevenue, @lstmthcost,  @contract,@status, 'A', @msg = @msg OUTPUT

					FETCH NEXT FROM Contract_Cursor INTO @contract, @lstmthrevenue, @lstmthcost, @contractstatus
			   END
			CLOSE Contract_Cursor
			DEALLOCATE Contract_Cursor
			end

		else
			begin
			DECLARE Contract_Cursor CURSOR local fast_forward  FOR
			select JCCM.Contract, JCContractLastMthActivity.lstMthRevenue, JCContractLastMthActivity.lstMthCost, JCCM.ContractStatus
			from JCCM with (nolock) 
			join JCContractLastMthActivity JCContractLastMthActivity
			on JCCM.JCCo = JCContractLastMthActivity.JCCo and JCCM.Contract = JCContractLastMthActivity.Contract and isnull(JCContractLastMthActivity.Job,'') = ''
			where JCCM.JCCo = @jcco and JCCM.MonthClosed <= @throughmonth and JCCM.StartMonth <= @batchmonth and (JCCM.ContractStatus = 1 or JCCM.ContractStatus = 2) 
			and not exists(select top 1 1 
							from JCXB o with (nolock) where o.Co = JCCM.JCCo and o.Contract=JCCM.Contract)
			OPEN Contract_Cursor
			FETCH NEXT FROM Contract_Cursor INTO @contract, @lstmthrevenue, @lstmthcost, @contractstatus
			WHILE @@FETCH_STATUS = 0
			   BEGIN
					select @MaxSeq = isnull(MAX(BatchSeq),0) from JCXB x with (nolock) where x.Co = @jcco and x.Mth = @batchmonth and x.BatchId = @batchid

					insert into bJCXB (Co, Mth, BatchId, Contract, Job, LastContractMth, LastJobMth, CloseDate, SoftFinal, CloseStatus,BatchSeq)
					values (@jcco,  @batchmonth, @batchid, @contract, null, @lstmthrevenue, @lstmthcost, @closedate, @status, @contractstatus, @MaxSeq+1  )

					EXEC @rcode = [dbo].[vspJCXBAddRemove] @jcco, @batchmonth, @batchid,	@closedate, @lstmthrevenue, @lstmthcost,  @contract,@status, 'A', @msg = @msg OUTPUT

					FETCH NEXT FROM Contract_Cursor INTO @contract, @lstmthrevenue, @lstmthcost, @contractstatus
			   END
			CLOSE Contract_Cursor
			DEALLOCATE Contract_Cursor
			end

	   end

   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCContractCloseInitialize] TO [public]
GO
