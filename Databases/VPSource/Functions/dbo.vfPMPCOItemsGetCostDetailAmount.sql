SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jason Gill
-- Create date: 03/11/2011
-- Description:	Sum and return either the phase/costtypes EstCost or Purchase amounts
-- Modified:`	GP 03/16/2011 - V1# TK-02660 added ability to get sum at PCO level with null PCOItem
--					for PM Change Order Request PCO tab.
--				GP 06/05/2011 - V1# D-02406 removed @pcoitem IS NULL from return 0 if condition
--
-- Inputs:
--	Co
--	Project
--	PCOType
--	PCO
--	PCOItem
--	AmountType
-- =============================================
CREATE FUNCTION [dbo].[vfPMPCOItemsGetCostDetailAmount]
(@co dbo.bCompany, @project dbo.bJob, @pcotype dbo.bPCOType, @pco dbo.bPCO, @pcoitem dbo.bPCOItem = null, @amounttype CHAR)
RETURNS bDollar
AS
BEGIN 
	DECLARE @amount dbo.bDollar
	SELECT @amount = 0

	IF @co IS NULL OR @project IS NULL OR @pcotype IS NULL OR @pco IS NULL OR @amounttype IS NULL
	BEGIN
		RETURN 0
	END
	
	IF @amounttype = 'E'
	BEGIN
		SELECT @amount = ISNULL(SUM(EstCost),0) FROM PMOL
		WHERE PMCo = @co
		AND Project = @project
		AND PCOType = @pcotype
		AND PCO = @pco
		AND PCOItem = isnull(@pcoitem, PCOItem)
		
		--SELECT @amount = 55
	END
	ELSE IF @amounttype = 'P'
	BEGIN
		SELECT @amount = ISNULL(SUM(PurchaseAmt),0) FROM PMOL
		WHERE PMCo = @co
		AND Project = @project
		AND PCOType = @pcotype
		AND PCO = @pco
		AND PCOItem = isnull(@pcoitem, PCOItem)
	END
	ELSE
	BEGIN
		RETURN 0
	END
		
	RETURN @amount
	
END

GO
GRANT EXECUTE ON  [dbo].[vfPMPCOItemsGetCostDetailAmount] TO [public]
GO
