SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE	PROC [dbo].[vspAPCreditServiceExport]
/************************************
* Created:	04/11/12 - CHS
* Modified: 04/17/12 - CHS
*
* This SP is called from form AP Credit Service Export to return CS info.
* Any changes here will require changes to the form.
*
***********************************/
(@apco bCompany, @month bMonth, @batchid bBatchID)

	AS
	SET NOCOUNT ON

	DECLARE @rcode int
	SELECT @rcode = 0
	
	DECLARE @PaymentID varchar(50), @FileDate smalldatetime, @PaymentDate smalldatetime
	
	SELECT @FileDate = GETDATE()

	SELECT 

		t.BatchSeq, a.Vendor, p.APCreditService, p.CSCMAcct, p.CDAcctCode, p.CDCustID, p. CDCodeWord, 
		p.TCCo, p.TCAcct, a.Amount, a.Vendor, a.Name, a.CMRef, 'FileDate' = @FileDate, h.DueDate,
		t.APRef, t.InvDate, 'Gross' = ABS(t.Gross), v.CSEmail, a.PaidDate, 'NetAmt' = ABS(totals.NetAmt), 'DiscTaken' = ABS(t.DiscTaken),
		'GrossAmountSign' = (CASE WHEN t.Gross < 0 THEN '-' ELSE '+' END),
		'NetAmountSign' = (CASE WHEN totals.NetAmt < 0 THEN '-' ELSE '+' END),
		'DiscountAmountSign' = (CASE WHEN t.DiscTaken < 0 THEN '-' ELSE '+' END),
		'NetTotalPaymentAmt' = (SELECT SUM(b.Gross)-SUM(b.DiscTaken) 
									FROM bAPTB b 
									WHERE a.Co = b.Co 
										AND a.Mth = b.Mth 
										AND a.BatchId = b.BatchId 
										AND a.BatchSeq = b.BatchSeq)
		
	FROM bAPPB a with (nolock) 
		JOIN bAPTB t with (nolock) ON a.Co = t.Co AND a.Mth = t.Mth AND a.BatchId = t.BatchId AND a.BatchSeq = t.BatchSeq
		JOIN bAPTH h with (nolock) ON t.Co = h.APCo AND t.ExpMth = h.Mth AND t.APTrans = h.APTrans AND a.VendorGroup = h.VendorGroup and a.Vendor = h.Vendor
		JOIN bAPCO p with (nolock) ON a.Co = p.APCo
		JOIN bAPVM v with (nolock) ON v.VendorGroup = a.VendorGroup and v.Vendor = a.Vendor
		JOIN APTransTotals totals ON totals.Co = t.Co AND
										totals.Mth = t.Mth AND
										totals.BatchId = t.BatchId AND
										totals.BatchSeq = t.BatchSeq AND
										totals.ExpMth = t.ExpMth AND
										totals.APTrans = t.APTrans 
	WHERE 
		a.Co = @apco 
			AND a.Mth = @month 
			AND a.BatchId = @batchid 
			AND a.PayMethod = 'S' 
	ORDER BY t.BatchSeq

	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspAPCreditServiceExport] TO [public]
GO
