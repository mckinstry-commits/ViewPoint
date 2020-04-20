SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE procedure [dbo].[vspSMModifySMPOItemLine]
/************************************************************************
* Created By:	JG 09/22/2011 
* MODIFIED By:	
*
* Purpose of Stored Procedure
* Create/update/delete a SMPOItemLine extension records.
*    
* 
* Inputs
* @POCo				- Company of the PO
* @PO				- PO name
* @POItem			- PO Item number
* @POItemLine		- PO Item Line Number
*
* Outputs
* @rcode		- 0 = successfull - 1 = error
* @errmsg		- Error Message
*
*************************************************************************/

(@POCo bCompany, @PO VARCHAR(30), @POItem bItem, @POItemLine INT, @ColumnsUpdated varbinary(max),
 @msg varchar(255) output)

AS
SET NOCOUNT ON

DECLARE @rcode INT, @GLCo dbo.bCompany, @CostAcct CHAR(20), @CostWIPAcct CHAR(20)
		, @SMCo bCompany, @SMWorkOrder INT, @SMScope INT, @POItemType TINYINT

SET @rcode = 0

--Don't do any updates if we only updated the GLCo and GLAcct because this update happens on PO Receipt Batch Validation and when
--moving the gl from one account to another.
IF @ColumnsUpdated IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.vfColumnsUpdated(@ColumnsUpdated, 'vPOItemLine') WHERE ColumnsUpdated NOT IN ('GLCo', 'GLAcct'))
	GOTO vspExit

-- VALIDATE INPUTS --

SELECT @SMCo = SMCo
	, @SMWorkOrder = SMWorkOrder
	, @SMScope = SMScope
	, @POItemType = ItemType 
FROM dbo.POItemLine 
WHERE POCo = @POCo 
	AND PO = @PO 
	AND POItem = @POItem 
	AND POItemLine = @POItemLine

IF @@ROWCOUNT = 0
BEGIN
	SELECT @rcode = 1, @msg = 'Missing PO Item Line record.'
	GOTO vspExit
END

-- Check if ItemType is 6 - if not, then delete
IF @POItemType = 6
BEGIN
	IF @SMCo IS NULL OR @SMWorkOrder IS NULL OR @SMScope IS NULL
	BEGIN
		SELECT @rcode = 1, @msg = 'Missing SMCo or SMWorkOrder or SMScope.'
		GOTO vspExit
	END
END
-- Delete record if ItemType is not 6.
ELSE
BEGIN
	DELETE FROM vSMPOItemLine
	WHERE POCo = @POCo 
	AND PO = @PO
	AND POItem = @POItem
	AND POItemLine = @POItemLine
	
	GOTO vspExit
END

-- Grab accounts from SM data
SELECT @GLCo = GLCo, @CostAcct = CostGLAcct, @CostWIPAcct = CostWIPGLAcct 
FROM dbo.vfSMGetAccountingTreatment(@SMCo, @SMWorkOrder, @SMScope, 5, NULL)

-- Validate account
IF @@ROWCOUNT != 1
BEGIN
	SELECT @msg = 'Unable to find account info for SMCo: ' + @SMCo + ', Work Order: ' + @SMWorkOrder + ', Scope: ' + @SMScope + '.', @rcode = 1
	GOTO vspExit
END
	
-- Check if SMPOItemLine record exists - if so - update otherwise add
IF EXISTS (SELECT 1 FROM dbo.vSMPOItemLine WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine)
BEGIN
	DECLARE @RecvdUnits bUnits, @RecvdCost bDollar, @InvUnits bUnits, @InvCost bDollar
	
	SELECT @RecvdUnits = RecvdUnits, @RecvdCost = RecvdCost, @InvUnits = InvUnits, @InvCost = InvCost
	FROM dbo.POItemLine
	WHERE POCo = @POCo
		AND PO = @PO
		AND POItem = @POItem
		AND POItemLine = @POItemLine
	
	-- Don't update if Received Cost or Invoiced Cost is not zero
	IF @RecvdUnits <> 0 OR @RecvdCost <> 0 OR @InvUnits <> 0 OR @InvCost <> 0
		GOTO vspExit

	IF EXISTS(SELECT 1 FROM dbo.SMWorkCompleted WHERE POCo = @POCo AND PONumber = @PO AND POItem = @POItem AND POItemLine = @POItemLine)
		GOTO vspExit

	--UPDATE
	UPDATE dbo.vSMPOItemLine
	SET GLCo = @GLCo
	, CostWIPAccount = @CostWIPAcct
	, CostAccount = @CostAcct
	WHERE POCo = @POCo
	AND PO = @PO
	AND POItem = @POItem
	AND POItemLine = @POItemLine
END
ELSE
BEGIN
	--NEW
	INSERT INTO dbo.vSMPOItemLine (
		POCo,
		PO,
		POItem,
		POItemLine,
		SMCo,
		SMCostType,
		GLCo,
		CostWIPAccount,
		CostAccount
	) VALUES ( 
		/* POCo - bCompany */ @POCo,
		/* PO - varchar(30) */ @PO,
		/* POItem - bItem */ @POItem,
		/* POItemLine - int */ @POItemLine,
		/* SMCo - bCompany */ @SMCo,
		/* SMCostType - smallint */ NULL,
		/* GLCo - bCompany */ @GLCo,
		/* CostWIPAccount - bGLAcct */ @CostWIPAcct,
		/* CostAccount - bGLAcct */ @CostAcct ) 
END	

vspExit:
	RETURN @rcode
	

	
	
GO
GRANT EXECUTE ON  [dbo].[vspSMModifySMPOItemLine] TO [public]
GO
