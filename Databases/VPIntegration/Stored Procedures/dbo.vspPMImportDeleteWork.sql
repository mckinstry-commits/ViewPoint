SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImportDeleteWork   Script Date: 11/1/2006 ******/
CREATE proc [dbo].[vspPMImportDeleteWork]
/*************************************
 * Created By:	GF 11/1/2006 for 6.x
 * Modified By:
 *
 * Pass this a PMCo and Import Id and SP will delete all data from import work
 * tables except for the header (PMWH). Called from PMImportEdit.StdBeforeRecDelete
 *
 * Pass:
 * PMCO          PM Company for this import
 * ImportId      PM Import Id to delete from work tables
 *
 * Returns:
 *      MSG if Error
 * Success returns:
 *	0 on Success, 1 on ERROR
 *
 * Error returns:
 *  
 *	1 and error message
 **************************************/
(@pmco bCompany, @importid varchar(10) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @pmco is null or @importid is null
	begin
	select @msg = 'Missing information!', @rcode = 1
	goto bspexit
	end


---- delete PMWS - Subcontract
delete from bPMWS where PMCo=@pmco and ImportId=@importid

---- delete PMWM - Material
delete from bPMWM where PMCo=@pmco and ImportId=@importid
   
---- delete PMWD - Detail
delete from bPMWD where PMCo=@pmco and ImportId=@importid
       
---- delete PMWP - Phase
delete from bPMWP where PMCo=@pmco and ImportId=@importid
     
---- delete PMWI - Item 
delete from bPMWI where PMCo=@pmco and ImportId=@importid

---- delete PMWX import data
delete from bPMWX where PMCo=@pmco and ImportId=@importid







bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportDeleteWork] TO [public]
GO
