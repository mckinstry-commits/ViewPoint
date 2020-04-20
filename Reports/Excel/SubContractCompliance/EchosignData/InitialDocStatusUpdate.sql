use MCK_INTEGRATION
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='lwospProcessEchosign' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE')
begin
	print 'DROP PROCEDURE [dbo].[lwospProcessEchosign]'
	drop PROCEDURE [dbo].[lwospProcessEchosign] 
end
go

print 'CREATE PROCEDURE  [dbo].[lwospProcessEchosign]'
go

create procedure lwospProcessEchosign
(
	@paramSL  varchar(30) =null
,	@doUpdates	int=0
)
as
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
select 
	ltrim(rtrim(AgreementNumber)), count(*)
from 
	[MCKTESTSQL04\VIEWPOINT].[MCK_INTEGRATION].[dbo].[EchosignData_Scrubbed] 
where 
	(AgreementNumber is not null and ltrim(rtrim(AgreementNumber)) <> '' and ltrim(rtrim(AgreementNumber)) <> 'MISSING')
and (ltrim(rtrim(AgreementNumber))=ltrim(rtrim(@paramSL)) or @paramSL is null)
group by 
	AgreementNumber
order by 1
for read only

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
	+	cast(@VP_SLCo as char(10))
	+	cast(coalesce(@VP_AgreementNumber,@AgreementNumber) as char(32))
	+	cast(@VP_SLChangeOrderCount as char(8))
	+	cast(@RecordCount as char(10))

	if @AgreementValid='Y'
	begin
		
		with mostrecent as 
		(
			select top 1
				*
			from
				[MCKTESTSQL04\VIEWPOINT].[MCK_INTEGRATION].[dbo].[EchosignData_Scrubbed]
			where 
				ltrim(rtrim(AgreementNumber)) = ltrim(rtrim(@AgreementNumber))
			order by 
				CreatedDate asc
		)
		select 
			@AgreementStatus=t1.AgreementStatus
		,	@LastTransactionDate=t1.LastTransactionDate	
		,	@SenderName=t1.SenderName				
		,	@SenderEmail=t1.SenderEmail			
		,	@NextRecipientEmail=t1.NextRecipientEmail		
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
			if @NextRecipientEmail like '%mckinstry.com%'
				select @vpSLDocStatus='4'
			else
				select @vpSLDocStatus='2'
		end
			
		print
			cast('' as char(10))
		+	cast(coalesce(@AgreementStatus,'') + '=' + coalesce(@vpSLDocStatus,'') as char(20))
		--+   cast(coalesce(@vpSLDocStatus,'') as char(10))
		+	cast(@LastTransactionDate as char(20))
		--+	cast(coalesce(@SenderName,'') as char(20))
		--+	cast(coalesce(@SenderEmail,'') as char(20))
		+	cast(coalesce(@NextRecipientEmail,'') as char(20))

		if @doUpdates<>0
		begin
			update Viewpoint.dbo.SLHD set udDocStatus=@vpSLDocStatus, udLastStatusChgDate=coalesce(@LastTransactionDate,getdate()), udLastStatusChgBy='ECHOSIGN' where SLCo=@VP_SLCo and SL=@VP_AgreementNumber
		end

		print ''
	end
	else
	begin
		print 
			cast('' as char(10))
		+	@AgreementNumber
		+	' INVALID: No Action Taken'

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

lwospProcessEchosign @paramSL=null, @doUpdates=0 --'10009-001001'
