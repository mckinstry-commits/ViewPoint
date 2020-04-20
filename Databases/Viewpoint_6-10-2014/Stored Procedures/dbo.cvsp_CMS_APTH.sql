SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE proc [dbo].[cvsp_CMS_APTH] 
	( @fromco1 smallint
	, @fromco2 smallint
	, @fromco3 smallint
	, @toco smallint
	, @errmsg varchar(1000) output
	, @rowcount bigint output
	) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Transaction Header
	Created:	10.12.09
	Created by:	JJH
	Revisions:	1.	10/25/2012 BTC - Add Vendor cross reference & weed out headers with no detail.
				2.  01/18/2013 MTG – change criteria for flaggin for 1099 based on value in APVM
				3.	02/20/2014 AEL - Added reference to Job Xref for McKinstry.
*/

set @errmsg='';
set @rowcount=0;

--Defaults from HQCO
declare @VendorGroup tinyint
select @VendorGroup=VendorGroup from bHQCO where HQCo=@toco;

--Defaults from APCO
declare @CMAcct int
select @CMAcct=CMAcct from bAPCO where APCo=@toco;


ALTER Table bAPTH disable trigger all;

--delete trans
begin tran
delete bAPTH where APCo=@toco
	--and udConv = 'Y';
commit tran

-- add new trans
BEGIN TRY
BEGIN TRAN


insert bAPTH (APCo, APTrans,Mth,Vendor,VendorGroup,APRef, InvDate,DueDate, InvTotal,
PayMethod,CMCo,CMAcct, PrePaidYN,PrePaidProcYN,PrePaidMth, PrePaidDate,V1099YN,PayOverrideYN,OpenYN,BatchId,
Purge,InPayControl,SeparatePayYN,ChkRev,udRetgInvYN, PrePaidChk, PrePaidSeq, Description, udPaidAmt, udYSN,
udSource,udConv,udCGCTable,udCGCTableID)

select APCo=@toco
	,APTrans=h.udAPTrans
		--convert(nvarchar(max),h.PAYMENTSELNO) + convert(nvarchar(max),h.RECORDCODE) --if this gets changed 
	-- the cvsp_CMS_APTD_Rounding procedure will need to have a modification as well.
	,Mth=h.udMth
		--substring(convert(nvarchar(max),h.JOURNALDATE),5,2) + '/01/' +  substring(convert(nvarchar(max),h.JOURNALDATE),1,4)
	,Vendor=xv.NewVendorID 
	,VendorGroup=@VendorGroup
	,APRef=h.INVOICE
	,InvDate=substring(convert(nvarchar(max),h.INVOICEDATE),5,2) + '/' +  substring(convert(nvarchar(max),h.INVOICEDATE),7,2) 
				+ '/' + substring(convert(nvarchar(max),INVOICEDATE),1,4)
	,DueDate=substring(convert(nvarchar(max),h.DUEDATE),5,2) + '/' +  substring(convert(nvarchar(max),h.DUEDATE),7,2) 
				+ '/' + substring(convert(nvarchar(max),DUEDATE),1,4)
	,InvTotal=h.GROSSAMT
	,PayMethod='C'
	,CMCo=@toco
	,CMAcct=@CMAcct
	,PrePaidYN='N'
	,PrePaidProcYN='N'
	,PrePaidMth=null
	,PrePaidDate=null
	,V1099YN=Case when APVM.[V1099YN]='Y' then 'Y' else 'N' end--'N'
	,PayOverrideYN='N'
	,OpenYN=case when h.CHECKNUMBER<>0 then 'N' else 'Y' end
	,BatchId=0
	,Purge='N'
	,InPayControl='N'
	,SeperatePayYN='N'
	,ChkRev=CASE when h.PAIDCODE=3 then 'Y' else 'N' end
	,udRetgInvYN=h.RETNINVOICE
	,PrePaidChk=null
	,PrePaidSeq=null
	,Description = h.INVDESC
	,udPaidAmt=h.PARTPAYAMTCUR
	,udYSN = h.PAYMENTSELNO
	,udSource ='APTH'
	, udConv='Y'
	,udCGCTable='APTOPC'
	,udCGCTableID=h.APTOPCID
from CV_CMS_SOURCE.dbo.APTOPC h

join (select distinct COMPANYNUMBER, VENDORNUMBER, PAYMENTSELNO, RECORDCODE -- Weed out headers with no detail
	  from CV_CMS_SOURCE.dbo.APTOPD) pd
	  on pd.COMPANYNUMBER = h.COMPANYNUMBER 
	  and pd.VENDORNUMBER = h.VENDORNUMBER 
	  and pd.PAYMENTSELNO = h.PAYMENTSELNO
	  and pd.RECORDCODE   = h.RECORDCODE

left join Viewpoint.dbo.budxrefAPVendor xv
	on xv.Company        = @VendorGroup
	and xv.OldVendorID   = h.VENDORNUMBER 
	and xv.CGCVendorType = 'V'

JOIN Viewpoint.dbo.bAPVM APVM 
	on xv.VendorGroup  = APVM.VendorGroup 
	and xv.NewVendorID = APVM.Vendor
	
JOIN budxrefJCJobs j
  on j.COMPANYNUMBER = h.COMPANYNUMBER
 and j.JOBNUMBER = h.JOBNUMBER
 and j.SUBJOBNUMBER = h.SUBJOBNUMBER
 and j.DIVISIONNUMBER = h.DIVISIONNUMBER
 and j.VPJob is not null

where h.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3);


select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bAPTH enable trigger all;

return @@error





GO