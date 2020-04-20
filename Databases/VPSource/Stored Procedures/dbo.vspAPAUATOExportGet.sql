SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE	PROC [dbo].[vspAPAUATOExportGet]
/************************************
* Created By:	GF 04/09/2013 AP ATO Taxable Payment Enhancement
* Modified By:	GF 06/13/2013 TFS-52766 return BSB, Account # from APVM and format address fields
*
*
* This procedure is called form the AP ATO Export Process and returns
* supplier/payer - creditor/payee information to be reported in the E file process.
*
* INPUT PARAMETERS
*   @APCo		AP Company
*   @TaxYear	Tax Year
*	@AmendedDate	ATO Amended Date or null
*
***********************************/
(@APCo bCompany = NULL,
 @TaxYear SMALLINT = NULL,
 @AmendedDate bDate = NULL)

AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0
	
DECLARE  @FileDate smalldatetime

SET @FileDate = dbo.vfDateOnly()
	
IF ISNULL(@AmendedDate,'') = '' SET @AmendedDate = NULL

---- get supplier/payer information
SELECT  Payer.TaxYear,
		ISNULL(Payer.ABN, '00000000000') AS [ABN],
		ISNULL(Payer.BranchNo, '001') AS [BranchNo],
		Payer.CompanyName, 	Payer.ContactName, Payer.ContactPhone,
		Payer.SignatureOfAuthPerson,
		Payer.ReportDate, @FileDate AS [FileDate],

		----TFS-52766
		ISNULL(PayerAddress.[Address], '')		AS [Address],
		ISNULL(PayerAddress.[Address2], '')		AS [Address2],
		ISNULL(PayerAddress.[City], '')			AS [City],
		ISNULL(PayerAddress.[State], '')		AS [State],
		ISNULL(PayerAddress.[PostalCode], '')	AS [PostalCode],
		ISNULL(PayerAddress.[Country], '')		AS [Country]

		--LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Payer.[Address],'      ',' '),'     ',' '),'    ',' '),'   ',' '),'  ',' ')) AS [Address],
		--LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Payer.[Address2],'      ',' '),'     ',' '),'    ',' '),'   ',' '),'  ',' ')) AS [Address2],
		--LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Payer.[City],'      ',' '),'     ',' '),'    ',' '),'   ',' '),'  ',' ')) AS [City],
		--CASE WHEN Payer.[State] NOT IN ('ACT', 'NSW', 'NT', 'QLD', 'SA', 'TAS', 'VIC', 'WA') THEN 'OTH' ELSE Payer.[State] END AS [State],

		------TFS-52766
		--CASE WHEN ISNULL(Payer.Country, HQCO.DefaultCountry) <> 'AU' THEN '9999'
		--	ELSE
		--		CASE WHEN ISNULL(Payer.[Address], '') = '' THEN '0000'
		--		WHEN ISNULL(Payer.[PostalCode], '') BETWEEN '0001' AND '9998' THEN Payer.[PostalCode]
		--		ELSE '0000' END
		--	END AS [PostalCode],
		----CASE WHEN ISNULL(Payer.Country, HQCO.DefaultCountry) = 'AU' THEN Payer.[PostalCode] ELSE '9999' END AS [PostalCode],

		--CASE WHEN ISNULL(Payer.Country, HQCO.DefaultCountry) = 'AU' THEN 'AUSTRALIA' ELSE ISNULL(Payer.Country, HQCO.DefaultCountry) END AS [Country],


FROM dbo.vAPAUPayerTaxPaymentATO Payer
INNER JOIN dbo.bHQCO HQCO ON HQCO.HQCo = Payer.APCo

---- TFS-52766 TABLE FUNCTION APPLIED FOR Creditor address values
CROSS APPLY dbo.vfAPAUATOAddressGet(Payer.[Address], Payer.[Address2], Payer.[City], Payer.[State],
				Payer.[PostalCode], ISNULL(Payer.[Country], HQCO.[DefaultCountry])) PayerAddress

WHERE Payer.APCo = @APCo
	AND Payer.TaxYear = @TaxYear



---- get creditor/payee information
SELECT  Creditor.VendorGroup, Creditor.Vendor, Creditor.PayeeName,
		ISNULL(Creditor.AusBusNbr, '00000000000') AS [AusBusNbr],
		Creditor.AmendedDate, Creditor.Phone,
		CAST(ROUND(ABS(Creditor.TotalNoABNTax), 0, 1) AS DECIMAL (11,0)) AS [TotalNoABNTax],
		CAST(ROUND(ABS(Creditor.TotalGST), 0, 1)	  AS DECIMAL (11,0)) AS [TotalGST],
		CAST(ROUND(ABS(Creditor.TotalPaid), 0, 1)	  AS DECIMAL (11,0)) AS [TotalPaid],
		CASE WHEN @AmendedDate IS NOT NULL THEN 'A' ELSE 'O' END AS [AmendmentIndicator],
		----TFS-52766
		APVM.AUVendorBSB AS [AUVendorBSB],
		APVM.AUVendorAccountNumber AS [AUVendorAccountNumber],

		ISNULL(CreditorAddress.[Address], '')	AS [Address],
		ISNULL(CreditorAddress.[Address2], '')	AS [Address2],
		ISNULL(CreditorAddress.[City], '')		AS [City],
		ISNULL(CreditorAddress.[State], '')		AS [State],
		ISNULL(CreditorAddress.[PostalCode], '')	AS [PostalCode],
		ISNULL(CreditorAddress.[Country], '')		AS [Country]

FROM dbo.vAPAUPayeeTaxPaymentATO Creditor
INNER JOIN dbo.bHQCO HQCO ON HQCO.HQCo = Creditor.APCo
LEFT JOIN dbo.bAPVM APVM ON APVM.VendorGroup = Creditor.VendorGroup AND APVM.Vendor = Creditor.Vendor

---- TFS-52766 TABLE FUNCTION APPLIED FOR Creditor address values
CROSS APPLY dbo.vfAPAUATOAddressGet(Creditor.[Address], Creditor.[Address2], Creditor.[City], Creditor.[State],
				Creditor.[PostalCode], ISNULL(Creditor.[Country], HQCO.[DefaultCountry])) CreditorAddress



WHERE Creditor.APCo = @APCo
	AND Creditor.TaxYear = @TaxYear
	AND CASE WHEN @AmendedDate IS NOT NULL AND Creditor.AmendedDate = @AmendedDate THEN 0
			 WHEN @AmendedDate IS NOT NULL AND Creditor.AmendedDate <> @AmendedDate THEN 1
			 ELSE 0
			 END = 0





return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspAPAUATOExportGet] TO [public]
GO
