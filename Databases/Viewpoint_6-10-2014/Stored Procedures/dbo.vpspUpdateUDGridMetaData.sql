SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Ken E / Chris G
-- Create date: 8/23/12
-- Description:	Updates UD Column in Connects Data Grid
-- =============================================
CREATE PROCEDURE [dbo].[vpspUpdateUDGridMetaData] 
	(@dataGridID INT, @view VARCHAR(128))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    -- Get the max column order and the starting new grid column id
	DECLARE @maxStandardColumnOrder INT, @newGridColumnID INT
	SELECT @maxStandardColumnOrder = MAX(ColumnOrder) FROM pvDataGridColumns where DataGridID = @dataGridID
	SELECT @newGridColumnID = 
		CASE 	 
			WHEN MAX(DataGridColumnID) IS NULL THEN 100000 
			WHEN MAX(DataGridColumnID) < 100000 THEN 100000
			ELSE MAX(DataGridColumnID) + 1
		END 
	FROM pPortalDataGridColumnsCustom
	
	-- clear out the current records for this data grid id in the custom table
	delete from pPortalDataGridColumnsCustom where DataGridID=@dataGridID
		
	-- insert the new records into the custom table
	INSERT INTO pPortalDataGridColumnsCustom (DataGridColumnID, HeaderText, Visible, ColumnOrder, DefaultValue, ColumnWidth, IsRequired, DataFormatID, MaxLength, DataGridID, ColumnName, HasLookup)
	SELECT 
		@newGridColumnID + ROW_NUMBER() OVER (ORDER BY Seq) As DataGridColumnID	
		,[Label] AS HeaderText
		,1 As Visible
		,ROW_NUMBER() OVER (ORDER BY Seq) + @maxStandardColumnOrder As ColumnOrder
		,[DefaultValue]
		,[ColWidth] As ColumnWidth
		,CASE [Req] WHEN 'Y' THEN 1 Else 0 END As IsRequired
		,dbo.vfUDGetDataFormatID(@view,[ColumnName]) 
		,[InputLength] 
		,@dataGridID As DataGridID  
		,ColumnName
		,case when exists(select 1 from vDDFLc b where a.Form = b.Form and a.Seq = b.Seq and b.Active = 'Y') then 1 else 0 end As HasLookup
	FROM [dbo].[vDDFIc] a
	where ViewName=@view
	
END
GO
GRANT EXECUTE ON  [dbo].[vpspUpdateUDGridMetaData] TO [VCSPortal]
GO
