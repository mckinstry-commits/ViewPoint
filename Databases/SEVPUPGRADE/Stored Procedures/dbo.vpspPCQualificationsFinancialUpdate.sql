SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCQualificationsFinancialUpdate]
	(@Original_APVMKeyIDFromAPVM INT, @DBNumber VARCHAR(30), @DBRating VARCHAR(5), @DBPayRecord TINYINT, @DBDateOfRating bDate, @RevenueYear SMALLINT, @RevenueAmount NUMERIC(18), @NetIncome NUMERIC(18), @NetEquity NUMERIC(18), @WorkingCapital NUMERIC(18), @AverageEmployees INT, @ThisYearVolume NUMERIC(18), @ThisYearProjects INT, @CurrentBacklog NUMERIC(18), @LiquidatedDamageNotes VARCHAR(MAX), @BankName VARCHAR(60), @BankBranch VARCHAR(60), @BankContact VARCHAR(30), @BankPhone bPhone, @BankFax bPhone, @BankEmail VARCHAR(60), @BankYears TINYINT, @BankLineOfCreditTotal NUMERIC(18), @BankLineOfCreditAvailable NUMERIC(18), @BankLineOfCreditExpiration bDate, @BankAddress1 VARCHAR(60), @BankCity VARCHAR(30), @BankState VARCHAR(4), @BankZip bZip, @BankCountry CHAR(2), @BankAddress2 VARCHAR(60), @CPAName VARCHAR(60), @CPAContact VARCHAR(30), @CPAPhone bPhone, @CPAFax bPhone, @CPAEmail VARCHAR(60), @CPAYears TINYINT, @CPAFinancialStatements TINYINT, @CPAAddress1 VARCHAR(60), @CPACity VARCHAR(60), @CPAState VARCHAR(4), @CPAZip bZip, @CPACountry CHAR(2), @CPAAddress2 VARCHAR(60))
AS
SET NOCOUNT ON;

BEGIN
	-- Validation
	DECLARE @rcode INT
	IF not @RevenueYear IS NULL
	BEGIN
		EXEC @rcode = vpspPCValidateYearField @RevenueYear
		
		IF @rcode != 0
		BEGIN
			GOTO vpspExit
		END
	END
	
	EXEC @rcode = vpspPCValidateStateCountry @BankState, @BankCountry
	IF @rcode != 0
	BEGIN
		GOTO vpspExit
	END
	
	EXEC @rcode = vpspPCValidateStateCountry @CPAState, @CPACountry
	IF @rcode != 0
	BEGIN
		GOTO vpspExit
	END
	
	-- Validation successful
	UPDATE PCQualifications
	SET
		DBNumber = @DBNumber,
		DBRating = @DBRating,
		DBPayRecord = @DBPayRecord,
		DBDateOfRating = @DBDateOfRating,
		RevenueYear = @RevenueYear,
		RevenueAmount = @RevenueAmount,
		NetIncome = @NetIncome,
		NetEquity = @NetEquity,
		WorkingCapital = @WorkingCapital,
		AverageEmployees = @AverageEmployees,
		ThisYearVolume = @ThisYearVolume,
		ThisYearProjects = @ThisYearProjects,
		CurrentBacklog = @CurrentBacklog,
		LiquidatedDamages = CASE WHEN dbo.vpfIsNullOrEmpty(@LiquidatedDamageNotes) = 1 THEN 'N' ELSE 'Y' END,
		LiquidatedDamageNotes = @LiquidatedDamageNotes,
		BankName = @BankName,
		BankBranch = @BankBranch,
		BankContact = @BankContact,
		BankPhone = @BankPhone,
		BankFax = @BankFax,
		BankEmail = @BankEmail,
		BankYears = @BankYears,
		BankLineOfCreditTotal = @BankLineOfCreditTotal,
		BankLineOfCreditAvailable = @BankLineOfCreditAvailable,
		BankLineOfCreditExpiration = @BankLineOfCreditExpiration,
		BankAddress1 = @BankAddress1,
		BankCity = @BankCity,
		BankState = @BankState,
		BankZip = @BankZip,
		BankCountry = @BankCountry,
		BankAddress2 = @BankAddress2,
		CPAName = @CPAName,
		CPAContact = @CPAContact,
		CPAPhone = @CPAPhone,
		CPAFax = @CPAFax,
		CPAEmail = @CPAEmail,
		CPAYears = @CPAYears,
		CPAFinancialStatements = @CPAFinancialStatements,
		CPAAddress1 = @CPAAddress1,
		CPACity = @CPACity,
		CPAState = @CPAState,
		CPAZip = @CPAZip,
		CPACountry = @CPACountry,
		CPAAddress2 = @CPAAddress2
	WHERE APVMKeyIDFromAPVM = @Original_APVMKeyIDFromAPVM

vpspExit:
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCQualificationsFinancialUpdate] TO [VCSPortal]
GO
