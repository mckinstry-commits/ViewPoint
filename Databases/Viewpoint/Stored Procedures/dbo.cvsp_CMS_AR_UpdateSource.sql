
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Update Source Columns 
	Created:	04.07.09
	Created by:	Viewpoint Technical Services - Jim Emery
	Revisions:	
		1. 12/16/09 CR - Added ITEMNUMBER to 2nd temp table, #id -
			 needed for Reily but not Quandel or WB so it is commented out.
		2. 06/29/10 JH - Added the update to the historical AR tables to standardize the code.
		3. 03/20/12 BBA - Added notes below and rem'd update statements out 
			with invalid columns.
		
					 
	Notes: Source field does not exist on CV_CMS_SOURCE.dbo.ARTOPC and
	CV_CMS_SOURCE.dbo.ARTOPD tables. Must add and populate field and then
	uncomment the fields from the section below that updates the Source field.
					 
**/


CREATE proc [dbo].[cvsp_CMS_AR_UpdateSource] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

set @errmsg='';
set @rowcount=0;

declare @JobFormat varchar(30), @PhaseFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob');
Set @PhaseFormat =  (Select InputMask from vDDDTc where Datatype = 'bPhase');


-- add new trans
BEGIN TRAN
BEGIN TRY

/* Creates Month Mth field and populates using JOURNALDATE.
 ARTCNS used to get Customer for JCCM */

/*
Alter Table ARTCSD add Mth smalldatetime;
Alter Table ARTOPC add Mth smalldatetime;
Alter Table ARTOPD add Mth smalldatetime;
*/
update CV_CMS_SOURCE.dbo.ARTCSD set Mth =
convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)+'/'+substring(convert(nvarchar(max),JOURNALDATE),5,2) +'/01'))
where JOURNALDATE <> 0

update CV_CMS_SOURCE.dbo.ARTOPC set Mth =
convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)+'/'+substring(convert(nvarchar(max),JOURNALDATE),5,2) +'/01'))
where JOURNALDATE <> 0  ;

update CV_CMS_SOURCE.dbo.ARTOPD set Mth =
convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)+'/'+substring(convert(nvarchar(max),JOURNALDATE),5,2) +'/01'))
where JOURNALDATE <> 0;



create table #ID
	(ARTOPCID		numeric(12,0)	null,
	COMPANYNUMBER	int				null,
	DIVISIONNUMBER	int				null,
	CUSTOMERNUMBER	int				null,
	JOBNUMBER		varchar(20)		null,
	SUBJOBNUMBER	varchar(10)		null,
	INVOICEDATE		varchar(10)		null,
	INVOICENO		varchar(20)		null,
	RECORDCODE		int				null,
	SEQUENCENO02	int				null,
	TRANSACTIONDATE	varchar(10)		null,
	CASHRCPTSDATE	varchar(10)		null)

insert into #ID
select ARTOPCID=Row_Number() Over(Partition by COMPANYNUMBER order by COMPANYNUMBER)
	, COMPANYNUMBER
	, DIVISIONNUMBER
	, CUSTOMERNUMBER
	, JOBNUMBER
	, SUBJOBNUMBER
	, INVOICEDATE
	, INVOICENO
	, RECORDCODE
	, SEQUENCENO02
	, TRANSACTIONDATE
	, CASHRCPTSDATE
from CV_CMS_SOURCE.dbo.ARTOPC
order by COMPANYNUMBER, DIVISIONNUMBER, CUSTOMERNUMBER, JOBNUMBER, SUBJOBNUMBER, INVOICEDATE, INVOICENO, RECORDCODE,SEQUENCENO02,
	TRANSACTIONDATE, CASHRCPTSDATE


update CV_CMS_SOURCE.dbo.ARTOPC set ARTOPCID=i.ARTOPCID
from CV_CMS_SOURCE.dbo.ARTOPC 

	join #ID i on CV_CMS_SOURCE.dbo.ARTOPC.COMPANYNUMBER=i.COMPANYNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPC.DIVISIONNUMBER=i.DIVISIONNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPC.CUSTOMERNUMBER=i.CUSTOMERNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPC.JOBNUMBER=i.JOBNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPC.SUBJOBNUMBER=i.SUBJOBNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPC.INVOICEDATE=i.INVOICEDATE
			and CV_CMS_SOURCE.dbo.ARTOPC.INVOICENO=i.INVOICENO
			and CV_CMS_SOURCE.dbo.ARTOPC.RECORDCODE=i.RECORDCODE
			and CV_CMS_SOURCE.dbo.ARTOPC.SEQUENCENO02=i.SEQUENCENO02
			and CV_CMS_SOURCE.dbo.ARTOPC.TRANSACTIONDATE=i.TRANSACTIONDATE
			and CV_CMS_SOURCE.dbo.ARTOPC.CASHRCPTSDATE=i.CASHRCPTSDATE
where CV_CMS_SOURCE.dbo.ARTOPC.ARTOPCID is null

-------------------------------------------------------------------------------------
create table #id
	(ARTOPDID		numeric(12,0)	null,
	COMPANYNUMBER	int				null,
	DIVISIONNUMBER	int				null,
	CUSTOMERNUMBER	int				null,
	JOBNUMBER		varchar(20)		null,
	SUBJOBNUMBER	varchar(10)		null,
	--ITEMNUMBER		varchar(15)		null,
	INVOICEDATE		varchar(10)		null,
	INVOICENO		varchar(20)		null,
	RECORDCODE		int				null,
	SEQUENCENO02	int				null,
	TRANSACTIONDATE	varchar(10)		null,
	CASHRCPTSDATE	varchar(10)		null)

insert into #id
select ARTOPDID=Row_Number() Over(Partition by COMPANYNUMBER order by COMPANYNUMBER)
	, COMPANYNUMBER
	, DIVISIONNUMBER
	, CUSTOMERNUMBER
	, JOBNUMBER
	, SUBJOBNUMBER
	--, ITEMNUMBER
	, INVOICEDATE
	, INVOICENO
	, RECORDCODE
	, SEQUENCENO02
	, TRANSACTIONDATE
	, CASHRCPTSDATE
from CV_CMS_SOURCE.dbo.ARTOPD
order by COMPANYNUMBER, DIVISIONNUMBER, CUSTOMERNUMBER, JOBNUMBER, SUBJOBNUMBER,-- ITEMNUMBER,
	INVOICEDATE, INVOICENO, RECORDCODE,SEQUENCENO02,TRANSACTIONDATE, CASHRCPTSDATE



update CV_CMS_SOURCE.dbo.ARTOPD set ARTOPDID=i.ARTOPDID
from CV_CMS_SOURCE.dbo.ARTOPD
	join #id i on CV_CMS_SOURCE.dbo.ARTOPD.COMPANYNUMBER=i.COMPANYNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPD.DIVISIONNUMBER=i.DIVISIONNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPD.CUSTOMERNUMBER=i.CUSTOMERNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPD.JOBNUMBER=i.JOBNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPD.SUBJOBNUMBER=i.SUBJOBNUMBER
			--and CV_CMS_SOURCE.dbo.ARTOPD.ITEMNUMBER=i.ITEMNUMBER
			and CV_CMS_SOURCE.dbo.ARTOPD.INVOICEDATE=i.INVOICEDATE
			and CV_CMS_SOURCE.dbo.ARTOPD.INVOICENO=i.INVOICENO
			and CV_CMS_SOURCE.dbo.ARTOPD.RECORDCODE=i.RECORDCODE
			and CV_CMS_SOURCE.dbo.ARTOPD.SEQUENCENO02=i.SEQUENCENO02
			and CV_CMS_SOURCE.dbo.ARTOPD.TRANSACTIONDATE=i.TRANSACTIONDATE
			and CV_CMS_SOURCE.dbo.ARTOPD.CASHRCPTSDATE=i.CASHRCPTSDATE
where CV_CMS_SOURCE.dbo.ARTOPD.ARTOPDID is null


-------------------------------------------------------------------------------------

update CV_CMS_SOURCE.dbo.ARTOPC set JOURNALDATE = TRANSACTIONDATE where JOURNALDATE = 0;

update CV_CMS_SOURCE.dbo.ARTOPD set udARTOPCID=C.ARTOPCID 
from CV_CMS_SOURCE.dbo.ARTOPD
	join CV_CMS_SOURCE.dbo.ARTOPC C on C.COMPANYNUMBER=ARTOPD.COMPANYNUMBER 
			and C.DIVISIONNUMBER=ARTOPD.DIVISIONNUMBER 
			and C.CUSTOMERNUMBER=ARTOPD.CUSTOMERNUMBER 
			and C.JOBNUMBER=ARTOPD.JOBNUMBER 
			and C.SUBJOBNUMBER=ARTOPD.SUBJOBNUMBER
			and C.INVOICEDATE=ARTOPD.INVOICEDATE 
			and C.INVOICENO=ARTOPD.INVOICENO
			and C.SEQUENCENO02=ARTOPD.SEQUENCENO02
where (udARTOPCID is null or udARTOPCID<>C.ARTOPCID);

select @rowcount=@@rowcount;


update CV_CMS_SOURCE.dbo.ARTOPD 
set udMth=convert(smalldatetime,(substring(convert(nvarchar(max),JOURNALDATE),1,4)+'/'
			+substring(convert(nvarchar(max),JOURNALDATE),5,2) +'/'+ '01')) 
   ,udContract=dbo.bfMuliPartFormat(RTRIM(JOBNUMBER),@JobFormat)
   ,udItem=case when CONTRACTNO not in (1,0,2) -- Added 2 for Reilly
				then space(16-datalength(rtrim(CONTRACTNO))) 
				+ rtrim(CONTRACTNO)
			when CONTRACTNO in (1,0,2) and ITEMNUMBER not in ('0','','001')  -- Added 2 for Reilly
				then space(16-datalength(rtrim(ITEMNUMBER))) + rtrim(ITEMNUMBER) 
			else space(15)+'1' end
where JOURNALDATE <> 0 ;


-- set the Contract Number and item for all other lines
update CV_CMS_SOURCE.dbo.ARTOPD 
set udContract=Line1Contract, udItem=Line1Item
from CV_CMS_SOURCE.dbo.ARTOPD
	join (select COMPANYNUMBER, DIVISIONNUMBER, CUSTOMERNUMBER, JOBNUMBER,
				SUBJOBNUMBER, JOURNALDATE, INVOICEDATE, INVOICENO,RECORDCODE,
				SEQUENCENO02, ARTOPDID,
				Line1Contract=udContract, Line1Item=udItem
			from CV_CMS_SOURCE.dbo.ARTOPD
			where SEQUENCENO05 = 1) 
			as D 
			on D.COMPANYNUMBER=ARTOPD.COMPANYNUMBER 
				and D.DIVISIONNUMBER=ARTOPD.DIVISIONNUMBER 
				and D.CUSTOMERNUMBER=ARTOPD.CUSTOMERNUMBER 
				and D.JOBNUMBER=ARTOPD.JOBNUMBER 
				and D.SUBJOBNUMBER=ARTOPD.SUBJOBNUMBER 
				and D.INVOICENO=ARTOPD.INVOICENO 
where SEQUENCENO05<>1 ;


--------


/* Remove duplicate records from ARTOPC */
/*
update CV_CMS_SOURCE.dbo.ARTOPC
set Source=case when CURRENTRPTPER IS not null then 'ARTOPC' else 'ARTHST' end;

update CV_CMS_SOURCE.dbo.ARTOPD
set Source=case when CURRENTRPTPER IS not null then 'ARTOPD' else 'ARTHSD' end
  , INVAMT=case when INVAMT is null then AAMPD else INVAMT end;
*/

update CV_CMS_SOURCE.dbo.ARTOPD 
set udPaidMth=convert(smalldatetime,(substring(convert(nvarchar(max),PAIDDATE),1,4)+'/'
		+substring(convert(nvarchar(max),PAIDDATE),5,2) +'/'+ '01')) 
where convert(nvarchar(max),PAIDDATE) <> '0' and convert(nvarchar(max),PAIDDATE)<>'';


update CV_CMS_SOURCE.dbo.ARTOPC 
set udPaidMth=convert(smalldatetime,(substring(convert(nvarchar(max),PAIDDATE),1,4)+'/'
		+substring(convert(nvarchar(max),PAIDDATE),5,2) +'/'+ '01')) 
where convert(nvarchar(max),PAIDDATE) <> '0' and convert(nvarchar(max),PAIDDATE)<>'';


--Update historical tables
--update ARTCSD set VDTJR = VDTCR where VDTJR = 0;
--update ARTCSD set VDTPD= VDTIN where VDTPD=0;



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

return @@error

GO
