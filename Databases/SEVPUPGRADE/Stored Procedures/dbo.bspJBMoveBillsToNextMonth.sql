SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[bspJBMoveBillsToNextMonth]
/********************************************************
* CREATED BY: 	CHS	11/29/2011	- TK-10764
* MODIFIED BY:	MV	12/20/2011 - TK-10764 - isnull wrap newbillnumbers
*				MV	12/21/2011 - TK-10764 - validate for open month when moving backwards
*				MV	12/22/2011 - TK-10764 - exclude interfaced bills from select of bills to move	
*				CHS	02/24/2012 - TK-12946 - moving 'ud' fields too
*
* USAGE:
*	Called by front end code to move JB billing records from one month to the month following
*	so the month can be closed.
* 
* INPUT PARAMETERS:
*	@JBCo
*	@BillMonth
*	@BillNumber
*
* OUTPUT PARAMETERS:
*
*	@msg		error message IF failure
*
* RETURN VALUE:
* 	0 	    success
*	1 		failure
**********************************************************/
(@JBCo bCompany, @BillMonth bMonth, @BillNumber int, @MoveDirection char(1), @msg varchar(255) = null output)

	AS
	SET NOCOUNT ON

	DECLARE @rcode int, @NextMonth bMonth, @Contract bContract, @CustGroup bGroup, @Customer bCustomer, @AuditBills bYN,
			@NewBillNumber int, @StartNewBill int, @PreviousMonth bMonth, @StartPreviousBill int
			
	DECLARE @ColumnList VARCHAR(MAX), @udCommandString VARCHAR(MAX), @TableName varchar(60), @UpdateList VARCHAR(MAX)		

	SELECT @rcode = 0
	
	-- validate input parameters JB Company
	IF @JBCo is null
		BEGIN
  		SELECT @msg = 'Missing JB Company', @rcode = 1
  		RETURN @rcode
  		END

	-- validate input parameters Bill Month  		
	IF @BillMonth is null
		BEGIN
  		SELECT @msg = 'Missing Bill Month', @rcode = 1
  		RETURN @rcode
  		END  	

	-- validate input parameters Bill Number 		
	IF @BillNumber is null
		BEGIN
  		SELECT @msg = 'Missing Bill Number', @rcode = 1
  		RETURN @rcode
  		END  
  		
	-- validate input parameters Bill Number 		
	IF @MoveDirection is null
		BEGIN
  		SELECT @msg = 'Missing Move Direction Flag', @rcode = 1
  		RETURN @rcode
  		END  
  		
	-- validate input parameters Bill Number 		
	IF @MoveDirection NOT IN ('F','B')
		BEGIN
  		SELECT @msg = 'Invalid move direction specified. You must select either "F" or "B" for move direction', @rcode = 1
  		RETURN @rcode
  		END    		
  		  		
	-- get the next bill month that we want to move these bills into.
	SELECT @NextMonth = DATEADD(month, 1, @BillMonth)	 
	
	-- get the previous bill month that we want to move these bills into.
	SELECT @PreviousMonth = DATEADD(month, -1, @BillMonth)	   	

	-- get the next bill number that we want to move these bills into.	
	SELECT @StartNewBill = ISNULL(MAX(BillNumber) + 1,1)
			FROM bJBIN
			WHERE JBCo = @JBCo
				AND BillMonth = @NextMonth 		
				
	-- get the next bill number that we want to move these bills into.	
	SELECT @StartPreviousBill = ISNULL(MAX(BillNumber) + 1,1)
			FROM bJBIN
			WHERE JBCo = @JBCo
				AND BillMonth = @PreviousMonth 					
	
	-- get the Contract, Customer Group, and Customer from JBIN
	SELECT TOP 1 @Contract = Contract, @CustGroup = CustGroup, @Customer = Customer
	FROM bJBIN
	WHERE JBCo = @JBCo
		AND @BillMonth = BillMonth
		AND @BillNumber = BillNumber

	-- exit when no contract is found		
	IF @@rowcount < 1
		BEGIN
 		SELECT @msg = 'Error - the Contract and Customer combination was not found', @rcode = 1
 		RETURN @rcode
 		END		
 		
	-- move billing records to the following month
	IF @MoveDirection = 'F'
		BEGIN 	

			BEGIN TRY
				BEGIN TRANSACTION

				-- Start #MyFutureJBIN cursor
				-- declare cursor flags
				DECLARE @cursorBillMonth SMALLDATETIME, @cursorBillNumber INT, @openJBINToMove TINYINT
				
				-- declare cursor
				DECLARE vcMyJBINToMove CURSOR FOR
				SELECT BillMonth, BillNumber
				FROM bJBIN
				WHERE JBCo = @JBCo
					AND Contract = @Contract 
					AND CustGroup = @CustGroup 
					AND Customer = @Customer
					AND InvStatus = 'A'
					AND ((BillMonth = @NextMonth AND BillNumber < @StartNewBill) OR (BillMonth = @BillMonth AND BillNumber >= @BillNumber))	
				ORDER BY BillMonth, BillNumber
				
				-- open cursor
				OPEN vcMyJBINToMove
				SELECT @openJBINToMove = 1
			  	
				-- loop through cursor of all #MyFutureJBIN records
				next_JBINToMove:
					FETCH NEXT FROM vcMyJBINToMove INTO @cursorBillMonth, @cursorBillNumber
					IF @@FETCH_STATUS = -1 GOTO end_JBINToMove
					if @@FETCH_STATUS <> 0 GOTO next_JBINToMove  
					
						

					-- get bill number of new bJBIN record to insert
					SELECT @NewBillNumber = ISNULL(MAX(BillNumber) + 1, 1)
					FROM bJBIN
					WHERE JBCo = @JBCo
						AND BillMonth = @NextMonth
				  		
					-- insert new (moved) record in bJBIN
					INSERT INTO bJBIN (	JBCo, BillMonth, BillNumber, Invoice, Contract, CustGroup, Customer, InvStatus, 
												Application, ProcessGroup, RestrictBillGroupYN, BillGroup, RecType, DueDate, 
												InvDate, PayTerms, DiscDate, FromDate, ToDate, BillAddress, BillAddress2, BillCity, 
												BillState, BillZip, ARTrans, InvTotal, InvRetg, RetgRel, InvDisc, TaxBasis, 
												InvTax, InvDue, ARRelRetgTran, ARRelRetgCrTran, ARGLCo, JCGLCo, CurrContract, WC, 			
												Installed, Purchased, SM, SMRetg, WCRetg, ChgOrderAmt, AutoInitYN, InUseBatchId, 
												InUseMth, Notes, BillOnCompleteYN, BillType, Template, CustomerReference, 
												CustomerJob, ACOThruDate, Purge, AuditYN, OverrideGLRevAcctYN, OverrideGLRevAcct, 
												UniqueAttchID, RevRelRetgYN, InvDescription, TMUpdateAddonYN, BillCountry, 
												RetgTax, RetgTaxRel, CertifiedDate, AmtClaimed, ClaimDate, Certified, 
												CreatedBy, CreatedDate, InitOption, 									
												PrevAmt, PrevRetg, PrevRRel, PrevTax, PrevDue, 		
												PrevWC, PrevSM, PrevSMRetg, PrevWCRetg,	
												PrevChgOrderAdds, PrevChgOrderDeds, 
												PrevRetgTax, PrevRetgTaxRel
												)					


					SELECT 	JBCo, @NextMonth, 
							@NewBillNumber, Invoice, Contract, CustGroup, Customer, InvStatus, 
							Application, ProcessGroup, RestrictBillGroupYN, BillGroup, RecType, DueDate, 
							InvDate, PayTerms, DiscDate, FromDate, ToDate, BillAddress, BillAddress2, BillCity, 
							BillState, BillZip, ARTrans, InvTotal, InvRetg, RetgRel, InvDisc, TaxBasis, 
							InvTax, InvDue, ARRelRetgTran, ARRelRetgCrTran, ARGLCo, JCGLCo, CurrContract, WC, 			
							Installed, Purchased, SM, SMRetg, WCRetg, ChgOrderAmt, AutoInitYN, InUseBatchId, 
							InUseMth, Notes, BillOnCompleteYN, BillType, Template, CustomerReference, 
							CustomerJob, ACOThruDate, 
							/*Purge*/ 'Y', /*AuditYN*/ 'Y', 
							OverrideGLRevAcctYN, OverrideGLRevAcct, 
							UniqueAttchID, RevRelRetgYN, InvDescription, TMUpdateAddonYN, BillCountry, 
							RetgTax, RetgTaxRel, CertifiedDate, AmtClaimed, ClaimDate, Certified, 
							CreatedBy, CreatedDate, InitOption, 
							PrevAmt, PrevRetg, PrevRRel, PrevTax, PrevDue, 	
							PrevWC, PrevSM, PrevSMRetg, PrevWCRetg, 	
							PrevChgOrderAdds, PrevChgOrderDeds, 
							PrevRetgTax, PrevRetgTaxRel
							
					FROM bJBIN
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber


							
					-- CHS	02/24/2012 - TK-12946	
					-- look for "ud" fields in bJBIN and copy any that are found
					SELECT @ColumnList = '', @udCommandString = '', @UpdateList = '', @TableName = 'JBIN'
					-- we need to look at the sys.columns in sys.tables for any column names that start with 'ud'
					-- and build a list of those columns
					SELECT @ColumnList = @ColumnList + c.[name] + ',' ,
					@UpdateList = @UpdateList + c.[name] + '=s.' + c.[name] + ','					
					FROM sys.columns AS c 
						  JOIN sys.views AS t ON t.object_id = c.object_id
					WHERE t.name = @TableName and c.name LIKE 'ud%'


					-- skip the ud fields if none exist
					IF LEN(@ColumnList)> 0
						BEGIN
						-- remove last comma
						SET @ColumnList = LEFT(@ColumnList,LEN(@ColumnList)-1)
						SET @UpdateList = LEFT(@UpdateList,LEN(@UpdateList)-1)
						-- build dynamic SQL code string to move the data from old UD field to the new ones.
						SELECT @udCommandString = 'UPDATE dbo.' + @TableName
													+ ' SET ' + @UpdateList
													+ ' FROM (SELECT ' + @ColumnList + ' FROM dbo.' + @TableName 
													+ ' WHERE JBCo = ' + cast(@JBCo as varchar(10))
													+ ' AND BillMonth = ''' + convert(varchar(20), @cursorBillMonth, 126) + ''''
													+ ' AND BillNumber = ' + cast(@cursorBillNumber as varchar(10)) + ') s '
													+ ' WHERE JBCo = ' + cast(@JBCo as varchar(10))
													+ ' AND BillMonth = ''' + convert(varchar(20), @NextMonth, 126) + ''''
													+ ' AND BillNumber = ' + cast(@NewBillNumber as varchar(10))
												
						EXECUTE(@udCommandString)
													
						END



			  			

					-- insert new (moved) record in bJBIT
					INSERT INTO bJBIT ( JBCo, BillMonth, BillNumber, Item, Description, UnitsBilled, AmtBilled, 
											RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, AmountDue, ARLine, 
											ARRelRetgLine, ARRelRetgCrLine, TaxGroup, TaxCode, CurrContract, 
											ContractUnits, WC, WCUnits, Installed, Purchased, SM, SMRetg, WCRetg, 
											BillGroup, Notes, Contract, Purge, AuditYN, WCRetPct, ChangedYN, 
											UniqueAttchID, RetgTax, RetgTaxRel, ReasonCode, AmtClaimed, 
											UnitsClaimed,									
											PrevUnits, PrevAmt, PrevRetg, 
											PrevRetgReleased, PrevTax, PrevDue, 	
											PrevWC, PrevWCUnits, PrevSM,  															
											PrevSMRetg, PrevWCRetg, PrevRetgTax, 
											PrevRetgTaxRel
	  										)
	  				SELECT
						JBCo, @NextMonth, 
						@NewBillNumber, Item, Description, UnitsBilled, AmtBilled, 
						RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, AmountDue, ARLine, 
						ARRelRetgLine, ARRelRetgCrLine, TaxGroup, TaxCode, CurrContract, 
						ContractUnits, WC, WCUnits, Installed, Purchased, SM, SMRetg, WCRetg, 
						BillGroup, Notes, Contract, 
						/*Purge*/ 'Y', /*AuditYN*/ 'Y', 
						WCRetPct, ChangedYN, 
						UniqueAttchID, RetgTax, RetgTaxRel, ReasonCode, AmtClaimed, 
						UnitsClaimed,									
						PrevUnits, PrevAmt, PrevRetg, 
						PrevRetgReleased, PrevTax, PrevDue, 	
						PrevWC, PrevWCUnits, PrevSM,  															
						PrevSMRetg, PrevWCRetg, PrevRetgTax, 
						PrevRetgTaxRel
	  				FROM bJBIT
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber		
					ORDER BY Item	
							

					-- CHS	02/24/2012 - TK-12946	
					-- look for "ud" fields in bJBIN and copy any that are found
					SELECT @ColumnList = '', @udCommandString = '', @UpdateList = '', @TableName = 'JBIT'
					-- we need to look at the sys.columns in sys.tables for any column names that start with 'ud'
					-- and build a list of those columns
					SELECT @ColumnList = @ColumnList + c.[name] + ',' ,
					@UpdateList = @UpdateList + c.[name] + '=s.' + c.[name] + ','					
					FROM sys.columns AS c 
						  JOIN sys.views AS t ON t.object_id = c.object_id
					WHERE t.name = @TableName and c.name LIKE 'ud%'


					-- skip the ud fields if none exist
					IF LEN(@ColumnList)> 0
						BEGIN
						-- remove last comma
						SET @ColumnList = LEFT(@ColumnList,LEN(@ColumnList)-1)
						SET @UpdateList = LEFT(@UpdateList,LEN(@UpdateList)-1)
						-- build dynamic SQL code string to move the data from old UD field to the new ones.						
						SELECT @udCommandString = 'UPDATE dbo.' + @TableName + ' '
													+ 'SET ' + @UpdateList
													+ ' FROM (SELECT Item, ' + @ColumnList + ' FROM dbo.' + @TableName 
													+ ' WHERE JBCo = ' + cast(@JBCo as varchar(10))
													+ ' AND BillMonth = ''' + convert(varchar(20), @cursorBillMonth, 126) + ''''
													+ ' AND BillNumber = ' + cast(@cursorBillNumber as varchar(10)) + ') s '
													+ ' WHERE JBCo = ' + cast(@JBCo as varchar(10))
													+ ' AND BillMonth = ''' + convert(varchar(20), @NextMonth, 126) + ''''
													+ ' AND BillNumber = ' + cast(@NewBillNumber as varchar(10))
													+ ' AND ' + @TableName + '.Item = s.Item  '
												
						EXECUTE(@udCommandString)
													
						END
							
							
					-- insert new (moved) record in bJBCC
					INSERT INTO bJBCC ( JBCo, BillMonth, BillNumber, Job, ACO, ChgOrderTot, AuditYN, Purge, UniqueAttchID)
	  				SELECT JBCo, @NextMonth, 
						@NewBillNumber, Job, ACO, ChgOrderTot, /*AuditYN*/ 'Y', /*Purge*/ 'Y', UniqueAttchID
	  				FROM bJBCC
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber							
					ORDER BY Job, ACO


					-- insert new (moved) record in bJBCX
					INSERT INTO bJBCX ( JBCo, BillMonth, BillNumber, Job, ACO, ACOItem, ChgOrderUnits, 
										ChgOrderAmt, AuditYN, Purge, UniqueAttchID)
	  				SELECT JBCo, @NextMonth, 
						@NewBillNumber, Job, ACO, ACOItem, ChgOrderUnits, 
	  									ChgOrderAmt, /*AuditYN*/ 'Y', /*Purge*/ 'Y', UniqueAttchID
	  				FROM bJBCX
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber	
					ORDER BY Job, ACO, ACOItem					
							
							
				
					-- insert new (moved) record in bJBIS
					INSERT INTO bJBIS ( JBCo, BillMonth, BillNumber, Job, Item, ACO, ACOItem, Description, 
										UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, 
										TaxAmount, AmountDue, PrevUnits, PrevAmt, PrevRetg, PrevRetgReleased, 
										PrevTax, PrevDue, ARLine, ARRelRetgLine, ARRelRetgCrLine, TaxGroup, 
										TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, 
										WCUnits, PrevSM, Installed, Purchased, SM, SMRetg, PrevSMRetg, 
										PrevWCRetg, WCRetg, BillGroup, Contract, ChgOrderUnits, ChgOrderAmt, Notes, WCRetPct, 
										Purge, AuditYN, 
										RetgTax, PrevRetgTax, RetgTaxRel, PrevRetgTaxRel )
	  				SELECT
	  						JBCo, @NextMonth, 
							@NewBillNumber, Job, Item, ACO, ACOItem, Description, 
							UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, 
							TaxAmount, AmountDue, PrevUnits, PrevAmt, PrevRetg, PrevRetgReleased, 
							PrevTax, PrevDue, ARLine, ARRelRetgLine, ARRelRetgCrLine, TaxGroup, 
							TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, 
							WCUnits, PrevSM, Installed, Purchased, SM, SMRetg, PrevSMRetg, 
							PrevWCRetg, WCRetg, BillGroup, Contract, ChgOrderUnits, ChgOrderAmt, Notes, WCRetPct, 
							/*Purge*/ 'Y', /*AuditYN*/ 'Y', 
							RetgTax, PrevRetgTax, RetgTaxRel, PrevRetgTaxRel		
	  				FROM bJBIS
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber
					ORDER BY Job, Item, ACO, ACOItem							
				


							
					-- set bJBIN flags on the moved records to their normal postions N & Y
					UPDATE bJBIN
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBIN
					WHERE JBCo = @JBCo
							AND BillMonth = @NextMonth
							AND BillNumber >= @StartNewBill

					-- set bJBIT flags on the moved records to their normal postions N & Y
					UPDATE bJBIT
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBIT
					WHERE JBCo = @JBCo
							AND BillMonth = @NextMonth
							AND BillNumber >= @StartNewBill
					
					-- set bJBCC flags on the moved records to their normal postions N & Y
					UPDATE bJBCC
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBCC
					WHERE JBCo = @JBCo
							AND BillMonth = @NextMonth
							AND BillNumber >= @StartNewBill
						
					-- set bJBCX flags on the moved records to their normal postions N & Y	
					UPDATE bJBCX
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBCX
					WHERE JBCo = @JBCo
							AND BillMonth = @NextMonth
							AND BillNumber >= @StartNewBill
																
					-- set bJBIS flags on the moved records to their normal postions N & Y				
					UPDATE bJBIS
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBIS
					WHERE JBCo = @JBCo
							AND BillMonth = @NextMonth
							AND BillNumber >= @StartNewBill

							
										
					-- deleting	section -------------------------------------------------------------------------				
					-- set bJBIN flags on the old records	
					UPDATE bJBIN
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBIN
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber
											
					-- delete old records from bJBIN	
					DELETE
					FROM bJBIN
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber
							
					-- create auditing entry in bHQMA					
					SELECT @AuditBills = AuditBills FROM bJBCO WHERE JBCo = @JBCo
					IF @AuditBills = 'Y'
						BEGIN
						Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,
							[DateTime], UserName)
						VALUES('bJBIN',
							'JBCo: ' + convert(varchar(3),@JBCo) + 'BillMonth: ' + convert(varchar(8), @cursorBillMonth,1)
							+ 'BillNumber: ' + convert(varchar(10),@cursorBillNumber),
							@JBCo, 'D', null, null, null, getdate(), SUSER_SNAME())	
						END

												
							
					-- set bJBIT flags on the old records				
					UPDATE bJBIT
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBIT
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber
											
					-- delete old records from bJBIT	
					DELETE
					FROM bJBIT
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber

					
					
					-- set bJBCC flags on the old records			
					UPDATE bJBCC
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBCC
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber
											
					-- delete old records from bJBCC	
					DELETE
					FROM bJBCC
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber

							
					
					-- set bJBCX flags on the old records			
					UPDATE bJBCX
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBCX
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber
											
					-- delete old records from bJBCX	
					DELETE
					FROM bJBCX
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber

			
																	
								
					-- set bJBIS flags on the old records			
					UPDATE bJBIS
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBIS
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber
											
					-- delete old records from bJBIS
					DELETE
					FROM bJBIS
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBillMonth
							AND BillNumber = @cursorBillNumber


							  		
					GOTO next_JBINToMove
					
			  
			end_JBINToMove:    	
				CLOSE vcMyJBINToMove
				DEALLOCATE vcMyJBINToMove
				SELECT @openJBINToMove = 0				
					
					

				COMMIT TRANSACTION  	

			END TRY


			BEGIN CATCH
				IF @@error <> 0 ROLLBACK TRANSACTION
				
				SELECT @msg = ERROR_MESSAGE() + CHAR(13) + CHAR(10) 
					+ 'Error moving JB records to next month.' + CHAR(13) + CHAR(10) 
					+ 'Rolling back transaction!', @rcode = 1

			END CATCH;
		
		END
		
		
	-- billing records to previous month	
	ELSE IF @MoveDirection = 'B'
		BEGIN 		
		--validate that the previous month that we are moving bills back to is open
		EXEC @rcode = bspJBClosedMthChk @JBCo, @PreviousMonth, @msg output
		IF @rcode = 1
		BEGIN
			RETURN @rcode		
		END
			BEGIN TRY
				BEGIN TRANSACTION

				-- Start #MyFutureJBIN cursor
				-- declare cursor flags
				DECLARE @cursorBackBillMonth SMALLDATETIME, @cursorBackBillNumber INT, @openBackJBINToMove TINYINT
				
				-- declare cursor
				DECLARE vcMyBackJBINToMove CURSOR FOR
				SELECT BillMonth, BillNumber
				FROM bJBIN
				WHERE JBCo = @JBCo
					AND Contract = @Contract 
					AND CustGroup = @CustGroup 
					AND Customer = @Customer
					AND InvStatus = 'A'
					AND (BillMonth = @BillMonth AND BillNumber <= @BillNumber)
				ORDER BY BillMonth, BillNumber
				
				-- open cursor
				OPEN vcMyBackJBINToMove
				SELECT @openBackJBINToMove = 1
			  	
				-- loop through cursor of all #MyFutureJBIN records
				next_BackJBINToMove:
					FETCH NEXT FROM vcMyBackJBINToMove INTO @cursorBackBillMonth, @cursorBackBillNumber
					IF @@FETCH_STATUS = -1 GOTO end_BackJBINToMove
					if @@FETCH_STATUS <> 0 GOTO next_BackJBINToMove  
				

					-- get bill number of new bJBIN record to insert
					SELECT @NewBillNumber = ISNULL(MAX(BillNumber) + 1,1)
					FROM bJBIN
					WHERE JBCo = @JBCo
						AND BillMonth = @PreviousMonth
				  		
					-- insert new (moved) record in bJBIN
					INSERT INTO bJBIN (	JBCo, BillMonth, BillNumber, Invoice, Contract, CustGroup, Customer, InvStatus, 
												Application, ProcessGroup, RestrictBillGroupYN, BillGroup, RecType, DueDate, 
												InvDate, PayTerms, DiscDate, FromDate, ToDate, BillAddress, BillAddress2, BillCity, 
												BillState, BillZip, ARTrans, InvTotal, InvRetg, RetgRel, InvDisc, TaxBasis, 
												InvTax, InvDue, ARRelRetgTran, ARRelRetgCrTran, ARGLCo, JCGLCo, CurrContract, WC, 			
												Installed, Purchased, SM, SMRetg, WCRetg, ChgOrderAmt, AutoInitYN, InUseBatchId, 
												InUseMth, Notes, BillOnCompleteYN, BillType, Template, CustomerReference, 
												CustomerJob, ACOThruDate, Purge, AuditYN, OverrideGLRevAcctYN, OverrideGLRevAcct, 
												UniqueAttchID, RevRelRetgYN, InvDescription, TMUpdateAddonYN, BillCountry, 
												RetgTax, RetgTaxRel, CertifiedDate, AmtClaimed, ClaimDate, Certified, 
												CreatedBy, CreatedDate, InitOption, 									
												PrevAmt, PrevRetg, PrevRRel, PrevTax, PrevDue, 		
												PrevWC, PrevSM, PrevSMRetg, PrevWCRetg,	
												PrevChgOrderAdds, PrevChgOrderDeds, 
												PrevRetgTax, PrevRetgTaxRel
												)					


					SELECT 	JBCo, @PreviousMonth, 
							@NewBillNumber, Invoice, Contract, CustGroup, Customer, InvStatus, 
							Application, ProcessGroup, RestrictBillGroupYN, BillGroup, RecType, DueDate, 
							InvDate, PayTerms, DiscDate, FromDate, ToDate, BillAddress, BillAddress2, BillCity, 
							BillState, BillZip, ARTrans, InvTotal, InvRetg, RetgRel, InvDisc, TaxBasis, 
							InvTax, InvDue, ARRelRetgTran, ARRelRetgCrTran, ARGLCo, JCGLCo, CurrContract, WC, 			
							Installed, Purchased, SM, SMRetg, WCRetg, ChgOrderAmt, AutoInitYN, InUseBatchId, 
							InUseMth, Notes, BillOnCompleteYN, BillType, Template, CustomerReference, 
							CustomerJob, ACOThruDate, 
							/*Purge*/ 'Y', /*AuditYN*/ 'Y', 
							OverrideGLRevAcctYN, OverrideGLRevAcct, 
							UniqueAttchID, RevRelRetgYN, InvDescription, TMUpdateAddonYN, BillCountry, 
							RetgTax, RetgTaxRel, CertifiedDate, AmtClaimed, ClaimDate, Certified, 
							CreatedBy, CreatedDate, InitOption, 
							PrevAmt, PrevRetg, PrevRRel, PrevTax, PrevDue, 	
							PrevWC, PrevSM, PrevSMRetg, PrevWCRetg, 	
							PrevChgOrderAdds, PrevChgOrderDeds, 
							PrevRetgTax, PrevRetgTaxRel
							
					FROM bJBIN
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber

					-- CHS	02/24/2012 - TK-12946	
					-- look for "ud" fields in bJBIN and copy any that are found
					SELECT @ColumnList = '', @udCommandString = '', @UpdateList = '', @TableName = 'JBIN'
					-- we need to look at the sys.columns in sys.tables for any column names that start with 'ud'
					-- and build a list of those columns
					SELECT @ColumnList = @ColumnList + c.[name] + ',' ,
					@UpdateList = @UpdateList + c.[name] + '=s.' + c.[name] + ','					
					FROM sys.columns AS c 
						  JOIN sys.views AS t ON t.object_id = c.object_id
					WHERE t.name = @TableName and c.name LIKE 'ud%'


					-- skip the ud fields if none exist
					IF LEN(@ColumnList)> 0
						BEGIN
						-- remove last comma
						SET @ColumnList = LEFT(@ColumnList,LEN(@ColumnList)-1)
						SET @UpdateList = LEFT(@UpdateList,LEN(@UpdateList)-1)
						-- build dynamic SQL code string to move the data from old UD field to the new ones.						
						SELECT @udCommandString = 'UPDATE dbo.' + @TableName
													+ ' SET ' + @UpdateList
													+ ' FROM (SELECT  ' + @ColumnList + ' FROM dbo.' + @TableName 
													+ ' WHERE JBCo = ' + cast(@JBCo as varchar(10))													
													+ ' AND BillMonth = ''' + convert(varchar(20), @cursorBackBillMonth, 126) + ''''
													+ ' AND BillNumber = ' + cast(@cursorBackBillNumber as varchar(10)) + ') s '													
													+ ' WHERE JBCo = ' + cast(@JBCo as varchar(10))
													+ ' AND BillMonth = ''' + convert(varchar(20), @PreviousMonth, 126) + ''''
													+ ' AND BillNumber = ' + cast(@NewBillNumber as varchar(10))
											
						EXECUTE(@udCommandString)
													
						END
								  			

					-- insert new (moved) record in bJBIT
					INSERT INTO bJBIT ( JBCo, BillMonth, BillNumber, Item, Description, UnitsBilled, AmtBilled, 
											RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, AmountDue, ARLine, 
											ARRelRetgLine, ARRelRetgCrLine, TaxGroup, TaxCode, CurrContract, 
											ContractUnits, WC, WCUnits, Installed, Purchased, SM, SMRetg, WCRetg, 
											BillGroup, Notes, Contract, Purge, AuditYN, WCRetPct, ChangedYN, 
											UniqueAttchID, RetgTax, RetgTaxRel, ReasonCode, AmtClaimed, 
											UnitsClaimed,									
											PrevUnits, PrevAmt, PrevRetg, 
											PrevRetgReleased, PrevTax, PrevDue, 	
											PrevWC, PrevWCUnits, PrevSM,  															
											PrevSMRetg, PrevWCRetg, PrevRetgTax, 
											PrevRetgTaxRel
	  										)
	  				SELECT
						JBCo, @PreviousMonth, 
						@NewBillNumber, Item, Description, UnitsBilled, AmtBilled, 
						RetgBilled, RetgRel, Discount, TaxBasis, TaxAmount, AmountDue, ARLine, 
						ARRelRetgLine, ARRelRetgCrLine, TaxGroup, TaxCode, CurrContract, 
						ContractUnits, WC, WCUnits, Installed, Purchased, SM, SMRetg, WCRetg, 
						BillGroup, Notes, Contract, 
						/*Purge*/ 'Y', /*AuditYN*/ 'Y', 
						WCRetPct, ChangedYN, 
						UniqueAttchID, RetgTax, RetgTaxRel, ReasonCode, AmtClaimed, 
						UnitsClaimed,									
						PrevUnits, PrevAmt, PrevRetg, 
						PrevRetgReleased, PrevTax, PrevDue, 	
						PrevWC, PrevWCUnits, PrevSM,  															
						PrevSMRetg, PrevWCRetg, PrevRetgTax, 
						PrevRetgTaxRel
	  				FROM bJBIT
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber		
					ORDER BY Item	
							
					-- CHS	02/24/2012 - TK-12946	
					-- look for "ud" fields in bJBIN and copy any that are found
					SELECT @ColumnList = '', @udCommandString = '', @UpdateList = '', @TableName = 'JBIT'
					-- we need to look at the sys.columns in sys.tables for any column names that start with 'ud'
					-- and build a list of those columns
					SELECT @ColumnList = @ColumnList + c.[name] + ',' ,
					@UpdateList = @UpdateList + c.[name] + '=s.' + c.[name] + ','					
					FROM sys.columns AS c 
						  JOIN sys.views AS t ON t.object_id = c.object_id
					WHERE t.name = @TableName and c.name LIKE 'ud%'


					-- skip the ud fields if none exist
					IF LEN(@ColumnList)> 0
						BEGIN
						-- remove last comma
						SET @ColumnList = LEFT(@ColumnList,LEN(@ColumnList)-1)
						SET @UpdateList = LEFT(@UpdateList,LEN(@UpdateList)-1)
						-- build dynamic SQL code string to move the data from old UD field to the new ones.						
						SELECT @udCommandString = 'UPDATE dbo.' + @TableName 
													+ ' SET ' + @UpdateList
													+ ' FROM (SELECT Item, ' + @ColumnList + ' FROM dbo.' + @TableName 
													+ ' WHERE JBCo = ' + cast(@JBCo as varchar(10))													
													+ ' AND BillMonth = ''' + convert(varchar(20), @cursorBackBillMonth, 126) + ''''
													+ ' AND BillNumber = ' + cast(@cursorBackBillNumber as varchar(10)) + ') s '													
													+ ' WHERE JBCo = ' + cast(@JBCo as varchar(10))
													+ ' AND BillMonth = ''' + convert(varchar(20), @PreviousMonth, 126) + ''''
													+ ' AND BillNumber = ' + cast(@NewBillNumber as varchar(10))
													+ ' AND ' + @TableName + '.Item = s.Item  '													
									
						EXECUTE(@udCommandString)
													
						END
													
							
					-- insert new (moved) record in bJBCC
					INSERT INTO bJBCC ( JBCo, BillMonth, BillNumber, Job, ACO, ChgOrderTot, AuditYN, Purge, UniqueAttchID)
	  				SELECT JBCo, @PreviousMonth, 
						@NewBillNumber, Job, ACO, ChgOrderTot, /*AuditYN*/ 'Y', /*Purge*/ 'Y', UniqueAttchID
	  				FROM bJBCC
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber							
					ORDER BY Job, ACO


					-- insert new (moved) record in bJBCX
					INSERT INTO bJBCX ( JBCo, BillMonth, BillNumber, Job, ACO, ACOItem, ChgOrderUnits, 
										ChgOrderAmt, AuditYN, Purge, UniqueAttchID)
	  				SELECT JBCo, @PreviousMonth, 
						@NewBillNumber, Job, ACO, ACOItem, ChgOrderUnits, 
	  									ChgOrderAmt, /*AuditYN*/ 'Y', /*Purge*/ 'Y', UniqueAttchID
	  				FROM bJBCX
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber	
					ORDER BY Job, ACO, ACOItem					
							
							
				
					-- insert new (moved) record in bJBIS
					INSERT INTO bJBIS ( JBCo, BillMonth, BillNumber, Job, Item, ACO, ACOItem, Description, 
										UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, 
										TaxAmount, AmountDue, PrevUnits, PrevAmt, PrevRetg, PrevRetgReleased, 
										PrevTax, PrevDue, ARLine, ARRelRetgLine, ARRelRetgCrLine, TaxGroup, 
										TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, 
										WCUnits, PrevSM, Installed, Purchased, SM, SMRetg, PrevSMRetg, 
										PrevWCRetg, WCRetg, BillGroup, Contract, ChgOrderUnits, ChgOrderAmt, Notes, WCRetPct, 
										Purge, AuditYN, 
										RetgTax, PrevRetgTax, RetgTaxRel, PrevRetgTaxRel )
	  				SELECT
	  						JBCo, @PreviousMonth, 
							@NewBillNumber, Job, Item, ACO, ACOItem, Description, 
							UnitsBilled, AmtBilled, RetgBilled, RetgRel, Discount, TaxBasis, 
							TaxAmount, AmountDue, PrevUnits, PrevAmt, PrevRetg, PrevRetgReleased, 
							PrevTax, PrevDue, ARLine, ARRelRetgLine, ARRelRetgCrLine, TaxGroup, 
							TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, 
							WCUnits, PrevSM, Installed, Purchased, SM, SMRetg, PrevSMRetg, 
							PrevWCRetg, WCRetg, BillGroup, Contract, ChgOrderUnits, ChgOrderAmt, Notes, WCRetPct, 
							/*Purge*/ 'Y', /*AuditYN*/ 'Y', 
							RetgTax, PrevRetgTax, RetgTaxRel, PrevRetgTaxRel		
	  				FROM bJBIS
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber
					ORDER BY Job, Item, ACO, ACOItem							
				


							
					-- set bJBIN flags on the moved records to their normal postions N & Y
					UPDATE bJBIN
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBIN
					WHERE JBCo = @JBCo
							AND BillMonth = @PreviousMonth
							AND BillNumber >= @StartPreviousBill

					-- set bJBIT flags on the moved records to their normal postions N & Y
					UPDATE bJBIT
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBIT
					WHERE JBCo = @JBCo
							AND BillMonth = @PreviousMonth
							AND BillNumber >= @StartPreviousBill
					
					-- set bJBCC flags on the moved records to their normal postions N & Y
					UPDATE bJBCC
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBCC
					WHERE JBCo = @JBCo
							AND BillMonth = @PreviousMonth
							AND BillNumber >= @StartPreviousBill
						
					-- set bJBCX flags on the moved records to their normal postions N & Y	
					UPDATE bJBCX
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBCX
					WHERE JBCo = @JBCo
							AND BillMonth = @PreviousMonth
							AND BillNumber >= @StartPreviousBill
																
					-- set bJBIS flags on the moved records to their normal postions N & Y				
					UPDATE bJBIS
					SET Purge = 'N', AuditYN = 'Y'
					FROM bJBIS
					WHERE JBCo = @JBCo
							AND BillMonth = @PreviousMonth
							AND BillNumber >= @StartPreviousBill

							
										
					-- deleting	section -------------------------------------------------------------------------				
					-- set bJBIN flags on the old records	
					UPDATE bJBIN
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBIN
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber
											
					-- delete old records from bJBIN	
					DELETE
					FROM bJBIN
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber
							
					-- create auditing entry in bHQMA					
					SELECT @AuditBills = AuditBills FROM bJBCO WHERE JBCo = @JBCo
					IF @AuditBills = 'Y'
						BEGIN
						Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,
							[DateTime], UserName)
						VALUES('bJBIN',
							'JBCo: ' + convert(varchar(3),@JBCo) + 'BillMonth: ' + convert(varchar(8), @cursorBackBillMonth,1)
							+ 'BillNumber: ' + convert(varchar(10),@cursorBackBillNumber),
							@JBCo, 'D', null, null, null, getdate(), SUSER_SNAME())	
						END

												
							
					-- set bJBIT flags on the old records				
					UPDATE bJBIT
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBIT
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber
											
					-- delete old records from bJBIT	
					DELETE
					FROM bJBIT
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber

					
					
					-- set bJBCC flags on the old records			
					UPDATE bJBCC
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBCC
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber
											
					-- delete old records from bJBCC	
					DELETE
					FROM bJBCC
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber

							
					
					-- set bJBCX flags on the old records			
					UPDATE bJBCX
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBCX
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber
											
					-- delete old records from bJBCX	
					DELETE
					FROM bJBCX
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber

			
																	
								
					-- set bJBIS flags on the old records			
					UPDATE bJBIS
					SET Purge = 'Y', AuditYN = 'N'
					FROM bJBIS
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber
											
					-- delete old records from bJBIS
					DELETE
					FROM bJBIS
					WHERE JBCo = @JBCo
							AND BillMonth = @cursorBackBillMonth
							AND BillNumber = @cursorBackBillNumber


							  		
					GOTO next_BackJBINToMove
					
			  
			end_BackJBINToMove:    	
				CLOSE vcMyBackJBINToMove
				DEALLOCATE vcMyBackJBINToMove
				SELECT @openBackJBINToMove = 0				
					
					

				COMMIT TRANSACTION  	

			END TRY


			BEGIN CATCH
				IF @@error <> 0 ROLLBACK TRANSACTION
				
				SELECT @msg = ERROR_MESSAGE() + CHAR(13) + CHAR(10) 
					+ 'Error moving JB records to next month.' + CHAR(13) + CHAR(10) 
					+ 'Rolling back transaction!', @rcode = 1

			END CATCH;
		
		END
		
		
	ELSE		
		BEGIN
  		SELECT @msg = 'Invalid move direction specified. You must select either "F" or "B" for move direction', @rcode = 1
  		RETURN @rcode
  		END  
  		
		
  bspexit:


						
	IF @openJBINToMove = 1
	BEGIN
	CLOSE vcMyJBINToMove
	DEALLOCATE vcMyJBINToMove	
	END	
  										
	IF @openBackJBINToMove = 1
	BEGIN
	CLOSE vcMyBackJBINToMove
	DEALLOCATE vcMyBackJBINToMove	
	END	
	
	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspJBMoveBillsToNextMonth] TO [public]
GO
