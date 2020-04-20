SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMImportIdDelete    Script Date: 8/28/99 9:33:04 AM ******/
CREATE procedure [dbo].[bspPMImportIdDelete]
/*******************************************************************************
* This SP will delete the import work header record after a successfull
* update.
*
* It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
*
* Pass In
*   ImportId		ImportId to insert
* 
* RETURN PARAMS
*   msg           Error Message, or Success message
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
(@pmco bCompany = null, @importid varchar(10) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode=0

If @importid is null
     begin
     select @msg='Missing ImportId', @rcode=1
     goto bspexit
     end

---- delete ImportId
delete from PMWH where PMCo=@pmco and ImportId=@importid


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMImportIdDelete] TO [public]
GO
