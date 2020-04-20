SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMFormatStripChar]
   /************************************************************************
   * CREATED:  MH 8/17/00
   * MODIFIED: CC 3/19/2008 - Issue #122980 - Add support for notes/large fields
   *		   CC 4/18/2008 - Issue #127913 - Changed loop to Replace t-sql command
   *
   * Purpose of Stored Procedure
   *
   *  Strip the characters from a string.  For example commas a string
   *  '1,000,000.00' will be converted to '1000000.00'.
   *
   *
   * Notes about Stored Procedure
   *
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@invalue varchar(max), @stripchar varchar(10), @outvalue varchar(max) output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
       select @outvalue = @invalue
   
	   SET @outvalue = REPLACE(@outvalue, @stripchar, '')
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMFormatStripChar] TO [public]
GO
