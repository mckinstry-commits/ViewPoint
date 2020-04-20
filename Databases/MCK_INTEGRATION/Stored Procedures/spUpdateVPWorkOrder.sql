USE [MCK_INTEGRATION]
GO
/****** Object:  StoredProcedure [dbo].[spUpdateVPWorkOrder]    Script Date: 2/12/2016 8:48:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer/Curt Salada 
-- Create date: 4/29/2014
-- Description:	Update VP Work Orders from Astea (2nd hop)
-- 2014-05-30  CS  include inserts as well as updates
-- 2014-06-22  CS  add Markup Pct and Sale Person
-- 2014-06-23  CS  add AsteaBillTo, handle calltype updates
-- 2014-06-25  CS  set CustGroup in scope
-- 2014-07-15  CS  check SMCo and Type for Sites,
--                 and CustGroup for Customers
-- 2014-09-03  CS  set PhaseGroup in scope, 
--                 set WorkScope 000 and default Phase
-- 2014-09-29  CS  Use Job Sites for job-related orders
--                 If no Job Site exists, create one
-- 2014-09-30  CS  Don't use generic workscope;
--                 If job work, choose a phase from the job; 
--                 otherwise, no phase;
--                 set Costing Method = Actual Cost
-- 2014-10-02  CS  ignore inbound JCCo (it will always be 1);
--                 get the JCCo from the VP db
-- 2014-10-15  CS  "retired work order" in notes
-- 2014-10-28  CS  no updates for Job/JCCo fields;
--                 pull out job info for Co20 and put in Requested By;
--                 add four scopes for each WO
-- 2014-10-30  CS  add Subcontract scope for non-jobs
-- 2014-11-02  CS  pull out job info for Co20 scopes, too
-- 2014-11-25  CS  new scope scheme
-- 2014-11-26  CS  zero markup for Co20
-- 2015-04-07  CS  add scope 006 Truck Burden
-- 2015-04-08  CS  96863 - allow most WO updates to transfer, 
--                 even if demands have been posted
-- 2015-08-31  CS  98931 - upgrade to Vista 6.10:
--                 don't populate SMWorkOrderScope.IsComplete column;
--                 do populate these new mandatory columns:
--						SMWorkOrder.Certified
--						SMWorkOrderScope.Status
--						SMWorkOrderScope.IsPreventativeMaintenance
--						SMServiceSite.Certified
-- 2015-09-04  CS  98937 - fail transfer if service center changes 
--                 after costs posted in Viewpoint
-- 2015-10-28  CS  98995 - add WITH NOLOCKs to JCJCM and HQCO selects
-- 2016-01-04  CS  99074 - handle B&O Classification field
-- 2016-01-11  CS  98999 - Prior to this change, we only allowed Co 1 jobs on orders; if the
--                 job was for another company, we would strip the job info from the order and 
--                 stuff it in the Requested By field -- then report on those orders to be handled
--                 as manual exceptions.  We need to allow updates to these "Requested By" orders,
--                 but for updates to orders created after this change, we get the JCCo from the order.
--                 From now on, if order is new, we get JCCo from Astea (Astea got it from the job).
-- 2016-02-11  CS  99074 - write B&O Class for inserts only -- no updates
-- =============================================

ALTER PROCEDURE [dbo].[spUpdateVPWorkOrder] 
	-- Stored Procedure params
	@RowId int = 0
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @SMCo TINYINT, @Type VARCHAR(30), @WorkOrderId INT , @Scope INT, @sSMCo TINYINT
	DECLARE @msg VARCHAR(MAX) = ''
	DECLARE @isProcess CHAR(1) = 'N'
	DECLARE @CRLF AS CHAR(2) = CHAR(13) + CHAR(10)

	--Transact Log Variables
	DECLARE @Table VARCHAR(128) = 0, @KeyColumn VARCHAR(128) = 0, @KeyId VARCHAR(255), @User VARCHAR(128), @UpdateInsert CHAR(1)
	SELECT @Table = 'WorkOrder', @KeyColumn = 'RowId', @KeyId = @RowId, @User = SUSER_SNAME(), @UpdateInsert = 'N'
	
	-- Viewpoint Customer/Site/Bill-To
	DECLARE @MMServiceSite VARCHAR(20), @MMCustomer INT
	
	--VP Work Order fields  (98999 - moved here from below)
	DECLARE @VPSMWorkOrderID INT
		, @VPCustomer INT
		, @VPCustGroup TINYINT
		, @VPServiceSite VARCHAR(20)
		, @VPServiceCenter VARCHAR(10)
		, @VPJob VARCHAR(10)
		, @VPJCCo TINYINT
		, @VPDescription VARCHAR(MAX)
		, @VPNotes VARCHAR(MAX)
		, @VPSMWorkOrderScopeID INT
		, @VPMarkupPct FLOAT
		, @VPSalePerson VARCHAR(30)
		, @VPBillTo INT
		, @VPCallType VARCHAR(10)
		, @VPAsteaWO VARCHAR(40)
		, @VPudBOClass VARCHAR(10)   -- 99074
		, @VPRequestedBy VARCHAR(50) -- 98999
		
	--MCK_INTEGRATION Work Order fields
	DECLARE @MCustomer VARCHAR(30)
		, @MCustGroup TINYINT
		, @MPhaseGroup TINYINT
		, @MServiceSite VARCHAR(30)
		, @MServiceCenter VARCHAR(10)
		, @MJob VARCHAR(10)
		, @MJCCo TINYINT
		, @MProcessStatus CHAR(1)
		, @MDescription VARCHAR(MAX)
		, @MNotes VARCHAR(MAX)
		, @MRequestedDate DATETIME
		, @MRequestedTime DATETIME
		, @MEnteredDateTime DATETIME
		, @MEnteredBy VARCHAR(128)
		, @MudAsteaWO VARCHAR(20)
		, @MRequestedBy VARCHAR(50)
		, @sScope INT
		, @sCallType VARCHAR(10)
		, @sWorkScope VARCHAR(20)
		, @sDescription VARCHAR(60)
		, @sServiceCenter VARCHAR(10)
		, @sDivision VARCHAR(10)
		, @sNotes VARCHAR(MAX)
		, @sCustGroup TINYINT
		, @sBillToARCustomer INT
		, @sRateTemplate VARCHAR(10)
		, @sServiceItem VARCHAR(20)
		, @sSaleLocation TINYINT
		, @sIsComplete CHAR(1)
		, @sPriorityName VARCHAR(10)
		, @sIsTrackingWIP CHAR(1)
		, @sDueStartDate DATETIME
		, @sDueEndDate DATETIME
		, @sCustomerPO VARCHAR(30)
		, @sNotToExceed NUMERIC(12,2)
		, @sPhase VARCHAR(20)
		, @sPhaseGroup TINYINT
		, @sJCCo TINYINT
		, @sJob VARCHAR(10)
		, @sAgreement VARCHAR(15)
		, @sRevision INT
		, @sPriceMethod CHAR(1) 
		, @sPrice NUMERIC(12,2)
		, @sService INT
		, @sUseAgreementRates CHAR(1)
		, @MMarkupPct FLOAT
		, @MSalePerson VARCHAR(30)
		, @MAsteaBillTo VARCHAR(30)
		, @MudBOClass VARCHAR(10)     -- 99074
	
	-- get values from MCK_INTEGRATION record (Astea data)
	SELECT @MCustomer = AsteaCustomer
		, @MServiceSite = AsteaSite
		, @MServiceCenter = ServiceCenter
		, @MJob = Job
		, @MJCCo = JCCo
		, @MProcessStatus = ProcessStatus
		, @SMCo = SMCo 
		, @WorkOrderId = WorkOrder 
		, @MDescription = [Description]
		, @MNotes = Notes
		, @MRequestedDate = RequestedDate
		, @MRequestedTime = RequestedTime
		, @MEnteredDateTime = EnteredDateTime
		, @MEnteredBy = EnteredBy
		, @MudAsteaWO = udAsteaWO
		, @sScope = sScope
		, @sCallType = sCallType
		, @sWorkScope = sWorkScope
		, @sDescription = sDescription
		, @sServiceCenter = sServiceCenter
		, @sDivision = sDivision
		, @sNotes = sNotes
		--, @sCustGroup = sCustGroup
		--, @sBillToARCustomer = sBillToARCustomer
		, @sRateTemplate  = sRateTemplate
		, @sServiceItem = sServiceItem 
		, @sSaleLocation = sSaleLocation
		, @sIsComplete = ISNULL(sIsComplete, 'N')
		, @sPriorityName = sPriorityName
		, @sIsTrackingWIP = ISNULL(sIsTrackingWIP, 'N')
		, @sDueStartDate = sDueStartDate
		, @sDueEndDate = sDueEndDate
		, @sCustomerPO = sCustomerPO
		, @sNotToExceed = sNotToExceed
		, @sPhase = sPhase
		--, @sPhaseGroup = sPhaseGroup
		, @sJCCo = sJCCo
		, @sJob = sJob
		, @sAgreement = sAgreement
		, @sRevision = sRevision
		, @sPriceMethod = sPriceMethod 
		, @sPrice = sPrice
		, @sService = sService
		, @sUseAgreementRates =	sUseAgreementRates
		, @MMarkupPct = MarkupPct
		, @MSalePerson = SalePerson 
		, @MAsteaBillTo = AsteaBillTo
		, @MudBOClass = udBOClass         -- 99074
	FROM MCK_INTEGRATION.dbo.WorkOrder
	WHERE RowId = @RowId
	
	
	-- validate company (SMCo)
	IF @SMCo IS NULL
	BEGIN
		-- invalid company, note error and quit
		SET @msg = 'Missing company for work order ' + ISNULL(CONVERT(VARCHAR(20),@WorkOrderId), 'null')
		GOTO spexitfail
	END
	
	-- validate Astea Site ID
	IF @MServiceSite IS NULL
	BEGIN
		-- invalid site, note error and quit
		SET @msg = 'Missing site for work order ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), 'null') + ', Company ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), '')
		GOTO spexitfail
	END
			
	-- get CustGroup & PhaseGroup from VP based on company (SMCo)
	SELECT @MCustGroup = co.CustGroup, @MPhaseGroup = co.PhaseGroup
		  FROM Viewpoint.dbo.HQCO co WITH (NOLOCK)
		  WHERE co.HQCo = @SMCo
		  
	IF @MCustGroup IS NULL
	BEGIN
		-- invalid CustGroup, note error and quit
		SET @msg = 'Customer Group not found for company ' + ISNULL(CONVERT(VARCHAR(3), @SMCo), 'null')
		GOTO spexitfail
	END	

	IF @MPhaseGroup IS NULL
	BEGIN
		-- invalid PhaseGroup, note error and quit
		SET @msg = 'Phase Group not found for company ' + ISNULL(CONVERT(VARCHAR(3), @SMCo), 'null')
		GOTO spexitfail
	END	
		
	-- Scope needs Groups, too
	SELECT @sCustGroup = @MCustGroup	
	SELECT @sPhaseGroup = @MPhaseGroup
	
    -- begin 98999
	
	-- Check for matching SM Work Order in VP
	DECLARE @woExists AS BIT = 0
	IF EXISTS (SELECT TOP 1 1 FROM Viewpoint.dbo.SMWorkOrder wo
			WHERE wo.SMCo = @SMCo 
			  AND wo.WorkOrder = @WorkOrderId) 
	BEGIN
        -- set flag for later  
		SET @woExists = 1

		-- get old values from VP Work Order (moved this from down below)
		SELECT @VPSMWorkOrderID = SMWorkOrderID
			, @VPCustomer = Customer
			, @VPCustGroup = CustGroup
			, @VPServiceSite = ServiceSite
			, @VPServiceCenter = ServiceCenter
			, @VPJob = Job
			, @VPJCCo = JCCo
			, @VPDescription = [Description]
			, @VPNotes = Notes
			, @VPMarkupPct = udMarkupPct
			, @VPSalePerson = udSalesRep
			, @VPAsteaWO = udAsteaWO
			, @VPudBOClass = udBOClass  -- 99074
			, @VPRequestedBy = RequestedBy  -- 98999
		FROM Viewpoint.dbo.SMWorkOrder
		WHERE SMCo = @SMCo 
			AND WorkOrder = @WorkOrderId 		
	END
	-- end 98999 

	-- this will hold Job info for non-company 1 jobs  (98999 -- now only for older work orders)
	SELECT @MRequestedBy = NULL
	
	-- set phase
	IF ISNULL(@MJob, '') = ''
		-- for non-job work, there is no phase
		SELECT @sPhase = NULL
	ELSE
	BEGIN
	    -- 98999 comment this section out 
		---- get the job company (ignore the JCCo that Astea sent)
		--DECLARE @cnt INT
		--SELECT @cnt = COUNT(*) FROM Viewpoint.dbo.JCJM j WITH (NOLOCK)
		--INNER JOIN Viewpoint.dbo.HQCO h WITH (NOLOCK) ON j.JCCo = h.HQCo AND h.udTESTCo = 'N'
		--WHERE j.Job = @MJob
		--IF @cnt IS NULL OR @cnt < 1 
		--BEGIN
        --  SET @msg = 'Job ' + ISNULL(@MJob, 'null')  + ' not found.'
		--	GOTO spexitfail      
		--END
		
		--IF @cnt > 1
		--BEGIN
        --  SET @msg = 'More than one job ' + ISNULL(@MJob, 'null')  + ' was found.'
		--	GOTO spexitfail
		--END      
		
		--SELECT @MJCCo = JCCo, @sJCCo = JCCo 
		--FROM Viewpoint.dbo.JCJM j WITH (NOLOCK)
		--INNER JOIN Viewpoint.dbo.HQCO h WITH (NOLOCK) ON j.JCCo = h.HQCo AND h.udTESTCo = 'N'      
		--WHERE j.Job = @MJob	

		---- can only handle company 1 jobs
		--IF @MJCCo <> 1 
		--BEGIN
		--	SET @MRequestedBy = 'Job ' + ISNULL(@MJob, 'null') + ' JCCo ' + ISNULL(CAST(@MJCCo AS VARCHAR(3)), 'null')
		--	SET @MJCCo = NULL
		--	SET @MJob = NULL
        --  SET @sJCCo = NULL
		--    SET @sJob = NULL
		--	SET @sPhase = NULL   
		--	SET @MMarkupPct = 0
		--END
		
		-- begin 98999 
		-- We need to allow updates to the older "Requested By" orders,
		-- but for updates to orders created after this change, we get JCCo from Astea.
		-- (Astea got it from the job).

		IF @woExists = 1
		BEGIN               
			-- If there's no job number on the VP work order but there's a job number coming from Astea, 
			-- then this must be an update to one of the older "Requested By" orders...
			-- So, overwrite the Astea job data with blanks.
			IF @VPJob IS NULL AND @MJob IS NOT NULL
			BEGIN
				SET @MRequestedBy = @VPRequestedBy
				SET @MJCCo = NULL
				SET @MJob = NULL
  				SET @sJCCo = NULL
				SET @sJob = NULL
				SET @sPhase = NULL   
				SET @MMarkupPct = 0
            END
            ELSE           
			BEGIN
                -- If Viewpoint says this work order should have a Job number, and
				-- Astea does not send a job number, fail the transaction.
				-- (Sanity check -- should never happen.)          
  				IF @VPJob IS NOT NULL AND @MJob IS NULL
				BEGIN
				  SET @msg = 'Astea work order is missing the job number ' + @VPJob
				  GOTO spexitfail      
				END
				-- ELSE if both the VP order and the Astea order have a job number, 
				-- then we can assume the job data is the same in both systems
				-- because there is a work order #/job # validation in Astea,
				-- and no change to the job fields is required;
				-- just use what Astea sent.

				-- ELSE if neither VP nor Astea have a job number then there is no issue;
				-- just use what Astea sent.               
			END
        END
        -- ELSE if the work order doesn't exist in VP then this is a new order; 
		-- use the data that Astea sent.
	END      
	
	-- only process this row if it hasn't already been processed
	IF @MProcessStatus IS NULL OR @MProcessStatus <> 'N'
	BEGIN
		SET @msg = 'Row ' + ISNULL(CONVERT(VARCHAR(10),@RowId), 'null') + ' already processed, process status = ' + ISNULL(@MProcessStatus, 'null')
		GOTO spexitnoprocess	
	END

	-- look up VP SITE, VP CUSTOMER, and VP BILL-TO using Astea Customer, Astea Site, and Astea Bill To

	-- SITE
	IF ISNULL(@MJob, '') = ''
		-- get Customer site
		SELECT TOP 1 @MMServiceSite = ServiceSite FROM Viewpoint.dbo.SMServiceSite WHERE udAsteaSiteId = @MServiceSite AND SMCo = @SMCo AND Type = 'Customer'
	ELSE
	BEGIN
		-- get Job site  
		DECLARE @VPJobSite VARCHAR(20)
		SELECT @VPJobSite = LEFT(LTRIM(RTRIM(@MJob)) + '-' + LTRIM(RTRIM(@MServiceSite)), 20)

    	SELECT @MMServiceSite = ServiceSite FROM Viewpoint.dbo.SMServiceSite 
		WHERE SMCo = @SMCo AND ServiceSite = @VPJobSite AND Type = 'Job'

		-- if a Job Site doesn't exist for this job, create one!
		-- (could happen if user forces job number on service order)
		IF @MMServiceSite IS NULL
		BEGIN
			-- use Job + "-" + AsteaSite      
			SELECT @MMServiceSite = @VPJobSite
			      
			-- get existing Customer ServiceSite ID (we will use this site to copy data from)
			DECLARE @CustServiceSite AS VARCHAR(20)
			SELECT TOP 1 @CustServiceSite = ServiceSite FROM Viewpoint.dbo.SMServiceSite 
			WHERE udAsteaSiteId = @MServiceSite AND SMCo = @SMCo AND Type = 'Customer'

			IF @CustServiceSite IS NOT NULL         
			BEGIN
				BEGIN TRY	
					-- copy fields from Customer site into Job site, just change Type to 'Job' & add Job fields
					-- 98931 added mandatory Certified column
					INSERT INTO Viewpoint.dbo.SMServiceSite
						(SMCo, ServiceSite, Type, CustGroup, Customer, Job, JCCo, Description, udAsteaSiteId, Address1, Address2, 
						City, State, Zip, Country, Phone, DefaultServiceCenter, Active, 
						NonBillable, TaxCode, TaxGroup, RateTemplate, BillToARCustomer,	ContactGroup, Certified)
					SELECT @SMCo, @VPJobSite, 'Job', CustGroup, Customer, @MJob, @MJCCo, Description, udAsteaSiteId, Address1, Address2, 
						City, State, Zip, Country, Phone, DefaultServiceCenter, Active, 
						NonBillable, TaxCode, TaxGroup, RateTemplate, BillToARCustomer,	ContactGroup, 'N'
					FROM Viewpoint.dbo.SMServiceSite cs
					WHERE cs.ServiceSite = @CustServiceSite AND cs.SMCo = @SMCo
				END TRY
				BEGIN CATCH
					SET @msg = 'Failed to insert SMServiceSite'
					GOTO spexitfail         
				END CATCH   
			END -- customer service site is found 
		END -- servicesite is null
    END -- job site
    
	IF @MMServiceSite IS NULL
	BEGIN
		SET @msg = 'Astea site ' + ISNULL(@MServiceSite, 'null') + ' not found in SM Service Sites '
		IF ISNULL(@MJob, '') = ''
			SET @msg = @msg + '(Customer site)'
		ELSE
			SET @msg = @msg + '(Job site)'      
		GOTO spexitfail
	END
	SET @msg = 'SM Service Site identified: ' + ISNULL(@MMServiceSite, 'null')
	EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg
	
	-- CUSTOMER	(Astea is string, VP is integer)
	SELECT TOP 1 @MMCustomer = Customer FROM Viewpoint.dbo.ARCM WHERE udASTCust = @MCustomer AND CustGroup = @MCustGroup
	IF @MMCustomer IS NULL
	BEGIN
		SET @msg = 'Astea customer ' + ISNULL(@MCustomer, 'null') + ' not found in SM Customers'
		GOTO spexitfail
	END
	SET @msg = 'AR Customer identified: ' + ISNULL(CAST(@MMCustomer AS VARCHAR(20)), 'null')
	EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg

	-- BILL-TO
	IF (ISNULL(@MAsteaBillTo, '') <> '')
	BEGIN
		SELECT TOP 1 @sBillToARCustomer = Customer FROM Viewpoint.dbo.ARCM WHERE udASTCust = @MAsteaBillTo
		IF @sBillToARCustomer IS NULL
		BEGIN
			SET @msg = 'Astea Bill-to customer ' + ISNULL(@MAsteaBillTo, 'null') + ' not found in SM Customers'
			GOTO spexitfail
		END
		SET @msg = 'Bill-To identified: ' + ISNULL(CAST(@sBillToARCustomer AS VARCHAR(20)), 'null')
	END
	ELSE 
	BEGIN
		SET @sBillToARCustomer = @MMCustomer  -- if no 3rd party bill-to is specified, use Customer
		SET @msg = 'No Astea Bill-To supplied, defaulting to Customer: ' + ISNULL(CAST(@sBillToARCustomer AS VARCHAR(20)), 'null')
	END
	EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg	
		
    -- 98999 commented - moved this code to above
	----VP Work Order fields
	--DECLARE @VPSMWorkOrderID INT
	--	, @VPCustomer INT
	--	, @VPCustGroup TINYINT
	--	, @VPServiceSite VARCHAR(20)
	--	, @VPServiceCenter VARCHAR(10)
	--	, @VPJob VARCHAR(10)
	--	, @VPJCCo TINYINT
	--	, @VPDescription VARCHAR(MAX)
	--	, @VPNotes VARCHAR(MAX)
	--	, @VPSMWorkOrderScopeID INT
	--	, @VPMarkupPct FLOAT
	--	, @VPSalePerson VARCHAR(30)
	--	, @VPBillTo INT
	--	, @VPCallType VARCHAR(10)
	--	, @VPAsteaWO VARCHAR(40)
	--	, @VPudBOClass VARCHAR(10)   -- 99074
	
	--Set logging variables and execute log entry.
	SET @msg = 'Top of Work Order SP'
	EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg

	--Check for matching SM Work Order in VP
	-- 98999 replace with check for @woExists=1
	--IF EXISTS (SELECT TOP 1 1 FROM Viewpoint.dbo.SMWorkOrder wo
	--		WHERE wo.SMCo = @SMCo 
	--		  AND wo.WorkOrder = @WorkOrderId)
	IF @woExists = 1
	BEGIN
		-- existing work order must have at least one scope; otherwise, fail	
		IF NOT EXISTS (SELECT TOP 1 1 FROM Viewpoint.dbo.SMWorkOrderScope s
		WHERE s.SMCo = @SMCo AND s.WorkOrder = @WorkOrderId)
		BEGIN
			SET @msg = 'No scope found for WorkOrder ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), 'null') + ', Company ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), '')
			GOTO spexitfail				
		END
		
		-- UPDATE EXISTING VP WORK ORDER
		
		SET @msg = 'SM Work Order identified: Work Order ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), 'null') + ', Company ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), '') 
		EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg
	 
	    -- 98999 move this section up above
		---- get old values from VP Work Order
		--SELECT @VPSMWorkOrderID = SMWorkOrderID
		--	, @VPCustomer = Customer
		--	, @VPCustGroup = CustGroup
		--	, @VPServiceSite = ServiceSite
		--	, @VPServiceCenter = ServiceCenter
		--	, @VPJob = Job
		--	, @VPJCCo = JCCo
		--	, @VPDescription = [Description]
		--	, @VPNotes = Notes
		--	, @VPMarkupPct = udMarkupPct
		--	, @VPSalePerson = udSalesRep
		--	, @VPAsteaWO = udAsteaWO
		--	, @VPudBOClass = udBOClass  -- 99074
		--FROM Viewpoint.dbo.SMWorkOrder
		--WHERE SMCo = @SMCo 
		--  AND WorkOrder = @WorkOrderId 	 
		
		-- get old values from VP Work Order Scope (use the first one; all values should be the same for all scopes)
		SELECT TOP 1 @VPBillTo=BillToARCustomer, @VPCallType = CallType
		FROM Viewpoint.dbo.SMWorkOrderScope
		WHERE SMCo = @SMCo
			AND WorkOrder = @WorkOrderId
		
		-- 98937 - fail transaction if service center changed after costs posted in Viewpoint
		IF (ISNULL(@MServiceCenter,'') <> ISNULL(@VPServiceCenter,''))
		BEGIN
			DECLARE @workcount INT
			SELECT @workcount = COUNT(*) FROM Viewpoint.dbo.SMWorkCompleted w WHERE w.SMCo = @SMCo AND w.WorkOrder = @WorkOrderId   
			IF @workcount > 0
			BEGIN   			
    			SELECT @msg = 'Service Center update not allowed for Work Order ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), 'null') + ', Company ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), '') + ' | old ServiceCenter: ' + ISNULL(@VPServiceCenter, 'null') + ' new ServiceCenter: ' + ISNULL(@MServiceCenter, 'null')							
				GOTO spexitfail
			END
		END

		SELECT @msg = ''
	
		/*
		1. Divide existing Notes field into two parts: the Previous Numbers section and the Notes section.
		2. If the Astea WO ID has changed, this will also be an update to the Previous Numbers section.
		3. If the Notes have changed, this will be an update to the Notes section.
		4. If either section has changed, update the Notes field with the re-combined Previous Numbers and Notes sections.
		*/

		DECLARE @noteschanged AS BIT
		SET @noteschanged = 0

		-- 1. divide existing Notes field into oPrev and oNotes
		DECLARE @oPrev AS VARCHAR(MAX), @oNotes AS VARCHAR(MAX)

		DECLARE @retBeginText VARCHAR(100), @retEndText VARCHAR(100) 
		SET @retBeginText = '**BEGIN Previous Astea Reference Numbers section **' + @CRLF
		SET @retEndText = '**END Previous Astea Reference Numbers section **' + @CRLF

		DECLARE @retOrders VARCHAR(1000) -- the list of orders, from in between the Begin and End texts
		DECLARE @retOrdersIx INTEGER     -- position of the list of orders
		DECLARE @retBeginIx INTEGER      -- position of the begin text
		DECLARE @retEndIx INTEGER        -- position of the end text
        
		SET @retBeginIx = CHARINDEX(@retBeginText, @VPNotes) -- get position of the begin text
		SET @retEndIx = CHARINDEX(@retEndText, @VPNotes)     -- get position of the end text
		
		-- if there is a Previous Numbers section in the old notes, copy the whole section into @oPrev,
		-- put everything else in @oNotes, and put just the list of orders into @retOrders
		IF (@retBeginIx > 0) AND (@retEndIx > @retBeginIx)
		BEGIN
			SET @retOrdersIx = @retBeginIx + LEN(@retBeginText) -- get position of first char after the begin text      
			SET @oPrev = SUBSTRING(@VPNotes, 0, @retEndIx + LEN(@retEndText))		-- everything up to and including the Previous Numbers section
			SET @oNotes = SUBSTRING(@VPNotes, @retEndIx + LEN(@retEndText), LEN(@VPNotes)) -- everything after the Previous Numbers section
			SET @retOrders = SUBSTRING(@VPNotes, @retOrdersIx, (@retEndIx - @retOrdersIx)) -- everything between the begin and end texts
		END 
		ELSE 
		BEGIN
			SET @retOrders = ''
			SET @oPrev = ''
			SET @oNotes = @VPNotes
		END
        
		-- 2. if the Astea WO number has changed, update oPrev	
		IF (ISNULL(@MudAsteaWO,'') <> ISNULL(@VPAsteaWO,''))
		BEGIN     
			SELECT @msg = @msg +  ' | old Astea WO: ' + ISNULL(@VPAsteaWO, 'null') + ' new Astea WO: ' + ISNULL(@MudAsteaWO, 'null')		

			-- add old order ID to Previous Numbers section copied from old Notes text
      		SET @retOrders = @VPAsteaWO + ' on ' + CONVERT(VARCHAR(30), GETDATE(), 100) + @CRLF + @retOrders

			-- flag notes change
			SET @noteschanged = 1
		END
		
		-- 3. if the Notes have changed (aside from the list of work orders), update Notes
		IF (ISNULL(@MNotes, '') <> ISNULL(@oNotes, ''))
		BEGIN
			SELECT @msg = @msg + ' | Notes changed'

			-- flag notes change
			SET @noteschanged = 1
		END

		-- 4. If either section has changed, update the Notes field with the re-combined Previous Numbers and Notes sections
		IF @noteschanged = 1
		BEGIN
			-- append the new Notes text to the Previous Numbers section
			SET @MNotes = @retBeginText + @retOrders + @retEndText + @MNotes
		END      
        
		--IF (ISNULL(@MServiceCenter,'') <> ISNULL(@VPServiceCenter,''))
		--BEGIN
		--	DECLARE @workcount INT
		--	SELECT @workcount = COUNT(*) FROM Viewpoint.dbo.SMWorkCompleted w WHERE w.SMCo = SMCo AND w.WorkOrder = WorkOrder   
		--	IF @workcount = 0
		--	BEGIN   
		--		SELECT @msg = @msg + ' | old ServiceCenter: ' + ISNULL(@VPServiceCenter, 'null') + ' new ServiceCenter: ' + ISNULL(@MServiceCenter, 'null')							
		--	END
		--END
				
		IF (ISNULL(@MDescription,'') <> ISNULL(@VPDescription,''))
			SELECT @msg = @msg + ' | old Description: ' + ISNULL(QUOTENAME(@VPDescription,''''), 'null') + ' new Description: ' + ISNULL(QUOTENAME(@MDescription,''''), 'null')		
	
		IF (ISNULL(@MMarkupPct,0) <> ISNULL(@VPMarkupPct, 0))
			SELECT @msg = @msg + ' | old MarkupPct: ' + ISNULL(CAST(@VPMarkupPct AS VARCHAR(20)), 'null') + ' new MarkupPct: ' + ISNULL(CAST(@MMarkupPct AS VARCHAR(20)), 'null')

		IF (ISNULL(@MSalePerson,'') <> ISNULL(@VPSalePerson,''))
			SELECT @msg = @msg +  ' | old Sale Person: ' + ISNULL(@VPSalePerson, 'null') + ' new Sale Person: ' + ISNULL(@MSalePerson, 'null')		

		IF (ISNULL(@sBillToARCustomer,0) <> ISNULL(@VPBillTo, 0))
			SELECT @msg = @msg + ' | old Bill-To: ' + ISNULL(CAST(@VPBillTo AS VARCHAR(20)), 'null') + ' new Bill-To: ' + ISNULL(CAST(@sBillToARCustomer AS VARCHAR(20)), 'null')

		IF (ISNULL(@sCallType,'') <> ISNULL(@VPCallType,''))
			SELECT @msg = @msg +  ' | old Call Type: ' + ISNULL(@VPCallType, 'null') + ' new Call Type: ' + ISNULL(@sCallType, 'null')		
		
		-- 99074
		--IF (ISNULL(@MudBOClass,'') <> ISNULL(@VPudBOClass,''))
		--	SELECT @msg = @msg +  ' | old B&O Class: ' + ISNULL(@VPudBOClass, 'null') + ' new B&O Class: ' + ISNULL(@MudBOClass, 'null')		
	
		DECLARE @woupdates AS BIT
		SET @woupdates = 0      
		-- now compare the old and new values; if any fields have changed then do an update
		IF  (@msg <> '')
		BEGIN
			-- flag that an update happened      
			SET @woupdates = 1

			-- build the trans log message
			SELECT @msg = 'SMWorkOrderID: ' + CAST(@VPSMWorkOrderID AS VARCHAR(20)) + @msg
			EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg

			-- Update the Work Order
			UPDATE WO 
			  SET [Description] = @MDescription
				, Notes = @MNotes
				, udMarkupPct = @MMarkupPct
				, udSalesRep = @MSalePerson
				, udAsteaWO = @MudAsteaWO
				--, udBOClass = @MudBOClass  -- 99074
			 FROM Viewpoint.dbo.SMWorkOrder WO
			WHERE WO.SMCo = @SMCo AND WO.WorkOrder = @WorkOrderId 
			
			-- Update all Scopes for the Work Order
			UPDATE S
			  SET BillToARCustomer = @sBillToARCustomer
				, CallType = @sCallType
			 FROM Viewpoint.dbo.SMWorkOrderScope S
			WHERE S.SMCo = @SMCo AND S.WorkOrder = @WorkOrderId 
			
		END  -- any fields changed?

		-- only update Service Center if there have been no postings made to this work order
		-- 98937 - check for postings is now made above, and causes transfer to fail if any postings found
		IF (ISNULL(@MServiceCenter,'') <> ISNULL(@VPServiceCenter,''))
		BEGIN
			--DECLARE @workcount INT
			--SELECT @workcount = COUNT(*) FROM Viewpoint.dbo.SMWorkCompleted w WHERE w.SMCo = @SMCo AND w.WorkOrder = @WorkOrderId   
			--IF @workcount = 0
			--BEGIN   			
				-- flag that an update happened
				SET @woupdates = 1

				-- build the trans log message
				SELECT @msg = 'Service Center updated for Work Order ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), 'null') + ', Company ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), '') + ' | old ServiceCenter: ' + ISNULL(@VPServiceCenter, 'null') + ' new ServiceCenter: ' + ISNULL(@MServiceCenter, 'null')							

				-- update the work order
				UPDATE WO 
				  SET ServiceCenter = @MServiceCenter
				 FROM Viewpoint.dbo.SMWorkOrder WO
				WHERE WO.SMCo = @SMCo AND WO.WorkOrder = @WorkOrderId 
			--END
			--ELSE
   -- 			SELECT @msg = 'Service Center update not allowed for Work Order ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), 'null') + ', Company ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), '') + ' | old ServiceCenter: ' + ISNULL(@VPServiceCenter, 'null') + ' new ServiceCenter: ' + ISNULL(@MServiceCenter, 'null')							

			EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg
		END
	
		IF @woupdates = 0
		BEGIN
			SELECT @msg = 'No updates for Work Order ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), 'null') + ', Company ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), '')
			SELECT @msg = @msg + ' | old ServiceCenter: ' + ISNULL(@VPServiceCenter, 'null') + ' new ServiceCenter: ' + ISNULL(@MServiceCenter, 'null')
			SELECT @msg = @msg + ' | old Description: ' + ISNULL(@VPDescription, 'null') + ' new Description: ' + ISNULL(@MDescription, 'null')
			SELECT @msg = @msg + ' | old MarkupPct: ' + ISNULL(CAST(@VPMarkupPct AS VARCHAR(20)), 'null') + ' new MarkupPct: ' + ISNULL(CAST(@MMarkupPct AS VARCHAR(20)), 'null')
			SELECT @msg = @msg + ' | old Sale Person: ' + ISNULL(@VPSalePerson, 'null') + ' new Sale Person: ' + ISNULL(@MSalePerson, 'null')					
			SELECT @msg = @msg + ' | old Bill-To: ' + ISNULL(CAST(@VPBillTo AS VARCHAR(20)), 'null') + ' new Bill-To: ' + ISNULL(CAST(@sBillToARCustomer AS VARCHAR(20)), 'null')			
			SELECT @msg = @msg + ' | old Call Type: ' + ISNULL(@VPCallType, 'null') + ' new Call Type: ' + ISNULL(@sCallType, 'null')
			--SELECT @msg = @msg + ' | old B&O Class: ' + ISNULL(@VPudBOClass, 'null') + ' new B&O Class: ' + ISNULL(@MudBOClass, 'null') -- 99074			
			EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg
		END  -- no updates detected			  
	
	END  -- work order exists in VP, update it
	ELSE
	BEGIN
		-- INSERT NEW WORK ORDER

		SET @msg = 'Insert new SM Work Order ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(20)), 'null') + ', Company ' + ISNULL(CAST(@SMCo AS VARCHAR(3)), '')
		EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg

		-- insert SM Work Order
		INSERT Viewpoint.dbo.SMWorkOrder (
			SMCo
			, WorkOrder
			, CustGroup
			, Customer
			, ServiceSite
			, [Description]
			, ServiceCenter
			, RequestedBy
			, RequestedDate
			, RequestedTime
			, EnteredDateTime
			, EnteredBy
		--	, IsNew
			, Notes
			, JCCo
			, Job
			, udAsteaWO
		    , udMarkupPct
		    , udSalesRep
			, CostingMethod
			, Certified                    -- added mandatory 98931
			, udBOClass                    -- 99074
		)
		VALUES ( 
			@SMCo
			, @WorkOrderId
			, @MCustGroup
			, @MMCustomer
			, @MMServiceSite
			, @MDescription
			, @MServiceCenter
			, @MRequestedBy
			, @MRequestedDate
			, @MRequestedTime
			, @MEnteredDateTime
			, @MEnteredBy
			--, IsNew
			, @MNotes
			, @MJCCo
			, @MJob
			, @MudAsteaWO
			, @MMarkupPct
			, @MSalePerson
			, 'Cost'
			, 'N'                    -- added mandatory 98931
			, @MudBOClass            -- 99074
		)

		-- insert 5 SM Work Order Scopes: 001 Fire, 003 Service, Subcontract, Rental, 006 Truck Burden

		---- insert SM Work Order Scope
		INSERT INTO Viewpoint.dbo.SMWorkOrderScope (
			SMCo
			, WorkOrder
			, Scope
			, CallType
			, WorkScope
			, [Description]
			, ServiceCenter
			, Division
			, Notes
			, CustGroup
			, BillToARCustomer
			, RateTemplate
			, ServiceItem 
			, SaleLocation
			--, IsComplete   commented 98931
			, PriorityName
			, IsTrackingWIP
			, DueStartDate
			, DueEndDate
			, CustomerPO
			, NotToExceed
			, Phase
			, PhaseGroup
			, JCCo
			, Job
			, Agreement
			, Revision
			, PriceMethod 
			, Price
			, [Service]
			, [Status]                      -- added mandatory 98931
			, IsPreventativeMaintenance     -- added mandatory 98931
			)
		SELECT
			@SMCo
			, @WorkOrderId
			, d.[row]
			, @sCallType
			, d.WorkScope
			, d.[Description]
			, @sServiceCenter
			, @sDivision
			, @sNotes
			, @sCustGroup
			, @sBillToARCustomer
			, @sRateTemplate
			, @sServiceItem 
			, @sSaleLocation
			--, @sIsComplete    commented 98931
			, @sPriorityName
			, @sIsTrackingWIP
			, @sDueStartDate
			, @sDueEndDate
			, @sCustomerPO
			, @sNotToExceed
			, CASE WHEN ISNULL(@MJob, '') = '' THEN NULL ELSE d.Phase END Phase
			, @sPhaseGroup
			, @sJCCo
			, @sJob
			, @sAgreement
			, @sRevision
			, @sPriceMethod
			, @sPrice
			, @sService
			, 1                    -- added mandatory 98931
			, 'N'                  -- added mandatory 98931
			FROM 
			(
			SELECT ROW_NUMBER() OVER (ORDER BY s.WorkScope) 'row', 
			       s.Phase,
				   s.WorkScope,
				   s.Description
			FROM Viewpoint.dbo.SMWorkScope s 
			WHERE s.PhaseGroup = 1 AND s.WorkScope IN ('001', '003')
			UNION ALL
			SELECT 3, '2300-0000-      -   ', CASE WHEN ISNULL(@MJob, '') = '' THEN '004' ELSE NULL END, 'Subcontract'
			UNION ALL
			SELECT 4, '0100-0500-      -   ', NULL, 'Rental'    
			UNION ALL 
			SELECT 4 + ROW_NUMBER() OVER (ORDER BY s.WorkScope) 'row', 
			       s.Phase,
				   s.WorkScope,
				   s.Description
			FROM Viewpoint.dbo.SMWorkScope s 
			WHERE s.PhaseGroup = 1 AND s.WorkScope IN ('006')
			) d

			--IF ISNULL(@MJob, '') = '' 
			--BEGIN
			--	---- insert SM Work Order Scope for Subcontracts (non-job only)
			--	INSERT INTO Viewpoint.dbo.SMWorkOrderScope (
			--		SMCo
			--		, WorkOrder
			--		, Scope
			--		, CallType
			--		, WorkScope
			--		, [Description]
			--		, ServiceCenter
			--		, Division
			--		, Notes
			--		, CustGroup
			--		, BillToARCustomer
			--		, RateTemplate
			--		, ServiceItem 
			--		, SaleLocation
			--		, IsComplete
			--		, PriorityName
			--		, IsTrackingWIP
			--		, DueStartDate
			--		, DueEndDate
			--		, CustomerPO
			--		, NotToExceed
			--		, Phase
			--		, PhaseGroup
			--		, JCCo
			--		, Job
			--		, Agreement
			--		, Revision
			--		, PriceMethod 
			--		, Price
			--		, [Service])
			--	SELECT
			--		@SMCo
			--		, @WorkOrderId
			--		, d.[row]
			--		, @sCallType
			--		, d.WorkScope
			--		, d.[Description]
			--		, @sServiceCenter
			--		, @sDivision
			--		, @sNotes
			--		, @sCustGroup
			--		, @sBillToARCustomer
			--		, @sRateTemplate
			--		, @sServiceItem 
			--		, @sSaleLocation
			--		, @sIsComplete
			--		, @sPriorityName
			--		, @sIsTrackingWIP
			--		, @sDueStartDate
			--		, @sDueEndDate
			--		, @sCustomerPO
			--		, @sNotToExceed
			--		, CASE WHEN ISNULL(@MJob, '') = '' THEN NULL ELSE d.Phase END Phase
			--		, @sPhaseGroup
			--		, @sJCCo
			--		, @sJob
			--		, @sAgreement
			--		, @sRevision
			--		, @sPriceMethod
			--		, @sPrice
			--		, @sService
			--		FROM 
			--		(
			--		SELECT 4 'row', 
			--			   s.Phase,
			--			   s.WorkScope,
			--			   s.Description
			--		FROM Viewpoint.dbo.SMWorkScope s 
			--		WHERE s.PhaseGroup = @sPhaseGroup AND s.WorkScope IN ('004')
			--		) d
            --END          

	END  -- insert SM Work Order

	SET @msg = 'End of Work Order SP'

	spexit:
	BEGIN
		--Write back to MCK_INTEGRATION.dbo.WorkOrder
		UPDATE MCK_INTEGRATION.dbo.WorkOrder
		SET ProcessStatus = 'Y', ProcessTimeStamp = GETDATE()
		WHERE RowId = @RowId
		GOTO spexitnoprocess
		
		spexitfail:
		UPDATE MCK_INTEGRATION.dbo.WorkOrder
		SET ProcessStatus = 'F', ProcessTimeStamp = GETDATE(), ProcessDesc = LEFT(ISNULL(@msg, ''), 250)
		WHERE RowId = @RowId
		GOTO spexitnoprocess
		
		spexitnoprocess:
		BEGIN
			SELECT @KeyId = ISNULL(@KeyId,'MISSINGKEY')
			EXEC spInsertToTransactLog @Table = @Table, @KeyColumn = @KeyColumn, @KeyId = @KeyId, @User = @User, @UpdateInsert = @UpdateInsert, @msg = @msg
			RETURN 0
		END
	END

spquit:
END

GRANT EXEC ON dbo.spUpdateVPWorkOrder TO AsteaIntegration

GO