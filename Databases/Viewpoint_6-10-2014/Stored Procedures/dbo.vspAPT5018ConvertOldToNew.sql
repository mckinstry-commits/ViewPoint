SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[vspAPT5018ConvertOldToNew]
/******************************************************
* CREATED BY:	GF 06/06/2013 TFS-00000 conversion process to convert the old APT5 data into APT5018Payment and Detail
* MODIFIED By:
*
* Usage: Process to be run with the service pack to convert old date into new tables
*
*
* Input params:
*
* No input parameters. Purpose is to convert all data.
*
* Output params:
* @Msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
(@Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @StartMonth SMALLDATETIME, @EndMonth SMALLDATETIME, @ValidDate DATETIME,
		@VendorGroup bGroup, @ErrMsg varchar(255), @EOM SMALLDATETIME

SET @rcode = 0

---- do we have data to convert
IF NOT EXISTS(SELECT 1 FROM dbo.bAPT5)
	BEGIN
    SET @Msg = 'No T5018 data to convert'
	RETURN 0
	END
	  
---- create table variable for APCo and PeriodEndDate (AAPT5)
DECLARE @T5018Header TABLE (APCo TINYINT, PeriodEndDate SMALLDATETIME, ReportDate SMALLDATETIME)

---- create table variable for Vendor Detail Payments (APT5)
DECLARE @T5018Detail TABLE (APCo TINYINT, PeriodEndDate SMALLDATETIME, VendorGroup TINYINT,
							Vendor INT, OrigReportDate SMALLDATETIME, OrigAmount bDollar,
							ReportDate SMALLDATETIME, Amount MONEY, ReportTypeCode CHAR(1),
							RefilingYN CHAR(1))


---- POPULATE @T5018HEADER
INSERT INTO @T5018Header (APCo, PeriodEndDate, ReportDate)
SELECT DISTINCT APCo, PeriodEndDate, ISNULL(ReportDate, OrigReportDate)
FROM dbo.bAPT5

---- need to convert the period end date from first day of month to last day of month
UPDATE @T5018Header SET PeriodEndDate = dbo.vfLastDayOfMonth (PeriodEndDate)

---- validate that the PeriodEndDate is a valid EOM date
IF EXISTS(SELECT 1 FROM @T5018Header WHERE dbo.vfLastDayOfMonth(PeriodEndDate) <> PeriodEndDate)
	BEGIN
    SET @Msg = 'Invalid Reporting Period End Date.'
	RETURN 1
	END
    

---- we may have possible duplicates that we need to remove
delete from a
from
(select APCo, PeriodEndDate,
		ROW_NUMBER() over (partition by APCo, PeriodEndDate
                           order by APCo, PeriodEndDate) RowNumber 
from @T5018Header) a
where a.RowNumber > 1


---- POPULATE @T5018DETAIL
INSERT INTO @T5018Detail (APCo, PeriodEndDate, VendorGroup, Vendor, OrigReportDate,
						  OrigAmount, ReportDate, Amount, ReportTypeCode, RefilingYN)
SELECT  APCo, PeriodEndDate, VendorGroup, Vendor, OrigReportDate,
		OrigAmount, ReportDate, Amount, [Type], RefilingYN
FROM dbo.bAPT5

---- need to convert the period end date from first day of month to last day of month
UPDATE @T5018Detail SET PeriodEndDate = dbo.vfLastDayOfMonth (PeriodEndDate)

---- validate that the PeriodEndDate is a valid EOM date
IF EXISTS(SELECT 1 FROM @T5018Detail WHERE dbo.vfLastDayOfMonth(PeriodEndDate) <> PeriodEndDate)
	BEGIN
    SET @Msg = 'Invalid Reporting Period End Date.'
	RETURN 1
	END


---- insert T5018 Payment Header
---- there will be no data except APCo, PeriodEndDate, ReportDate, and PeriodClosed which will be 'Y' closed

ALTER TABLE vAPT5018Payment DISABLE TRIGGER ALL

INSERT INTO dbo.vAPT5018Payment (APCo, PeriodEndDate, ReportDate, PeriodClosed)
SELECT a.APCo, a.PeriodEndDate, a.ReportDate, 'Y'
FROM @T5018Header a
WHERE NOT EXISTS(SELECT 1 FROM dbo.vAPT5018Payment b WHERE b.APCo = a.APCo AND b.PeriodEndDate = a.PeriodEndDate)

ALTER TABLE vAPT5018Payment ENABLE TRIGGER ALL

---- insert T5018 Payment Detail
---- will use information from @T5018Detail plus information from APVM

ALTER TABLE vAPT5018PaymentDetail DISABLE TRIGGER ALL

INSERT INTO dbo.vAPT5018PaymentDetail
	    (
			APCo, PeriodEndDate, VendorGroup, Vendor, VendorName, [Address], Address2, City,
			[State], PostalCode, Country, T5BusTypeCode, T5BusinessNbr, T5PartnerFIN, T5FirstName,
			T5MiddleInit, T5LastName, T5SocInsNbr, ReportTypeCode, TotalPaid
	    )

SELECT  a.APCo, a.PeriodEndDate, a.VendorGroup, a.Vendor, APVM.Name,
		CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Address],1,30)  ELSE SUBSTRING(APVM.[Address],1,30)  END,
		CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Address2],1,30) ELSE SUBSTRING(APVM.[Address2],1,30) END,
		CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[City],1,28)		ELSE SUBSTRING(APVM.[City],1,28)	 END,
		CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[State],1,2)		ELSE SUBSTRING(APVM.[State],1,2)	 END,
		CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN SUBSTRING(APAA.[Zip],1,10)		ELSE SUBSTRING(APVM.[Zip],1,10)		 END,
		CASE WHEN APVM.V1099AddressSeq IS NOT NULL THEN APAA.[Country] ELSE ISNULL(APVM.Country, HQCO.DefaultCountry) END,
		APVM.T5BusTypeCode,
		CASE WHEN APVM.T5BusinessNbr IS NOT NULL THEN APVM.T5BusinessNbr ELSE '000000000RZ0000' END,
		APVM.T5PartnerFIN, APVM.T5FirstName, APVM.T5MiddleInit, APVM.T5LastName,
		CASE WHEN APVM.T5SocInsNbr IS NOT NULL THEN APVM.T5SocInsNbr ELSE '000000000' END,
		a.ReportTypeCode,
		CASE a.ReportTypeCode WHEN 'O' THEN ISNULL(a.OrigAmount, 0) ELSE ISNULL(a.Amount,0) END
FROM @T5018Detail a
INNER JOIN dbo.bHQCO HQCO ON HQCO.HQCo = a.APCo
LEFT  JOIN dbo.bAPVM APVM ON APVM.VendorGroup = a.VendorGroup AND APVM.Vendor = a.Vendor
LEFT  JOIN dbo.bAPAA APAA ON APAA.VendorGroup = APVM.VendorGroup AND APAA.Vendor = APVM.Vendor AND APAA.AddressSeq = APVM.V1099AddressSeq
WHERE EXISTS(SELECT 1 FROM dbo.vAPT5018Payment b WHERE b.APCo = a.APCo
				AND b.PeriodEndDate = a.PeriodEndDate)
	AND NOT EXISTS(SELECT 1 FROM dbo.vAPT5018PaymentDetail c WHERE c.APCo = a.APCo
						AND c.PeriodEndDate = a.PeriodEndDate
						AND c.VendorGroup = a.VendorGroup
						AND c.Vendor = a.Vendor)

ALTER TABLE vAPT5018PaymentDetail ENABLE TRIGGER ALL



RETURN 0








GO
GRANT EXECUTE ON  [dbo].[vspAPT5018ConvertOldToNew] TO [public]
GO
