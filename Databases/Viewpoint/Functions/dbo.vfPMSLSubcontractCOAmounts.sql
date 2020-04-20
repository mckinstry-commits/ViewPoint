SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:	GF
-- Create date: 03/16/2011
-- Description:	TK-02607 TK-04281
--				GF 11/23/2011 TK-10291 exclude VAT tax type
--				GPT/NH 09/06/12 TK-17499 Collect the PMSL Original Amount.
--
--<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[vfPMSLSubcontractCOAmounts]
(
		@SLCo INT = null,
		@SL VARCHAR(30) = NULL,
		@SubCO INT = null
)

RETURNS	@PMSLSubCOAmts TABLE
		(
			PMSLPrevApprAmt		NUMERIC(18,2),
			PMSLPrevApprTaxAmt	NUMERIC(18,2),
			PMSLPendingAmt		NUMERIC(18,2),
			PMSLPendingTaxAmt	NUMERIC(18,2),
			PMSLCurrentAmt		NUMERIC(18,2),
			PMSLCurrentTaxAmt	NUMERIC(18,2),
			PMSLOriginalAmt		NUMERIC(18,2)
		)
		
AS
BEGIN

	DECLARE @PMSLPriorAmt AS NUMERIC(18,2),
			@PMSLPriorTaxAmt AS NUMERIC(18,2),
			@PMSLPendAmt AS NUMERIC(18,2),
			@PMSLPendTaxAmt AS NUMERIC(18,2),
			@PMSLCurrentAmt AS NUMERIC(18,2),
			@PMSLCurrentTaxAmt AS NUMERIC(18,2),
			@PMSLOriginalAmt AS NUMERIC(18,2)
			
			
	SET @PMSLPriorAmt = 0
	SET @PMSLPriorTaxAmt = 0
	SET @PMSLPendAmt = 0
	SET @PMSLPendTaxAmt = 0
	SET @PMSLCurrentAmt = 0
	SET @PMSLCurrentTaxAmt = 0
	SET @PMSLOriginalAmt = 0
	
	---- PM PM Original Amounts not yet interfaced
	SELECT  @PMSLOriginalAmt = @PMSLOriginalAmt + ISNULL(SUM(d.Amount), 0)
	FROM dbo.bPMSL d
	WHERE d.SendFlag = 'Y'
		  AND d.SLCo = @SLCo
		  AND d.SL = @SL
		  AND d.SLItem IS NOT NULL
		  AND d.SubCO is Null
		  AND d.SLItemType <> 3
		  AND d.InterfaceDate IS NULL
		  
	 GROUP BY d.SLCo,
			  d.SL,
			  d.SubCO
	
	---- PM PREVIOUS AUTHORIZED CHANGE AMOUNTS
	SELECT  @PMSLPriorAmt    = @PMSLPriorAmt + ISNULL(SUM(d.Amount), 0),
			@PMSLPriorTaxAmt = @PMSLPriorTaxAmt +
				CASE WHEN d.TaxCode IS NULL  THEN 0
				----TK-10291
					 WHEN d.TaxType IN (2,3) THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
				END
	FROM dbo.bPMSL d
	INNER JOIN dbo.vPMSubcontractCO c ON c.SLCo=d.SLCo AND c.SL=d.SL AND c.SubCO=d.SubCO
	LEFT JOIN dbo.bPMSC sc ON sc.Status=c.Status
	WHERE d.SendFlag = 'Y'
		  AND d.SLCo=@SLCo
		  AND d.SL=@SL
		  AND d.SLItem IS NOT NULL
		  AND d.SubCO IS NOT NULL
		  AND d.SubCO < @SubCO
		  AND d.SLItemType <> 3
		  AND d.InterfaceDate IS NULL
		  ---- MUST BE APPROVED (ACO ASSIGEND) OR STATUS IS FINAL AND Ready for Accounting is 'Y')
		  AND (d.ACO IS NOT NULL OR
			  (c.Status IS NOT NULL
				AND c.ReadyForAcctg = 'Y'
				AND sc.CodeType = 'F'))
				
	GROUP BY d.SLCo,
			 d.SL,
			 d.TaxGroup,
			 d.TaxCode,
			 d.TaxType

		
	---- PM PRIOR PENDING CHANGE AMOUNTS
	SELECT	@PMSLPendAmt    = @PMSLPendAmt + ISNULL(SUM(d.Amount), 0),
			@PMSLPendTaxAmt = @PMSLPendTaxAmt + 
				CASE WHEN d.TaxCode IS NULL THEN 0
					 ----TK-10291
					 WHEN d.TaxType IN (2,3) THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
				END
	FROM dbo.bPMSL d
	INNER JOIN dbo.vPMSubcontractCO c ON c.SLCo=d.SLCo AND c.SL=d.SL AND c.SubCO=d.SubCO
	LEFT JOIN dbo.bPMSC sc WITH ( NOLOCK ) ON sc.Status=c.Status
	WHERE d.SendFlag = 'Y'
		  AND d.SLCo = @SLCo
		  AND d.SL = @SL
		  AND d.SLItem IS NOT NULL
		  AND d.SubCO IS NOT NULL
		  AND d.SubCO < @SubCO
		  AND d.SLItemType <> 3
		  AND d.InterfaceDate IS NULL
		  ---- MUST NOT BE APPROVED (ACO NOT ASSIGEND) AND STATUS IS NOT FINAL
		  AND ((d.ACO IS NOT NULL AND (c.ReadyForAcctg = 'N' OR ISNULL(sc.CodeType,'B') <> 'F'))
		  OR
			  (d.ACO is NULL AND (c.ReadyForAcctg = 'N' OR ISNULL(sc.CodeType,'B') <> 'F')))
		  
	 GROUP BY d.SLCo,
			  d.SL,
			  d.TaxGroup,
			  d.TaxCode,
			  d.TaxType


	---- PM CURRENT SUBCONTRACT CHANGE AMOUNTS
	SELECT  @PMSLCurrentAmt = @PMSLCurrentAmt + ISNULL(SUM(d.Amount), 0),
			@PMSLCurrentTaxAmt = @PMSLCurrentTaxAmt + 
				CASE WHEN d.TaxCode IS NULL THEN 0
					 ----TK-10291
					 WHEN d.TaxType IN (2,3) THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
				END
	FROM dbo.bPMSL d
	WHERE d.SendFlag = 'Y'
		  AND d.SLCo = @SLCo
		  AND d.SL = @SL
		  AND d.SLItem IS NOT NULL
		  AND d.SubCO = @SubCO
		  AND d.SLItemType <> 3
		  
	 GROUP BY d.SLCo,
			  d.SL,
			  d.SubCO,
			  d.TaxGroup,
			  d.TaxCode,
			  d.TaxType




	---- INSERT INTO TABLE VARIABLE TO BE RETURNED TO CALLING ROUTINE
	INSERT INTO @PMSLSubCOAmts
		(
			PMSLPrevApprAmt, PMSLPrevApprTaxAmt, PMSLPendingAmt, PMSLPendingTaxAmt, PMSLCurrentAmt, PMSLCurrentTaxAmt, PMSLOriginalAmt
		)
	VALUES
		(
			ISNULL(@PMSLPriorAmt,0) + ISNULL(@PMSLPriorTaxAmt,0),
			ISNULL(@PMSLPriorTaxAmt,0),
			ISNULL(@PMSLPendAmt,0) + ISNULL(@PMSLPendTaxAmt,0),
			ISNULL(@PMSLPendTaxAmt,0),
			ISNULL(@PMSLCurrentAmt,0) + ISNULL(@PMSLCurrentTaxAmt,0),
			ISNULL(@PMSLCurrentTaxAmt,0),
			ISNULL(@PMSLOriginalAmt,0)
		)

	
	RETURN
END



GO
GRANT SELECT ON  [dbo].[vfPMSLSubcontractCOAmounts] TO [public]
GO
