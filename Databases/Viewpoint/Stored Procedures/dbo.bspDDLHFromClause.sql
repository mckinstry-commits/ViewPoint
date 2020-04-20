SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDLHFromClause    Script Date: 8/6/2003 3:33:54 PM ******/
   CREATE   proc [dbo].[bspDDLHFromClause]
   /***********************************************************
    * CREATED BY	: DC 8/7/03 - #21802 - change lookup joins in DDLH to be ANSI standard 
    * MODIFIED BY	: 
    *                                 
    *
    * USAGE:
    * validates FromClause 
    *
    * INPUT PARAMETERS
    *   Lookup    Lookup in DDLH
    *
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    * RETURN VALUE
    *   0         success
    *   1         Failure  
    *****************************************************/
   
       (@lookup char(30), @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @msg = 'Valid FromClause'
   
   if @lookup like '%,%' 
   select @rcode=1, @msg= 'Invalid FromClause.  FromClause cannot contain any commas'
   
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspDDLHFromClause] TO [public]
GO
