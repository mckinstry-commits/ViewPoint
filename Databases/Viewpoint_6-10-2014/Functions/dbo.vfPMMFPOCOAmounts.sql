SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:	TRL
-- Create date: 04/07/2011
-- Description:	TK-03970
-- Modified By:	GF 04/15/2011 TK-04281
--				JG 07/15/2011 TK-06766 - Changed the PendingAmt area from d.POCONum < @POCONum to d.POCONum <> @POCONum
--				GF 11/23/2011 TK-10291 exclude VAT tax type
--				GF 04/09/2012 TK-13886 #145504 get PMMF original amount and tax for inclusion on totals
--<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[vfPMMFPOCOAmounts]
(
		@POCo INT = null,
		@PO VARCHAR(30) = NULL,
		@POCONum INT = null
)

RETURNS	@PMMFPOCONumAmts TABLE
		(
			PMMFPrevApprAmt		NUMERIC(18,2),
			PMMFPrevApprTaxAmt	NUMERIC(18,2),
			PMMFPendingAmt		NUMERIC(18,2),
			PMMFPendingTaxAmt	NUMERIC(18,2),
			PMMFCurrentAmt		NUMERIC(18,2),
			PMMFCurrentTaxAmt	NUMERIC(18,2)
			----TK-13886
			,PMMFOriginalAmt	NUMERIC(18,2)
			,PMMFOriginalTaxAmt	NUMERIC(18,2)
		)
		
AS
BEGIN

	DECLARE @PMMFPriorAmt AS NUMERIC(18,2),
			@PMMFPriorTaxAmt AS NUMERIC(18,2),
			@PMMFPendAmt AS NUMERIC(18,2),
			@PMMFPendTaxAmt AS NUMERIC(18,2),
			@PMMFCurrentAmt AS NUMERIC(18,2),
			@PMMFCurrentTaxAmt AS NUMERIC(18,2)
			----TK-13886
			,@PMMFOriginalAmt AS NUMERIC(18,2)
			,@PMMFOriginalTaxAmt AS NUMERIC(18,2)
			
			
	SET @PMMFPriorAmt = 0
	SET @PMMFPriorTaxAmt = 0
	SET @PMMFPendAmt = 0
	SET @PMMFPendTaxAmt = 0
	SET @PMMFCurrentAmt = 0
	SET @PMMFCurrentTaxAmt = 0
	----TK-13886
	SET @PMMFOriginalAmt = 0
	SET @PMMFOriginalTaxAmt = 0
	
	
	---- TK-13886 PM Original Amounts not yet interfaced
	SELECT  @PMMFOriginalAmt	= @PMMFOriginalAmt + ISNULL(SUM(d.Amount), 0),
			@PMMFOriginalTaxAmt = @PMMFOriginalTaxAmt +
			CASE WHEN d.TaxCode IS NULL THEN 0
				 WHEN d.TaxType IN (2,3) THEN 0
			ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
			END
	FROM dbo.bPMMF d
	WHERE d.SendFlag = 'Y'
		  AND d.POCo=@POCo
		  AND d.PO=@PO
		  AND d.POItem IS NOT NULL
		  AND d.POCONum IS NULL
		  AND d.MaterialOption = 'P'
		  AND d.InterfaceDate IS NULL

	GROUP BY d.POCo,
			 d.PO,
			 d.TaxGroup,
			 d.TaxCode,
			 d.TaxType
		  
		  
	---- PM PREVIOUS AUTHORIZED CHANGE AMOUNTS
	SELECT  @PMMFPriorAmt    = @PMMFPriorAmt + ISNULL(SUM(d.Amount), 0),
			@PMMFPriorTaxAmt = @PMMFPriorTaxAmt +
				CASE WHEN d.TaxCode IS NULL THEN 0
					 ----TK-10291
					 WHEN d.TaxType IN (2,3) THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
				END
	FROM dbo.bPMMF d
	INNER JOIN dbo.vPMPOCO c ON c.POCo=d.POCo AND c.PO=d.PO AND c.POCONum=d.POCONum
	LEFT JOIN dbo.bPMSC sc ON sc.Status=c.Status
	WHERE d.SendFlag = 'Y'
		  AND d.POCo=@POCo
		  AND d.PO=@PO
		  AND d.POItem IS NOT NULL
		  AND d.POCONum IS NOT NULL
		  AND d.POCONum < @POCONum
		  AND d.MaterialOption = 'P'
		  AND d.InterfaceDate IS NULL
		  ---- MUST BE APPROVED (ACO ASSIGEND) OR STATUS IS FINAL AND Ready for Accounting is 'Y')
		  AND (d.ACO IS NOT NULL OR
			  (c.Status IS NOT NULL
				AND c.ReadyForAcctg = 'Y'
				AND sc.CodeType = 'F'))
				
	GROUP BY d.POCo,
			 d.PO,
			 d.TaxGroup,
			 d.TaxCode,
			 d.TaxType

		
	---- PM PRIOR PENDING CHANGE AMOUNTS
	SELECT	@PMMFPendAmt    = @PMMFPendAmt + ISNULL(SUM(d.Amount), 0),
			@PMMFPendTaxAmt = @PMMFPendTaxAmt + 
				CASE WHEN d.TaxCode IS NULL THEN 0
					 ----TK-10291
					 WHEN d.TaxType IN (2,3) THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
				END
	FROM dbo.bPMMF d
	INNER JOIN dbo.vPMPOCO c ON c.POCo=d.POCo AND c.PO=d.PO AND c.POCONum=d.POCONum
	LEFT JOIN dbo.bPMSC sc WITH ( NOLOCK ) ON sc.Status=c.Status
	WHERE d.SendFlag = 'Y'
		  AND d.POCo = @POCo
		  AND d.PO = @PO
		  AND d.POItem IS NOT NULL
		  AND d.POCONum IS NOT NULL
		  AND d.POCONum <> @POCONum  ----TK-06766
		  AND d.MaterialOption = 'P'
		  AND d.InterfaceDate IS NULL
		  ---- MUST NOT BE APPROVED (ACO NOT ASSIGEND) AND STATUS IS NOT FINAL
		  AND ((d.ACO IS NOT NULL AND (c.ReadyForAcctg = 'N' OR ISNULL(sc.CodeType,'B') <> 'F'))
		  OR
			  (d.ACO is NULL AND (c.ReadyForAcctg = 'N' OR ISNULL(sc.CodeType,'B') <> 'F')))
		  
	 GROUP BY d.POCo,
			  d.PO,
			  d.TaxGroup,
			  d.TaxCode,
			  d.TaxType


	---- PM CURRENT PO CHANGE AMOUNTS
	SELECT  @PMMFCurrentAmt = @PMMFCurrentAmt + ISNULL(SUM(d.Amount), 0),
			@PMMFCurrentTaxAmt = @PMMFCurrentTaxAmt + 
				CASE WHEN d.TaxCode IS NULL THEN 0
					 ----TK-10291
					 WHEN d.TaxType IN (2,3) THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
				END
	FROM dbo.bPMMF d
	WHERE d.SendFlag = 'Y'
		  AND d.POCo = @POCo
		  AND d.PO = @PO
		  AND d.POItem IS NOT NULL
		  AND d.POCONum = @POCONum
		  AND d.MaterialOption = 'P'
		  
	 GROUP BY d.POCo,
			  d.PO,
			  d.POCONum,
			  d.TaxGroup,
			  d.TaxCode,
			  d.TaxType




	---- INSERT INTO TABLE VARIABLE TO BE RETURNED TO CALLING ROUTINE
	INSERT INTO @PMMFPOCONumAmts
		(
			PMMFPrevApprAmt, PMMFPrevApprTaxAmt, PMMFPendingAmt, PMMFPendingTaxAmt, PMMFCurrentAmt,
			PMMFCurrentTaxAmt, PMMFOriginalAmt, PMMFOriginalTaxAmt
		)
	VALUES
		(
			ISNULL(@PMMFPriorAmt,0) + ISNULL(@PMMFPriorTaxAmt,0),
			ISNULL(@PMMFPriorTaxAmt,0),
			ISNULL(@PMMFPendAmt,0) + ISNULL(@PMMFPendTaxAmt,0),
			ISNULL(@PMMFPendTaxAmt,0),
			ISNULL(@PMMFCurrentAmt,0) + ISNULL(@PMMFCurrentTaxAmt,0),
			ISNULL(@PMMFCurrentTaxAmt,0)
			----TK-13886
			,ISNULL(@PMMFOriginalAmt,0)
			,ISNULL(@PMMFOriginalTaxAmt,0)
		)

	
	RETURN
END





GO
GRANT SELECT ON  [dbo].[vfPMMFPOCOAmounts] TO [public]
GO
