SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspIMClearBatchEntries]
   /***********************************************************
    * CREATED BY: DANF 06/27/2007
    * MODIFIED BY :
    *
    * USAGE:
    *   remove batch entries where status is greater than 5
    *
    * INPUT PARAMETERS
    *   Template
    *
    * OUTPUT PARAMETERS
    *    FileType
    *    Error Message if error occurs
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@msg varchar(60) output)

   as
   set nocount on
   declare @rcode int
   select @rcode = 0
      
	delete IMBC 
	from IMBC a 
	join HQBC b
	on a.Co = b.Co and a.BatchId = b.BatchId and a.Mth = b.Mth and b.Status >= 5

   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Error') + char(13) + char(10) + '[vspIMClearBatchEntries]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMClearBatchEntries] TO [public]
GO
