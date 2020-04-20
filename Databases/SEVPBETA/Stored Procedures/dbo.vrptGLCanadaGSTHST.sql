SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vrptGLCanadaGSTHST]
(
	@GLCo			bCompany,
	@BeginningMonth	bMonth		= '01/01/1950',
	@EndingMonth	bMonth		= '12/01/2050'
)

AS

/**************************************************************************************

Author:			Czeslaw
Date Created:	07/31/2012
Reports:		GL GST/HST Drilldown (GLCanadaGSTHST.rpt)

Purpose:		Returns sales (AR) and purchase (AP) transaction details, including 
				tax information, to support completion of GST/HST returns for periodic 
				filing with the Canada Revenue Agency.

Revision History      
Date	Author	Issue	Description

**************************************************************************************/

SET NOCOUNT ON

/* Create temp table to hold values for final selection */

CREATE TABLE dbo.#TempTableGSTHST
(
	[Source]				char(2),
	[GLCo]					tinyint,		--bCompany
	[CompanyName]			varchar(60),
	[ARCo]					tinyint,		--bCompany
	[APCo]					tinyint,		--bCompany
	[ARApplyMth]			smalldatetime,	--bMonth
	[ARApplyTrans]			int,			--bTrans
	[Invoice]				varchar(20),
	[ARCustGroup]			tinyint,		--bGroup
	[ARCustomer]			int,			--bCustomer
	[ARCustName]			varchar(60),
	[APVendorGroup]			tinyint,		--bGroup
	[APVendor]				int,			--bVendor
	[APVendorName]			varchar(60),
	[Mth]					smalldatetime,	--bMonth
	[Trans]					int,			--bTrans
	[Line]					smallint,
	[APSeq]					tinyint,
	[ARTransType]			char(1),
	[APPayType]				tinyint,
	[APPayTypeDescription]	varchar(30),	--bDesc
	[APPayCategory]			int,
	[APSeqIsRetgPayType]	char(1),
	[TaxGroup]				tinyint,		--bGroup
	[TaxCode]				varchar(10),	--bTaxCode
	[ARTaxCodeIsVAT]		char(1),		--bYN
	[ARTaxCodeIsGST]		char(1),		--bYN
	[ARTaxCodeIsMultiLevel]	char(1),		--bYN
	[InvoiceDate]			smalldatetime,	--bDate
	[APStatus]				varchar(8),
	[APPaidMth]				smalldatetime,	--bMonth
	[Amount]				numeric(12,2),	--bDollar
	[Holdback]				numeric(12,2),	--bDollar
	[Tax]					numeric(12,2),	--bDollar
	[HoldbackTax]			numeric(12,2),	--bDollar
	[APInvTaxAddend]		numeric(12,2),	--bDollar
	[APGSTtaxAmt]			numeric(12,2),	--bDollar
	[AmtLine101]			numeric(12,2),	--bDollar
	[AmtLine103]			numeric(12,2),	--bDollar
	[AmtLine106]			numeric(12,2),	--bDollar
	[AmtLine107]			numeric(12,2)	--bDollar
)


/* Insert initial AR rows (primarily from ARTL) into temp table  */

INSERT INTO dbo.#TempTableGSTHST 
(
	[Source],
	[GLCo],
	[CompanyName],
	[ARCo],
	[APCo],
	[ARApplyMth],
	[ARApplyTrans],
	[Invoice],
	[ARCustGroup],
	[ARCustomer],
	[ARCustName],
	[APVendorGroup],
	[APVendor],
	[APVendorName],
	[Mth],
	[Trans],
	[Line],
	[APSeq],
	[ARTransType],
	[APPayType],
	[APPayTypeDescription],
	[APPayCategory],
	[APSeqIsRetgPayType],
	[TaxGroup],
	[TaxCode],
	[ARTaxCodeIsVAT],
	[ARTaxCodeIsGST],
	[ARTaxCodeIsMultiLevel],
	[InvoiceDate],
	[APStatus],
	[APPaidMth],
	[Amount],
	[Holdback],
	[Tax],
	[HoldbackTax],
	[APInvTaxAddend],
	[APGSTtaxAmt],
	[AmtLine101],
	[AmtLine103],
	[AmtLine106],
	[AmtLine107]
)
SELECT 
	'Source'				= 'AR',
	'GLCo'					= ARCO.GLCo,
	'CompanyName'			= HQCO.Name,
	'ARCo'					= ARTL.ARCo,
	'APCo'					= NULL,  --AP only
	'ARApplyMth'			= ARTL.ApplyMth,
	'ARApplyTrans'			= ARTL.ApplyTrans,
	'Invoice'				= ARTHorig.Invoice,
	'ARCustGroup'			= ARTHorig.CustGroup,
	'ARCustomer'			= ARTHorig.Customer,
	'ARCustName'			= ARCM.Name,
	'APVendorGroup'			= NULL,  --AP only
	'APVendor'				= NULL,  --AP only
	'APVendorName'			= NULL,  --AP only
	'Mth'					= ARTL.Mth,
	'Trans'					= ARTL.ARTrans,
	'Line'					= ARTL.ARLine,
	'APSeq'					= NULL,  --AP only
	'ARTransType'			= ARTHappl.ARTransType,
	'APPayType'				= NULL,  --AP only
	'APPayTypeDescription'	= NULL,  --AP only
	'APPayCategory'			= NULL,  --AP only
	'APSeqIsRetgPayType'	= NULL,  --AP only
	'TaxGroup'				= ARTL.TaxGroup,
	'TaxCode'				= ARTL.TaxCode,
	'ARTaxCodeIsVAT'		= HQTX.ValueAdd,
	'ARTaxCodeIsGST'		= HQTX.GST,
	'ARTaxCodeIsMultiLevel'	= HQTX.MultiLevel,
	'InvoiceDate'			= ARTHappl.TransDate,
	'APStatus'				= NULL,  --AP only
	'APPaidMth'				= NULL,  --AP only
	'Amount'				= CASE  --reverse sign on amounts for miscellaneous cash receipts (ARTransType='M')
								WHEN ARTHappl.ARTransType <> 'M' THEN (ARTL.Amount - (ARTL.TaxAmount + ARTL.RetgTax))
								ELSE -(ARTL.Amount - (ARTL.TaxAmount + ARTL.RetgTax)) END,
	'Holdback'				= CASE
								WHEN ARTHappl.ARTransType <> 'M' THEN (ARTL.Retainage - ARTL.RetgTax)
								ELSE -(ARTL.Retainage - ARTL.RetgTax) END,
	'Tax'					= CASE
								WHEN ARTHappl.ARTransType <> 'M' THEN ARTL.TaxAmount
								ELSE -(ARTL.TaxAmount) END,
	'HoldbackTax'			= CASE
								WHEN ARTHappl.ARTransType <> 'M' THEN ARTL.RetgTax
								ELSE -(ARTL.RetgTax) END,
	'APInvTaxAddend'		= NULL,  --AP only
	'APGSTtaxAmt'			= NULL,  --AP only
	'AmtLine101'			= NULL,  --calculate in AR cursor
	'AmtLine103'			= NULL,  --calculate in AR cursor
	'AmtLine106'			= NULL,  --AP only
	'AmtLine107'			= NULL   --calculate in AR cursor
FROM dbo.ARTL ARTL  --lines for "applied" trans (ie, trans applied to original invoice trans)
JOIN dbo.ARTH ARTHappl ON ARTHappl.ARCo = ARTL.ARCo AND ARTHappl.Mth = ARTL.Mth AND ARTHappl.ARTrans = ARTL.ARTrans  --header for "applied" trans (ie, trans applied to original invoice trans)
JOIN dbo.ARTH ARTHorig ON ARTHorig.ARCo = ARTL.ARCo AND ARTHorig.Mth = ARTL.ApplyMth AND ARTHorig.ARTrans = ARTL.ApplyTrans  --header for "original" invoice trans
JOIN dbo.ARCO ARCO ON ARCO.ARCo = ARTL.ARCo
JOIN dbo.HQCO HQCO ON HQCO.HQCo = ARCO.GLCo
LEFT JOIN dbo.ARCM ARCM ON ARCM.CustGroup = ARTHorig.CustGroup AND ARCM.Customer = ARTHorig.Customer
LEFT JOIN dbo.HQTX HQTX ON HQTX.TaxGroup = ARTL.TaxGroup AND HQTX.TaxCode = ARTL.TaxCode
WHERE ARCO.GLCo = @GLCo
AND ARTL.Mth BETWEEN @BeginningMonth AND @EndingMonth
AND NOT ARTHappl.ARTransType = 'P'  --Exclude payments
--AND NOT (ARTHappl.ARTransType = 'R' AND NOT (ARTL.Mth = ARTL.ApplyMth AND ARTL.ARTrans = ARTL.ApplyTrans AND ARTL.ARLine = ARTL.ApplyLine))  --Exclude "R1" transactions


/* AR cursor: Update AR rows in temp table with calculated amounts for Line 101, Line 103, Line 107 */

/* GST amounts associated with credit memo (C) and write-off (W) transactions must be assigned conditionally to either Line 103 or Line 107.
If both the original invoice (I) transaction and the subsequent applied C or W transaction occurred within the current reporting period, then
the GST amount associated with the C or W transaction is assigned to Line 103 (and has a negative value), reducing the GST amount collectible.
If the original I transaction occurred prior to the current reporting period, then the GST amount associated with the C or W transaction is
assigned to Line 107 (and has a positive value), increasing the ITC amount that may be claimed (as if the GST amount for the bad debt that 
the user is unable to collect from the customer had been paid by the user to a vendor). */

DECLARE	@ARCo bCompany, @Mth bMonth, @Trans bTrans, @Line smallint
DECLARE @ARTransType char(1), @ARApplyMth bMonth, @TaxGroup bGroup, @TaxCode bTaxCode, @ARTaxCodeIsVAT bYN, @ARTaxCodeIsGST bYN, @ARTaxCodeIsMultiLevel bYN, @InvoiceDate bDate
DECLARE @Amount bDollar, @Holdback bDollar, @Tax bDollar

DECLARE @AmtLine101 bDollar, @AmtLine103 bDollar, @AmtLine107 bDollar, @AmtGSTAR bDollar
SELECT @AmtLine101 = 0, @AmtLine103 = 0, @AmtLine107 = 0, @AmtGSTAR = 0

DECLARE AmountsCursorAR CURSOR LOCAL FAST_FORWARD FOR
	SELECT ARCo, Mth, Trans, Line, ARTransType, ARApplyMth, TaxGroup, TaxCode, ARTaxCodeIsVAT, ARTaxCodeIsGST, ARTaxCodeIsMultiLevel, InvoiceDate, Amount, Holdback, Tax
	FROM dbo.#TempTableGSTHST
	WHERE [Source] = 'AR'

OPEN AmountsCursorAR
FETCH NEXT FROM AmountsCursorAR INTO @ARCo, @Mth, @Trans, @Line, @ARTransType, @ARApplyMth, @TaxGroup, @TaxCode, @ARTaxCodeIsVAT, @ARTaxCodeIsGST, @ARTaxCodeIsMultiLevel, @InvoiceDate,
	@Amount, @Holdback, @Tax

WHILE @@fetch_status = 0
	BEGIN
		
		/* Line 101: Sales amount */
		SELECT @AmtLine101 = @Amount - @Holdback
		
		/* Line 103, Line 107: GST amount */
		
		--Calculate GST portion of line tax amount (@Tax)		
		IF @TaxCode IS NOT NULL AND @ARTaxCodeIsVAT = 'Y'
			BEGIN
				IF @ARTaxCodeIsGST = 'Y'
					BEGIN
						SELECT @AmtGSTAR = @Tax
					END
				ELSE IF @ARTaxCodeIsMultiLevel = 'Y'
					BEGIN
						
						--Confirm that multi-level tax code (base) has GST tax code (comp) as single-level member, then calculate GST
						IF EXISTS
						(
							SELECT 1
							FROM dbo.HQTX HQTXbase
							JOIN dbo.HQTL HQTL ON HQTL.TaxGroup = HQTXbase.TaxGroup AND HQTL.TaxCode = HQTXbase.TaxCode
							JOIN dbo.HQTX HQTXcomp ON HQTXcomp.TaxGroup = HQTL.TaxGroup AND HQTXcomp.TaxCode = HQTL.TaxLink
							WHERE HQTXbase.TaxGroup = @TaxGroup AND HQTXbase.TaxCode = @TaxCode AND HQTXcomp.GST = 'Y'
						)
							BEGIN
							
								DECLARE @rcode tinyint, @taxrate bRate, @gstrate bRate, @pstrate bRate, @msg varchar(60)
								EXEC @rcode = bspHQTaxRateGetAll @TaxGroup, @TaxCode, @InvoiceDate, NULL, @taxrate OUTPUT, @gstrate OUTPUT, @pstrate OUTPUT,
									NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @msg OUTPUT
								
								IF @pstrate = 0
								/* Indicates that multi-level tax code has no non-GST single-level member, or all its non-GST single-level members have rates of 0.
								   In either case, @taxrate is identical to @gstrate, and consequently entire line tax amount (@Tax) should be assigned to GST. */
									BEGIN
										SELECT @AmtGSTAR = @Tax
									END
								ELSE
								/* Indicates that multi-level tax code has at least one non-GST single-level member whose rate is not 0. Consequently, we need
								   to calculate the portion of line tax amount (@Tax) that should be assigned to GST. */
									BEGIN
										IF @taxrate <> 0 
											BEGIN
												SELECT @AmtGSTAR = (@Tax * @gstrate) / @taxrate
											END
									END

							END

					END
			END

		--Assign GST to Line 103 or Line 107, reverse sign only if Line 107		
		IF @ARTransType NOT IN ('C','W')  --Includes transactions other than Credit Memo and Write-off; always assigned to Line 103
			BEGIN
				SELECT @AmtLine103 = @AmtGSTAR
			END
		ELSE  --Includes only Credit Memo and Write-off transactions; assigned to Line 103 only if original invoice posted within current reporting period
			BEGIN
				IF @ARApplyMth >= @BeginningMonth  --Original invoice posted after start of current reporting period
					BEGIN
						SELECT @AmtLine103 = @AmtGSTAR
					END
				ELSE  --Original invoice posted prior to start of current reporting period
					BEGIN
						SELECT @AmtLine107 = -(@AmtGSTAR)
					END
			END
		
		/* Update temp table with calculated amounts */
		UPDATE dbo.#TempTableGSTHST
		SET AmtLine101 = @AmtLine101, AmtLine103 = @AmtLine103, AmtLine107 = @AmtLine107
		WHERE [Source] = 'AR' AND ARCo = @ARCo AND Mth = @Mth AND Trans = @Trans AND Line = @Line
		
		/* Re-initialize variables */
		SELECT @ARTransType = NULL, @ARApplyMth = NULL, @TaxGroup = NULL, @TaxCode = NULL, @ARTaxCodeIsVAT = NULL, @ARTaxCodeIsGST = NULL, @ARTaxCodeIsMultiLevel = NULL, @InvoiceDate = NULL
		SELECT @Amount = 0, @Holdback = 0, @Tax = 0
		
		SELECT @AmtLine101 = 0, @AmtLine103 = 0, @AmtLine107 = 0, @AmtGSTAR = 0

		/* Retrieve next row from cursor */
		FETCH NEXT FROM AmountsCursorAR INTO @ARCo, @Mth, @Trans, @Line, @ARTransType, @ARApplyMth, @TaxGroup, @TaxCode, @ARTaxCodeIsVAT, @ARTaxCodeIsGST, @ARTaxCodeIsMultiLevel, @InvoiceDate,
			@Amount, @Holdback, @Tax

	END

CLOSE AmountsCursorAR
DEALLOCATE AmountsCursorAR


/* Insert initial AP rows (primarily from APTD) into temp table  */

INSERT INTO dbo.#TempTableGSTHST 
(
	[Source],
	[GLCo],
	[CompanyName],
	[ARCo],
	[APCo],
	[ARApplyMth],
	[ARApplyTrans],
	[Invoice],
	[ARCustGroup],
	[ARCustomer],
	[ARCustName],
	[APVendorGroup],
	[APVendor],
	[APVendorName],
	[Mth],
	[Trans],
	[Line],
	[APSeq],
	[ARTransType],
	[APPayType],
	[APPayTypeDescription],
	[APPayCategory],
	[APSeqIsRetgPayType],
	[TaxGroup],
	[TaxCode],
	[ARTaxCodeIsVAT],
	[ARTaxCodeIsGST],
	[ARTaxCodeIsMultiLevel],
	[InvoiceDate],
	[APStatus],
	[APPaidMth],
	[Amount],
	[Holdback],
	[Tax],
	[HoldbackTax],
	[APInvTaxAddend],
	[APGSTtaxAmt],
	[AmtLine101],
	[AmtLine103],
	[AmtLine106],
	[AmtLine107]
)
SELECT 
	'Source'				= 'AP',
	'GLCo'					= APCO.GLCo,
	'CompanyName'			= HQCO.Name,
	'ARCo'					= NULL,  --AR only
	'APCo'					= APTD.APCo,
	'ARApplyMth'			= NULL,  --AR only
	'ARApplyTrans'			= NULL,  --AR only
	'Invoice'				= APTH.APRef,
	'ARCustGroup'			= NULL,  --AR only
	'ARCustomer'			= NULL,  --AR only
	'ARCustName'			= NULL,  --AR only
	'APVendorGroup'			= APTH.VendorGroup,
	'APVendor'				= APTH.Vendor,
	'APVendorName'			= APVM.Name,
	'Mth'					= APTD.Mth,
	'Trans'					= APTD.APTrans,
	'Line'					= APTD.APLine,
	'APSeq'					= APTD.APSeq,
	'ARTransType'			= NULL,  --AR only
	'APPayType'				= APTD.PayType,
	'APPayTypeDescription'	= APPT.[Description],
	'APPayCategory'			= APTD.PayCategory,
	'APSeqIsRetgPayType'	= CASE
								WHEN APTD.PayCategory IS NULL THEN 
									CASE WHEN APTD.PayType = APCO.RetPayType THEN 'Y' ELSE 'N' END
								ELSE
									CASE WHEN APTD.PayType = APPC.RetPayType THEN 'Y' ELSE 'N' END
								END,
	'TaxGroup'				= APTL.TaxGroup,
	'TaxCode'				= APTL.TaxCode,
	'ARTaxCodeIsVAT'		= NULL,  --AR only
	'ARTaxCodeIsGST'		= NULL,  --AR only
	'ARTaxCodeIsMultiLevel'	= NULL,  --AR only
	'InvoiceDate'			= APTH.InvDate,
	'APStatus'				= CASE APTD.[Status]
								WHEN 1 THEN 'Open' WHEN 2 THEN 'Hold' WHEN 3 THEN 'Paid' WHEN 4 THEN 'Cleared' 
								ELSE 'None'
								END,
	'APPaidMth'				= APTD.PaidMth,
	'Amount'				= (APTD.Amount - ISNULL(APTD.TotTaxAmount,0)),
	'Holdback'				= NULL,  --calculate in AP cursor
	'Tax'					= ISNULL(APTD.TotTaxAmount,0),
	'HoldbackTax'			= NULL,  --calculate in AP cursor
	'APInvTaxAddend'		= NULL,  --calculate in AP cursor
	'APGSTtaxAmt'			= ISNULL(APTD.GSTtaxAmt,0),
	'AmtLine101'			= NULL,  --AR only
	'AmtLine103'			= NULL,  --AR only
	'AmtLine106'			= NULL,  --calculate in AP cursor
	'AmtLine107'			= NULL   --AR only
FROM dbo.APTD APTD
JOIN dbo.APTL APTL ON APTL.APCo = APTD.APCo AND APTL.Mth = APTD.Mth AND APTL.APTrans = APTD.APTrans AND APTL.APLine = APTD.APLine
JOIN dbo.APTH APTH ON APTH.APCo = APTD.APCo AND APTH.Mth = APTD.Mth AND APTH.APTrans = APTD.APTrans
JOIN dbo.APCO APCO ON APCO.APCo = APTD.APCo
JOIN dbo.HQCO HQCO ON HQCO.HQCo = APCO.GLCo
JOIN dbo.APPT APPT ON APPT.APCo = APTD.APCo AND APPT.PayType = APTD.PayType
JOIN dbo.APVM APVM ON APVM.VendorGroup = APTH.VendorGroup AND APVM.Vendor = APTH.Vendor
LEFT JOIN dbo.APPC APPC ON APPC.APCo = APTD.APCo AND APPC.PayCategory = APTD.PayCategory
WHERE APCO.GLCo = @GLCo
AND (
	--Include all rows whose expense month falls within reporting period, including retainage rows
	APTD.Mth BETWEEN @BeginningMonth AND @EndingMonth
	OR (
		--Include also retainage rows whose paid month falls within reporting period
		APTD.PaidMth BETWEEN @BeginningMonth AND @EndingMonth 
		AND (
			--Identify retainage row
			(APTD.PayCategory IS NULL AND APTD.PayType = APCO.RetPayType) OR (APTD.PayCategory IS NOT NULL AND APTD.PayType = APPC.RetPayType)
		)
	)
)


/* AP cursor: Update AP rows in temp table with calculated amounts for Holdback, Holdback Tax, Tax at Invoice level (APInvTaxAddend), Line 106 */

/* "Calculations" are primarily column assignments. Some amounts must be assigned conditionally to various columns mainly to separate 
retainage amounts from non-retainage amounts conditionally for display at the invoice level, based on whether retainage was paid within 
current reporting period. If retainage was paid within current reporting period, then at the invoice level: 1) retainage amount should not appear in 
Holdback column, 2) retainage tax amount should appear in Tax column and not in Holdback Tax column, and 3) any GST amount associated with retainage 
should be reported on Line 106. */

/* Rules of assignment:
Holdback: Non-retainage row is always 0; retainage row is 0 if PaidMth is within reporting period, otherwise same as "Amount" column.
Holdback Tax: Non-retainage row is always 0; retainage row is 0 if PaidMth is within reporting period, otherwise same as "Tax" column.
Tax at Invoice level (APInvTaxAddend): Non-retainage row is always same as "Tax" column; retainage row is same as "Tax" column if PaidMth is within 
reporting period, otherwise 0.
Line 106: Non-retainage row is always APTD.GSTtaxAmt; retainage row is APTD.GSTtaxAmt if PaidMth is within reporting period, otherwise 0. */

DECLARE @APCo bCompany, /* @Mth bMonth, @Trans bTrans, @Line smallint */ @APSeq tinyint
DECLARE @APSeqIsRetgPayType bYN, @APPaidMth bMonth
DECLARE /* @Amount bDollar, @Tax bDollar */ @APGSTtaxAmt bDollar

DECLARE /* @Holdback bDollar */ @HoldbackTax bDollar, @APInvTaxAddend bDollar, @AmtLine106 bDollar
SELECT @Holdback = 0, @HoldbackTax = 0, @APInvTaxAddend = 0, @AmtLine106 = 0

DECLARE AmountsCursorAP CURSOR LOCAL FAST_FORWARD FOR
	SELECT APCo, Mth, Trans, Line, APSeq, APSeqIsRetgPayType, APPaidMth, Amount, Tax, APGSTtaxAmt
	FROM dbo.#TempTableGSTHST
	WHERE [Source] = 'AP'

OPEN AmountsCursorAP
FETCH NEXT FROM AmountsCursorAP INTO @APCo, @Mth, @Trans, @Line, @APSeq, @APSeqIsRetgPayType, @APPaidMth,
	@Amount, @Tax, @APGSTtaxAmt

WHILE @@fetch_status = 0
	BEGIN
		
		/* Calculate amounts for non-retainage row */
		IF @APSeqIsRetgPayType = 'N'
			BEGIN
				SELECT @APInvTaxAddend = @Tax, @AmtLine106 = @APGSTtaxAmt
			END
		
		/* Calculate amounts for retainage row */
		ELSE
			BEGIN
				IF @APPaidMth BETWEEN @BeginningMonth AND @EndingMonth
					BEGIN
						SELECT @APInvTaxAddend = @Tax, @AmtLine106 = @APGSTtaxAmt
					END
				ELSE
					BEGIN
						SELECT @Holdback = @Amount, @HoldbackTax = @Tax
					END
			END		
		
		/* Update temp table with calculated amounts */
		UPDATE dbo.#TempTableGSTHST
		SET Holdback = @Holdback, HoldbackTax = @HoldbackTax, APInvTaxAddend = @APInvTaxAddend, AmtLine106 = @AmtLine106
		WHERE [Source] = 'AP' AND APCo = @APCo AND Mth = @Mth AND Trans = @Trans AND Line = @Line AND APSeq = @APSeq
		
		/* Re-initialize variables */
		SELECT @APSeqIsRetgPayType = NULL, @APPaidMth = NULL
		SELECT @Amount = 0, @Tax = 0, @APGSTtaxAmt = 0
		
		SELECT @Holdback = 0, @HoldbackTax = 0, @APInvTaxAddend = 0, @AmtLine106 = 0
		
		/* Retrieve next row from cursor */
		FETCH NEXT FROM AmountsCursorAP INTO @APCo, @Mth, @Trans, @Line, @APSeq, @APSeqIsRetgPayType, @APPaidMth,
			@Amount, @Tax, @APGSTtaxAmt
		
	END

CLOSE AmountsCursorAP
DEALLOCATE AmountsCursorAP


/* Final selection for report */

SELECT
	[Source],
	[GLCo],
	[CompanyName],
	[ARCo],
	[APCo],
	[ARApplyMth],
	[ARApplyTrans],
	[Invoice],
	--[ARCustGroup],			--Column not used in Crystal file
	[ARCustomer],
	[ARCustName],
	--[APVendorGroup],			--Column not used in Crystal file
	[APVendor],
	[APVendorName],
	[Mth],
	[Trans],
	[Line],
	[APSeq],
	[ARTransType],
	[APPayType],
	[APPayTypeDescription],
	--[APPayCategory],			--Column not used in Crystal file
	--[APSeqIsRetgPayType],		--Column not used in Crystal file
	--[TaxGroup],				--Column not used in Crystal file
	[TaxCode],
	--[ARTaxCodeIsVAT],			--Column not used in Crystal file
	--[ARTaxCodeIsGST],			--Column not used in Crystal file
	--[ARTaxCodeIsMultiLevel],	--Column not used in Crystal file
	[InvoiceDate],
	[APStatus],
	[APPaidMth],
	[Amount],
	[Holdback],
	[Tax],
	[HoldbackTax],
	[APInvTaxAddend],
	--[APGSTtaxAmt],			--Column not used in Crystal file
	[AmtLine101],
	[AmtLine103],
	[AmtLine106],
	[AmtLine107]
FROM dbo.#TempTableGSTHST

DROP TABLE dbo.#TempTableGSTHST
GO
GRANT EXECUTE ON  [dbo].[vrptGLCanadaGSTHST] TO [public]
GO
