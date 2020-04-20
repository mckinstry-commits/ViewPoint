SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Dan Koslicki
-- Create date: 03/19/13
-- Description:	Populate the table SMAgreementAmrtBatch for Recognizing revenue
-- Modification: 
-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementAmrtRevBatchCreate](	@BatchCo			AS bCompany, 
													@BatchMonth			AS bMonth,
													@ThroughDate		AS bDate, 
													
													@msg				AS VARCHAR(255) OUTPUT, 
													@BatchId			AS bBatchID = NULL OUTPUT) 

AS 

BEGIN 

	IF NOT EXISTS
	(
		SELECT	1

			FROM	vfSMAgreementAmortizedAmount(@BatchCo, @ThroughDate) AA
			
			WHERE	NOT EXISTS (SELECT 1
								FROM SMAgreementAmrtBatch AB 
								WHERE AB.Co = AA.SMCo AND AB.Agreement = AA.Agreement AND AB.Revision = AA.Revision AND dbo.vfIsEqual(AB.Service, AA.Service) = 1)  
					AND AA.RecognizableAmount <> 0 
	)
	BEGIN
		SET @msg = 'No revenue to amortize'
		RETURN 1
	END
	
	
	BEGIN TRY 
		BEGIN TRAN
					DECLARE @Restrict			AS bYN,
							@BatchTable			AS VARCHAR(20), 
							@Source				AS bSource		

					SELECT	@Restrict		= NULL, 
							@BatchTable		= 'SMAgreementAmrtBatch', 
							@Source			= 'SMAmortize'
					
					SELECT @Restrict = (SELECT RestrictedBatches FROM DDUPExtended WHERE VPUserName = SUSER_NAME())
					IF @Restrict IS NULL 
					BEGIN 
						SELECT @Restrict = 'Y'
					END 

					-- Create Batch Entry in HQBC 
					EXEC @BatchId = dbo.bspHQBCInsert @co = @BatchCo, @month = @BatchMonth, @source = @Source, @batchtable = @BatchTable, @restrict = @Restrict, @adjust = 'N', @errmsg = @msg OUTPUT
					
					-- Exit if creating an entry in HQBC should fail. 
					IF @BatchId = 0
					BEGIN
						ROLLBACK TRAN
						RETURN 1
					END


					INSERT INTO SMAgreementAmrtBatch (	Co, 
														Mth, 
														BatchId, 
														Seq, 
														Agreement, 
														Revision, 
														Service, 
														Amount, 
														GLCo, 
														AgreementRevDefGLAcct, 
														AgreementRevGLAcct)

					SELECT	Co						= @BatchCo, 
							Mth						= @BatchMonth, 
							BatchId					= @BatchId, 
							Seq						= ROW_NUMBER() OVER (ORDER BY AA.Agreement, AA.Revision, AA.Service), 
							Agreement				= AA.Agreement, 
							Revision				= AA.Revision, 
							Service					= AA.Service, 
							Amount					= AA.RecognizableAmount, 
							GLCo					= AA.GLCo, 
							AgreementRevDefGLAcct	= AA.AgreementRevDefGLAcct, 
							AgreementRevGLAcct		= AA.AgreementRevGLAcct

					FROM	vfSMAgreementAmortizedAmount(@BatchCo, @ThroughDate) AA
					
					WHERE	NOT EXISTS (SELECT 1
										FROM SMAgreementAmrtBatch AB 
										WHERE AB.Co = AA.SMCo AND AB.Agreement = AA.Agreement AND AB.Revision = AA.Revision AND dbo.vfIsEqual(AB.Service, AA.Service) = 1)  
							AND AA.RecognizableAmount <> 0 
		
		COMMIT TRAN
	END TRY

	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
END 
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementAmrtRevBatchCreate] TO [public]
GO
