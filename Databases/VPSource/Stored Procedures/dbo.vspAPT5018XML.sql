
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE            proc [dbo].[vspAPT5018XML]
    /************************************
    * Created: MV 06/23/09 - #27230 
    * Modified:	MV 06/18/12 - TK15758 restrict Amended refiling by bAPVM.V1099YN = 'Y' (vendor is still subject to T5)  
	*			GF 04/22/2013 TFS-47480 use APVM.V1099AddressSeq for vendor address if there is one.  
	*
    * This SP is called from form APT5018 to return a list of vendor info
    *
    ***********************************/
    (@co bCompany, @vendorgroup bGroup, @perenddate bDate, @reporttype char(1))
  
   as
   set nocount on
  
	if @reporttype = 'A' --Amended refiling
		begin
		select isnull(c.Name,'')'HQName',isnull(c.Address,'') 'HQAddress', isnull(c.City,'') 'HQCity', isnull(c.State,'') 'HQState',
			isnull(c.Country,'') 'HQCountry', isnull(c.Zip,'') 'HQPostal', isnull(c.FedTaxId,'') 'HQBusNbr',isnull(v.Name,'') 'VMName',
		    ----TFS-47400
     				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Address]  ELSE v.[Address]	END AS [VMAddress],
					CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[City]	 ELSE v.[City]		END AS [VMCity],
					CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[State]    ELSE v.[State]		END AS [VMState],
					CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Zip]      ELSE v.[Zip]		END AS [VMPostal],
					CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Country]  ELSE v.Country		END AS [VMCountry], 
			--isnull(v.Address,'') 'VMAddress', isnull(v.City,'') 'VMCity', isnull(v.State,'') 'VMState', isnull(v.Zip,'') 'VMPostal',
			--isnull(v.Country,'') 'VMCountry',
			isnull(v.T5BusTypeCode,'') 'VMBusTypeCode', isnull(v.T5BusinessNbr,'') 'VMBusinessNbr',
			isnull(v.T5PartnerFIN,'') 'VMPartnerFIN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', isnull(v.T5FirstName,'') 'VMFirstName',
			isnull(v.T5MiddleInit,'') 'VMMiddleInit', isnull(v.T5LastName,'') 'VMLastName', isnull(t.Amount,'0') 'T5Amount', isnull(t.Type,'') 'T5Type'
		From dbo.bAPT5 t (nolock)
		join dbo.bAPVM v (nolock) on t.VendorGroup=v.VendorGroup and t.Vendor=v.Vendor
		join dbo.bHQCO c (nolock) on c.HQCo=t.APCo
		----TFS-47480
		LEFT JOIN dbo.bAPAA APAA ON APAA.VendorGroup = v.VendorGroup AND APAA.Vendor = v.Vendor AND APAA.AddressSeq = v.V1099AddressSeq
		where t.APCo=@co and @perenddate=t.PeriodEndDate and t.VendorGroup=@vendorgroup and t.RefilingYN='Y' AND v.V1099YN = 'Y' 
		end
	else
		begin	--Original filing
		select isnull(c.Name,'')'HQName',isnull(c.Address,'') 'HQAddress', isnull(c.City,'') 'HQCity', isnull(c.State,'') 'HQState',
			isnull(c.Country,'') 'HQCountry', isnull(c.Zip,'') 'HQPostal', isnull(c.FedTaxId,'') 'HQBusNbr',isnull(v.Name,'') 'VMName',
		    ----TFS-47400
     				CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Address]  ELSE v.[Address]	END AS [VMAddress],
					CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[City]	 ELSE v.[City]		END AS [VMCity],
					CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[State]    ELSE v.[State]		END AS [VMState],
					CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Zip]      ELSE v.[Zip]		END AS [VMPostal],
					CASE WHEN v.V1099AddressSeq IS NOT NULL THEN APAA.[Country]  ELSE v.Country		END AS [VMCountry], 
			--isnull(v.Address,'') 'VMAddress', isnull(v.City,'') 'VMCity', isnull(v.State,'') 'VMState', isnull(v.Zip,'') 'VMPostal',
			--isnull(v.Country,'') 'VMCountry', 
			isnull(v.T5BusTypeCode,'') 'VMBusTypeCode', isnull(v.T5BusinessNbr,'') 'VMBusinessNbr',
			isnull(v.T5PartnerFIN,'') 'VMPartnerFIN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', isnull(v.T5FirstName,'') 'VMFirstName',
			isnull(v.T5MiddleInit,'') 'VMMiddleInit', isnull(v.T5LastName,'') 'VMLastName', isnull(t.OrigAmount,'0') 'T5Amount', isnull(t.Type,'') 'T5Type'
		From dbo.bAPT5 t (nolock)
		join dbo.bAPVM v (nolock) on t.VendorGroup=v.VendorGroup and t.Vendor=v.Vendor
		join dbo.bHQCO c (nolock) on c.HQCo=t.APCo
		----TFS-47480
		LEFT JOIN dbo.bAPAA APAA ON APAA.VendorGroup = v.VendorGroup AND APAA.Vendor = v.Vendor AND APAA.AddressSeq = v.V1099AddressSeq
		where t.APCo=@co and @perenddate=t.PeriodEndDate and t.VendorGroup=@vendorgroup and t.RefilingYN='N'
		end

   

	return 








GO

GRANT EXECUTE ON  [dbo].[vspAPT5018XML] TO [public]
GO
