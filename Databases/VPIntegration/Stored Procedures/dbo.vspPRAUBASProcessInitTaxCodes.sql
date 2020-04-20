SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



	CREATE  procedure [dbo].[vspPRAUBASProcessInitTaxCodes]
	/******************************************************
	* CREATED BY:	MV 03/23/11	PR AU BAS Epic
	* MODIFIED By: 
	*
	* Usage:	Initializes tax code data into vPRAUEmployerBASGSTTaxCodes 
	*			from the previous taxyear/seq. If a previous Seq does not 
	*			exist it copies from previous taxyear/max seq. 
	*			Called from PRAUBASProcess.
	*
	* Input params:
	*
	*	@Co - PR Company
	*	@Taxyear - Tax Year
	*	@Seq - sequence
	*	
	*
	* Output params:
	*	@Msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@Co bCompany,@TaxYear CHAR(4), @Seq INT,@Msg VARCHAR(100) OUTPUT)
   	
	AS
	SET NOCOUNT ON
	DECLARE @rcode INT, @PrevSeq INT
	
	SELECT @rcode = 0, @PrevSeq = 0

	if @Co IS NULL
	BEGIN
		SELECT @Msg = 'Missing PR Company.', @rcode = 1	
		GOTO  vspexit
	END

	IF @TaxYear IS NULL
	BEGIN	
		SELECT @Msg = 'Missing Tax Year.', @rcode = 1
		GOTO  vspexit
	END
	
	IF @Seq IS NULL
	BEGIN	
		SELECT @Msg = 'Missing Sequence.', @rcode = 1
		GOTO  vspexit
	END
	
	-- Get TaxCodes from same Tax Year, previous Seq	
	IF @Seq > 1
	BEGIN
		-- loop through previous seq to find Tax Codes
		SELECT @PrevSeq = @Seq-1
		WHILE 
			(
				NOT EXISTS 
					(
						SELECT * 
						FROM dbo.PRAUEmployerBASGSTTaxCodes
						WHERE PRCo=@Co AND TaxYear=@TaxYear 
						AND Seq = @PrevSeq
					)
			)
		BEGIN
			SELECT @PrevSeq = @PrevSeq - 1
			IF @PrevSeq = 0
				 BREAK
			ELSE
				CONTINUE
		END
		
		-- If we have a previous seq get tax codes
		IF @PrevSeq > 0
		BEGIN
			INSERT INTO dbo.PRAUEmployerBASGSTTaxCodes
				(
					PRCo,
					TaxYear,
					Seq,
					Item,
					TaxCode,
					TaxGroup	
				)
			SELECT				
					@Co AS [PRCo],
					@TaxYear AS [TaxYear],
					@Seq AS [Seq],
					Item,
					TaxCode,
					TaxGroup
						
			FROM dbo.PRAUEmployerBASGSTTaxCodes 
			WHERE PRCo=@Co AND TaxYear=@TaxYear 
			AND Seq = @PrevSeq
		END
	END	
	
	-- No tax codes in current year/previous seq so look in previous year
	IF @PrevSeq=0 OR @Seq = 1
	BEGIN
		IF EXISTS
			(
				SELECT Seq 
				FROM dbo.PRAUEmployerBASGSTTaxCodes
				WHERE PRCo=@Co AND TaxYear=(@TaxYear - 1)
				AND Seq =	(
							SELECT MAX(Seq)
							FROM dbo.PRAUEmployerBASGSTTaxCodes g
							WHERE g.PRCo=@Co AND g.TaxYear=(@TaxYear - 1)
							)
							
			)
		BEGIN
			INSERT INTO dbo.PRAUEmployerBASGSTTaxCodes
				(
					PRCo,
					TaxYear,
					Seq,
					Item,
					TaxCode,
					TaxGroup	
				)
			SELECT				
					@Co AS [PRCo],
					@TaxYear AS [TaxYear],
					@Seq AS [Seq],
					Item,
					TaxCode,
					TaxGroup
			FROM dbo.PRAUEmployerBASGSTTaxCodes 
			WHERE PRCo=@Co AND TaxYear=(@TaxYear - 1)
			AND Seq =	(
							SELECT MAX(Seq)
							FROM dbo.PRAUEmployerBASGSTTaxCodes g
							WHERE g.PRCo=@Co AND g.TaxYear=(@TaxYear - 1)
						)
		END
	END
	 
	vspexit:
	
	RETURN @rcode





GO
GRANT EXECUTE ON  [dbo].[vspPRAUBASProcessInitTaxCodes] TO [public]
GO
