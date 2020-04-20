USE [MCK_INTEGRATION]
GO

/****** Object:  StoredProcedure [dbo].[spInsertInvoiceToARBatch]    Script Date: 12/16/2015 4:08:58 PM ******/
DROP PROCEDURE [dbo].[spInsertInvoiceToARBatch]
GO

/****** Object:  StoredProcedure [dbo].[spInsertInvoiceToARBatch]    Script Date: 12/16/2015 4:08:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Curt Salada
-- Create date: 7/11/2014
-- Description:	Transfer Invoices from Astea to VP (2nd hop)
-- --------------------------------------------------------
-- 2014-10-08  CS  populate udSMWorkOrderID
-- 2014-11-01  CS  validate tax code;
--                 handle TaxGroup in fail msg
-- 2014-11-20  CS  add JCCo to Item select
-- 2014-12-02  CS  add pPrevMonth param, enable back-dating batch;
--                 use DueDate for both TransactionDate and DueDate (NET_NOW)
-- 2015-01-28  CS  set LineType="C" for jobs
-- 2015-02-13  CS  set udWorkOrder and udSMCo on ARBL
-- 2015-02-24  CS  limit to invoices from current (or previous) month;
--                 use DateCreated instead of DueDate for Trans Date
--                 (DueDate is always the same as DateCreated for now, 
--                 but that may change someday)
-- 2015-03-12  CS  if invoice ID is supplied, ignore other params
-- 2015-06-05  CS  98620 release the batch when done;
--                 return batch info as output, including dollar sums
-- 2015-07-17  CS  98816 if BillToCust is invalid, fail
-- 2015-12-16  CS  99078 trim whitespace from the TaxCode column
-- =============================================

CREATE PROCEDURE [dbo].[spInsertInvoiceToARBatch] 
	--@pDocTypeId AS VARCHAR(30)
	@pAsteaInvoiceId AS VARCHAR(30)
	,@pContractSwitch AS CHAR(1)
	,@pServiceOrderSwitch AS CHAR(1)
	,@pJobSwitch AS CHAR(1)
	,@pNonJobSwitch AS CHAR(1)
	,@pCompany AS TINYINT
	--, @pLock AS VARCHAR(256)
	,@pPrevMonth AS CHAR(1)
	, @errmess AS VARCHAR(500) OUTPUT
	, @batchinfo AS VARCHAR(100) OUTPUT   -- 98620 return batch info to put in email 
 
AS
BEGIN
  
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;
		
		-- default value		
		SELECT @errmess = ''
		SELECT @batchinfo = ''	-- 98620 
		
		-- define date boundaries
		DECLARE @MonthsSince1900 AS INT

		SET @MonthsSince1900 =  DATEDIFF(MONTH, 0, GETDATE())

		DECLARE @FirstOfCurrentMonth AS DateTime
		DECLARE @FirstOfNextMonth AS DATETIME

		-- if posting to previous month, adjust the date boundaries back one month
		SET @pPrevMonth = ISNULL(@pPrevMonth, 'N')
		IF UPPER(@pPrevMonth) = 'Y' SET @MonthsSince1900 = @MonthsSince1900 - 1	-- 98620 add "UPPER()"

		SET @FirstOfCurrentMonth = DATEADD(MONTH, @MonthsSince1900, 0)
		SET @FirstOfNextMonth = DATEADD(MONTH, @MonthsSince1900 + 1, 0)

		DECLARE @LogUser VARCHAR(128), @LogMsg VARCHAR(MAX)

		-- begin 98620 accumulate sums
		DECLARE @SumInvoiceTotal NUMERIC(12,2), @SumTotalTax NUMERIC(12,2)
		SELECT @SumInvoiceTotal = 0, @SumTotalTax = 0
		-- end 98620

		BEGIN TRY
			
			SELECT @LogUser = SUSER_SNAME()        
			SELECT @LogMsg = 'Params InvoiceId: ' + ISNULL(@pAsteaInvoiceId, 'NULL') + ' | Contract: ' + ISNULL(@pContractSwitch, 'N') 
				+ ' | ServiceOrder: ' + ISNULL(@pServiceOrderSwitch, 'N') + ' | Job: ' + ISNULL(@pJobSwitch, 'N')
				+ ' | NonJob: ' + ISNULL(@pNonJobSwitch, 'N') + ' | Company: ' + ISNULL(CAST(@pCompany AS VARCHAR(10)), 'NULL')
				+ ' | PrevMonth: ' + ISNULL(@pPrevMonth, 'NULL')

			--IF @pDocTypeId NOT IN ('service_order', 'contract')
			--BEGIN
			--	SELECT @errmess = 'Invalid Doc Type ' + ISNULL(@pDocTypeId, 'NULL')
			--	GOTO spexit  
			--END  
		END TRY
		BEGIN CATCH
			SELECT @errmess = 'Failed to parse parameters: ' + ERROR_MESSAGE()
			GOTO spexit
		END CATCH      

		-- validate mandatory params

		BEGIN TRY
			IF NOT EXISTS (SELECT 1 FROM Viewpoint.dbo.HQCO WHERE HQCo = @pCompany)
			BEGIN
				SELECT @errmess = 'Invalid HQ Company ' + ISNULL(CAST(@pCompany AS VARCHAR(10)), 'NULL')
				GOTO spexit
			END  

			IF NOT EXISTS (SELECT 1 FROM Viewpoint.dbo.ARCO WHERE ARCo = @pCompany)
			BEGIN
				SELECT @errmess =  'Invalid AR Company ' + ISNULL(CAST(@pCompany AS VARCHAR(10)), 'NULL')  
				GOTO spexit
			END      
		END TRY
		BEGIN CATCH
			SELECT @errmess = 'Failed to validate company parameter: ' + ERROR_MESSAGE()
			GOTO spexit
		END CATCH      
      
		SET @pPrevMonth = ISNULL(@pPrevMonth, 'N')

		DECLARE @RowId INT
			,@CustGroup TINYINT
			,@AsteaCustomer VARCHAR(30)
			,@AsteaBillTo VARCHAR(30)
			,@AsteaInvoiceId VARCHAR(30)
			,@BatchId INTEGER
			,@UIMonth SMALLDATETIME
			,@Source VARCHAR(10)
			,@BatchSeq INTEGER
			,@CMCo TINYINT
			,@CMAcct SMALLINT
  			,@TransType char(1)
			,@ARTrans INT
			,@ARTransType char(1)
			,@RecType tinyint
			,@CustRef varchar(20)
			,@CustPO varchar(20)
			,@DueDate SMALLDATETIME
			,@DiscDate SMALLDATETIME
			,@AppliedMth SMALLDATETIME
			,@AppliedTrans INT
			,@PayTerms VARCHAR(10)
			,@MSCo TINYINT
			,@Job VARCHAR(10)      
			,@JCCo TINYINT 
			,@Contract VARCHAR(7)
			,@Customer INTEGER
			,@InvoiceNumber VARCHAR(10)
			,@CheckNumber VARCHAR(10)
			,@Description VARCHAR(30)
			,@CheckDate SMALLDATETIME
			,@DepositNumber VARCHAR(10)
			,@CheckAmount NUMERIC(12,2)
			,@ARLine INTEGER
			,@LineType CHAR(1)
			,@GLCo TINYINT
			,@TaxGroup TINYINT
			,@GLAcct VARCHAR(20)
			,@TransactionDate DATETIME
			,@InvoiceTotal NUMERIC(12,2)
			,@TotalTax NUMERIC(12,2)
			,@TaxCode VARCHAR(10)     
			,@TableName CHAR(20)
			,@Department VARCHAR(10)
			,@ServiceCenter VARCHAR(10)
			,@Progress VARCHAR(500)
			,@VPCustomer INTEGER
			,@JobCnt INTEGER  
			,@InvCount INTEGER 
			,@RowCount INTEGER
			,@Item VARCHAR(16)
			,@SMCo TINYINT
			,@WorkOrder INTEGER
			,@SMWorkOrderID INTEGER    
			,@DateCreated SMALLDATETIME  
			,@ProcessDesc VARCHAR(100)    -- 98620 stamped on each invoice and returned to caller

		-- lock records
		DECLARE @lock VARCHAR(256)
		SELECT @lock = USER_NAME() + '_' + CONVERT(VARCHAR(30), SYSUTCDATETIME())

		BEGIN TRY
			BEGIN TRANSACTION      	

			-- lock invoices that match the input params
			DECLARE @tSQL AS NVARCHAR(1000);

			-- build SQL statement and log it			
			SELECT @tSQL = ' UPDATE dbo.Invoice SET ProcessStatus = ''L'', ProcessDesc = ' + QUOTENAME(@lock, '''') + ' WHERE LOWER(SourceSystemId) = ''astea'' '

			-- invoice ID
			IF (@pAsteaInvoiceId IS NOT NULL AND @pAsteaInvoiceId <> '')
				SELECT @tSQL = @tSQL + ' AND AsteaInvoiceId = ' + QUOTENAME(@pAsteaInvoiceId, '''') + ' '
			ELSE
			BEGIN          
				-- invoice records that have not yet been processed
				SELECT @tSQL = @tSQL + ' AND LOWER(ProcessStatus) = ''n'' '

				-- company (SMCo or JCCo) must match pCompany param
				SELECT @tSQL = @tSQL + ' AND ( (DocTypeId = ''contract'' AND JCCo = ' + QUOTENAME(CAST(@pCompany AS VARCHAR(10)), '''') + ') OR
											  (DocTypeId = ''service_order'' AND Job IS NULL AND SMCo = ' + QUOTENAME(CAST(@pCompany AS VARCHAR(10)), '''') + ') OR 
											  (DocTypeId = ''service_order'' AND Job IS NOT NULL AND JCCo = ' + QUOTENAME(CAST(@pCompany AS VARCHAR(10)), '''') + ') ) '

				-- invoice must be created within posting month
				SELECT @tSQL = @tSQL + ' AND  ( DateCreated >= ''' + CONVERT(NVARCHAR(19), @FirstOfCurrentMonth, 120) + ''' AND DateCreated < ''' + CONVERT(NVARCHAR(19), @FirstOfNextMonth, 120) + ''' )'

			
				-- we know that one or both switches must be set to 'Y'
				IF (LOWER(@pContractSwitch) = 'y' AND LOWER(@pServiceOrderSwitch) <> 'y')
					SELECT @tSQL = @tSQL + ' AND (Lower(DocTypeId) = ''contract'') '

				IF (LOWER(@pContractSwitch) <> 'y' AND LOWER(@pServiceOrderSwitch) = 'y')
					SELECT @tSQL = @tSQL + ' AND (Lower(DocTypeId) = ''service_order'') '
				
				-- check for job-related or not-job-related invoices
				IF (LOWER(@pJobSwitch) = 'y')
					SELECT @tSQL = @tSQL + ' AND (Job IS NOT NULL AND Job <> '''') '

				IF (LOWER(@pNonJobSwitch) = 'y')
					SELECT @tSQL = @tSQL + ' AND (Job IS NULL OR Job = '''') '

			END
			-- execute the SQL to do the locking
			EXECUTE sp_executesql @tSQL
		
			COMMIT TRANSACTION   
			        
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
			SELECT @errmess = 'Failed to lock invoice records: ' + ERROR_MESSAGE() + ' | tSQL: ' + ISNULL(@tSQL, 'NULL')
			GOTO spexit
		END CATCH
  
		-- log invoice count
		SELECT @InvCount = COUNT(*) FROM dbo.Invoice WHERE ProcessStatus = 'L' AND ProcessDesc = @lock

		SELECT @LogMsg = @LogMsg + ' | Invoice Count: ' + ISNULL(CAST(@InvCount AS VARCHAR(20)), 'NULL') + ' | Lock: ' + ISNULL(@lock, 'NULL')
		BEGIN TRANSACTION
  			EXEC dbo.spInsertToTransactLog @Table = 'Invoice transfer', -- varchar(128)
			@KeyColumn = '', -- varchar(128)
			@KeyId = '', -- varchar(255)
			@User = @LogUser, -- varchar(128)
			@UpdateInsert = 'I', -- char(1)
			@msg = @LogMsg  -- varchar(max)      
		COMMIT TRANSACTION

		-- quit if no invoices to process
		IF ( @InvCount < 1)
		BEGIN
			SELECT @LogMsg = 'No invoices to process'
			GOTO spexit
		END

		BEGIN TRY
			-- prepare to generate a new batch number
			IF @pPrevMonth = 'Y'
			BEGIN
			    SELECT @TransactionDate = DATEADD(MONTH, -1, GETDATE())
			END
			ELSE
	        BEGIN
				SELECT @TransactionDate = GETDATE()	
			END 
			SELECT @UIMonth = Viewpoint.[dbo].[vfFirstDayOfMonth] (@TransactionDate)    
			     
			IF (@UIMonth IS NULL)
			BEGIN
				SELECT @errmess = 'Invalid First Day Of Month for transaction date ' + ISNULL(CAST(@TransactionDate AS VARCHAR(20)), 'NULL') 
				GOTO spexit
			END

			SELECT @LogMsg = 'Generate batch | UIMonth: ' + ISNULL(CAST(@UIMonth AS VARCHAR(20)), 'NULL') 

			-- get Next Trans# (as Batch Number) for This Table, Company, and Month
			SELECT @TableName = 'bHQBC'		--  BC = Batch Control
			SELECT @LogMsg = @LogMsg + ' | TableName: ' + ISNULL(@TableName, 'NULL')
 
		END TRY
		BEGIN CATCH
			SELECT @errmess = 'New batch number preliminaries failed: ' + ERROR_MESSAGE() + ' || ' + ISNULL(@LogMsg, 'NULL')
			GOTO spexit
		END CATCH		
		      
		BEGIN TRY
			BEGIN TRANSACTION   
			
			-- insert HQBC (Batch Control) record
			SELECT @Source = 'AR Invoice'

			EXECUTE @BatchId = Viewpoint.dbo.[bspHQBCInsert] @co=@pCompany, @month=@UIMonth, @source=@Source, @batchtable='ARBH', 
				@restrict='N',@adjust='N',@prgroup=NULL,@prenddate=NULL, @errmsg=@errmess OUTPUT

			SELECT @errmess = ''
			SELECT @CMCo = CMCo	, @CMAcct = CMAcct FROM Viewpoint.dbo.ARCO WHERE ARCo = @pCompany
	
			SELECT @LogMsg = @LogMsg + ' | HQBC Insert Batch ' + ISNULL(CAST(@BatchId AS VARCHAR(20)), 'NULL')

			EXEC dbo.spInsertToTransactLog @Table = 'Invoice transfer', -- varchar(128)
			@KeyColumn = '', -- varchar(128)
			@KeyId = '', -- varchar(255)
			@User = @LogUser, -- varchar(128)
			@UpdateInsert = 'I', -- char(1)
			@msg = @LogMsg  -- varchar(max)  

			COMMIT TRANSACTION
			GOTO spinvoiceloop

		END TRY
		BEGIN CATCH

			ROLLBACK TRANSACTION
            
			SELECT @LogMsg = 'Create batch failed: ' + ERROR_MESSAGE() + ' || ' + @LogMsg
			
			GOTO spexit
		END CATCH;
		
    spinvoiceloop:
        
		-- reset log message for next transaction
		SELECT @LogMsg = ''

		-- define cursor to loop through invoice records
		DECLARE @cur_invoice CURSOR 
		SET @cur_invoice = CURSOR FOR 

			SELECT i.RowId, i.AsteaInvoiceId, i.DueDate, i.InvoiceTotal, i.TotalTax, LTRIM(RTRIM(i.TaxCode)) TaxCode, i.Job, i.JCCo, 
				i.ServiceCenter, i.CustomerId, i.BillToCustomer, co.TaxGroup, co.CustGroup, i.SMCo, i.WorkOrder, i.DateCreated
			FROM dbo.Invoice i 
			INNER JOIN Viewpoint.dbo.HQCO co ON co.HQCo = @pCompany
			WHERE i.ProcessStatus = 'L' AND i.ProcessDesc = @lock

		OPEN @cur_invoice

		-- get first invoice
		FETCH NEXT FROM @cur_invoice INTO 
			@RowId, @AsteaInvoiceId, @DueDate, @InvoiceTotal, @TotalTax, @TaxCode, @Job, @JCCo,
			@ServiceCenter, @AsteaCustomer, @AsteaBillTo, @TaxGroup, @CustGroup, @SMCo, @WorkOrder, @DateCreated

		SELECT @RowCount = 0
		SELECT @BatchSeq = NULL
        
		-- 98620 this string gets put on each Invoice record and also returned to the caller
		SELECT @ProcessDesc = 'Co:' + ISNULL(CAST(@pCompany AS VARCHAR(20)), 'NULL') 
					+ ' Mth:' + ISNULL(CAST(DATEPART(MONTH, @UIMonth) AS VARCHAR(2)) + '/' + RIGHT(CAST(DATEPART(YEAR, @UIMonth) AS VARCHAR(4)), 2), 'NULL')
					+ ' Bat:' + ISNULL(CAST(@BatchId AS VARCHAR(20)), 'NULL')

		BEGIN TRY

			-- invoice loop is one big transaction        
			BEGIN TRANSACTION

			-- loop through invoice records
			WHILE (@@FETCH_STATUS = 0) 
			BEGIN 	

				SELECT @RowCount = @RowCount + 1
				SELECT @Progress = 'Progress: Row ' + ISNULL(CAST(@RowId AS VARCHAR(20)), 'NULL') + ', RowCount ' + CAST(@RowCount AS VARCHAR(10)) + ' , step '
				SELECT @LogMsg = @Progress + '0'

				SELECT @Item = NULL, @Contract = NULL
                
				-- get VP Customer & invoice number 
				SELECT @VPCustomer = NULL
				IF (@AsteaBillTo IS NOT NULL)
				BEGIN
					SELECT @VPCustomer = Customer FROM Viewpoint.dbo.ARCM WHERE CustGroup = @CustGroup AND udASTCust = @AsteaBillTo
					-- 98816 fail for invalid bill-to customer
					IF (@VPCustomer IS NULL)
					BEGIN
						SELECT @errmess = 'Bill-To Customer not found'
						GOTO spfail
					END                  
				END
				IF (@VPCustomer IS NULL)
				BEGIN
					SELECT @VPCustomer = Customer FROM Viewpoint.dbo.ARCM WHERE CustGroup = @CustGroup AND udASTCust = @AsteaCustomer
					IF (@VPCustomer IS NULL)
					BEGIN
						SELECT @errmess = 'Customer not found'
						GOTO spfail
					END
				END     
				
				SELECT @InvoiceNumber = ISNULL(@AsteaInvoiceId, 'NULL')     
				
				-- if this is a work order invoice, get the primary key for the order to store in ARBL
				-- (not needed for job work, but for non-job work we lose connection between the AR batch and the work order
				-- without this field)

				SET @SMWorkOrderID = NULL
				IF @SMCo IS NOT NULL AND @WorkOrder IS NOT NULL
				BEGIN
					SELECT @SMWorkOrderID = SMWorkOrderID FROM Viewpoint.dbo.SMWorkOrder s WHERE s.SMCo = @SMCo AND s.WorkOrder = @WorkOrder              
				END              
				
				-- validate tax code
				IF ISNULL(@TaxCode, '') = '' 
				BEGIN
			        SELECT @errmess = 'Missing tax code'
					GOTO spfail      
				END
  
				IF NOT EXISTS(SELECT TOP 1 1 FROM Viewpoint.dbo.HQTX h WHERE h.TaxCode = @TaxCode AND h.TaxGroup = @TaxGroup
									 AND h.MultiLevel='Y' AND h.udIsActive='Y')
				BEGIN
					SELECT @errmess = 'Tax Code '+ ISNULL(@TaxCode, 'null') + ' not found for Tax Group '
					IF @TaxGroup IS NULL 
					BEGIN
					  SELECT @errmess = @errmess + 'null'
					END 
					ELSE
					BEGIN                  
					  SELECT @errmess = @errmess + STR(@TaxGroup)
					END
					GOTO spfail
				END            
				
				-- GL account info

				IF @Job IS NOT NULL
				BEGIN
   					SELECT @LineType = 'C' -- "Contract"
					              
					-- Get GL Account Info set up in JC Department Master          
					SELECT @Contract = LEFT(@Job, 7)
					SELECT @Department = Department FROM Viewpoint.dbo.JCCM WHERE JCCo = @pCompany AND Contract = @Contract
					SELECT @GLAcct = OpenRevAcct FROM Viewpoint.dbo.JCDM WHERE Department = @Department AND JCCo = @pCompany
					SELECT @LogMsg = @Progress + '0A'
					
					-- Get first item for this contract
					SELECT TOP 1 @Item = Item FROM Viewpoint.dbo.JCCI WHERE Contract = @Contract AND JCCo = @pCompany
					IF (@Item IS NULL)
					BEGIN
						SELECT @errmess = 'Contract Item not found for contract ' + ISNULL(@Contract, 'NULL')
						GOTO spfail                    
					END                  

					SELECT @LogMsg = @Progress + '0AA'
				END
				ELSE
				BEGIN
					SELECT @LineType = 'O' -- "Other"

					-- Get GL Account Info set up in SM Departments
					SELECT @Department = Department FROM Viewpoint.dbo.SMServiceCenter WHERE ServiceCenter = @ServiceCenter AND SMCo = @SMCo
					SELECT @GLAcct = OtherRevGLAcct FROM Viewpoint.dbo.SMDepartment WHERE GLCo = @pCompany AND Department = @Department
					SELECT @LogMsg = @Progress + '0B'
				END          
	
				-- generate new batch sequence
				IF (@BatchSeq IS NULL)
					EXECUTE @BatchSeq = Viewpoint.[dbo].[bspGetNextBatchSeq] @pCompany, @UIMonth, @BatchId;
				ELSE 
					SELECT @BatchSeq = @BatchSeq + 1

				SELECT @LogMsg = @Progress + '1'
						
				SELECT	@TransType = 'A'
						,@ARTrans = NULL
						,@ARTransType = 'I'  -- Invoice
						,@RecType = 1        -- ACCT REC
						,@CustRef = NULL
						,@CustPO = NULL
						,@MSCo = NULL
						,@DiscDate = NULL
						,@AppliedMth = NULL
						,@AppliedTrans = NULL
						,@PayTerms = NULL

				INSERT INTO Viewpoint.[dbo].[ARBH] (
					 Co
					,Mth	
					,BatchId	
					,BatchSeq	
					,TransType	
					,ARTrans	
					,[Source]	
					,ARTransType	
					,CustGroup	
					,Customer	
					,RecType	
					,JCCo	
					,Contract	
					,CustRef	
					,CustPO	
					,Invoice	
					,CheckNo	
					,[Description]	
					,MSCo	
					,TransDate	
					,DueDate	
					,DiscDate	
					,CheckDate	
					,AppliedMth	
					,AppliedTrans	
					,CMCo	
					,CMAcct	
					,CMDeposit	
					,CreditAmt	
					,PayTerms	
					,Notes
					)
				VALUES (
					 @pCompany
					,@UIMonth	
					,@BatchId	
					,@BatchSeq	
					,@TransType	
					,@ARTrans	
					,@Source	
					,@ARTransType	
					,@CustGroup	
					,@VPCustomer	
					,@RecType	
					,@JCCo	
					,@Contract	
					,@CustRef	
					,@CustPO	
					,@InvoiceNumber
					,@CheckNumber	
					,@Description	
					,@MSCo	
					,@DateCreated -- @DueDate	--,@TransactionDate	
					,@DueDate	
					,@DiscDate	
					,@CheckDate	
					,@AppliedMth	
					,@AppliedTrans	
					,@CMCo	
					,@CMAcct	
					,@DepositNumber
					,@CheckAmount
					,@PayTerms	
					,@AsteaInvoiceId
					)		   

				SELECT @LogMsg = @Progress + '2'

				-- new AR Line (one summary AR line per invoice)

				SELECT @ARLine = ISNULL(MAX(ARLine), 0) + 1 
				FROM Viewpoint.dbo.ARBL
				WHERE Co = @pCompany
				AND Mth = @UIMonth
				AND BatchId = @BatchId
				AND BatchSeq = @BatchSeq

				SELECT @GLCo = @pCompany

				-- only insert SMCo if there is a work order
                IF (@WorkOrder IS NULL) SET @SMCo = NULL
		
				SELECT @LogMsg = @Progress + '3'
			
				INSERT INTO Viewpoint.[dbo].[ARBL](
					 Co
					,Mth	
					,BatchId	
					,BatchSeq	
					,ARLine
					,TransType	
					,ARTrans	
					,RecType
					,LineType	
					,[Description]
					,GLCo
					,GLAcct
					,TaxGroup
					,TaxCode
					,Amount
					,TaxBasis
					,TaxAmount
					,Job
					,JCCo
					,[Contract]
					,Item
					,udSMWorkOrderID
					,udWorkOrder
					,udSMCo
					)
				VALUES (
					 @pCompany
					,@UIMonth	
					,@BatchId	
					,@BatchSeq
					,@ARLine	
					,@TransType	
					,@ARTrans	
					,@RecType
					,@LineType
					,@AsteaInvoiceId
					,@GLCo
					,@GLAcct
					,@TaxGroup
					,@TaxCode
					,(@InvoiceTotal + @TotalTax)
					,@InvoiceTotal
					,@TotalTax
					,@Job
					,@JCCo
					,@Contract
					,@Item
					,@SMWorkOrderID
					,@WorkOrder
					,@SMCo
					)	

				SELECT @LogMsg = @Progress + '4'
		
				-- begin 98620 accumulate sums
				SET @SumInvoiceTotal = @SumInvoiceTotal + ISNULL(@InvoiceTotal, 0)
				SET @SumTotalTax = @SumTotalTax  + ISNULL(@TotalTax, 0)
				-- end 98620

				-- unlock record, stamp as processed
				BEGIN TRY
					-- 98620 use @ProcessDesc instead of rebuilding the string for every invoice          
					--UPDATE dbo.Invoice SET ProcessStatus = 'Y', ProcessTimeStamp = GETDATE(), ProcessDesc = 'Co:' + ISNULL(CAST(@pCompany AS VARCHAR(20)), 'NULL') 
					--+ ' Mth:' + ISNULL(CAST(DATEPART(MONTH, @UIMonth) AS VARCHAR(2)) + '/' + RIGHT(CAST(DATEPART(YEAR, @UIMonth) AS VARCHAR(4)), 2), 'NULL')
					--+ ' Bat:' + ISNULL(CAST(@BatchId AS VARCHAR(20)), 'NULL')
					UPDATE dbo.Invoice SET ProcessStatus = 'Y', ProcessTimeStamp = GETDATE(), ProcessDesc = @ProcessDesc
					WHERE ProcessStatus = 'L' AND ProcessDesc = @lock AND RowId = @RowId
					SELECT @LogMsg = @Progress + '5a'
				END TRY
				BEGIN CATCH
					SELECT @LogMsg = @Progress + '5b'
				END CATCH

				GOTO spnext

		spfail:

				-- stamp record as failed
				BEGIN TRY
					UPDATE dbo.Invoice SET ProcessStatus = 'F', ProcessTimeStamp = GETDATE(), ProcessDesc = @errmess
					WHERE ProcessStatus = 'L' AND ProcessDesc = @lock AND RowId = @RowId
					SELECT @LogMsg = @Progress + '5c'
				END TRY
				BEGIN CATCH
					SELECT @LogMsg = @Progress + '5d'
				END CATCH
				
		spnext:

				-- get next invoice
				FETCH NEXT FROM @cur_invoice INTO 
					@RowId, @AsteaInvoiceId, @DueDate, @InvoiceTotal, @TotalTax, @TaxCode, @Job, @JCCo,
					@ServiceCenter, @AsteaCustomer, @AsteaBillTo, @TaxGroup, @CustGroup, @SMCo, @WorkOrder, @DateCreated

			END -- loop through invoice records
		
			CLOSE @cur_invoice
			DEALLOCATE @cur_invoice 		
	      
			-- begin 98620
			BEGIN TRY	
				--  release HQBC (Batch Control) record
				declare @p6 varchar(255)
				set @p6=NULL
				exec Viewpoint.dbo.[bspHQBCExitCheck] @co=@pCompany, @mth=@UIMonth, @batchid=@BatchId, @source=@Source, @tablename='ARBH', @errmsg=@p6 output
			END TRY
			BEGIN CATCH 
				SELECT @LogMsg = 'Release batch failed: ' + ERROR_MESSAGE() + ' || ' + @LogMsg
			  	EXEC dbo.spInsertToTransactLog @Table = 'Invoice transfer', -- varchar(128)
				@KeyColumn = '', -- varchar(128)
				@KeyId = '', -- varchar(255)
				@User = @LogUser, -- varchar(128)
				@UpdateInsert = 'I', -- char(1)
				@msg = @LogMsg  -- varchar(max)              
			END CATCH
			-- end 98620

			COMMIT TRANSACTION      

			-- begin 98620 return batchinfo to caller
			SELECT @errmess = '', @LogMsg = 'Batch ' + ISNULL(CAST(@BatchId AS VARCHAR(20)), 'NULL') + ' Invoice processing complete',
			@batchinfo = @ProcessDesc
				+ ' Inv: $' + convert(varchar,cast(@SumInvoiceTotal as money),1)
				+ '  Tax: $' + convert(varchar,cast(@SumTotalTax as money),1)
			-- end 98620
			GOTO spexit

		END TRY
		BEGIN CATCH
			SELECT @errmess = 'Invoice loop exception: ' + ERROR_MESSAGE(), @batchinfo = ''      
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION
			GOTO spexit	
		END CATCH      
					
	spexit:

		IF (@errmess <> '' AND @errmess IS NOT NULL)
			SELECT @LogMsg = ISNULL(@errmess, 'NULL errmess') + ' || ' + ISNULL(@LogMsg, 'NULL LogMsg')
  
		BEGIN TRANSACTION
  			EXEC dbo.spInsertToTransactLog @Table = 'Invoice transfer', -- varchar(128)
			@KeyColumn = '', -- varchar(128)
			@KeyId = '', -- varchar(255)
			@User = @LogUser, -- varchar(128)
			@UpdateInsert = 'I', -- char(1)
			@msg = @LogMsg  -- varchar(max)      
		COMMIT TRANSACTION
END


GO
