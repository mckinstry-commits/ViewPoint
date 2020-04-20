SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*************************************
* Created By:	Dan So 03/23/2010 - Issue: #129350
* Modified by:	Dan So 06/22/2010 - Issue: #140319 - Delete MSSurcharges - work around for Surcharges being
*													 added within MSTBVal procedure
*
* Called from MSBatchProcessing to delete Surcharges from MSTB
*
* INPUT:
*	@MSCo		MS Company
*	@Mth		Batch Month
*	@BatchID	BatchID
*
* OUTPUT:
*	@msg		Description or Error message
*	@rcode		0 - Success
*				1 - Error
*
**************************************/
 --CREATE PROC [dbo].[vspMSSurchargeCleanMSTB]
 CREATE PROC [dbo].[vspMSSurchargeCleanMSTB]
 
(@MSCo bCompany = NULL, @Mth bMonth = NULL, @BatchID bBatchID = NULL,
 @msg varchar(255) = NULL output)
	
AS
SET NOCOUNT ON

	DECLARE	@NumMSTB			int,
			@NumMSSurcharges	int,
			@Status				tinyint,
			@rcode				int
	
	----------------------------------
	-- VALIDATE INCOMING PARAMETERS --
	----------------------------------
	IF @MSCo IS NULL
		BEGIN
			SELECT @msg = 'Missing MS Company', @rcode = 1
			GOTO vspexit
		END
		
	IF @Mth IS NULL
		BEGIN
			SELECT @msg = 'Missing Batch Month', @rcode = 1
			GOTO vspexit
		END
		
	IF @BatchID IS NULL
		BEGIN
			SELECT @msg = 'Missing Batch ID', @rcode = 1
			GOTO vspexit
		END
		
	
	-- PRIME VARIABLES --
	SET @rcode = 0

	-----------------------------------------------------------------------
	-- WORK AROUND - DELETE SURCHARGES THAT WERE CREATED FROM MSTBVal SP --
	-----------------------------------------------------------------------------------------------
	-- ONLY HAPPENS WHEN THE USER VALIDATES THE BATCH, THEN CLOSES THE BATCH FORM WITHOUT		 --
	-- PROCESSING WHILE THERE ARE NO OTHER SURCHARGES ON ANY OTHER RECORDS IN THE BATCH			 --
	-- PLUS THE SYSTEM MUST BE SET UP TO AUTOMATICALLY CREATE SURCHARGES - SO THIS SHOLD BE RARE --
	-----------------------------------------------------------------------------------------------
	-- ISSUE: #140319 --
	--------------------
	SELECT @NumMSTB = COUNT(*)
	  FROM bMSTB WITH (NOLOCK)
	 WHERE Co = @MSCo
	   AND Mth = @Mth
	   AND BatchId = @BatchID
	   AND SurchargeKeyID IS NOT NULL

	SELECT @NumMSSurcharges = COUNT(*)
      FROM bMSSurcharges WITH (NOLOCK)
	 WHERE Co = @MSCo
	   AND Mth = @Mth
	   AND BatchId = @BatchID

	SELECT @Status = Status
      FROM bHQBC
	 WHERE Co = @MSCo
	   AND Mth = @Mth
	   AND BatchId = @BatchID

	-- DELETE RECORDS CREATE FROM MSTBVal --
	IF (@NumMSTB <> @NumMSSurcharges) AND (@Status = 3)	-- 3 = validated
		BEGIN
		
			DELETE bMSSurcharges 
			  FROM bMSSurcharges s
			  JOIN bMSTB b ON b.KeyID = s.MSTBKeyID
			 WHERE b.Co = @MSCo
			   AND b.Mth = @Mth
			   AND b.BatchId = @BatchID	

		END

	--------------------------------------------------------
	-- REMOVE ALL ASSOCIATED SURCHARGE RECORDS FROM BATCH --
	--------------------------------------------------------
	DELETE bMSTB
	 WHERE Co = @MSCo
	   AND Mth = @Mth
	   AND BatchId = @BatchID
	   AND SurchargeKeyID IS NOT NULL
	   
	   
	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		IF @rcode <> 0 
			SET @msg = isnull(@msg,'')
			
		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeCleanMSTB] TO [public]
GO
