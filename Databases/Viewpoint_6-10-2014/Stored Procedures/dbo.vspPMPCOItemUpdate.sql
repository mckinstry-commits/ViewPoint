SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[vspPMPCOItemUpdate]
/***********************************************************
* Created By:	  ScottP 03/06/2013 TK-42879  create procedure
*				
*Procedure is used by the PM PCO Item Update to update fields in the PCO Item record
*		
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
( @KeyIDString varchar(max), @ContractItem bContractItem = null, 
@errormsg VARCHAR(255) OUTPUT)

AS

SET NOCOUNT ON
   
DECLARE @CurrentKeyID varchar(10)

IF @KeyIDString is null
	BEGIN
		SELECT @errormsg = 'No PCO Items to update. Missing KeyID string'
		RETURN 1
	END

WHILE @KeyIDString IS NOT NULL
BEGIN
	--Get next KeyID
	IF CHARINDEX(CHAR(44), @KeyIDString) <> 0
		BEGIN
			SELECT @CurrentKeyID = SUBSTRING(@KeyIDString, 1, CHARINDEX(CHAR(44), @KeyIDString) - 1)
		END
	ELSE
		BEGIN
			SELECT @CurrentKeyID = @KeyIDString	
		END	

     --Remove current keyid from keystring
	SELECT @KeyIDString = SUBSTRING(@KeyIDString, LEN(@CurrentKeyID) + 2, (LEN(@KeyIDString) - LEN(@CurrentKeyID) + 1))

	--Update Contract Item for the current KeyID
	IF @ContractItem IS NOT NULL 
	BEGIN
		UPDATE dbo.PMOI
		SET [ContractItem] = @ContractItem
		WHERE KeyID=@CurrentKeyID
	END
		
	--Get the final KeyID value
	IF CHARINDEX(CHAR(44), @KeyIDString) = 0	
	BEGIN
		SET @KeyIDString = @KeyIDString + CHAR(44)
	END

	--Set KeyIDstring to null if no values left
	IF LEN(@KeyIDString) < 2		
	BEGIN
		SET @KeyIDString = null
	END

--End While
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOItemUpdate] TO [public]
GO
