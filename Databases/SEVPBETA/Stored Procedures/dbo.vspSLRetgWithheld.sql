SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.vspSLRetgWithheld    Script Date: 8/28/99 9:36:38 AM ******/
CREATE proc [dbo].[vspSLRetgWithheld]      
/***********************************************************
* CREATED BY: DC	2/10/10
* MODIFIED By : GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*				GF 05/15/2012 TK-14927 ISSUE #146439
*
*
*
* USAGE:
* Called from SL procedures to return the amount of retainage
*		already withheld for a subcontract
*
*
*  INPUT PARAMETERS
*	@slco		Current SL Co#
*	@sl		Subcontract to add
*
* OUTPUT PARAMETERS
*		@maxretgamt maximum amount of retainage that can be withheld on the subcontract
*   	@msg     	error message if error occurs
*
* RETURN VALUE
*   	0         	success
*   	1         	failure
*****************************************************/   
(@slco bCompany, @sl VARCHAR(30), @retgamtwithheld bDollar output, @msg varchar(200) output)
AS
SET NOCOUNT ON

DECLARE @rcode int, @paycategory int, @APretpaytype tinyint, @retpaytype tinyint,
		@retgamtwithheldAPTD bDollar, @retgamtwithheldAPLB bDollar,
		@retgamtwithheldAPUL bDollar
		----TK-14927
		,@DefaultCountry CHAR(2)
		,@TaxBasisNetRetgYN bYN

SELECT @rcode = 0, @retgamtwithheld = 0, @retgamtwithheldAPTD = 0, 
		@retgamtwithheldAPLB = 0, @retgamtwithheldAPUL = 0
	
---- get AP company info
----TK-14927
SELECT @APretpaytype = a.RetPayType
		,@TaxBasisNetRetgYN = a.TaxBasisNetRetgYN
		,@DefaultCountry = h.DefaultCountry
FROM dbo.bAPCO a
JOIN dbo.bHQCO h ON h.HQCo = a.APCo
WHERE a.APCo = @slco

---- get pay category from APTL
SELECT @paycategory = PayCategory 
FROM dbo.bAPTL with (nolock)
WHERE APCo = @slco and SL = @sl

---- get pay category info
IF @paycategory is not null
	BEGIN
	SELECT @retpaytype=RetPayType 
	FROM dbo.bAPPC with (nolock)
	WHERE APCo=@slco and PayCategory=@paycategory
	END
ELSE
	BEGIN
	SELECT @retpaytype=@APretpaytype
	END
	    		
----Retainage total from posted AP Invoices
----TK-14927		
SELECT @retgamtwithheldAPTD = 
		CASE @DefaultCountry WHEN 'US'
				 THEN ISNULL(SUM(d.Amount),0)
			ELSE
				CASE @TaxBasisNetRetgYN WHEN 'Y'
				THEN ISNULL(SUM(d.Amount),0) - ISNULL(SUM(d.GSTtaxAmt),0)
				ELSE isnull(sum(d.Amount),0)
				END
			END
			----sum(isnull(d.Amount,0)) OLD
FROM dbo.bAPTD d
JOIN dbo.bAPTL l on l.APCo = d.APCo and l.Mth = d.Mth and l.APTrans = d.APTrans and d.APLine = l.APLine
JOIN dbo.bSLIT s on s.SLCo = d.APCo and l.SL = s.SL and s.WCRetPct <> 0 and l.SLItem = s.SLItem
WHERE l.APCo = @slco
	AND l.SL = @sl 
	AND d.PayType = @retpaytype
	AND NOT EXISTS(select 1 from dbo.bAPLB b WHERE b.Co = @slco and b.SL = @sl)
	
--Retainage amount from Open AP Transaction Batches
SELECT @retgamtwithheldAPLB = sum(isnull(b.Retainage,0))
FROM dbo.bAPLB b
JOIN dbo.bSLIT s on s.SLCo = b.Co and b.SL = s.SL and s.WCRetPct <> 0 and b.SLItem = s.SLItem
WHERE b.Co = @slco
	AND b.SL = @sl

--Get retainage amounts from AP Unapproved Invoices
SELECT @retgamtwithheldAPUL = sum(isnull(l.Retainage,0))
FROM dbo.bAPUL l
JOIN dbo.SLIT s on s.SLCo = l.APCo and l.SL = s.SL and s.WCRetPct <> 0 and l.SLItem = s.SLItem
WHERE l.APCo = @slco and l.SL = @sl 

----set retainage amount withheld
SELECT @retgamtwithheld = isnull(@retgamtwithheldAPTD, 0)
				+ isnull(@retgamtwithheldAPLB,0)
				+ isnull(@retgamtwithheldAPUL,0)
	
	
	
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLRetgWithheld] TO [public]
GO
