SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLAPUnappRevApproveAll    Script Date:  ******/
CREATE procedure [dbo].[vspSLAPUnappRevApproveAll]
/*******************************************************************************************
* CREATED BY:   	TJL 03/04/09 - Issue #129889, SL Claims and Certifications
* MODIFIED By :   	GF 11/13/2012 TK-19330 SL CLAIM CLEANUP
*
*
* USAGE:
* 	Called from 'bspSLUpdateAP' to set 'Approved' on All Reviewers for invoices
*
*
* INPUT PARAMETERS
*   @apco       SL Company
*	@slusername	VPUserName who is certifying the claim on the SL Worksheet
*	@slkeyid	Worksheet ID
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
***************************************************************************************************/
@apco bCompany, @slusername bVPUserName, @slkeyid bigint, @errmsg varchar(128) output

as
set nocount on

declare @rcode int

select @rcode = 0

if @apco is null
  	begin
  	select @errmsg = 'Missing AP Company.', @rcode = 1
  	goto vspexit
  	end
if @slusername is null
  	begin
  	select @errmsg = 'Missing User Name.', @rcode = 1
  	goto vspexit
  	end
if @slkeyid is null
  	begin
  	select @errmsg = 'Missing Worksheet ID.', @rcode = 1
  	goto vspexit
  	end

if exists(select 1 from bAPUR with (nolock)
		join bAPUL l on bAPUR.APCo = l.APCo and bAPUR.UIMth = l.UIMth and bAPUR.UISeq = l.UISeq and bAPUR.Line = l.Line
		where bAPUR.APCo = @apco and l.SLKeyID = @slkeyid and bAPUR.APTrans is null and  bAPUR.ExpMonth IS NULL)
  	begin
	update bAPUR 
	set bAPUR.ApprvdYN = 'Y', bAPUR.Rejected = 'N', bAPUR.RejReason = '', bAPUR.LoginName = @slusername
	from bAPUR
	join bAPUL l on bAPUR.APCo = l.APCo and bAPUR.UIMth = l.UIMth and bAPUR.UISeq = l.UISeq and bAPUR.Line = l.Line
	where bAPUR.APCo = @apco and l.SLKeyID = @slkeyid and bAPUR.APTrans is null and bAPUR.ExpMonth is null
	if @@rowcount = 0
  		begin
  		select @errmsg = 'Reviewer lines were not approved.', @rcode = 1
  		end
	end

vspexit:

if @rcode <> 0 select @errmsg = @errmsg	
return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspSLAPUnappRevApproveAll] TO [public]
GO
