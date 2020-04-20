--begin tran

--update 
--	SMWorkOrderScope
--set 
--	CallType=bu.CallType
--from 
--	SMWorkOrderScope_20141114_BU bu
--where 
--	SMWorkOrderScope.SMCo=bu.SMCo
--and SMWorkOrderScope.WorkOrder=bu.WorkOrder
--and SMWorkOrderScope.Scope=bu.Scope
--COMMIT TRAN

--select * from SMWorkOrderScope WHERE SMCo < 100 _20141114_BU

/*
begin tran
	delete SMWorkOrderScope where SMCo < 100

INSERT INTO [dbo].[vSMWorkOrderScope]
           ([SMCo]
           ,[WorkOrder]
           ,[Scope]
           ,[CallType]
           ,[WorkScope]
           ,[Description]
           ,[DueStartDate]
           ,[DueEndDate]
           ,[ServiceCenter]
           ,[Division]
           ,[Notes]
           ,[CustGroup]
           ,[BillToARCustomer]
           ,[RateTemplate]
           ,[ServiceItem]
           ,[SaleLocation]
           ,[IsComplete]
           ,[UniqueAttchID]
           ,[PriorityName]
           ,[IsTrackingWIP]
           ,[CustomerPO]
           ,[NotToExceed]
           ,[Phase]
           ,[PhaseGroup]
           ,[JCCo]
           ,[Job]
           ,[Agreement]
           ,[Revision]
           ,[PriceMethod]
           ,[Price]
           ,[Service]
           ,[UseAgreementRates]
           ,[TaxType]
           ,[TaxGroup]
           ,[TaxCode]
           ,[WorkOrderQuote]
           ,[TaxRate]
           ,[OnHold]
           ,[HoldReason]
           ,[FollowUpDate])
	select
			[SMCo]
           ,[WorkOrder]
           ,[Scope]
           ,[CallType]
           ,[WorkScope]
           ,[Description]
           ,[DueStartDate]
           ,[DueEndDate]
           ,[ServiceCenter]
           ,[Division]
           ,[Notes]
           ,[CustGroup]
           ,[BillToARCustomer]
           ,[RateTemplate]
           ,[ServiceItem]
           ,[SaleLocation]
           ,[IsComplete]
           ,[UniqueAttchID]
           ,[PriorityName]
           ,[IsTrackingWIP]
           ,[CustomerPO]
           ,[NotToExceed]
           ,[Phase]
           ,[PhaseGroup]
           ,[JCCo]
           ,[Job]
           ,[Agreement]
           ,[Revision]
           ,[PriceMethod]
           ,[Price]
           ,[Service]
           ,[UseAgreementRates]
           ,[TaxType]
           ,[TaxGroup]
           ,[TaxCode]
           ,[WorkOrderQuote]
           ,[TaxRate]
           ,[OnHold]
           ,[HoldReason]
           ,[FollowUpDate]
	from SMWorkOrderScope_20141114_BU where SMCo<100

COMMIT TRAN
*/

USE Viewpoint
GO

IF EXISTS ( SELECT 1 FROM sysobjects WHERE type='P' AND name='mspLWO_SMWO_ScopeCheck')
BEGIN
	PRINT 'DROP PROCEDURE mspLWO_SMWO_ScopeCheck'
	DROP PROCEDURE mspLWO_SMWO_ScopeCheck
END

PRINT 'CREATE PROCEDURE mspLWO_SMWO_ScopeCheck'
go

--Backup original table
--select * into SMWorkOrderScope_20141114_BU from SMWorkOrderScope
--go


CREATE PROCEDURE mspLWO_SMWO_ScopeCheck
(
	@Company	bCompany = null
,	@WorkOrder	bWO = null
,	@doSQL		int	= 0
)
as
/*
2014.11.14 - LWO - Created

Routine to update SM Work Orders with standard set of Scopes for both PM ( Job/Phase Code assignments )
and Break Fix ( GL assignment ).

Attempts to find and update existing records where possible, but will add records as needed to provide
missing scopes.

mspLWO_SMWO_ScopeCheck
	@Company=# (Optional - run for a specific company or all companies if left null [default])
,	@WorkOrder = ####### (Optional - run for a specific Work Order or all Work Orders if left null [default] )
,	@doSQL=# (Default=0 : Leave at default (or <> 1 to run simulation to see output before running.  Set to 1 to actual process the updates/inserts).3
go

*/
-- Only Open and New Workorders

-- TODO: For Break Fix - Don't add Service as new Scope, but rename HVAC to be Service. DONE [2014.11.14 - LWO]
--		 Update Plumbing to "Do Not Use" and dont add if missing. DONE [2014.11.14 - LWO]

set nocount on 

DECLARE wocur CURSOR FOR
SELECT
	wo.SMCo
,	wo.WorkOrder
,	CASE
		WHEN wo.Job IS NULL THEN 'B'
		WHEN LTRIM(RTRIM(wo.Job)) ='' THEN 'B'
		ELSE 'P'
	END AS WOType
,	wo.JCCo
,	wo.Job
FROM 
	dbo.SMWorkOrder wo
WHERE
	wo.SMCo<100
AND wo.WOStatus=0
--AND wo.Job IS NOT NULL 
--AND LTRIM(RTRIM(Job)) <> ''
AND (wo.SMCo = @Company OR @Company is NULL)
AND (wo.WorkOrder=@WorkOrder OR @WorkOrder is null)
ORDER BY
	wo.SMCo
,	wo.WorkOrder
FOR READ ONLY

DECLARE @SMCo bCompany
DECLARE @SMWorkOrder bWO
DECLARE @WOType CHAR(1)

DECLARE @SMWorkOrderScopeID int
DECLARE @Scope int       -- Sequence
DECLARE @Description varchar(MAX) -- Scope Detail
DECLARE @WorkScope varchar(20)

DECLARE @JCCo bCompany
DECLARE @Job bJob

DECLARE @PhaseGroup bGroup
DECLARE @Phase bPhase
DECLARE @CallType VARCHAR(10)

declare @newScopeID int

DECLARE @rcnt INT

SET @rcnt=0

OPEN wocur
FETCH wocur INTO
	@SMCo 
,	@SMWorkOrder
,	@WOType
,	@JCCo
,	@Job 

WHILE @@fetch_status=0

BEGIN
	SET @rcnt=@rcnt+1
	-- Check for Job vs. Customer Site

	PRINT 
		CAST(@rcnt AS CHAR(8))
	+	CAST(@SMCo AS CHAR(8))
	+	CAST(@SMWorkOrder AS CHAR(15))
	+	CAST(@WOType AS CHAR(5))

	--SELECT * FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder
	--Test for required Scope/Phase on PM Workorders
	select @CallType=t1.CallType from (select top 1 CallType from vSMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder order by Scope DESC) t1

	print 
		CAST('' AS CHAR(8))
	+	'Default CallType: ' + @CallType

	IF @WOType='P'
	BEGIN 
		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND PhaseGroup=1 AND RTRIM(Phase)='2100-0000-      -' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Phase ' + '[2100-0000-      -] Exists'
		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Phase ' + '[2100-0000-      -] not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=1)
			BEGIN
				select @newScopeID=1
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) + 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod )'
			print CAST('' AS CHAR(8)) +  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Fire'', 1, ''2100-0000-      -'',''N'',''N'' )'

			if @doSQL=1
			begin
				insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod, JCCo, Job )
				values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType /* Keep value consistent with Workorder */, 'Fire', 1, '2100-0000-      -','N','N', @JCCo, @Job )
			end 
		END 

		--Test for required Scope/Phase
		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND PhaseGroup=1 AND RTRIM(Phase)='2200-0000-      -' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Phase ' + '[2200-0000-      -] Exists'
			
			-- 2104.11.14 - LWO - Update Plumbing Description to '* DO NOT USE *' if it is not alread there.
			update SMWorkOrderScope set Description= '* DO NOT USE * ' + coalesce(Description,'') where SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND PhaseGroup=1 AND RTRIM(Phase)='2200-0000-      -' and Description not like '%* DO NOT USE *%'
		END

		-- 2104.11.14 - LWO - DO NOT ADD Plumbing if not there.  We dont want this going forward.
		--ELSE
		--BEGIN
		--	PRINT 
		--		CAST('' AS CHAR(8))
		--	+	'- Phase ' + '[2200-0000-      -] not represented'

		--	IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=2)
		--	BEGIN
		--		select @newScopeID=2
		--	END
		--	ELSE
		--	BEGIN
		--		select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
		--	END

		--	print 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod )'
		--	print  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''PLBPIPEPM'', ''Plumbing'', 1, ''2200-0000-      -'',''N'',''N'' )'

		--	if @doSQL=1
		--	begin
		--	  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod, JCCo, Job )
		--	  values ( @SMCo, @SMWorkOrder, @newScopeID, 'PLBPIPEPM', 'Plumbing', 1, '2200-0000-      -','N','N', @JCCo, @Job )
		--	end
		--END 

		--Test for required Scope/Phase
		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND RTRIM(Phase)='2320-0000-      -' and Description='HVAC' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Phase ' + '[2320-0000-      -] Exists'

			-- Update Existing

			print  CAST('' AS CHAR(8)) + 'update vSMWorkOrderScope set PhaseGroup=1, Phase=''2300-0000-      -'', Description=''Service'' where SMCo=' + cast(@SMCo as varchar(5)) + ' AND WorkOrder=''' + @SMWorkOrder + ''' and RTRIM(Phase)=''2320-0000-      -'''

			if @doSQL=1
			begin
			  update vSMWorkOrderScope set PhaseGroup=1, Phase='2300-0000-      -', Description='Service' where SMCo=@SMCo AND WorkOrder=@SMWorkOrder and RTRIM(Phase)='2320-0000-      -'
			end
		END

		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND RTRIM(Phase)='2300-0000-      -' and Description='Service' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Phase ' + '[2300-0000-      -] "Service" Exists'
		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Phase ' + '[2320-0000-      -] "Service" not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=3)
			BEGIN
				select @newScopeID=3
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) + 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod )'
			print  CAST('' AS CHAR(8)) + 'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Service'', 1, ''2300-0000-      -'',''N'',''N'' )'

			if @doSQL=1
			begin
			  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod, JCCo, Job )
			  values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType, 'Service', 1, '2300-0000-      -','N','N', @JCCo, @Job )
			end

		END


		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND RTRIM(Phase)='2300-0000-      -' and Description='Subcontract' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Phase ' + '[2300-0000-      -] "Subcontract" Exists'
		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Phase ' + '[2320-0000-      -] "Subcontract" not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=4)
			BEGIN
				select @newScopeID=4
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) + 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod )'
			print  CAST('' AS CHAR(8)) + 'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Subcontract'', 1, ''2300-0000-      -'',''N'',''N'' )'

			if @doSQL=1
			begin
			  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod, JCCo, Job )
			  values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType, 'Subcontract', 1, '2300-0000-      -','N','N', @JCCo, @Job )
			end

		END

		--Test for required Scope/Phase
		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND RTRIM(Phase)='0100-0500-      -' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Phase ' + '[0100-0500-      -] Exists'

			-- Update Existing

		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Phase ' + '[0100-0500-      -] not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=5)
			BEGIN
				select @newScopeID=5
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) + 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod )'
			print CAST('' AS CHAR(8)) +  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Rental'', 1, ''0100-0500-      -'',''N'',''N'' )'

			if @doSQL=1
			begin
			  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, PhaseGroup, Phase, IsTrackingWIP, PriceMethod, JCCo, Job )
			  values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType /* Keep value consistent with Workorder */, 'Rental', 1, '0100-0500-      -','N','N', @JCCo, @Job )
			end

		END
	END
	ELSE
	BEGIN
		--PRINT
		--		CAST('' AS CHAR(8))
		--+	'* Break Fix Workorder'

		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='Fire' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Scope ' + '[Fire] Exists'
		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Scope ' + '[Fire] not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=1)
			BEGIN
				select @newScopeID=1
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) +  'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )'
			print CAST('' AS CHAR(8)) +  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Fire'',''N'',''N'')'

			if @doSQL=1
			begin
			  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )
			  values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType /* Keep value consistent with Workorder */, 'Fire','N','N' )
			end

		END 

		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='Plumbing' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Scope ' + '[Plumbing] Exists'

			-- 2104.11.14 - LWO - Update Plumbing to * DO NOT USE * if not already set.
			update SMWorkOrderScope set Description= '* DO NOT USE * ' + coalesce(Description,'') where SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='Plumbing' and Description not like '%* DO NOT USE *%'
		END

		-- 2104.11.14 - LWO - Dont add Plumbing Phase going forward.
		--ELSE
		--BEGIN
		--	PRINT 
		--		CAST('' AS CHAR(8))
		--	+	'- Scope ' + '[Plumbing] not represented'

		--	IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=2)
		--	BEGIN
		--		select @newScopeID=2
		--	END
		--	ELSE
		--	BEGIN
		--		select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
		--	END

		--	print 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )'	
		--	print  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''PlbComTM'', ''Plumbing'',''N'',''N'')'

		--	if @doSQL=1
		--	begin
		--	  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )
		--	  values ( @SMCo, @SMWorkOrder, @newScopeID, 'PlbComTM', 'Plumbing','N','N' )
		--	end

		--END 

		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='HVAC' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Scope ' + '[HVAC] Exists'

			--Update HVAC to Service
			update SMWorkOrderScope set Description='Service' WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='HVAC'
		END

		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='Service' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Scope ' + '[Service] Exists'

			--Update HVAC to Service
		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Scope ' + '[Service] not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=3)
			BEGIN
				select @newScopeID=3
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) + 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )'
			print CAST('' AS CHAR(8)) +  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Service'',''N'',''N'')'

			if @doSQL=1
			begin
			  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )
			  values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType /* Keep value consistent with Workorder */, 'Service','N','N' )
			end 
			
		END 

		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='Subcontract' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Scope ' + '[Subcontract] Exists'
		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Scope ' + '[Subcontract] not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=4)
			BEGIN
				select @newScopeID=4
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) + 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )'
			print CAST('' AS CHAR(8)) +  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Subcontract'',''N'',''N'')'

			if @doSQL=1
			begin
			  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )
			  values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType /* Keep value consistent with Workorder */, 'Subcontract','N','N' )
			end

		END 

		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='Service' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Scope ' + '[Service] Exists'
		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Scope ' + '[Service] not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=5)
			BEGIN
				select @newScopeID=5
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) + 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )'
			print CAST('' AS CHAR(8)) +  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Service'',''N'',''N'')'

			if @doSQL=1
			begin
			  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )
			  values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType /* Keep value consistent with Workorder */, 'Service','N','N' )
			end

		END 

		IF EXISTS ( SELECT 1 FROM SMWorkOrderScope WHERE SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND Description='Rental' )
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'+ Scope ' + '[Rental] Exists'
		END
		ELSE
		BEGIN
			PRINT 
				CAST('' AS CHAR(8))
			+	'- Scope ' + '[Rental] not represented'

			IF NOT EXISTS (SELECT 1 FROM dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder and Scope=5)
			BEGIN
				select @newScopeID=5
			END
			ELSE
			BEGIN
				select @newScopeID=max(Scope)+1 from  dbo.SMWorkOrderScope WHERE SMCo=@SMCo and WorkOrder=@SMWorkOrder
			END

			print CAST('' AS CHAR(8)) + 'insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )'
			print CAST('' AS CHAR(8)) +  'values ( ' + cast(@SMCo as varchar(5)) + ', ' + cast(@SMWorkOrder as varchar(20)) + ', ' + cast(@newScopeID as varchar(5)) + ', ''' + @CallType + ''', ''Rental'',''N'',''N'')'

			if @doSQL=1
			begin
			  insert vSMWorkOrderScope ( SMCo, WorkOrder, Scope, CallType, Description, IsTrackingWIP, PriceMethod )
			  values ( @SMCo, @SMWorkOrder, @newScopeID, @CallType /* Keep value consistent with Workorder */, 'Rental','N','N' )
			end

		END 

	END

	DECLARE wosccur CURSOR FOR
    SELECT
		wos.SMWorkOrderScopeID
	,	wos.Scope -- Sequence
	,	wos.Description -- Scope Detail
	,	wos.WorkScope
	,	wos.PhaseGroup
	,	wos.Phase
	,	wos.CallType
	FROM 
		SMWorkOrderScope wos
	WHERE
		wos.SMCo=@SMCo
	AND wos.WorkOrder=@SMWorkOrder
	ORDER BY 
		wos.Scope

	OPEN wosccur
	FETCH wosccur into
		@SMWorkOrderScopeID 
	,	@Scope        -- Sequence
	,	@Description  -- Scope Detail
	,	@WorkScope 
	,	@PhaseGroup 
	,	@Phase 
	,	@CallType

	WHILE @@FETCH_STATUS=0
	begin

		PRINT 
			CAST('' AS CHAR(8))
		+	CAST(ISNULL(@SMWorkOrderScopeID,0) AS CHAR(8))
		+	CAST(ISNULL(@Scope,0) AS CHAR(8))
		+	CAST(ISNULL(left(@Description,30),'') AS CHAR(35))
		+	CAST(ISNULL(@WorkScope,'') AS CHAR(25))
		+	CAST(ISNULL(@PhaseGroup,'') AS CHAR(5))
		+	CAST(ISNULL(@Phase,'') AS CHAR(15))
		+	CAST(ISNULL(@CallType,'') AS CHAR(15))

		FETCH wosccur into
			@SMWorkOrderScopeID 
		,	@Scope        -- Sequence
		,	@Description  -- Scope Detail
		,	@WorkScope 
		,	@PhaseGroup 
		,	@Phase 
		,	@CallType
	END
    
	CLOSE wosccur
	DEALLOCATE wosccur
		
    PRINT '' 

	FETCH wocur INTO
		@SMCo 
	,	@SMWorkOrder
	,	@WOType
	,	@JCCo
	,	@Job 
	
END

CLOSE wocur
DEALLOCATE wocur
go

--mspLWO_SMWO_ScopeCheck
--	@Company=1
--,	@WorkOrder = 8993268
--,	@doSQL=1
--go

mspLWO_SMWO_ScopeCheck
	@Company=1
,	@WorkOrder = null
,	@doSQL=1
go

