SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspAPCMAcctUpdate]
/***************************************************
* CREATED BY    : MV 04/09/08
* MODIFIED BY:	EN 
*				KK 07/25/12 - D-05528 Re-vamped the logic to update to or from null values (CM Co and CM Acct) 
*									  for all transactions, Check/EFT and Credit Service
* Usage:
*   Called from APCompany Parameters when user changes the subledger CM Company or Account
*	or the Credit Service CM Account. 
*	Using the old and new subledger CM Company/Account and the old and new Credit Service
*	CM Company/Account, it updates all open Check and EFT transactions in APTH that have the old 
*	subledger CM Company/Account and updates all open Credit Service transactions in APTH
*	that have the previous Credit Service CM Company/Account.
*
* Input:
*	@APCo			Ap Company         
*   @oldCMCo		previous subledger CM Company
*	@newCMCo		new subledger CM Company
*	@oldCMAcct		previous subledger CM Account
*	@newCMAcct		new subledger CM Account
*	@oldCSCMCo		previous Credit Service CM Company
*	@newCSCMCo		new Credit Service CM Company
*	@oldCSCMAcct	previous Credit Service CM Account
*	@newCSCMAcct	new Credit Service CM Account    
* Output:
*   @msg			includes a statement of all successes and failures to update        
*
* Returns:
*	0               only 0 will be returned ... @msg includes a report of success and failure
*************************************************/
(@APCo bCompany, 
 @oldCMCo bCompany, 
 @newCMCo bCompany, 
 @oldCMAcct bCMAcct, 
 @newCMAcct bCMAcct,
 @oldCSCMCo bCompany, 
 @newCSCMCo bCompany, 
 @oldCSCMAcct bCMAcct, 
 @newCSCMAcct bCMAcct,
 @msg varchar(200) OUTPUT)
 
AS
SET NOCOUNT ON
   
DECLARE @return_value int, 
		@valproc varchar(60),
		@valmsg varchar(200),
		@savecount int,
		@totalupdated int
		
SELECT @msg = '', @totalupdated = 0

--validate newCMCo
SELECT @valproc = ValProc 
FROM dbo.vDDFI 
WHERE	Form = 'APCompany' AND
		ViewName = 'APCO' AND
		ColumnName = 'CMCo' 

EXEC	@return_value = @valproc
		@cmco = @newCMCo,
		@msg = @valmsg OUTPUT

IF @return_value <> 0 
BEGIN
	--CM Company validation failed - generate non success message
	SELECT @msg = 'Not a valid CM Company - could not update transactions'
END		

ELSE
BEGIN
	--Set the ACCOUNT values that came in as 0 (flagged as NULL) back to NULL
	IF @oldCMAcct   = 0 SELECT @oldCMAcct   = NULL
	IF @newCMAcct   = 0 SELECT @newCMAcct   = NULL
	IF @oldCSCMAcct = 0 SELECT @oldCSCMAcct = NULL
	IF @newCSCMAcct = 0 SELECT @newCSCMAcct = NULL
	--Set the COMPANY values for Credit Service transactions follow the same behavior as CMCo from AP Co Subledgers
	--since the user has no control over the CS CM Co
	SELECT @oldCSCMCo = @oldCMCo 
	SELECT @newCSCMCo = @newCMCo

	--Reset our flag for transaction updates
	SELECT @return_value = 0
	
	--if subledger CMCo and/or CMAcct changed, update Check and EFT open transactions
	IF @oldCMCo <> @newCMCo OR ISNULL(@oldCMAcct,0) <> ISNULL(@newCMAcct,0)
	BEGIN
		IF @newCMAcct IS NOT NULL
		BEGIN
			--validate subledger CM Account
			SELECT @valproc = ValProc 
			FROM dbo.vDDFI 
			WHERE	Form = 'APCompany' AND
					ViewName = 'APCO' AND
					ColumnName = 'CMAcct' 
					
			EXEC	@return_value = @valproc
					@cmco = @newCMCo,
					@cmacct = @newCMAcct,
					@msg = @valmsg OUTPUT

			IF @return_value <> 0 
			BEGIN
				--subledger CM Account validation failed - generate non success message
				SELECT @msg = 'Subledger CM Account not on file - could not update Check and EFT open transactions'
			END
			ELSE IF @oldCMAcct IS NOT NULL
			BEGIN
				--subledger CM Account validation passed - update Check and EFT open transactions and generate success message
				UPDATE dbo.bAPTH
				SET CMCo = @newCMCo, 
					CMAcct = @newCMAcct
				WHERE	APCo = @APCo AND 
						CMCo = @oldCMCo AND 
						CMAcct = @oldCMAcct AND 
						PayMethod IN ('C','E') AND
						OpenYN = 'Y'
				SELECT @savecount = @@ROWCOUNT
			END
			ELSE --the old CM Acct was NULL
			BEGIN
				--subledger CM Account validation passed - update Check and EFT open transactions and generate success message
				UPDATE dbo.bAPTH
				SET CMCo = @newCMCo, 
					CMAcct = @newCMAcct
				WHERE	APCo = @APCo AND 
						CMCo = @oldCMCo AND 
						CMAcct IS NULL AND 
						PayMethod IN ('C','E') AND
						OpenYN = 'Y'
				SELECT @savecount = @@ROWCOUNT
			END	
		END
		ELSE --Else the new CM Account is NULL so we don't need to validate
		BEGIN
			--subledger CM Account validation passed - update Check and EFT open transactions and generate success message
			UPDATE dbo.bAPTH
			SET CMCo = @newCMCo, 
				CMAcct = @newCMAcct
			WHERE	APCo = @APCo AND 
					CMCo = @oldCMCo AND 
					CMAcct = @oldCMAcct AND 
					PayMethod IN ('C','E') AND
					OpenYN = 'Y'
			SELECT @savecount = @@ROWCOUNT
		END						
		IF @savecount = 0 
		BEGIN
			SELECT @msg = 'Check and EFT open transaction update attempt failed'
		END	
		ELSE
		BEGIN
			SELECT @totalupdated = @savecount
		END
	END

	SELECT @return_value = 0 --Reset our flag again for Credit Service transaction updates
	--if subledger CMCo and/or CS CMAcct changed, update Credit Service open transactions
	IF ISNULL(@oldCSCMCo,0) <> ISNULL(@newCSCMCo,0) OR ISNULL(@oldCSCMAcct,0) <> ISNULL(@newCSCMAcct,0)
	BEGIN
		IF @newCSCMAcct IS NOT NULL
		BEGIN
			--validate Credit Service CM Account
			SELECT @valproc = ValProc 
			FROM dbo.vDDFI 
			WHERE	Form = 'APCompany' AND
					ViewName = 'APCO' AND
					ColumnName = 'CSCMAcct' 

			EXEC	@return_value = @valproc
					@CMCo = @newCSCMCo,
					@CSCMAcct = @newCSCMAcct,
					@msg = @valmsg OUTPUT
					
			IF @return_value <> 0 
			BEGIN
				--Credit Service CM Account validation failed - generate non success message
				IF LEN(@msg) <> 0 SELECT @msg = @msg + CHAR(13) + CHAR(10)
				SELECT @msg = @msg + 'Credit Service CM Account not on file - could not update Credit Service open transactions'
			END
			ELSE IF @oldCSCMAcct IS NOT NULL
			BEGIN
				--Credit Service CM Account validation passed - update Credit Service open transactions and generate success message
				UPDATE dbo.bAPTH
				SET CMCo = @newCSCMCo, 
					CMAcct = @newCSCMAcct
				WHERE	APCo = @APCo AND 
						CMCo = @oldCSCMCo AND 
						CMAcct = @oldCSCMAcct AND 
						PayMethod = 'S' AND
						OpenYN = 'Y'
				SELECT @savecount = @@ROWCOUNT
			END	
			ELSE --the old CS CM Acct was NULL
			BEGIN
				--Credit Service CM Account validation passed but the old value was NULL- update Credit Service open transactions and generate success message
				UPDATE dbo.bAPTH
				SET CMCo = @newCSCMCo, 
					CMAcct = @newCSCMAcct
				WHERE	APCo = @APCo AND 
						CMCo = @oldCSCMCo AND 
						CMAcct IS NULL AND 
						PayMethod = 'S' AND
						OpenYN = 'Y'
				SELECT @savecount = @@ROWCOUNT
			END
		END
		ELSE --Else the new CS CM Account is NULL so we don't need to validate
		BEGIN
			--Credit Service CM Account validation passed - update Credit Service open transactions and generate success message
			UPDATE dbo.bAPTH
			SET CMCo = @newCSCMCo, 
				CMAcct = @newCSCMAcct
			WHERE	APCo = @APCo AND 
					CMCo = @oldCSCMCo AND 
					CMAcct = @oldCSCMAcct AND 
					PayMethod = 'S' AND
					OpenYN = 'Y'
			SELECT @savecount = @@ROWCOUNT
		END	
		IF @savecount = 0 
		BEGIN
			IF LEN(@msg) <> 0 SELECT @msg = @msg + CHAR(13) + CHAR(10)
			SELECT @msg = @msg + 'Credit Service open transaction update attempt failed'
		END	
		ELSE
		BEGIN
			SELECT @totalupdated = @totalupdated + @savecount
		END
	END
END

--generate success message if any updates occurred
IF @totalupdated <> 0
BEGIN
	IF LEN(@msg) <> 0 SELECT @msg = @msg + CHAR(13) + CHAR(10)
	SELECT @msg = @msg + 'Updated ' + CONVERT(varchar, @totalupdated) + ' open transactions'
END
ELSE
BEGIN
	IF LEN(@msg) <> 0 SELECT @msg = @msg + CHAR(13) + CHAR(10)
	SELECT @msg = @msg + 'Found no open transactions to update'
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspAPCMAcctUpdate] TO [public]
GO
