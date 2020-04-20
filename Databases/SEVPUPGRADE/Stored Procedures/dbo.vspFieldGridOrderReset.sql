SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCompanyVal    Script Date: 8/28/99 9:34:49 AM ******/
CREATE     proc [dbo].[vspFieldGridOrderReset]
/********************************
* Created: kb 09/02/03 
* Modified:	
*
* Called from FieldProperty form to update properties to vDDFIc, vDDUI
*
* Input:
*	no inputs
* Output:
*	@msg - errmsg if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30), @username varchar(128), @msg varchar(255) output)
as
	set nocount on
	declare @rcode int
	select @rcode = 0

update vDDUI set GridCol = null
  from vDDUI u 
  where u.Form = @form and u.VPUserName = @username
  

update vDDFIc set GridCol = Seq from vDDFIc
  where Form = @form and FieldType =4

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspFieldGridOrderReset] TO [public]
GO
