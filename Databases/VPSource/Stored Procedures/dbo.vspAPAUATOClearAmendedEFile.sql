SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[vspAPAUATOClearAmendedEFile]
/********************************************************/
-- CREATED BY:	GF 03/14/2013 AP ATO enhancement
-- MODIFIED BY:  
--
-- USAGE:
--	Set the Amended Date in APAUPayeeTaxPaymentATO to NULL
--	for all Creditor for the specified APCo/TaxYear.
--
-- INPUT PARAMETERS:
--	@APCo		AP Company
--	@TaxYear	Tax Year to affect in ATO Creditor taxable payments
--
--
-- OUTPUT PARAMETERS:
--	@Message	error message if failure, message specifying # of records cleared if success
--
-- RETURN VALUE:
-- 	0 	    success
--	1 		failure
--
/**********************************************************/
(
 @APCo bCompany, 
 @TaxYear char(4), 
 @Message VARCHAR(4000) = NULL OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON

	-- Check Parameters
	IF @APCo IS NULL
		BEGIN
		SET @Message = 'Missing AP Company!'
		RETURN 1
		END

	IF @TaxYear IS NULL
		BEGIN
		SET @Message = 'Missing Tax Year!'
		RETURN 1
		END


---- update Creditor table setting amended flag to 'N' and amended date to null
BEGIN TRY

	---- start a transaction, commit after fully processed
    BEGIN TRANSACTION;

	UPDATE dbo.APAUPayeeTaxPaymentATO
		SET AmendedDate = NULL
	WHERE APCo = @APCo AND TaxYear = @TaxYear AND AmendedDate IS NOT NULL

	SELECT @Message = 'Cleared ' + CONVERT(varchar,@@ROWCOUNT) + ' amended records.'

		---- insert for Creditor payments has completed. commit transaction
	COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    -- Test XACT_STATE:
        -- If 1, the transaction is committable.
        -- If -1, the transaction is uncommittable and should 
        --     be rolled back.
        -- XACT_STATE = 0 means that there is no transaction and
        --     a commit or rollback operation would generate an error.
	IF XACT_STATE() <> 0
		BEGIN
		ROLLBACK TRANSACTION
		SET @Message = CAST(ERROR_MESSAGE() AS VARCHAR(200))
		RAISERROR (@Message, 15, 1)
		RETURN 1
		END
END CATCH


RETURN 0


END
GO
GRANT EXECUTE ON  [dbo].[vspAPAUATOClearAmendedEFile] TO [public]
GO
