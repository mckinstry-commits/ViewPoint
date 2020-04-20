SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJCCloseBatchDescTotals]
  /***********************************************************
   * CREATED BY: DANF 05/23/2007
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC Close to return totals.
   *
   * INPUT PARAMETERS
   *   JCCo   			JC Co 
   *   Month			Month
   *   BatchId			Batch ID
   *   BatchSeq			Batch Seq
   *   Source			Source
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
	Seq    ColumnName                Description
	------ ------------------------- ------------------------------
	200    NULL                      Last Mth Orig Contract Units
	205    lstMthOrigContractAmount  Last Mth Orig Contract Amount
	210    NULL                      Last Mth Curr Contract Amount
	215    lstMthContractUnits       Last Mth Cur Contract Units
	220    lstMthBilledTax           Last Mth Billed Tax Amount
	225    lstMthBilledAmount        Last Mth Billed Amount
	235    lstMthActualHours         Last Mth Actual Hours
	240    lstMthActualUnits         Last Mth Actual Units
	245    lstMthActualCost          Last Mth Actual Cost
	250    lstMthOrigHours           Last Mth Orig Hours
	255    lstMthOrigUnits           Last Mth Orig Units
	260    lstMthOrigCost            Last Mth Orig Cost
	265    lstMthCurrEstHours        Last Mth Cur Est Hours
	270    lstMthCurrEstUnits        Last Mth Cur Est Units
	275    lstMthCurrEstCost         Last Mth Cur Est Cost
	280    lstMthProjHours           Last Mth Projected Hours
	285    lstMthProjUnits           Last Mth Projected Units
	290    lstMthProjCost            Last Mth Projected Cost
	295    lstMthForecastHours       Last Mth Forecast Hours
	300    lstMthForecastUnits       Last Mth Forecast Units
	305    lstMthForecastCost        Last Mth Forecast Cost
	310    lstMthTotalCmtdUnits      Last Mth Total Cmtd Units
	315    lstMthTotalCmtdCost       Last Mth Total Cmtd Cost
	320    lstMthRemainCmtdUnits     Last Mth Remain Cmtd Units
	325    lstMthRemainCmtdCost      Last Mth Remain Cmtd Cost
	330    lstMthRecvdNotInvcdUnits  Last Mth Recv'd Not Invcd Unts
	335    lstMthRecvdNotInvcdCost   Last Mth Recv'd Not Invcd Cost

	-- join JCContractLastMthActivity JCContractLastMthActivity
	-- on JCXB.Co = JCContractLastMthActivity.JCCo and JCXB.Contract = JCContractLastMthActivity.Contract and isnull(JCXB.Job,'') = isnull(JCContractLastMthActivity.Job,'')
   *****************************************************/ 
  
(@jcco bCompany, @Contract bContract, @Job bJob, @batchmonth bMonth, @batchid int,
	@lstMthOrigContractUnits bDate output, 
	@lstMthOrigContractAmount bDate output, 
	@lstMthContractAmount bDate output, 
	@lstMthContractUnits bDate output, 
	@lstMthBilledTax bDate output, 
	@lstMthBilledAmount bDate output, 
	@lstMthCurrentRetainageAmount bDate output, 
	@lstMthActualHours bDate output, 
	@lstMthActualUnits bDate output, 
	@lstMthActualCost bDate output, 
	@lstMthOrigHours bDate output, 
	@lstMthOrigUnits bDate output, 
	@lstMthOrigCost bDate output, 
	@lstMthCurrEstHours bDate output, 
	@lstMthCurrEstUnits bDate output, 
	@lstMthCurrEstCost bDate output, 
	@lstMthProjHours bDate output, 
	@lstMthProjUnits bDate output, 
	@lstMthProjCost bDate output, 
	@lstMthForecastHours bDate output, 
	@lstMthForecastUnits bDate output, 
	@lstMthForecastCost bDate output, 
	@lstMthTotalCmtdUnits bDate output, 
	@lstMthTotalCmtdCost bDate output, 
	@lstMthRemainCmtdUnits bDate output, 
	@lstMthRemainCmtdCost bDate output, 
	@lstMthRecvdNotInvcdUnits bDate output, 
	@lstMthRecvdNotInvcdCost bDate output,
 @msg varchar(255) output)
  as
  set nocount on
  
  	declare @rcode int, @rc int
  	select @rcode = 0, @msg=''
  
 	if @jcco is not null and  isnull(@Contract,'') <> ''
		begin

				select @lstMthOrigContractUnits = lstMthOrigContractUnits,
					   @lstMthContractAmount = lstMthContractAmount
				from JCContractLastMthActivity
				where JCCo = @jcco and Contract = @Contract and isnull(Job,'') = isnull(@Job,'')
/*
				exec dbo.vspJCContractCloseVal @jcco, @Contract, @batchmonth, @batchid, --@status, @startmonth, @lstMthRevenue, @lstMthCost, 
												@lstMthOrigContractUnits, 
												@lstMthOrigContractAmount, 
												@lstMthContractAmount, 
												@lstMthContractUnits, 
												@lstMthBilledTax,
												@lstMthBilledAmount, 
												@lstMthCurrentRetainageAmount, 
												@lstMthActualHours, 
												@lstMthActualUnits, 
												@lstMthActualCost, 
												@lstMthOrigHours, 
												@lstMthOrigUnits, @lstMthOrigCost, 
												@lstMthCurrEstHours, @lstMthCurrEstUnits, @lstMthCurrEstCost, 
												@lstMthProjHours, @lstMthProjUnits, @lstMthProjCost, 
												@lstMthForecastHours, @lstMthForecastUnits, @lstMthForecastCost, 
												@lstMthTotalCmtdUnits, @lstMthTotalCmtdCost, 
												@lstMthRemainCmtdUnits, @lstMthRemainCmtdCost, 
												@lstMthRecvdNotInvcdUnits, @lstMthRecvdNotInvcdCost, 
												--@warning, 
												@msg
*/
		end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCloseBatchDescTotals] TO [public]
GO
