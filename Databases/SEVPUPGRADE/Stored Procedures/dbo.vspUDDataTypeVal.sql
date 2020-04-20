SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vspUDDataTypeVal]
   /****************************************************
   	Created 03/08/01 RM
   	Modified 10/21/03 RM - Issue#22787 - Validate Time/Date based types.
             08/10/07 TIMP - updated to vspUDDataTypeVal
			AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
			
			
   	Usage
   		Validates that datatype specified exists in DDDT
   
   ****************************************************/
    (
      @Datatype CHAR(30),
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    DECLARE @rcode INT
    SELECT  @rcode = 0
   
    IF LEFT(@Datatype, 6) = 'bNotes' 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'bNotes is not allowed.  Use InputType string, length 8000 or use the ''Use Notes Field'' checkbox.'
            GOTO vspexit
        END
   
    IF NOT EXISTS ( SELECT  *
                    FROM    vDDDT
                    WHERE   Datatype = @Datatype ) 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'Datatype does not exist.'
            GOTO vspexit
        END
   
    IF EXISTS ( SELECT  *
                FROM    vDDDT
                WHERE   Datatype = @Datatype
                        AND InputType IN ( 2, 3 )
                        AND SQLDatatype IS NULL ) 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'Use bMonth or bDate for date based data.'
            GOTO vspexit
        END
   
    IF EXISTS ( SELECT  *
                FROM    vDDDT
                WHERE   Datatype = @Datatype
                        AND InputType = 4 ) 
        BEGIN
            SELECT  @rcode = 1,
                    @errmsg = 'Time Datatype not allowed.'
            GOTO vspexit
        END
   
   
    vspexit:
    RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspUDDataTypeVal] TO [public]
GO
