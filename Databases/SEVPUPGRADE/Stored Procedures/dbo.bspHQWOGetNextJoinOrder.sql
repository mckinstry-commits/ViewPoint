SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQWOGetNextJoinOrder ******/
CREATE procedure [dbo].[bspHQWOGetNextJoinOrder]
/*******************************************************************************
* Created By:	GF 02/09/2007 6.x
* Modified By:
*
*
*
* Pass In
* TemplateType		Document Template type
*
* RETURN PARAMS
* NextJoin			Next HQWO join order number
*
*
********************************************************************************/
(@templatetype varchar(10) = null, @next_join int = 0 output)
as
set nocount on

declare @rcode int

select @rcode = 0, @next_join = 0

---- get next join for template type
if isnull(@templatetype,'') <> ''
	begin
	select @next_join = max(JoinOrder) + 1 from HQWO where TemplateType=@templatetype
	if @@rowcount = 0 select @next_join = 0
	end



bspexit:
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWOGetNextJoinOrder] TO [public]
GO
