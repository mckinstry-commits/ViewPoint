USE Viewpoint
go

ALTER PROCEDURE mspRecalcJCCostForecast
    (
      @Company bCompany ,
      @Job bJob = null,
      @Contract bContract = NULL,
      @InitMonths bYN = 'N' ,
      @Debug INT = 0
    )
AS
    BEGIN
		SET NOCOUNT ON
		
        --DECLARE @Contract bContract
        DECLARE @TotEstCost NUMERIC(20, 2)
        DECLARE @ForecastStartMonth bDate
        DECLARE @ForecastEndMonth bDate

        DECLARE @ContractStartMonth bDate
        DECLARE @ContractEndMonth bDate

        DECLARE @ProjectionStartMonth bDate
        DECLARE @ProjectionEndMonth bDate

        DECLARE @CurrMonth bMonth
        DECLARE @CurrContractCostEstimate NUMERIC(20, 2)
        DECLARE @CurrContractRevenue NUMERIC(20, 2)	
        DECLARE @CurrMonthCostAmount NUMERIC(20, 2)
        DECLARE @CurrMonthCostPct NUMERIC(10,6)
        DECLARE @CurrMonthRevAmount NUMERIC(20, 2)
        DECLARE @CurrMonthRevPct NUMERIC(10,6)

        DECLARE @RemainingContractCost NUMERIC(20, 2)
        DECLARE @RemainingContractRevenue NUMERIC(20, 2)	
        DECLARE @RemainingMonths INT	
	
        DECLARE @NumMonths INT
        DECLARE @LoopCounter INT
		
		IF @Contract IS NULL and @Job IS NOT NULL
		BEGIN
			--Get Contract from Job
			SELECT  @Contract = Contract
			FROM    JCJM
			WHERE   JCCo = @Company
					AND Job = @Job --999049-001'
		END 
		
		IF @Contract IS NOT NULL
		BEGIN
			--Get Total Estimated Costs for all Jobs tied to Contract
			SELECT  @TotEstCost = SUM(jccp.CurrEstCost)
			FROM    JCJM jcjm
					JOIN JCCP jccp ON jcjm.JCCo = jccp.JCCo
									  AND jcjm.Job = jccp.Job
			WHERE   jccp.JCCo = @Company
					AND jcjm.Contract = @Contract

			-- Get Dates from JCCM and JCCP/JCPR to determine forecast spread.
			SELECT  @ContractStartMonth = jccm.StartMonth ,
					@ContractEndMonth = jccm.ProjCloseDate
			FROM    JCCM jccm
			WHERE   jccm.JCCo = @Company
					AND jccm.Contract = @Contract

		
			SELECT  @ProjectionStartMonth = MIN(jcpr.DetMth) ,
					@ProjectionEndMonth = MAX(jcpr.DetMth)
			FROM    JCCM jccm
					JOIN JCJM jcjm ON jccm.JCCo = jcjm.JCCo
									  AND jccm.Contract = jcjm.Contract
					JOIN JCCP jccp ON jcjm.JCCo = jccp.JCCo
									  AND jcjm.Job = jccp.Job
					JOIN JCPR jcpr ON jccp.JCCo = jcpr.JCCo
									  AND jccp.Job = jcpr.Job
			WHERE   jccm.JCCo = @Company
					AND jccm.Contract = @Contract

		   --Get Minimum StartDate ( Either JCCM StartMonth or ealiest JCCP Mth Value
			SELECT  
				@ForecastStartMonth = 
					CASE 
						WHEN @ContractStartMonth IS NOT NULL AND ( @ContractStartMonth <= @ProjectionStartMonth OR @ProjectionStartMonth IS NULL ) THEN @ContractStartMonth
						WHEN @ProjectionStartMonth IS NOT NULL AND ( @ProjectionStartMonth <= @ContractStartMonth OR @ContractStartMonth IS NULL ) THEN @ProjectionStartMonth
						ELSE NULL
					END


			--Get Maximum EndDate ( Either JCCM ProjCloseDate or latest JCCP Mth Value
			SELECT  @ForecastEndMonth = 
						CASE WHEN @ContractEndMonth IS NOT NULL AND ( @ContractEndMonth >= @ProjectionEndMonth OR @ProjectionEndMonth IS NULL ) THEN @ContractEndMonth
							WHEN @ProjectionEndMonth IS NOT NULL AND ( @ProjectionEndMonth >= @ContractEndMonth OR @ContractEndMonth IS NULL ) THEN @ProjectionEndMonth
							ELSE NULL
						END

			--Reformat Dates to Months (e.g. 1st of month)
			SELECT  @ForecastStartMonth = CAST(SUBSTRING(CONVERT(VARCHAR(10)
			,		@ForecastStartMonth, 102), 6, 2) + '/1/' + SUBSTRING(CONVERT(VARCHAR(10)
			,		@ForecastStartMonth, 102), 1, 4) AS DATETIME) 
			,		@ForecastEndMonth = CAST(SUBSTRING(CONVERT(VARCHAR(10), @ForecastEndMonth, 102),
													   6, 2) + '/1/'
					+ SUBSTRING(CONVERT(VARCHAR(10), @ForecastEndMonth, 102), 1, 4) AS DATETIME)

		--Run Custom Initialize
			EXEC mspJCForecastInitialize @JCCo = @Company	--bCompany = NULL
				, @InitializeBy = 'C'	--char(1) = NULL
				, @ReInit = @InitMonths	--bYN = NULL
				, @FutureMonths = 12	--tinyint = NULL
				, @InitPending = 'Y'	--char(1) = NULL
				, @InitOpen = 'Y'	--char(2) = NULL
				, @InitSoft = 'Y'	--char(1) = NULL
				, @InitHard = 'Y'	--char(1) = NULL
				, @BeginContract = @Contract	--bContract = NULL
				, @EndContract = @Contract	--bContract = NULL
				, @StartDate = @ForecastStartMonth --bMonth = NULL
				, @EndDate = @ForecastEndMonth		--bMonth = NULL
				, @ProjectMgr = NULL	--bProjectMgr = NULL
		
		
		-- Update JCForcastMonths with Actuals for history and spread the rest over the future months.
		-- Verify JCForcast Records for entire range
			SELECT  @NumMonths = DATEDIFF(MONTH, @ForecastStartMonth,@ForecastEndMonth) ,@RemainingMonths=DATEDIFF(MONTH, @ForecastStartMonth,@ForecastEndMonth),@LoopCounter = 0	
		
			SELECT  @CurrContractCostEstimate = CurrentEstimate 
			FROM    dbo.JCForecastTotalsCost
			WHERE   JCCo = @Company
					AND Contract = @Contract
					AND ForecastMonth = @ForecastEndMonth
		
			SELECT  @CurrContractRevenue = CurrentContract , @RemainingContractRevenue=CurrentContract
			FROM    dbo.JCForecastTotalsRev
			WHERE   JCCo = @Company
					AND Contract = @Contract
					AND ForecastMonth = @ForecastEndMonth
	            
			-- TODO: Get Total Projection Totals from Cost and Revenue Projects to calculate percentages for future months               

			WHILE @LoopCounter <= @NumMonths
				BEGIN	
					SELECT  @CurrMonth = DATEADD(month, @LoopCounter,@ForecastStartMonth)
			
					IF @CurrMonth < CAST(MONTH(GETDATE()) AS VARCHAR) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR)
						BEGIN
							--Process Actuals for Historical Entries
							IF EXISTS ( SELECT  1 FROM    dbo.JCForecastMonth WHERE   JCCo = @Company AND Contract = @Contract AND ForecastMonth = @CurrMonth )
								BEGIN
				
									IF EXISTS ( SELECT  1 FROM    JCForecastTotalsCost WHERE   JCCo = @Company AND Contract = @Contract AND ForecastMonth = @CurrMonth )
										BEGIN					
											SELECT  @CurrMonthCostAmount = ActualToDate
											FROM    JCForecastTotalsCost
											WHERE   JCCo = @Company
													AND Contract = @Contract
													AND ForecastMonth = @CurrMonth
										END
									ELSE
										BEGIN 
											SELECT  @CurrMonthCostAmount = 0.00
										END 
										
									--IF EXISTS ( SELECT  1 FROM    JCForecastTotalsCost WHERE   JCCo = @Company AND Contract = @Contract AND ForecastMonth = DATEADD(month,-1, @CurrMonth) )
									--	BEGIN
									--		SELECT  @CurrMonthCostAmount = @CurrMonthCostAmount - ActualToDate
									--		FROM    JCForecastTotalsCost
									--		WHERE   JCCo = @Company
									--				AND Contract = @Contract
									--				AND ForecastMonth = DATEADD(month,-1, @CurrMonth)

									--	END
				
									--TODO: Percentages need to be cumulative
									
									SELECT  @CurrMonthCostPct = /* COALESCE(@CurrMonthCostPct,0) + */
																CASE
																  WHEN @CurrContractCostEstimate = 0
																  THEN 0.00
																  ELSE CAST(( @CurrMonthCostAmount/@CurrContractCostEstimate ) AS NUMERIC(10,6))
																END
				
									PRINT @CurrMonthCostPct
		
				
									-- REVENUE: Current Month Percent
					
	 							
									IF EXISTS ( SELECT  1 FROM    JCForecastTotalsRev WHERE   JCCo = @Company AND Contract = @Contract AND ForecastMonth = @CurrMonth )
										BEGIN
											SELECT  @CurrMonthRevAmount = COALESCE(BilledToDate,0.00)
											FROM    JCForecastTotalsRev
											WHERE   JCCo = @Company
													AND Contract = @Contract
													AND ForecastMonth = @CurrMonth

										END
									ELSE
										BEGIN
											SELECT  @CurrMonthRevAmount = 0
										END
					
									--IF EXISTS ( SELECT  1 FROM    JCForecastTotalsRev WHERE   JCCo = @Company AND Contract = @Contract AND ForecastMonth = DATEADD(month,-1, @CurrMonth) )
									--	BEGIN
									--		SELECT  @CurrMonthRevAmount = @CurrMonthRevAmount - COALESCE(BilledToDate, 0.00)
									--		FROM    JCForecastTotalsRev
									--		WHERE   JCCo = @Company
									--				AND Contract = @Contract
									--				AND ForecastMonth = DATEADD(month,-1, @CurrMonth)

									--	END
							
									--TODO: Percentages need to be cumulative
									SELECT  @CurrMonthRevPct = /* COALESCE(@CurrMonthRevPct,0) + */
															   CASE
																  WHEN @CurrContractRevenue = 0 THEN 0.00
																  ELSE CAST(@CurrMonthRevAmount/@CurrContractRevenue AS NUMERIC(10,6))
															   END
									PRINT @CurrMonthRevPct
									
				
									UPDATE  dbo.JCForecastMonth
									SET     CostPct = @CurrMonthCostPct ,
											RevenuePct = @CurrMonthRevPct
									WHERE   JCCo = @Company
											AND Contract = @Contract
											AND ForecastMonth = @CurrMonth
					

									--TODO: Deduct current actuals from Projection totals for future month spread.
									
									SELECT  --@RemainingContractCost = @RemainingContractCost - @CurrMonthCostAmount ,
											@RemainingContractRevenue = @RemainingContractRevenue - @CurrMonthRevAmount,
											@RemainingMonths=@RemainingMonths-1
								END			
						END
					ELSE
					BEGIN

						--HERE --TODO:  Change TO post numbers from Projections 
						--SELECT * FROM JCCD WHERE JCCo=@Company AND 
						SELECT 
							@CurrMonthCostAmount=SUM(jcpd.Amount) 
						FROM 
							JCPR jcpd JOIN
							JCCP jccp ON
								jcpd.JCCo=jccp.JCCo
							AND jcpd.Job=jccp.Job
							AND jccp.Mth=jcpd.Mth 
							AND jccp.PhaseGroup=jcpd.PhaseGroup
							AND jccp.Phase=jcpd.Phase 
							AND jccp.CostType=jcpd.CostType	
							JOIN
							JCJM jcjm ON
								jcjm.JCCo=jccp.JCCo
							AND jcjm.Job=jccp.Job 	
						WHERE 
							jccp.JCCo=@Company
						AND jcjm.Contract=@Contract
						AND jcpd.DetMth=@CurrMonth						
									
						SELECT  @CurrMonthCostPct = @CurrMonthCostPct +
						CASE
						  WHEN @CurrContractCostEstimate = 0 THEN 0.00
						  ELSE CAST((@CurrMonthCostAmount/@CurrContractCostEstimate) AS NUMERIC(10,6))
						END
	                    
						SELECT  @CurrMonthRevPct = @CurrMonthRevPct +
						CASE
						  WHEN @CurrContractRevenue = 0 THEN 0.00
						  ELSE CAST((@RemainingContractRevenue/(@RemainingMonths+1))/@CurrContractRevenue AS NUMERIC(10,6))
						END
						--SELECT  @CurrMonthRevPct = 1
						
						UPDATE  dbo.JCForecastMonth
									SET     CostPct = COALESCE(@CurrMonthCostPct,0) ,
											RevenuePct = COALESCE(@CurrMonthRevPct,0)
									WHERE   JCCo = @Company
											AND Contract = @Contract
											AND ForecastMonth = @CurrMonth										
							
					END
			
					SELECT  @LoopCounter = @LoopCounter + 1
				END

				--SELECT
				--	@CurrMonthCostPct=1-SUM(CostPct) 
				--,	@CurrMonthRevPct=1-SUM(RevenuePct) 
				--FROM 
				--	dbo.JCForecastMonth
				--WHERE JCCo=@Company AND Contract=@Contract		
					
				--Update Last Entry to absorb "slush"
				--UPDATE dbo.JCForecastMonth
				--SET CostPct=CostPct+@CurrMonthCostPct,RevenuePct=RevenuePct+@CurrMonthRevPct
				--WHERE JCCo=@Company AND Contract=@Contract AND ForecastMonth=@CurrMonth
				
		END
	END
GO


--SELECT JCCo,Job,Contract FROM JCJM WHERE Job='080600-004'
EXEC mspRecalcJCCostForecast @Company = 101			--bCompany
--    , @Job = '080600-004'	--bJob
    , @Contract = '080600-'
    , @InitMonths = 'Y'			--bYN
    , @Debug = 1				--INT = 0
go
0.355924
--SELECT (SELECT 186123/522928.59) * 522928.59

--SELECT JCCo,Job,Contract FROM JCJM WHERE Contract='999037-'

--EXEC mspRecalcJCCostForecast 
--	@Company	=101			--bCompany
--,	@Job		='701198-001'	--bJob
--,	@InitMonths ='Y'			--bYN
--,	@Debug		=1				--INT = 0

----SELECT Contract FROM JCJM WHERE Job=''
----SELECT Contract FROM JCJM WHERE Job=''
----SELECT JCCo,Job,Contract FROM JCJM WHERE Contract=' 17284-'

--EXEC mspRecalcJCCostForecast 
--	@Company	=201			--bCompany
--,	@Job		=' 17284-001'	--bJob
--,	@InitMonths ='Y'			--bYN
--,	@Debug		=1				--INT = 0
--go

--EXEC mspRecalcJCCostForecast 
--	@Company	=201			--bCompany
--,	@Job		='999055-001'	--bJob
--,	@InitMonths ='Y'			--bYN
--,	@Debug		=0				--INT = 0
--go
--EXEC mspRecalcJCCostForecast 
--	@Company	=201			--bCompany
--,	@Job		='999056-001'	--bJob
--,	@InitMonths ='Y'			--bYN
--,	@Debug		=0				--INT = 0
--go
--EXEC mspRecalcJCCostForecast 
--	@Company	=201			--bCompany
--,	@Job		='999056-002'	--bJob
--,	@InitMonths ='Y'			--bYN
--,	@Debug		=0				--INT = 0
--go
--EXEC mspRecalcJCCostForecast 
--	@Company	=201			--bCompany
--,	@Job		='999057-001'	--bJob
--,	@InitMonths ='Y'			--bYN
--,	@Debug		=0				--INT = 0
--go
