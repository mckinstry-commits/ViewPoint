SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE proc [dbo].[vspPMPFUserFormUpdate]
/************************************************
* Created By:	GF 02/06/2005 
* Modified By:	GF 10/08/2007 - issue #125699 skip update if @form is empty
*
*
* Called from the PMPFListView form to update list view form position and size
* for the owner form by user. Options="PMRFI;110,234,800,54:PMRFQ;0,0,0,0:"
*
* Input:
* @form				PM Owner Form 
* @options			PM Form Options stores the position and size for the list view by owner form name.
*
*
* Output:
* @errmsg		error message

* Return code:
* 0 = success, 1 = failure
*
*********************************/
(@form varchar(30) = null, @options varchar(256) = null, @errmsg varchar(256) output)
as
set nocount on

declare @rcode int

select @rcode = 0

-- don't update if viewpoint
if suser_sname()= 'viewpointcs' goto vspexit

if isnull(@form,'') = '' goto vspexit

-- try to update existing user lookup entry
update dbo.vDDFU set Options = @options
where VPUserName = suser_sname() and Form = @form 
if @@rowcount = 0
	begin
	-- add new entry
	insert dbo.vDDFU (VPUserName, Form, Options)
	select suser_sname(), @form, @options
	end




vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPFUserFormUpdate] TO [public]
GO
