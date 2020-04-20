SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Created date: 08/25/2008
-- Description:	Gets the query filters for the DM Transaction Attachments form.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMGetQueryFilterColumns]
	-- Add the parameters for the stored procedure here
	@DDFHForm varchar(30), @queryView varchar(30) output, @returnMessage varchar(512) output
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    SELECT @queryView = QueryView FROM DDQueryableViewsShared Where Form = @DDFHForm
             
	SELECT q.QueryColumnName, 
		   isnull(q.Datatype,d.Datatype) as Datatype,
		   isnull(q.InputType, d.InputType) as InputType, 
		   isnull(q.InputMask, d.InputMask) as InputMask,
		   isnull(q.InputLength, d.InputLength) as InputLength, 
		   isnull(q.Prec, d.Prec) Prec,
		   q.ControlType, 
		   q.ComboType,
		   isnull(c.Description, q.QueryColumnName) as Description,
		   '' as [Filter Value]		
		FROM DDQueryableColumnsShared q
		LEFT JOIN DDDTShared d ON q.Datatype = d.Datatype
		JOIN DDTCShared c ON c.TableName = @queryView and c.ColumnName = q.QueryColumnName
		WHERE Form = @DDFHForm AND ShowInQueryFilter = 'Y'		
		ORDER BY QueryColumnName		
END

GO
GRANT EXECUTE ON  [dbo].[vspDMGetQueryFilterColumns] TO [public]
GO
