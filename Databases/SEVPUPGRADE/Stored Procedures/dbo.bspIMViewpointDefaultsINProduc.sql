SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROC [dbo].[bspIMViewpointDefaultsINProduc]
     /***********************************************************
      * CREATED BY: JimE
      * Usage:
      *	INProduction Defaults - runs bspIMViewpointDefaulsINPB & bspIMViewpointDefaulsINPD
      *      data based upon Bidtek default rules. This will call 
      *      coresponding bsp based on record type.
      *
      * Input params:
      *	@ImportId	Import Identifier
      *	@ImportTemplate	Import ImportTemplate
      *
      * Output params:
      *	@msg		error message
      *
      * Return code:
      *	0 = success, 1 = failure
      ************************************************************/
    ( @Company bCompany
    , @ImportId VARCHAR(20)
    , @ImportTemplate VARCHAR(20)
    , @Form VARCHAR(20)
    , @rectype VARCHAR(10)
    , @msg VARCHAR(120) OUTPUT
    )
AS 
SET nocount ON
DECLARE @rcode INT
  , @recode INT
  , @desc VARCHAR(120)
  , @tablename VARCHAR(10)
SELECT  @rcode = 0
      , @msg = ''
SELECT  @Form = Form
FROM    IMTR
WHERE   RecordType = @rectype
        AND ImportTemplate = @ImportTemplate
--select @Form as f,'Here' as m into x1d  select * from x1d
IF @Form = 'INProduction' 
    BEGIN
        EXEC @rcode = dbo.bspIMViewpointDefaultsINPB 
            @Company
          , @ImportId
          , @ImportTemplate
          , @Form
          , @rectype
          , @msg OUTPUT
    END
IF @Form = 'INProdComponents' 
    BEGIN
        EXEC @rcode = dbo.bspIMViewpointDefaultsINPD 
            @Company
          , @ImportId
          , @ImportTemplate
          , @Form
          , @rectype
          , @msg OUTPUT
    END
     
     
     
bspexit:
SELECT  @msg = ISNULL(@desc, 'IN Production') + CHAR(13) + CHAR(10) + '[bspIMViewpointDefaultsINProduc]'
     
RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsINProduc] TO [public]
GO
