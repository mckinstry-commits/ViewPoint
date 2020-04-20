SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMGroupGetEx    Script Date: 11/6/2002 9:31:57 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspIMGroupGetEx    Script Date: 02/09/2000 9:36:08 AM ******/
    CREATE   proc [dbo].[bspIMGroupGetEx]
     /****************************************************************************
     * CREATED BY: 	DANF 05/22/2000
      * 					DANF 10/26/2004 - Issue 25901 Added with ( nolock ) 
     * USAGE:
     * 	Fills grid in IM imports for Ending date
     *
     * INPUT PARAMETERS:
     *
     * OUTPUT PARAMETERS:
   
     *	See Select statement below
     *
     * RETURN VALUE:
     * 	0 	    Success
     *	1 & message Failure
     *
     *****************************************************************************/
     (@importid varchar(20) = null)
   
     as
     set nocount on
   
     declare @rcode as integer, @prgroup as int
   
     select @rcode = 0
   
   
     begin
   
     select @prgroup = Identifier
     from DDUD with (nolock)
     where Form = 'PRTimeCards' and ColumnName = 'PRGroup'
   
     select Distinct (UploadVal)
     from IMWE with (nolock)
     where ImportId = @importid and Identifier = @prgroup
   
   
   
   
     bspexit:
     return @rcode
     end

GO
GRANT EXECUTE ON  [dbo].[bspIMGroupGetEx] TO [public]
GO
