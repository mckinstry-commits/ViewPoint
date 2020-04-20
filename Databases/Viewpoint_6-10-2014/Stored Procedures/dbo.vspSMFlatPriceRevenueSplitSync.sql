SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMFlatPriceRevenueSplitSync]
/***********************************************************************
*	Created by: 	EricV  
*	Created Date:	5/2/2013
*	Purpose:		Automatically redistribute the amounts of a Flat Price split when the Flat Price changes.				
* 
*	Modified:		Matthew B
*	Date:			5/9/2013
*	Purpose:		Function
*							
* 
***********************************************************************/
	@SMCo bCompany,
	@EntitySeq int, 
	@FlatPrice bDollar,
	@UpdateSplitAmounts bit,
	@NoSplitsExists bit OUTPUT,
	@SplitAmountTotal bDollar OUTPUT
AS  
BEGIN
	IF NOT EXISTS
	(
		SELECT 1 
		FROM 
			vSMFlatPriceRevenueSplit
		INNER JOIN 
			vSMEntity 
		ON 
			vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND 
			vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq
		WHERE 
			vSMEntity.SMCo = @SMCo AND
			vSMEntity.EntitySeq = @EntitySeq
	)
	BEGIN
		SET @NoSplitsExists = 1
		RETURN 0
	END

	SELECT 
		@SplitAmountTotal = SUM(Amount) 
	FROM 
		vSMFlatPriceRevenueSplit	
	WHERE
		vSMFlatPriceRevenueSplit.SMCo = @SMCo AND
		vSMFlatPriceRevenueSplit.EntitySeq = @EntitySeq

	-- Update any missing PricePercent amounts.
	UPDATE 
		vSMFlatPriceRevenueSplit 
	SET 
		PricePercent = 
	CASE 
		WHEN @SplitAmountTotal = 0 
		THEN PricePercent 
		ELSE (Amount/@SplitAmountTotal) 
	END
	WHERE 
		SMCo = @SMCo AND 
		EntitySeq = @EntitySeq AND 
		PricePercent IS NULL

	IF @FlatPrice IS NOT NULL AND @UpdateSplitAmounts = 1
	BEGIN
		UPDATE 
			vSMFlatPriceRevenueSplit 
		SET 
			Amount = 
				CASE 
					WHEN @SplitAmountTotal = 0 
					THEN 0 
					ELSE (Amount/@SplitAmountTotal) * @FlatPrice 
				END, 
			PricePercent = 
				CASE 
					WHEN @SplitAmountTotal = 0 
					THEN PricePercent 
					ELSE (Amount/@SplitAmountTotal) 
				END
		WHERE 
			SMCo = @SMCo AND 
			EntitySeq = @EntitySeq
	END

	SELECT 
		@SplitAmountTotal = SUM(Amount) 
	FROM 
		vSMFlatPriceRevenueSplit
	INNER JOIN 
		vSMEntity 
	ON 
		vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND 
		vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq
	WHERE 
		vSMEntity.SMCo = @SMCo AND
		vSMEntity.EntitySeq = @EntitySeq
	
	IF @SplitAmountTotal <> @FlatPrice AND @UpdateSplitAmounts = 1
	BEGIN
		UPDATE 
			vSMFlatPriceRevenueSplit 
		SET 
			Amount = Amount - (@SplitAmountTotal - @FlatPrice)
		WHERE 
			SMFlatPriceRevenueSplitID = 
			(
				SELECT 
					TOP 1 SMFlatPriceRevenueSplitID 
				FROM
					vSMFlatPriceRevenueSplit
				WHERE 
					SMCo = @SMCo AND 
					EntitySeq = @EntitySeq
			)
	END
	
	RETURN 0
END		
	
	
GO
GRANT EXECUTE ON  [dbo].[vspSMFlatPriceRevenueSplitSync] TO [public]
GO
