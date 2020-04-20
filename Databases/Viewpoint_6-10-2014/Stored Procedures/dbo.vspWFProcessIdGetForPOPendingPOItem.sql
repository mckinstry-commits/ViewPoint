SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[vspWFProcessIdGetForPOPendingPOItem]
/***********************************************************
* CREATED BY:	GF 04/18/2012 TK-14088 PO work flow
* MODIFIED BY:	
*
*				
* USAGE:
* used within the work flow class to get a process id
* for the PO Pending Purchase Order form.
* returns a work flow process id for a POPendingPOItem record .
* if no process is in place then will return null
*
* There are 3 levels that need to be checked to get the POPendingPOItem process id.
* These levels are dependent based on the item type.
* 1. Level 3 is the most detailed level for job, location, or EM department
* 2. Level 2 is the next level up for JCCo, INCo, GLCo, or EMCo
* 3. Level 1 is the last level up for the HQ Company.
*
* This procedure will return the process id for the item at either
* level 3, level 2, or level 1 in that order.
*
* INPUT PARAMETERS
* @SrcKeyId		the source PO item key id to check for a work flow process
*
* OUTPUT PARAMETERS
* @ProcessId	the work flow process id found for the po item or NULL
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 
(@SrcKeyId BIGINT = NULL, @ProcessId BIGINT = NULL OUTPUT)
AS
SET NOCOUNT ON

declare @rcode INT, @ItemType TINYINT,
		@wflevel3 BIGINT,
		@wflevel2 BIGINT,
		@wflevel1 BIGINT

SET @rcode = 0
SET @ProcessId = NULL
SET @wflevel3 = NULL
SET @wflevel2 = NULL
SET @wflevel1 = NULL

---- must have a PMMF source key id
IF @SrcKeyId IS NULL RETURN

---- get the POPendingPurchaseOrder.ItemType
SELECT @ItemType = ItemType
FROM dbo.vPOPendingPurchaseOrderItem
WHERE KeyID = @SrcKeyId
---- if record not found done
IF @@ROWCOUNT = 0 RETURN
	
---- if the item type is 6 - SM Work Order return null - not available yet
IF @ItemType = 6 RETURN

---- work flow level 1 is checked for all of the item types - get first
SELECT @wflevel1 = wflevel1.KeyID
FROM dbo.vPOPendingPurchaseOrderItem src
	OUTER APPLY (SELECT wflevel1.KeyID
					FROM dbo.vWFProcess wflevel1
					INNER JOIN dbo.vHQCompanyProcess hq ON hq.Process = wflevel1.Process
					WHERE hq.Mod = 'HQ' 
						AND hq.DocType = 'PO' 
						AND hq.HQCo = src.POCo
						AND hq.Active = 'Y') wflevel1
						
WHERE src.KeyID = @SrcKeyId
	
---- process Job item type to locate a valid work flow process
IF @ItemType = 1
	BEGIN
	SELECT @ProcessId = COALESCE(wflevel3.KeyID, wflevel2.KeyID, @wflevel1)
	FROM dbo.vPOPendingPurchaseOrderItem src
					
		OUTER APPLY (SELECT wflevel2.KeyID
							FROM dbo.vHQCompanyProcess toco
							INNER JOIN dbo.vWFProcess wflevel2 ON wflevel2.Process = toco.Process
							WHERE toco.Mod = 'JC' 
								AND toco.DocType = 'PO' 
								AND toco.HQCo = src.JCCo
								AND toco.Active = 'Y') wflevel2

		OUTER APPLY (SELECT wflevel3.KeyID
							FROM dbo.JCJobApprovalProcess job
							INNER JOIN dbo.WFProcess wflevel3 ON wflevel3.Process = job.Process
							WHERE job.JCCo = src.JCCo
								AND job.DocType = 'PO' 
								AND job.Job = src.Job
								AND job.Active = 'Y') wflevel3
								
	WHERE src.KeyID = @SrcKeyId
	IF @@ROWCOUNT = 0 SET @ProcessId = NULL
	END

---- process Inventory item type to locate a valid work flow process
IF @ItemType = 2
	BEGIN
	SELECT @ProcessId = COALESCE(wflevel3.KeyID, wflevel2.KeyID, @wflevel1)
	FROM dbo.vPOPendingPurchaseOrderItem src
							
		OUTER APPLY (SELECT wflevel2.KeyID
				FROM dbo.vHQCompanyProcess toco
				INNER JOIN dbo.vWFProcess wflevel2 ON wflevel2.Process = toco.Process
				WHERE toco.Mod = 'IN' 
					AND toco.DocType = 'PO' 
					AND toco.HQCo = src.INCo
					AND toco.Active = 'Y'
				) wflevel2
			
		OUTER APPLY (SELECT wflevel3.KeyID
				FROM dbo.vINLocationApprovalProcess loc
				INNER JOIN dbo.vWFProcess wflevel3 ON wflevel3.Process = loc.Process
				WHERE loc.INCo = src.INCo 
					AND loc.DocType = 'PO' 
					AND loc.Loc = src.Loc
					AND loc.Active = 'Y'
				) wflevel3

	WHERE src.KeyID = @SrcKeyId
	IF @@ROWCOUNT = 0 SET @ProcessId = NULL
	END

---- process Expense item type to locate a valid work flow process
IF @ItemType = 3
	BEGIN
	SELECT @ProcessId = COALESCE(wflevel2.KeyID, @wflevel1)
	FROM dbo.vPOPendingPurchaseOrderItem src
							
		OUTER APPLY (SELECT wflevel2.KeyID
				FROM dbo.vHQCompanyProcess toco
				INNER JOIN dbo.vWFProcess wflevel2 ON wflevel2.Process = toco.Process
				WHERE toco.Mod = 'GL' 
					AND toco.DocType = 'PO' 
					AND toco.HQCo = src.GLCo
					AND toco.Active = 'Y'
				) wflevel2
				
	WHERE src.KeyID = @SrcKeyId
	IF @@ROWCOUNT = 0 SET @ProcessId = NULL
	END

---- process Equipment item type to locate a valid work flow process
IF @ItemType = 4
	BEGIN
	SELECT @ProcessId = COALESCE(wflevel3.KeyID, wflevel2.KeyID, @wflevel1)
	FROM dbo.vPOPendingPurchaseOrderItem src
							
		OUTER APPLY (SELECT wflevel2.KeyID
				FROM dbo.vHQCompanyProcess toco
				INNER JOIN dbo.vWFProcess wflevel2 ON wflevel2.Process = toco.Process
				WHERE toco.Mod = 'EM' 
					AND toco.DocType = 'PO' 
					AND toco.HQCo = src.EMCo
					AND toco.Active = 'Y'
				) wflevel2
			
		OUTER APPLY (SELECT wflevel3.KeyID
				FROM dbo.bEMEM emem
				INNER JOIN dbo.vEMDepartmentApprovalProcess empr ON empr.EMCo=emem.EMCo AND empr.Department=emem.Department
				INNER JOIN dbo.vWFProcess wflevel3 ON wflevel3.Process = empr.Process
				WHERE emem.EMCo = src.EMCo
					AND emem.Equipment = src.Equip
					AND empr.EMCo = src.EMCo
					AND empr.DocType = 'PO'
					AND empr.Department = emem.Department
					AND empr.Active = 'Y'
				) wflevel3

	WHERE src.KeyID = @SrcKeyId
	IF @@ROWCOUNT = 0 SET @ProcessId = NULL
	END


---- process EM WO item type to locate a valid work flow process
IF @ItemType = 5
	BEGIN
	SELECT @ProcessId = COALESCE(wflevel3.KeyID, wflevel2.KeyID, @wflevel1)
	FROM dbo.vPOPendingPurchaseOrderItem src
							
		OUTER APPLY (SELECT wflevel2.KeyID
					FROM dbo.vHQCompanyProcess toco
					INNER JOIN dbo.vWFProcess wflevel2 ON wflevel2.Process = toco.Process
					WHERE toco.Mod = 'EM' 
						AND toco.DocType = 'PO' 
						AND toco.HQCo = src.EMCo
						AND toco.Active = 'Y'
					) wflevel2
			
		OUTER APPLY (SELECT wflevel3.KeyID
					FROM dbo.bEMWH emwh
					INNER JOIN dbo.bEMEM emem ON emem.EMCo=emwh.EMCo AND emem.Equipment=emwh.Equipment
					INNER JOIN dbo.vEMDepartmentApprovalProcess empr ON empr.EMCo=emem.EMCo AND empr.Department=emem.Department
					INNER JOIN dbo.vWFProcess wflevel3 ON wflevel3.Process = empr.Process
					WHERE emwh.EMCo = src.EMCo
						AND emwh.WorkOrder = src.WO
						AND empr.EMCo = src.EMCo
						AND empr.DocType = 'PO'
						AND empr.Department = emem.Department
						AND empr.Active = 'Y'
					) wflevel3

	WHERE src.KeyID = @SrcKeyId
	IF @@ROWCOUNT = 0 SET @ProcessId = NULL
	END



GO
GRANT EXECUTE ON  [dbo].[vspWFProcessIdGetForPOPendingPOItem] TO [public]
GO
