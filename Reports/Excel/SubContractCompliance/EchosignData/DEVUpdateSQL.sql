use Viewpoint
go

--select * from [MCK_INTEGRATION].dbo.[EchosignDataSource]

DISABLE TRIGGER [dbo].[mcktmckbSLHDSLAdmin_U]
ON Viewpoint.dbo.bSLHD
go

update 
	Viewpoint.dbo.SLHD 
set 
	udDocStatus=null
,	udLastStatusChgDate=null
,	udLastStatusChgBy=null
where
	udLastStatusChgBy in ('INITIALIZATION','ECHOSIGN','MCKINSTRY\billo','CGC')
or  udLastStatusChgBy  like '%(ES)%'
go

use MCK_INTEGRATION
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='lwospProcessEchosign2' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE')
begin
	print 'DROP PROCEDURE [dbo].[lwospProcessEchosign2]'
	drop PROCEDURE [dbo].[lwospProcessEchosign2] 
end
go

print 'CREATE PROCEDURE  [dbo].[lwospProcessEchosign2]'
go

create procedure lwospProcessEchosign2
(
	@paramSL  varchar(30) =null
,	@doUpdates	int=0
)
as

set nocount on
/*
2015.08.13 - LWO - Created
Routing to perform initial population of the new udDocStatus fields on the Subcontract records in Viewpoint.
Source is a report download from Echosign that is used to determine the current status to be recorded in Viewpoint.

The process rus for each distinct Subcontract defined in the source and then selects the most recent activity for 
population into Viewpoint.

Exchosign Status Values
In Process
Completed
Cancelled

Viewpoint udDocStatus Values
DatabaseValue	DisplayValue
1	1-Pending
2	2-Sent to Subcontractor
3	3-In Negotiation
4	4-Awaiting McKinstry Signature
5	5-Fully Executed

Echosign "Completed" = Viewpoint "5-Fully Executed"
Echosign "In Process" or "Cancelled" with a next recipient address including "@mckinstry.com" = Viewpoint "4-Awaiting McKinstry Signature"
Echosign "In Process" or "Cancelled" with a next recipient address somthing other than "@mckinstry.com" = Viewpoint "2-Sent to Subcontractor"

Selects source data from [MCKTESTSQL04\VIEWPOINT].[MCK_INTEGRATION].[dbo].[EchosignData_Scrubbed] 
via linked server connection so this can run from any of our Viewpoint servers but then interacts with Viewpoint data via
local server cross database syntax (e.g. Viewpoint.dbo.SLHD).

This approach should allow this to be run on MCKTESTSQL04\VIEWPOINT, VPSTAGINGAG\VIEWPOINT and VIEWPOINTAG\VIEWPOINT without modification (assuming the 
MCKTESTSQL04\VIEWPOINT linked server definition is present.

Inputs:
	@paramSL	varchar(30)  -- Optional Subcontract number to process only a single Subcontract.  Pass in "null" to run all source data.
	@doUpdates	int=0
*/

declare eccur cursor for
select distinct
	/*ContractNumber + '-' +  */ ltrim(rtrim(SubcontractNumber)) as SL, count(*)
from 
	[MCKTESTSQL04\VIEWPOINT].[MCK_INTEGRATION].[dbo].[EchosignDataSource] 
where 
	(SubcontractNumber is not null and ltrim(rtrim(SubcontractNumber)) <> '' and ltrim(rtrim(SubcontractNumber)) <> 'MISSING')
and (ChangeOrder is null)
and Target='SLHD'
and (ltrim(rtrim(SubcontractNumber))=ltrim(rtrim(@paramSL)) or @paramSL is null)
group by 
	ContractNumber, SubcontractNumber
order by 1
for read only

--select * from Viewpoint.dbo.SLHD where SL='100106-001001'

declare @rcnt int
declare @AgreementNumber varchar(30)
declare @RecordCount	int

declare @VP_AgreementNumber varchar(30)
declare @VP_SLCo int
declare @VP_SLChangeOrderCount int
declare @AgreementValid	char(1)


declare @AgreementStatus		varchar(50)
declare @LastTransactionDate	datetime
declare @SenderName				varchar(50)
declare @SenderEmail			varchar(50)
declare @NextRecipientEmail		varchar(50)

declare @vpSLDocStatus			varchar(30)	

/*
DatabaseValue	DisplayValue
1	1-Pending
2	2-Sent to Subcontractor
3	3-In Negotiation
4	4-Awaiting McKinstry Signature
5	5-Fully Executed
*/	

set @rcnt=0

print 
	cast('Rec#' as char(10))
+	cast('Valid' as char(10))
+	cast('SLCo' as char(10))
+	cast('Agreement #' as char(32))
+	cast('COCount' as char(8))
+	cast('Count' as char(10))

print replicate('-',75)

open eccur
fetch eccur into @AgreementNumber, @RecordCount

while @@FETCH_STATUS=0
begin
	select @rcnt=@rcnt+1

	select @VP_SLCo=SLCo, @VP_AgreementNumber=SL from Viewpoint.dbo.SLHD where SLCo < 100 and ( ltrim(rtrim(SL))=@AgreementNumber or ltrim(rtrim(udCGCTableID))=@AgreementNumber )
	select @VP_SLChangeOrderCount=count(*) from Viewpoint.dbo.PMSubcontractCO where SLCo=@VP_SLCo and SL=@VP_AgreementNumber

	if @VP_SLCo is not null set @AgreementValid='Y' else set @AgreementValid='N' 
	

	print 
		cast(@rcnt as char(10))
	+	cast(@AgreementValid as char(10))
	+	cast(coalesce(@VP_SLCo,'') as char(10))
	+	cast(coalesce(@VP_AgreementNumber,@AgreementNumber) as char(32))
	+	cast(coalesce(@VP_SLChangeOrderCount,0) as char(8))
	+	cast(coalesce(@RecordCount,0) as char(10))

	if @AgreementValid='Y'
	begin
		
		with mostrecent as 
		(
			select top 1
				*
			from
				[MCKTESTSQL04\VIEWPOINT].[MCK_INTEGRATION].[dbo].[EchosignDataSource]
			where
				/*ltrim(rtrim(ContractNumber)) + '-' +  */ ltrim(rtrim(SubcontractNumber)) = ltrim(rtrim(@AgreementNumber))
			order by 
				CreatedDate desc
		)
		select 
			@AgreementStatus=t1.AgreementStatus
		,	@LastTransactionDate=t1.CreatedDate
		,	@SenderName=t1.SenderName				
		--,	@SenderEmail=t1.SenderEmail			
		,	@NextRecipientEmail=t1.NextRecipientRole
		from
			mostrecent t1 

/*
DatabaseValue	DisplayValue
1	1-Pending
2	2-Sent to Subcontractor
3	3-In Negotiation
4	4-Awaiting McKinstry Signature
5	5-Fully Executed
*/	
		set @vpSLDocStatus='1'

		if ltrim(rtrim(@AgreementStatus))='Completed'
			select @vpSLDocStatus='5'

		if ltrim(rtrim(@AgreementStatus)) in ('In Process','Cancelled')
		begin
			if lower(@NextRecipientEmail) like '%mckinstry.com%'
				select @vpSLDocStatus='4'
			else
				select @vpSLDocStatus='2'
		end
			
		print
			cast('' as char(10))
		+	cast(coalesce(@AgreementStatus,'') + '=' + coalesce(@vpSLDocStatus,'') as char(20))
		--+   cast(coalesce(@vpSLDocStatus,'') as char(10))
		+	coalesce(cast(@LastTransactionDate as char(20)),cast('' as char(20)))
		--+	cast(coalesce(@SenderName,'') as char(20))
		--+	cast(coalesce(@SenderEmail,'') as char(20))
		+	cast(coalesce(@NextRecipientEmail,'') as char(50))

		if @doUpdates<>0
		begin
			update Viewpoint.dbo.SLHD set udDocStatus=@vpSLDocStatus, udLastStatusChgDate=coalesce(@LastTransactionDate,getdate()), udLastStatusChgBy=coalesce(ltrim(rtrim(@SenderName)) + ' (ES)','ECHOSIGN') where SLCo=@VP_SLCo and SL=@VP_AgreementNumber
		end

		print ''
	end
	else
	begin
		print 
			cast('' as char(10))
		+	coalesce(@AgreementNumber,'')
		+	' [INVALID: No Action Taken]'

		print ''
	end


		select 
			@AgreementNumber=null
		,	@RecordCount=null
		,	@VP_SLCo=null
		,   @VP_AgreementNumber=null
		,	@VP_SLChangeOrderCount=null
		,	@AgreementValid=null
		,	@AgreementStatus=null
		,	@LastTransactionDate=null	
		,	@SenderName=null				
		,	@SenderEmail=null			
		,	@NextRecipientEmail=null	
		,	@vpSLDocStatus=null

	fetch eccur into @AgreementNumber, @RecordCount
end

close eccur
deallocate eccur
go

update [EchosignDataSource] set ChangeOrder=null where ltrim(rtrim(cast(ChangeOrder as varchar(50))))=''

update [EchosignDataSource] set CO=ChangeOrder
go


lwospProcessEchosign2 @paramSL=null, @doUpdates=1 --'10009-001001'
go

use Viewpoint
go

ENABLE TRIGGER [dbo].[mcktmckbSLHDSLAdmin_U]
ON Viewpoint.dbo.bSLHD
go

--update EchosignDataSource set CO=left(CO,charindex('(',CO)) where charindex('(',CO) > 0 and CO is not null 

--update EchosignDataSource set CO=replace(CO,'(','')
--update EchosignDataSource set CO=replace(CO,' ','')
--update EchosignDataSource set CO=replace(CO,'CO','')
--update EchosignDataSource set CO=replace(CO,'revised','')

--update EchosignDataSource set CO=replace(CO,'REV','')
--update EchosignDataSource set CO=replace(CO,'rev','')
--update EchosignDataSource set CO=replace(CO,'REVISED','')
--update EchosignDataSource set CO=replace(CO,'.docx','')
--update EchosignDataSource set CO=replace(CO,'CA','')
--update EchosignDataSource set CO=replace(CO,'A','')
--update EchosignDataSource set CO=replace(CO,'CA','')
--update EchosignDataSource set CO=replace(CO,'ISED','')

--update EchosignDataSource set CO=null where ltrim(rtrim(CO))=''

--select ChangeOrder,CO from EchosignDataSource where CO is not null 

use Viewpoint
go

DISABLE TRIGGER [dbo].[mcktvPMSubcontractCO_U]
ON Viewpoint.dbo.vPMSubcontractCO
go

update 
	Viewpoint.dbo.PMSubcontractCO
set 
	udDocStatus=null
,	udLastStatusChgDate=null
,	udLastStatusChgBy=null
where
	udLastStatusChgBy in ('INITIALIZATION','ECHOSIGN','MCKINSTRY\billo','CGC')
or  udLastStatusChgBy  like '%(ES)%'
--	udLastStatusChgBy='ECHOSIGN'
go

use MCK_INTEGRATION
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='lwospProcessEchosign3' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE')
begin
	print 'DROP PROCEDURE [dbo].[lwospProcessEchosign3]'
	drop PROCEDURE [dbo].[lwospProcessEchosign3] 
end
go

print 'CREATE PROCEDURE  [dbo].[lwospProcessEchosign3]'
go

create procedure lwospProcessEchosign3
(
	@paramSL  varchar(30) =null
,	@doUpdates	int=0
)
as

set nocount on

/*
2015.08.13 - LWO - Created
Routing to perform initial population of the new udDocStatus fields on the Subcontract records in Viewpoint.
Source is a report download from Echosign that is used to determine the current status to be recorded in Viewpoint.

The process rus for each distinct Subcontract defined in the source and then selects the most recent activity for 
population into Viewpoint.

Exchosign Status Values
In Process
Completed
Cancelled

Viewpoint udDocStatus Values
DatabaseValue	DisplayValue
1	1-Pending
2	2-Sent to Subcontractor
3	3-In Negotiation
4	4-Awaiting McKinstry Signature
5	5-Fully Executed

Echosign "Completed" = Viewpoint "5-Fully Executed"
Echosign "In Process" or "Cancelled" with a next recipient address including "@mckinstry.com" = Viewpoint "4-Awaiting McKinstry Signature"
Echosign "In Process" or "Cancelled" with a next recipient address somthing other than "@mckinstry.com" = Viewpoint "2-Sent to Subcontractor"

Selects source data from [MCKTESTSQL04\VIEWPOINT].[MCK_INTEGRATION].[dbo].[EchosignData_Scrubbed] 
via linked server connection so this can run from any of our Viewpoint servers but then interacts with Viewpoint data via
local server cross database syntax (e.g. Viewpoint.dbo.SLHD).

This approach should allow this to be run on MCKTESTSQL04\VIEWPOINT, VPSTAGINGAG\VIEWPOINT and VIEWPOINTAG\VIEWPOINT without modification (assuming the 
MCKTESTSQL04\VIEWPOINT linked server definition is present.

Inputs:
	@paramSL	varchar(30)  -- Optional Subcontract number to process only a single Subcontract.  Pass in "null" to run all source data.
	@doUpdates	int=0
*/

declare eccur cursor for
select distinct
	/* ContractNumber + '-' +  */ ltrim(rtrim(SubcontractNumber)) as SL, CO, count(*)
from 
	[MCKTESTSQL04\VIEWPOINT].[MCK_INTEGRATION].[dbo].[EchosignDataSource] 
where 
	(SubcontractNumber is not null and ltrim(rtrim(SubcontractNumber)) <> '' and ltrim(rtrim(SubcontractNumber)) <> 'MISSING')
and (ChangeOrder is not null)
and Target='SLCO'
--and (ltrim(rtrim(SubcontractNumber))=ltrim(rtrim(@paramSL)) or @paramSL is null)
group by 
	ContractNumber, SubcontractNumber, CO
order by 1
for read only

--select * from Viewpoint.dbo.SLHD where SL='100106-001001'

declare @rcnt int
declare @AgreementNumber varchar(30)
declare @ChangeOrderNumber varchar(30)
declare @RecordCount	int

declare @VP_AgreementNumber varchar(30)
declare @VP_SLCo int
declare @VP_ChangeOrderNumber varchar(30)
declare @VP_SLChangeOrderCount int
declare @AgreementValid	char(1)


declare @AgreementStatus		varchar(50)
declare @LastTransactionDate	datetime
declare @SenderName				varchar(50)
declare @SenderEmail			varchar(50)
declare @NextRecipientEmail		varchar(50)

declare @vpSLDocStatus			varchar(30)	

/*
DatabaseValue	DisplayValue
1	1-Pending
2	2-Sent to Subcontractor
3	3-In Negotiation
4	4-Awaiting McKinstry Signature
5	5-Fully Executed
*/	

set @rcnt=0

print 
	cast('Rec#' as char(10))
+	cast('Valid' as char(10))
+	cast('SLCo' as char(10))
+	cast('Agreement #' as char(32))
+	cast('CO #' as char(10))
+	cast('CO Count' as char(10))
+	cast('Count' as char(10))

print replicate('-',75)

open eccur
fetch eccur into @AgreementNumber, @ChangeOrderNumber, @RecordCount

while @@FETCH_STATUS=0
begin
	select @rcnt=@rcnt+1

	
	select @VP_SLCo=co.SLCo, @VP_AgreementNumber=co.SL, @VP_ChangeOrderNumber=co.SubCO 
	from 
		Viewpoint.dbo.PMSubcontractCO co join Viewpoint.dbo.SLHD sl on co.SLCo=sl.SLCo and co.SL=sl.SL 
	where 
		co.SLCo < 100 and ( ltrim(rtrim(co.SL))=@AgreementNumber or ltrim(rtrim(sl.udCGCTableID))=@AgreementNumber ) and ltrim(rtrim(co.SubCO))=ltrim(rtrim(@ChangeOrderNumber))
	
	select @VP_SLChangeOrderCount=count(*) from Viewpoint.dbo.PMSubcontractCO where SLCo=@VP_SLCo and SL=@VP_AgreementNumber

	if @VP_SLCo is not null set @AgreementValid='Y' else set @AgreementValid='N' 
	
	print 
		cast(@rcnt as char(10))
	+	cast(@AgreementValid as char(10))
	+	cast(coalesce(@VP_SLCo,'') as char(10))
	+	cast(coalesce(@VP_AgreementNumber,@AgreementNumber) as char(32))
	+	cast(coalesce(@VP_ChangeOrderNumber,@ChangeOrderNumber) as char(10))
	+	cast(coalesce(@VP_SLChangeOrderCount,0) as char(8))
	+	cast(coalesce(@RecordCount,0) as char(10))

	if @AgreementValid='Y'
	begin
		
		with mostrecent as 
		(
			select top 1
				*
			from
				[MCKTESTSQL04\VIEWPOINT].[MCK_INTEGRATION].[dbo].[EchosignDataSource]
			where 
				/* ltrim(rtrim(ContractNumber)) + '-' +  */ ltrim(rtrim(SubcontractNumber)) = ltrim(rtrim(@AgreementNumber))
			and ltrim(rtrim(CO)) = ltrim(rtrim(@ChangeOrderNumber))
			order by 
				CreatedDate desc
		)
		select 
			@AgreementStatus=t1.AgreementStatus
		,	@LastTransactionDate=t1.CreatedDate
		,	@SenderName=t1.SenderName				
		,	@NextRecipientEmail=t1.NextRecipientRole		
		from
			mostrecent t1 

/*
DatabaseValue	DisplayValue
1	1-Pending
2	2-Sent to Subcontractor
3	3-In Negotiation
4	4-Awaiting McKinstry Signature
5	5-Fully Executed
*/	
		set @vpSLDocStatus='1'

		if ltrim(rtrim(@AgreementStatus))='Completed'
			select @vpSLDocStatus='5'

		if ltrim(rtrim(@AgreementStatus)) in ('In Process','Cancelled')
		begin
			if lower(@NextRecipientEmail) like '%mckinstry.com%'
				select @vpSLDocStatus='4'
			else
				select @vpSLDocStatus='2'
		end
			
		print
			cast('' as char(10))
		+	cast(coalesce(@AgreementStatus,'') + '=' + coalesce(@vpSLDocStatus,'') as char(20))
		--+   cast(coalesce(@vpSLDocStatus,'') as char(10))
		+	coalesce(cast(@LastTransactionDate as char(20)),cast('' as char(20)))
		--+	cast(coalesce(@SenderName,'') as char(20))
		--+	cast(coalesce(@SenderEmail,'') as char(20))
		+	cast(coalesce(@NextRecipientEmail,'') as char(50))

		if @doUpdates<>0
		begin
			update Viewpoint.dbo.PMSubcontractCO set udDocStatus=@vpSLDocStatus, udLastStatusChgDate=coalesce(@LastTransactionDate,getdate()), udLastStatusChgBy=coalesce(ltrim(rtrim(@SenderName)) + ' (ES)','ECHOSIGN') 
			where SLCo=@VP_SLCo and SL=@VP_AgreementNumber and SubCO=@VP_ChangeOrderNumber
		end

		print ''
	end
	else
	begin
		print 
			cast('' as char(10))
		+	coalesce(@AgreementNumber,'') + ' - CO: '
		+	coalesce(@ChangeOrderNumber,'')
		+	' [INVALID: No Action Taken]'
		
		print ''
	end


		select 
			@AgreementNumber=null
		,	@RecordCount=null
		,	@VP_SLCo=null
		,   @VP_AgreementNumber=null
		,	@VP_ChangeOrderNumber=null
		,	@VP_SLChangeOrderCount=null
		,	@AgreementValid=null
		,	@AgreementStatus=null
		,	@LastTransactionDate=null	
		,	@SenderName=null				
		,	@SenderEmail=null			
		,	@NextRecipientEmail=null	
		,	@vpSLDocStatus=null

	fetch eccur into @AgreementNumber, @ChangeOrderNumber, @RecordCount
end

close eccur
deallocate eccur
go

lwospProcessEchosign3 @paramSL=null, @doUpdates=1 --'10009-001001'
go

use Viewpoint
go

ENABLE  TRIGGER [dbo].[mcktvPMSubcontractCO_U]
ON Viewpoint.dbo.vPMSubcontractCO
go


use Viewpoint
go

/*
DatabaseValue	DisplayValue
1	1-Pending
2	2-Sent to Subcontractor
3	3-In Negotiation
4	4-Awaiting McKinstry Signature
5	5-Fully Executed
*/	

DISABLE TRIGGER [dbo].[mcktmckbSLHDSLAdmin_U]
ON Viewpoint.dbo.bSLHD
go

--Update udDocStatus to 5	5-Fully Executed
--select SLCo, SL, udCGCTable, udCGCTableID, OrigDate, udDocStatus, udLastStatusChgBy, udLastStatusChgDate 
--from SLHD 
--where udDocStatus is null and OrigDate < '11/3/2014'
--order by OrigDate
UPDATE SLHD set udDocStatus=5, udLastStatusChgBy='CGC', udLastStatusChgDate=OrigDate
where udDocStatus is null and  OrigDate < '11/3/2014'
go

--Update udDocStatus to 1	1-Pending
--select SLCo, SL, udCGCTable, udCGCTableID, OrigDate, udDocStatus, udLastStatusChgBy, udLastStatusChgDate 
--from SLHD 
--where udDocStatus is null and OrigDate >= '11/3/2014'
--order by OrigDate
UPDATE SLHD set udDocStatus=1, udLastStatusChgBy='CGC', udLastStatusChgDate=OrigDate
where udDocStatus is null and (OrigDate >= '11/3/2014' or OrigDate is null)
go

ENABLE TRIGGER [dbo].[mcktmckbSLHDSLAdmin_U]
ON Viewpoint.dbo.bSLHD
go

DISABLE TRIGGER [dbo].[mcktvPMSubcontractCO_U]
ON Viewpoint.dbo.vPMSubcontractCO
go

--Update udDocStatus to 5	5-Fully Executed
--select SLCo, SL, SubCO, Date, udDocStatus, udLastStatusChgBy, udLastStatusChgDate 
--from Viewpoint.dbo.PMSubcontractCO
--where udDocStatus is null and Date < '11/3/2014'
update Viewpoint.dbo.PMSubcontractCO set udDocStatus=5, udLastStatusChgBy='CGC', udLastStatusChgDate=Date
where udDocStatus is null and Date < '11/3/2014'
go

--Update udDocStatus to 1	1-Pending
--select SLCo, SL, SubCO, Date, udDocStatus, udLastStatusChgBy, udLastStatusChgDate 
--from Viewpoint.dbo.PMSubcontractCO
--where udDocStatus is null and Date >= '11/3/2014'
update Viewpoint.dbo.PMSubcontractCO set udDocStatus=1, udLastStatusChgBy='CGC', udLastStatusChgDate=Date
where udDocStatus is null and (Date >= '11/3/2014' or Date is null)
go

ENABLE TRIGGER [dbo].[mcktvPMSubcontractCO_U]
ON Viewpoint.dbo.vPMSubcontractCO
go


--select * from Viewpoint.dbo.SLHD where udLastStatusChgBy like 'E%'
--select * from Viewpoint.dbo.vPMSubcontractCO where udLastStatusChgBy like 'E%'
--select * from Viewpoint.dbo.SLHD where udLastStatusChgBy like 'I%'
--select * from Viewpoint.dbo.vPMSubcontractCO where udLastStatusChgBy like 'I%'
--go

--select udDocStatus,count(*) from Viewpoint.dbo.SLHD group by udDocStatus
--select udDocStatus,count(*) from Viewpoint.dbo.vPMSubcontractCO group by udDocStatus


--select * from HQAD

--select * from sysobjects where upper(name) like '%AUD%' and type in ('U','V') order by name

--select * from PMSL
--select top 100 * from brvHQAuditDetail where ViewName='SLHD'

--select top 100 * from HQMA where TableName='bSLHD'

--select top 100 * from brvHQAuditDetail where ViewName = 'SLHD' and RecType='A' and KeyString='SL:100115-001008'
--select top 100 * from brvHQAuditDetail where ViewName = 'PMSubcontractCO'

--select datediff(day,slhd.OrigDate,audit.DateTime) as Delta,   slhd.OrigDate, audit.DateTime, audit.UserName, slhd.* from SLHD slhd left join brvHQAuditDetail audit on audit.RecType='A' and slhd.SLCo=audit.Co and 'SL:' + slhd.SL = audit.KeyString --and KeyString='SL:100115-001008'--where slhd.udDocStatus is null
