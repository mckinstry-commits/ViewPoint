SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPOnCostWorkFileLineVal]
/***************************************************
* CREATED BY:	CHS	03/09/2012
*
* Usage:
*   Returns Detail description for display in Line label validates line
*
* Input:
*	@APCo         
*	@Mth
*	@APLine
* Output:
*	@msg          header description
*
* Returns:
*	0             success
*   1             error
*************************************************/
(@APCo bCompany = null, @Mth bMonth = null, @APTrans bTrans = null, @APLine int = null, 
	@OnCostStatus int = null output, @Amount bDollar = null output, @msg varchar(60) output)
   	
	AS
   
	SET NOCOUNT ON
   
	DECLARE @RCode int
   
	SELECT @RCode = 0


	IF @APCo is null
		BEGIN
		SELECT @msg = 'Missing AP Company', @RCode = 1
		RETURN @RCode
		END

	IF @Mth is null
		BEGIN
		SELECT @msg = 'Missing Month', @RCode = 1
		RETURN @RCode
		END
		
	IF @APTrans is null
		BEGIN
		SELECT @msg = 'Missing AP Trans #', @RCode = 1
		RETURN @RCode
		END		

	IF @APLine is null
		BEGIN
		SELECT @msg = 'Missing AP Line #', @RCode = 1
		RETURN @RCode
		END

	IF EXISTS(SELECT TOP 1 1 from dbo.bAPTL where APCo=@APCo and Mth=@Mth and APTrans = @APTrans and APLine=@APLine)
		BEGIN
		SELECT @msg = Description, @OnCostStatus = OnCostStatus, @Amount = GrossAmt
		FROM dbo.bAPTL 
		WHERE APCo=@APCo and Mth=@Mth and APTrans=@APTrans and APLine=@APLine
		END   

	ELSE
		BEGIN
		SELECT @msg = 'Not a valid AP Line #.', @RCode = 1
		END	

	RETURN @RCode
GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostWorkFileLineVal] TO [public]
GO
