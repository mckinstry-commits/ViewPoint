SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_MASTER_APVM] (@fromco smallint, @toco smallint, @errmsg varchar(1000) output, @rowcount bigint output) 
as




/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Vendor Master (APVM)
	Created:	4.2.09
	Created by:	Andrew Bynum
	Revisions:	1. JRE 08/07/09 - created proc & @toco, @fromco
				2. JJH 08/27/09 - Added contact/phone update after APVM insert
				3. BTC 05/10/12 - Added restriction by company to join for Contact update
				4. BTC 05/10/12 - Added restriction for VENDORLOCNO 0 to join for Contact update
				5. BTC 05/10/12 - Modified to use ABBREVIATION10 for Sort Name if it is available and unique.
				6. BTC 06/05/12 - Added Phone Number format mask to Phone and Fax numbers in APVM.
				7. BTC 06/05/12 - Removed COMPANYNUMBER from 'dup' query built to prevent duplication of sort names.
					Cannot have when Vendor Group is shared.
				8. BTC 10/25/12 - Modified SortName to account for duplications between shared Companies.
**/


set @errmsg=''
set @rowcount=0

-- get defaults from HQCO
declare @VendorGroup smallint, @TaxGroup smallint,@CustGroup smallint
select @VendorGroup=VendorGroup, @CustGroup=CustGroup,@TaxGroup=TaxGroup from bHQCO where HQCo=@toco


--get Customer Defaults
declare @defaultOverrideMinAmtYN varchar(1)
select @defaultOverrideMinAmtYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='OverrideMinAmtYN' and a.TableName='bAPVM';

declare @V1099Type varchar(5)
select @V1099Type=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='V1099Type' and a.TableName='bAPVM';


declare @V1099Box int
select @V1099Box=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='V1099Box' and a.TableName='bAPVM';




alter table bAPVM disable trigger all;

-- delete existing trans
BEGIN tran
alter table bPMFM NOCHECK Constraint FK_bPMFM_bAPVM;
alter table bPMMF NOCHECK Constraint FK_bPMMF_bAPVM;
alter table bPMSL NOCHECK Constraint FK_bPMSL_bAPVM;
alter table bPMOL NOCHECK Constraint FK_bPMOL_bAPVM;
alter table vPCQualifications NOCHECK Constraint FK_vPCQualifications_bAPVM
delete from bAPVM where VendorGroup=@VendorGroup
	and udConv = 'Y';
alter table vPCQualifications CHECK Constraint FK_vPCQualifications_bAPVM
alter table bPMOL CHECK Constraint FK_bPMOL_bAPVM;
alter table bPMSL CHECK Constraint FK_bPMSL_bAPVM;
alter table bPMMF CHECK Constraint FK_bPMMF_bAPVM;
alter table bPMFM CHECK Constraint FK_bPMFM_bAPVM;
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bAPVM (VendorGroup, Vendor, SortName, Name, Type, TempYN, Contact, Phone ,Fax ,EMail,
	URL, Address, City, State, Zip, Address2,
	Purge, CustGroup, Customer,TaxGroup,TaxCode,PayTerms,GLCo,V1099YN, V1099Type,V1099Box,
	TaxId,Prop,ActiveYN, PayMethod,EFT,RoutingId,
	BankAcct,AcctType,LastInvDate,AuditYN,Notes,AddnlInfo,AddendaTypeId,Reviewer,SeparatePayInvYN, 
	OverrideMinAmtYN, MasterVendor, APRefUnqOvr, UpdatePMYN, 
	udSource, udConv, udCGCTable, udCGCTableID, udSubcontractorYN, udCGCVendor )

select @VendorGroup
	,Vendor=x.NewVendorID -- E.VENDORNUMBER
	,SortName=upper(case
		when E.ABBREVIATION10='' then LEFT(LTRIM(RTRIM(E.NAME25)),15
			-len(LTRIM(RTRIM(convert(varchar(10),x.NewVendorID)))))+convert(varchar(10),x.NewVendorID)
		else left(ltrim(rtrim(E.ABBREVIATION10)), 15 - case
				when dup.ABBREVIATION10 is not null then LEN(ltrim(rtrim(convert(varchar(10), x.NewVendorID))))
				else 0 end)
			+ case
				when dup.ABBREVIATION10 IS not null then convert(varchar(10), x.NewVendorID) else '' end
		end)	
	,Name=rtrim(NAME25)
	,Type='R'
	,TempYN='N'
	,Contact=null
	,Phone=case
		when E.AREACODE=0 and E.PHONENO=0 then null
		else case 
			when E.AREACODE=0 then '(   ) '
			else '(' + RIGHT(space(3) + convert(varchar(3), E.AREACODE), 3) + ') '
			end
		+ case
			when E.PHONENO=0 then ''
			else SUBSTRING(convert(varchar(7), E.PHONENO), 1, 3) + '-'
				+ SUBSTRING(convert(varchar(7), E.PHONENO), 4, 4)
			end
		end
	,Fax=case
		when E.FAXAREACD=0 and E.FAXPHONENO=0 then null
		else case 
			when E.FAXAREACD=0 then '(   ) '
			else '(' + RIGHT(space(3) + convert(varchar(3), E.FAXAREACD), 3) + ') '
			end
		+ case
			when E.FAXPHONENO=0 then ''
			else SUBSTRING(convert(varchar(7), E.FAXPHONENO), 1, 3) + '-'
				+ SUBSTRING(convert(varchar(7), E.FAXPHONENO), 4, 4)
			end
		end
	,EMail=NULL --left(E.URLADDRESS,60)
	,URL=left(E.URLADDRESS,60)
	,Address=rtrim(E.ADDRESS25A) 
	,City=case when E.CITY18='' then null else rtrim(E.CITY18) end
	,State=case when E.STATECODE='' then null else rtrim(E.STATECODE) end
	,Zip=case when ZIPCODE='' then null else rtrim(E.ZIPCODE) end
	,Address2= NULL
	,Purge='N'
	,@CustGroup
	,Customer=null
	,@TaxGroup
	,TaxCode=null
		-- changed this on 7/15/2013  new codes not the same, don't have an xref CR
	,PayTerms='30'--case when E.TERMSCODE='' then null else + convert(varchar(2),E.TERMSCODE) end
	,GLCo=@toco
	,V1099YN=case when FORM1099REQ<>'' then 'Y' else 'N' end
	,V1099Type=@V1099Type
	,V1099Box=@V1099Box
	,TaxId=FEDIDNUMBER
	,Prop=null 
	,ActiveYN='Y'
	, PayMethod          = case when CREATEEFT = 'Y' then 'E' else 'C' end
	, EFT                = case when CREATEEFT='Y' and CREATEPRENOTE='N' then 'A' 
			                   when CREATEEFT='Y' and CREATEPRENOTE='Y' then 'P' else 'N'end
	, RoutingId         = BANKIDNO 
	, BankAcct          = EMPLBANKACCT 
	, AcctType         = case when CHKINGSVINGS='22' then 'C' when CHKINGSVINGS='32' then 'S' else null end
	, LastInvDate       = null
	, AuditYN           = 'Y'
	, Notes             = NULL
	, AddnlInfo         = rtrim(ADDRESS25B)
	, AddendaTypeId     = null
	, Reviewer          = null
	, SeparatePayInvYN  = PRTSEPCHKINV 
	, OverrideMinAmtYN  = @defaultOverrideMinAmtYN
	, MasterVendor      = null
	, APRefUnqOvr       = 0
	, UpdatePMYN        = 'Y'
	, udSource          = 'MASTER_APVM'
	, udConv            = 'Y'
	, udCGCTable        = 'APTVEN'
	, udCGCTableID      =  APTVENID
	, udSubcontractorYN = E.STDCOSTCODE
	, udGCGVendor       = E.VENDORNUMBER
	
from CV_CMS_SOURCE.dbo.APTVEN E with(nolock)

/* only bringing over certain Vendors, ideally only put converted Vendors into the xref 8/26/2013 CR */
join budxrefAPVendor x
	on /*x.Company=E.COMPANYNUMBER and*/ 
	x.OldVendorID=E.VENDORNUMBER 
	and x.CGCVendorType='V'
	
--left join (select COMPANYNUMBER, DIVISIONNUMBER, VENDORNUMBER, CONTRACTNAME, EMAILADDR, SEQUENCENO05
--		from CV_CMS_SOURCE.dbo.APTVCN with(nolock)
--		where SEQUENCENO05=1)
--		as C 
--	on C.COMPANYNUMBER=E.COMPANYNUMBER and C.DIVISIONNUMBER=E.DIVISIONNUMBER and C.VENDORNUMBER=E.VENDORNUMBER

left join (select upper(ltrim(rtrim(ABBREVIATION10))) as ABBREVIATION10
			, COUNT(1) as AbbCount
			from CV_CMS_SOURCE.dbo.APTVEN
			group by upper(ltrim(rtrim(ABBREVIATION10))) 
			having COUNT(1)>1) dup
	        on dup.ABBREVIATION10=upper(ltrim(rtrim(E.ABBREVIATION10)))		
	        
--where E.COMPANYNUMBER=@fromco;


select @rowcount=@@rowcount

----Updates Phone and contact information
update bAPVM
set Contact = b.CONTRACTNAME,
	Phone = case 
		    when bAPVM.Phone is NULL or bAPVM.Phone = '' 
		    then 
				case 
					when b.AREACODE = 0 and b.PHONENO <> 0 
					then '(   ) ' +
						substring(convert(varchar(7),b.PHONENO),1,3) + '-' + 
						substring(convert(varchar(7),b.PHONENO),4,4)
					when (b.AREACODE = 0 and b.PHONENO = 0) 
					then NULL 
				else '(' + right(space(3) + convert(varchar(3),b.AREACODE), 3) + ') '
				+ substring(convert(varchar(7),b.PHONENO),1,3) + '-'
				+ substring(convert(varchar(7),b.PHONENO),4,4) 
				end
			else bAPVM.Phone
			end	
			
from bAPVM 

join CV_CMS_SOURCE.dbo.APTVCN b 
	on bAPVM.Vendor = b.VENDORNUMBER 
	and b.COMPANYNUMBER=@fromco

where b.SEQUENCENO05 = 1 
	and b.VENDORLOCNO=0
	and bAPVM.VendorGroup=@VendorGroup;
	

--/*  this is on a per customer basis */		
update bAPVM
set V1099Box = case
when x.Type='M' then 6
when x.Type='O' then 3
when x.Type='R' then 1
when x.Type='T' then 2
when x.Type='Y' then 7 end

from bAPVM
join (select COMPANYNUMBER, VENDORNUMBER, Type= max(FORM1099REQ)  
			from CV_CMS_SOURCE.dbo.APTOPD 
			where FORM1099REQ <> ''
			Group by COMPANYNUMBER, VENDORNUMBER) 
		as x 
		on x.COMPANYNUMBER =@fromco and x.VENDORNUMBER=bAPVM.Vendor
where bAPVM.V1099YN = 'Y';	
	
	

select @rowcount=@rowcount+@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bAPVM enable trigger all;

return @@error

GO
