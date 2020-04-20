SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlNotesGet    Script Date: 7/28/2004 11:23:12 AM ******/
     CREATE      proc [dbo].[bspHQMatlNotesGet]
     /********************************************************
     * CREATED BY: 	DC 7/28/04
     * MODIFIED BY:
     *				
     *
     * USAGE:
     * 	Retrieves the Material Notes from bHQMT
     *
     * CALLED FROM:
     *	RQ Entry
     *	PO Entry
     *
     * INPUT PARAMETERS:
     *	HQ Material
     *	HQ Material Group
     *
     * OUTPUT PARAMETERS:
     *	Notes from bHQMT
     *	Error Message, if one
     *
     * RETURN VALUE:
     * 	0 	    Success
     *	1 & message Failure
     *
     **********************************************************/
     
     	(@material bMatl, @matlgroup bGroup, @notes varchar(8000) output, @msg varchar(255) output)
     as 
     	set nocount on
     	declare @rcode int
     	select @rcode = 0
     	
     IF @material is null
     	begin
     	select @msg = 'Missing HQ Material', @rcode = 1
     	goto bspexit
     	end
     
     IF @matlgroup is null
     	begin
     	select @msg = 'Missing HQ Material Group', @rcode = 1
     	goto bspexit
     	end
     
     	SELECT @notes = isnull(Notes,'')
     	FROM HQMT 
     	WHERE MatlGroup = @matlgroup AND Material = @material
     	IF @@rowcount = 0 
     		SELECT @msg = 'HQ material does not exist', @rcode=0, @notes = ''
     
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatlNotesGet] TO [public]
GO
