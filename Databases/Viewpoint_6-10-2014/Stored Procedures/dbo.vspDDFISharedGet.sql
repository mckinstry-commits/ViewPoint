SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
CREATE PROC [dbo].[vspDDFISharedGet]
  /***************************************
  * Created: JRK 01/25/07
  * Modified: AMR - 6/23/11 - TK-06411, Fixing performance issue by using an inline table function., Fixing performance issue by using an inline table function.
  *
  * Used to populate a combo box with the column name and display name of fields on a form.
  *
  **************************************/
    (
      @form VARCHAR(30) = NULL,
      @msg VARCHAR(60) OUTPUT
    )
AS 
    SET nocount ON
	  
    DECLARE @rcode INT
    SELECT  @rcode = 0
  
    IF @form IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Form!',
                    @rcode = 1
            RETURN @rcode
        END
	-- Construct a string with the internal column name followed by the displayed column name in quotes.
    SELECT  ColumnName + '  ("' + ISNULL(Description, '') + '")',
            Seq
            -- use inline table function for perf
    FROM    dbo.vfDDFIShared(@form)
    WHERE   ColumnName IS NOT NULL
    ORDER BY Seq
	 
    IF @@rowcount = 0 
        SELECT  @msg = 'No columns for the specified form!',
                @rcode = 1
	  
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFISharedGet] TO [public]
GO
