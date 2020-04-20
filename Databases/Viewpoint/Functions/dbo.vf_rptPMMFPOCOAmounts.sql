SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- ==========================================================================================
-- Author:	HH
-- Create date: 04/07/2011
-- Description:	TK-05764 Modificated vfPMMFPOCOAmounts which only considers interfaced records. 
-- Used in vrvPMPOCOTotal, vrvPMVendorRegister in PM Vendor Register Drilldown report.
-- Modified By:	
--
--<Description,,>
-- ==========================================================================================
CREATE FUNCTION [dbo].[vf_rptPMMFPOCOAmounts]
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
		)
		
AS
BEGIN

	DECLARE @PMMFPriorAmt AS NUMERIC(18,2),
			@PMMFPriorTaxAmt AS NUMERIC(18,2),
			@PMMFPendAmt AS NUMERIC(18,2),
			@PMMFPendTaxAmt AS NUMERIC(18,2),
			@PMMFCurrentAmt AS NUMERIC(18,2),
			@PMMFCurrentTaxAmt AS NUMERIC(18,2)
			
			
	SET @PMMFPriorAmt = 0
	SET @PMMFPriorTaxAmt = 0
	SET @PMMFPendAmt = 0
	SET @PMMFPendTaxAmt = 0
	SET @PMMFCurrentAmt = 0
	SET @PMMFCurrentTaxAmt = 0
	
	
	---- PM PREVIOUS AUTHORIZED CHANGE AMOUNTS
	SELECT  @PMMFPriorAmt    = @PMMFPriorAmt + ISNULL(SUM(d.Amount), 0),
			@PMMFPriorTaxAmt = @PMMFPriorTaxAmt +
				CASE WHEN d.TaxCode IS NULL THEN 0
					 WHEN d.TaxType = 2 THEN 0
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
					 WHEN d.TaxType = 2 THEN 0
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
		  AND d.POCONum < @POCONum
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
					 WHEN d.TaxType = 2 THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
				END
	FROM dbo.bPMMF d
	WHERE d.SendFlag = 'Y'
		  AND d.POCo = @POCo
		  AND d.PO = @PO
		  AND d.POItem IS NOT NULL
		  AND d.POCONum = @POCONum
		  AND d.MaterialOption = 'P'
		  AND d.InterfaceDate IS NULL
		  
	 GROUP BY d.POCo,
			  d.PO,
			  d.POCONum,
			  d.TaxGroup,
			  d.TaxCode,
			  d.TaxType




	---- INSERT INTO TABLE VARIABLE TO BE RETURNED TO CALLING ROUTINE
	INSERT INTO @PMMFPOCONumAmts
		(
			PMMFPrevApprAmt, PMMFPrevApprTaxAmt, PMMFPendingAmt, PMMFPendingTaxAmt, PMMFCurrentAmt, PMMFCurrentTaxAmt
		)
	VALUES
		(
			ISNULL(@PMMFPriorAmt,0) + ISNULL(@PMMFPriorTaxAmt,0),
			ISNULL(@PMMFPriorTaxAmt,0),
			ISNULL(@PMMFPendAmt,0) + ISNULL(@PMMFPendTaxAmt,0),
			ISNULL(@PMMFPendTaxAmt,0),
			ISNULL(@PMMFCurrentAmt,0) + ISNULL(@PMMFCurrentTaxAmt,0),
			ISNULL(@PMMFCurrentTaxAmt,0)
		)

	
	RETURN
END





GO
GRANT SELECT ON  [dbo].[vf_rptPMMFPOCOAmounts] TO [public]
GO
