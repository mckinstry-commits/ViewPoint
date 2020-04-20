use Viewpoint
go

alter FUNCTION dbo.mfnFormatZipCode
(
	-- Add the parameters for the function here
	@ZipCode varchar(12)
)
RETURNS varchar(12)
AS
BEGIN
	-- Declare the return variable here
	declare @retZip varchar(12)

	declare @ZipLen int 
	select @ZipCode=REPLACE(@ZipCode,'-','')
	select @ZipLen = len(@ZipCode)

	if @ZipLen > 5
	begin
		if @ZipLen > 6
		begin
			select @retZip=left(@ZipCode,5) + '-' + SUBSTRING(@ZipCode,6,@ZipLen-5)
		end
		else
		begin
			select @retZip=upper(left(@ZipCode,3) + ' ' + right(@ZipCode,3))
		end

	end
	else
	begin
		select @retZip=@ZipCode
	end

	RETURN @retZip

END
GO

grant exec  on dbo.mfnFormatZipCode to public
go

alter function [dbo].[mfnV1099Export]
(	
	@Year		bMonth
,	@Company	bCompany
) 
RETURNS TABLE 
AS
/*
2016.01.20 - LWO - Altered to incorporate new Legan Entity Name and Address Fields
*/
RETURN 
(	
SELECT
	hqco.HQCo
,	hqco.Name as CompanyName
,	hqco.FedTaxId
,	apft.APCo
,	apft.YEMO
,	apft.V1099Type
,	case 
		when apvm.V1099AddressSeq is null and apvm.udEntityType is null then apvm.Name
		when apvm.V1099AddressSeq is null and apvm.udEntityType is not null then coalesce(apvm.udLEName,apvm.Name)
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is null then coalesce(apvm.Prop,apvm.Name)
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is not null then coalesce(apvm.udLEName,apvm.Name)
		else coalesce(apvm.udLEName,apvm.Name,apvm.Prop)
	end as VendorName
--,	coalesce(apvm.udLEName, apvm.Name) as VendorName
,	apvm.VendorGroup
,	apvm.Vendor
,	apvm.TaxId
,	apvm.V1099YN as APVMV1099YN
,	apvm.V1099Type as AMVMV1099Type
,	apvm.V1099Box as APVMV1099Box
--,	aptt.Description
,	apft.Box1Amt
,	apft.Box2Amt
,	apft.Box3Amt
,	apft.Box4Amt
,	apft.Box5Amt
,	apft.Box6Amt
,	apft.Box7Amt
,	apft.Box8Amt
,	apft.Box9Amt
,	apft.Box10Amt
,	apft.Box11Amt
,	apft.Box12Amt
,	apft.Box13Amt
,	apft.Box14Amt
,	apft.Box15Amt
,	apft.Box16Amt
,	apft.Box18Amt
--,	apth.Mth as APTHMth
--,	apth.APTrans as APTHAPTrans
--,	aptd.Mth as APTDMth
--,	aptd.APTrans as APTDAPTrans
--,	apth.APRef as APTHAPRef
--,	apth.Description as APTHDesc
--,	apth.InvDate as APTHInvDate
--,	aptd.Status as APTDStatus
--,	aptd.Amount as APTDAmount
--,	aptd.CMAcct as APTDCMAcct
--,	aptd.CMRef as APTDCMRef
--,	aptd.PayMethod as APTDPayMethod
--,	aptd.PaidDate as APTDPaidDate
--,	apth.V1099YN as APTHV1099YN
--,	apth.V1099Box as APTHV1099Box
--,	aptd.PaidMth as APTDPaidMonth
--,	apth.V1099Type as APTHV1099Type
--,	apvm.Prop
--,	apvm.SortName
--,	apvm.OverrideMinAmtYN
--,	aptd.DiscTaken
--,	apft.CorrectedFilingYN
--,	apft.VendorGroup
--,	apft.Vendor
,	case 
		when apvm.V1099AddressSeq is null and apvm.udEntityType is null then 'Main'
		when apvm.V1099AddressSeq is null and apvm.udEntityType is not null then 'Legal'
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is null then 'Alternate'
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is not null then 'Legal'
		else 'Main'
	end as AddressType
,	case 
		when apvm.V1099AddressSeq is null and apvm.udEntityType is null then apvm.Address
		when apvm.V1099AddressSeq is null and apvm.udEntityType is not null then apvm.udLEAddress1
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is null then apaa.Address
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is not null then apvm.udLEAddress1
		else apvm.Address
	end as Address
,	case 
		when apvm.V1099AddressSeq is null and apvm.udEntityType is null then apvm.Address2
		when apvm.V1099AddressSeq is null and apvm.udEntityType is not null then apvm.udAddress2
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is null then apaa.Address2
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is not null then apvm.udAddress2
		else apvm.Address2
		--when apvm.V1099AddressSeq is null then apvm.Address2
		--else apaa.Address2
	end as Address2
,	case 
		when apvm.V1099AddressSeq is null and apvm.udEntityType is null then apvm.AddnlInfo
		when apvm.V1099AddressSeq is null and apvm.udEntityType is not null then null
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is null then null
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is not null then null
		else apvm.AddnlInfo
		--when apvm.V1099AddressSeq is null then apvm.AddnlInfo
		--else null
	end as AddnlInfo
,	case 
		when apvm.V1099AddressSeq is null and apvm.udEntityType is null then apvm.City
		when apvm.V1099AddressSeq is null and apvm.udEntityType is not null then apvm.udLECity
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is null then apaa.City
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is not null then apvm.udAddress2
		else apvm.City
		--when apvm.V1099AddressSeq is null then apvm.City
		--else apaa.City
	end as City
,	case 
		when apvm.V1099AddressSeq is null and apvm.udEntityType is null then apvm.State
		when apvm.V1099AddressSeq is null and apvm.udEntityType is not null then apvm.udLEState
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is null then apaa.State
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is not null then apvm.udLEState
		else apvm.State
		--when apvm.V1099AddressSeq is null then apvm.State
		--else apaa.State
	end as State
,	case 
		when apvm.V1099AddressSeq is null and apvm.udEntityType is null then dbo.mfnFormatZipCode(apvm.Zip)
		when apvm.V1099AddressSeq is null and apvm.udEntityType is not null then dbo.mfnFormatZipCode(apvm.udLEZip)
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is null then dbo.mfnFormatZipCode(apaa.Zip)
		when apvm.V1099AddressSeq is not null and apvm.udEntityType is not null then dbo.mfnFormatZipCode(apvm.udLEZip)
		else dbo.mfnFormatZipCode(apvm.Zip)
		--when apvm.V1099AddressSeq is null then dbo.mfnFormatZipCode(apvm.Zip)
		--else dbo.mfnFormatZipCode(apaa.Zip)
	end as Zip
--,	apvm.Address
--,	apaa.Address
--,	apvm.V1099AddressSeq
--,	apaa.AddressSeq
--,	apvm.Address2
--,	apaa.Address2
--,	apvm.City
--,	apvm.State
--,	apvm.Zip
--,	apaa.City
--,	apaa.State
--,	apaa.Zip
--,	{fn IFNULL(apft.V1099Type,'')}
 FROM
			APFT apft 
INNER JOIN	APTT aptt ON 
	apft.V1099Type=aptt.V1099Type
INNER JOIN HQCO hqco ON 
	apft.APCo=hqco.HQCo
INNER JOIN APVM apvm ON 
	apft.VendorGroup=apvm.VendorGroup
AND apft.Vendor=apvm.Vendor
--LEFT OUTER JOIN APTH apth ON
--	apft.APCo=apth.APCo
--AND apft.VendorGroup=apth.VendorGroup
--AND apft.Vendor=apth.Vendor
--AND apft.V1099Type=apth.V1099Type
--LEFT OUTER JOIN APTL aptl ON 
--	apth.APCo=aptl.APCo
--AND apth.Mth=aptl.Mth
--AND apth.APTrans=aptl.APTrans
--LEFT OUTER JOIN APTD aptd ON
--	aptl.APCo=aptd.APCo
--AND aptl.Mth=aptd.Mth
--AND aptl.APTrans=aptd.APTrans
--AND aptl.APLine=aptd.APLine
LEFT OUTER JOIN APAA apaa ON
	apvm.VendorGroup=apaa.VendorGroup
AND apvm.Vendor=apaa.Vendor
AND apvm.V1099AddressSeq=apaa.AddressSeq
WHERE  
--AND (apvm.Vendor>=0 AND apvm.Vendor<=999999) 
	apvm.V1099YN='Y'
AND ( apft.APCo = @Company or @Company is null )
AND apft.YEMO=@Year
--ORDER BY 
--	apft.APCo
)
go

grant select on [dbo].[mfnV1099Export] to public
go

grant exec on [dbo].[mfnFormatZipCode] to public
go

select * from [dbo].[mfnV1099Export]('12/1/2015',null)

