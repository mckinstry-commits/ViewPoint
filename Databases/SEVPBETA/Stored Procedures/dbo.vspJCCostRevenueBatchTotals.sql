SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCJPRecalcAmounts    Script Date: 05/23/2005 ******/
CREATE   procedure [dbo].[vspJCCostRevenueBatchTotals]
/***********************************************************
 * Created By:	DANF 06/09/2005
 * Modified By:
 *
 * USAGE:
 * Returns batch totals for the JC Cost Adjustment, JC Revenue Adjustments, 
 * and JC Material Use Forms. 
 * 
 *
 *
 * INPUT PARAMETERS
 * JCCo
 * Month
 * Batchid
 * Source
 *
 * OUTPUT PARAMETERS
 * Total Credits
 * Total Debits
 * Undistributed
 * Total
 *
 * RETURN VALUE
 * 0 = success, 1 = failure
 *****************************************************/ 
(@jcco bCompany, @mth bMonth,  @batchid bBatchID, @source bSource,
 @totalcredits bDollar output, @totaldebits bDollar output, 
 @undistributed bDollar output, @total bDollar output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @totalcredits = 0, @totaldebits = 0, @undistributed = 0, @total = 0, @msg=''

if @jcco is null or @mth is null or @batchid is null or @source is null goto bspexit


if @source = 'JC CostAdj' 
	begin
	-- Key Co \ Mth \ BatchId

	select 
				@total = sum(case TransType 
						when 'A' then isnull(Cost,0)
						when 'C' then isnull(Cost,0) - isnull(OldCost,0)
						when 'D' then -isnull(Cost,0)
						end),
		@totalcredits = sum( case TransType
							when 'A' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)< 0 then ABS(isnull(Cost,0))
												else 0
											end
										  else
											ABS(isnull(Cost,0))
										  end
							when 'C' then  case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)< 0 then ABS(isnull(Cost,0)) - ABS(isnull(OldCost,0))
												else 0
											end
										  else
											ABS(isnull(Cost,0)) - ABS(isnull(OldCost,0))
										  end

							when 'D' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)< 0 then -ABS(isnull(Cost,0))
												else 0
											end
										  else
											-ABS(isnull(Cost,0))
										  end 
							end),
		@totaldebits = sum( case TransType
							when 'A' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)> 0 then ABS(isnull(Cost,0))
												else 0
											end
										  else
											ABS(isnull(Cost,0))
										  end
							when 'C' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)> 0 then ABS(isnull(Cost,0)) - ABS(isnull(OldCost,0))
												else 0
											end
										  else
											ABS(isnull(Cost,0)) - ABS(isnull(OldCost,0))
										  end
							when 'D' then  case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)> 0 then -ABS(isnull(Cost,0))
												else 0
											end
										  else
											-ABS(isnull(Cost,0))
										  end
							end),
		@undistributed = sum( case TransType
							when 'A' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)> 0 then ABS(isnull(Cost,0))
												when isnull(Cost,0)< 0 then -ABS(isnull(Cost,0))
												else 0
											end
										  else
											0
										  end
							when 'C' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)> 0 then ABS(isnull(Cost,0)) - ABS(isnull(OldCost,0))
												when isnull(Cost,0)< 0 then -ABS(isnull(Cost,0)) + ABS(isnull(OldCost,0))
												else 0
											end
										  else
											0
										  end
							when 'D' then  case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(Cost,0)> 0 then -ABS(isnull(Cost,0))
												when isnull(Cost,0)< 0 then ABS(isnull(Cost,0))
												else 0
											end
										  else
											0
										  end
							end)
	from JCCB with (nolock)
	where Co = @jcco and Mth = @mth and BatchId = @batchid

	end

if @source = 'JC RevAdj'
	begin
	-- Key Co \ Mth \ BatchId
	select
		@total = sum(case TransType 
						when 'A' then isnull(BilledAmt,0)
						when 'C' then isnull(BilledAmt,0) - isnull(OldBilledAmt,0)
						when 'D' then -isnull(BilledAmt,0)
						end),
		@totalcredits = sum( case TransType
							when 'A' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)< 0 then ABS(isnull(BilledAmt,0))
												else 0
											end
										  else
											ABS(isnull(BilledAmt,0))
										  end
							when 'C' then  case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)< 0 then ABS(isnull(BilledAmt,0)) - ABS(isnull(OldBilledAmt,0))
												else 0
											end
										  else
											ABS(isnull(BilledAmt,0)) - ABS(isnull(OldBilledAmt,0))
										  end

							when 'D' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)< 0 then -ABS(isnull(BilledAmt,0))
												else 0
											end
										  else
											-ABS(isnull(BilledAmt,0))
										  end 
							end),
		@totaldebits = sum( case TransType
							when 'A' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)> 0 then ABS(isnull(BilledAmt,0))
												else 0
											end
										  else
											ABS(isnull(BilledAmt,0))
										  end
							when 'C' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)> 0 then ABS(isnull(BilledAmt,0)) - ABS(isnull(OldBilledAmt,0))
												else 0
											end
										  else
											ABS(isnull(BilledAmt,0)) - ABS(isnull(OldBilledAmt,0))
										  end
							when 'D' then  case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)> 0 then -ABS(isnull(BilledAmt,0))
												else 0
											end
										  else
											-ABS(isnull(BilledAmt,0))
										  end
							end),
		@undistributed = sum( case TransType
							when 'A' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)> 0 then ABS(isnull(BilledAmt,0))
												when isnull(BilledAmt,0)< 0 then -ABS(isnull(BilledAmt,0))
												else 0
											end
										  else
											0
										  end
							when 'C' then case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)> 0 then ABS(isnull(BilledAmt,0)) - ABS(isnull(OldBilledAmt,0))
												when isnull(BilledAmt,0)< 0 then -ABS(isnull(BilledAmt,0)) + ABS(isnull(OldBilledAmt,0))
												else 0
											end
										  else
											0
										  end
							when 'D' then  case isnull(GLOffsetAcct,'') 
											when '' then
											case  
												when isnull(BilledAmt,0)> 0 then -ABS(isnull(BilledAmt,0))
												when isnull(BilledAmt,0)< 0 then ABS(isnull(BilledAmt,0))
												else 0
											end
										  else
											0
										  end
							end)
	from JCIB with (nolock)
	where Co = @jcco and Mth = @mth and BatchId = @batchid

	end

if @source = 'JC MatUse' 
	begin
	-- Key Co \ Mth \ BatchId

	select 
				@total = sum(case TransType 
						when 'A' then isnull(Cost,0)
						when 'C' then isnull(Cost,0) - isnull(OldCost,0)
						when 'D' then -isnull(Cost,0)
						end)
	from JCCB with (nolock)
	where Co = @jcco and Mth = @mth and BatchId = @batchid
	end

if  @totalcredits is null select @totalcredits = 0
if  @totaldebits is null select @totaldebits = 0
if  @undistributed is null select @undistributed = 0
if  @total is null select @total = 0


/*
-- Action = TransType 
-- Old Amt = OldCost - OldBilledAmt
-- Gl Offsetaccount = GLOffsetAcct - GLOffsetAcct

   Case "A" 'Adding a row

                    If GLOffsetAcct = "" Then 'no GLOffsetAcct specified
                        'If +Amt:
                        '       Add Abs(Amt) to Debits
                        '       Add 0 to Credits
                        '       Add Abs(Amt) to Undistributed
                        'If -Amt"
                        '       Add 0 to Debits
                        '       Add Abs(Amt) to Credits
                        '       Add Abs(Amt) to Undistributed

                        If Amt > 0 Then
                            TotalDebits = TotalDebits + Abs(Amt)
                            Undistributed = Undistributed + Abs(Amt)
                        Else
                            TotalCredits = TotalCredits + Abs(Amt)
                            Undistributed = Undistributed - Abs(Amt)
                        End If

                    Else 'both GLTransAcct and GLOffsetAcct specified
                        'If + or - Amt:
                        '       Add Abs(Amt) to Debits
                        '       Add Abs(Amt) to Credits
                        '       Add 0 to Undistributed

                        TotalDebits = TotalDebits + Abs(Amt)
                        TotalCredits = TotalCredits + Abs(Amt)
                        Undistributed = Undistributed + 0

                    End If

                Case "C" 'Changing a row

                    If GLOffsetAcct = "" Then 'no GLOffsetAcct specified
                        'If +Amt:
                        '       Add Abs(Amt) - Abs(OldAmt) to Debits
                        '       Add 0 to Credits
                        '       Add Abs(Amt) - Abs(OldAmt) to Undistributed
                        'If -Amt"
                        '       Add 0 to Debits
                        '       Add Abs(Amt) - Abs(OldAmt) to Credits
                        '       Add Abs(Amt) - Abs(OldAmt) to Undistributed
                        If Amt > 0 Then
                            TotalDebits = TotalDebits + Abs(Amt) - Abs(OldAmt)
                            Undistributed = Undistributed + Abs(Amt) - Abs(OldAmt)
                        Else
                            TotalCredits = TotalCredits + Abs(Amt) - Abs(OldAmt)
                            Undistributed = Undistributed - Abs(Amt) + Abs(OldAmt)
                        End If

                    Else 'both GLTransAcct and GLOffsetAcct specified
                        'If + or - Amt:
                        '       Add Abs(Amt)  - Abs(OldAmt) to Debits
                        '       Add Abs(Amt)  - Abs(OldAmt) to Credits
                        '       Add 0 to Undistributed
                        TotalDebits = TotalDebits + Abs(Amt) - Abs(OldAmt)
                        TotalCredits = TotalCredits + Abs(Amt) - Abs(OldAmt)
                        Undistributed = Undistributed + 0

                    End If

                Case "D"

                    If GLOffsetAcct = "" Then 'no GLOffsetAcct specified
                        'If +Amt:
                        '       Subtract Abs(Amt) from Debits
                        '       Subtract 0 from Credits
                        '       Subtract Abs(Amt) from Undistributed
                        'If -Amt"
                        '       Subtract 0 from Debits
                        '       Subtract Abs(Amt) from Credits
                        '       Subtract Abs(Amt) from Undistributed
                        If Amt > 0 Then
                            TotalDebits = TotalDebits - Abs(Amt)
                            Undistributed = Undistributed - Abs(Amt)
                        Else
                            TotalCredits = TotalCredits - Abs(Amt)
                            Undistributed = Undistributed + Abs(Amt)
                        End If

                    Else 'both GLTransAcct and GLOffsetAcct specified
                        'If + or - Amt:
                        '       Subtract Abs(Amt) from Debits
                        '       Subtract Abs(Amt) from Credits
                        '       Subtract 0 from Undistributed
                        TotalDebits = TotalDebits - Abs(Amt)
                        TotalCredits = TotalCredits - Abs(Amt)
                        Undistributed = Undistributed - 0

                    End If
*/


bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCostRevenueBatchTotals] TO [public]
GO
