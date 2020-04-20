SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/***********************************************************
* CREATED BY:	GF 05/14/2012 TK-14648 B-08882 retrieve vital PO data for work flow
* MODIFIED By:	GF 06/07/2012 TK-15581 look at last step for each item 
*
*
*
* USAGE:
* This function is used to return the the current status of the work flow process
* for the header source (i.e. PO) not the item status. All that will be returned
* here is whether the source has been submitted for approval and a summary of where the 
* source is in the approval process. This status is not the item status, but
* an aggregate for the source header.
*
* Currently will be used in PM PO Header and PO Pending Header and the work flow business layer.
*
* 10 - Draft no reviewers or error occurred.
* 15 - Draft Approval Required. Approvers exist when submitted. Handled by forms only.	
* 20 - Submitted for Approval Existing rewiewers for source but all new or submitted.
* 30 - Partial Approval. Not all reviewers have approved.
* 40 - Approved. All reviewers for source have approved.
* 50 - Rejected. Any status for any reviewer any item forces PO into a rejected state.
* 60 - Processed The PO is longer has status 0 - pending
* 
*
* INPUT PARAMETERS
* @SourceView		WF Source View tells the function if PO/SL or whatever.
* @poKeyId			POHD KeyId
*
*
* OUTPUT PARAMETERS
* @POWFData		table variable PO status, PO Amount, PO Detail Exists, POCONumOnly (PM)
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/

CREATE FUNCTION [dbo].[vfWFPOStatusGet]
(
		@Source		INTEGER = NULL
		,@poKeyId	BIGINT = NULL
)

RETURNS @PMPOWorkFlowData TABLE (POStatus INTEGER, POAmount numeric(20,2), PODetail BIT, POCONumOnly BIT)

AS
BEGIN

	DECLARE @POAmount		NUMERIC(20,2)
			,@POStatus		INTEGER
			,@PODetail		BIT
			,@POCo			TINYINT
			,@PO			VARCHAR(30)
			,@POCONumOnly	BIT
			,@POHDStatus	INTEGER
			,@ItemID		BIGINT
			,@StepID		BIGINT

	SET @POAmount = 0
	SET @POStatus = 10
	SET @PODetail = 0
	SET @POCONumOnly = 0
	SET @ItemID = 0

	---- get info for source PMMF
	IF @Source = 1
		BEGIN
		
		---- get info from POHD
		SELECT  @POCo = a.POCo
				,@PO = a.PO
				,@POHDStatus = [Status]
		FROM dbo.bPOHD a
		WHERE a.KeyID = @poKeyId
		IF @@ROWCOUNT = 0 GOTO Row_Insert
		
		---- get sum for PO
		SELECT @POAmount = ISNULL(SUM(Amount),0)
		FROM dbo.bPMMF
		WHERE POCo = @POCo
			AND PO = @PO
			AND InterfaceDate IS NULL
			AND POCONum IS NULL
			
		---- check status of PO, if Status < 3 then open, complete, closed
		IF @POHDStatus < 3
			BEGIN
			SET @POStatus = 60
			SET @PODetail = 1
			GOTO Row_Insert
			END
		
		---- check for PO detail in PMMF
		IF EXISTS(SELECT 1 FROM dbo.bPMMF WHERE POCo = @POCo AND PO = @PO
						AND InterfaceDate IS NULL
						AND POCONum IS NULL)
			BEGIN
			SET @PODetail = 1
			END
				
		---- check if PMMF detail for PO is only POCONum detail
		---- PO change orders are currently not going through the work flow process
		IF @PODetail = 0 AND EXISTS(SELECT 1 FROM dbo.bPMMF WHERE POCo = @POCo
						AND PO = @PO AND InterfaceDate IS NULL AND POCONum IS NOT NULL)
			BEGIN
			SET @PODetail = 1
			SET @POCONumOnly = 1
			SET @POStatus = 10
			GOTO Row_Insert
			END

		---- is the PO in work flow yet?
		IF NOT EXISTS(SELECT 1 FROM dbo.WFProcessDetailApproverForPMMF WHERE POCo = @POCo AND PO = @PO)
			BEGIN
			SET @POStatus = 10
			GOTO Row_Insert
			END
			
		---- check for status (0,1) - awaiting review or approval
		IF NOT EXISTS(SELECT 1 FROM dbo.WFProcessDetailApproverForPMMF WHERE POCo = @POCo
						AND PO = @PO
						AND [Status] > 1)
			BEGIN
			SET @POStatus = 20
			GOTO Row_Insert
			END
			
		---- now get status 3 - rejected count. do this first.
		---- if any approver has rejected optional or required
		---- then status is rejected and do not need to do other checks
		IF EXISTS(SELECT 1 FROM dbo.WFProcessDetailApproverForPMMF
					WHERE POCo = @POCo
						AND PO = @PO
						AND [Status] = 3)
			BEGIN
			SET @POStatus = 50
			GOTO Row_Insert
			END
			
		---- check for status 2 - approved
		IF NOT EXISTS(SELECT 1 FROM dbo.WFProcessDetailApproverForPMMF WHERE POCo = @POCo
						AND PO = @PO
						AND [Status] <> 2)
			BEGIN
			SET @POStatus = 40
			GOTO Row_Insert
			END

		END
		
		
	---- get info for source POPending
	IF @Source = 2
		BEGIN	

		---- get info for PO
		SELECT @POCo = a.POCo
				,@PO = a.PO
		FROM dbo.vPOPendingPurchaseOrder a
		WHERE a.KeyID = @poKeyId
		IF @@ROWCOUNT = 0 GOTO Row_Insert

		---- get sum for PO
		SELECT @POAmount = ISNULL(SUM(OrigCost),0)
		FROM dbo.vPOPendingPurchaseOrderItem
		WHERE POCo = @POCo
			AND PO = @PO
			
		---- check status of PO if exists and Status > 0 then open or complete
		IF EXISTS(SELECT 1 FROM dbo.bPOHD WHERE POCo=@POCo AND PO=@PO AND [Status] < 3)
			BEGIN
			----interfaced
			SET @POStatus = 60
			SET @PODetail = 1
			GOTO Row_Insert
			END
		
		---- check for PO detail in POPendingPurchaseOrderItem
		IF EXISTS(SELECT 1 FROM dbo.vPOPendingPurchaseOrderItem WHERE POCo = @POCo AND PO = @PO)
			BEGIN
			SET @PODetail = 1
			END

		---- is the PO in work flow yet?
		IF NOT EXISTS(SELECT 1 FROM dbo.WFProcessDetailApproverForPO WHERE POCo = @POCo AND PO = @PO)
			BEGIN
			SET @POStatus = 10
			GOTO Row_Insert
			END
			
		---- check for status (0,1) - awaiting review or approval
		IF NOT EXISTS(SELECT 1 FROM dbo.WFProcessDetailApproverForPO WHERE POCo = @POCo
						AND PO = @PO
						AND [Status] > 1)
			BEGIN
			SET @POStatus = 20
			GOTO Row_Insert
			END
			
		---- check for a status 3 - rejected
		---- if any approver has rejected optional or required
		---- then status is rejected and do not need to do other checks
		IF EXISTS(SELECT 1 FROM dbo.WFProcessDetailApproverForPO WHERE POCo = @POCo
						AND PO = @PO
						AND [Status] = 3)
			BEGIN
			SET @POStatus = 50
			GOTO Row_Insert
			END

		---- check for status 2 - approved
		IF NOT EXISTS(SELECT 1 FROM dbo.WFProcessDetailApproverForPO WHERE POCo = @POCo
						AND PO = @PO
						AND [Status] <> 2)
			BEGIN
			SET @POStatus = 40
			GOTO Row_Insert
			END

		END


	----TK-15581
	---- get the status of the last step for the last item
	---- need to loop through each item and check if the last
	---- step for the item is in a partial state.
	---- PO Pending PO source
	IF @Source = 2
		BEGIN
		SELECT TOP 1 @ItemID = KeyID
		FROM dbo.WFProcessDetailForPO
		WHERE POCo = @POCo
			AND PO = @PO
		ORDER BY KeyID
		IF @@ROWCOUNT = 0 SET @ItemID = NULL
		END
	ELSE
		---- PMMF source	
		BEGIN
		SELECT TOP 1 @ItemID = KeyID
		FROM dbo.WFProcessDetailForPMMF
		WHERE POCo = @POCo
			AND PO = @PO
		ORDER BY KeyID
		IF @@ROWCOUNT = 0 SET @ItemID = NULL
		END

	---- cycle through items
	WHILE @ItemID IS NOT NULL
	BEGIN
		---- GET LAST STEP
		SET @StepID = 0
		SELECT TOP 1 @StepID = KeyID
		FROM dbo.vWFProcessDetailStep
		WHERE ProcessDetailID = @ItemID
		ORDER BY Step DESC
		
		---- analyze the approvers for the last item step
		---- check to see if the step is still in a partial state
		---- if true then the work flow status is partial approve
		---- and we can drop out of the while loop. review requited first
		IF @StepID > 0
			BEGIN
			IF EXISTS(SELECT 1 FROM dbo.vWFProcessDetailApprover a WHERE DetailStepID = @StepID
								AND ApproverOptional = 'N')
				BEGIN
				---- if required approver(s) have not approved then status - partial
				IF EXISTS(SELECT 1 FROM dbo.vWFProcessDetailApprover WHERE DetailStepID = @StepID
						AND ApproverOptional = 'N'
						AND [Status] <> 2)
					BEGIN
					SET @POStatus = 30
					GOTO Row_Insert
					END
				END
			ELSE
				BEGIN
				---- only step left is optional step where all the approvers are optional
				---- once any approver(s) approve the step, then the status - approved
				IF NOT EXISTS(SELECT 1 FROM dbo.vWFProcessDetailApprover WHERE DetailStepID = @StepID
								AND [Status] = 2)
					BEGIN
					SET @POStatus = 30
					GOTO Row_Insert
					END
				END
			END
			
		---- move to next item
		---- POPending source
		IF @Source = 2
			BEGIN
			SELECT @ItemID = MIN(KeyID)
			FROM dbo.WFProcessDetailForPO
			WHERE POCo = @POCo
				AND PO = @PO
				AND KeyID > @ItemID 
			IF @@ROWCOUNT = 0 SET @ItemID = NULL
			END
		ELSE
			---- PMMF source	
			BEGIN
			SELECT @ItemID = MIN(KeyID)
			FROM dbo.WFProcessDetailForPMMF
			WHERE POCo = @POCo
				AND PO = @PO
				AND KeyID > @ItemID 
			IF @@ROWCOUNT = 0 SET @ItemID = NULL
			END

	END ---end of item loop

	---- no partial approved steps found status - approved
	SET @POStatus = 40
	
		
	
	Row_Insert:
	INSERT INTO @PMPOWorkFlowData (POStatus, POAmount, PODetail, POCONumOnly) 
	VALUES (@POStatus, @POAmount, @PODetail, @POCONumOnly)
	
	
	RETURN
END



GO
GRANT SELECT ON  [dbo].[vfWFPOStatusGet] TO [public]
GO
