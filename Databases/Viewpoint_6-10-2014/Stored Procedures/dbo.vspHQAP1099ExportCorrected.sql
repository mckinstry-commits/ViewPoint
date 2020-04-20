SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[vspHQAP1099ExportCorrected]
    /************************************
    * Created: 07/20/09 MV
    * Modified: 02/15/10 - #137772 - return CombinedYN flag to indicate if any of the
	*								records to be returned is for a participating fed/st filing
	*			10/01/2010 CHS - #138377 Added oregon
	*			10/03/2011 CHS - D-03052 removed oregon
	*			10/17/11	MV - TK-09070 get mailing address from APVM V1099AddressSeq else APVM Payment Address
	*			12/05/2013	EN TFS-68310/Task 68972 Added Michigan and Vermont to list of states participating in combined fed/state filing
	*
	*	PLEASE NOTE: IF YOU UPDATE LIST OF PARTICIPATING STATES HERE YOU MUST UPDATE FORM CODE FUNCTION 'StateNumericCodes'
    *	Returns vendor and 1099 information to frmAP1099Download
	*	for corrected filings 
    *
    * Pass in:
    *	@APCo        AP Company
    *	@YEMO        YEMO
    *	@Types       Type of 1099 being reported
    *
    * Returns:
    *	Data related to the exporting of 1099 data
    *
    ***********************************/
    (@APCo bCompany, @Yemo bMonth, @Types varchar(10),@errortype tinyint)
   
   as
   set nocount on

 declare @combinedyn bYN
-- return CombinedYN = 'Y' if any state included in the select below participates in the combined fed/state filing
	if exists (
	select * from bAPFT a
    inner join bAPVM b on b.VendorGroup = a.VendorGroup and b.Vendor = a.Vendor
    inner join bHQCO c on a.APCo = c.HQCo
    where a.APCo = @APCo and a.YEMO = @Yemo and RTRIM(a.V1099Type)= @Types and b.V1099YN = 'Y' and a.CorrectedFilingYN = 'Y' and
		a.CorrectedErrorType = @errortype 
		and b.State in ('AL','AZ','AR','CA','CO','CT','DE','DC','GA','HI','ID','IN','IA','KS','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE',
		'NJ','NM','NC','ND','OH',
		--'OR', D-03052 -- 10/03/2011 CHS
		'SC','VA','WI','UT','VT' ))
		begin
		Select @combinedyn = 'Y'
		end
	else
		begin
		select @combinedyn = 'N'
		end
		
	Select	'APCo'=a.APCo, 'VendorGroup'=a.VendorGroup, 'APFTVendor'=a.Vendor, 'YEMO'=a.YEMO ,'1099Type'=RTRIM(a.V1099Type),
			'Box1Amt'=a.Box1Amt, 'Box2Amt'=a.Box2Amt, 'Box3Amt'=a.Box3Amt, 'Box4Amt'=a.Box4Amt, 'Box5Amt'=a.Box5Amt,
			'Box6Amt'=a.Box6Amt, 'Box7Amt'=a.Box7Amt,'Box8Amt'=a.Box8Amt, 'Box9Amt'=a.Box9Amt,'Box10Amt'=a.Box10Amt,
			'Box11Amt'= a.Box11Amt,'Box12Amt'= a.Box12Amt,'Box13Amt'= a.Box13Amt,'Box14Amt'=a.Box14Amt,'Box15Amt'=a.Box15Amt,
			'Box16Amt'=a.Box16Amt,'Box17Amt'= a.Box17Amt,'Box18Amt'=a.Box18Amt,'OtherData'= a.OtherData,'DivBox7FC'=a.DIVBox7FC,
			'TIN2'=a.TIN2,'APVMVendor'=b.Vendor, 'APVMName'=b.Name,
			'APVMAddress'= ISNULL(d.Address,b.Address),
			'APVMCity'= ISNULL(d.City,b.City),
			'APVMState'= ISNULL(d.State,b.State),
			'APVMZip'= ISNULL(d.Zip,b.Zip),
			'APVMAddress2'= ISNULL(d.Address2,b.Address2),
			'TaxId'=b.TaxId ,'Prop'=b.Prop,'HQCoName'=c.Name, 'HQCoAddress'=c.Address,
			'HQCOCity'=c.City,'HQCOState'=c.State, 'HQCOZip'=c.Zip, 'HQCOAddress2'=c.Address2,'FedTaxId'=c.FedTaxId,
			'ErrorType' = a.CorrectedErrorType,'OldVendorName' = a.OldVendorName, 'OldVendorAddr' = a.OldVendorAddr,
			'OldVendorCity' = a.OldVendorCity, 'OldVendorState'= a.OldVendorState, 'OldVendorZip'=a.OldVendorZip,
			'OldVendorTaxId' = a.OldVendorTaxId, 'CombinedYN' = @combinedyn
   
    from bAPFT a
    inner join bAPVM b on b.VendorGroup = a.VendorGroup and b.Vendor = a.Vendor
    inner join bHQCO c on a.APCo = c.HQCo
    LEFT JOIN dbo.bAPAA d ON d.VendorGroup = a.VendorGroup and d.Vendor = a.Vendor AND b.V1099AddressSeq = d.AddressSeq
    
    where a.APCo = @APCo and a.YEMO = @Yemo and RTRIM(a.V1099Type)= @Types and b.V1099YN = 'Y' and a.CorrectedFilingYN = 'Y' and
		a.CorrectedErrorType = @errortype
    Order By a.V1099Type
	
	
	


   

 
GO
GRANT EXECUTE ON  [dbo].[vspHQAP1099ExportCorrected] TO [public]
GO
