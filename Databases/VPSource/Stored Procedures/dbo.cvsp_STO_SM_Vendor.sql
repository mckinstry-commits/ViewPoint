SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	Convert STO SM Vendors to AP Vendor Master Table (bAPVM)	
	Created: 11/27/2012
	Created by:	VCS Technical Services - Brenda Ackerson
	Revisions:	
		1. 
	
Notes:
1. bAPCO, bCMCO and bCMAC must be populated prior to running this procedure.
	
2. Payment Terms must setup in Headquarters Payment Terms table (HQPT) by executing the HQPT 
stored procedure. STO's Vendor master table has 4 fields related to Payment Terms which 
are Discount_Percentage, Discount_Days, Payment_Days and Pmt_Days_Type fields but does not 
have a payment terms setup table like Viewpoint. Thus, 4 user defined columns are added to bHQPT
and are populated in order to be able to join onto this table and populate the bAPVM PayTerms field.		
**/


CREATE PROCEDURE [dbo].[cvsp_STO_SM_Vendor] 
(@Co bCompany, @VendorGroup bGroup)--, @DeleteAPVMDataYN char(1))   

AS

/** DECLARE AND SET PARAMETERS **/
--select * from dbo.budcvspParameters

declare @PrefixLength int 
set @PrefixLength=(select MAX(PrefixLength) from dbo.budcvspParameters where VendorGroup=@VendorGroup)

declare @UseTLVendorIDYN char(1) 
set @UseTLVendorIDYN=(select MAX(UseTLVendorIDYN) from dbo.budcvspParameters where VendorGroup=@VendorGroup)

declare @V1099TypeDefault varchar(5) 
set @V1099TypeDefault=(select MAX(V1099TypeDefault) from dbo.budcvspParameters where VendorGroup=@VendorGroup)

declare @V1099BoxDefault tinyint 
set @V1099BoxDefault=(select MAX(V1099BoxDefault) from dbo.budcvspParameters where VendorGroup=@VendorGroup)

declare @UseTLLastBankAcctYN char(1) 
set @UseTLLastBankAcctYN=(select MAX(UseTLLastBankAcctYN) from dbo.budcvspParameters where VendorGroup=@VendorGroup)

declare @DefaultOldBankID varchar(10) 
set @DefaultOldBankID=(select MAX(DefaultOldBankID) from dbo.budcvspParameters where VendorGroup=@VendorGroup)

declare @DefaultCMAcct int 
set @DefaultCMAcct=(select MAX(DefaultCMAcct) from dbo.budcvspParameters where VendorGroup=@VendorGroup)

declare @DefaultPayTerms int
set @DefaultPayTerms=(select Top 1 PayTerms from bHQPT)


/**DELETE DATA IN bAPVM TABLE**/
IF OBJECT_ID('bAPVM_bak','U') IS NOT NULL
BEGIN
	DROP TABLE bAPVM_bak
END;
BEGIN
	SELECT * INTO bAPVM_bak FROM bAPVM
END;

--if @DeleteAPVMDataYN IN('Y','y')
--begin
--	ALTER TABLE bAPVM DISABLE TRIGGER ALL;
--	BEGIN TRAN
--		DELETE bAPVM
--		WHERE bAPVM.VendorGroup=@VendorGroup
--	COMMIT TRAN
--	CHECKPOINT;
--	WAITFOR DELAY '00:00:02.000';
--	ALTER TABLE bAPVM ENABLE TRIGGER ALL;
--end;


/** POPULATE SM VENDORS TO AP VENDORS **/
ALTER TABLE bAPVM DISABLE TRIGGER ALL;

INSERT bAPVM
	(
		 VendorGroup
		,Vendor
		,SortName --Must be unique
		,Name
		,Type
		,TempYN
		,Contact
		,Phone
		,Fax
		,EMail
		,URL
		,Address
		,City
		,State
		,Zip
		,Address2
		,POAddress
		,POCity
		,POState
		,POZip
		,POAddress2
		,Purge
		,CustGroup
		,Customer
		,TaxGroup
		,TaxCode
		,PayTerms
		,GLCo
		,GLAcct
		,V1099YN
		,V1099Type
		,V1099Box
		,TaxId
		,Prop
		,ActiveYN
		,EFT
		,RoutingId
		,BankAcct
		,AcctType
		,LastInvDate
		,AuditYN
		,Notes
		,AddnlInfo
		,AddendaTypeId
		,Reviewer
		,SeparatePayInvYN
		--, UniqueAttchID
		,OverrideMinAmtYN
		,MasterVendor
		,APRefUnqOvr
		,ICFirstName
		,ICMInitial
		,ICLastName
		,ICSocSecNbr
		,ICStreetNbr
		,ICStreetName
		,ICAptNbr
		,ICCity
		,ICState
		,ICZip
		,ICLastRptDate
		,UpdatePMYN
		,Country
		,POCountry
		,ICCountry
		,AddRevToAllLinesYN
		--,PayInfoDelivMthd
		--,IATYN
		--,ISODestinationCountryCode
		--,RDFIBankName
		--,BranchCountryCode
		--,RDFIIdentNbrQualifier
		--,GatewayOperatorRDFIIdent
		,CMAcct
		--,T5FirstName
		--,T5MiddleInit
		--,T5LastName
		--,T5SocInsNbr
		--,T5BusinessNbr
		--,T5BusTypeCode
		--,T5PartnerFIN
		--,PayControl
			
	/** 6.4 Fields **/
		,V1099AddressSeq	

	/** 6.5 Fields **/
		,PayMethod
		,SubjToOnCostYN
		,CSEmail
		,OnCostCostType
		
	/** AUSTRALIAN FIELDS **/
		
		,AUVendorEFTYN
		,AUVendorAccountNumber
		,AUVendorBSB
		,AUVendorReference
		--,AusBusNbr
		--,AusCorpNbr

	/** CANADIAN FIELDS **/
	
		,CASubjToWC --YN field
		,CAClearanceCert
		,CACertEffectiveDate
	
	/** CONVERSION FIELDS **/
		,udTLVendor
		,udTLCustomerNumber
		,udConvertedYN
	)


SELECT DISTINCT
		 VendorGroup=bHQCO.VendorGroup
		,Vendor=x.NewVendorID		
		/*NOTE - SortName must be unique, no two vendors can have same sortname*/
		,SortName=
			case when @UseTLVendorIDYN='Y' then x.OldVendorID 
				else
					case 
						when v.APVENDOR='ONETIME' then 'ONETIME' 
						when v.APVENDOR<>'ONETIME' then
							case
								when LEN(v.APVENDOR)< 7 then
									UPPER(LEFT(dbo.cvfn_StripNonAlphaChar(v.NAME),8)
									+'-'+CAST(LEFT(v.APVENDOR,6) as varchar(6)))
								when LEN(v.APVENDOR)=7 then
									UPPER(LEFT(dbo.cvfn_StripNonAlphaChar(v.NAME),7)
									+'-'+CAST(LEFT(v.APVENDOR,7) as varchar(7)))
								else 
									UPPER(LEFT(dbo.cvfn_StripNonAlphaChar(v.NAME),6)
									+'-'+CAST(LEFT(v.APVENDOR,8) as varchar(8)))
							end
					end
			end
		,Name=v.NAME
/*STO Vendor record has a "type" field but it doesn't correlate to VP Type which only allows R=Regular or S=Supplier*/
		,Type='R' 
		,TempYN=case when v.APVENDOR='ONETIME' then 'Y' else 'N' end 
		,Contact=v.CONTACT
		,Phone=CASE 
					WHEN v.MAINPHONE<>'' THEN dbo.cvfn_StandardPhone(v.MAINPHONE)
					WHEN v.CONTACTPHONE<>'' THEN dbo.cvfn_StandardPhone(v.CONTACTPHONE)
					ELSE NULL 
				END
		,Fax=CASE WHEN v.FAX<>'' THEN dbo.cvfn_StandardPhone(v.FAX) ELSE NULL END 
		,EMail=EMAILADDR 
		,URL=null 
		,Address=
			CASE WHEN v.ADDRESS<>'' THEN 
				CASE WHEN v.ADDRESS2<>'' AND LEN(v.ADDRESS+', '+v.ADDRESS2)<=60  
					THEN v.ADDRESS+', '+v.ADDRESS2 
					ELSE v.ADDRESS 
				END
				ELSE NULL 
			END    
		,City=CASE WHEN v.CITY<>'' THEN v.CITY ELSE NULL END  
		,State=
			case 
				when v.STATE='' then null 
				else v.STATE 
			end
		,Zip=CASE WHEN v.ZIP<>'' THEN v.ZIP ELSE NULL END  
		,Address2=
			CASE 
				WHEN v.ADDRESS2<>'' AND LEN(v.ADDRESS+', '+v.ADDRESS2)>60 THEN v.ADDRESS2 
				ELSE NULL 
			END
		,POAddress=
			CASE WHEN v.ADDRESS<>'' THEN 
				CASE WHEN v.ADDRESS2<>'' AND LEN(v.ADDRESS+', '+v.ADDRESS2)<=60  
					THEN v.ADDRESS+', '+v.ADDRESS2 
					ELSE v.ADDRESS 
				END
				ELSE NULL 
			END 
		,POCity=CASE WHEN v.CITY<>'' THEN v.CITY ELSE NULL END  
		,POState=
			case 
				when v.STATE='' then null 
				else v.STATE 
			end
		,POZip=CASE WHEN v.ZIP<>'' THEN v.ZIP ELSE NULL END  
		,POAddress2=
			CASE 
				WHEN v.ADDRESS2<>'' AND LEN(v.ADDRESS+', '+v.ADDRESS2)>60 THEN v.ADDRESS2 
				ELSE NULL 
			END 		
		,Purge='N'
		,CustGroup=bHQCO.CustGroup 
		,Customer=NULL
		,TaxGroup=bHQCO.TaxGroup 
		,TaxCode=
			case 
				when TAXGROUP<>'' then UPPER(TAXGROUP)
				else NULL
			end
		,PayTerms=
			CASE 
				WHEN v.TERMSCODE=0 THEN @DefaultPayTerms 
				--WHEN v.TERMSCODE=1 THEN @DefaultPayTerms 
				--If using, may need to add cross reference or multiple statements to do the mapping.
				ELSE @DefaultPayTerms 
			END	
		,GLCo=@Co
		,GLAcct=NULL
		,V1099YN='Y' --2011 Requirement.
		,V1099Type=@V1099TypeDefault
		,V1099Box=@V1099BoxDefault
		,TaxId=NULL --If any value is in the field, then convert. STO is 15 characters; VP is 12 characters.
		,Prop=NULL --If any value is in the field, then convert.
		,ActiveYN=x.ActiveYN
		,EFT='N'
		,RoutingID=null
		,BankAcct=null --Vendor's bank account
		,AcctType=null
		,LastInvDate=NULL
		,AuditYN='Y'
		,Notes=NULL
		,AddnlInfo=NULL --Additional information for addresses for printing on checks
		,AddendaTypeId=null 
		,Reviewer=null
		,SeperatePayInvYN='N'
		--,UniqueAttchID=null
		,OverrideMinAmtYN='N'
		,MasterVendor=null
		,APRefUnqOvr=0
		,ICFirstName=null
		,ICMInitial=null
		,ICLastName=null
		,ICSocSecNo=null
		,ICStreetNbr=null
		,ICStreetName=null 
		,ICAptNbr=null
		,ICCity=null
		,ICState=null
		,ICZip=null
		,ICLastRprtUpdate=null
		,UpdatePMYN='N'
		,Country=dbo.cvfn_Country(v.STATE)
		,POCountry=dbo.cvfn_Country(v.STATE)
		,ICCountry=dbo.cvfn_Country(v.STATE)
		,AddRevToAllLinesYN='N'

		--,PayInfoDelivMthd
		--,IATYN
		--,ISODestinationCountryCode
		--,RDFIBankName
		--,BranchCountryCode
		--,RDFIIdentNbrQualifier
		--,GatewayOperatorRDFIIdent
		,CMAcct=@DefaultCMAcct
		--,T5FirstName
		--,T5MiddleInit
		--,T5LastName
		--,T5SocInsNbr
		--,T5BusinessNbr
		--,T5BusTypeCode
		--,T5PartnerFIN
	    --,PayControl		
	    
	/** 6.4 Fields **/
		,V1099AddressSeq	

	/** 6.5 Fields **/
		,PayMethod='C' --default
		,SubjToOnCostYN='N' --default
		,CSEmail=NULL
		,OnCostCostType=NULL
		
	/** AUSTRALIAN FIELDS **/
		,AUVendorEFTYN='N'
		,AUVendorAccountNumber=NULL
		,AUVendorBSB=NULL
		,AUVendorReference=NULL
		--,AusBusNbr=
		--	case 
		--		when col_length('CV_TL_Source.dbo.APM_MASTER__VENDOR','Australian_Bus_Number') is not null
		--			and v.Australian_Bus_Number<>'' then v.Australian_Bus_Number 
		--		else NULL 
		--	end
		--,AusCorpNbr=
		--	case 
		--		when col_length('CV_TL_Source.dbo.APM_MASTER__VENDOR','Australian_Comp_Number') is not null
		--			and v.Australian_Comp_Number<>'' then v.Australian_Comp_Number 
		--		else NULL 
		--	end

	/** CANADIAN FIELDS **/
		,CASubjToWC='N'
		,CAClearanceCert=NULL
		,CACertEffectiveDate=NULL
	
	/** CONVERSION FIELDS **/		
		,udTLVendor=v.APVENDOR
		,udTLCustomerNumber=NULL
		,udConvertedYN='Y'
	
--declare @Co bCompany set @Co=
--select * 
FROM CV_TL_Source_SM.dbo.VENDOR v
INNER JOIN bHQCO  
	ON HQCo=@Co
INNER JOIN dbo.budXRefAPVendor x
	ON x.OldVendorID=v.APVENDOR AND x.VendorGroup=bHQCO.VendorGroup
INNER JOIN bAPCO 
	ON APCo=@Co
LEFT JOIN CV_TL_Source_SM.dbo.PAYTERMS pt --If client is using, edit case statement above.
	ON pt.TERMSCODE=v.TERMSCODE	
LEFT JOIN CV_TL_Source_SM.dbo.SHIPMETHOD sh
	ON sh.SHIPMETHOD=v.SHIPMETHOD --Not currently populated on APVM
LEFT JOIN bAPVM 
	ON bAPVM.VendorGroup=bHQCO.VendorGroup and bAPVM.Vendor=x.NewVendorID
WHERE bAPVM.Vendor IS NULL;

ALTER TABLE bAPVM ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @VendorGroup bGroup set @VendorGroup=
select COUNT(*) as bAPVM_Count from bAPVM where VendorGroup=@VendorGroup;
select * from bAPVM where VendorGroup=@VendorGroup;

select COUNT(*) as STOVendorCount from CV_TL_Source_SM.dbo.VENDOR;
select * from CV_TL_Source_SM.dbo.VENDOR order by APVENDOR;


/** DATA REVIEW 
select * from CV_TL_Source_SM.dbo.VENDOR order by APVENDOR;
**/



GO
