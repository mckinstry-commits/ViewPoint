SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************/
CREATE proc [dbo].[vspPMPCOSItemsDetail]
/********************************************************
* Created By:	JG 06/24/2011
* Modified By:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
*				JG 02/21/2012 TK-12788 - Updated the way we check if items exist.
*
* USAGE:
* Returns if a SL/PO item exists or not (returns no if the only existing is the one 
* we're modifying).
*
* When SL/PO items exist within SLIT/POIT or PMSL/PMMF, we are unable to modify 
* values that are previously set within PCO.
*
* The only values that are changeable are units (if not LS) and the purchase amount.  
* The UM and the Unit Price are set from the existing item.
*
* The stored procedure "vspPMPCOSItemsDetail" has been modified for these checks.  
* If the item is new or if the item is the only instance of the existing item in 
* PMSL/PMMF, then the procedure will return 'N' for the item existing.
*
* OUTPUT PARAMETERS:
*	ItemExists
*
*	
* RETURN VALUE:
* 	0 	    Success
*	1		Failure
*
**********************************************************/
(@pmco bCompany=NULL, @project bJob=NULL, @pcotype bDocType=NULL, @pco bPCO=NULL, @pcoitem bPCOItem=NULL, @po varchar(30)=NULL, @sl VARCHAR(30)=NULL, @item bItem=NULL,
 @phase bPhase=NULL, @costtype dbo.bJCCType=NULL, @itemexists bYN='N' OUTPUT)
as 
set nocount on

declare @rcode INT, @apco bCompany, @rowcount INT
select @rcode = 0, @itemexists = 'N'

SELECT @apco = APCo
FROM dbo.PMCO
WHERE PMCo = @pmco

----Check for POs first
IF @po IS NOT NULL
BEGIN
	----Check if there is a POIT item for the PMOL item we're looking at.
	IF EXISTS (SELECT 1 FROM POIT WHERE POCo = @apco AND PO = @po AND POItem = @item)
	BEGIN
		SET @itemexists = 'Y'
	END
	ELSE
	BEGIN
		----Get the number of PO Item recods that have already been created
		SELECT 1 
		FROM PMMF 
		WHERE POCo = @apco
			AND PO = @po
			AND POItem = @item
		
		SET @rowcount = @@ROWCOUNT 
		
		----If more than 1, then we're dealing with an existing record and none can be modified
		IF @rowcount > 1
		BEGIN
			SET @itemexists = 'Y'
		END
		----If just one, check that the PMSL item is the PMOL item we're modifying
		ELSE IF @rowcount = 1
		BEGIN
			If NOT EXISTS (SELECT 1 
							FROM PMMF 
							WHERE PMCo = @pmco 
								AND Project = @project 
								AND PCOType = @pcotype
								AND PCO = @pco
								AND PCOItem = @pcoitem
								AND PO = @po
								AND POItem = @item
								AND Phase = @phase
								AND CostType = @costtype)
			BEGIN
				SET @itemexists = 'Y'
			END
		END
	END
END
----Check for SLs
ELSE IF @sl IS NOT NULL
BEGIN
	----Check for an existing SLIT item for the PMOL item we're looking into
	IF EXISTS (SELECT 1 FROM SLIT WHERE SLCo = @apco AND SL = @sl AND SLItem = @item)
	BEGIN
		SET @itemexists = 'Y'
	END
	ELSE
	BEGIN
		----Get the count of PMSL records that match the SL Item we're looking into
		SELECT 1 
		FROM PMSL 
		WHERE SLCo = @apco
			AND SL = @sl
			AND SLItem = @item
		
		SET @rowcount = @@ROWCOUNT 
		
		----If more than one, then we're dealing with duplicates and can't make a change
		IF @rowcount > 1
		BEGIN
			SET @itemexists = 'Y'
		END
		----If just one, then check if we're modifying the PMSL item we're dealing with
		ELSE IF @rowcount = 1
		BEGIN
			If NOT EXISTS (SELECT 1 
							FROM PMSL 
							WHERE PMCo = @pmco 
								AND Project = @project 
								AND PCOType = @pcotype
								AND PCO = @pco
								AND PCOItem = @pcoitem
								AND SL = @sl
								AND SLItem = @item
								AND Phase = @phase
								AND CostType = @costtype)
			BEGIN
				SET @itemexists = 'Y'
			END
		END
	END
END

bspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOSItemsDetail] TO [public]
GO
