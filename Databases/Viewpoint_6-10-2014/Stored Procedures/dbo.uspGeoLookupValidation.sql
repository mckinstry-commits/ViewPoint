SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[uspGeoLookupValidation] /** User Defined Validation Procedure **/
(@McKCityId varchar(100), @msg varchar(255) output)
AS

declare @rcode int
select @rcode = 0


/****/
if exists(select * from [udGeographicLookup] with (nolock) where   @McKCityId = [McKCityId] )
begin
select @msg = isnull(coalesce(t1.[City] + ', ',' ') + ' ' + coalesce(t1.[State],' ') + ' ' +  coalesce(t1.[ZipCode] + ' ' + coalesce(t2.[Country],''),' ') ,@msg) from [udGeographicLookup] t1 LEFT OUTER JOIN HQST t2  on t1.[State]=t2.[State] where   @McKCityId = [McKCityId] 
end
else
begin
select @msg = 'Invalid City', @rcode = 1
goto spexit
end

spexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[uspGeoLookupValidation] TO [public]
GO
