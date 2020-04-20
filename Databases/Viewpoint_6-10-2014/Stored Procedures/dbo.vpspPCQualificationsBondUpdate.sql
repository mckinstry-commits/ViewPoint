SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsBondUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @BondName VARCHAR(60), @BondBroker VARCHAR(60), @BondContact VARCHAR(30), @BondPhone bPhone, @BondFax bPhone, @BondEmail VARCHAR(60), @BondYears TINYINT, @BondCapacity NUMERIC(18,0), @BondCapicityPerJob NUMERIC(18,0), @BondLastDate bDate, @BondLastAmount NUMERIC(18,0), @BondLastRate bRate, @BondAddress1 VARCHAR(60), @BondCity VARCHAR(30), @BondState VARCHAR(4), @BondZip bZip, @BondCountry CHAR(2), @BondAddress2 VARCHAR(60), @BondFinishNotes VARCHAR(MAX), @BondPersonalGuarantee bYN)
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @rcode INT
	
	EXEC @rcode = vpspPCValidateStateCountry @BondState, @BondCountry
	IF @rcode != 0
	BEGIN
		GOTO vpspExit
	END
	
	UPDATE PCQualifications
	SET
		BondName = @BondName,
		BondBroker = @BondBroker,
		BondContact = @BondContact,
		BondPhone = @BondPhone,
		BondFax = @BondFax,
		BondEmail = @BondEmail,
		BondYears = @BondYears,
		BondCapacity = @BondCapacity,
		BondCapicityPerJob = @BondCapicityPerJob,
		BondLastDate = @BondLastDate,
		BondLastAmount = @BondLastAmount,
		BondLastRate = @BondLastRate,
		BondAddress1 = @BondAddress1,
		BondCity = @BondCity,
		BondState = @BondState,
		BondZip = @BondZip,
		BondCountry = @BondCountry,
		BondAddress2 = @BondAddress2,
		BondFinish = CASE WHEN dbo.vpfIsNullOrEmpty(@BondFinishNotes) = 1 THEN 'N' ELSE 'Y' END,
		BondFinishNotes = @BondFinishNotes,
		BondPersonalGuarantee = @BondPersonalGuarantee
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM
	
vpspExit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsBondUpdate] TO [VCSPortal]
GO
