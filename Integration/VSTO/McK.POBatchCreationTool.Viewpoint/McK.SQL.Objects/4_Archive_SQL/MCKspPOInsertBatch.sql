USE [Viewpoint]
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='MCKspPOInsertBatch' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.MCKspPOInsertBatch'
	DROP PROCEDURE dbo.MCKspPOInsertBatch
End
GO

Print 'CREATE PROCEDURE dbo.MCKspPOInsertBatch'
GO

CREATE PROCEDURE [dbo].MCKspPOInsertBatch
(  @JCCo bCompany
  ,@BatchMth bMonth
  ,@Rbatchid bBatchID
  ,@passCnt INT OUTPUT  
) 
AS
/*
	AUTHOR:	Leo Gurdian
	PURPOSE: Inserted validated POs into VP Batch, user then approves / continues process in VP.
	HISTORY:	
	-------	  -----------------------
	3.30.18	- Created - LeoG
	4.4.18	- use PO instead of udMCKPONumber - LG.
	4.13.18	- remove Try..Cath.. to let errors bubble up and avoid suppresion
*/

DECLARE @jcco bCompany = @JCCo
DECLARE @batchmth bMonth = @BatchMth
DECLARE @batchid bBatchID = @Rbatchid
DECLARE @po varchar(30)
DECLARE @includeitems bYN ='Y'
DECLARE @errmsg varchar(255)
DECLARE @totalCnt INT
declare @rcode int -- 0 success,  1 fail

Begin

	-- loop thru and insert all validated POs into VP batch
		DECLARE PO_Cursor CURSOR
       STATIC
       FOR
             Select Distinct PO From MCKPOLoad 
				 Where PO is NOT NULL 
						AND JCCo = @jcco 
						AND BatchMth = @batchmth 
						AND BatchNum = @batchid
						AND Status = 'P'; -- passed validation
		
		/* loop through all rows in this batch */				  
      BEGIN
			OPEN PO_Cursor;
			FETCH NEXT FROM PO_Cursor into @po;
			WHILE @@FETCH_STATUS = 0
				BEGIN
              
					EXECUTE @rcode = [dbo].bspPOHBInsertExistingTrans 
											@jcco 
											,@batchmth 
											,@batchid 
											,@po
											,@includeitems
											,@errmsg OUTPUT
					if @rcode <> 0
						BEGIN
							-- insert failure if not already in error table
							Insert into dbo.MCKPOerror
							(JCCo, BatchNum, MCKPO, PO, BatchMth, ErrMsg, ErrDate)
							(Select JCCo, BatchNum, MCKPO, PO, BatchMth, @errmsg, GetDate()
							 From dbo.MCKPOLoad a
							 Where Not Exists (Select 1 from dbo.MCKPOerror rr Where JCCo = @jcco AND BatchNum = @batchid AND rr.PO = @po)
									AND BatchNum = @batchid
									AND a.PO = @po );
							
							/* 2nd pass validation failed; mark record */
							Update MCKPOLoad
							Set Status = 'F'
							Where JCCo = @jcco and BatchMth = @batchmth and BatchNum = @batchid and PO = @po
						END 
					FETCH NEXT FROM PO_Cursor into @po;
				END
       
         CLOSE PO_Cursor;
         DEALLOCATE PO_Cursor;
		END

		Begin
			Select @passCnt  = Count(*) from  MCKPOLoad where BatchNum = @batchid and BatchMth =  @batchmth and JCCo = @jcco AND Status = 'P'; 
			Select @totalCnt = Count(*) from  MCKPOLoad where BatchNum = @batchid and BatchMth =  @batchmth and JCCo = @jcco; 
		END

		/* if all POs fail, cancel batch */
		Begin
			If @passCnt = 0
				Begin
					Update bHQBC
					Set Status = 6 -- Cancel
					Where Co = @jcco and Mth = @batchmth and Source = 'PO Entry' and BatchId = @batchid
				End
		End

		/* ENABLE: batch to appear in 'PO Batch Process' F4 look up */
		/* If enabled, anyone can process the batch.  Else, only the user that created the batch can process it. */
		Begin
			Update bHQBC
			Set InUseBy = null
			Where Co = @jcco and Mth = @batchmth and TableName = 'POHB' and BatchId = @Rbatchid and Status = 0
		End


--email the results
	DECLARE @tableHTML  NVARCHAR(MAX), @subject NVARCHAR(120)
	DECLARE @msge VARCHAR(2000)
	DECLARE @body1  NVARCHAR(MAX)
		
	BEGIN
		
		
		BEGIN
			
			SELECT @subject = 'VP PO Load for Co: ' + Cast (@jcco AS Varchar(3)) 
								 + ' - Batch Num: ' + Cast (@batchid AS Varchar(10)) 
								 + ' - Batch Mth: ' + Cast (@batchmth AS Varchar(20)) 
								 + ' - Batch Rec count: ' + Cast (@passCnt AS Varchar(6)) 
								 + ' / ' +  Cast (@totalCnt AS Varchar(6))
			SELECT 
@msge = '<html><head><title>Viewpoint PO Load Processing Message</title></head><body>'
+             '<p>Note: If there are no records to be processed, there will not be a list.<br/>'
+             '<br/><br/></p>'
+             '<hr/><br/><font size="-2" color="silver"><i>'  
+             @@SERVERNAME + '.' + DB_NAME() + ' [' + SUSER_SNAME() + ' @ ' + CONVERT(VARCHAR(20),GETDATE(),100) + '] '
+             '</i></font><br/><br/></body></html>' 

			SET @tableHTML = 
				N'<H3>' + @subject + N'</H3>' +
				N'<H4>' + @msge + N'</H4>' +
				N'<font size="-2">' +
				N'<table border="1">' +
				N'<tr bgcolor=silver>' +
				N'<th>Co</th>' +
				N'<th>MCK PO</th>' +
				N'<th>PO Request #</th>' +
				N'<th>Validation</th>' +
				 N'</tr>' +
				CAST 
				( 
					( 
						SELECT
							td = COALESCE(@jcco,' '), ''
						,	td = COALESCE(a.MCKPO,' '), ''
						,	td = COALESCE(a.PO,' '), ''
						,	td = COALESCE(a.Status,' '), ''
						FROM  MCKPOLoad a 
						WHERE BatchNum = @batchid 
								AND BatchMth =  @batchmth 
								AND JCCo = @jcco
					
						ORDER BY 2	
						FOR XML PATH('tr'), TYPE 
					) AS NVARCHAR(MAX) 
				) + N'</table>' + N'<br/><br/>'

				SELECT @body1 = ISNULL(@tableHTML,@msge)

				Declare @userEmail varchar(320) = REPLACE (SUSER_SNAME(), 'MCKINSTRY\','') + '@McKinstry.com';

				EXEC msdb.dbo.sp_send_dbmail 
					@profile_name = 'Viewpoint',
					@recipients =  @userEmail
					,@blind_copy_recipients = 'ArunT@mckinstry.com;JeanN@mckinstry.com;KevinS@mckinstry.com;LeoG@mckinstry.com'
					,@subject = @subject,
					@body = @body1,
					@body_format = 'HTML'

		 END

	END

End

GO

Grant EXECUTE ON dbo.MCKspPOInsertBatch TO [MCKINSTRY\Viewpoint Users]
