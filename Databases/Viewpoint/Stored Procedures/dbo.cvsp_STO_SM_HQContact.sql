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
	Title:	Convert SM Service Site Contacts to HQ Contacts Table (dbo.vHQContact)
	Created: 12/05/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 12/06/2012 BBA - Changed to create a SERVICESITE_CONTACTS table which will
			be used in other stored procedure.

Notes: STO SM does not have a CONTACTS or Address Book link. Thus, there are C1 and C2
Contact fields. The converted data will most likely need edited.

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_HQContact]
(@ContactGroup bGroup, @DeleteDataYN char(1))

AS 


/** BACKUP vHQContact TABLE **/
IF OBJECT_ID('vHQContact_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vHQContact_bak
END;
BEGIN
	SELECT * INTO vHQContact_bak FROM vHQContact
END;


/** DELETE DATA IN vHQContact TABLE **/
IF @DeleteDataYN IN('Y','y')
BEGIN
	DELETE dbo.vHQContact 
	WHERE ContactGroup=@ContactGroup
	  AND Notes='SM Service Site Contact'
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXSeq1 int 
SET @MAXSeq1=(SELECT ISNULL(MAX(HQContactID),0) FROM dbo.vHQContact)

DECLARE @MAXSeq2 int 
SET @MAXSeq2=(SELECT ISNULL(MAX(ContactSeq),0) FROM dbo.vHQContact)


/** CREATE SERVICESITE CONTACT TABLES **/
IF OBJECT_ID('#SERVICESITE_CONTACT1') IS NOT NULL
BEGIN
	DROP TABLE #SERVICESITE_CONTACT1
END;
BEGIN;
	SELECT
		 SITETYPE
		,SERVSITENBR
		,ARCUST
		,NAME
		,CNAME=C1NAME
		,CLASTNAME=
			CASE 
				WHEN C1NAME<>'' AND RTRIM(C1NAME) NOT LIKE '% %' THEN 'MissingLastName'
				WHEN C1NAME<>'' AND RTRIM(C1NAME) LIKE '% %' 
					THEN RTRIM(LTRIM(SUBSTRING(C1NAME,CHARINDEX(' ',C1NAME,1),25)))
				ELSE NULL
			END
		,CFIRSTNAME=LEFT(C1NAME, CHARINDEX(' ',C1NAME,1))
		,CTITLE=C1TITLE
		,CPHONE=C1PHONE
		,CMOBILE=C1MOBILE
		,CFAX=C1FAX
		,CEMAIL=C1EMAIL
		,SMCONTACTID='SM'+CAST(SITETYPE AS VARCHAR(5))+'-'+CAST(SERVSITENBR AS VARCHAR(13))+'-'+'C1'
	INTO #SERVICESITE_CONTACT1
	FROM CV_TL_Source_SM.dbo.SERVICESITE
	WHERE C1NAME<>'';
END;

IF OBJECT_ID('#SERVICESITE_CONTACT2') IS NOT NULL
BEGIN
	DROP TABLE #SERVICESITE_CONTACT2
END;
BEGIN
	SELECT
		 SITETYPE
		,SERVSITENBR
		,ARCUST
		,NAME
		,CNAME=C2NAME
		,CLASTNAME=
			CASE 
				WHEN C2NAME<>'' AND RTRIM(C2NAME) NOT LIKE '% %' THEN 'MissingLastName'
				WHEN C2NAME<>'' AND RTRIM(C2NAME) LIKE '% %' 
					THEN RTRIM(LTRIM(SUBSTRING(C2NAME,CHARINDEX(' ',C2NAME,1),25)))
				ELSE NULL
			END
		,CFIRSTNAME=LEFT(C2NAME, CHARINDEX(' ',C2NAME,1))
		,CTITLE=C2TITLE
		,CPHONE=C2PHONE
		,CMOBILE=C2MOBILE
		,CFAX=C2FAX
		,CEMAIL=C2EMAIL
		,SMCONTACTID='SM'+CAST(SITETYPE AS VARCHAR(5))+'-'+CAST(SERVSITENBR AS VARCHAR(13))+'-'+'C2'	
	INTO #SERVICESITE_CONTACT2
	FROM CV_TL_Source_SM.dbo.SERVICESITE
	WHERE C2NAME<>'';
END;

IF OBJECT_ID('CV_TL_Source_SM.dbo.SERVICESITE_CONTACTS ') IS NOT NULL
BEGIN
	DROP TABLE CV_TL_Source_SM.dbo.SERVICESITE_CONTACTS 
END;

BEGIN
	SELECT * INTO CV_TL_Source_SM.dbo.SERVICESITE_CONTACTS 
	FROM 
	(
		SELECT * FROM #SERVICESITE_CONTACT1
		UNION
		SELECT * FROM #SERVICESITE_CONTACT2
	) SSC
END;


/** POPULATE HQ CONTACTS FROM SM SERVICE SITES **/
SET IDENTITY_INSERT vHQContact ON
ALTER TABLE vHQContact NOCHECK CONSTRAINT ALL;
ALTER TABLE vHQContact DISABLE TRIGGER ALL;

/* SM SERVICE SITE CONTACT 1 */
INSERT vHQContact
	(
		HQContactID
	   ,ContactGroup
       ,ContactSeq
       ,FirstName
       ,MiddleInitial
       ,LastName
       ,CourtesyTitle
       ,Title
       ,Organization
       ,Phone
       ,PhoneExtension
       ,Cell
       ,Fax
       ,Email
       --,Address
       --,AddressAdditional
       --,City
       --,State
       --,Country
       --,Zip
       ,Notes
       --,UniqueAttchID
		
		--UD Fields
		--,udConvertedYN 
		--,udTLContact_ID
		,udSTOContactID
	   )

--declare @ContactGroup bGroup set @ContactGroup=
SELECT
		HQContactID=@MAXSeq1+ROW_NUMBER () OVER (ORDER BY @ContactGroup, ss.SMCONTACTID)
	   ,ContactGroup=@ContactGroup
       ,ContactSeq=CAST(@MAXSeq2+ROW_NUMBER () OVER (ORDER BY @ContactGroup, ss.SMCONTACTID)AS INT)
       ,FirstName=ss.CFIRSTNAME
       ,MiddleInitial=NULL
       ,LastName=ss.CLASTNAME
       ,CourtesyTitle=NULL
       ,Title=case when ss.CTITLE<>'' then ss.CTITLE else NULL end
       ,Organization=case when ss.NAME<>'' then LEFT(ss.NAME,30) else NULL end
       ,Phone=
			case 
				when ss.CPHONE<>'' 
					then dbo.cvfn_StandardPhone(ss.CPHONE) 
					else NULL 
			end
       ,PhoneExtension=NULL
       ,Cell=
			case 
				when ss.CMOBILE<>'' 
					then dbo.cvfn_StandardPhone(ss.CMOBILE) 
					else NULL 
			end
       ,Fax=
			case 
				when ss.CFAX<>'' 
					then dbo.cvfn_StandardPhone(ss.CFAX) 
				else NULL 
			end
       ,Email=case when ss.CEMAIL<>'' then ss.CEMAIL else NULL end
       
       /* NO ADDRESS INFORMATION FOR CONTACT */
       --,Address
       --,AddressAdditional
       --,City
       --,State
       --,Country
       --,Zip
            
       ,Notes='SM Service Site Contact'
       --,UniqueAttchID
		
		--UD Fields
		--,udConvertedYN='Y'
		,udSTOContractID=ss.SMCONTACTID
		
--declare @ContactGroup bGroup set @ContactGroup=1	
--SELECT *
FROM CV_TL_Source_SM.dbo.SERVICESITE_CONTACTS ss
LEFT JOIN vHQContact hc
	ON hc.ContactGroup=@ContactGroup AND hc.udSTOContactID=ss.SMCONTACTID
WHERE hc.udSTOContactID IS NULL
ORDER BY hc.ContactGroup, ss.SMCONTACTID;


SET IDENTITY_INSERT vHQContact OFF
ALTER TABLE vHQContact CHECK CONSTRAINT ALL;
ALTER TABLE vHQContact ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @ContactGroup bGroup set @ContactGroup=1	
SELECT COUNT(*) FROM vHQContact 
WHERE ContactGroup=@ContactGroup
	AND Notes='SM Service Site Contact';

SELECT * FROM vHQContact 
WHERE ContactGroup=@ContactGroup
	AND Notes='SM Service Site Contact';

/** DATA REVIEW 
--declare @ContactGroup bGroup set @ContactGroup=	
select * from vHQContact where ContactGroup=@ContactGroup;

select distinct Address_Type from CV_TL_Source.dbo.ABM_MASTER__COMPANY_PERSON_ADDRESS

--Person business add
--Other address
--Street address
--Remittance address
--Shipping address

select Address_Type, COUNT(*) 
from CV_TL_Source.dbo.ABM_MASTER__COMPANY_PERSON_ADDRESS
group by Address_Type

select * from CV_TL_Source.dbo.ABM_MASTER__PERSON where Person_Name<>''
select * from CV_TL_Source.dbo.ABM_MASTER__COMPANY
select * from CV_TL_Source.dbo.ABM_MASTER__COMPANY_PERSON_ADDRESS
select * from CV_TL_Source.dbo.ABM_MASTER__CONTACT
**/
GO
