SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Unknown
-- Create date: Unknown
-- Modify date: 2011/09/14 TomJ - Added the InputType (i.e. data type)
-- Modify date: 2012/1/2 JoeA - Removed reference to pvReportParameterControlShared

-- Description:	Retrieves the Parameters and their default values for the PortalControlID and
--              ReportID combination. If a ParameterName is included, it will return the information 
--              for the specific parameter only.
-- =============================================
CREATE PROCEDURE [dbo].[vpspViewpointReportControlParametersGet]
(@PortalControlID int, @ReportID int, @UserID int, @ParameterName varchar(30) = null)
AS
SET NOCOUNT ON;

   SELECT @PortalControlID AS PortalControlID
        , @UserID AS UserID
        , OverridenParameters.ReportID
        , OverridenParameters.ParameterName
        , OverridenParameters.DisplaySeq
        , OverridenParameters.Description
		, OverridenParameters.ParamRequired
		, ISNULL(pReportParametersPortalControl.PortalParameterDefault, OverridenParameters.PortalParameterDefault) AS PortalParameterDefault
        , OverridenParameters.PortalAccess
        , OverridenParameters.InputType
        , OverridenParameters.Datatype
        , ISNULL(pvPortalParameters.Description, 'Not Set') AS PortalParameterDefaultDisplay
        , ISNULL(pvPortalParameterAccess.AccessDescription, 'Not Set') AS PortalAccessDisplay
		, OverridenParameters.LookupName
		, OverridenParameters.LookupTitle
		, OverridenParameters.LookupParams
		, OverridenParameters.LookupLoadSeq
		, OverridenParameters.LookupFromClause
		, OverridenParameters.LookupWhereClause
		, OverridenParameters.LookupJoinClause
		, OverridenParameters.LookupOrderByColumn
		, OverridenParameters.LookupGroupByClause
     FROM
	     (SELECT RPRPShared.ReportID
	           , RPRPShared.ParameterName
	           , RPRPShared.DisplaySeq
	           , RPRPShared.Description
			   , RPRPShared.ParamRequired
	           , RPRPShared.PortalParameterDefault AS PortalParameterDefault
	           , RPRPShared.PortalAccess AS PortalAccess
	           , ISNULL(RPRPShared.InputType, DDDTShared.InputType) as InputType
	           , RPRPShared.Datatype
			   , Lookups.LookupName
			   , Lookups.LookupTitle
			   , Lookups.LookupParams
			   , Lookups.LookupLoadSeq
			   , Lookups.LookupFromClause
			   , Lookups.LookupWhereClause
			   , Lookups.LookupJoinClause
			   , Lookups.LookupOrderByColumn
			   , Lookups.LookupGroupByClause
	        FROM RPRPShared
 LEFT OUTER JOIN 
				(select RPRPShared.ParameterName
					  , DDDT.ReportLookup As LookupName
				      , DDLHShared.Title As LookupTitle
				      , RPRPShared.LookupParams As LookupParams
				      ,	RPRPShared.LookupSeq as LookupLoadSeq
				      , DDLHShared.FromClause AS LookupFromClause
				      , DDLHShared.WhereClause AS LookupWhereClause
				      , DDLHShared.JoinClause AS LookupJoinClause
				      , DDLHShared.OrderByColumn AS LookupOrderByColumn
				      , DDLHShared.GroupByClause As LookupGroupByClause
                   FROM RPRPShared 
        LEFT OUTER JOIN DDDT  
                     on DDDT.Datatype = RPRPShared.Datatype
              LEFT JOIN DDLHShared  
                     on (DDLHShared.[Lookup] = DDDT.ReportLookup)
                  where RPRPShared.ReportID = @ReportID 
                    and RPRPShared.ActiveLookup = 'Y' 
                    and DDDT.ReportLookup is not null	        
                  UNION 
                 SELECT RPRPShared.ParameterName
					  , RPPLShared.[Lookup] As LookupName
			          , DDLHShared.Title As LookupTitle
			          , RPPLShared.LookupParams As LookupParams
			          , RPPLShared.LoadSeq AS LookupLoadSeq
			          , DDLHShared.FromClause AS LookupFromClause
			          , DDLHShared.WhereClause AS LookupWhereClause
			          , DDLHShared.JoinClause AS LookupJoinClause
			          , DDLHShared.OrderByColumn AS LookupOrderByColumn
			          , DDLHShared.GroupByClause As LookupGroupByClause
                   FROM RPRPShared 
        left outer join DDDTShared 
                     on DDDTShared.Datatype = RPRPShared.Datatype
              LEFT join RPPLShared 
                     on RPRPShared.ReportID = RPPLShared.ReportID 
                    and RPRPShared.ParameterName = RPPLShared.ParameterName 
              left join DDLHShared on DDLHShared.[Lookup] = RPPLShared.[Lookup]
        LEFT OUTER JOIN DDDT  
                     on DDDT.Datatype = RPRPShared.Datatype
                  WHERE RPRPShared.ReportID = @ReportID 
                    and (DDDT.ReportLookup is null OR DDLHShared.Title IS NOT NULL)
              ) As Lookups
                     ON RPRPShared.ParameterName = Lookups.ParameterName
LEFT OUTER JOIN DDDTShared  
             on DDDTShared.Datatype = RPRPShared.Datatype
	       WHERE RPRPShared.ReportID = @ReportID) OverridenParameters
LEFT JOIN pReportParametersPortalControl
	   ON pReportParametersPortalControl.ReportID = @ReportID 
	  AND pReportParametersPortalControl.ParameterName = OverridenParameters.ParameterName
	  AND pReportParametersPortalControl.PortalControlID = @PortalControlID
LEFT JOIN pvPortalParameters 
       ON OverridenParameters.PortalParameterDefault = pvPortalParameters.KeyField
LEFT JOIN pvPortalParameterAccess 
       ON OverridenParameters.PortalAccess = pvPortalParameterAccess.KeyField
    WHERE OverridenParameters.ParameterName = ISNULL(@ParameterName,OverridenParameters.ParameterName)
 ORDER BY OverridenParameters.DisplaySeq
GO
GRANT EXECUTE ON  [dbo].[vpspViewpointReportControlParametersGet] TO [VCSPortal]
GO
