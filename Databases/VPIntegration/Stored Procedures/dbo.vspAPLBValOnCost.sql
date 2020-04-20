SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   CREATE procedure [dbo].[vspAPLBValOnCost]
   /*********************************************
    * Created: MV	01/25/12	TK-11875 AP On-Cost Processing
    * Modified: 
    *
    * Usage:
    *  Called from the AP Transaction Batch validation procedure (bspAPLBVal)
    *  to check for the existence of bAPLB, bAPTL, bAPUL On-Cost records associated with this line.
    *
    * Input:
    *  @APCo       EM Co#
    *  @Mth         Work Order
    *  @Trans     Work Order Item
    *  @Line      Equipment
    *
    * Output:
    *  @errmsg     Error message
    *
    * Return:
    *  0           success
    *  1           error
    *************************************************/
   
	(@APCo bCompany,
		@Mth bMonth,
		@Trans bTrans,
		@Line Int,
		@Msg VARCHAR(255) OUTPUT)
   
	AS
   
	SET NOCOUNT ON
  
	DECLARE	@Rcode tinyint,
			@OnCostStatus tinyint,
			@OnCostMth bMonth,
			@OnCostTrans int,
			@OnCostLine int,
			@OnCostBatchId int
			
	SELECT @Rcode = 0
  
	IF @APCo IS NULL
	BEGIN
		SELECT @Msg = 'Missing APCo!', @Rcode=1
		RETURN
	END
	
	IF @Mth IS NULL
	BEGIN
		SELECT @Msg = 'Missing Exp Month!', @Rcode=1
		RETURN
	END
	
	IF @Trans IS NULL
	BEGIN
		SELECT @Msg = 'Missing Trans #!', @Rcode=1
		RETURN
	END
	
	IF @Line IS NULL
	BEGIN
		SELECT @Msg = 'Missing Line #!', @Rcode=1
		RETURN
	END
	
	-- If OnCostStatus is greater than 0 check for OnCost invoices.
	IF EXISTS
		(
			SELECT *
			FROM dbo.bAPTL
			WHERE APCo=@APCo 
			AND Mth=@Mth 
			AND APTrans=@Trans 
			AND APLine=@Line
			AND ISNULL(OnCostStatus,0)>0
		)
	BEGIN
		-- check APLB batches
		SELECT @OnCostMth=Mth,@OnCostBatchId=BatchId
		FROM dbo.bAPLB
		WHERE Co=@APCo 
		AND ocApplyMth=@Mth 
		AND ocApplyTrans=@Trans 
		AND ocApplyLine=@Line
		IF @@ROWCOUNT > 0 
		BEGIN
			SELECT @Msg = 'Line is in On-Cost batch month: ' + CONVERT(VARCHAR(12),@OnCostMth,1)
				+ ' batchid: ' + CONVERT(VARCHAR(10),@OnCostBatchId)
			SELECT @Rcode=1
			RETURN @Rcode	
		END 
		
		-- check APTL
		SELECT @OnCostMth=Mth,@OnCostTrans=APTrans,@OnCostLine=APLine 
		FROM dbo.bAPTL
		WHERE APCo=@APCo 
		AND ocApplyMth=@Mth 
		AND ocApplyTrans=@Trans 
		AND ocApplyLine=@Line
		IF @@ROWCOUNT > 0 
		BEGIN
			SELECT @Msg = 'Line is in On-Cost Transaction Month: ' + CONVERT(VARCHAR(12),@OnCostMth, 1)
				+ ' APTrans: ' + CONVERT(VARCHAR(10),@OnCostTrans)
				+ ' APLine: ' + CONVERT(VARCHAR(10),@OnCostLine)
			SELECT @Rcode=1
			RETURN @Rcode
		END 	
		
		-- APUL
		--SELECT @OnCostMth=UIMth,@OnCostTrans=UISeq,@OnCostLine=Line 
		--FROM dbo.bAPUL
		--WHERE APCo=@APCo 
		--AND ocApplyMth=@Mth 
		--AND ocApplyTrans=@Trans 
		--AND ocApplyLine=@Line
		--IF @@ROWCOUNT > 0 
		--BEGIN
		--	SELECT @Msg = 'Line is in On-Cost Unapproved Month: ' + CONVERT(VARCHAR(12),@OnCostMth, 1)
		--		+ ' UISeq: ' + CONVERT(VARCHAR(10),@OnCostTrans)
		--		+ ' Line: ' + CONVERT(VARCHAR(10),@OnCostLine)
		--	SELECT @Rcode=1
		--	RETURN	
		--END 	
		
	END	
	
GO
GRANT EXECUTE ON  [dbo].[vspAPLBValOnCost] TO [public]
GO
