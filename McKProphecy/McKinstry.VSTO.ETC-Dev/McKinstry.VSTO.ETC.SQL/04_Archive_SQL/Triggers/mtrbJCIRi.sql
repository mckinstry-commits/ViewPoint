USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mtrbJCIRi]    Script Date: 5/12/2016 3:39:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ========================================================================
-- INSERT TRIGGER on bJCIR
-- Author:		Ziebell, Jonathan
-- Create date: 05/06/2016
-- Description:	When Conract is added to Batch, add any matching detail rows from budJCIPD for current month.  
-- If not found, add max prior month.  If not exists, spread total projected cost over duration.
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================

CREATE TRIGGER [dbo].[mtrbJCIRi] on [dbo].[bJCIR] 
FOR INSERT
AS
	DECLARE   @errmsg varchar(255)
			, @numrows int
			, @opencursor tinyint
			, @JCCo bCompany
			, @Contract bContract
			, @Month bMonth
			, @StartDate bDate
			, @CloseDate bDate
			, @Duration int
			, @Item bContractItem
			, @ProjDollars bDollar
			, @ProjUnits bUnits
			, @batch_seq int
			, @batchid bBatchID
			, @counter int
			   
    SELECT @numrows = @@rowcount
    if @numrows = 0 return
    SET nocount on
		
	SET @counter = 0 
	SET @opencursor = 0
    
    -- Process Inserted Rows as Simple Select if only 1 row
    IF @numrows = 1
    	SELECT 	  @JCCo = i.Co
				, @Month = i.Mth
				, @Contract = i.Contract
				, @Item = i.Item
				, @batch_seq = i.BatchSeq
				, @batchid = i.BatchId
    	FROM inserted i  
    ELSE
    	BEGIN
    	-- Use a cursor to process each inserted row in sequence
    	DECLARE bJCID_insert cursor LOCAL FAST_FORWARD
    		FOR SELECT Co, Mth, Contract, Item, BatchSeq, BatchId
    			FROM inserted 
       	OPEN bJCID_insert
    	SET @opencursor = 1
    	
    	FETCH bJCID_insert INTO @JCCo, @Month, @Contract, @Item, @batch_seq, @batchid
    	
    	IF @@fetch_status <> 0
    		BEGIN
    			SELECT @errmsg = 'Cursor error'
    			GOTO Error
    		END
    	END

BEGIN    
budJCIRD_Insert:
--INSERT INTO budJCIRD
-- Check for Revenue Project Details Rows on budJCIPD, If rows on budJCIPD rows are found, insert them into budJCIRD
	IF EXISTS (SELECT 1 FROM budJCIPD y 
					WHERE y.Co = @JCCo 
					AND y.Mth = @Month 
					AND y.Contract = @Contract 
					AND y.Item = @Item)
		BEGIN
			SET IDENTITY_INSERT budJCIRD ON
			INSERT INTO budJCIRD ( Co, BatchId, BatchSeq, Contract, FromDate, Item, Mth, ProjDollars, ProjUnits, ToDate, UniqueAttchID, KeyID)
						SELECT	s.Co
							,   @batchid
							,   @batch_seq
							,	s.Contract
							,	s.FromDate
							,	s.Item
							,	s.Mth
							,	s.ProjDollars
							,	s.ProjUnits
							,   s.ToDate
							,	s.UniqueAttchID
							,	s.KeyID
						FROM budJCIPD s
						WHERE s.Co = @JCCo
							AND s.Contract = @Contract 
							AND s.Item = @Item
							AND s.Mth = @Month 
			SET IDENTITY_INSERT budJCIRD OFF
		END
	ELSE
	--If Current Month Projection isnt found, check for prior month projections
		IF EXISTS (SELECT 1 FROM budJCIPD y
					WHERE y.Co = @JCCo 
					AND y.Contract = @Contract 
					AND y.Item = @Item
					AND y.Mth < @Month)
		BEGIN
			SET IDENTITY_INSERT budJCIRD ON
			INSERT INTO budJCIRD ( Co, BatchId, BatchSeq, Contract, FromDate, Item, Mth, ProjDollars, ProjUnits, ToDate, UniqueAttchID, KeyID)
						SELECT	s.Co
							,   @batchid
							,   @batch_seq
							,	s.Contract
							,	s.FromDate
							,	s.Item
							,	@Month
							,	s.ProjDollars
							,	s.ProjUnits
							,   s.ToDate
							,	s.UniqueAttchID
							,	s.KeyID
						FROM budJCIPD s
						WHERE s.Co = @JCCo  
								AND s.Contract = @Contract 
								AND s.Item = @Item
								AND s.Mth = (SELECT MAX(s2.Mth) FROM budJCIPD s2
												WHERE s2.Co = s.Co 
												AND s2.Contract = s.Contract 
												AND s2.Item = s.Item
												AND s2.Mth < @Month)
			SET IDENTITY_INSERT budJCIRD OFF
		END
	ELSE
	IF NOT EXISTS (select 1 FROM budJCIPD y 
											WHERE y.Co = @JCCo
											AND y.Contract = @Contract 
											AND y.Item = @Item
											AND y.Mth <= @Month)
		BEGIN			
			SELECT @StartDate = case when CM.StartDate is null then @Month else CM.StartDate end 
				, @CloseDate = case when CM.ProjCloseDate is null then @Month else CM.ProjCloseDate end 
				, @Duration = ((datediff(month
							,(case when CM.StartDate is null then @Month else CM.StartDate end)
							,(case when CM.ProjCloseDate is null then @Month else CM.ProjCloseDate end)))+1)
				, @ProjDollars = coalesce(sum(IP.ProjDollars), CM.ContractAmt)
				, @ProjUnits = coalesce(sum(IP.ProjUnits),0)
			FROM JCCM CM
				INNER JOIN JCCI CI 
					ON CM.JCCo = CI.JCCo
					AND CM.Contract = CI.Contract 
					AND CI.Item = @Item
				INNER JOIN JCIP IP 
					ON CI.JCCo = IP.JCCo
					AND CI.Contract = IP.Contract
					AND CI.Item = IP.Item
					AND IP.Mth <= @Month
			WHERE CM.JCCo = @JCCo
				AND CM.Contract = @Contract
			GROUP BY
				  CM.JCCo
				, CM.Contract
				, CM.StartDate
				, CM.ProjCloseDate
				, CI.Item
				, CM.ContractAmt
				
		SELECT @StartDate = CAST(cast(MONTH(@StartDate) as varchar(2)) + '/1/' + cast(YEAR(@StartDate) as varchar(4)) as datetime)
		SELECT @counter = 0

		WHILE @counter <  @Duration
			BEGIN
				--SET IDENTITY_INSERT budJCIRD ON
				INSERT INTO budJCIRD (Co, BatchId, BatchSeq, Contract, FromDate, Item, Mth,ProjDollars,ProjUnits,ToDate)
					SELECT	 
							  @JCCo
							, @batchid
							, @batch_seq
							, @Contract
							, dateadd(month,@counter,@StartDate)
							, @Item
							, @Month
							, @ProjDollars/@Duration
							, @ProjUnits/@Duration
							, dateadd(day, -1, dateadd(month,@counter+1,@StartDate))

				SELECT @counter = @counter +1
			END
			--SET IDENTITY_INSERT budJCIRD OFF
		END

	IF @numrows > 1
    	BEGIN

    	FETCH bJCID_insert INTO @JCCo, @Month, @Contract, @Item, @batch_seq, @batchid
     	IF @@fetch_status = 0
     		GOTO budJCIRD_Insert
     	ELSE
     		BEGIN
     		CLOSE bJCID_insert
     		DEALLOCATE bJCID_insert
    		SET @opencursor = 0
     		END
     	END

END

RETURN

Error:
    	IF @opencursor = 1
     		BEGIN
     		close bJCID_insert
     		deallocate bJCID_delete
    		set @opencursor = 0
			RETURN
     		END
    