SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPHoldRelReleaseHoldCodes]
/***********************************************************
* CREATED: MV 02/22/10 - #136500 - releases transaction holdcode for APHoldRel
* MODIFIED:	MV 05/25/10 - #136500 - limit GST tax update to trans detail not already updated
*			MV 11/1/11 - TK-09243 - multilevel tax codes net of retention - recalc holdback/ret PST
*			MV 11/17/11 - TK-09243 - fixed where clause for update statements. 
*
* USAGE:
* Releases all transaction detail in APHoldRel grid, updates APTD GST tax amount first
* on retainage detail checked for update
*  INPUT PARAMETERS
*   @apco	AP company number
*	@userid user login
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************/
	(@apco bCompany = 0,@userid bVPUserName, @msg varchar(200) output)
          
as
set nocount on

declare @retpaytype tinyint, @TaxRate bRate, @GSTRate bRate, @PSTRate bRate

-- Get default retainage pay type
select @retpaytype=RetPayType from APCO where APCo=@apco                    


-- Update Retainage APTD GSTtaxAmount, PSTTaxAmount and TotTaxAmount with new tax rate if APHOldRel flag 'ApplyNewTaxRateYN' = Y                                                                                                                                          
UPDATE dbo.bAPTD SET OldGSTtaxAmt=d.GSTtaxAmt, OldPSTtaxAmt=d.PSTtaxAmt,
	 GSTtaxAmt = ((d.Amount - d.TotTaxAmount) * t.TaxRate),
	 PSTtaxAmt = ((d.Amount - d.TotTaxAmount) * t.PSTRate),
	 TotTaxAmount = ((d.Amount - d.TotTaxAmount) * t.TaxRate) + ((d.Amount - d.TotTaxAmount) * t.PSTRate)
from dbo.bAPTD d
LEFT JOIN dbo.APHR r on d.APCo=r.APCo and d.Mth=r.Mth and d.APTrans=r.APTrans and d.APLine=r.APLine and d.APSeq=r.APSeq   
JOIN dbo.bAPTL l on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine 
CROSS APPLY (SELECT TaxRate,PSTRate FROM dbo.vfHQTaxRatesForPSTGST(l.TaxGroup, l.TaxCode)) t 
WHERE d.APCo=@apco and r.UserId=@userid and r.ApplyNewTaxRateYN = 'Y'
	--AND	(d.GSTtaxAmt <> 0 and d.OldGSTtaxAmt = 0) OR (d.PSTtaxAmt <> 0 and d.OldPSTtaxAmt = 0)
	AND	(
			(
				d.PayCategory IS NULL AND d.PayType=@retpaytype
			) 
			OR 
			(
				d.PayCategory IS NOT NULL AND d.PayType = (select RetPayType from bAPPC with (nolock) where APCo=@apco and PayCategory=d.PayCategory)
			)
		)
-- Now update Retainage APTD with new Amount
UPDATE dbo.bAPTD SET Amount = ((d.Amount - (d.OldGSTtaxAmt + d.OldPSTtaxAmt)) + (d.GSTtaxAmt + d.PSTtaxAmt))
FROM dbo.bAPTD d
JOIN dbo.APHR r on d.APCo=r.APCo and d.Mth=r.Mth and d.APTrans=r.APTrans and d.APLine=r.APLine and d.APSeq=r.APSeq  
JOIN dbo.APTL l on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine 
WHERE d.APCo=@apco and r.UserId=@userid and r.ApplyNewTaxRateYN = 'Y'
	--AND	((d.GSTtaxAmt <> 0 and d.OldGSTtaxAmt <> 0) OR (d.PSTtaxAmt <> 0 and d.OldPSTtaxAmt <> 0))
	AND	(
			(
				d.PayCategory IS NULL AND d.PayType=@retpaytype
			) 
			OR 
			(
				d.PayCategory IS NOT NULL AND d.PayType = (select RetPayType from dbo.bAPPC with (nolock) where APCo=@apco and PayCategory=d.PayCategory)
			)
		)
-- Delete holdcodes in bAPHD from transactions in APHoldRel grid (bAPHR)
Delete APHD
from APHD d 
join APHR r on r.APCo=d.APCo and r.Mth=d.Mth and r.APTrans=d.APTrans 
	and r.APLine=d.APLine and r.APSeq=d.APSeq and r.HoldCode=d.HoldCode
where r.APCo=@apco and r.UserId=@userid
select @msg = convert( varchar(20),@@rowcount) + ' transactions released.'

-- Clear bAPHR 
delete from APHR 
where not exists(select * from APHD d join APHR r on r.APCo=d.APCo and r.Mth=d.Mth and r.APTrans=d.APTrans 
	and r.APLine=d.APLine and r.APSeq=d.APSeq and r.HoldCode=d.HoldCode)


                     

      


GO
GRANT EXECUTE ON  [dbo].[vspAPHoldRelReleaseHoldCodes] TO [public]
GO
