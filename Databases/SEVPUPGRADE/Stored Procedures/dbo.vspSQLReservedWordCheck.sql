SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspSQLReservedWordCheck]
   /*********************************************
    * Created: RM 01/03/08
    * Modified: 
    *
    * Usage:
    *  Checks input parameter against SQL Reserved word list
    *
    * Input:
    *  @wordtocheck - Word to check against Reserved Word List
    *
    * Output:
    *  @msg        Error message
    *
    * Return:
    *  0           success
    *  1           error
    *************************************************/
    @wordtocheck varchar(50),@msg varchar(255) output
   
	as
   
	set nocount on

	declare @rcode int
	select @rcode = 0   


	if exists(select top 1 1 from vSQLReservedWords where UPPER(ReservedWord)=UPPER(@wordtocheck))
		select @rcode = 1, @msg='Cannot use ''' + @wordtocheck + ''' because it is a SQL reserved word.'
   
	bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSQLReservedWordCheck] TO [public]
GO
