SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************
* Created By:  DAN SO 03/02/2010 - ISSUE #129350
* Modified By: 
*
*
* USAGE:   Get Parent and associated Surcharge Ticket Totals
*
*
* INPUT PARAMETERS
*	@msco           MS Company
*	@Mth			Batch Month
*	@BatchID		Batch ID
*	@BatchSeq		Batch Sequence
*
* OUTPUT PARAMETERS
*	@SurchargeTotal	Surcharge Ticket Total
*	@msg            error message
*   
* RETURN VALUE
*   0         Success
*   1         Failure
*
**************************************/
--CREATE PROC [dbo].[vspMSSurchargeTicketTotal]
CREATE  PROC [dbo].[vspMSSurchargeTicketTotal]
 
(@msco bCompany = NULL, @Mth bMonth = NULL, @BatchID bBatchID = NULL, @BatchSeq int = NULL, 
 @SurchargeExistsYN bYN output, @SurchargeTotal bDollar output, @SurchargeDiscountTotal bDollar output,
 @msg varchar(255) = NULL output)
 

AS
SET NOCOUNT ON 

	DECLARE	@rcode	int,
			@Count	int
	
	-- PRIME VALUES --
	SET @rcode = 0
	SET @Count = 0
	SET @SurchargeExistsYN = 'N'
	
	
	----------------------------------
	-- VALIDATE INCOMING PARAMETERS --
	----------------------------------
	IF @msco IS NULL
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
		
	IF @BatchSeq IS NULL
		BEGIN
			SELECT @msg = 'Missing Batch Sequence', @rcode = 1
			GOTO vspexit
		END

		
	------------------------------------
	-- GET ASSOCIATED SURCHARGE TOTAL --
	------------------------------------   
	SELECT	@SurchargeTotal = ISNULL(SUM(s.SurchargeTotal + s.TaxTotal),0), 
			@SurchargeDiscountTotal = ISNULL(SUM(s.DiscountOffered + s.TaxDiscount),0), 
			@Count = COUNT(*)
	  FROM	MSTB b WITH (NOLOCK)
	  JOIN	MSSurcharges s WITH (NOLOCK) ON b.KeyID = s.MSTBKeyID
	 WHERE	b.Co = @msco
	   AND	b.Mth = @Mth
	   AND	b.BatchId = @BatchID
	   AND	b.BatchSeq = @BatchSeq
	   AND  s.BatchTransType <> 'D'

	-- DOES AT LEAST 1 ASSOCIATED SURCHARGE EXIST? --
	IF @Count > 0 SET @SurchargeExistsYN = 'Y'
	

	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		IF @rcode <> 0 
			SET @msg = isnull(@msg,'')
		RETURN @rcode
		
		
		
		

GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeTicketTotal] TO [public]
GO
