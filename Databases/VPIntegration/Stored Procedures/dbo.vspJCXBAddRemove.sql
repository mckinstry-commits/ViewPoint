SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCXBAddRemove    Script Date: 8/28/99 9:34:15 AM ******/
   CREATE  proc [dbo].[vspJCXBAddRemove]
   
   
   /***********************************************************
    * CREATED BY: CJW   April 15  
    * MODIFIED By : CJW April 15
    * Modified By:  GR 11/11/99 -modified the error message to display the month
    *               if contract already exisits in JCClose program
    *				DANF 10/6/06 - recode 6.x
    *
    * USAGE:
    * creates JCXB entries
    * an error is returned if any goes wrong.
    *
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to get JCPC recs from
    *   Contract    Contract to add
    *
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@jcco bCompany = 0, @Mth bMonth, @BatchID int, @CloseDate bDate,  @LastRevenue bDate,
   			@LastCost bDate, @Contract bContract = null, @SoftFinal char,
   			@AddorRemove varchar(1), @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @id int, @batchmth bMonth, @MaxSeq int
   
   select @rcode = 0, @MaxSeq = 1
   
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @AddorRemove='A'
     begin
        select @id = BatchId, @batchmth=Mth from JCXB
        where JCXB.Co = @jcco and JCXB.Contract=@Contract
        if @@rowcount>0 and @id <> @BatchID and @batchmth <> @Mth
   			begin
   			select @msg = 'Contract already exists in JCClose batch: ' +
							  convert(varchar(10),@id) + ' for Mth: ' +
							  convert(varchar(3),@batchmth,1) +
							  substring(convert(varchar(8),@batchmth,1),7,2) , @rcode = 1
		   
   			goto bspexit
   			end
   
        if exists(select distinct JCCM.Contract,JCJM.Job from JCCM
					left join JCJM on JCJM.JCCo=JCCM.JCCo and JCJM.Contract=JCCM.Contract
   					where JCCM.Contract = @Contract and JCCM.JCCo=@jcco)
   
           begin
			select @MaxSeq = MAX(BatchSeq)from JCXB x where x.Co = @jcco and x.Mth = @Mth and x.BatchId = @BatchID

   			insert into bJCXB (Co, Mth, BatchId, Contract, Job, LastContractMth, LastJobMth, CloseDate, SoftFinal, CloseStatus, BatchSeq)
            select distinct @jcco,@Mth, @BatchID, @Contract, null, @LastRevenue, @LastCost, @CloseDate, @SoftFinal, JCCM.ContractStatus,
			@MaxSeq + ROW_NUMBER() OVER(ORDER BY JCCM.Contract ASC)
			from JCCM JCCM with (nolock)
			where JCCM.Contract = @Contract and JCCM.JCCo=@jcco 
			and not exists(select top 1 1 from JCXB JCXB with (nolock) where JCXB.Co = JCCM.JCCo and JCXB.Contract = JCCM.Contract and JCXB.Job is null)

			select @MaxSeq = MAX(BatchSeq)from JCXB x where x.Co = @jcco and x.Mth = @Mth and x.BatchId = @BatchID

            insert into bJCXB (Co, Mth, BatchId, Contract, Job, LastContractMth, LastJobMth, CloseDate, SoftFinal, CloseStatus, BatchSeq)
            select distinct @jcco, @Mth, @BatchID, @Contract, JCJM.Job, @LastRevenue, @LastCost, @CloseDate, @SoftFinal,JCJM.JobStatus,
			 @MaxSeq + ROW_NUMBER() OVER(ORDER BY JCJM.Job ASC)
			from JCCM JCCM with (nolock)
            join JCJM JCJM with (nolock) on JCJM.JCCo=JCCM.JCCo and JCJM.Contract=JCCM.Contract
            where JCCM.Contract = @Contract and JCCM.JCCo=@jcco
			and not exists(select top 1 1 from JCXB JCXB with (nolock) where JCXB.Co = JCCM.JCCo and JCXB.Contract = JCCM.Contract and JCXB.Job = JCJM.Job)
   
   			update bJCCM			/* update JCCM to show this contract is currently in batch */
   			set InBatchMth = @Mth, InUseBatchId = @BatchID
   			where bJCCM.JCCo=@jcco and bJCCM.Contract = @Contract
           end
       else
          begin
             select @rcode =1, @msg = 'Contract not on file'
          end
   
        select @rcode = 0, @msg = convert(varchar(5),@@rowcount) + 'Rows inserted!'
      end
   
   if @AddorRemove='R'
   		begin
   			delete JCXB where JCXB.Co=@jcco and JCXB.Mth = @Mth and JCXB.BatchId=@BatchID and JCXB.Contract=@Contract 
   
			update bJCCM
   			set InBatchMth = null, InUseBatchId = null
   			where bJCCM.JCCo = @jcco and bJCCM.Contract = @Contract
      	end
   
    if @AddorRemove='U'
   	begin
		Update JCXB 
		set SoftFinal = @SoftFinal,
			CloseDate = @CloseDate
		where JCXB.Co = @jcco and JCXB.Mth = @Mth and JCXB.BatchId = @BatchID and JCXB.Contract=@Contract
    end

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCXBAddRemove] TO [public]
GO
