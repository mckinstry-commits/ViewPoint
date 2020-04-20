CREATE TABLE [dbo].[vSMWorkOrderScope]
(
[SMWorkOrderScopeID] [int] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[WorkOrder] [int] NOT NULL,
[Scope] [int] NOT NULL,
[CallType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[WorkScope] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DueStartDate] [dbo].[bDate] NULL,
[DueEndDate] [dbo].[bDate] NULL,
[ServiceCenter] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Division] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CustGroup] [dbo].[bGroup] NULL,
[BillToARCustomer] [dbo].[bCustomer] NULL,
[RateTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ServiceItem] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SaleLocation] [tinyint] NOT NULL CONSTRAINT [DF_vSMWorkOrderScope_SaleLocation] DEFAULT ((0)),
[IsComplete] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMWorkOrderScope_IsComplete] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[PriorityName] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[IsTrackingWIP] [dbo].[bYN] NOT NULL,
[CustomerPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[NotToExceed] [dbo].[bDollar] NULL,
[Phase] [dbo].[bPhase] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Revision] [int] NULL,
[PriceMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Price] [dbo].[bDollar] NULL,
[Service] [int] NULL,
[UseAgreementRates] [dbo].[bYN] NULL,
[TaxType] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[WorkOrderQuote] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[TaxRate] [dbo].[bRate] NULL,
[OnHold] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSMWorkOrderScope_OnHold] DEFAULT ('N'),
[HoldReason] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[FollowUpDate] [dbo].[bDate] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Matthew Bradford
-- Create date: 7/24/13
-- Description:	Update so that if a phase is added to a work order scope for a job it is
--				immediately added to the F4 lookup to the phases bug 56492
-- Modified:    This is perfect and will never need modification BEWHAHAHAHA!
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderScopeAddPhaseiu]
   ON  [dbo].[vSMWorkOrderScope]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int, @Job bJob, @JCCo bCompany, @PhaseGroup bGroup, @Phase bPhase, @Description bItemDesc,
	@Contract bContract, @ContractItem bContractItem, @ProjMinPct bPct, @JCCostType bJCCType, @errmsg varchar(255)

	DECLARE PhasesToAdd CURSOR FOR
	WITH WorkOrderScopeJobPhaseCTE
	AS
		(
		SELECT DISTINCT 
			inserted.PhaseGroup,
			inserted.Phase,
			inserted.Job,
			inserted.JCCo		
		FROM 
			inserted
		LEFT JOIN 
			JCJP
		ON
			inserted.JCCo = JCJP.JCCo AND
			inserted.Job = JCJP.Job	AND
			inserted.Phase = JCJP.Phase AND
			inserted.PhaseGroup = JCJP.PhaseGroup
		WHERE inserted.Phase IS NOT NULL AND JCJP.Phase IS NULL	
		)			
		SELECT * FROM WorkOrderScopeJobPhaseCTE
		OPEN PhasesToAdd
		FETCH NEXT FROM PhasesToAdd
		INTO 
			@PhaseGroup,
			@Phase,
			@Job,
			@JCCo			
		WHILE @@FETCH_STATUS =0
		BEGIN
			--Get Required fields for JC Job Phase Insert
			--Get Job Contract and default Phase Projection Min% from Job Master
			SELECT @Contract = [Contract], @ProjMinPct=ProjMinPct FROM dbo.JCJM WHERE JCCo = @JCCo AND Job = @Job
			--Get min Contract Item for Job and assign it to Phase
			SELECT @ContractItem = MIN(Item) FROM dbo.JCCI WHERE JCCo = @JCCo AND [Contract] = @Contract
			--Get JC Phase Master phase description for insert
			SELECT @Description = [Description] FROM dbo.JCPM where PhaseGroup = @PhaseGroup and Phase = @Phase
			--Create JC Job Phase in JCJP
			EXEC @rcode = dbo.vspJCJPAdd @JCCo=@JCCo, @Job=@Job, @PhaseGroup=@PhaseGroup, @Phase=@Phase, @Desc=@Description, @Contract=@Contract, @Item=@ContractItem, @ProjMinPct=@ProjMinPct, @ActiveYN='Y', @msg=@errmsg OUTPUT
			IF @rcode <> 0
			BEGIN
				RAISERROR(@errmsg, 11, -1)
				ROLLBACK TRANSACTION
			END	
			FETCH NEXT FROM PhasesToAdd
			INTO 
				@PhaseGroup,
				@Phase,
				@Job,
				@JCCo
		END		
		CLOSE PhasesToAdd
		DEALLOCATE PhasesToAdd	
END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Dan Koslicki
-- Create date: 04/22/13
-- Description:	Clear Flat Price Splits
--
-- Modifications:
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderScopeFlatPriceu]
   ON  [dbo].[vSMWorkOrderScope]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF UPDATE(PriceMethod)
	BEGIN 
		BEGIN TRY
			DELETE		SMFlatPriceRevenueSplit 
			FROM		SMFlatPriceRevenueSplit
			INNER JOIN	SMEntity
					ON	SMEntity.EntitySeq	=  SMFlatPriceRevenueSplit.EntitySeq
					AND SMEntity.SMCo		= SMFlatPriceRevenueSplit.SMCo
			INNER JOIN	INSERTED I
					ON	I.SMCo				= SMFlatPriceRevenueSplit.SMCo
					AND I.WorkOrder			= SMEntity.WorkOrder
					AND I.Scope				= SMEntity.WorkOrderScope
			INNER JOIN	DELETED D
					ON	D.SMCo				= I.SMCo
					AND D.WorkOrder			= I.WorkOrder
					AND D.Scope				= I.Scope

			WHERE		I.PriceMethod <> 'F'
		END TRY 

		BEGIN CATCH 
			RAISERROR('Flat Price Rate Split could not be cleared.', 11, -1)
			ROLLBACK TRANSACTION
		END CATCH 
	END

END

GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/25/2013
-- Description:	Updates the corresponding work completed based on the scope's setup.
--				Most of this code was originally pulled out of vspSMWorkOrderScopeAgreementUpdate.
--				JVH	  3/14/13 - TFS-40927 - Moved the validation into the validation trigger and included re-pricing when the rate template changes.
--              EricV 05/22/13 TFS-50951 Changed PriceMethod value check of 'C' to 'N'.
--				EricV  05/31/13 TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
--				MattB 6/19/13 TFS-50962 Remove coverage and nonbillable variables. Handle updating of pricing method.
--				MDB 6/21/13 TFS-50962 Update so tax information on work completed grid will update whens witching from a nonbillable to T&M PriceMethod on the scope.
--				MDB 6/25/13 TFS-50962 Update to clear use agreement rates if updated scope from t&m to anything else.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderScopeuWorkCompletedUpdate]
   ON  [dbo].[vSMWorkOrderScope]
   AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT (UPDATE(Agreement) OR UPDATE(Revision) OR UPDATE(PriceMethod) OR UPDATE(RateTemplate) OR UPDATE(UseAgreementRates))
		RETURN

	-- Update cost, price and GL accounts if all needed fields are present.
	DECLARE @SMCo bCompany, @WorkOrder int, @Scope int,
		@Agreement varchar(15), @Revision int, @PriceMethod char(1), @UseAgreementRates bYN,
		@CurrentWorkCompletedID bigint, @Date bDate,
		@TaxGroup bGroup, @TaxType tinyint, @TaxCode bTaxCode, @TaxRate bRate,
		@msg varchar(255), @rcode int

	DECLARE WorkCompletedUpdateCursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT DISTINCT SMCo, WorkOrder, Scope
	FROM INSERTED

	OPEN WorkCompletedUpdateCursor
	FETCH NEXT FROM WorkCompletedUpdateCursor INTO @SMCo, @WorkOrder, @Scope
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @WorkCompletedToUpdate TABLE (SMWorkCompletedID bigint, [Date] bDate, TaxGroup bGroup NULL, TaxType tinyint NULL, TaxCode bTaxCode NULL)

		SELECT @Agreement = Agreement, @Revision = Revision, @PriceMethod = PriceMethod,
			@UseAgreementRates = UseAgreementRates, @TaxGroup = dbo.vfSMGetDefaultTaxInfo.TaxGroup, @TaxType = dbo.vfSMGetDefaultTaxInfo.TaxType,
			@TaxCode = dbo.vfSMGetDefaultTaxInfo.TaxCode
		FROM dbo.SMWorkOrderScope
		CROSS APPLY dbo.vfSMGetDefaultTaxInfo(@SMCo, @WorkOrder, @Scope)
		WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope

		IF @PriceMethod IN ('F', 'N')
		BEGIN
			UPDATE dbo.SMWorkCompleted
			SET NonBillable='Y', Agreement = @Agreement, Revision = @Revision, UseAgreementRates='N',
				PriceUM = NULL, PriceQuantity = NULL, PriceRate = NULL, PriceECM = NULL, PriceTotal = NULL,
				TaxType = NULL, TaxCode = NULL, TaxBasis = NULL, TaxAmount = NULL, NoCharge='N'
			WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope
		END
		ELSE
		BEGIN
			--If price method is changed to time and material then all work completed should be set to billable
			IF UPDATE(PriceMethod)
			BEGIN
				UPDATE dbo.SMWorkCompleted
				SET NonBillable = 'N'
				WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope
			
				UPDATE dbo.vSMWorkCompletedDetail
				SET 
					TaxGroup = @TaxGroup,
					TaxType = @TaxType,
					TaxCode = @TaxCode
				FROM 
					dbo.vSMWorkCompletedDetail
				LEFT JOIN dbo.vSMCostType ON
					vSMWorkCompletedDetail.SMCo = vSMCostType.SMCo AND vSMWorkCompletedDetail.SMCostType = vSMCostType.SMCostType	
				LEFT JOIN dbo.SMWorkCompletedPart ON 
					vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompletedPart.SMWorkCompletedID
					AND vSMWorkCompletedDetail.IsSession = SMWorkCompletedPart.IsSession					
				LEFT JOIN dbo.SMWorkCompletedPurchase ON 
					vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompletedPurchase.SMWorkCompletedID
					AND vSMWorkCompletedDetail.IsSession = SMWorkCompletedPurchase.IsSession
					LEFT JOIN dbo.POIT ON SMWorkCompletedPurchase.POCo = POIT.POCo AND SMWorkCompletedPurchase.PO = POIT.PO AND SMWorkCompletedPurchase.POItem = POIT.POItem
				LEFT JOIN dbo.HQMT ON 
						(SMWorkCompletedPart.MatlGroup = HQMT.MatlGroup AND SMWorkCompletedPart.Part = HQMT.Material) OR
						(POIT.MatlGroup = HQMT.MatlGroup AND POIT.Material = HQMT.Material)									
				WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.Scope = @Scope AND vSMWorkCompletedDetail.IsSession=0
					AND (vSMCostType.TaxableYN='Y' OR HQMT.Taxable='Y')
			END
			
			--IF Agreement or revision updated we need to update work completed details.
			IF UPDATE(Agreement) OR UPDATE(Revision) OR UPDATE(UseAgreementRates)
			BEGIN
				UPDATE vSMWorkCompletedDetail
				SET Agreement=@Agreement,
					Revision=@Revision,
					UseAgreementRates = @UseAgreementRates
				WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope 
			END
			
			--The PriceQuantity are cleared when the work completed is non-billable
			--so they need to be copied over from the cost if they are missing.
			UPDATE dbo.SMWorkCompleted
			SET PriceQuantity = CostQuantity
			WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND [Type] IN (2,3) AND PriceQuantity IS NULL AND NonBillable='N'

			--The PriceUM and PriceECM are cleared when the work completed is non-billable
			--so they need to be copied over from the cost if they are missing.
			UPDATE dbo.SMWorkCompleted
			SET PriceUM = UM, PriceECM = CostECM
			WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND [Type] IN (4,5) AND (PriceUM IS NULL OR PriceECM IS NULL) AND NonBillable='N'

			-- Update Equipment line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = Rates.PriceRate,
				vSMWorkCompletedDetail.PriceTotal = Rates.PriceRate * CASE WHEN RevCodeInfo.Basis = 'H' THEN SMWorkCompleted.TimeUnits ELSE SMWorkCompleted.WorkUnits END
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRateEquipment(SMCo, WorkOrder, Scope, [Date], Agreement, Revision, NonBillable, UseAgreementRates, EMCo, Equipment, RevCode, CostRate) Rates 
				CROSS APPLY dbo.vfEMEquipmentRevCodeSetup(EMCo, Equipment, EMGroup, RevCode) RevCodeInfo
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 1 AND SMWorkCompleted.NonBillable='N'

			-- Update Labor line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = Rates.Rate,
				vSMWorkCompletedDetail.PriceTotal = Rates.Rate * SMWorkCompleted.PriceQuantity
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRateLabor(SMCo, WorkOrder, Scope, [Date], Agreement, Revision, NonBillable, UseAgreementRates, PRCo, PayType, Craft, Class, Technician) Rates 
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 2 AND SMWorkCompleted.NonBillable='N'

			--Update misc lines that came from AP
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = COALESCE(MaterialRate.PriceRate, SMWorkCompleted.PriceRate, SMWorkCompleted.CostRate),
				vSMWorkCompletedDetail.PriceTotal = COALESCE(MaterialRate.PriceTotal, SMWorkCompleted.PriceTotal, SMWorkCompleted.ActualCost)
			FROM dbo.SMWorkCompleted
				OUTER APPLY
				(
					SELECT vfSMRatePurchase.PriceRate, vfSMRatePurchase.PriceTotal
					FROM dbo.APTL
						INNER JOIN dbo.HQMT ON APTL.MatlGroup = HQMT.MatlGroup AND APTL.Material = HQMT.Material
						CROSS APPLY dbo.vfSMRatePurchase(SMWorkCompleted.SMCo, SMWorkCompleted.WorkOrder, SMWorkCompleted.Scope, SMWorkCompleted.[Date], @Agreement, @Revision, NonBillable, @UseAgreementRates, APTL.MatlGroup, APTL.Material, APTL.UM, SMWorkCompleted.CostQuantity, SMWorkCompleted.ActualCost, APTL.UM, 'E')
					WHERE SMWorkCompleted.APTLKeyID = APTL.KeyID
				) MaterialRate
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 3 AND SMWorkCompleted.APTLKeyID IS NOT NULL AND SMWorkCompleted.NonBillable='N'

			-- Update Misc line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = COALESCE(StandardItemRate.BillableRate, SMWorkCompleted.PriceRate, SMWorkCompleted.CostRate),
				vSMWorkCompletedDetail.PriceTotal = COALESCE(StandardItemRate.BillableRate * SMWorkCompleted.PriceQuantity, SMWorkCompleted.PriceTotal,  SMWorkCompleted.ActualCost)
			FROM dbo.SMWorkCompleted
				OUTER APPLY
				(
					SELECT BillableRate
					FROM dbo.vfSMGetStandardItemRate (SMCo, WorkOrder, Scope, [Date], StandardItem, Agreement, Revision, NonBillable, UseAgreementRates)
					WHERE SMWorkCompleted.StandardItem IS NOT NULL
				) StandardItemRate
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 3 AND SMWorkCompleted.APTLKeyID IS NULL AND SMWorkCompleted.NonBillable='N'

			-- Update Inventory line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = vfSMRateInventory.PriceRate,
				vSMWorkCompletedDetail.PriceTotal = vfSMRateInventory.PriceTotal
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRateInventory(SMCo, WorkOrder, Scope, [Date], Agreement, Revision, NonBillable, UseAgreementRates, INCo, INLocation, MatlGroup, Part, UM, Quantity, ActualCost, PriceUM, PriceECM) 
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 4 AND SMWorkCompleted.NonBillable='N'

			-- Update Purchase line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = vfSMRatePurchase.PriceRate,
				vSMWorkCompletedDetail.PriceTotal = vfSMRatePurchase.PriceTotal
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRatePurchase(SMCo, WorkOrder, Scope, [Date], Agreement, Revision, NonBillable, UseAgreementRates, MatlGroup, Part, UM, Quantity, ProjCost, PriceUM, PriceECM) 
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 5 AND SMWorkCompleted.NonBillable='N'

			-- Populate table variable - This is used to update taxes for all line types
			INSERT INTO @WorkCompletedToUpdate
			SELECT SMWorkCompletedID, [Date], TaxGroup, TaxType, TaxCode
			FROM dbo.SMWorkCompleted 
			WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND TaxGroup IS NOT NULL AND TaxCode IS NOT NULL AND TaxType IS NOT NULL AND NonBillable='N'
			
			-- Loop through all line items to update taxes
			WHILE EXISTS (SELECT 1 FROM @WorkCompletedToUpdate)
			BEGIN
				SELECT TOP 1 @CurrentWorkCompletedID = SMWorkCompletedID, @Date = [Date], 
					@TaxGroup = TaxGroup, @TaxType = TaxType, @TaxCode = TaxCode
				FROM @WorkCompletedToUpdate

				EXEC @rcode = dbo.vspHQTaxCodeVal @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @Date, @taxtype = @TaxType, @taxrate = @TaxRate OUTPUT, @msg = @msg OUTPUT
				
				IF (@rcode <> 0)
				BEGIN
					ROLLBACK TRAN
					RAISERROR(@msg, 11, -1)
					RETURN
				END
				
				-- Update Tax Amounts
				UPDATE dbo.vSMWorkCompletedDetail 
				SET TaxBasis = PriceTotal,
					TaxAmount = PriceTotal * @TaxRate
				WHERE SMWorkCompletedID = @CurrentWorkCompletedID

				DELETE FROM @WorkCompletedToUpdate WHERE SMWorkCompletedID = @CurrentWorkCompletedID
			END
		END

		FETCH NEXT FROM WorkCompletedUpdateCursor INTO @SMCo, @WorkOrder, @Scope
	END
	CLOSE WorkCompletedUpdateCursor
	DEALLOCATE WorkCompletedUpdateCursor
END
GO

ALTER TABLE [dbo].[vSMWorkOrderScope] ADD
CONSTRAINT [CK_vSMWorkOrderScope_FlatPrice] CHECK (([PriceMethod]<>'F' OR [dbo].[vfEqualsNull]([Price])=(0)))
ALTER TABLE [dbo].[vSMWorkOrderScope] ADD
CONSTRAINT [CK_vSMWorkOrderScope_Agreement] CHECK (([dbo].[vfEqualsNull]([Agreement])=[dbo].[vfEqualsNull]([Revision]) AND ([Service] IS NULL OR [Agreement] IS NOT NULL)))
ALTER TABLE [dbo].[vSMWorkOrderScope] ADD
CONSTRAINT [FK_vSMWorkOrderScope_vSMWorkOrderQuote] FOREIGN KEY ([SMCo], [WorkOrderQuote]) REFERENCES [dbo].[vSMWorkOrderQuote] ([SMCo], [WorkOrderQuote])
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
--	 	 Author: Lane Gresham
--  Create date: 10/28/11
--  Description:	
-- Modification: DKS 7/22/2013 - Adding error for quote related scopes.
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderScoped]
   ON  [dbo].[vSMWorkOrderScope]
   AFTER DELETE
AS 
BEGIN

	SET NOCOUNT ON; 

	IF EXISTS(SELECT 1 FROM DELETED WHERE IsComplete = 'Y')
	BEGIN
		RAISERROR('This work order scope is not open.', 11, -1)
		ROLLBACK TRANSACTION
	END  

	IF EXISTS(SELECT 1 FROM DELETED WHERE WorkOrderQuote IS NOT NULL)
	BEGIN
		RAISERROR('This work order scope can only be deleted by un-approving the quote that created it.', 11, -1)
		ROLLBACK TRANSACTION
	END 

END

GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 07/27/2011
-- Description:	Work Order Scope Insert
-- Modified:  MarkH 08/19/11 TK-07482 Removed MiscellaneousType   
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderScopei]
   ON  [dbo].[vSMWorkOrderScope]
   AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1
		FROM INSERTED
		INNER JOIN vSMWorkOrder ON vSMWorkOrder.SMCo = INSERTED.SMCo AND vSMWorkOrder.WorkOrder = INSERTED.WorkOrder
		WHERE vSMWorkOrder.WOStatus <> 0)
	BEGIN
		RAISERROR('This work order is not open.', 11, -1)
		ROLLBACK TRANSACTION
	END
END


GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/6/2011
-- Modified:
--				2/12/2012 - JG - TK-12371 - Use the Cost values for Billing if the 
--											Work Order Costing Method is Cost.
--				6/11/12 EricV TK-15593 Don't add to Agreement work orders.
--				9/10/12 LaneG TK-17490 Fixed VAT tax default auto generated WC for AU and CA.
--			    2/6/13  Jacob VH TFS-39301 Modified to work with changes made to support company copy on rate overrides
--				3/29/13	JVH		- TFS-44846 - Updated to handle deriving sm gl accounts
--              5/09/13 EricV TFS-49443 Create Work Completed from quote for quote work orders.
--				05/31/13 EricV  TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
-- Description:	Work Order Scope Insert
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderScopeiWorkCompletedAutoCreate]
   ON  [dbo].[vSMWorkOrderScope]
   AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1 FROM INSERTED WHERE Agreement IS NULL)
	BEGIN
		DECLARE @Date bDate, @PostMonth bMonth,
			@KeyID int, @SMCo bCompany, @WorkOrder int, @WorkOrderScope int, @WorkCompleted int,
			@TaxGroup bGroup, @TaxCode bTaxCode, @TaxRate bRate, @NonBillable bYN,
			@Provisional bit, @rcode int, @msg varchar(255)
			
		SELECT @Date = dbo.vfDateOnly(), @PostMonth = dbo.vfDateOnlyMonth()
	
		DECLARE @WorkCompletedToCreate TABLE (
			SMCo bCompany, WorkOrder int, Scope int,
			GLCo bCompany, CostWIPGLAcct bGLAcct, CostGLAcct bGLAcct, RevenueWIPGLAcct bGLAcct, RevenueGLAcct bGLAcct,
			ServiceSite varchar(20), StandardItem varchar(20), [Description] varchar(60) NULL, SMCostType smallint,
			CostQuantity bUnits NULL, CostRate bUnitCost NULL, CostTotal bDollar NULL,
			PriceQuantity bUnits NULL, PriceRate bUnitCost NULL, PriceTotal bDollar NULL,
			TaxType tinyint NULL, TaxGroup bGroup NULL, TaxCode bTaxCode NULL, NonBillable bYN,
			KeyID int IDENTITY(1,1))
		
		INSERT @WorkCompletedToCreate
		SELECT INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope, 
				GLAccounts.GLCo, GLAccounts.CostWIPGLAcct, GLAccounts.CostGLAcct, GLAccounts.RevenueWIPGLAcct, GLAccounts.RevenueGLAcct,
				SMServiceSite.ServiceSite, SMStandardItem.StandardItem, SMStandardItem.[Description], SMStandardItem.SMCostType,
				SMStandardItemDefault.CostQuantity, SMStandardItem.CostRate, NULL AS CostTotal,
				CASE WHEN SMWorkOrder.CostingMethod = 'Cost' 
					 THEN SMStandardItemDefault.CostQuantity
					 ELSE SMStandardItemDefault.PriceQuantity
				END, 
				CASE WHEN SMWorkOrder.CostingMethod = 'Cost'
					 THEN SMStandardItem.CostRate
					 ELSE DerivedBillableRate.BillableRate
				END, 
				NULL AS PriceTotal,
				TaxableTaxInfo.TaxType, TaxableTaxInfo.TaxGroup, TaxableTaxInfo.TaxCode,
				CASE WHEN INSERTED.PriceMethod='F' THEN 'Y' 
				WHEN INSERTED.PriceMethod='N' THEN 'Y' 
				ELSE 'N' END					
		FROM INSERTED
			INNER JOIN dbo.SMCO ON INSERTED.SMCo = SMCO.SMCo 
			INNER JOIN dbo.HQCO ON SMCO.ARCo = HQCO.HQCo
			INNER JOIN dbo.SMWorkOrder ON INSERTED.SMCo = SMWorkOrder.SMCo AND INSERTED.WorkOrder = SMWorkOrder.WorkOrder
			--Service site is still required on the work order. If this changes make sure to address the scope sale location.
			INNER JOIN dbo.SMServiceSite ON SMWorkOrder.SMCo = SMServiceSite.SMCo AND SMWorkOrder.ServiceSite = SMServiceSite.ServiceSite
			LEFT JOIN dbo.SMEntity SMServiceSiteEntity ON SMServiceSite.SMCo = SMServiceSiteEntity.SMCo AND SMServiceSite.ServiceSite = SMServiceSiteEntity.ServiceSite
			LEFT JOIN dbo.SMCustomer ON SMWorkOrder.SMCo = SMCustomer.SMCo AND SMWorkOrder.CustGroup = SMCustomer.CustGroup AND SMWorkOrder.Customer = SMCustomer.Customer
			LEFT JOIN dbo.SMEntity SMCustomerEntity ON SMCustomer.SMCo = SMCustomerEntity.SMCo AND SMCustomer.CustGroup = SMCustomerEntity.CustGroup AND SMCustomer.Customer = SMCustomerEntity.Customer
			INNER JOIN dbo.SMStandardItemDefault ON SMStandardItemDefault.SMCo = INSERTED.SMCo AND 
				SMStandardItemDefault.EntitySeq = 
				CASE 
					WHEN EXISTS(SELECT 1 FROM dbo.SMStandardItemDefault WHERE SMStandardItemDefault.SMCo = SMServiceSiteEntity.SMCo AND SMStandardItemDefault.EntitySeq = SMServiceSiteEntity.EntitySeq) THEN SMServiceSiteEntity.EntitySeq
					ELSE SMCustomerEntity.EntitySeq 
				END
			INNER JOIN dbo.SMStandardItem ON SMStandardItemDefault.SMCo = SMStandardItem.SMCo AND SMStandardItemDefault.StandardItem = SMStandardItem.StandardItem
			LEFT JOIN dbo.SMCostType ON SMStandardItem.SMCo = SMCostType.SMCo AND SMStandardItem.SMCostType = SMCostType.SMCostType
			CROSS APPLY dbo.vfSMGetAccountingTreatment (INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope, 'O', SMCostType.SMCostType) GLAccounts
			CROSS APPLY dbo.vfSMGetStandardItemRate(INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope, @Date, SMStandardItem.StandardItem, NULL, NULL, NULL, NULL) DerivedBillableRate
			OUTER APPLY
			(
				SELECT TaxGroup, TaxCode, TaxType
				FROM dbo.vfSMGetDefaultTaxInfo(INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope)
				WHERE SMCostType.TaxableYN = 'Y'
			) TaxableTaxInfo
		WHERE INSERTED.Scope = 1
		AND INSERTED.WorkOrderQuote IS NULL

		UPDATE @WorkCompletedToCreate
		SET CostTotal = CostQuantity * CostRate

		-- Now add records to @WorkCompletedToCreate from the Quote for Quote Work Orders.
		INSERT @WorkCompletedToCreate
		SELECT INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope,
				GLAccounts.GLCo, 
				GLAccounts.CostWIPGLAcct, 
				GLAccounts.CostGLAcct, 
				GLAccounts.RevenueWIPGLAcct, 
				GLAccounts.RevenueGLAcct,
				SMServiceSite.ServiceSite, 
				SMRequiredMisc.StandardItem, 
				SMRequiredMisc.[Description], 
				SMRequiredMisc.SMCostType,
				SMRequiredMisc.Quantity,
				SMRequiredMisc.CostRate,
				SMRequiredMisc.CostTotal,
				SMRequiredMisc.Quantity,
				DerivedBillableRate.BillableRate, 
				NULL AS PriceTotal,
				SMWorkOrderQuoteScope.TaxType,
				SMWorkOrderQuoteScope.TaxGroup, 
				SMWorkOrderQuoteScope.TaxCode,
				CASE WHEN SMWorkOrderQuoteScope.PriceMethod ='F' THEN 'Y' ELSE 'N' END
		FROM INSERTED
			INNER JOIN dbo.SMCO ON INSERTED.SMCo = SMCO.SMCo 
			INNER JOIN dbo.HQCO ON SMCO.ARCo = HQCO.HQCo
			INNER JOIN dbo.SMWorkOrder ON INSERTED.SMCo = SMWorkOrder.SMCo AND INSERTED.WorkOrder = SMWorkOrder.WorkOrder
			--Service site is still required on the work order. If this changes make sure to address the scope sale location.
			INNER JOIN dbo.SMServiceSite ON SMWorkOrder.SMCo = SMServiceSite.SMCo AND SMWorkOrder.ServiceSite = SMServiceSite.ServiceSite
			INNER JOIN dbo.SMWorkOrderQuoteScope ON INSERTED.SMCo = SMWorkOrderQuoteScope.SMCo 
				AND INSERTED.WorkOrderQuote = SMWorkOrderQuoteScope.WorkOrderQuote 
				AND INSERTED.Scope = SMWorkOrderQuoteScope.WorkOrderQuoteScope
			INNER JOIN dbo.SMEntity QuoteScopeEntity ON SMWorkOrderQuoteScope.SMCo = QuoteScopeEntity.SMCo AND SMWorkOrderQuoteScope.WorkOrderQuote = QuoteScopeEntity.WorkOrderQuote AND SMWorkOrderQuoteScope.WorkOrderQuoteScope = QuoteScopeEntity.WorkOrderQuoteScope
			INNER JOIN dbo.SMRequiredMisc ON SMRequiredMisc.SMCo = QuoteScopeEntity.SMCo AND SMRequiredMisc.EntitySeq = QuoteScopeEntity.EntitySeq 
			LEFT JOIN dbo.SMStandardItem ON SMRequiredMisc.SMCo = SMStandardItem.SMCo AND SMRequiredMisc.StandardItem = SMStandardItem.StandardItem
			LEFT JOIN dbo.SMCostType ON SMRequiredMisc.SMCo = SMCostType.SMCo AND SMRequiredMisc.SMCostType = SMCostType.SMCostType
			CROSS APPLY dbo.vfSMGetAccountingTreatment (INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope, 'O', SMRequiredMisc.SMCostType) GLAccounts
			CROSS APPLY dbo.vfSMGetStandardItemRate(INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope, @Date, SMStandardItem.StandardItem, NULL, NULL, NULL, NULL) DerivedBillableRate
			OUTER APPLY
			(
				SELECT TaxGroup, TaxCode, TaxType
				FROM dbo.vfSMGetDefaultTaxInfo(INSERTED.SMCo, INSERTED.WorkOrder, INSERTED.Scope)
				WHERE SMCostType.TaxableYN = 'Y'
			) TaxableTaxInfo
		WHERE INSERTED.WorkOrderQuote IS NOT NULL
	
		--Massage the data and figure out the totals
		UPDATE @WorkCompletedToCreate
		SET CostQuantity = NULL, CostRate = NULL
		WHERE CostRate IS NULL OR ISNULL(CostQuantity, 0) = 0
		
		UPDATE @WorkCompletedToCreate
		SET PriceQuantity = NULL, PriceRate = NULL
		WHERE PriceRate IS NULL OR ISNULL(PriceQuantity, 0) = 0 OR NonBillable = 'Y'
		
		UPDATE @WorkCompletedToCreate
		SET PriceTotal = PriceQuantity * PriceRate
	
		WHILE EXISTS(SELECT 1 FROM @WorkCompletedToCreate)
		BEGIN
			SET @Provisional = 0
		
			SELECT TOP 1 @KeyID = KeyID, @SMCo = SMCo, @WorkOrder = WorkOrder,
				@TaxGroup = TaxGroup, @TaxCode = TaxCode
			FROM @WorkCompletedToCreate
			
			EXEC @rcode = vspSMWorkCompletedScopeVal @SMCo = @SMCo, @WorkOrder = @WorkOrder, @Scope = 1, @LineType = 3, @AllowProvisional='Y', @Provisional=@Provisional OUTPUT
			
			IF @TaxCode IS NOT NULL
			BEGIN
				EXEC @rcode = dbo.vspHQTaxCodeVal @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @Date, @taxtype = 1, @taxrate = @TaxRate OUTPUT
			END

			/* Get the value for the next WorkCompleted */
			SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @WorkOrder)

			BEGIN TRY
				INSERT SMWorkCompleted (SMCo, WorkOrder, WorkCompleted, [Type], Scope, [Date], TaxType, TaxGroup, TaxCode,
					TaxBasis, TaxAmount, GLCo, CostAccount, RevenueAccount, CostWIPAccount, RevenueWIPAccount, 
					StandardItem, [Description], CostQuantity, CostRate, SMCostType, ActualCost, PriceQuantity, PriceRate, PriceTotal, 
					ServiceSite, NoCharge, Provisional, AutoAdded, MonthToPostCost, NonBillable)
				SELECT SMCo, WorkOrder, @WorkCompleted, 3 /*Misc Type*/, Scope, @Date, TaxType, TaxGroup, TaxCode,
					CASE WHEN TaxCode IS NOT NULL THEN PriceTotal END AS TaxBasis, CASE WHEN TaxCode IS NOT NULL THEN PriceTotal * @TaxRate END AS TaxTotal,
					GLCo, CostGLAcct, RevenueGLAcct, CostWIPGLAcct, RevenueWIPGLAcct,
					StandardItem, [Description], CostQuantity, CostRate, SMCostType, CostTotal, PriceQuantity, PriceRate, PriceTotal,
					ServiceSite, 'N' AS NoCharge, @Provisional, 1 AS AutoAdded /*Mark as auto added*/, @PostMonth, NonBillable
				FROM @WorkCompletedToCreate
				WHERE KeyID = @KeyID
			END TRY
			
			BEGIN CATCH
				SET @msg = 'Error inserting Work Completed - ' + ERROR_MESSAGE()
				RAISERROR(@msg, 11, -1);
				ROLLBACK TRANSACTION
				RETURN
			END CATCH

			DELETE @WorkCompletedToCreate WHERE KeyID = @KeyID
		END	
	END
END

GO
GO

GO

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: Dec 1, 2010
-- Description:	Do now allow updates if the work order is closed.
-- Modified:    EricV   07/25/11 Added update of Provisional WorkCompleted records.
-- Modified:	MarkH 08/19/11 TK-07482 Removed MiscellaneousType 
--				JG	  01/25/2012 - TK-00000 - Null JCCostType for vspSMLaborRateGet
--				JVH	  2/25/13 - TFS-40927 - Moved validating changes to the RateTemplate
--				JVH	  3/14/13 - TFS-40927 - Modified validating when the rate template can be changed
--				JVH 4/29/13 TFS-44860 Updated check to see if work completed is part of an invoice
-- =============================================
CREATE TRIGGER [dbo].[vtSMWorkOrderScopeu]
   ON  [dbo].[vSMWorkOrderScope]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF EXISTS(SELECT 1 FROM dbo.vfColumnsUpdated(COLUMNS_UPDATED(), 'vSMWorkOrderScope') WHERE ColumnsUpdated <> 'IsComplete')
		AND EXISTS(SELECT 1 FROM INSERTED WHERE IsComplete = 'Y')
	BEGIN
		RAISERROR('This work order scope is not open.', 11, -1)
		RETURN
	END  

	-- Do not allow changes if a line has already been billed.
	IF (UPDATE(Agreement) OR UPDATE(Revision) OR UPDATE(PriceMethod) OR UPDATE(RateTemplate) OR UPDATE(UseAgreementRates))
		AND EXISTS
		(
			SELECT 1 
			FROM inserted
				INNER JOIN dbo.vSMWorkCompletedDetail ON inserted.SMCo = vSMWorkCompletedDetail.SMCo AND inserted.WorkOrder = vSMWorkCompletedDetail.WorkOrder AND inserted.Scope = vSMWorkCompletedDetail.Scope
				INNER JOIN dbo.vSMInvoiceDetail ON vSMWorkCompletedDetail.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompletedDetail.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompletedDetail.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		)
	BEGIN
		ROLLBACK TRAN
		RAISERROR('A work completed line item for this scope seq is part of an invoice. The price method, rate template and agreement related fields can not be changed.', 11, -1)
		RETURN
	END
	
	-- Check for Provisional Work Completed records

	-- Update cost, price and GL accounts if all needed fields are present.
	DECLARE @SMCo bCompany, @WorkOrder int, @Scope int

	DECLARE ProvisionalCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT DISTINCT SMCo, WorkOrder, Scope
		FROM INSERTED
		
	OPEN ProvisionalCursor
	FETCH NEXT FROM ProvisionalCursor INTO @SMCo, @WorkOrder, @Scope
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @rcode int, @msg varchar(255)

		EXEC @rcode = dbo.vspSMWorkCompletedCheckProvisional @SMCo, @WorkOrder, @Scope, @msg OUTPUT

		IF @rcode <> 0
		BEGIN
			ROLLBACK TRAN
			RAISERROR(@msg, 11, -1)
			RETURN
		END

		FETCH NEXT FROM ProvisionalCursor INTO @SMCo, @WorkOrder, @Scope
	END
	CLOSE ProvisionalCursor
	DEALLOCATE ProvisionalCursor
	
END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderScope_Audit_Delete ON dbo.vSMWorkOrderScope
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditCreateAuditTriggers

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Agreement' , 
								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'BillToARCustomer' , 
								CONVERT(VARCHAR(MAX), deleted.[BillToARCustomer]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CallType' , 
								CONVERT(VARCHAR(MAX), deleted.[CallType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[CustGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'CustomerPO' , 
								CONVERT(VARCHAR(MAX), deleted.[CustomerPO]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Division' , 
								CONVERT(VARCHAR(MAX), deleted.[Division]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'DueEndDate' , 
								CONVERT(VARCHAR(MAX), deleted.[DueEndDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'DueStartDate' , 
								CONVERT(VARCHAR(MAX), deleted.[DueStartDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'FollowUpDate' , 
								CONVERT(VARCHAR(MAX), deleted.[FollowUpDate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'HoldReason' , 
								CONVERT(VARCHAR(MAX), deleted.[HoldReason]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'IsComplete' , 
								CONVERT(VARCHAR(MAX), deleted.[IsComplete]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'IsTrackingWIP' , 
								CONVERT(VARCHAR(MAX), deleted.[IsTrackingWIP]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'JCCo' , 
								CONVERT(VARCHAR(MAX), deleted.[JCCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Job' , 
								CONVERT(VARCHAR(MAX), deleted.[Job]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'NotToExceed' , 
								CONVERT(VARCHAR(MAX), deleted.[NotToExceed]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'OnHold' , 
								CONVERT(VARCHAR(MAX), deleted.[OnHold]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Phase' , 
								CONVERT(VARCHAR(MAX), deleted.[Phase]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PhaseGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[PhaseGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Price' , 
								CONVERT(VARCHAR(MAX), deleted.[Price]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PriceMethod' , 
								CONVERT(VARCHAR(MAX), deleted.[PriceMethod]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'PriorityName' , 
								CONVERT(VARCHAR(MAX), deleted.[PriorityName]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'RateTemplate' , 
								CONVERT(VARCHAR(MAX), deleted.[RateTemplate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Revision' , 
								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMCo' , 
								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SMWorkOrderScopeID' , 
								CONVERT(VARCHAR(MAX), deleted.[SMWorkOrderScopeID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'SaleLocation' , 
								CONVERT(VARCHAR(MAX), deleted.[SaleLocation]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Scope' , 
								CONVERT(VARCHAR(MAX), deleted.[Scope]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'Service' , 
								CONVERT(VARCHAR(MAX), deleted.[Service]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceCenter' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceCenter]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'ServiceItem' , 
								CONVERT(VARCHAR(MAX), deleted.[ServiceItem]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxCode' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxCode]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxGroup' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxGroup]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxRate' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxRate]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'TaxType' , 
								CONVERT(VARCHAR(MAX), deleted.[TaxType]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'UniqueAttchID' , 
								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'UseAgreementRates' , 
								CONVERT(VARCHAR(MAX), deleted.[UseAgreementRates]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkOrder' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkOrder]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkOrderQuote' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkOrderQuote]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14
							INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(deleted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(deleted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(deleted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								deleted.SMCo , 
								'D' , 
								'WorkScope' , 
								CONVERT(VARCHAR(MAX), deleted.[WorkScope]) , 								NULL , 
								GETDATE() , 
								SUSER_SNAME()
							FROM deleted
								JOIN dbo.vAuditFlagCompany AS afc ON deleted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', d.SMCo, CAST(d.SMCo AS VARCHAR(30)), 'vSMWorkOrderScope'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString SMCo = "' + REPLACE(CAST(ISNULL(d.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(d.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(d.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderScope_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderScope_Audit_Delete]', 'last', 'delete', null
GO
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderScope_Audit_Delete]', 'last', 'delete', null
GO

GO

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderScope_Audit_Insert ON dbo.vSMWorkOrderScope
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
-- log additions to the Agreement column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Agreement' , 
								NULL , 
								[Agreement] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the BillToARCustomer column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'BillToARCustomer' , 
								NULL , 
								[BillToARCustomer] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CallType column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CallType' , 
								NULL , 
								[CallType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CustGroup column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustGroup' , 
								NULL , 
								[CustGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the CustomerPO column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'CustomerPO' , 
								NULL , 
								[CustomerPO] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Division column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Division' , 
								NULL , 
								[Division] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the DueEndDate column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DueEndDate' , 
								NULL , 
								[DueEndDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the DueStartDate column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'DueStartDate' , 
								NULL , 
								[DueStartDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the FollowUpDate column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'FollowUpDate' , 
								NULL , 
								[FollowUpDate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the HoldReason column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'HoldReason' , 
								NULL , 
								[HoldReason] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the IsComplete column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'IsComplete' , 
								NULL , 
								[IsComplete] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the IsTrackingWIP column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'IsTrackingWIP' , 
								NULL , 
								[IsTrackingWIP] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the JCCo column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'JCCo' , 
								NULL , 
								[JCCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Job column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Job' , 
								NULL , 
								[Job] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the NotToExceed column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'NotToExceed' , 
								NULL , 
								[NotToExceed] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the OnHold column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'OnHold' , 
								NULL , 
								[OnHold] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Phase column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Phase' , 
								NULL , 
								[Phase] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PhaseGroup column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PhaseGroup' , 
								NULL , 
								[PhaseGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Price column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Price' , 
								NULL , 
								[Price] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PriceMethod column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PriceMethod' , 
								NULL , 
								[PriceMethod] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the PriorityName column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'PriorityName' , 
								NULL , 
								[PriorityName] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the RateTemplate column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'RateTemplate' , 
								NULL , 
								[RateTemplate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Revision column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Revision' , 
								NULL , 
								[Revision] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMCo column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMCo' , 
								NULL , 
								[SMCo] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SMWorkOrderScopeID column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SMWorkOrderScopeID' , 
								NULL , 
								[SMWorkOrderScopeID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the SaleLocation column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'SaleLocation' , 
								NULL , 
								[SaleLocation] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Scope column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Scope' , 
								NULL , 
								[Scope] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the Service column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'Service' , 
								NULL , 
								[Service] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the ServiceCenter column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceCenter' , 
								NULL , 
								[ServiceCenter] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the ServiceItem column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'ServiceItem' , 
								NULL , 
								[ServiceItem] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the TaxCode column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxCode' , 
								NULL , 
								[TaxCode] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the TaxGroup column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxGroup' , 
								NULL , 
								[TaxGroup] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the TaxRate column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxRate' , 
								NULL , 
								[TaxRate] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the TaxType column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'TaxType' , 
								NULL , 
								[TaxType] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the UniqueAttchID column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UniqueAttchID' , 
								NULL , 
								[UniqueAttchID] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the UseAgreementRates column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'UseAgreementRates' , 
								NULL , 
								[UseAgreementRates] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the WorkOrder column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkOrder' , 
								NULL , 
								[WorkOrder] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the WorkOrderQuote column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkOrderQuote' , 
								NULL , 
								[WorkOrderQuote] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

-- log additions to the WorkScope column
							INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)
									OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
							SELECT 
								'vSMWorkOrderScope' , 
								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 
								ISNULL(inserted.SMCo, '') , 
								'A' , 
								'WorkScope' , 
								NULL , 
								[WorkScope] , 
								GETDATE() , 
								SUSER_SNAME()
							FROM inserted
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', i.SMCo, CAST(i.SMCo AS VARCHAR(30)), 'vSMWorkOrderScope'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString SMCo = "' + REPLACE(CAST(ISNULL(i.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(i.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(i.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderScope_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderScope_Audit_Insert]', 'last', 'insert', null
GO

EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderScope_Audit_Insert]', 'last', 'insert', null
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtvSMWorkOrderScope_Audit_Update ON dbo.vSMWorkOrderScope
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspAuditTriggersCreate

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
							IF UPDATE([Agreement])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Agreement' , 								CONVERT(VARCHAR(MAX), deleted.[Agreement]) , 								CONVERT(VARCHAR(MAX), inserted.[Agreement]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[Agreement] <> deleted.[Agreement]) OR (inserted.[Agreement] IS NULL AND deleted.[Agreement] IS NOT NULL) OR (inserted.[Agreement] IS NOT NULL AND deleted.[Agreement] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([BillToARCustomer])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'BillToARCustomer' , 								CONVERT(VARCHAR(MAX), deleted.[BillToARCustomer]) , 								CONVERT(VARCHAR(MAX), inserted.[BillToARCustomer]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[BillToARCustomer] <> deleted.[BillToARCustomer]) OR (inserted.[BillToARCustomer] IS NULL AND deleted.[BillToARCustomer] IS NOT NULL) OR (inserted.[BillToARCustomer] IS NOT NULL AND deleted.[BillToARCustomer] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CallType])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CallType' , 								CONVERT(VARCHAR(MAX), deleted.[CallType]) , 								CONVERT(VARCHAR(MAX), inserted.[CallType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[CallType] <> deleted.[CallType]) OR (inserted.[CallType] IS NULL AND deleted.[CallType] IS NOT NULL) OR (inserted.[CallType] IS NOT NULL AND deleted.[CallType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CustGroup])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustGroup' , 								CONVERT(VARCHAR(MAX), deleted.[CustGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[CustGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[CustGroup] <> deleted.[CustGroup]) OR (inserted.[CustGroup] IS NULL AND deleted.[CustGroup] IS NOT NULL) OR (inserted.[CustGroup] IS NOT NULL AND deleted.[CustGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([CustomerPO])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'CustomerPO' , 								CONVERT(VARCHAR(MAX), deleted.[CustomerPO]) , 								CONVERT(VARCHAR(MAX), inserted.[CustomerPO]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[CustomerPO] <> deleted.[CustomerPO]) OR (inserted.[CustomerPO] IS NULL AND deleted.[CustomerPO] IS NOT NULL) OR (inserted.[CustomerPO] IS NOT NULL AND deleted.[CustomerPO] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Division])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Division' , 								CONVERT(VARCHAR(MAX), deleted.[Division]) , 								CONVERT(VARCHAR(MAX), inserted.[Division]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[Division] <> deleted.[Division]) OR (inserted.[Division] IS NULL AND deleted.[Division] IS NOT NULL) OR (inserted.[Division] IS NOT NULL AND deleted.[Division] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([DueEndDate])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'DueEndDate' , 								CONVERT(VARCHAR(MAX), deleted.[DueEndDate]) , 								CONVERT(VARCHAR(MAX), inserted.[DueEndDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[DueEndDate] <> deleted.[DueEndDate]) OR (inserted.[DueEndDate] IS NULL AND deleted.[DueEndDate] IS NOT NULL) OR (inserted.[DueEndDate] IS NOT NULL AND deleted.[DueEndDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([DueStartDate])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'DueStartDate' , 								CONVERT(VARCHAR(MAX), deleted.[DueStartDate]) , 								CONVERT(VARCHAR(MAX), inserted.[DueStartDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[DueStartDate] <> deleted.[DueStartDate]) OR (inserted.[DueStartDate] IS NULL AND deleted.[DueStartDate] IS NOT NULL) OR (inserted.[DueStartDate] IS NOT NULL AND deleted.[DueStartDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([FollowUpDate])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'FollowUpDate' , 								CONVERT(VARCHAR(MAX), deleted.[FollowUpDate]) , 								CONVERT(VARCHAR(MAX), inserted.[FollowUpDate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[FollowUpDate] <> deleted.[FollowUpDate]) OR (inserted.[FollowUpDate] IS NULL AND deleted.[FollowUpDate] IS NOT NULL) OR (inserted.[FollowUpDate] IS NOT NULL AND deleted.[FollowUpDate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([HoldReason])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'HoldReason' , 								CONVERT(VARCHAR(MAX), deleted.[HoldReason]) , 								CONVERT(VARCHAR(MAX), inserted.[HoldReason]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[HoldReason] <> deleted.[HoldReason]) OR (inserted.[HoldReason] IS NULL AND deleted.[HoldReason] IS NOT NULL) OR (inserted.[HoldReason] IS NOT NULL AND deleted.[HoldReason] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([IsComplete])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'IsComplete' , 								CONVERT(VARCHAR(MAX), deleted.[IsComplete]) , 								CONVERT(VARCHAR(MAX), inserted.[IsComplete]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[IsComplete] <> deleted.[IsComplete]) OR (inserted.[IsComplete] IS NULL AND deleted.[IsComplete] IS NOT NULL) OR (inserted.[IsComplete] IS NOT NULL AND deleted.[IsComplete] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([IsTrackingWIP])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'IsTrackingWIP' , 								CONVERT(VARCHAR(MAX), deleted.[IsTrackingWIP]) , 								CONVERT(VARCHAR(MAX), inserted.[IsTrackingWIP]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[IsTrackingWIP] <> deleted.[IsTrackingWIP]) OR (inserted.[IsTrackingWIP] IS NULL AND deleted.[IsTrackingWIP] IS NOT NULL) OR (inserted.[IsTrackingWIP] IS NOT NULL AND deleted.[IsTrackingWIP] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([JCCo])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'JCCo' , 								CONVERT(VARCHAR(MAX), deleted.[JCCo]) , 								CONVERT(VARCHAR(MAX), inserted.[JCCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[JCCo] <> deleted.[JCCo]) OR (inserted.[JCCo] IS NULL AND deleted.[JCCo] IS NOT NULL) OR (inserted.[JCCo] IS NOT NULL AND deleted.[JCCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Job])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Job' , 								CONVERT(VARCHAR(MAX), deleted.[Job]) , 								CONVERT(VARCHAR(MAX), inserted.[Job]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[Job] <> deleted.[Job]) OR (inserted.[Job] IS NULL AND deleted.[Job] IS NOT NULL) OR (inserted.[Job] IS NOT NULL AND deleted.[Job] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([NotToExceed])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'NotToExceed' , 								CONVERT(VARCHAR(MAX), deleted.[NotToExceed]) , 								CONVERT(VARCHAR(MAX), inserted.[NotToExceed]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[NotToExceed] <> deleted.[NotToExceed]) OR (inserted.[NotToExceed] IS NULL AND deleted.[NotToExceed] IS NOT NULL) OR (inserted.[NotToExceed] IS NOT NULL AND deleted.[NotToExceed] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([OnHold])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'OnHold' , 								CONVERT(VARCHAR(MAX), deleted.[OnHold]) , 								CONVERT(VARCHAR(MAX), inserted.[OnHold]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[OnHold] <> deleted.[OnHold]) OR (inserted.[OnHold] IS NULL AND deleted.[OnHold] IS NOT NULL) OR (inserted.[OnHold] IS NOT NULL AND deleted.[OnHold] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Phase])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Phase' , 								CONVERT(VARCHAR(MAX), deleted.[Phase]) , 								CONVERT(VARCHAR(MAX), inserted.[Phase]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[Phase] <> deleted.[Phase]) OR (inserted.[Phase] IS NULL AND deleted.[Phase] IS NOT NULL) OR (inserted.[Phase] IS NOT NULL AND deleted.[Phase] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PhaseGroup])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PhaseGroup' , 								CONVERT(VARCHAR(MAX), deleted.[PhaseGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[PhaseGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[PhaseGroup] <> deleted.[PhaseGroup]) OR (inserted.[PhaseGroup] IS NULL AND deleted.[PhaseGroup] IS NOT NULL) OR (inserted.[PhaseGroup] IS NOT NULL AND deleted.[PhaseGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Price])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Price' , 								CONVERT(VARCHAR(MAX), deleted.[Price]) , 								CONVERT(VARCHAR(MAX), inserted.[Price]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[Price] <> deleted.[Price]) OR (inserted.[Price] IS NULL AND deleted.[Price] IS NOT NULL) OR (inserted.[Price] IS NOT NULL AND deleted.[Price] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PriceMethod])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PriceMethod' , 								CONVERT(VARCHAR(MAX), deleted.[PriceMethod]) , 								CONVERT(VARCHAR(MAX), inserted.[PriceMethod]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[PriceMethod] <> deleted.[PriceMethod]) OR (inserted.[PriceMethod] IS NULL AND deleted.[PriceMethod] IS NOT NULL) OR (inserted.[PriceMethod] IS NOT NULL AND deleted.[PriceMethod] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([PriorityName])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'PriorityName' , 								CONVERT(VARCHAR(MAX), deleted.[PriorityName]) , 								CONVERT(VARCHAR(MAX), inserted.[PriorityName]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[PriorityName] <> deleted.[PriorityName]) OR (inserted.[PriorityName] IS NULL AND deleted.[PriorityName] IS NOT NULL) OR (inserted.[PriorityName] IS NOT NULL AND deleted.[PriorityName] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([RateTemplate])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'RateTemplate' , 								CONVERT(VARCHAR(MAX), deleted.[RateTemplate]) , 								CONVERT(VARCHAR(MAX), inserted.[RateTemplate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[RateTemplate] <> deleted.[RateTemplate]) OR (inserted.[RateTemplate] IS NULL AND deleted.[RateTemplate] IS NOT NULL) OR (inserted.[RateTemplate] IS NOT NULL AND deleted.[RateTemplate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Revision])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Revision' , 								CONVERT(VARCHAR(MAX), deleted.[Revision]) , 								CONVERT(VARCHAR(MAX), inserted.[Revision]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[Revision] <> deleted.[Revision]) OR (inserted.[Revision] IS NULL AND deleted.[Revision] IS NOT NULL) OR (inserted.[Revision] IS NOT NULL AND deleted.[Revision] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMCo])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMCo' , 								CONVERT(VARCHAR(MAX), deleted.[SMCo]) , 								CONVERT(VARCHAR(MAX), inserted.[SMCo]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[SMCo] <> deleted.[SMCo]) OR (inserted.[SMCo] IS NULL AND deleted.[SMCo] IS NOT NULL) OR (inserted.[SMCo] IS NOT NULL AND deleted.[SMCo] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SMWorkOrderScopeID])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SMWorkOrderScopeID' , 								CONVERT(VARCHAR(MAX), deleted.[SMWorkOrderScopeID]) , 								CONVERT(VARCHAR(MAX), inserted.[SMWorkOrderScopeID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[SMWorkOrderScopeID] <> deleted.[SMWorkOrderScopeID]) OR (inserted.[SMWorkOrderScopeID] IS NULL AND deleted.[SMWorkOrderScopeID] IS NOT NULL) OR (inserted.[SMWorkOrderScopeID] IS NOT NULL AND deleted.[SMWorkOrderScopeID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([SaleLocation])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'SaleLocation' , 								CONVERT(VARCHAR(MAX), deleted.[SaleLocation]) , 								CONVERT(VARCHAR(MAX), inserted.[SaleLocation]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[SaleLocation] <> deleted.[SaleLocation]) OR (inserted.[SaleLocation] IS NULL AND deleted.[SaleLocation] IS NOT NULL) OR (inserted.[SaleLocation] IS NOT NULL AND deleted.[SaleLocation] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Scope])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Scope' , 								CONVERT(VARCHAR(MAX), deleted.[Scope]) , 								CONVERT(VARCHAR(MAX), inserted.[Scope]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[Scope] <> deleted.[Scope]) OR (inserted.[Scope] IS NULL AND deleted.[Scope] IS NOT NULL) OR (inserted.[Scope] IS NOT NULL AND deleted.[Scope] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([Service])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'Service' , 								CONVERT(VARCHAR(MAX), deleted.[Service]) , 								CONVERT(VARCHAR(MAX), inserted.[Service]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[Service] <> deleted.[Service]) OR (inserted.[Service] IS NULL AND deleted.[Service] IS NOT NULL) OR (inserted.[Service] IS NOT NULL AND deleted.[Service] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([ServiceCenter])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceCenter' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceCenter]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceCenter]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[ServiceCenter] <> deleted.[ServiceCenter]) OR (inserted.[ServiceCenter] IS NULL AND deleted.[ServiceCenter] IS NOT NULL) OR (inserted.[ServiceCenter] IS NOT NULL AND deleted.[ServiceCenter] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([ServiceItem])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'ServiceItem' , 								CONVERT(VARCHAR(MAX), deleted.[ServiceItem]) , 								CONVERT(VARCHAR(MAX), inserted.[ServiceItem]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[ServiceItem] <> deleted.[ServiceItem]) OR (inserted.[ServiceItem] IS NULL AND deleted.[ServiceItem] IS NOT NULL) OR (inserted.[ServiceItem] IS NOT NULL AND deleted.[ServiceItem] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([TaxCode])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxCode' , 								CONVERT(VARCHAR(MAX), deleted.[TaxCode]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxCode]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[TaxCode] <> deleted.[TaxCode]) OR (inserted.[TaxCode] IS NULL AND deleted.[TaxCode] IS NOT NULL) OR (inserted.[TaxCode] IS NOT NULL AND deleted.[TaxCode] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([TaxGroup])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxGroup' , 								CONVERT(VARCHAR(MAX), deleted.[TaxGroup]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxGroup]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[TaxGroup] <> deleted.[TaxGroup]) OR (inserted.[TaxGroup] IS NULL AND deleted.[TaxGroup] IS NOT NULL) OR (inserted.[TaxGroup] IS NOT NULL AND deleted.[TaxGroup] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([TaxRate])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxRate' , 								CONVERT(VARCHAR(MAX), deleted.[TaxRate]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxRate]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[TaxRate] <> deleted.[TaxRate]) OR (inserted.[TaxRate] IS NULL AND deleted.[TaxRate] IS NOT NULL) OR (inserted.[TaxRate] IS NOT NULL AND deleted.[TaxRate] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([TaxType])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'TaxType' , 								CONVERT(VARCHAR(MAX), deleted.[TaxType]) , 								CONVERT(VARCHAR(MAX), inserted.[TaxType]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[TaxType] <> deleted.[TaxType]) OR (inserted.[TaxType] IS NULL AND deleted.[TaxType] IS NOT NULL) OR (inserted.[TaxType] IS NOT NULL AND deleted.[TaxType] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([UniqueAttchID])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'UniqueAttchID' , 								CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) , 								CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([UseAgreementRates])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'UseAgreementRates' , 								CONVERT(VARCHAR(MAX), deleted.[UseAgreementRates]) , 								CONVERT(VARCHAR(MAX), inserted.[UseAgreementRates]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[UseAgreementRates] <> deleted.[UseAgreementRates]) OR (inserted.[UseAgreementRates] IS NULL AND deleted.[UseAgreementRates] IS NOT NULL) OR (inserted.[UseAgreementRates] IS NOT NULL AND deleted.[UseAgreementRates] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([WorkOrder])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkOrder' , 								CONVERT(VARCHAR(MAX), deleted.[WorkOrder]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkOrder]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[WorkOrder] <> deleted.[WorkOrder]) OR (inserted.[WorkOrder] IS NULL AND deleted.[WorkOrder] IS NOT NULL) OR (inserted.[WorkOrder] IS NOT NULL AND deleted.[WorkOrder] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([WorkOrderQuote])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkOrderQuote' , 								CONVERT(VARCHAR(MAX), deleted.[WorkOrderQuote]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkOrderQuote]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[WorkOrderQuote] <> deleted.[WorkOrderQuote]) OR (inserted.[WorkOrderQuote] IS NULL AND deleted.[WorkOrderQuote] IS NOT NULL) OR (inserted.[WorkOrderQuote] IS NOT NULL AND deleted.[WorkOrderQuote] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

							IF UPDATE([WorkScope])
							BEGIN
							INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)
										OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
								SELECT 							'vSMWorkOrderScope' , 								'<KeyString SMCo = "' + REPLACE(CAST(ISNULL(inserted.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(inserted.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(inserted.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />' , 								inserted.SMCo , 								'C' , 								'WorkScope' , 								CONVERT(VARCHAR(MAX), deleted.[WorkScope]) , 								CONVERT(VARCHAR(MAX), inserted.[WorkScope]) , 								GETDATE() , 								SUSER_SNAME()
							FROM inserted
								INNER JOIN deleted
									ON  inserted.[SMWorkOrderScopeID] = deleted.[SMWorkOrderScopeID] 
									AND ((inserted.[WorkScope] <> deleted.[WorkScope]) OR (inserted.[WorkScope] IS NULL AND deleted.[WorkScope] IS NOT NULL) OR (inserted.[WorkScope] IS NOT NULL AND deleted.[WorkScope] IS NULL))
								JOIN dbo.vAuditFlagCompany AS afc ON inserted.SMCo = afc.AuditCo 
							WHERE afc.AuditFlagID = 14

							END 

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, 'bSMCo', i.SMCo, CAST(i.SMCo AS VARCHAR(30)), 'vSMWorkOrderScope'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString SMCo = "' + REPLACE(CAST(ISNULL(i.[SMCo],'') AS VARCHAR(MAX)),'"', '&quot;') + '" Scope = "' + REPLACE(CAST(ISNULL(i.[Scope],'') AS VARCHAR(MAX)),'"', '&quot;') + '" WorkOrder = "' + REPLACE(CAST(ISNULL(i.[WorkOrder],'') AS VARCHAR(MAX)),'"', '&quot;') + '" />'


 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtvSMWorkOrderScope_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderScope_Audit_Update]', 'last', 'update', null
GO

EXEC sp_settriggerorder N'[dbo].[vtvSMWorkOrderScope_Audit_Update]', 'last', 'update', null
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] ADD CONSTRAINT [PK_vSMWorkOrderScope] PRIMARY KEY CLUSTERED  ([SMWorkOrderScopeID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] ADD CONSTRAINT [IX_vSMWorkOrderScope_SMCo_WorkOrder_Scope] UNIQUE NONCLUSTERED  ([SMCo], [WorkOrder], [Scope]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] ADD CONSTRAINT [IX_vSMWorkOrderScope_SMCo_WorkOrder_Scope_Agreement_Revision_Service] UNIQUE NONCLUSTERED  ([SMCo], [WorkOrder], [Scope], [Agreement], [Revision], [Service]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderScope_vSMScopePriority] FOREIGN KEY ([PriorityName]) REFERENCES [dbo].[vSMScopePriority] ([PriorityName])
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderScope_vSMAgreementService] FOREIGN KEY ([SMCo], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service])
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderScope_vSMCallType] FOREIGN KEY ([SMCo], [CallType]) REFERENCES [dbo].[vSMCallType] ([SMCo], [CallType])
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderScope_vSMRateTemplate] FOREIGN KEY ([SMCo], [RateTemplate]) REFERENCES [dbo].[vSMRateTemplate] ([SMCo], [RateTemplate])
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderScope_vSMDivision] FOREIGN KEY ([SMCo], [ServiceCenter], [Division]) REFERENCES [dbo].[vSMDivision] ([SMCo], [ServiceCenter], [Division])
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderScope_vSMWorkOrder] FOREIGN KEY ([SMCo], [WorkOrder], [ServiceCenter]) REFERENCES [dbo].[vSMWorkOrder] ([SMCo], [WorkOrder], [ServiceCenter]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[vSMWorkOrderScope] WITH NOCHECK ADD CONSTRAINT [FK_vSMWorkOrderScope_vSMWorkScope] FOREIGN KEY ([SMCo], [WorkScope]) REFERENCES [dbo].[vSMWorkScope] ([SMCo], [WorkScope])
GO
