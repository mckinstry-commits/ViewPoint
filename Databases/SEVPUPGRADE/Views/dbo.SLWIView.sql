SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   view [dbo].[SLWIView]
/***************************************
*	Created by:		DC 12/14/06
*	Modified by:	DC 02/05/07 - Added APTD.Amount to the recordset
*					GG 03/15/07 - added SLItem to join clause to eliminate duplicates
*					GF 05/15/2012 TK-14927 ISSUE #146439
*
*
* Used by:		SL WorkSheet Form
*
* Returns
*	SLWI.SMRetAmt
*	SLWI.WCRetAmt
*	SLWI.SLCo
*	SLWI.UserName
*	SLWI.SL
*	SLWI.SLItem
*	Sum(APTD.Amount) as RetainageTotal

****************************************/
AS

SELECT isnull(i.SMRetAmt,0) + isnull(i.WCRetAmt,0) as ItemRetainage,
		i.SLCo, 
		i.UserName, 
		i.SL, 
		i.SLItem,
		'Amount' = isnull(Amount,0)
FROM dbo.bSLWI i with (nolock)
/*AP Held Retainage Total */
		LEFT JOIN (select d.APCo as SLCo, 
				l.SL,
				l.SLItem,
				----TK-14927
				Amount = CASE h.DefaultCountry WHEN 'US'
						 THEN ISNULL(SUM(d.Amount),0)
					ELSE
						CASE c.TaxBasisNetRetgYN WHEN 'Y'
						THEN ISNULL(SUM(d.Amount),0) - ISNULL(SUM(d.GSTtaxAmt),0)
						ELSE isnull(sum(d.Amount),0)
						END
					END
					
		FROM dbo.bAPTD d with (nolock)
		JOIN dbo.bAPTL l with (nolock) on d.APCo = l.APCo and d.Mth = l.Mth and d.APTrans = l.APTrans and d.APLine = l.APLine
		JOIN dbo.bAPCO c with (nolock) on c.APCo = d.APCo
		JOIN dbo.bHQCO h ON h.HQCo = d.APCo
		where d.Status = 2
					AND ((d.PayCategory is null and d.PayType = c.RetPayType)
					OR (d.PayCategory is not NULL
					AND d.PayType=(select p.RetPayType from bAPPC p WITH (NOLOCK)
   									where p.APCo=c.APCo and p.PayCategory=d.PayCategory)))
					Group By d.APCo, l.SL, l.SLItem, c.TaxBasisNetRetgYN, h.DefaultCountry)
		ap on ap.SLCo = i.SLCo and ap.SL = i.SL and i.SLItem = ap.SLItem
		----TK-14927





GO
GRANT SELECT ON  [dbo].[SLWIView] TO [public]
GRANT INSERT ON  [dbo].[SLWIView] TO [public]
GRANT DELETE ON  [dbo].[SLWIView] TO [public]
GRANT UPDATE ON  [dbo].[SLWIView] TO [public]
GO
