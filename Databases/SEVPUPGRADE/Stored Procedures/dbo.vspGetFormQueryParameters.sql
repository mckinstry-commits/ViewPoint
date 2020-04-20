SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:        Ken Eucker, vspGetFormQueryParameters
-- Create date: 5/29/2012
-- Description: Takes a queryname and formname and returns the parameters for the 
--				query
-- =============================================
CREATE PROCEDURE [dbo].[vspGetFormQueryParameters]
      @queryname varchar(120),
      @formname varchar(120)
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
		select * from VPGridQueryLinkParameters l 
		Join VPGridQueryParameters p on l.RelatedQueryName = p.QueryName AND l.ParameterName = p.ParameterName
		where l.RelatedQueryName=@queryname and l.QueryName=(select QueryName from VPGridQueries where Query=@formname)

END


GO
GRANT EXECUTE ON  [dbo].[vspGetFormQueryParameters] TO [public]
GO
