SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*****************************************/
CREATE function [dbo].[vfPMSLItemMaxRetgAmt] (@SLCO int = null, @SL varchar(30) = null)
returns numeric(20,2)
/***********************************************************
* CREATED BY:	GF 09/24/2010 - Issue #129892 Maximum Retainage Enhancement
* MODIFIED By:	GF 05/15/2012 TK-14929 issue #146439 item type in (1,2)
*
*
*
* USAGE:
* Provides a view for SL Subcontract Entry form that returns the calculated
* maximum retainage amount based upon:
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
* @slco				SL Company
* @sl				Subcontract
*
*
* OUTPUT PARAMETERS
* maximum retainage by percentage
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/
as
BEGIN

DECLARE @PMMaxRetgByPct AS NUMERIC(20,2), @SLMaxRetgByPct AS NUMERIC(20,2)

SET @PMMaxRetgByPct = 0
SET @SLMaxRetgByPct = 0

---- sum of all subcontract items from PMSL - not interfaced and not change orders
SELECT @PMMaxRetgByPct = h.MaxRetgPct * ISNULL(SUM(i.Amount),0)
FROM dbo.bPMSL i
JOIN dbo.bSLHD h ON h.SLCo=i.SLCo AND h.SL=i.SL
WHERE i.SLCo=@SLCO AND i.SL=@SL AND i.InterfaceDate IS NULL
AND i.SLItemType = 1 AND i.WCRetgPct <> 0 AND i.SendFlag = 'Y' ----AND i.RecordType = 'O' AND h.InclACOinMaxYN = 'N' 
GROUP BY i.SLCo, i.SL, i.InterfaceDate, h.MaxRetgPct

---- sum of all subcontract items from PMSL - not interfaced change order item types only
SELECT @PMMaxRetgByPct = @PMMaxRetgByPct + h.MaxRetgPct * ISNULL(SUM(i.Amount),0)
FROM dbo.bPMSL i
JOIN dbo.bSLHD h ON h.SLCo=i.SLCo AND h.SL=i.SL
WHERE i.SLCo=@SLCO AND i.SL=@SL AND i.InterfaceDate IS NULL
AND i.SLItemType = 2 AND i.WCRetgPct <> 0 AND i.SendFlag = 'Y' AND h.InclACOinMaxYN = 'Y' 
GROUP BY i.SLCo, i.SL, i.InterfaceDate, h.MaxRetgPct

---- sum of all subcontract items from SLIT
SELECT @SLMaxRetgByPct =
		CASE WHEN h.InclACOinMaxYN = 'Y' then (h.MaxRetgPct * ISNULL(sum(t.CurCost), 0))
			 ELSE (h.MaxRetgPct * sum(isnull(t.OrigCost, 0)))
			 END
FROM dbo.bSLHD h
LEFT JOIN dbo.bSLIT t ON h.SLCo = t.SLCo and h.SL = t.SL 
WHERE h.SLCo = @SLCO AND h.SL = @SL AND t.WCRetPct <> 0
----TK-14929
AND t.ItemType IN (1,2)
GROUP BY h.SLCo, h.SL, h.MaxRetgPct, h.InclACOinMaxYN



RETURN ISNULL(@PMMaxRetgByPct,0) + ISNULL(@SLMaxRetgByPct,0)

END



GO
GRANT EXECUTE ON  [dbo].[vfPMSLItemMaxRetgAmt] TO [public]
GO
