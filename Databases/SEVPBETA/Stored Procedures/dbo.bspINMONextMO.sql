SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspINMONextMO]
   /***********************************************************
    * CREATED BY	: GF 03/01/2002
    * MODIFIED BY	: 
    *				RM 12/23/02 Cleanup Double Quotes
    *
    *
    * USAGE:
    * looks at the inCO AutoMO flag to get the next MO
    * If AutoMO flag is 'Y' then get the MO Increment it and write it back out
    *
    * INPUT PARAMETERS
    *   INCo  IN Co to get next MO from
    *
    * OUTPUT PARAMETERS
    *   @MO    the next MO number to use, if AutoMO is N then ''
    * RETURN VALUE
    *   0         success
    *   1         Failure
   
    *****************************************************/
   ( @inco bCompany = 0, @mo varchar(10) output)
   as
   set nocount on

declare @rcode int  
select @rcode=0
   
   
   -- if AutoMO is Y then update the Current MO then read what the MO should be
   select @mo=''
   
   if (select ISNUMERIC(LastMO) from bINCO where INCo = @inco) = 1
   	begin
       begin transaction AutoMO
   	update bINCO
   	set LastMO = convert(char(30),(convert(int, isNull(LastMO,'')) + 1))
   	where AutoMO='Y' and INCo=@inco
   
   	select @mo=LastMO from bINCO
   	where AutoMO='Y' and INCo=@inco
   
       commit transaction AutoMO
       end
   
   
   return 0

GO
GRANT EXECUTE ON  [dbo].[bspINMONextMO] TO [public]
GO
