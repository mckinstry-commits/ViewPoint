SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE                         PROCEDURE [dbo].[vspVPGetLogViewerGridColumns]
/**************************************************
* Created:  JK 07/28/05
* Modified:  JRK 03/08/06 to use DDFI and DDUI instead of vDDFI and vDDUI.
*
* Retrieves grid column info for a user.
* 
* Inputs:
*	@username		user's id
*
* Output
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null,
	 @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@username is null) 
	begin
	select @errmsg = 'Missing required field:  username.  [vspVPGetLogViewerGridColumns]', @rcode = 1
	goto vspexit
	end

-- Do the Select:

select i.Seq, i.GridCol, i.ColumnName, i.GridColHeading, w.ColWidth
From DDFI i
Left Outer Join DDUI w on i.Form=w.Form and i.Seq = w.Seq and w.VPUserName=@username
Where i.Form = 'frmLogViewer'
Order By i.GridCol

GOTO vspexit

--
vspexit:
	return @rcode











GO
GRANT EXECUTE ON  [dbo].[vspVPGetLogViewerGridColumns] TO [public]
GO
