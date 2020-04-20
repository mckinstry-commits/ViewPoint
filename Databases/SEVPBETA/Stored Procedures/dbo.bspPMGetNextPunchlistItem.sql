SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMGetNextPunchlistItem    Script Date: 11/25/2003 11:57:23 AM ******/
    CREATE  procedure [dbo].[bspPMGetNextPunchlistItem]
    /************************************************************************
    * CREATED:    DC 11/25/03  Issue 21544 - Add the '+' option to punchlist items..    
    * MODIFIED:   
    *
    *
    * Purpose of Stored Procedure
    *
    *	Get the next PM Punchlist Item  
    *      
    * INPUT PARAMETERS:
    *	PM Company = @pmco
    *	PM Project = @project
    *	PM Punchlist = @punchlist
    *
    * OUTPUT PARAMETERS:
    *	Next Item Number = @item
    * 	Error Message = @errmsg    
    *           
    * 
    * 
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
   	(@pmco bCompany, @project bJob, @punchlist bDocument, @item smallint output, @errmsg varchar(255) output)   	
   
    as
    set nocount on
    
   	declare @rcode int, @autogen varchar(10)
   	select @rcode = 0
   
   --Validate parameters
   	IF @pmco = null
   	BEGIN
   		Select @errmsg = 'Missing PM Company.', @rcode = 1
   		goto bspexit
   	END
   
   	IF @project = null
   	BEGIN
   		Select @errmsg = 'Missing PM Project.', @rcode = 1
   		goto bspexit
   	END
   
   	IF @punchlist = null
   	BEGIN
   		Select @errmsg = 'Missing PM Punchlist Item.', @rcode = 1
   		goto bspexit
   	END
   
   
    select @item = max(cast(Item as numeric) +1) 
    from dbo.bPMPI with (nolock)
    where PMCo = @pmco
    and Project = @project
    and PunchList = @punchlist
    and isnumeric(Item) = 1
   
    IF @item is null select @item = 1
    
    bspexit:
    
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMGetNextPunchlistItem] TO [public]
GO
