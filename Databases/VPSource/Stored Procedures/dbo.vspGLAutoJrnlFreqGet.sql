SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspGLAutoJrnlFreqGet]
/*************************************
*  Created:		GG 08/17/06
*  Modified:	GP 04/22/09 - Issue 131863, changed select statement to pull frequency descriptions.
*
*  Returns frequency codes used by GL Auto Journal Entries
*	to populate a list.
*
*  Inputs:
*	@glco		GL Company
*	@jrnl		Journal
*
*  Outputs:
*	 recordset of Frequency codes 
*
**************************************/
(@glco bCompany = null, @jrnl char(2) = null)
as
 
set nocount on
  	
  	
select distinct j.Frequency, c.Description from bGLAJ j
join bHQFC c on c.Frequency = j.Frequency
where j.GLCo = @glco and j.Jrnl = @jrnl

GO
GRANT EXECUTE ON  [dbo].[vspGLAutoJrnlFreqGet] TO [public]
GO
