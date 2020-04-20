SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMBatchDescTotals]
  /***********************************************************
   * CREATED BY: DANF 07/26/2007
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in  EM Cost Adjustments to return the a description to the key field and totals.
   *
   * INPUT PARAMETERS
   *   EMCo   			EM Co 
   *   Month			Month
   *   BatchId			Batch ID
   *   BatchSeq			Batch Seq
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
(@emco bCompany, @mth bMonth,  @batchid bBatchID, 
 @batchseq int, @totalcredits bDollar output, @totaldebits bDollar output, 
 @undistributed bDollar output, @msg varchar(255) output)
  as
  set nocount on
  
  	declare @rcode int, @rc int
  	select @rcode = 0, @msg=''
  
 	if @emco is not null and  isnull(@mth,'') <> '' 
		begin
	  		select @msg = Description 
	  		from dbo.EMBF with (nolock)
	  		where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

			select 
			@totalcredits = sum( case BatchTransType
								when 'A' then case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)< 0 then ABS(isnull(Dollars,0))
													else 0
												end
											  else
												ABS(isnull(Dollars,0))
											  end
								when 'C' then  case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)< 0 then ABS(isnull(Dollars,0)) - ABS(isnull(OldDollars,0))
													else 0
												end
											  else
												ABS(isnull(Dollars,0)) - ABS(isnull(OldDollars,0))
											  end

								when 'D' then case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)< 0 then -ABS(isnull(Dollars,0))
													else 0
												end
											  else
												-ABS(isnull(Dollars,0))
											  end 
								end),
			@totaldebits = sum( case BatchTransType
								when 'A' then case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)> 0 then ABS(isnull(Dollars,0))
													else 0
												end
											  else
												ABS(isnull(Dollars,0))
											  end
								when 'C' then case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)> 0 then ABS(isnull(Dollars,0)) - ABS(isnull(OldDollars,0))
													else 0
												end
											  else
												ABS(isnull(Dollars,0)) - ABS(isnull(OldDollars,0))
											  end
								when 'D' then  case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)> 0 then -ABS(isnull(Dollars,0))
													else 0
												end
											  else
												-ABS(isnull(Dollars,0))
											  end
								end),
			@undistributed = sum( case BatchTransType
								when 'A' then case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)> 0 then ABS(isnull(Dollars,0))
													when isnull(Dollars,0)< 0 then -ABS(isnull(Dollars,0))
													else 0
												end
											  else
												0
											  end
								when 'C' then case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)> 0 then ABS(isnull(Dollars,0)) - ABS(isnull(OldDollars,0))
													when isnull(Dollars,0)< 0 then -ABS(isnull(Dollars,0)) + ABS(isnull(OldDollars,0))
													else 0
												end
											  else
												0
											  end
								when 'D' then  case isnull(GLOffsetAcct,'') 
												when '' then
												case  
													when isnull(Dollars,0)> 0 then -ABS(isnull(Dollars,0))
													when isnull(Dollars,0)< 0 then ABS(isnull(Dollars,0))
													else 0
												end
											  else
												0
											  end
								end)
			from EMBF with (nolock)
			where Co = @emco and Mth = @mth and BatchId = @batchid
		end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMBatchDescTotals] TO [public]
GO
