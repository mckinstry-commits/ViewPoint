SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[vspAPChkPrntOvrflwUpdate]
   /***********************************************************
    * CREATED BY: MV 02/15/06
    * MODIFIED By:	MV 09/08/08 - #129755 update and check
    *				MV 04/14/11 - #142830 return begin check# for 
    *				overflow checks.  Limit update by CMAcct 
    *
    * USAGE:
	* called by APChkPrnt to either set the OverFlow flag to "N"
	* in APPB after printing overflow checks or do a check in
	* APPB to see if there are overflows to print.
	* 
    * An error is returned if the update fails
    *
    * INPUT PARAMETERS
	*	@updatequery	 update statement
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@co bCompany, @mth bMonth, @batchid INT,@updateorcheck VARCHAR(1),@CMCo bCompany,
    @CMAcct bCMAcct,@overflowexists bYN OUTPUT,@BeginOverflowCheck BIGINT OUTPUT,
    @msg VARCHAR(255) OUTPUT)
    
   AS
   SET NOCOUNT ON
  	DECLARE @rcode AS INT
	SELECT @rcode = 0
	
	IF @updateorcheck = 'U'
	BEGIN
		UPDATE dbo.APPB SET Overflow='N' 
		WHERE Overflow='Y' AND Co=@co and Mth=@mth AND BatchId=@batchid
		AND CMCo=@CMCo and CMAcct=@CMAcct
	END

	IF @updateorcheck = 'C'
	BEGIN
		IF EXISTS
			(
			SELECT *
			FROM dbo.APPB 
			WHERE Co=@co 
				AND Mth=@mth 
				AND BatchId=@batchid 
				AND Overflow='Y'
				AND CMCo=@CMCo
				AND CMAcct=@CMAcct
			)
		BEGIN
			SELECT @overflowexists = 'Y', @BeginOverflowCheck = MIN(CMRef)
			FROM dbo.APPB 
			WHERE Co=@co 
				AND Mth=@mth 
				AND BatchId=@batchid 
				AND Overflow='Y'
				AND CMCo=@CMCo
				AND CMAcct=@CMAcct
		END
		ELSE
		BEGIN
			SELECT @overflowexists = 'N'
		END
	END
		
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPChkPrntOvrflwUpdate] TO [public]
GO
