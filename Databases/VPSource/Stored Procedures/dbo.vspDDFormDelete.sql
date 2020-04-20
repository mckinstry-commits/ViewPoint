SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDFormDelete]

/********************************************************
* CREATED BY: 	TJL 01/16/09 - General Purpose
* MODIFIED BY:  JayR 01/08/2013  Changed to delete quite a few more tables.
*
*
* USAGE:  Can be used to remove all references of a given Form from
*		DD tables and RP tables upon removing Form from Viewpoint.
*
*		Create a Script to be placed in the "Scripts" folder that will
*		call this procedure.  (ie: DropFormNameRefs20090116.sql)
*
* INPUT:
*	@formname		Name of Form being removed from Viewpoint
*
* OUTPUT:
*	@rc		To be used in calling script
*	@msg	To be used in calling script to RAISERROR
*
* EXAMPLE SCRIPT USAGE:
*
*	declare @rc int, @msg varchar(256)
*
*	exec @rc = vspDDFormDelete 'JBProgressBillInit', @msg output
*	
*	if @rc = 1
*		begin
*		raiserror(@msg, 11, -1)
*		end
*
*	if @rc = 0 raiserror('DropFormNameRefs20090116.sql successfull!',9,-1)
*	go
*
*
**********************************************************/
@formname varchar(30), @msg varchar(256) output

as 

declare @rc int

set nocount on

select @rc = 0

--Remove references to Form Name.  Order is important to avoid Trigger errors
DELETE FROM pPortalDetailsField WHERE [Form] = @formname;
DELETE FROM bDDUD WHERE [Form] = @formname;
DELETE FROM vDDRelatedForms WHERE [Form] = @formname;
DELETE FROM vDDFormRelated WHERE [Form] = @formname;
DELETE FROM vDDQueryableColumns WHERE [Form] = @formname;
DELETE FROM vDDQueryableViews WHERE [Form] = @formname;
DELETE FROM bHQAD WHERE [Form] = @formname;
DELETE FROM bDDUF WHERE [Form] = @formname
DELETE FROM vDDFormCountries WHERE [Form] = @formname;
DELETE FROM vDDFormRelatedInfo WHERE [Form] = @formname;

DELETE FROM vVPPartFormChangedParameters
WHERE FormChangedID = 
   (
   SELECT KeyID 
   FROM vVPPartFormChangedMessages 
   WHERE FormName = @formname 
   )
DELETE FROM vVPPartFormChangedMessages WHERE [FormName] = @formname;

-- We are not including this for now
--  'bIMTH'

ALTER TABLE vDDFT DISABLE TRIGGER ALL;
ALTER TABLE vDDFTc DISABLE TRIGGER ALL;

delete vRPFDc where Form = @formname
delete vRPFD where Form = @formname
delete vRPFRc where Form = @formname
delete vRPFR where Form = @formname
delete vDDGBc where Form = @formname
delete vDDTD where MenuItem = @formname
delete vDDSI where MenuItem = @formname
delete vDDTS where Form = @formname
delete vDDFS where Form = @formname
delete vDDFTc where Form = @formname
delete vDDFT where Form = @formname
delete vDDUI where Form = @formname
delete vDDFU where Form = @formname
delete vDDMFc where Form = @formname
delete vDDMF where Form = @formname
delete vDDFLc where Form = @formname
delete vDDFL where Form = @formname
delete vDDFIc where Form = @formname
delete vDDFI where Form = @formname
delete vDDFHc where Form = @formname
delete vDDFH where Form = @formname

ALTER TABLE vDDFT ENABLE TRIGGER ALL;
ALTER TABLE vDDFTc ENABLE TRIGGER ALL;

-- Verify success -------------------------------------------------------------
if exists(select top 1 1 from vDDFH with (nolock) where Form = @formname)
	begin
	select @msg = 'References to Form ' + @formname + ' have not all been removed from vDDFH. Contact Viewpoint support.'
	select @rc = 1
	end

return @rc

GO
GRANT EXECUTE ON  [dbo].[vspDDFormDelete] TO [public]
GO
