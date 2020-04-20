SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDLValForCopy    Script Date: 1/22/03 9:45:18 AM ******/
   CREATE   proc [dbo].[bspPRDLValForCopy]
   /***********************************************************
    * CREATED BY: MV 06/13/2013	TFS-49396
    * MODIFIED By : 
    *
    * USAGE:
    * validates PR Dedn or Liab Code from PRDL for Basis Copy
    *
    *
    * INPUT PARAMETERS
    *   @PRCo   		PR Company
	*	@CopyFromCode
	*	@ToCodeDLType
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(	@PRCo bCompany,		@CopyFromCode bEDLCode,
   		@ToCodeDLType Varchar(1),	@msg varchar(200) output)
   AS
   SET NOCOUNT ON
   
   DECLARE @FromCodeDLType Varchar(1)

   IF @PRCo IS NULL
   BEGIN
   	SELECT @msg = 'Missing PR Company!'
   	RETURN 1
   END

   IF @CopyFromCode IS NULL
   	BEGIN
   	SELECT @msg = 'Missing PR Deduction/Liability Code!'
   	RETURN 1
   	END
   
   SELECT @msg=Description, @FromCodeDLType = DLType 
   FROM dbo.PRDL
   WHERE PRCo=@PRCo AND DLCode=@CopyFromCode
   IF @@ROWCOUNT = 0
   BEGIN
   	SELECT @msg = 'PR Deduction/Liability Code not on file!'
   	RETURN 1
   END
   ELSE
   BEGIN
	IF @ToCodeDLType <> @FromCodeDLType
	BEGIN
		SELECT @msg = 'DL Type for DLCode: ' + CONVERT(Varchar(10),@CopyFromCode) + ' does not match the DL Type for the new DLCode!'
   		RETURN 1
	END
   END
   
   RETURN 

GO
GRANT EXECUTE ON  [dbo].[bspPRDLValForCopy] TO [public]
GO
