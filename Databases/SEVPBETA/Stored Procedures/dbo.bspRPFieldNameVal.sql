SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRPFieldNameVal    Script Date: 8/28/99 9:33:38 AM ******/
   /****** Object:  Stored Procedure dbo.bspRPFieldNameVal    Script Date: 3/28/99 12:00:38 AM ******/
   /************************************************************************
   * CREATED:	   
   * MODIFIED: AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
   *
   * Purpose:  validates Report FieldName
   
   * returns 1 and error msg if failed
   *
   *************************************************************************/
CREATE  PROCEDURE [dbo].[bspRPFieldNameVal]
(
  @fieldname varchar(60) = NULL,
  @msg varchar(60) OUTPUT
)
AS 
   /* pass FieldName */
   /* returns error message if error */
SET nocount ON
DECLARE @rcode int
DECLARE @byte integer,
    @len integer,
    @endbyte integer
SELECT  @rcode = 0
IF @fieldname IS NULL 
    BEGIN
        SELECT  @msg = 'Missing fieldname!',
                @rcode = 1
        GOTO bspexit
    END
   /* formulas begin with a @,  can't validate to anything) */
IF SUBSTRING(@fieldname, 1, 1) = '@' 
    BEGIN	
        IF DATALENGTH(RTRIM(@fieldname)) = 1 
            BEGIN
                SELECT  @msg = 'Invalid fieldname (' + @fieldname + ').',
                        @rcode = 1
                GOTO bspexit
            END
        GOTO bspexit
    END
   
   /* find the byte position of '.' in fieldname i.e. GLAC.GLAcct */
SELECT  @byte = ISNULL(CHARINDEX('.', @fieldname), 0),
        @len = ISNULL(DATALENGTH(RTRIM(@fieldname)), 0),
        @endbyte = ISNULL(CHARINDEX('(', @fieldname), 0) - 1
IF @endbyte <= 0 
    SELECT  @endbyte = @len
IF @byte <= 1
    OR @byte >= @len
    OR @endbyte <= @byte 
    BEGIN
        SELECT  @msg = 'Invalid fieldname!',
                @rcode = 1
        GOTO bspexit
    END
   
   /* check if the datatype is valid (characters, numerics, and dates only) */
   --#142278
SELECT  @msg = b.name
FROM    syscolumns a
			JOIN systypes b ON a.usertype = b.usertype
WHERE   a.id = OBJECT_ID(SUBSTRING(@fieldname, 1, @byte - 1))
        AND a.name = SUBSTRING(@fieldname, @byte + 1, @endbyte - @byte)
        AND a.[type] NOT IN ( NULL, 34, 35, 37, 45, 50 )

IF @@rowcount = 0 
    BEGIN
        SELECT  @msg = 'Invalid field or datatype (' + @fieldname + ').',
                @rcode = 1
        GOTO bspexit
    END
   
bspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRPFieldNameVal] TO [public]
GO
