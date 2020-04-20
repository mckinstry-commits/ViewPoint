SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************/
CREATE function [dbo].[vfPMRFIResponses] 
	(@pmco tinyint = null, @project varchar(10) = null, @rfitype varchar(10) = null, @rfi varchar(10) = null)
returns nvarchar(max)
as
begin

/***********************************************************
* CREATED BY:	GF 07/30/2009 - issue #134256
* MODIFIED By:
*
*
*
* USAGE:
* This function is used to return the RFI responses from PMRFIResponse view
* concatenated together in one output parameters. Used in the PM RFI Document
* create and send feature.
*
*
* INPUT PARAMETERS
* @pmco		PM Company
* @project	PM Project
* @rfitype	PM RFI Document Type
* @rfi		PM RFI
*
*
* OUTPUT PARAMETERS
* Responses from PMRFIResponses concatenated together in one output parameter
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/

declare @response nvarchar(max)

set @response = ''

if @pmco is null or @project is null or @rfitype is null or @rfi is null goto bspexit

---- get the responses for the requested RFI and add to @response
select @response = @response + isnull(r.Notes,'') + CHAR(13) + CHAR(10)
from dbo.PMRFIResponse r with (nolock)
where r.PMCo = @pmco and r.Project = @project and r.RFIType = @rfitype
and r.RFI = @rfi and r.Send = 'Y' and isnull(r.Notes,'') <> ''
order by r.DisplayOrder, r.KeyID, r.Notes



bspexit:
	return(@response)
	end

GO
GRANT EXECUTE ON  [dbo].[vfPMRFIResponses] TO [public]
GO
