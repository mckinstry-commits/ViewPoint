SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*=============================================
* Author:	GF 05/11/2011 TK-00000
* Modified By:	GF 11/23/2011 TK-10291 exclude VAT Tax type from totals
*				GF 05/15/2012 TK-14929 issue #146439 item type in (1,2)
*				AW 10/11/2012 TK-18480 Remove CO's from Org Total
*
*
* USAGE:
* Provides a function to return totals and the calculated maximum retainage amount
* for PM SL Header and other PM Forms (including SL document).
* Built into view PMSLTotal
*
* calculated maximum retainage amount based upon:
*
*	SLHD Percent of Contract setup value.
*	SLHD exclude Variations from Max Retainage by % value.
*	SLIT Non-Zero Retainage Percent items
*
* Business logic for the maximum retainage amount within PM.
* 1. Get sum of PMSL detail amounts for original where interface date is null
*	 and item type equals 1 and item WCRetgPct <> 0 and Item Send Flag equals 'Y'
* 2. Get sum of PMSL detail amounts for original where interface date is null
*	 and item type equals 2 and item WCRetgPct <> 0 and Item Send Flag equals 'Y'
* 3. Get sum of SLIT current costs and original costs where item type = '1' and
*	 item WCRetgPct <> 0.
*
* Maximum Retainage amount equals:
*  1. When SL Include change orders = 'Y' then SL maximum retainage % times
*	  SLIT current cost + SLIT original cost + PMSL Original cost + PMSL Change order cost.
*  2. When SL Include change orders = 'Y' then SL maximum retainage % times
*	  SLIT original cost + PMSL Original cost
*
*
* INPUT PARAMETERS
* @SLCo				SL Company
* @sl				Subcontract
*
*
* OUTPUT PARAMETERS
* table variable with PM SL Current Amount, Current Tax Amount, and maximum retainage by percentage
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
-- =============================================*/
CREATE FUNCTION [dbo].[vfPMSLHeaderAmounts]
(
		@SLCo INT = null,
		@SL VARCHAR(30) = NULL
)

RETURNS	@PMSLHeaderAmts TABLE
		(
			PMSLAmt				NUMERIC(18,2),
			PMSLTaxAmt			NUMERIC(18,2),
			PMSLAmtOrig			NUMERIC(18,2),
			PMSLTaxOrig			NUMERIC(18,2),
			MaxRetgByPct		NUMERIC(18,2)
		)
		
AS
BEGIN

	DECLARE @PMSLAmt		AS NUMERIC(18,2),
			@PMSLTaxAmt		AS NUMERIC(18,2),
			@PMSLAmtOrig	AS NUMERIC(18,2),
			@PMSLTaxOrig	AS NUMERIC(18,2),
			@PMMaxRetgByPct AS NUMERIC(18,2),
			@SLMaxRetgByPct AS NUMERIC(18,2)


	SET @PMSLAmt = 0
	SET @PMSLTaxAmt = 0
	SET @PMSLAmtOrig = 0
	SET @PMSLTaxOrig = 0
	SET @PMMaxRetgByPct = 0
	SET @SLMaxRetgByPct = 0

	---- PM SUBCONTRACT AMOUNTS IF EXISTS
	IF EXISTS(SELECT 1 FROM dbo.bPMSL s WHERE s.SLCo=@SLCo AND s.SL=@SL)
		BEGIN
	SELECT  @PMSLAmt = @PMSLAmt + ISNULL(SUM(d.Amount), 0),
			@PMSLAmtOrig = @PMSLAmtOrig + 
					CASE WHEN d.SLItemType IN (2,3) THEN 0
						 WHEN d.SubCO IS NOT NULL THEN 0
						 ELSE ISNULL(SUM(d.Amount),0)
						 END,
						 ----TK-10291
			@PMSLTaxAmt = @PMSLTaxAmt + 
					CASE WHEN d.TaxCode IS NULL  THEN 0
						 WHEN d.TaxType IN (2,3) THEN 0
					ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
					END,
			@PMSLTaxOrig = @PMSLTaxOrig + 
					CASE WHEN d.TaxCode IS NULL		THEN 0
						 WHEN d.TaxType IN (2,3)	THEN 0
						 WHEN d.SLItemType IN (2,3) THEN 0
					ELSE ISNULL(ROUND(ISNULL(SUM(d.Amount), 0) * ISNULL(dbo.vfHQTaxRate(d.TaxGroup, d.TaxCode, GetDate()),0),2),0)
					END
	FROM dbo.bPMSL d
	WHERE d.SendFlag = 'Y'
		  AND d.SLCo = @SLCo
		  AND d.InterfaceDate IS NULL
		  AND d.SL = @SL
		  AND d.SLItem IS NOT NULL
		  AND d.SLItemType <> 3
		  AND ((d.RecordType='O' and d.ACO is null)
		  OR   (d.RecordType='C' and (d.ACO is not null or d.PCO is not null)))
		  
	 GROUP BY d.SLCo,
			  d.SL,
			  d.SubCO,
			  d.TaxGroup,
			  d.TaxCode,
			  d.TaxType,
			  d.SLItemType
	END
	
	---- maximum retention is based on the SLHD.MaxRetgOpt <> 'N' otherwise zero
	IF EXISTS(SELECT 1 FROM dbo.bSLHD h WHERE h.SLCo=@SLCo AND h.SL=@SL AND h.MaxRetgOpt <> 'N')
		BEGIN
		---- sum of all subcontract items from PMSL - not interfaced and not change orders
		SELECT @PMMaxRetgByPct = h.MaxRetgPct * ISNULL(SUM(i.Amount),0)
		FROM dbo.bPMSL i
		JOIN dbo.bSLHD h ON h.SLCo=i.SLCo AND h.SL=i.SL
		WHERE i.SLCo=@SLCo AND i.SL=@SL AND i.InterfaceDate IS NULL
		AND i.SLItemType = 1 AND i.WCRetgPct <> 0 AND i.SendFlag = 'Y' ----AND i.RecordType = 'O' AND h.InclACOinMaxYN = 'N' 
		GROUP BY i.SLCo, i.SL, i.InterfaceDate, h.MaxRetgPct

		---- sum of all subcontract items from PMSL - not interfaced change order item types only
		SELECT @PMMaxRetgByPct = @PMMaxRetgByPct + h.MaxRetgPct * ISNULL(SUM(i.Amount),0)
		FROM dbo.bPMSL i
		JOIN dbo.bSLHD h ON h.SLCo=i.SLCo AND h.SL=i.SL
		WHERE i.SLCo=@SLCo AND i.SL=@SL AND i.InterfaceDate IS NULL
		AND i.SLItemType = 2 AND i.WCRetgPct <> 0 AND i.SendFlag = 'Y' AND h.InclACOinMaxYN = 'Y' 
		GROUP BY i.SLCo, i.SL, i.InterfaceDate, h.MaxRetgPct

		---- sum of all subcontract items from SLIT
		SELECT @SLMaxRetgByPct =
				CASE WHEN h.InclACOinMaxYN = 'Y' then (h.MaxRetgPct * ISNULL(sum(t.CurCost), 0))
					 ELSE (h.MaxRetgPct * sum(isnull(t.OrigCost, 0)))
					 END
		FROM dbo.bSLHD h
		LEFT JOIN dbo.bSLIT t ON h.SLCo = t.SLCo and h.SL = t.SL 
		WHERE h.SLCo = @SLCo AND h.SL = @SL AND t.WCRetPct <> 0
		----TK-14929
		AND t.ItemType IN (1,2)
		GROUP BY h.SLCo, h.SL, h.MaxRetgPct, h.InclACOinMaxYN
		END
			  
	---- INSERT INTO TABLE VARIABLE TO BE RETURNED TO CALLING ROUTINE
	INSERT INTO @PMSLHeaderAmts
		(
			PMSLAmt, PMSLTaxAmt,PMSLAmtOrig, PMSLTaxOrig, MaxRetgByPct
		)
	VALUES
		(	ISNULL(@PMSLAmt,0)			+ ISNULL(@PMSLTaxAmt,0),
			ISNULL(@PMSLTaxAmt,0),
			ISNULL(@PMSLAmtOrig,0)		+ ISNULL(@PMSLTaxOrig,0),
			ISNULL(@PMSLTaxOrig,0),
			ISNULL(@PMMaxRetgByPct,0)	+ ISNULL(@SLMaxRetgByPct,0)
		)

	
	RETURN
END





GO
GRANT SELECT ON  [dbo].[vfPMSLHeaderAmounts] TO [public]
GO
